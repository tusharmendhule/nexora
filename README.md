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

### Seed data & scripts (backend)

The API ships with two seed scripts plus an end-to-end test script, all run
from the `backend/` directory (they read `MONGODB_URI` from `.env`):

```bash
cd backend

# 1) Fresh demo dataset — 8 members, posts, chats, notifications, reports,
#    stories. WARNING: wipes users/posts/trust results/etc. first.
node scripts/seed.mjs

# 2) Add 200 more realistic posts with AI content checks (additive, nothing
#    is deleted). Pass a number to change the count.
node scripts/seed-posts.mjs          # 200 posts
node scripts/seed-posts.mjs 500      # 500 posts

# 3) E2E sweep of every DB-writing endpoint against a live backend on :4000.
bash scripts/e2e-test.sh
```

Demo accounts (password `nexora123`):

| Email               | Role      |
| ------------------- | --------- |
| `aria@nexora.test`  | user      |
| `sofia@nexora.test` | user      |
| `marcus@nexora.test`| moderator |
| `dev@nexora.test`   | admin     |

## System Architecture

| Layer          | Technology                              | Purpose                                              |
| -------------- | --------------------------------------- | ---------------------------------------------------- |
| Presentation   | Flutter (Dart)                          | Cross-platform UI, feed, upload, trust-label display |
| API            | Node.js, Express.js                     | REST APIs, content workflow, feed & moderation logic |
| AI Service     | Python, PyTorch/TensorFlow, Hugging Face| Model inference and NLP processing                   |
| Database       | MongoDB Atlas                           | Users, posts, trust results, reports & moderation logs |
| Authentication | JWT (email/password + refresh rotation)  | Manual auth with bcrypt + short-lived access tokens  |
| Media          | Cloudinary                              | Media storage and CDN delivery                       |
| Caching        | Redis                                   | Optional caching for repeated or short-lived results |
| Verification   | Google Gemini (via AI service)          | LLM fact-check lookup and content review evidence     |
| Development    | Git/GitHub, VS Code, Docker             | Version control, development & containerisation      |

## Trust System

Nexora's signature feature: every member carries a **Trust Score (0–100)** and a
**color-coded Trust Label** shown across the app. See `nexora/README.md` for the
full label table.

## Admin settings API

Admins can toggle three platform-wide switches through the REST API (the admin
dashboard in the Flutter app binds to these):

| Method | Route                  | Auth  | Description                                       |
| ------ | ---------------------- | ----- | ------------------------------------------------- |
| GET    | `/api/v1/admin/settings` | Admin | Read the current settings                         |
| PUT    | `/api/v1/admin/settings` | Admin | Persist any of the switches below                 |

```jsonc
// PUT /api/v1/admin/settings  — send only the fields you want to change
{
  "maintenanceMode": true,        // blocks post/story creation for members (HTTP 503)
  "verifiedOnlyExplore": false,   // Explore shows verified creators only
  "aiTriage": true                // gates AI auto-flagging of severe content
}
```

All three are stored as a single `AdminSettings` document in MongoDB and are
**enforced server-side**: `maintenanceMode` rejects member mutations with
`503`, `verifiedOnlyExplore` filters the Explore feed to `isVerified` authors,
and `aiTriage` controls whether the AI content pipeline auto-flags posts into
the moderation queue. See `backend/README.md` for the full endpoint list.
