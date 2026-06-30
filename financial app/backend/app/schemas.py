from datetime import date

from pydantic import BaseModel, Field

from app.db.models import TransactionChannel


class TransactionCreate(BaseModel):
    user_id: int
    txn_date: date
    amount: float = Field(gt=0)
    category: str = Field(min_length=2, max_length=60)
    channel: TransactionChannel = TransactionChannel.CASH
    description: str | None = None


class TransactionRead(TransactionCreate):
    id: int

    class Config:
        from_attributes = True


class ForecastPoint(BaseModel):
    period: str
    predicted_expense: float


class RiskResponse(BaseModel):
    risk_level: str
    risk_score: float
    reason: str
