"""Fact-check lookup powered by Google Gemini. Degrades gracefully to []
when no API key is configured, so the service still runs locally.
"""

import json
import re

import httpx

from app.config import settings

GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    f"{settings.gemini_model}:generateContent"
)

_JSON_BLOCK = re.compile(r"```(?:json)?\s*(.*?)```", re.DOTALL)


async def search_fact_checks(query: str, language_code: str = "en") -> list[dict]:
    if not settings.gemini_api_key:
        print("[factcheck] no GEMINI_API_KEY configured — returning empty results.")
        return []
    items = await _gemini_factcheck(query)
    if not items:
        print("[factcheck] Gemini found no verifiable sources — returning empty results.")
    return items


async def _gemini_factcheck(query: str) -> list[dict]:
    """Ask Gemini to research a claim and return structured fact-check items."""
    prompt = (
        "You are a professional fact-checker. Research the following claim and "
        "return a JSON array of fact-check findings. Each item must have exactly "
        "these keys: publisher (string), title (string), url (string), rating "
        "(one of: True, Mostly true, Half true, Mostly false, False, Unverified), "
        "checked_date (ISO date string or null). If the claim is not verifiable "
        "or no credible source exists, return an empty array. Do not invent "
        "sources. Claim: "
        + query
    )
    try:
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
        text = (data.get("candidates") or [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        text = _strip_json(text)
        items = json.loads(text)
        if not isinstance(items, list):
            return []
        return [
            {
                "publisher": str(i.get("publisher", "")),
                "title": str(i.get("title", "")),
                "url": str(i.get("url", "")),
                "rating": str(i.get("rating", "")),
                "checked_date": i.get("checked_date"),
            }
            for i in items
            if isinstance(i, dict)
        ][:5]
    except Exception as exc:  # pragma: no cover
        print(f"[factcheck] Gemini lookup failed: {exc}")
        return []


def _strip_json(text: str) -> str:
    """Extract the first JSON array/object from a model response."""
    text = text.strip()
    block = _JSON_BLOCK.search(text)
    if block:
        text = block.group(1).strip()
    start = text.find("[")
    end = text.rfind("]")
    if start != -1 and end != -1 and end > start:
        return text[start : end + 1]
    if start != -1:
        # Truncated response: an array was started but never closed.
        # Return an empty array so the caller degrades instead of crashing.
        return "[]"
    return text


