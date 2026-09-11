"""
Colab Ollama Client — Connect to your Colab GPU from any app.

Usage:
  1. Run the Colab notebook (colab_gpu_setup.ipynb)
  2. Copy the ngrok URL from Colab output
  3. Set OLLAMA_COLAB_URL in your .env
  4. Use this client to chat with GPU models

Example:
  from colab_client import ColabOllama

  client = ColabOllama("https://xxx.ngrok.io")
  response = await client.chat("Hello, what model are you?")
  print(response)
"""

import httpx
from typing import AsyncGenerator


class ColabOllama:
    """Client for Ollama running on Google Colab GPU via ngrok tunnel."""

    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")
        self.timeout = httpx.Timeout(120.0, connect=15.0)  # GPU models can be slower

    async def chat(self, messages: list[dict], model: str = "llama3.1:8b", temperature: float = 0.7) -> str:
        """Send chat messages and get a complete response."""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/api/chat",
                json={
                    "model": model,
                    "messages": messages,
                    "stream": False,
                    "options": {
                        "temperature": temperature,
                        "num_predict": 2048,
                    },
                },
            )
            response.raise_for_status()
            data = response.json()
            return data["message"]["content"]

    async def chat_stream(self, messages: list[dict], model: str = "llama3.1:8b", temperature: float = 0.7) -> AsyncGenerator[str, None]:
        """Stream chat response token by token."""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            async with client.stream(
                "POST",
                f"{self.base_url}/api/chat",
                json={
                    "model": model,
                    "messages": messages,
                    "stream": True,
                    "options": {
                        "temperature": temperature,
                        "num_predict": 2048,
                    },
                },
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.strip():
                        import json
                        data = json.loads(line)
                        if "message" in data:
                            yield data["message"].get("content", "")

    async def embed(self, text: str, model: str = "nomic-embed-text") -> list:
        """Get embedding vector for text."""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/api/embeddings",
                json={
                    "model": model,
                    "prompt": text,
                },
            )
            response.raise_for_status()
            return response.json()["embedding"]

    async def is_available(self) -> bool:
        """Check if Colab Ollama is running."""
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(f"{self.base_url}/api/tags")
                return resp.status_code == 200
        except Exception:
            return False

    async def list_models(self) -> list[str]:
        """List available models on Colab."""
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(f"{self.base_url}/api/tags")
                resp.raise_for_status()
                models = resp.json().get("models", [])
                return [m["name"] for m in models]
        except Exception:
            return []


# ─── Quick Test ───
if __name__ == "__main__":
    import asyncio

    async def main():
        import os
        url = os.getenv("OLLAMA_COLAB_URL")
        if not url:
            print("Set OLLAMA_COLAB_URL first!")
            print("Example: export OLLAMA_COLAB_URL=https://xxx.ngrok.io")
            return

        client = ColabOllama(url)

        if await client.is_available():
            print("Connected to Colab GPU!")
            models = await client.list_models()
            print(f"Available models: {models}")

            response = await client.chat(
                [{"role": "user", "content": "Hello! What GPU is this running on?"}],
                model="llama3.1:8b",
            )
            print(f"Response: {response}")
        else:
            print("Colab Ollama is not reachable. Check the ngrok URL.")

    asyncio.run(main())
