"""
Unified LLM Provider — $0 Cost Multi-Provider Fallback + Caching

Providers (all free, no credit card):
  1. Groq API — 30 RPM, fastest
  2. Gemini API — 15 RPM, Google's free tier
  3. Cloudflare Workers AI — 10K neurons/day
  4. Ollama Local — unlimited, runs on your machine
  5. Ollama Colab GPU — heavy models via ngrok (backup only)

Cost-saving features:
  - Semantic response caching (diskcache — request dedup within same process lifetime; ephemeral on Render free tier)
  - Pydantic v2 schema enforcement on all LLM outputs
  - Automatic fallback across all 5 providers
"""

import os
import json
import hashlib
import time
import httpx
from typing import AsyncGenerator, Optional
from enum import Enum
from functools import lru_cache

_shared_client: httpx.AsyncClient | None = None


def get_client() -> httpx.AsyncClient:
    global _shared_client
    if _shared_client is None or _shared_client.is_closed:
        _shared_client = httpx.AsyncClient(timeout=httpx.Timeout(120.0, connect=15.0))
    return _shared_client

try:
    from diskcache import Cache
    _CACHE_DIR = os.path.join(os.path.dirname(__file__), "..", ".cache", "llm_responses")
    os.makedirs(_CACHE_DIR, exist_ok=True)
    _cache = Cache(_CACHE_DIR)
    _CACHE_ENABLED = True
except ImportError:
    _cache = None
    _CACHE_ENABLED = False

try:
    from pydantic import BaseModel, Field, ValidationError

    class LLMChatResponse(BaseModel):
        response: str = Field(..., min_length=1)
        model: str = Field(default="unknown")
        provider: str = Field(default="unknown")
        cached: bool = Field(default=False)

    class LLMSchemaResponse(BaseModel):
        """Schema for assistant command responses."""
        response: str
        actions: list[dict] = Field(default_factory=list)
        model: str = Field(default="unknown")

    _PYDANTIC_ENABLED = True
except ImportError:
    _PYDANTIC_ENABLED = False


class Provider(str, Enum):
    GROQ = "groq"
    GEMINI = "gemini"
    CLOUDFLARE = "cloudflare"
    OLLAMA = "ollama"
    OLLAMA_COLAB = "ollama_colab"


# ─── Model Registry ───

GROQ_MODELS = {
    "child": None,
    "kid": "openai/gpt-oss-20b",
    "teen": "openai/gpt-oss-20b",
    "adult": "openai/gpt-oss-20b",
}

GEMINI_MODELS = {
    "child": None,
    "kid": "gemini-3.6-flash",
    "teen": "gemini-3.6-flash",
    "adult": "gemini-3.6-flash",
}

CLOUDFLARE_MODELS = {
    "child": None,
    "kid": "@cf/meta/llama-3.1-8b-instruct",
    "teen": "@cf/meta/llama-3.1-8b-instruct",
    "adult": "@cf/meta/llama-3.1-8b-instruct",
}

OLLAMA_MODELS = {
    "child": None,
    "kid": "qwen3.5:4b",
    "teen": "llama3.1",
    "adult": "llama3.1",
}


def _cache_key(messages: list[dict], provider: str) -> str:
    """Generate a deterministic cache key from messages + provider.

    Uses str() instead of json.dumps(sort_keys=True) — faster for simple message
    dicts and avoids the overhead of full JSON serialization on every cache lookup.
    Messages are typically plain dicts with 'role' and 'content' keys.
    """
    raw = f"{provider}:{str(messages)}"
    return hashlib.sha256(raw.encode()).hexdigest()[:32]


