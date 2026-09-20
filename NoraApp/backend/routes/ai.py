"""
AI routes — chat, command, classify-apps, analyze-usage, notification-text, decompose-task.
"""

import json as _json
import os
from typing import Optional

from fastapi import APIRouter, HTTPException

from ai.llm_provider import llm
from ai.ollama_client import ollama
from ai.prompts import (
    CRISIS_RESPONSE,
    check_crisis,
    get_assistant_system_prompt,
    get_system_prompt,
)
from schemas import (
    AICommandRequest,
    ChatRequest,
    ChatResponse,
    ClassifyAppsRequest,
    NotificationTextRequest,
    TaskDecompositionRequest,
)
from services.app_classifier import app_classifier

router = APIRouter(prefix="/ai", tags=["ai"])

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
            print(f"[ACTION VALIDATION FAILED] Unknown action: {action_name}")
            continue
        packages = raw.get("packages", [])
        for pkg in packages:
            if pkg in BLOCKED_EMERGENCY_PACKAGES:
                print(f"[ACTION VALIDATION FAILED] Cannot block emergency app: {pkg}")
                break
        else:
            minutes = raw.get("minutes", 25)
            if isinstance(minutes, int) and 1 <= minutes <= 120:
                validated.append(raw)
            else:
                print(f"[ACTION VALIDATION FAILED] Invalid minutes: {minutes}")
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
async def ai_chat(request: ChatRequest):
    """Chat with Nora AI — powered by multi-provider LLM fallback."""

    # SAFETY: Children (1-6) do NOT chat with the LLM
    if request.age_group == "child":
        return ChatResponse(
            response="Nora Little is a learning companion for young children. "
            "Let's read a story or learn colors together!",
            model="none",
        )

    # CRISIS DETECTION: Check user input for crisis keywords
    if check_crisis(request.message):
        return ChatResponse(
            response=CRISIS_RESPONSE,
            model=ollama.get_model_for_age_group(request.age_group),
        )

    # Build messages with age-appropriate system prompt
    system_prompt = get_system_prompt(request.age_group)
    messages = [{"role": "system", "content": system_prompt}]

    # Add conversation history
    for msg in request.conversation_history:
        messages.append({"role": msg.get("role", "user"), "content": msg.get("content", "")})

    # Add current user message
    messages.append({"role": "user", "content": request.message})

    # Pick best model for age group
    model = ollama.get_model_for_age_group(request.age_group)

    # Get response from Ollama
    try:
        response = await ollama.chat(messages, temperature=0.7)

        # CRISIS DETECTION: Check AI response for crisis content
        if check_crisis(response):
            return ChatResponse(response=CRISIS_RESPONSE, model=model)

        return ChatResponse(response=response, model=model)
    except Exception as e:
        return ChatResponse(
            response=f"I'm having trouble connecting to my brain right now. All LLM providers failed. Error: {str(e)}",
            model=model,
        )


@router.post("/command")
async def ai_command(request: AICommandRequest):
    """
    AI Digital Assistant — processes commands and executes actions.
    The AI can: scan apps, block apps, analyze usage, start focus, etc.
    """

    # SAFETY: Children (1-6) do NOT use the digital assistant
    if request.age_group == "child":
        return {
            "response": "Nora Little is a learning companion for young children. "
            "For device management, please use the parent's account.",
            "model": "none",
            "actions": [],
        }

    # CRISIS DETECTION: Check user input for crisis keywords
    if check_crisis(request.command):
        return {
            "response": CRISIS_RESPONSE,
            "model": ollama.get_model_for_age_group(request.age_group),
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
                "model": ollama.get_model_for_age_group(request.age_group),
                "actions": [],
                "crisis_detected": True,
            }

        # Parse response for actions
        raw_actions = _parse_actions_from_response(response)

        # VALIDATE actions against safety rules (model output is untrusted)
        validated_actions = _validate_actions(raw_actions)

        return {
            "response": response,
            "model": ollama.get_model_for_age_group(request.age_group),
            "actions": validated_actions,
        }
    except Exception as e:
        return {
            "response": f"I had trouble processing that. Error: {str(e)}",
            "model": ollama.get_model_for_age_group(request.age_group),
            "actions": [],
        }


@router.post("/classify-apps")
def classify_apps(request: ClassifyAppsRequest):
    """AI-powered app classification and blocking recommendations."""
    return app_classifier.classify_apps(request.apps, request.age_group)


@router.post("/analyze-usage")
def analyze_usage(request: ClassifyAppsRequest):
    """AI-powered usage analysis with insights and recommendations."""
    return app_classifier.analyze_usage(request.usage_data, request.age_group)


@router.post("/notification-text")
async def generate_notification_text(request: NotificationTextRequest):
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
async def decompose_task(request: TaskDecompositionRequest):
    """
    Decompose a broad task into Pomodoro-sized subtasks (15-25 min each).
    """
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
