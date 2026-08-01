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
| POST   | `/v1/analyze`    | Trust score + label + factors for text       |
| GET    | `/v1/factcheck`  | Look up claim reviews (`?query=...`)         |

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
