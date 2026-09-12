"""
AI Task Decomposition — Break complex tasks into Pomodoro-sized subtasks.

Uses the same free LLM providers (Groq, Gemini, Cloudflare, Ollama) to:
  1. Take a broad task description
  2. Break it into 15-25 minute subtasks
  3. Auto-suggest Pomodoro focus blocks

Prompt is designed to produce structured JSON output for reliable parsing.
"""

import json
import os
import httpx
from typing import Optional


DECOMPOSITION_PROMPT = """You are a productivity AI assistant. Break down the user's task into small, actionable subtasks that each take 15-25 minutes.

RULES:
- Each subtask must be completable in 15-25 minutes
- Use action verbs (Write, Review, Draft, Research, etc.)
- Order subtasks logically (dependencies first)
- Assign priority: 1=critical, 2=important, 3=nice-to-have
- Keep subtask titles short (under 60 characters)
- Aim for 3-6 subtasks per task
- Do NOT add subtasks the user didn't ask for

OUTPUT FORMAT (JSON only, no markdown):
{
  "original_task": "the user's original task",
  "subtasks": [
    {
      "title": "Subtask title",
      "priority": 1,
      "estimated_minutes": 20,
      "description": "Brief description of what to do"
    }
  ],
  "total_estimated_minutes": 80,
  "tip": "One practical tip for completing this task"
}

EXAMPLE:
User input: "Write quarterly report"
Output:
{
  "original_task": "Write quarterly report",
  "subtasks": [
    {"title": "Gather Q3 metrics and data", "priority": 1, "estimated_minutes": 25, "description": "Pull sales, growth, and KPI numbers"},
    {"title": "Draft executive summary", "priority": 1, "estimated_minutes": 20, "description": "Write the high-level overview section"},
    {"title": "Write revenue analysis section", "priority": 1, "estimated_minutes": 25, "description": "Detailed breakdown of revenue streams"},
    {"title": "Create charts and visuals", "priority": 2, "estimated_minutes": 20, "description": "Build charts for key metrics"},
    {"title": "Review and proofread", "priority": 2, "estimated_minutes": 15, "description": "Final review for errors and clarity"}
  ],
  "total_estimated_minutes": 105,
  "tip": "Start with data gathering — everything else flows from having the numbers ready."
}

Respond with ONLY the JSON. No explanation, no markdown, no code fences."""


async def decompose_task(
    task: str,
    age_group: str = "adult",
    provider: str = "auto",
) -> dict:
    """
    Decompose a task into subtasks using the free LLM provider chain.

    Args:
        task: The task to decompose
        age_group: User's age group (affects response style)
        provider: "auto" or specific provider name

    Returns:
        dict with subtasks list, or error dict
    """
    from ai.llm_provider import llm

    messages = [
        {"role": "system", "content": DECOMPOSITION_PROMPT},
        {"role": "user", "content": f"Break this task into subtasks: {task}"},
    ]

    try:
        result = await llm.chat(messages, temperature=0.3)

        # Handle dict response from new provider format
        if isinstance(result, dict):
            text = result.get("response", "")
        else:
            text = result

        # Parse JSON from response
        parsed = _parse_json_response(text)
        if parsed:
            return {
                "success": True,
                "data": parsed,
                "provider": result.get("provider", "unknown") if isinstance(result, dict) else "unknown",
            }
        else:
            return {
                "success": False,
                "error": "Could not parse LLM response",
                "raw": text[:500],
            }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


def _parse_json_response(text: str) -> Optional[dict]:
    """Try to parse JSON from LLM response, handling common issues."""
    # Clean up common LLM artifacts
    text = text.strip()

    # Remove markdown code fences if present
    if text.startswith("```"):
        lines = text.split("\n")
        # Remove first and last lines (``` markers)
        if lines[-1].strip() == "```":
            lines = lines[1:-1]
        else:
            lines = lines[1:]
        text = "\n".join(lines).strip()

    # Try direct parse
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Try to find JSON object in text
    start = text.find("{")
    end = text.rfind("}") + 1
    if start >= 0 and end > start:
        try:
            return json.loads(text[start:end])
        except json.JSONDecodeError:
            pass

    return None
