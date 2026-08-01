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

The API uses **manual JWT auth**: register/login with email + password
(bcrypt-hashed), a short-lived access token (15 min) for every request, and
refresh-token rotation for session renewal.

```
POST /auth/register { email, password, name, username }  → { token, refreshToken, user }
POST /auth/login    { email, password }                  → { token, refreshToken, user }
POST /auth/refresh  { refreshToken }                     → new { token, refreshToken }
```

Send the access token as `Authorization: Bearer <token>` on every request.

## Endpoints

| Method | Route                         | Auth    | Description                              |
| ------ | ----------------------------- | ------- | ---------------------------------------- |
| GET    | `/api/v1/health`              | –       | Health check                             |
| POST   | `/api/v1/auth/register`       | –       | Create account → `{ token, user }`       |
| POST   | `/api/v1/auth/login`          | –       | Email/password login → `{ token, user }` |
| POST   | `/api/v1/auth/guest`          | –       | Anonymous guest session                  |
| POST   | `/api/v1/auth/refresh`        | –       | Rotate refresh token                     |
| POST   | `/api/v1/auth/logout`         | Bearer  | Revoke the refresh token                 |
| GET    | `/api/v1/auth/me`             | Bearer  | Current user profile                     |
| PATCH  | `/api/v1/auth/me`             | Bearer  | Update profile (bio, avatar, link…)      |
| POST   | `/api/v1/auth/avatar`         | Bearer  | Upload avatar (multipart `avatar`)       |
| GET    | `/api/v1/feed`                | Bearer  | Paginated home feed + trust              |
| GET    | `/api/v1/feed/stories`        | Bearer  | Active stories                           |
| POST   | `/api/v1/feed/stories`        | Bearer  | Create a story (multipart `image`)       |
| POST   | `/api/v1/posts`               | Bearer  | Create post (multipart `media`, hashtags, mentions) |
| GET    | `/api/v1/posts/:id`           | Bearer  | Single post + trust result               |
| GET    | `/api/v1/posts/user/:userId`  | Bearer  | Posts by a user                          |
| DELETE | `/api/v1/posts/:id`           | Bearer  | Delete own post (or moderator)           |
| POST   | `/api/v1/posts/:id/like`      | Bearer  | Toggle like                              |
| POST   | `/api/v1/posts/:id/bookmark`  | Bearer  | Toggle bookmark                          |
| GET    | `/api/v1/posts/:id/comments`  | Bearer  | List comments                            |
| POST   | `/api/v1/posts/:id/comments`  | Bearer  | Add comment                              |
| GET    | `/api/v1/posts/saved`         | Bearer  | Bookmarked posts                         |
| GET    | `/api/v1/users/search`        | Bearer  | Search people/posts/hashtags             |
| GET    | `/api/v1/users/explore`       | Bearer  | Trending posts + hashtags                |
| GET    | `/api/v1/users/reels`         | Bearer  | Video reels                              |
| GET    | `/api/v1/users/suggestions`   | Bearer  | Suggested members to follow              |
| GET    | `/api/v1/users/:id`           | Bearer  | Profile (by id or username)              |
| POST   | `/api/v1/users/:id/follow`    | Bearer  | Follow/unfollow                          |
| GET    | `/api/v1/users/:id/followers` | Bearer  | Follower list                            |
| GET    | `/api/v1/users/:id/following` | Bearer  | Following list                           |
| POST   | `/api/v1/users/:id/block`     | Bearer  | Block/unblock                            |
| GET    | `/api/v1/users/blocked`       | Bearer  | List blocked accounts                    |
| GET    | `/api/v1/chat`                | Bearer  | Conversations + unread counts            |
| POST   | `/api/v1/chat`                | Bearer  | Start conversation `{ userId }`          |
| GET    | `/api/v1/chat/:id/messages`   | Bearer  | Message history                          |
| POST   | `/api/v1/chat/:id/messages`   | Bearer  | Send text or image message               |
| GET    | `/api/v1/notifications`       | Bearer  | Notification feed                        |
| POST   | `/api/v1/notifications/read-all` | Bearer | Mark all read                          |
| POST   | `/api/v1/notifications/:id/read` | Bearer | Mark one read                          |
| POST   | `/api/v1/reports`             | Bearer  | File a report                            |
| GET    | `/api/v1/reports`             | Bearer  | List your reports                        |
| GET    | `/api/v1/moderation/queue`    | Mod     | Moderation queue                         |
| GET    | `/api/v1/moderation/stats`    | Mod     | Queue stats                              |
| POST   | `/api/v1/moderation/action`   | Mod     | Approve/remove/dismiss                   |
| POST   | `/api/v1/trust/recompute`     | Bearer  | Recompute user trust score               |
| GET    | `/api/v1/trust/overview`      | Bearer  | Trust history + factors for Trust Center |
| GET    | `/api/v1/trust/verify`        | Bearer  | Fact-check a claim (`?query=`)           |
| GET    | `/api/v1/admin/stats`         | Admin   | Platform KPIs + growth + top members     |
| GET    | `/api/v1/admin/settings`      | Admin   | Read admin settings                      |
| PUT    | `/api/v1/admin/settings`      | Admin   | Update settings (see below)              |
| GET    | `/api/v1/admin/users`         | Admin   | List users (role/search/pagination)      |
| PATCH  | `/api/v1/admin/users/:id/role`| Admin   | Change a user's role                     |
| POST   | `/api/v1/admin/users/:id/ban` | Admin   | Ban / restore a user                     |

### Admin settings (`GET|PUT /api/v1/admin/settings`)

Platform-wide switches persisted in a single `AdminSettings` document and
enforced server-side:

| Field                  | Type    | Effect                                                     |
| ---------------------- | ------- | ---------------------------------------------------------- |
| `maintenanceMode`      | boolean | Members cannot create posts/stories (HTTP 503); admins bypass |
| `verifiedOnlyExplore`  | boolean | Explore feed only shows posts by verified creators         |
| `aiTriage`             | boolean | Gates the AI pipeline's auto-flagging of severe content    |

```bash
curl -X PUT http://localhost:4000/api/v1/admin/settings \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d '{"maintenanceMode": true}'
```

## Seed data & scripts

From the `backend/` directory (reads `MONGODB_URI` from `.env`):

```bash
node scripts/seed.mjs          # fresh demo dataset (wipes first)
node scripts/seed-posts.mjs    # add 200 realistic posts (additive)
bash scripts/e2e-test.sh       # E2E sweep of every DB-writing endpoint
```

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
