# Quick Start — Free Stack Setup

## Step 1: Groq API (2 minutes)

1. Go to https://console.groq.com/keys
2. Sign up (no credit card)
3. Create API key
4. Add to `NoraApp/backend/.env`:
```
GROQ_API_KEY=gsk_your_key_here
LLM_PROVIDER=groq
```

## Step 2: Colab GPU (5 minutes)

1. Open `colab-gpu/colab_gpu_setup.ipynb` in Google Colab
2. Runtime → Change runtime type → T4 GPU
3. Run all cells
4. Copy the ngrok URL
5. Add to `NoraApp/backend/.env`:
```
OLLAMA_COLAB_URL=https://xxx.ngrok.io
LLM_PROVIDER=auto
```

## Step 3: PocketBase on Oracle Cloud (15 minutes)

1. Sign up at https://cloud.oracle.com (free tier)
2. Create ARM instance: 4 OCPUs, 24GB RAM
3. SSH into instance
4. Run:
```bash
chmod +x setup_oracle.sh
./setup_oracle.sh
```
5. Open `http://YOUR_IP/_/` and create admin account

## Step 4: Firebase Crashlytics (10 minutes)

1. Go to https://console.firebase.google.com
2. Create project (no billing)
3. Add Android app (package: `com.nora.app`)
4. Download `google-services.json` → `NoraApp/android/app/`
5. Follow `crashlytics/setup_android.md`

## Step 5: Start Everything

```bash
cd NoraApp/backend
pip install -r requirements.txt
python main.py
```

Test the AI:
```bash
curl http://localhost:8000/ai/health
curl -X POST http://localhost:8000/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!", "age_group": "adult"}'
```

## Total Cost: $0
- Groq: Free tier (30 RPM)
- Colab: Free T4 GPU
- PocketBase: Oracle Cloud (4 OCPUs, 24GB RAM forever)
- Crashlytics: Unlimited, free forever
