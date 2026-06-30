from functools import lru_cache

from fastapi import Header, HTTPException, status

from app.core.config import settings


@lru_cache(maxsize=1)
def _firebase_auth():
    try:
        import firebase_admin
        from firebase_admin import auth, credentials
    except ImportError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="firebase-admin is required when FIREBASE_AUTH_REQUIRED=true",
        ) from exc

    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.ApplicationDefault())
    return auth


def get_current_user(authorization: str | None = Header(default=None)) -> dict[str, str]:
    if not settings.FIREBASE_AUTH_REQUIRED:
        return {"uid": "dev-user"}

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Firebase bearer token",
        )

    token = authorization.removeprefix("Bearer ").strip()
    try:
        decoded = _firebase_auth().verify_id_token(token)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase token",
        ) from exc

    return {"uid": decoded.get("uid", "")}
