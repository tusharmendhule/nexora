"""NLP processing for Nexora's trust scoring.

Computes six content-risk checks (fake news, hate speech, toxic language,
clickbait, spam, offensive content) using lightweight heuristics so the
service runs out-of-the-box in development, plus an optional Hugging Face
sentiment pass when the transformers stack is installed. A Gemini LLM pass
(content_review.py) refines the checks when an API key is configured.
"""

import re

_pipeline = None
_use_model = False

# One entry per content check. `weight` converts matched signals into risk
# points (each check is capped at a 100 risk score). `extra` adds
# punctuation/link-based signals for the categories that benefit from them.
_CATEGORIES = [
    {
        "name": "fakeNews",
        "label": "Fake news",
        "weight": 15,
        "signals": [
            "they don't want you to know",
            "the truth about",
            "wake up people",
            "mainstream media won't tell you",
            "big pharma",
            "deep state",
            "government is hiding",
            "100% proof",
            "share before it's deleted",
            "do your own research",
            "chem trails",
            "5g causes",
            "miracle cure",
            "vaccine is a",
            "flat earth",
            "nasa lies",
        ],
    },
    {
        "name": "hateSpeech",
        "label": "Hate speech",
        "weight": 25,
        "signals": [
            "white power",
            "kill all jews",
            "heil hitler",
            "nazi",
            "kike",
            "wetback",
            "gook",
            "chink",
            "porch monkey",
            "sand nigger",
            "faggot",
            "tranny",
            "retard",
            "lynch",
        ],
    },
    {
        "name": "toxicLanguage",
        "label": "Toxic language",
        "weight": 18,
        "signals": [
            "hate",
            "kill yourself",
            "die",
            "stupid",
            "idiot",
            "moron",
            "loser",
            "worthless",
            "shut up",
            "freak",
            "pathetic",
            "garbage",
        ],
    },
    {
        "name": "clickbait",
        "label": "Clickbait",
        "weight": 12,
        "signals": [
            "you won't believe",
            "shocking",
            "secret",
            "must see",
            "the one thing",
            "doctors hate",
            "number 1 trick",
            "this will blow your mind",
            "you need to see",
            "unbelievable",
        ],
    },
    {
        "name": "spam",
        "label": "Spam",
        "weight": 12,
        "signals": [
            "free money",
            "click here",
            "limited time",
            "win a prize",
            "make money fast",
            "crypto giveaway",
            "bitcoin giveaway",
            "dm me",
            "follow me for",
            "promo code",
            "buy now",
            "hot deal",
            "earn cash",
            "work from home",
            "cash prize",
        ],
    },
    {
        "name": "offensiveContent",
        "label": "Offensive content",
        "weight": 20,
        "signals": [
            "fuck",
            "shit",
            "bitch",
            "cunt",
            "asshole",
            "bastard",
            "whore",
            "slut",
            "porn",
            "sex tape",
            "dick",
            "pussy",
            "nudes",
            "dick pic",
            "onlyfans",
        ],
    },
]

_REPEATED_CHARS = re.compile(r"(.)\1{3,}")


def _level_for(risk: float) -> str:
    if risk >= 60:
        return "high"
    if risk >= 35:
        return "medium"
    if risk >= 15:
        return "low"
    return "none"


def _heuristic_checks(text: str) -> list[dict]:
    """Compute the six risk checks from lightweight text signals."""
    lowered = text.lower()
    checks = []
    for cat in _CATEGORIES:
        hits = [s for s in cat["signals"] if s in lowered]
        extra = 0
        if cat["name"] == "spam":
            extra += min(lowered.count("http"), 5) * 8
            extra += min(len(_REPEATED_CHARS.findall(lowered)), 3) * 5
        if cat["name"] == "clickbait":
            extra += min(text.count("!"), 6) * 3
        risk = min(100.0, len(hits) * cat["weight"] + extra)
        checks.append(
            {
                "name": cat["name"],
                "label": cat["label"],
                "score": round(risk, 1),
                "level": _level_for(risk),
                "flags": hits[:5],
                "detail": f"{len(hits)} signal(s) matched" if hits else "no signals found",
            }
        )
    return checks


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


def score_for_checks(checks: list[dict]) -> float:
    """Derive a 0-100 trust score from the six risk checks.

    Heavier categories (hate speech, offensive content) drag the score down
    faster than lighter ones (clickbait, spam).
    """
    penalties = {
        "fakeNews": 0.35,
        "hateSpeech": 0.5,
        "toxicLanguage": 0.3,
        "clickbait": 0.2,
        "spam": 0.25,
        "offensiveContent": 0.4,
    }
    score = 100.0
    for check in checks:
        score -= check["score"] * penalties.get(check["name"], 0.3)
    return round(max(0.0, min(100.0, score)), 1)


def label_for_score(score: float) -> str:
    if score >= 75:
        return "Verified"
    if score >= 60:
        return "Vetted"
    if score >= 40:
        return "Watch"
    return "Restricted"


def label_for_checks(checks: list[dict], score: float) -> str:
    """Label that never contradicts a high-risk check.

    A post with any "high" check is pulled for moderation, so its badge must
    not read "Verified"/"Vetted" — cap it at "Watch" (or worse by score).
    """
    label = label_for_score(score)
    if any(c.get("level") == "high" for c in checks) and label in (
        "Verified",
        "Vetted",
    ):
        return "Watch"
    return label


def factors_for_checks(checks: list[dict]) -> list[dict]:
    """Build the per-check factor list (mirrors the checks data)."""
    return [
        {
            "name": check["name"],
            "value": round(check["score"] / 100.0, 3),
            "detail": f"{check['label']}: {check['level']}",
        }
        for check in checks
    ]


def analyze_text(text: str, language: str = "en") -> dict:
    """Return a trust score (0-100) + label + six content checks."""
    checks = _heuristic_checks(text)
    score = score_for_checks(checks)
    factors = factors_for_checks(checks)

    model = _get_pipeline()
    if model is not None:
        try:
            result = model(text[:512])[0]
            confidence = float(result["score"])
            polarity = 1 if result["label"] == "POSITIVE" else -1
            # Trust is primarily check-driven; sentiment only nudges it.
            score = round(max(0.0, min(100.0, score + polarity * confidence * 5)), 1)
            factors.insert(
                0,
                {
                    "name": "sentiment",
                    "value": round(confidence, 3),
                    "detail": f"{result['label']} ({confidence:.2f})",
                },
            )
        except Exception as exc:  # pragma: no cover
            print(f"[nlp] model inference failed, falling back: {exc}")

    return {
        "score": score,
        "label": label_for_checks(checks, score),
        "factors": factors,
        "checks": checks,
    }
