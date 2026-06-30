import pandas as pd

from app.ml.data.preprocess import add_local_features


def train_pipeline(dataset_path: str) -> dict[str, str]:
    df = pd.read_csv(dataset_path)
    featured = add_local_features(df)

    # Placeholders: train forecasting, classification, and clustering models.
    _ = featured

    return {
        "status": "ok",
        "message": "Training pipeline executed with Bangladesh-localized feature engineering.",
    }
