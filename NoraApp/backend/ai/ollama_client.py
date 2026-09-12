"""
Ollama client — backward-compatible wrapper over UnifiedLLMProvider.

Supports 5 free providers:
  - Groq API (fast, free tier)
  - Gemini API (Google AI Studio, free)
  - Cloudflare Workers AI (10K neurons/day free)
  - Ollama local (localhost:11434)
  - Ollama Colab GPU (ngrok tunnel)

Set these in .env:
  GROQ_API_KEY=gsk_...              (free at console.groq.com)
  GEMINI_API_KEY=AIza...            (free at aistudio.google.com)
  CLOUDFLARE_ACCOUNT_ID=...         (free at dash.cloudflare.com)
  CLOUDFLARE_API_TOKEN=...          (free at dash.cloudflare.com)
  OLLAMA_BASE_URL=http://localhost:11434
  OLLAMA_COLAB_URL=https://xxx.ngrok.io
  LLM_PROVIDER=auto                 (auto|groq|gemini|cloudflare|ollama|ollama_colab)
"""

from ai.llm_provider import llm


class OllamaCompat:
    """
    Backward-compatible wrapper. Existing code uses:
      ollama.chat(messages)
      ollama.is_available()
      ollama.get_model_for_age_group(age)
    """

    def __init__(self):
        self._llm = llm

    @property
    def model(self):
        return self._llm.groq_model

    @property
    def base_url(self):
        return self._llm.ollama_base_url

    async def chat(self, messages: list[dict], temperature: float = 0.7) -> str:
        """Chat — returns string for backward compatibility."""
        result = await self._llm.chat(messages, temperature)
        if isinstance(result, dict):
            return result.get("response", "")
        return result

    async def is_available(self) -> bool:
        """Check if any provider is available."""
        status = await self._llm.is_available()
        return any(status.values())

    def get_model_for_age_group(self, age_group: str) -> str:
        return self._llm.get_model_for_age_group(age_group)


# Singleton — existing code does: from ai.ollama_client import ollama
ollama = OllamaCompat()
