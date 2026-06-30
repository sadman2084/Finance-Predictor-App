from __future__ import annotations

from collections import defaultdict

from sqlalchemy.orm import Session

from app.db import models


def build_savings_recommendations(user_id: int, db: Session) -> list[str]:
    txns = (
        db.query(models.Transaction)
        .filter(models.Transaction.user_id == user_id)
        .order_by(models.Transaction.txn_date.desc())
        .all()
    )

    if not txns:
        return [
            "No transaction history found yet. Add at least 5 records for personalized recommendations.",
            "Start by tracking groceries and transport to uncover your recurring expense pattern.",
            "Set a small weekly savings target and increase it gradually.",
        ]

    total_spent = 0.0
    category_spent: dict[str, float] = defaultdict(float)
    wallet_fee_count = 0

    for txn in txns:
        amount = float(txn.amount)
        total_spent += amount
        category_spent[txn.category] += amount
        if "wallet" in txn.category.lower():
            wallet_fee_count += 1

    avg_txn = total_spent / len(txns)
    top_category, top_amount = max(category_spent.items(), key=lambda item: item[1])

    recommendations = [
        f"Your highest spend is in '{top_category}' (about {top_amount:.0f} BDT). Set a category cap for next month.",
        f"Average expense per transaction is {avg_txn:.0f} BDT. Try reducing this by 10% to improve savings.",
    ]

    if wallet_fee_count >= 3:
        recommendations.append("Frequent wallet fees detected. Batch bKash/Nagad cash-outs to reduce charges.")

    if total_spent > 30000:
        recommendations.append("Monthly expense level is high. Move non-essential purchases to a weekly fixed budget.")
    else:
        recommendations.append("Current spending is manageable. Direct a fixed share of income to emergency savings.")

    return recommendations[:4]
