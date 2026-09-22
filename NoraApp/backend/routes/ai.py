"""
AI routes — chat, command, classify-apps, analyze-usage, notification-text, decompose-task.
"""

import json as _json
import logging
import os
import time
from collections import defaultdict, deque
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException

from ai.llm_provider import llm
from ai.ollama_client import ollama
from ai.prompts import (
    CRISIS_RESPONSE,
    check_crisis,
    get_assistant_system_prompt,
    get_system_prompt,
)
from core.security import get_current_user
from models.orm import UserModel
from schemas import (
    AICommandRequest,
    AnalyzeUsageRequest,
    ChatRequest,
    ChatResponse,
    ClassifyAppsRequest,
    DailyPlanRequest,
    DailyPlanResponse,
    NotificationTextRequest,
    PredictiveBlockingRequest,
    PredictiveBlockingResponse,
    SentimentCheckinRequest,
    SentimentCheckinResponse,
    TaskDecompositionRequest,
)
from services.app_classifier import app_classifier

router = APIRouter(prefix="/ai", tags=["ai"])

logger = logging.getLogger("nora.ai")

# ─── Auth + Rate Limiting ───
# In-memory sliding-window rate limit per user (60 req/min).
# Ephemeral per process — fine for a single-instance deployment.

_RATE_LIMIT_WINDOW_SECONDS = 60.0
_RATE_LIMIT_MAX_REQUESTS = 60
_rate_limit_buckets: dict[int, deque] = defaultdict(deque)


def require_ai_user(
    current_user: UserModel = Depends(get_current_user),
) -> UserModel:
    """Authenticated AI access + per-user sliding-window rate limit."""
    now = time.monotonic()
    bucket = _rate_limit_buckets[current_user.id]
    cutoff = now - _RATE_LIMIT_WINDOW_SECONDS
    while bucket and bucket[0] <= cutoff:
        bucket.popleft()
    if len(bucket) >= _RATE_LIMIT_MAX_REQUESTS:
        raise HTTPException(status_code=429, detail="AI rate limit exceeded. Try again in a minute.")
    bucket.append(now)
    return current_user


# ─── Action Validation ───

VALID_ACTION_TYPES = {
    "scan_apps",
    "block_apps",
    "unblock_apps",
    "start_focus",
    "show_usage",
    "show_recommendations",
    "analyze_usage",
}
BLOCKED_EMERGENCY_PACKAGES = {
    "com.android.phone",
    "com.android.dialer",
    "com.apple.mobilephone",
    "com.google.android.apps.maps",
}


def _validate_actions(raw_actions: list[dict]) -> list[dict]:
    """Validate raw action dicts against safety rules. Returns only valid actions."""
    validated = []
    for raw in raw_actions:
        action_name = raw.get("action")
        if action_name not in VALID_ACTION_TYPES:
            logger.warning("Action validation failed: unknown action %s", action_name)
            continue
        packages = raw.get("packages", [])
        for pkg in packages:
            if pkg in BLOCKED_EMERGENCY_PACKAGES:
                logger.warning("Action validation failed: cannot block emergency app %s", pkg)
                break
        else:
            minutes = raw.get("minutes", 25)
            if isinstance(minutes, int) and 1 <= minutes <= 120:
                validated.append(raw)
            else:
                logger.warning("Action validation failed: invalid minutes %r", minutes)
    return validated


