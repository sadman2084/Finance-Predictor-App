from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.ml.pipelines.predict import predict_next_month_expenses
from app.schemas import ForecastPoint, RiskResponse
from app.services.risk import detect_risk
from app.services.recommendation import build_savings_recommendations


router = APIRouter()


@router.get("/forecast", response_model=list[ForecastPoint])
def forecast(user_id: int = Query(..., gt=0), db: Session = Depends(get_db)):
    points = predict_next_month_expenses(user_id=user_id, db=db)
    return [ForecastPoint(period=p["period"], predicted_expense=p["predicted_expense"]) for p in points]


@router.get("/risk", response_model=RiskResponse)
def risk(user_id: int = Query(..., gt=0)):
    result = detect_risk(user_id=user_id)
    return RiskResponse(**result)


@router.get("/recommendations")
def recommendations(user_id: int = Query(..., gt=0), db: Session = Depends(get_db)):
    return {"recommendations": build_savings_recommendations(user_id=user_id, db=db)}
