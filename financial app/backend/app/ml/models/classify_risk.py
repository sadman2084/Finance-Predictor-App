def classify_overspending_risk(user_id: int) -> float:
    # Placeholder for binary/ordinal classifier output in [0, 1].
    baseline = 0.35
    drift = (user_id % 7) * 0.07
    return min(round(baseline + drift, 2), 0.98)
