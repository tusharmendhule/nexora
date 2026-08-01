"""Fact-check lookup powered by Google Gemini (primary) with a legacy
Google Fact Check Tools API fallback. Both degrade gracefully to [] when
no API key is configured, so the service still runs locally.
"""

import json
import re

import httpx

from app.config import settings

FACTCHECK_URL = "https://factchecktools.googleapis.com/v1alpha1/claims:search"
GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "gemini-1.5-flash:generateContent"
)

_JSON_BLOCK = re.compile(r"```(?:json)?\s*(.*?)```", re.DOTALL)


async def search_fact_checks(query: str, language_code: str = "en") -> list[dict]:
    if settings.gemini_api_key:
        items = await _gemini_factcheck(query)
        if items:
            return items
    if settings.factcheck_api_key:
        return await _legacy_factcheck(query, language_code)
    print("[factcheck] no GEMINI_API_KEY configured — returning empty results.")
    return []


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
                        "maxOutputTokens": 1024,
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
    return text


async def _legacy_factcheck(query: str, language_code: str) -> list[dict]:
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                FACTCHECK_URL,
                params={
                    "query": query,
                    "languageCode": language_code,
                    "key": settings.factcheck_api_key,
                },
            )
            resp.raise_for_status()
            claims = resp.json().get("claims", [])
        items = []
        for claim in claims:
            review = (claim.get("claimReview") or [{}])[0]
            items.append(
                {
                    "publisher": (review.get("publisher") or {}).get("name", ""),
                    "title": review.get("title", ""),
                    "url": review.get("url", ""),
                    "rating": review.get("textualRating", ""),
                    "checked_date": review.get("reviewDate"),
                }
            )
        return items
    except Exception as exc:  # pragma: no cover
        print(f"[factcheck] legacy lookup failed: {exc}")
        return []
