# Nexora — The Next Generation of Connected Communities

A premium, trust-first social platform. Monorepo containing the **Nexora Flutter
app**, the **Node.js/Express REST API**, and the **Python AI service**.

## Repository layout

```
nexora/
├── nexora/           # Flutter mobile app (Android) — see nexora/README.md
├── backend/          # Node.js + Express REST API — see backend/README.md
├── ai-service/       # Python FastAPI AI service — see ai-service/README.md
└── docker-compose.yml  # Local orchestration (API + AI + MongoDB + Redis)
```

## Run it

### Flutter app

```bash
cd nexora
flutter pub get
flutter run
```

### Backend API

```bash
cd backend
cp .env.example .env   # fill in MONGODB_URI at minimum
npm install
npm run dev            # http://localhost:4000
```

### AI service

```bash
cd ai-service
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload                       # http://localhost:8000
```

### Docker (everything)

```bash
docker compose up --build
```

## System Architecture

| Layer          | Technology                              | Purpose                                              |
| -------------- | --------------------------------------- | ---------------------------------------------------- |
| Presentation   | Flutter (Dart)                          | Cross-platform UI, feed, upload, trust-label display |
| API            | Node.js, Express.js                     | REST APIs, content workflow, feed & moderation logic |
| AI Service     | Python, PyTorch/TensorFlow, Hugging Face| Model inference and NLP processing                   |
| Database       | MongoDB Atlas                           | Users, posts, trust results, reports & moderation logs |
| Authentication | Firebase Authentication, JWT            | Identity provider integration & API authorisation    |
| Media          | Cloudinary                              | Media storage and CDN delivery                       |
| Caching        | Redis                                   | Optional caching for repeated or short-lived results |
| Verification   | Google Fact Check Tools API             | Known claim-review lookup and verification evidence  |
| Development    | Git/GitHub, VS Code, Docker             | Version control, development & containerisation      |

## Trust System

Nexora's signature feature: every member carries a **Trust Score (0–100)** and a
**color-coded Trust Label** shown across the app. See `nexora/README.md` for the
full label table.
