from fastapi import APIRouter

from app.api.v1.endpoints.health import router as health_router
from app.api.v1.endpoints.insights import router as insights_router
from app.api.v1.endpoints.transactions import router as transactions_router
from app.api.v1.endpoints.assistant import router as assistant_router
from app.api.v1.endpoints.subscriptions import router as subscriptions_router


api_router = APIRouter()
api_router.include_router(health_router, prefix="/health", tags=["health"])
api_router.include_router(transactions_router, prefix="/transactions", tags=["transactions"])
api_router.include_router(insights_router, prefix="/insights", tags=["insights"])
api_router.include_router(assistant_router, prefix="/assistant", tags=["assistant"])
api_router.include_router(subscriptions_router, prefix="/subscriptions", tags=["subscriptions"])
