# 🆓 Free Stack — Zero Cost Infrastructure

Complete infrastructure setup that costs **$0 forever**. No surprise bills, no credit card charges, no vendor lock-in.

## Stack Overview

| Component | Tool | Cost | Purpose |
|-----------|------|------|---------|
| LLM Inference (Fast) | Groq API | $0 | Always-on API for Llama, Mixtral, Gemma |
| LLM Inference (Heavy) | Colab + Ollama | $0 | GPU models (70B+, vision, embeddings) |
| Backend / Database | PocketBase | $0 | Auth, DB, storage, real-time |
| Hosting | Oracle Cloud Free Tier | $0 forever | 4 ARM OCPUs, 24GB RAM |
| Crash Reporting | Firebase Crashlytics | $0 | Unlimited error tracking |

## Quick Start

### 1. Groq (2 minutes)
```bash
cd groq
pip install -r requirements.txt
# Set your API key (free signup at console.groq.com)
export GROQ_API_KEY="gsk_..."
python chat.py
```

### 2. Colab GPU (5 minutes)
1. Open `colab_gpu_setup.ipynb` in Google Colab
2. Runtime → Change runtime type → T4 GPU
3. Run all cells
4. Copy the ngrok URL → use as your Ollama API endpoint

### 3. PocketBase on Oracle Cloud (15 minutes)
```bash
# On your Oracle Cloud VM:
chmod +x pocketbase/setup_oracle.sh
./pocketbase/setup_oracle.sh
```

### 4. Crashlytics (10 minutes)
```bash
cd crashlytics
# Add Firebase to your project, then:
# Copy firebase_config.json to your project root
npm install firebase
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  YOUR APP                        │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │  Groq    │  │  Colab   │  │ PocketBase│      │
│  │  API     │  │  +Ollama │  │ (Oracle)  │      │
│  │  (fast)  │  │  (GPU)   │  │ (backend) │      │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘      │
│       │              │              │             │
│       └──────────────┼──────────────┘             │
│                      │                            │
│              ┌───────┴───────┐                    │
│              │  Crashlytics  │                    │
│              │  (error       │                    │
│              │   tracking)   │                    │
│              └───────────────┘                    │
│                                                  │
└─────────────────────────────────────────────────┘

All $0. All free. All yours.
```

## Files

```
free-stack/
├── README.md                    # This file
├── config/
│   └── providers.json           # Unified LLM provider config
├── groq/
│   ├── requirements.txt         # Python dependencies
│   ├── chat.py                  # Basic chat example
│   ├── chat_stream.py           # Streaming response
│   ├── embeddings.py            # Embeddings example
│   └── .env.example             # Environment variables template
├── colab-gpu/
│   ├── colab_gpu_setup.ipynb    # Colab notebook (open in Colab)
│   └── ollama_client.py         # Client to connect to Colab Ollama
├── pocketbase/
│   ├── setup_oracle.sh          # Oracle Cloud setup script
│   ├── docker-compose.yml       # Docker setup
│   └── schema_backup.json       # Database schema backup
└── crashlytics/
    ├── firebase_config.json     # Firebase config template
    ├── setup_android.md         # Android integration guide
    └── setup_web.md             # Web integration guide
```