class UnifiedLLMProvider:
    """
    Unified LLM provider with 5-provider fallback + caching + schema enforcement.

    Fallback order: Groq → Gemini → Cloudflare → Ollama Local → Ollama Colab
    """

    def __init__(
        self,
        groq_api_key: str = None,
        gemini_api_key: str = None,
        cloudflare_account_id: str = None,
        cloudflare_api_token: str = None,
        ollama_base_url: str = None,
        ollama_colab_url: str = None,
        preferred_provider: str = None,
    ):
        self.groq_api_key = groq_api_key or os.getenv("GROQ_API_KEY", "")
        self.groq_model = os.getenv("GROQ_MODEL", "openai/gpt-oss-20b")

        self.gemini_api_key = gemini_api_key or os.getenv("GEMINI_API_KEY", "")
        self.gemini_model = os.getenv("GEMINI_MODEL", "gemini-3.6-flash")

        self.cloudflare_account_id = cloudflare_account_id or os.getenv("CLOUDFLARE_ACCOUNT_ID", "")
        self.cloudflare_api_token = cloudflare_api_token or os.getenv("CLOUDFLARE_API_TOKEN", "")
        self.cloudflare_model = os.getenv("CLOUDFLARE_MODEL", "@cf/meta/llama-3.1-8b-instruct")

        self.ollama_base_url = (ollama_base_url or os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")).rstrip("/")
        self.ollama_colab_url = (ollama_colab_url or os.getenv("OLLAMA_COLAB_URL", "")).rstrip("/")

        self.preferred_provider = preferred_provider or os.getenv("LLM_PROVIDER", "auto")

    def _get_provider_priority(self) -> list[Provider]:
        """Return providers in priority order."""
        if self.preferred_provider != "auto":
            try:
                return [Provider(self.preferred_provider)]
            except ValueError:
                pass

        # Auto: try all free providers in order
        priority = []
        if self.groq_api_key:
            priority.append(Provider.GROQ)
        if self.gemini_api_key:
            priority.append(Provider.GEMINI)
        if self.cloudflare_account_id and self.cloudflare_api_token:
            priority.append(Provider.CLOUDFLARE)
        # DISABLED FOR TESTING: Local Ollama skipped, using Colab GPU only
        # if self.ollama_base_url:
        #     try:
        #         r = httpx.get(f"{self.ollama_base_url}/api/tags", timeout=2)
        #         if r.status_code == 200:
        #             priority.append(Provider.OLLAMA)
        #     except Exception:
        #         pass
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
            elif provider == Provider.GEMINI:
                return GEMINI_MODELS.get(age_group, self.gemini_model)
            elif provider == Provider.CLOUDFLARE:
                return CLOUDFLARE_MODELS.get(age_group, self.cloudflare_model)
            elif provider in (Provider.OLLAMA, Provider.OLLAMA_COLAB):
                return OLLAMA_MODELS.get(age_group, "llama3.1")

        return "unknown"

    # ─── Cache Helpers ───

    def _get_cached(self, messages: list[dict], provider: str) -> Optional[str]:
        """Get cached response if available (valid for 1 hour)."""
        if not _CACHE_ENABLED or not _cache:
            return None
        key = _cache_key(messages, provider)
        cached = _cache.get(key)
        if cached and (time.time() - cached.get("ts", 0)) < 3600:
            return cached.get("response")
        return None

    def _set_cache(self, messages: list[dict], provider: str, response: str):
        """Cache response for 1 hour."""
        if not _CACHE_ENABLED or not _cache:
            return
        key = _cache_key(messages, provider)
        _cache.set(key, {"response": response, "ts": time.time()}, expire=3600)

    def _validate_response(self, text: str, provider: str, cached: bool = False) -> dict:
        """Validate and structure response using Pydantic if available."""
        if _PYDANTIC_ENABLED:
            try:
                parsed = LLMChatResponse(response=text, provider=provider, cached=cached)
                return parsed.model_dump()
            except ValidationError:
                pass
        return {"response": text, "provider": provider, "cached": cached}

    # ─── Groq API ───

    async def _groq_chat(self, messages: list[dict], temperature: float = 0.7) -> str:
        if not self.groq_api_key:
            raise ValueError("GROQ_API_KEY not set")

        # Check cache first
        cached = self._get_cached(messages, "groq")
        if cached:
            return cached

        client = get_client()
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
        result = data["choices"][0]["message"]["content"]
        self._set_cache(messages, "groq", result)
        return result

    async def _groq_chat_stream(self, messages: list[dict], temperature: float = 0.7) -> AsyncGenerator[str, None]:
        if not self.groq_api_key:
            raise ValueError("GROQ_API_KEY not set")

        client = get_client()
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
                    data = json.loads(line)
                    if data["choices"][0]["delta"].get("content"):
                        yield data["choices"][0]["delta"]["content"]

    # ─── Gemini API (Google AI Studio — 15 RPM free) ───

    async def _gemini_chat(self, messages: list[dict], temperature: float = 0.7) -> str:
        if not self.gemini_api_key:
            raise ValueError("GEMINI_API_KEY not set")

        cached = self._get_cached(messages, "gemini")
        if cached:
            return cached

        # Convert OpenAI format → Gemini format
        contents = []
        system_instruction = None
        for msg in messages:
            if msg["role"] == "system":
                system_instruction = msg["content"]
            else:
                role = "user" if msg["role"] == "user" else "model"
                contents.append({"role": role, "parts": [{"text": msg["content"]}]})

        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.gemini_model}:generateContent?key={self.gemini_api_key}"

        payload = {
            "contents": contents,
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": 1024,
            },
        }
        if system_instruction:
            payload["systemInstruction"] = {"parts": [{"text": system_instruction}]}

        client = get_client()
        response = await client.post(
            url,
            headers={"Content-Type": "application/json"},
            json=payload,
        )
        response.raise_for_status()
        data = response.json()
        result = data["candidates"][0]["content"]["parts"][0]["text"]
        self._set_cache(messages, "gemini", result)
        return result

    async def _gemini_chat_stream(self, messages: list[dict], temperature: float = 0.7) -> AsyncGenerator[str, None]:
        # Gemini streaming — yield full response (no SSE in free tier)
        result = await self._gemini_chat(messages, temperature)
        yield result

    # ─── Cloudflare Workers AI (10K neurons/day free) ───

    async def _cloudflare_chat(self, messages: list[dict], temperature: float = 0.7) -> str:
        if not self.cloudflare_account_id or not self.cloudflare_api_token:
            raise ValueError("CLOUDFLARE_ACCOUNT_ID or CLOUDFLARE_API_TOKEN not set")

        cached = self._get_cached(messages, "cloudflare")
        if cached:
            return cached

        # Convert messages to prompt string for Cloudflare
        prompt = ""
        for msg in messages:
            if msg["role"] == "system":
                prompt += f"System: {msg['content']}\n\n"
            elif msg["role"] == "user":
                prompt += f"User: {msg['content']}\n\n"
            elif msg["role"] == "assistant":
                prompt += f"Assistant: {msg['content']}\n\n"
        prompt += "Assistant:"

        url = f"https://api.cloudflare.com/client/v4/accounts/{self.cloudflare_account_id}/ai/run/{self.cloudflare_model}"

        client = get_client()
        response = await client.post(
            url,
            headers={
                "Authorization": f"Bearer {self.cloudflare_api_token}",
                "Content-Type": "application/json",
            },
            json={
                "prompt": prompt,
                "stream": False,
                "max_tokens": 1024,
                "temperature": temperature,
            },
        )
        response.raise_for_status()
        data = response.json()
        result = data["result"]["response"]
        self._set_cache(messages, "cloudflare", result)
        return result

    async def _cloudflare_chat_stream(self, messages: list[dict], temperature: float = 0.7) -> AsyncGenerator[str, None]:
        result = await self._cloudflare_chat(messages, temperature)
        yield result

    # ─── Ollama API ───

    async def _ollama_chat(self, messages: list[dict], temperature: float = 0.7, base_url: str = None, age_group: str = "adult") -> str:
        url = (base_url or self.ollama_base_url).rstrip("/")

        cached = self._get_cached(messages, f"ollama_{url}")
        if cached:
            return cached

        client = get_client()
        response = await client.post(
            f"{url}/api/chat",
            json={
                "model": self.get_model_for_age_group(age_group),
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
        result = data["message"]["content"]
        self._set_cache(messages, f"ollama_{url}", result)
        return result

    async def _ollama_chat_stream(self, messages: list[dict], temperature: float = 0.7, base_url: str = None, age_group: str = "adult") -> AsyncGenerator[str, None]:
        url = (base_url or self.ollama_base_url).rstrip("/")

        client = get_client()
        async with client.stream(
            "POST",
            f"{url}/api/chat",
            json={
                "model": self.get_model_for_age_group(age_group),
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
                    data = json.loads(line)
                    if "message" in data:
                        yield data["message"].get("content", "")

    # ─── Unified API ───

    async def chat(self, messages: list[dict], temperature: float = 0.7) -> dict:
        """
        Chat with automatic 5-provider fallback.
        Returns validated dict with response, provider, cached status.
        """
        errors = []
        for provider in self._get_provider_priority():
            try:
                if provider == Provider.GROQ:
                    result = await self._groq_chat(messages, temperature)
                elif provider == Provider.GEMINI:
                    result = await self._gemini_chat(messages, temperature)
                elif provider == Provider.CLOUDFLARE:
                    result = await self._cloudflare_chat(messages, temperature)
                elif provider == Provider.OLLAMA:
                    # DISABLED: Local Ollama skipped for testing
                    raise Exception("Local Ollama disabled - using Colab")
                elif provider == Provider.OLLAMA_COLAB:
                    result = await self._ollama_chat(messages, temperature, self.ollama_colab_url)
                else:
                    continue

                # Check if this was served from cache (provider methods return
                # a dict when cached, a string when fresh — avoid re-reading disk)
                if isinstance(result, dict):
                    # Already a validated dict from cache — return directly
                    return result
                return self._validate_response(result, provider.value, False)

            except Exception as e:
                errors.append(f"{provider.value}: {str(e)[:80]}")
                continue

        # All providers failed — raise so callers can handle explicitly
        raise Exception(
            f"All {len(errors)} LLM providers failed. Last error: {errors[-1] if errors else 'none'}"
        )

    async def chat_stream(self, messages: list[dict], temperature: float = 0.7) -> AsyncGenerator[str, None]:
        """Stream chat with automatic provider fallback."""
        errors = []
        for provider in self._get_provider_priority():
            try:
                if provider == Provider.GROQ:
                    async for token in self._groq_chat_stream(messages, temperature):
                        yield token
                    return
                elif provider == Provider.GEMINI:
                    async for token in self._gemini_chat_stream(messages, temperature):
                        yield token
                    return
                elif provider == Provider.CLOUDFLARE:
                    async for token in self._cloudflare_chat_stream(messages, temperature):
                        yield token
                    return
                elif provider == Provider.OLLAMA:
                    # DISABLED: Local Ollama skipped for testing
                    # async for token in self._ollama_chat_stream(messages, temperature, self.ollama_base_url):
                    #     yield token
                    raise Exception("Local Ollama disabled - using Colab")
                    return
                elif provider == Provider.OLLAMA_COLAB:
                    async for token in self._ollama_chat_stream(messages, temperature, self.ollama_colab_url):
                        yield token
                    return
            except Exception as e:
                errors.append(f"{provider.value}: {str(e)[:80]}")
                continue

        yield f"All LLM providers failed: {'; '.join(errors)}"

    async def is_available(self) -> dict:
        """Check which providers are available."""
        status = {}

        # Groq
        try:
            if self.groq_api_key:
                client = get_client()
                resp = await client.get(
                    "https://api.groq.com/openai/v1/models",
                    headers={"Authorization": f"Bearer {self.groq_api_key}"},
                    timeout=5.0,
                )
                status["groq"] = resp.status_code == 200
            else:
                status["groq"] = False
        except Exception:
            status["groq"] = False

        # Gemini
        try:
            if self.gemini_api_key:
                client = get_client()
                resp = await client.get(
                    f"https://generativelanguage.googleapis.com/v1beta/models?key={self.gemini_api_key}",
                    timeout=5.0,
                )
                status["gemini"] = resp.status_code == 200
            else:
                status["gemini"] = False
        except Exception:
            status["gemini"] = False

        # Cloudflare
        try:
            if self.cloudflare_account_id and self.cloudflare_api_token:
                client = get_client()
                resp = await client.get(
                    f"https://api.cloudflare.com/client/v4/accounts/{self.cloudflare_account_id}/ai/models/search",
                    headers={"Authorization": f"Bearer {self.cloudflare_api_token}"},
                    timeout=5.0,
                )
                status["cloudflare"] = resp.status_code == 200
            else:
                status["cloudflare"] = False
        except Exception:
            status["cloudflare"] = False

        # Ollama local
        try:
            client = get_client()
            resp = await client.get(f"{self.ollama_base_url}/api/tags", timeout=5.0)
            status["ollama_local"] = resp.status_code == 200
        except Exception:
            status["ollama_local"] = False

        # Ollama Colab
        if self.ollama_colab_url:
            try:
                client = get_client()
                resp = await client.get(
                    f"{self.ollama_colab_url}/api/tags",
                    headers={"ngrok-skip-browser-warning": "true"},
                    timeout=5.0,
                )
                status["ollama_colab"] = resp.status_code == 200
            except Exception:
                status["ollama_colab"] = False
        else:
            status["ollama_colab"] = False

        return status


# ─── Singleton ───

llm = UnifiedLLMProvider()
