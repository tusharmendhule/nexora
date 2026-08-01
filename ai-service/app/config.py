import os

from dotenv import load_dotenv

load_dotenv()


class Settings:
    port: int = int(os.getenv("AI_SERVICE_PORT", "8000"))
    log_level: str = os.getenv("LOG_LEVEL", "info")

    # Google Gemini API key used for real fact-checking (recommended).
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    # Legacy Google Fact Check Tools key (falls back to Gemini when unset).
    factcheck_api_key: str = os.getenv("GOOGLE_FACTCHECK_API_KEY", "")

    # Model name used when the transformers stack is installed.
    # e.g. "distilbert-base-uncased" for classification heads.
    model_name: str = os.getenv("MODEL_NAME", "distilbert-base-uncased")


settings = Settings()
