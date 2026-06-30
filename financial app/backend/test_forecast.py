#!/usr/bin/env python3
"""Quick test script to verify forecast integration."""
import sys
from app.ml.models.forecast import forecast_monthly_expense

result = forecast_monthly_expense(user_id=1, horizon_months=3)
print("✓ Forecast model loaded successfully")
print("\nPredicted Monthly Expenses:")
for point in result:
    print(f"  {point['period']}: ৳{point['predicted_expense']}")
