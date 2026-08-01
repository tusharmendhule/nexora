"""LLM content review via Google Gemini.

Refines the six content-risk checks (fake news, hate speech, toxic language,
clickbait, spam, offensive content) with a structured LLM pass. Degrades
gracefully to the heuristic checks when no API key is configured.
"""

import json

import httpx

from app.config import settings
from app.services.factcheck import GEMINI_URL, _strip_json

_CHECK_NAMES = [
    ("fakeNews", "Fake news"),
    ("hateSpeech", "Hate speech"),
    ("toxicLanguage", "Toxic language"),
    ("clickbait", "Clickbait"),
    ("spam", "Spam"),
    ("offensiveContent", "Offensive content"),
]

_VALID_LEVELS = {"none", "low", "medium", "high"}


def _level_for(risk: float) -> str:
    if risk >= 60:
        return "high"
    if risk >= 35:
        return "medium"
    if risk >= 15:
        return "low"
    return "none"


async def review_content(text: str) -> list[dict] | None:
    """Return refined checks for the text, or None when Gemini is unavailable."""
    if not settings.gemini_api_key or not text.strip():
        return None
    try:
        return await _gemini_review(text)
    except Exception as exc:  # pragma: no cover
        print(f"[content_review] Gemini review failed: {exc}")
        return None


async def _gemini_review(text: str) -> list[dict]:
    """Ask Gemini to score the six categories and return structured checks."""
    prompt = (
        "You are a content moderation assistant for a social network. "
        "Analyze the following text and return a JSON array of exactly 6 "
        "objects, one per category, in this exact order: fakeNews, "
        "hateSpeech, toxicLanguage, clickbait, spam, offensiveContent. Each "
        "object must have exactly these keys: name (string), label (string), "
        "score (a float between 0 and 100, the risk probability), level (one "
        "of: none, low, medium, high), flags (an array of short exact phrases "
        "from the text that triggered the flag, empty array if none), detail "
        "(one short sentence explaining the verdict). Use level \"high\" only "
        "for severe content. Text:\n"
        + text
    )
    async with httpx.AsyncClient(timeout=20.0) as client:
        resp = await client.post(
            GEMINI_URL,
            params={"key": settings.gemini_api_key},
            json={
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                    "temperature": 0.2,
                    "maxOutputTokens": 8192,
                    # Gemini 2.x models spend their token budget on
                    # "thinking" by default (900+ tokens), truncating the
                    # JSON answer. Disable it and keep the budget large.
                    "thinkingConfig": {"thinkingBudget": 0},
                },
            },
        )
        resp.raise_for_status()
        data = resp.json()
    raw = (
        (data.get("candidates") or [{}])[0]
        .get("content", {})
        .get("parts", [{}])[0]
        .get("text", "")
    )
    items = json.loads(_strip_json(raw))
    if not isinstance(items, list):
        return []
    by_name = {i.get("name"): i for i in items if isinstance(i, dict)}

    checks = []
    for name, fallback_label in _CHECK_NAMES:
        item = by_name.get(name, {})
        risk = max(0.0, min(100.0, float(item.get("score") or 0)))
        flags = item.get("flags") or []
        # Normalize the LLM's level: Gemini often returns "High", "HIGH" or
        # "Severe". Anything outside the known set falls back to the
        # score-derived level so the backend's enum + flag gate stay intact.
        level = str(item.get("level") or "").lower().strip()
        if level not in _VALID_LEVELS:
            level = _level_for(risk)
        checks.append(
            {
                "name": name,
                "label": str(item.get("label") or fallback_label),
                "score": round(risk, 1),
                "level": level,
                "flags": [str(f) for f in flags][:5] if isinstance(flags, list) else [],
                "detail": str(item.get("detail", "")),
            }
        )
    return checks
