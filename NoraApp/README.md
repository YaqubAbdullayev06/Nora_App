# Nora - AI-Powered Focus & Productivity App

## Project Overview

Nora is an AI-powered focus and productivity app that helps users overcome doomscrolling and social media addiction by converting idle time into micro-learning and productive habits.

**Total Monthly Cost: $0** — No credit cards, no surprise bills, no vendor lock-in.

## Free Stack Architecture

```
┌─────────────────────────────────────────────────────┐
│                    YOUR APP                          │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │
│  │   Groq API   │  │ Colab + GPU  │  │ PocketBase│  │
│  │  (fast LLM)  │  │  (heavy LLM) │  │ (backend) │  │
│  │  30 RPM free │  │  T4 15GB VRAM│  │  SQLite   │  │
│  └──────┬───────┘  └──────┬───────┘  └─────┬────┘  │
│         │                  │                │        │
│         └──────────────────┼────────────────┘        │
│                            │                         │
│                  ┌─────────┴─────────┐               │
│                  │ Crashlytics       │               │
│                  │ (error tracking)  │               │
│                  │ unlimited, free   │               │
│                  └───────────────────┘               │
│                                                      │
└─────────────────────────────────────────────────────┘
```

| Component | Tool | Cost | Credit Card |
|-----------|------|------|-------------|
| LLM Inference (Fast) | Groq API | $0 | No |
| LLM Inference (GPU) | Google Colab + Ollama | $0 | No |
| Backend / Database | PocketBase on Oracle Cloud | $0 forever | No |
| Crash Reporting | Firebase Crashlytics | $0 | No |

## Privacy Model

- **No cloud AI vendor lock-in** — Groq free tier or your own Ollama instance
- **No data sent to third parties** — inference runs on Groq (API only) or your infrastructure
- **PocketBase self-hosted** — your database, your server, your data
- **Crashlytics only** — no other Firebase services required, no billing risk

## Features

### Core Features (MVP)
- **Focus Score Dashboard** — Track daily productivity with visual circular progress
- **Smart Content Feed** — TikTok-style educational content curated by AI
- **AI Timer & Interrupter** — Pomodoro timer with intelligent break suggestions
- **Gamification System** — Badges, streaks, and points for motivation
- **Graduated Friction** — Delay screens, typed intentions, progressive unlock cost
- **Adaptive Personas** — Kid (6-12), Teen (12-18), Adult (18+) with age-appropriate guardrails
- **Parent-Managed Mode** — Children use pre-authored content library, no open LLM chat
- **AI Digital Assistant** — Scan apps, block distractions, analyze usage, start focus sessions

### AI Modules
1. **Unified LLM Provider** — Groq (fast) → Ollama (local) → Colab GPU (heavy) fallback chain
2. **Content Converter** — Transforms saved content into micro-learning format
3. **Smart Recommendations** — Vector-based personalized content suggestions
4. **Predictive Interrupter** — Detects doomscrolling patterns and suggests breaks
5. **Structured Action Output** — Schema-validated AI actions, no free-form JSON parsing
6. **Crisis Detection** — Keyword-based crisis routing to professional resources

## Tech Stack

### Frontend (Mobile)
- **Flutter** — Cross-platform iOS & Android development
- **Provider** — State management
- **flutter_secure_storage** — Secure JWT token storage
- **Custom Theme** — Dark mode with neon teal/purple accents

### Backend
- **Python FastAPI** — High-performance API server
- **MariaDB** — Primary database (free, self-hosted)
- **Unified LLM Provider** — Groq → Ollama → Colab GPU fallback chain
- **Pydantic** — Input validation and structured output schemas

### Free Infrastructure
- **Groq API** — Fast LLM inference (30 RPM, no credit card)
- **Google Colab** — GPU inference via T4 (ngrok tunnel)
- **Oracle Cloud** — ARM instance: 4 OCPUs, 24GB RAM (always free)
- **Firebase Crashlytics** — Unlimited crash reports ($0, no billing)
- **PocketBase** — Auth + database + storage + realtime (self-hosted)

## Project Structure

