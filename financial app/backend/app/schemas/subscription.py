from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field

from app.db.models import SubscriptionBillingCycle, SubscriptionStatus, TransactionChannel


class SubscriptionBase(BaseModel):
    name: str = Field(..., max_length=120)
    amount: Decimal = Field(..., gt=0, decimal_places=2)
    currency: str = Field("BDT", max_length=10)
    billing_cycle: SubscriptionBillingCycle
    start_date: date
    next_billing_date: date
    last_billed_date: Optional[date] = None
    category: str = Field(..., max_length=60)
    channel: TransactionChannel = Field(TransactionChannel.CASH)
    status: SubscriptionStatus = Field(SubscriptionStatus.ACTIVE)
    auto_renew: bool = Field(True)
    user_id: int


class SubscriptionCreate(SubscriptionBase):
    pass


class SubscriptionUpdate(SubscriptionBase):
    name: Optional[str] = Field(None, max_length=120)
    amount: Optional[Decimal] = Field(None, gt=0, decimal_places=2)
    currency: Optional[str] = Field(None, max_length=10)
    billing_cycle: Optional[SubscriptionBillingCycle] = None
    start_date: Optional[date] = None
    next_billing_date: Optional[date] = None
    category: Optional[str] = Field(None, max_length=60)
    channel: Optional[TransactionChannel] = None
    status: Optional[SubscriptionStatus] = None
    auto_renew: Optional[bool] = None
    user_id: Optional[int] = None # User_id should not be updated directly


class SubscriptionRead(SubscriptionBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