def _parse_actions_from_response(response: str) -> list[dict]:
    """Parse AI response for structured actions.

    Strategy:
      1. Extract JSON objects from the response (LLM is prompted to output JSON actions).
      2. Keep only objects that contain an "action" key with a valid action type.
      3. If no JSON actions found, fall back to keyword matching for simple intents.
    """
    actions = []

    # ── Pass 1: Extract JSON action blocks from the response ──
    i = 0
    while i < len(response):
        brace = response.find("{", i)
        if brace == -1:
            break

        # Find matching closing brace (handles nested braces inside arrays)
        depth = 0
        j = brace
        while j < len(response):
            if response[j] == "{":
                depth += 1
            elif response[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1

        if depth == 0:
            candidate = response[brace : j + 1]
            try:
                parsed = _json.loads(candidate)
                if isinstance(parsed, dict) and "action" in parsed:
                    actions.append(parsed)
            except _json.JSONDecodeError:
                pass  # Not valid JSON — skip
            i = j + 1
        else:
            i += 1

    # ── Pass 2: Keyword fallback (only if no JSON actions found) ──
    if not actions:
        response_lower = response.lower()

        if any(phrase in response_lower for phrase in ["scan your apps", "scan installed", "check your apps"]):
            actions.append({"action": "scan_apps"})

        if any(phrase in response_lower for phrase in ["start focus", "begin focus", "start a focus session"]):
            actions.append({"action": "start_focus", "minutes": 25})

        if any(
            phrase in response_lower
            for phrase in ["usage report", "screen time", "usage summary", "show usage"]
        ):
            actions.append({"action": "show_usage"})

        if any(phrase in response_lower for phrase in ["show recommendation", "ai recommendation"]):
            actions.append({"action": "show_recommendations"})

    return actions


# ─── Routes ───


@router.post("/chat", response_model=ChatResponse)
async def ai_chat(
    request: ChatRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """Chat with Nora AI — powered by multi-provider LLM fallback."""

    # SAFETY: Children (1-6) do NOT chat with the LLM
    if request.age_group in ("child", "baby"):
        return ChatResponse(
            response="Nora Little is a learning companion for young children. "
            "Let's read a story or learn colors together!",
            model="none",
        )

    # Pick best model for age group (call once, reuse)
    model = ollama.get_model_for_age_group(request.age_group)

    # CRISIS DETECTION: Check user input for crisis keywords
    if check_crisis(request.message):
        return ChatResponse(response=CRISIS_RESPONSE, model=model)

    # Build messages with age-appropriate system prompt
    system_prompt = get_system_prompt(request.age_group)
    messages = [{"role": "system", "content": system_prompt}]

    # Add conversation history
    for msg in request.conversation_history:
        messages.append({"role": msg.get("role", "user"), "content": msg.get("content", "")})

    # Add current user message
    messages.append({"role": "user", "content": request.message})

    # Get response from Ollama
    try:
        response = await ollama.chat(messages, temperature=0.7)

        # CRISIS DETECTION: Check AI response for crisis content
        if check_crisis(response):
            return ChatResponse(response=CRISIS_RESPONSE, model=model)

        return ChatResponse(response=response, model=model)
    except Exception as e:
        logger.error("AI chat failed: %s", e, exc_info=True)
        return ChatResponse(
            response=f"I'm having trouble connecting to my brain right now. All LLM providers failed. Error: {str(e)}",
            model=model,
        )


@router.post("/command")
async def ai_command(
    request: AICommandRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """
    AI Digital Assistant — processes commands and executes actions.
    The AI can: scan apps, block apps, analyze usage, start focus, etc.
    """

    # SAFETY: Children (1-6) do NOT use the digital assistant
    if request.age_group in ("child", "baby"):
        return {
            "response": "Nora Little is a learning companion for young children. "
            "For device management, please use the parent's account.",
            "model": "none",
            "actions": [],
        }

    # Pick best model for age group (call once, reuse)
    model = ollama.get_model_for_age_group(request.age_group)

    # CRISIS DETECTION: Check user input for crisis keywords
    if check_crisis(request.command):
        return {
            "response": CRISIS_RESPONSE,
            "model": model,
            "actions": [],
            "crisis_detected": True,
        }

    system_prompt = get_assistant_system_prompt(request.age_group, request.context)
    messages = [{"role": "system", "content": system_prompt}]

    for msg in request.conversation_history:
        messages.append({"role": msg.get("role", "user"), "content": msg.get("content", "")})

    messages.append({"role": "user", "content": request.command})

    try:
        response = await ollama.chat(messages, temperature=0.5)

        # CRISIS DETECTION: Check AI response for crisis content too
        if check_crisis(response):
            return {
                "response": CRISIS_RESPONSE,
                "model": model,
                "actions": [],
                "crisis_detected": True,
            }

        # Parse response for actions
        raw_actions = _parse_actions_from_response(response)

        # VALIDATE actions against safety rules (model output is untrusted)
        validated_actions = _validate_actions(raw_actions)

        return {
            "response": response,
            "model": model,
            "actions": validated_actions,
        }
    except Exception as e:
        logger.error("AI command failed: %s", e, exc_info=True)
        return {
            "response": f"I had trouble processing that. Error: {str(e)}",
            "model": model,
            "actions": [],
        }


@router.post("/classify-apps")
def classify_apps(
    request: ClassifyAppsRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """AI-powered app classification and blocking recommendations."""
    return app_classifier.classify_apps(request.apps, request.age_group)


@router.post("/analyze-usage")
def analyze_usage(
    request: AnalyzeUsageRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """AI-powered usage analysis with insights and recommendations."""
    return app_classifier.analyze_usage(request.usage_data, request.age_group)


@router.post("/notification-text")
async def generate_notification_text(
    request: NotificationTextRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """
    Generate AI-powered notification text for different app events.
    Falls back to default texts if LLM is unavailable.
    """
    event_descriptions = {
        "focus_start": "A focus/session timer is starting now",
        "focus_end": "A focus/session timer has just ended",
        "focus_break": "It's break time between focus sessions",
        "habit_reminder": f"Remind about a habit: {request.context.get('habit_name', 'daily habit')}",
        "hard_cap_warning": "User is approaching their daily screen time limit (80-90% used)",
        "hard_cap_reached": "User has hit their daily screen time hard cap",
        "accountability_alert": "Accountability lock check — remind user to stay on track",
        "daily_motivation": "Send a daily morning motivation message to start the day",
        "session_complete": "A focus session was completed successfully",
        "custom": f"Custom notification: {request.context.get('message', 'Nora has an update')}",
    }

    NOTIFICATION_PROMPTS = {
        "kid": """Generate a short, fun notification message for a kid (ages 6-12).
Rules:
- Use simple, encouraging language
- Add a fun emoji
- Keep it under 15 words
- Be enthusiastic and positive
- Never mention screen time limits negatively""",
        "teen": """Generate a short, motivating notification message for a teenager (ages 12-18).
Rules:
- Sound like a supportive friend, not a parent
- Use casual, modern language
- Keep it under 20 words
- Be real and authentic
- Include one relevant emoji""",
        "adult": """Generate a short, professional notification message for an adult (18+).
Rules:
- Be concise and actionable
- Sound like a focused productivity partner
- Keep it under 20 words
- Use professional but warm tone
- Optional: include one subtle emoji""",
    }

    event_desc = event_descriptions.get(request.event_type, request.event_type)
    personality = NOTIFICATION_PROMPTS.get(request.age_group, NOTIFICATION_PROMPTS["adult"])

    prompt = f"""{personality}

EVENT: {event_desc}

CONTEXT: {_json.dumps(request.context) if request.context else 'None'}

Generate ONLY the notification text. No quotes, no explanation. Just the message."""

    try:
        response = await ollama.chat(
            [{"role": "user", "content": prompt}],
            temperature=0.8,
        )
        # Clean up the response — remove quotes, extra whitespace
        clean_text = response.strip().strip('"').strip("'").strip()
        # Truncate if too long
        if len(clean_text) > 100:
            clean_text = clean_text[:97] + "..."
        return {"text": clean_text, "event_type": request.event_type}
    except Exception as e:
        # LLM failed — return a sensible default
        logger.warning("Notification text generation failed: %s", e)
        defaults = {
            "focus_start": "Time to focus! Your session starts now.",
            "focus_end": "Great work! Your focus session is complete.",
            "focus_break": "Break time! Stretch and recharge.",
            "habit_reminder": "Don't forget your daily habits!",
            "hard_cap_warning": "Heads up — you're approaching your screen time limit.",
            "hard_cap_reached": "You've reached your daily screen time cap.",
            "accountability_alert": "Stay on track! You've got this.",
            "daily_motivation": "Today is a new opportunity to focus and grow.",
            "session_complete": "Session complete! Keep up the great work.",
            "custom": "Nora has an update for you.",
        }
        return {
            "text": defaults.get(request.event_type, "Nora has an update."),
            "event_type": request.event_type,
        }


@router.post("/decompose-task")
async def decompose_task(
    request: TaskDecompositionRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """
    Decompose a broad task into Pomodoro-sized subtasks (15-25 min each).
    """
    # SAFETY: Young children do NOT use task decomposition
    if request.age_group in ("child", "baby"):
        return {
            "success": True,
            "subtasks": [],
            "original_task": request.task,
            "total_estimated_minutes": 0,
            "tip": "Ask a grown-up to help break big jobs into little ones!",
            "provider": "none",
        }

    from ai.task_decomposer import decompose_task as _decompose

    result = await _decompose(
        task=request.task,
        age_group=request.age_group,
    )

    if result["success"]:
        return {
            "success": True,
            "subtasks": result["data"].get("subtasks", []),
            "original_task": result["data"].get("original_task", request.task),
            "total_estimated_minutes": result["data"].get("total_estimated_minutes", 0),
            "tip": result["data"].get("tip", ""),
            "provider": result.get("provider", "unknown"),
        }
    else:
        raise HTTPException(
            status_code=500,
            detail=f"Task decomposition failed: {result.get('error', 'unknown')}",
        )


# ─── Feature 1: Smart Daily Plans ───


DAILY_PLAN_PROMPT = """You are a smart daily planner AI. Create an optimized schedule based on the user's goals, energy patterns, and available time.

RULES:
- Each block should be 15-60 minutes
- Include focus blocks, breaks, and transition time
- Match high-energy tasks to peak energy times
- Include short breaks between focus blocks (5-10 min)
- Add a longer break (15-30 min) every 2 hours
- Order: deep work first, admin tasks later
- Be realistic — don't over-schedule

OUTPUT FORMAT (JSON only):
{
  "plan": [
    {
      "time": "09:00",
      "end_time": "09:25",
      "type": "focus",
      "title": "Task name",
      "description": "Brief description",
      "energy_level": "high"
    }
  ],
  "summary": "Brief overview of the day",
  "total_focus_minutes": 180,
  "total_break_minutes": 45,
  "tip": "One practical tip for the day"
}

Respond with ONLY the JSON."""


@router.post("/daily-plan")
async def generate_daily_plan(
    request: DailyPlanRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """AI-generated smart daily schedule based on goals and energy patterns."""

    if request.age_group in ("child", "baby"):
        return {
            "success": True,
            "plan": [
                {"time": "09:00", "end_time": "09:20", "type": "focus", "title": "Learning Time", "description": "Fun educational activities", "energy_level": "high"},
                {"time": "09:20", "end_time": "09:30", "type": "break", "title": "Snack Break", "description": "Healthy snack and stretch", "energy_level": "low"},
                {"time": "09:30", "end_time": "09:50", "type": "focus", "title": "Creative Play", "description": "Drawing, building, or crafting", "energy_level": "medium"},
                {"time": "09:50", "end_time": "10:00", "type": "break", "title": "Movement Break", "description": "Quick dance or stretch", "energy_level": "low"},
            ],
            "summary": "A fun learning day with creative activities!",
            "total_focus_minutes": 40,
            "total_break_minutes": 20,
            "tip": "Take breaks to stay energized!",
        }

    commitments_text = ""
    if request.existing_commitments:
        commitments_text = "\nExisting commitments:\n" + "\n".join(
            f"- {c.get('title', 'Event')} at {c.get('time', 'TBD')}"
            for c in request.existing_commitments
        )

    goals_text = ", ".join(request.goals) if request.goals else "general productivity"

    prompt = f"""{DAILY_PLAN_PROMPT}

USER PROFILE:
- Age group: {request.age_group}
- Available hours: {request.available_hours}
- Energy pattern: {request.energy_pattern}
- Goals: {goals_text}
{commitments_text}

Create an optimized daily schedule."""

    try:
        response = await ollama.chat(
            [{"role": "user", "content": prompt}],
            temperature=0.4,
        )

        parsed = _parse_json_from_response(response)
        if parsed and "plan" in parsed:
            return {
                "success": True,
                "plan": parsed["plan"],
                "summary": parsed.get("summary", ""),
                "total_focus_minutes": parsed.get("total_focus_minutes", 0),
                "total_break_minutes": parsed.get("total_break_minutes", 0),
                "tip": parsed.get("tip", ""),
            }
    except Exception as e:
        logger.warning("Daily plan LLM path failed, using fallback: %s", e)

    # Fallback: generate a basic plan
    return {
        "success": True,
        "plan": _generate_fallback_plan(request.available_hours, request.energy_pattern),
        "summary": f"A productive {request.age_group}-focused day with balanced work and breaks.",
        "total_focus_minutes": int(request.available_hours * 60 * 0.6),
        "total_break_minutes": int(request.available_hours * 60 * 0.4),
        "tip": "Start with your most important task when energy is highest.",
    }


def _parse_json_from_response(response: str) -> Optional[dict]:
    """Extract JSON from LLM response."""
    text = response.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        if lines[-1].strip() == "```":
            lines = lines[1:-1]
        else:
            lines = lines[1:]
        text = "\n".join(lines).strip()
    try:
        return _json.loads(text)
    except _json.JSONDecodeError:
        pass
    start = text.find("{")
    end = text.rfind("}") + 1
    if start >= 0 and end > start:
        try:
            return _json.loads(text[start:end])
        except _json.JSONDecodeError:
            pass
    return None


def _generate_fallback_plan(available_hours: float, energy_pattern: str) -> list[dict]:
    """Generate a basic fallback plan when LLM fails."""
    blocks = []
    start_hour = 9 if energy_pattern != "night_owl" else 11
    total_minutes = int(available_hours * 60)
    elapsed = 0

    while elapsed < total_minutes - 25:
        focus_duration = min(25, total_minutes - elapsed - 5)
        break_duration = 5

        # Properly compute start time
        start_h = start_hour + (elapsed // 60)
        start_m = elapsed % 60
        # Properly compute end time (handles minute overflow)
        end_total = elapsed + focus_duration
        end_h = start_hour + (end_total // 60)
        end_m = end_total % 60

        blocks.append({
            "time": f"{start_h:02d}:{start_m:02d}",
            "end_time": f"{end_h:02d}:{end_m:02d}",
            "type": "focus",
            "title": "Focus Session",
            "description": f"Pomodoro block — {focus_duration} minutes",
            "energy_level": "high" if elapsed < total_minutes * 0.5 else "medium",
        })
        elapsed += focus_duration

        if elapsed < total_minutes - 10:
            break_start_h = start_hour + (elapsed // 60)
            break_start_m = elapsed % 60
            break_end = elapsed + break_duration
            break_end_h = start_hour + (break_end // 60)
            break_end_m = break_end % 60

            blocks.append({
                "time": f"{break_start_h:02d}:{break_start_m:02d}",
                "end_time": f"{break_end_h:02d}:{break_end_m:02d}",
                "type": "break",
                "title": "Short Break",
                "description": "Stretch and recharge",
                "energy_level": "low",
            })
            elapsed += break_duration

    return blocks


# ─── Feature 2: Sentiment-Aware Check-ins ───


@router.post("/sentiment-check")
async def sentiment_check(
    request: SentimentCheckinRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """Analyze user sentiment and provide empathetic, age-appropriate response."""

    if request.age_group in ("child", "baby"):
        return {
            "success": True,
            "sentiment": "positive",
            "confidence": 0.8,
            "response": "Hey there! You're doing awesome! Keep smiling! 😊",
            "suggestion": "Time for a fun activity!",
            "mood_score": 7,
        }

    sentiment_prompt = f"""Analyze the sentiment of this message and respond empathetically.

USER MESSAGE: "{request.message}"
AGE GROUP: {request.age_group}

Respond in JSON format:
{{
  "sentiment": "positive|negative|neutral|stressed|motivated",
  "confidence": 0.0-1.0,
  "response": "Empathetic, age-appropriate response (1-2 sentences)",
  "suggestion": "One actionable suggestion based on their mood",
  "mood_score": 1-10
}}

Rules:
- Kid (6-12): Fun, encouraging, use simple words
- Teen (12-18): Casual, supportive friend tone
- Adult (18+): Professional, warm productivity partner
- If stressed: acknowledge feelings, suggest a break
- If motivated: channel energy into a task
- If negative: offer support, don't dismiss feelings

Respond with ONLY the JSON."""

    try:
        response = await ollama.chat(
            [{"role": "user", "content": sentiment_prompt}],
            temperature=0.6,
        )

        parsed = _parse_json_from_response(response)
        if parsed and "sentiment" in parsed:
            return {
                "success": True,
                "sentiment": parsed["sentiment"],
                "confidence": min(1.0, max(0.0, parsed.get("confidence", 0.7))),
                "response": parsed.get("response", "I hear you!"),
                "suggestion": parsed.get("suggestion", ""),
                "mood_score": max(1, min(10, parsed.get("mood_score", 5))),
            }
    except Exception as e:
        logger.warning("Sentiment LLM path failed, using fallback: %s", e)

    # Fallback sentiment analysis
    msg_lower = request.message.lower()
    positive_words = ["good", "great", "awesome", "happy", "excited", "productive", "amazing", "love", "fantastic"]
    negative_words = ["tired", "stressed", "overwhelmed", "anxious", "frustrated", "sad", "exhausted", "hate", "terrible"]
    motivated_words = ["motivated", "ready", "let's", "going to", "will do", "determined", "focus"]

    pos_count = sum(1 for w in positive_words if w in msg_lower)
    neg_count = sum(1 for w in negative_words if w in msg_lower)
    mot_count = sum(1 for w in motivated_words if w in msg_lower)

    if neg_count > pos_count:
        sentiment = "stressed" if neg_count > 1 else "negative"
        mood = max(2, 5 - neg_count)
        response_text = "I hear you. It's okay to feel this way. Want to take a short break?"
        suggestion = "Try a 5-minute breathing exercise or a quick walk."
    elif mot_count > pos_count:
        sentiment = "motivated"
        mood = min(9, 6 + mot_count)
        response_text = "Love the energy! Let's channel that into something productive."
        suggestion = "Start with your most important task right now."
    elif pos_count > 0:
        sentiment = "positive"
        mood = min(8, 6 + pos_count)
        response_text = "That's great to hear! Keep up the momentum!"
        suggestion = "Use this positive energy to tackle a challenging task."
    else:
        sentiment = "neutral"
        mood = 5
        response_text = "Thanks for sharing. How can I help you today?"
        suggestion = "Check your daily plan for what's next."

    return {
        "success": True,
        "sentiment": sentiment,
        "confidence": 0.6,
        "response": response_text,
        "suggestion": suggestion,
        "mood_score": mood,
    }


# ─── Feature 3: Predictive App Blocking ───


PREDICTIVE_PROMPT = """You are a predictive digital wellness AI. Based on the user's patterns, predict when they might procrastinate and suggest proactive blocks.

RULES:
- Predict based on time of day and historical patterns
- Suggest blocking BEFORE procrastination happens
- Be specific about which apps and when
- Consider the user's age group for appropriate limits

OUTPUT FORMAT (JSON only):
{
  "predictions": [
    {
      "time": "14:00-15:00",
      "risk_level": "high|medium|low",
      "reason": "After lunch dip — historically high social media usage",
      "apps_at_risk": ["instagram", "tiktok"],
      "suggestion": "Start a focus session or take a walk"
    }
  ],
  "proactive_nudges": [
    {
      "trigger_time": "13:45",
      "message": "Heads up — your afternoon scroll window is coming up. Want to start a focus session?",
      "action": "start_focus"
    }
  ],
  "suggested_block": [
    {
      "packageName": "com.instagram.android",
      "block_until": "15:00",
      "reason": "High usage historically at this time"
    }
  ],
  "summary": "Based on your patterns, 2-4 PM is your highest risk window. I suggest blocking social media during that time."
}

Respond with ONLY the JSON."""


@router.post("/predictive-blocking")
async def predictive_blocking(
    request: PredictiveBlockingRequest,
    current_user: UserModel = Depends(require_ai_user),
):
    """Predict when user might procrastinate and suggest proactive blocks."""

    if request.age_group in ("child", "baby"):
        return {
            "success": True,
            "predictions": [],
            "proactive_nudges": [],
            "suggested_block": [],
            "summary": "No predictive blocking needed for children. Parent controls are active.",
        }

    usage_summary = ""
    if request.recent_usage:
        usage_summary = f"\nRecent usage: {_json.dumps(request.recent_usage, indent=2)}"

    prompt = f"""{PREDICTIVE_PROMPT}

USER PROFILE:
- Age group: {request.age_group}
- Current time: {request.current_time or 'not specified'}
- Day of week: {request.day_of_week or 'not specified'}
- Installed apps: {len(request.installed_apps)} apps
{usage_summary}

Analyze patterns and predict procrastination windows."""

    try:
        response = await ollama.chat(
            [{"role": "user", "content": prompt}],
            temperature=0.5,
        )

        parsed = _parse_json_from_response(response)
        if parsed and "predictions" in parsed:
            return {
                "success": True,
                "predictions": parsed["predictions"],
                "proactive_nudges": parsed.get("proactive_nudges", []),
                "suggested_block": parsed.get("suggested_block", []),
                "summary": parsed.get("summary", ""),
            }
    except Exception as e:
        logger.warning("Predictive blocking LLM path failed, using fallback: %s", e)

    # Fallback: rule-based predictions
    return _generate_fallback_predictions(request.age_group, request.current_time, request.recent_usage)


def _generate_fallback_predictions(age_group: str, current_time: str, recent_usage: dict) -> dict:
    """Generate rule-based predictions when LLM fails."""
    social_time = recent_usage.get("socialMediaMinutes", 0)
    total_time = recent_usage.get("totalScreenTimeMinutes", 0)

    predictions = []
    nudges = []
    blocks = []

    # High social media usage prediction
    if social_time > 60:
        predictions.append({
            "time": "next hour",
            "risk_level": "high",
            "reason": f"Already at {social_time}m social media today — trending toward excess",
            "apps_at_risk": ["instagram", "tiktok", "twitter"],
            "suggestion": "Consider switching to a focus session",
        })
        nudges.append({
            "trigger_time": "now",
            "message": f"You've spent {social_time}m on social media. Want to start a focus session?",
            "action": "start_focus",
        })

    # Afternoon dip prediction
    if current_time:
        try:
            hour = int(current_time.split(":")[0]) if ":" in current_time else -1
            if 13 <= hour <= 15:
                predictions.append({
                    "time": f"{hour}:00-{hour+1}:00",
                    "risk_level": "medium",
                    "reason": "Afternoon energy dip — historically high distraction window",
                    "apps_at_risk": ["youtube", "reddit", "news"],
                    "suggestion": "Take a short walk or start a light task",
                })
        except (ValueError, IndexError):
            pass

    # Total screen time warning
    if total_time > 180:
        predictions.append({
            "time": "now",
            "risk_level": "high",
            "reason": f"Total screen time at {total_time}m — approaching daily limit",
            "apps_at_risk": [],
            "suggestion": "Consider reducing screen time for the rest of the day",
        })

    if not predictions:
        predictions.append({
            "time": "today",
            "risk_level": "low",
            "reason": "Usage patterns look healthy",
            "apps_at_risk": [],
            "suggestion": "Keep up the good work!",
        })

    summary = f"Found {len(predictions)} prediction(s). "
    high_risk = [p for p in predictions if p["risk_level"] == "high"]
    if high_risk:
        summary += f"{len(high_risk)} high-risk window(s) detected."
    else:
        summary += "No high-risk windows detected."

    return {
        "success": True,
        "predictions": predictions,
        "proactive_nudges": nudges,
        "suggested_block": blocks,
        "summary": summary,
    }


@router.get("/health")
async def ai_health():
    """Check which LLM providers are available."""
    provider_status = await llm.is_available()
    any_available = any(provider_status.values())
    return {
        "providers": provider_status,
        "ollama_running": any_available,  # backward compat: True if ANY provider works
        "llm_available": any_available,
        "active_provider": llm.preferred_provider,
        "groq_model": llm.groq_model,
        "gemini_model": llm.gemini_model,
        "cloudflare_model": llm.cloudflare_model,
        "ollama_base_url": llm.ollama_base_url,
        "ollama_colab_url": llm.ollama_colab_url or "(not set)",
    }
