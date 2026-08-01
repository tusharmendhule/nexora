# Nexora API (Node.js + Express)

REST API for Nexora: content workflow, feed, moderation and trust logic.

## Stack

- **Node.js 22+** with **Express 5** (ESM)
- **MongoDB Atlas** via Mongoose (users, posts, trust results, reports, moderation logs)
- **Firebase Auth + JWT** authorization
- **Cloudinary** media upload & CDN
- **Redis** optional caching
- Calls the **AI service** (`ai-service/`) for NLP trust scoring and **Gemini fact-checking** (set `GEMINI_API_KEY` in `ai-service/.env` to enable)

## Setup

```bash
cp .env.example .env   # fill in MONGODB_URI at minimum
npm install
npm run dev            # http://localhost:4000
```

Health check: `GET http://localhost:4000/api/v1/health`

## Authentication flow

The client signs in with **Firebase Auth** (email/password or anonymous), then
exchanges the Firebase **ID token** for a Nexora JWT:

```
Flutter ── Firebase Auth ──> ID token ──POST /auth/login──> { token, user }
```

Set the Firebase Admin credentials in `.env` to enable token verification:
`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`.
Without them, the API falls back to accepting JWTs signed with `JWT_SECRET`
(development mode).

## Endpoints

| Method | Route                    | Auth  | Description                               |
| ------ | ------------------------ | ----- | ----------------------------------------- |
| GET    | `/api/v1/health`         | –     | Health check                              |
| POST   | `/api/v1/auth/register`  | –     | `{ idToken, name, username }` → `{ token, user }` |
| POST   | `/api/v1/auth/login`     | –     | `{ idToken }` → `{ token, user }`         |
| GET    | `/api/v1/auth/me`        | Bearer| Current user profile                      |
| GET    | `/api/v1/feed`           | Bearer| Paginated home feed + trust      |
| POST   | `/api/v1/posts`          | Bearer| Create post (multipart `media`)  |
| GET    | `/api/v1/posts/:id`      | Bearer| Single post + trust result       |
| GET    | `/api/v1/moderation/queue`| Mod | Moderation queue                 |
| POST   | `/api/v1/moderation/action`| Mod| Approve/flag/remove              |
| POST   | `/api/v1/trust/recompute`| Bearer| Recompute user trust score       |
| GET    | `/api/v1/trust/verify`   | Bearer| Fact-check a claim               |
| POST   | `/api/v1/reports`        | Bearer| File a report                    |

## Project structure

```
src/
├── server.js            # entry point
├── app.js               # express app + middleware
├── config/              # env, db connection
├── models/              # Mongoose schemas
├── controllers/         # request handlers
├── routes/              # express routers
├── services/            # ai, cloudinary, redis, factcheck
└── middleware/          # auth, error handling
```
