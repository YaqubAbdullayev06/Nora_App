"""
Groq API - Streaming Chat Example
Real-time streaming responses from Groq's free tier.
"""

import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))


def chat_stream(message: str, model: str = None):
    """Stream response token by token."""
    model = model or os.getenv("GROQ_MODEL", "llama3-8b-8192")

    stream = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": message},
        ],
        temperature=0.7,
        max_tokens=1024,
        stream=True,
    )

    print("", end="", flush=True)
    for chunk in stream:
        if chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)
    print()  # newline at end


def chat_stream_with_history(messages: list, model: str = None):
    """Stream with conversation history."""
    model = model or os.getenv("GROQ_MODEL", "llama3-8b-8192")

    stream = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=0.7,
        max_tokens=1024,
        stream=True,
    )

    for chunk in stream:
        if chunk.choices[0].delta.content:
            yield chunk.choices[0].delta.content


if __name__ == "__main__":
    print("=== Groq Streaming Chat ===\n")

    # Basic streaming
    print("Q: Explain quantum computing in 3 sentences")
    print("A: ", end="")
    chat_stream("Explain quantum computing in 3 sentences")

    print("\n---\n")

    # Streaming with history
    print("Q: Now explain it like I'm 5 years old")
    print("A: ", end="")
    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain quantum computing in 3 sentences"},
    ]
    for token in chat_stream_with_history(messages):
        print(token, end="", flush=True)
    print()
