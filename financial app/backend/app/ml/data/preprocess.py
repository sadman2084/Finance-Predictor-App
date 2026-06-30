import pandas as pd


BANGLADESH_FESTIVE_MONTHS = {3, 4, 5, 9, 10}  # Eid and Durga Puja windows vary yearly.


def add_local_features(df: pd.DataFrame) -> pd.DataFrame:
    data = df.copy()
    data["month"] = pd.to_datetime(data["txn_date"]).dt.month
    data["is_festive_season"] = data["month"].isin(BANGLADESH_FESTIVE_MONTHS).astype(int)
    data["is_salary_cycle_day"] = pd.to_datetime(data["txn_date"]).dt.day.isin([1, 2, 3, 25, 26, 27]).astype(int)
    return data
