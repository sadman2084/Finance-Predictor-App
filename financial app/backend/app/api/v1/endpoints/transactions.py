from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import models
from app.db.session import get_db
from app.schemas import TransactionCreate, TransactionRead
from app.services.categorizer import normalize_category


router = APIRouter()


@router.post("/", response_model=TransactionRead)
def create_transaction(payload: TransactionCreate, db: Session = Depends(get_db)):
    txn = models.Transaction(
        user_id=payload.user_id,
        txn_date=payload.txn_date,
        amount=Decimal(str(payload.amount)),
        category=normalize_category(payload.category),
        channel=payload.channel,
        description=payload.description,
    )
    db.add(txn)
    db.commit()
    db.refresh(txn)
    return txn


@router.get("/", response_model=list[TransactionRead])
def list_transactions(db: Session = Depends(get_db)):
    return db.query(models.Transaction).order_by(models.Transaction.txn_date.desc()).all()
