"""
Groq API - Basic Chat Example
Free tier: 30 RPM, 14,400 requests/day
No credit card required

Setup:
  1. pip install -r requirements.txt
  2. Copy .env.example to .env and add your API key
  3. Get free key at: https://console.groq.com/keys
"""

import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))


def chat(message: str, model: str = None) -> str:
    """Send a message and get a response."""
    model = model or os.getenv("GROQ_MODEL", "llama3-8b-8192")

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": message},
        ],
        temperature=0.7,
        max_tokens=1024,
    )

    return response.choices[0].message.content


def chat_with_history(messages: list, model: str = None) -> str:
    """Chat with conversation history."""
    model = model or os.getenv("GROQ_MODEL", "llama3-8b-8192")

    response = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=0.7,
        max_tokens=1024,
    )

    return response.choices[0].message.content


# --- Available Free Models ---
FREE_MODELS = {
    # Text models
    "llama3-8b-8192": "Llama 3 8B (fast, general purpose)",
    "llama3-70b-8192": "Llama 3 70B (slower, more capable)",
    "mixtral-8x7b-32768": "Mixtral 8x7B (long context, 32K)",
    "gemma-7b-it": "Gemma 7B (Google, instruction-tuned)",

    # Multimodal
    "llava-v1.5-7b-4096": "LLaVA 1.5 (vision + text)",
}

if __name__ == "__main__":
    print("=== Groq Free Tier Chat ===")
    print(f"Models available: {len(FREE_MODELS)}\n")

    # Simple chat
    response = chat("What is the capital of France?")
    print(f"Response: {response}\n")

    # With conversation history
    messages = [
        {"role": "system", "content": "You are a Python expert."},
        {"role": "user", "content": "Write a one-liner to reverse a string."},
    ]
    response = chat_with_history(messages)
    print(f"Python expert: {response}")
