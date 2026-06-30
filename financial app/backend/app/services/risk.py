from app.ml.models.classify_risk import classify_overspending_risk


def detect_risk(user_id: int) -> dict[str, str | float]:
    score = classify_overspending_risk(user_id=user_id)
    if score >= 0.75:
        return {
            "risk_level": "high",
            "risk_score": score,
            "reason": "Projected expenses are significantly above expected safe threshold.",
        }
    if score >= 0.45:
        return {
            "risk_level": "medium",
            "risk_score": score,
            "reason": "Projected spending is trending above your average income ratio.",
        }
    return {
        "risk_level": "low",
        "risk_score": score,
        "reason": "Projected spending appears manageable based on recent behavior.",
    }
