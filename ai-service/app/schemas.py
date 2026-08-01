from pydantic import BaseModel, Field


class AnalyzeRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2200)
    language: str = "en"


class Factor(BaseModel):
    name: str
    value: float
    detail: str = ""


class FactCheckEvidence(BaseModel):
    publisher: str = ""
    title: str = ""
    url: str = ""
    rating: str = ""
    checked_date: str | None = None


class AnalyzeResponse(BaseModel):
    score: float = Field(..., ge=0, le=100)
    label: str
    factors: list[Factor] = []
    factChecks: list[FactCheckEvidence] = []


class FactCheckItem(BaseModel):
    publisher: str = ""
    title: str = ""
    url: str = ""
    rating: str = ""
    checked_date: str | None = None


class FactCheckResponse(BaseModel):
    query: str
    data: list[FactCheckItem] = []
