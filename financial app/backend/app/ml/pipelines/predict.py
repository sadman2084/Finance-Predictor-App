from sqlalchemy.orm import Session

from app.ml.models.forecast import forecast_monthly_expense


def predict_next_month_expenses(user_id: int, db: Session | None = None) -> list[dict[str, float | str]]:
    return forecast_monthly_expense(user_id=user_id, horizon_months=1, db=db)
