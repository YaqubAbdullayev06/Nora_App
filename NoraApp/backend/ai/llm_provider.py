"""
Unified LLM Provider — Groq (fast) + Ollama (GPU/Colab) + Fallback Chain
Free stack: $0 cost, no credit card required.

Priority:
  1. Groq API (fastest, always available)
  2. Ollama local (if running locally)
  3. Ollama Colab (GPU tunnel via ngrok)
"""

import os
import httpx
from typing import AsyncGenerator, Optional
from enum import Enum


class Provider(str, Enum):
    GROQ = "groq"
    OLLAMA = "ollama"
    OLLAMA_COLAB = "ollama_colab"


# ─── Groq Free Tier Models ───
GROQ_MODELS = {
    "child": None,          # No LLM for children (safety)
    "kid": "llama3-8b-8192",
    "teen": "llama3-8b-8192",
    "adult": "llama3-8b-8192",
    # Heavy models (use Colab GPU for these):
    # "adult": "llama3-70b-8192",
    # "kid": "mixtral-8x7b-32768",
}

# ─── Ollama Models (local or Colab GPU) ───
OLLAMA_MODELS = {
    "child": None,
    "kid": "qwen3.5:4b",
    "teen": "llama3.1",
    "adult": "llama3.1",
}


class UnifiedLLMProvider:
    """
    Unified LLM provider with automatic fallback:
      Groq (fast API) → Ollama (local) → Ollama Colab (GPU)
    """

    def __init__(
        self,
        groq_api_key: str = None,
        groq_model: str = "llama3-8b-8192",
        ollama_base_url: str = "http://localhost:11434",
        ollama_colab_url: str = None,
        preferred_provider: str = None,
    ):
        self.groq_api_key = groq_api_key or os.getenv("GROQ_API_KEY", "")
        self.groq_model = groq_model or os.getenv("GROQ_MODEL", "llama3-8b-8192")
        self.ollama_base_url = (ollama_base_url or os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")).rstrip("/")
        self.ollama_colab_url = (ollama_colab_url or os.getenv("OLLAMA_COLAB_URL", "")).rstrip("/")
        self.preferred_provider = preferred_provider or os.getenv("LLM_PROVIDER", "auto")
        self.timeout = httpx.Timeout(60.0, connect=10.0)

    def _get_provider_priority(self) -> list[Provider]:
        """Return providers in priority order."""
        if self.preferred_provider == "groq":
            return [Provider.GROQ]
        elif self.preferred_provider == "ollama":
            return [Provider.OLLAMA]
        elif self.preferred_provider == "ollama_colab":
            return [Provider.OLLAMA_COLAB]
        # Auto: try Groq first, then Ollama, then Colab
        priority = [Provider.GROQ]
        if self.ollama_base_url:
            priority.append(Provider.OLLAMA)
        if self.ollama_colab_url:
            priority.append(Provider.OLLAMA_COLAB)
        return priority

    def get_model_for_age_group(self, age_group: str) -> str:
        """Pick the best model based on provider and age group."""
        if age_group == "child":
            return None

        provider_priority = self._get_provider_priority()

        for provider in provider_priority:
            if provider == Provider.GROQ:
                return GROQ_MODELS.get(age_group, self.groq_model)
            elif provider in (Provider.OLLAMA, Provider.OLLAMA_COLAB):
                return OLLAMA_MODELS.get(age_group, "llama3.1")

        return "llama3-8b-8192"

    # ─── Groq API ───

    async def _groq_chat(self, messages: list[dict], temperature: float = 0.7) -> str:
        """Chat via Groq free tier API."""
        if not self.groq_api_key:
            raise ValueError("GROQ_API_KEY not set")

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.groq_api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": self.groq_model,
                    "messages": messages,
                    "temperature": temperature,
                    "max_tokens": 1024,
                },
            )
            response.raise_for_status()
            data = response.json()
            return data["choices"][0]["message"]["content"]

    async def _groq_chat_stream(self, messages: list[dict], temperature: float = 0.7) -> AsyncGenerator[str, None]:
        """Stream chat via Groq free tier API."""
        if not self.groq_api_key:
            raise ValueError("GROQ_API_KEY not set")

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            async with client.stream(
                "POST",
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.groq_api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": self.groq_model,
                    "messages": messages,
                    "temperature": temperature,
                    "max_tokens": 1024,
                    "stream": True,
                },
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.strip():
                        import json
                        data = json.loads(line)
                        if data["choices"][0]["delta"].get("content"):
                            yield data["choices"][0]["delta"]["content"]

    # ─── Ollama API ───

    async def _ollama_chat(self, messages: list[dict], temperature: float = 0.7, base_url: str = None) -> str:
        """Chat via Ollama (local or Colab)."""
        url = (base_url or self.ollama_base_url).rstrip("/")

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{url}/api/chat",
                json={
                    "model": self.get_model_for_age_group("adult"),
                    "messages": messages,
                    "stream": False,
                    "options": {
                        "temperature": temperature,
                        "num_predict": 1024,
                    },
                },
            )
            response.raise_for_status()
            data = response.json()
            return data["message"]["content"]

    async def _ollama_chat_stream(self, messages: list[dict], temperature: float = 0.7, base_url: str = None) -> AsyncGenerator[str, None]:
        """Stream chat via Ollama (local or Colab)."""
        url = (base_url or self.ollama_base_url).rstrip("/")

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            async with client.stream(
                "POST",
                f"{url}/api/chat",
                json={
                    "model": self.get_model_for_age_group("adult"),
                    "messages": messages,
                    "stream": True,
                    "options": {
                        "temperature": temperature,
                        "num_predict": 1024,
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

    # ─── Unified API ───

    async def chat(self, messages: list[dict], temperature: float = 0.7) -> str:
        """
        Chat with automatic provider fallback.
        Tries: Groq → Ollama local → Ollama Colab
        """
        errors = []
        for provider in self._get_provider_priority():
            try:
                if provider == Provider.GROQ:
                    return await self._groq_chat(messages, temperature)
                elif provider == Provider.OLLAMA:
                    return await self._ollama_chat(messages, temperature, self.ollama_base_url)
                elif provider == Provider.OLLAMA_COLAB:
                    return await self._ollama_chat(messages, temperature, self.ollama_colab_url)
            except Exception as e:
                errors.append(f"{provider.value}: {str(e)}")
                continue

        raise ConnectionError(f"All LLM providers failed: {'; '.join(errors)}")

    async def chat_stream(self, messages: list[dict], temperature: float = 0.7) -> AsyncGenerator[str, None]:
        """
        Stream chat with automatic provider fallback.
        """
        errors = []
        for provider in self._get_provider_priority():
            try:
                if provider == Provider.GROQ:
                    async for token in self._groq_chat_stream(messages, temperature):
                        yield token
                    return
                elif provider == Provider.OLLAMA:
                    async for token in self._ollama_chat_stream(messages, temperature, self.ollama_base_url):
                        yield token
                    return
                elif provider == Provider.OLLAMA_COLAB:
                    async for token in self._ollama_chat_stream(messages, temperature, self.ollama_colab_url):
                        yield token
                    return
            except Exception as e:
                errors.append(f"{provider.value}: {str(e)}")
                continue

        raise ConnectionError(f"All LLM providers failed: {'; '.join(errors)}")

    async def is_available(self) -> dict:
        """Check which providers are available."""
        status = {}

        # Check Groq
        try:
            if self.groq_api_key:
                async with httpx.AsyncClient(timeout=5.0) as client:
                    resp = await client.get(
                        "https://api.groq.com/openai/v1/models",
                        headers={"Authorization": f"Bearer {self.groq_api_key}"},
                    )
                    status["groq"] = resp.status_code == 200
            else:
                status["groq"] = False
        except Exception:
            status["groq"] = False

        # Check Ollama local
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(f"{self.ollama_base_url}/api/tags")
                status["ollama_local"] = resp.status_code == 200
        except Exception:
            status["ollama_local"] = False

        # Check Ollama Colab
        if self.ollama_colab_url:
            try:
                async with httpx.AsyncClient(timeout=5.0) as client:
                    resp = await client.get(f"{self.ollama_colab_url}/api/tags")
                    status["ollama_colab"] = resp.status_code == 200
            except Exception:
                status["ollama_colab"] = False
        else:
            status["ollama_colab"] = False

        return status


# ─── Singleton (drop-in replacement for old OllamaClient) ───

llm = UnifiedLLMProvider()
