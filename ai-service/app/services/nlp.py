"""NLP processing for Nexora's trust scoring.

Uses Hugging Face transformers when installed (heavy), otherwise falls back to
a lightweight heuristic so the service runs out-of-the-box in development.
"""

_pipeline = None
_use_model = False


def _get_pipeline():
    """Lazily load the transformers pipeline on first use.

    Loading happens at call time (not import time) so `/health` and the
    heuristic fallback work even before the model stack is installed.
    """
    global _pipeline, _use_model
    if _pipeline is None:
        try:
            from transformers import pipeline  # type: ignore

            _pipeline = pipeline(
                "text-classification",
                model="distilbert-base-uncased-finetuned-sst-2-english",
            )
            _use_model = True
        except Exception as exc:  # pragma: no cover - transformers not installed
            print(f"[nlp] transformers unavailable, using heuristic: {exc}")
            _use_model = False
    return _pipeline if _use_model else None


def _heuristic(text: str) -> dict:
    """Simple content-based signals used when no model is available."""
    lowered = text.lower()
    signals = {
        "toxicity": sum(
            w in lowered for w in ["hate", "kill", "stupid", "idiot", "fake news"]
        ),
        "clickbait": sum(
            w in lowered
            for w in [
                "you won't believe",
                "shocking",
                "secret",
                "must see",
                "?!?",
                "!!!",
            ]
        ),
        "length": min(len(text) / 200.0, 1.0),
    }
    score = max(0.0, 100.0 - (signals["toxicity"] * 25 + signals["clickbait"] * 20))
    factors = [
        {"name": "toxicity", "value": signals["toxicity"], "detail": "flag-word count"},
        {"name": "clickbait", "value": signals["clickbait"], "detail": "clickbait phrase count"},
    ]
    return {"score": round(score, 1), "factors": factors}


def _label_for(score: float) -> str:
    if score >= 75:
        return "Verified"
    if score >= 60:
        return "Vetted"
    if score >= 40:
        return "Watch"
    return "Restricted"


def analyze_text(text: str, language: str = "en") -> dict:
    """Return a trust score (0-100) + label + factors for a piece of text."""
    model = _get_pipeline()
    if model is not None:
        try:
            result = model(text[:512])[0]
            confidence = float(result["score"])
            # Map sentiment classifier output to a trust score range.
            score = (
                50 + confidence * 50
                if result["label"] == "POSITIVE"
                else 50 - confidence * 50
            )
            score = round(max(0.0, min(100.0, score)), 1)
            return {
                "score": score,
                "label": _label_for(score),
                "factors": [
                    {
                        "name": "sentiment",
                        "value": confidence,
                        "detail": f"{result['label']} ({confidence:.2f})",
                    }
                ],
            }
        except Exception as exc:  # pragma: no cover
            print(f"[nlp] model inference failed, falling back: {exc}")

    result = _heuristic(text)
    result["label"] = _label_for(result["score"])
    return result
