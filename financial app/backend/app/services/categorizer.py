CATEGORY_ALIASES = {
    "food": "food",
    "grocery": "groceries",
    "groceries": "groceries",
    "rent": "rent",
    "transport": "transport",
    "travel": "travel",
    "utility": "utilities",
    "utilities": "utilities",
    "mobile recharge": "mobile_recharge",
    "bkash cashout": "wallet_fees",
    "nagad cashout": "wallet_fees",
}


def normalize_category(raw: str) -> str:
    key = raw.strip().lower()
    return CATEGORY_ALIASES.get(key, key.replace(" ", "_"))