```
NoraApp/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/app_theme.dart
│   │   └── utils/
│   ├── features/
│   │   ├── home/screens/
│   │   ├── feed/screens/
│   │   ├── timer/screens/
│   │   ├── stats/screens/
│   │   └── auth/
│   ├── models/
│   ├── services/
│   ├── widgets/
│   ├── providers/app_provider.dart
│   └── main.dart
├── backend/
│   ├── ai/
│   │   ├── llm_provider.py          ← Unified Groq/Ollama/Colab
│   │   ├── ollama_client.py         ← Backward-compatible wrapper
│   │   └── prompts.py               ← Personality + crisis detection
│   ├── api/
│   ├── models/database.py
│   ├── services/
│   ├── utils/
│   ├── main.py
│   ├── .env                         ← GROQ_API_KEY + OLLAMA_COLAB_URL
│   └── requirements.txt
├── free-stack/
│   ├── README.md                    ← Full documentation
│   ├── QUICKSTART.md                ← 5-minute setup guide
│   ├── groq/                        ← Standalone Groq scripts
│   │   ├── chat.py
│   │   ├── chat_stream.py
│   │   ├── embeddings.py
│   │   ├── requirements.txt
│   │   └── .env.example
│   ├── colab-gpu/
│   │   ├── colab_gpu_setup.ipynb    ← Open in Colab → T4 GPU
│   │   └── colab_client.py          ← Python client for Colab
│   ├── pocketbase/
│   │   ├── setup_oracle.sh          ← One-click Oracle Cloud setup
│   │   └── docker-compose.yml       ← Local dev alternative
│   ├── crashlytics/
│   │   ├── setup_android.md
│   │   └── setup_web.md
│   └── config/
│       └── providers.json           ← Provider registry
├── assets/
│   ├── images/
│   └── animations/
├── pubspec.yaml
└── README.md
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Python 3.8+
- MariaDB or PostgreSQL
- Groq API key (free — https://console.groq.com/keys)

### Frontend Setup

```bash
cd NoraApp
flutter pub get
flutter run
```

### Backend Setup

```bash
cd NoraApp/backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate              # Windows
# source venv/bin/activate        # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Configure .env (add your Groq key)
# GROQ_API_KEY=gsk_your_key_here

# Run server
python main.py
```

API available at `http://localhost:8000`

### Activate LLM Providers

```bash
# Option 1: Groq only (fastest, 2 min setup)
# Add to .env:
GROQ_API_KEY=gsk_your_key_here
LLM_PROVIDER=groq

# Option 2: Auto fallback (Groq → Ollama → Colab GPU)
LLM_PROVIDER=auto
GROQ_API_KEY=gsk_...
OLLAMA_COLAB_URL=https://xxx.ngrok.io   # from Colab notebook
```

## API Endpoints

### Users
- `POST /users/` — Create new user
- `GET /users/{user_id}` — Get user details

### Focus Sessions
- `POST /sessions/` — Create new session
- `GET /sessions/{user_id}` — Get user sessions
- `PUT /sessions/{session_id}/complete` — Complete session

### Content
- `POST /content/` — Add new content
- `GET /content/` — Get all content (filter by category)

### AI Recommendations
- `POST /recommendations/` — Create recommendation
- `GET /recommendations/{user_id}` — Get user recommendations

### Focus Score
- `GET /focus-score/{user_id}` — Get user focus score

### AI Endpoints
- `GET /ai/health` — Check LLM provider status (Groq, Ollama, Colab)
- `POST /ai/chat` — Chat with AI (supports age-group personas)
- `POST /ai/analyze-usage` — App usage analysis
- `POST /ai/suggest-apps` — Distraction app suggestions
- `POST /ai/takeover` — Execute focus commands

## Design System

### Colors
- **Primary Dark**: #0D0D1A
- **Secondary Dark**: #1A1A2E
- **Neon Teal**: #00D9FF
- **Neon Purple**: #9D4EDD
- **Neon Pink**: #FF006E

### Typography
- **Headlines**: Bold, 20-32px
- **Body**: Regular, 14-16px
- **Captions**: Light, 12px

## Development Stages

### Stage 1: MVP (Current)
- [x] User authentication
- [x] Pomodoro timer
- [x] Static Smart Feed
- [x] Basic stats
- [x] Unified LLM provider (Groq + Ollama + Colab)
- [x] Age-group personality system (kid/teen/adult)
- [x] Crisis detection routing
- [x] AI chat endpoint

### Stage 2: AI Integration
- [ ] Screen Time API (Flutter)
- [ ] Personalized recommendations
- [ ] Voice assistant integration

### Stage 3: Gamification & Vector Search
- [ ] Focus Score algorithm
- [ ] Achievement system
- [ ] Content vector embeddings

### Stage 4: Beta & B2B
- [ ] TestFlight/Play Store beta
- [ ] Admin panel
- [ ] Corporate packages

## Free Stack Setup Guides

| Component | Guide | Time |
|-----------|-------|------|
| Groq API | `free-stack/QUICKSTART.md` | 2 min |
| Colab GPU | `free-stack/colab-gpu/colab_gpu_setup.ipynb` | 5 min |
| PocketBase | `free-stack/pocketbase/setup_oracle.sh` | 15 min |
| Crashlytics | `free-stack/crashlytics/setup_android.md` | 10 min |

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or feedback, please open an issue on GitHub.