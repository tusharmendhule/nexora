from fastapi import APIRouter, HTTPException

from app.schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    FactCheckItem,
    FactCheckResponse,
)
from app.services.factcheck import search_fact_checks
from app.services.nlp import (
    analyze_text,
    factors_for_checks,
    label_for_checks,
    score_for_checks,
)
from app.services.content_review import review_content

router = APIRouter(prefix="/v1", tags=["v1"])


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(req: AnalyzeRequest):
    """Analyze post text and return a trust score + label + factors + six
    content checks (fake news, hate speech, toxic language, clickbait, spam,
    offensive content), enriched with Gemini when a key is configured."""
    result = analyze_text(req.text, req.language)

    # Refine the six checks with an LLM pass when a key is available; the
    # heuristic checks are already in `result` as a guaranteed fallback.
    refined = await review_content(req.text)
    if refined:
        result["checks"] = refined
        result["score"] = score_for_checks(refined)
        result["label"] = label_for_checks(refined, result["score"])
        # Keep the factors in sync with the refined checks so downstream
        # consumers (Trust Center) never see stale heuristic levels.
        result["factors"] = [
            *factors_for_checks(refined),
            *(f for f in result.get("factors", []) if f.get("name") == "sentiment"),
        ]

    # Enrich with real fact-check evidence (only when a key is available).
    if req.text.strip():
        try:
            checks = await search_fact_checks(req.text[:300])
            if checks:
                result["factChecks"] = checks
                # A confirmed fact-check bumps confidence.
                true_ratings = {
                    "true",
                    "mostly true",
                    "accurate",
                    "correct",
                }
                false_ratings = {"false", "mostly false", "misleading", "inaccurate"}
                lowest = checks[0]["rating"].lower()
                if any(r in lowest for r in true_ratings):
                    result["score"] = round(min(100.0, result["score"] + 5), 1)
                    result["label"] = label_for_checks(
                        result["checks"], result["score"]
                    )
                elif any(r in lowest for r in false_ratings):
                    result["score"] = round(max(0.0, result["score"] - 12), 1)
                    result["label"] = label_for_checks(
                        result["checks"], result["score"]
                    )
                result["factors"] = [
                    *result.get("factors", []),
                    {
                        "name": "factCheck",
                        "value": len(checks),
                        "detail": f"{len(checks)} claim review(s) found",
                    },
                ]
        except Exception as exc:  # pragma: no cover
            print(f"[analyze] fact-check enrichment skipped: {exc}")

    return AnalyzeResponse(**result)


@router.get("/factcheck", response_model=FactCheckResponse)
async def factcheck(query: str):
    """Look up known claim reviews for a query via Gemini."""
    if not query.strip():
        raise HTTPException(status_code=400, detail="query parameter required")
    items = await search_fact_checks(query)
    return FactCheckResponse(query=query, data=[FactCheckItem(**i) for i in items])
