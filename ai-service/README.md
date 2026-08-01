# Nexora AI Service (Python + FastAPI)

Model inference and NLP processing for Nexora trust scoring and verification.

## Stack

- **FastAPI** (async) with automatic OpenAPI docs
- **Hugging Face transformers / PyTorch** for model inference (optional local install)
- **Google Gemini** for claim-review lookup + LLM content review (set `GEMINI_API_KEY` in `.env` — see `.env.example`)
- Graceful **heuristic fallback** when models aren't installed

## Setup

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload    # http://localhost:8000
```

Docs: http://localhost:8000/docs

## Endpoints

| Method | Route            | Description                                  |
| ------ | ---------------- | -------------------------------------------- |
| GET    | `/health`        | Health check                                 |
| POST   | `/v1/analyze`    | Trust score + label + six content checks     |
| GET    | `/v1/factcheck`  | Look up claim reviews (`?query=...`)         |

`POST /v1/analyze` returns a 0–100 trust score, a color-coded label, and six
content-risk checks (fake news, hate speech, toxic language, clickbait, spam,
offensive content), each with a risk score 0–100, a `none/low/medium/high`
level, and the matched signals. The Gemini LLM pass (`content_review.py`)
refines the checks when `GEMINI_API_KEY` is set; otherwise heuristic checks
are the guaranteed fallback.

## Structure

```
app/
├── main.py            # FastAPI app
├── config.py          # settings from env
├── schemas.py         # pydantic models
├── routes/v1.py       # /v1/analyze, /v1/factcheck
└── services/
    ├── nlp.py         # transformers inference + heuristic fallback
    ├── content_review.py # Gemini LLM content checks (optional)
    └── factcheck.py   # Gemini fact-check client (optional)
```
