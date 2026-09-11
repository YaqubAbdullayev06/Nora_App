"""
Ollama client — now backed by UnifiedLLMProvider.

Supports:
  - Groq API (fast, free tier)
  - Ollama local (localhost:11434)
  - Ollama Colab GPU (ngrok tunnel)

Set these in .env:
  GROQ_API_KEY=gsk_...          (free at console.groq.com)
  OLLAMA_BASE_URL=http://localhost:11434
  OLLAMA_COLAB_URL=https://xxx.ngrok.io   (from Colab notebook)
  LLM_PROVIDER=auto              (auto|groq|ollama|ollama_colab)
"""

from ai.llm_provider import llm

# Backward-compatible singleton — existing code uses `ollama.chat()`, `ollama.is_available()`, etc.
ollama = llm
