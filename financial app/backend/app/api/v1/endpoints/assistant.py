import json
import re
import logging
from datetime import date
from typing import Any

import httpx
import google.generativeai as genai
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.core.auth import get_current_user
from app.core.config import settings

router = APIRouter(dependencies=[Depends(get_current_user)])


class AssistantChatRequest(BaseModel):
    message: str = Field(min_length=2, max_length=4000)
    context: dict[str, Any] = Field(default_factory=dict)


class AssistantChatResponse(BaseModel):
    reply: str


class SmsImportRequest(BaseModel):
    message: str = Field(min_length=5, max_length=3000)


class ParsedTransaction(BaseModel):
    amount: float
    category: str
    channel: str
    description: str
    txn_date: date | None = None


class ReceiptScanRequest(BaseModel):
    text: str | None = Field(default=None, max_length=6000)
    image_base64: str | None = None
    mime_type: str = "image/jpeg"


def _local_chat_reply(message: str, context: dict[str, Any] | None = None) -> str:
    """Generate a local reply without calling any external AI API."""
    lowered = message.lower()
    ctx = context or {}

    total_income = ctx.get("total_income", 0)
    total_expense = ctx.get("total_expense", 0)
    net_savings = ctx.get("net_savings", 0)
    txn_count = ctx.get("transaction_count", 0)
    debt_remaining = ctx.get("debt_remaining", 0)

    if any(w in lowered for w in ["hi", "hello", "hey"]):
        return "Hello! I'm your finance assistant. Ask me about your budget, spending, savings, or debts."

    if "spend" in lowered or "expense" in lowered or "spending" in lowered:
        if total_expense > 0:
            return f"Your total expenses so far are BDT {total_expense:,.0f} across {txn_count} transactions. Would you like a breakdown by category?"
        return "You don't have any expenses recorded yet. Add transactions first and I can help analyze your spending."

    if "income" in lowered or "earn" in lowered or "salary" in lowered:
        if total_income > 0:
            return f"Your total income is BDT {total_income:,.0f}. Your savings rate is {((net_savings / total_income) * 100):.0f}%."
        return "No income recorded yet. Track your earnings to get better insights."

    if "sav" in lowered or "save" in lowered or "budget" in lowered:
        if net_savings > 0:
            return f"Your net savings are BDT {net_savings:,.0f}. Great job! Try to save at least 20% of your income each month."
        elif net_savings < 0:
            return f"You're spending BDT {abs(net_savings):,.0f} more than you earn. Consider reviewing your expenses to find areas to cut back."
        return "Your income and expenses are balanced. Look for ways to increase your savings."

    if "debt" in lowered or "loan" in lowered or "owe" in lowered:
        if debt_remaining > 0:
            return f"You have BDT {debt_remaining:,.0f} in outstanding debts. Consider prioritizing high-interest debts first."
        return "You have no outstanding debts. That's excellent!"

    if "help" in lowered:
        return "I can help with:\n• Spending analysis\n• Budget tips\n• Savings goals\n• Debt tracking\nJust ask me about any of these!"

    # Default response
    return (
        f"Based on your finances: Income BDT {total_income:,.0f}, "
        f"Expenses BDT {total_expense:,.0f}, "
        f"Net BDT {net_savings:,.0f}. "
        f"Ask me about spending, savings, budget tips, or debts!"
    )


async def _call_gemini(prompt: str, image_base64: str | None = None, mime_type: str = "image/jpeg") -> str | None:  # noqa: E501
    if not settings.GEMINI_API_KEY:
        return None
    
    genai.configure(api_key=settings.GEMINI_API_KEY)
    
    try:
        model = genai.GenerativeModel(settings.GEMINI_MODEL)
        
        content = [prompt]
        if image_base64:
            from PIL import Image
            import io
            import base64
            
            image_data = base64.b64decode(image_base64)
            img = Image.open(io.BytesIO(image_data))
            content.append(img)
            
        response = await model.generate_content_async(content)
        return response.text
    except Exception as e:
        logger.error(f"Error calling Gemini API: {e}", exc_info=True)
        return None


def _json_from_text(text: str) -> dict[str, Any]:
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        raise ValueError("No JSON object found")
    return json.loads(match.group(0))


def _fallback_parse_transaction(text: str) -> ParsedTransaction:
    lowered = text.lower()
    amount_match = re.search(r"(?:bdt|tk|৳)?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]+)?)", lowered)
    amount = float(amount_match.group(1).replace(",", "")) if amount_match else 0.0

    channel = "cash"
    for candidate in ["bkash", "nagad", "rocket", "bank"]:
        if candidate in lowered:
            channel = candidate
            break

    category = "shopping"
    category_rules = {
        "food": ["restaurant", "cafe", "food", "meal", "lunch", "dinner"],
        "transportation": ["uber", "pathao", "ride", "bus", "train", "fuel"],
        "phone": ["recharge", "airtime", "mobile"],
        "education": ["tuition", "school", "course"],
        "salary": ["salary", "payroll"],
    }
    for name, keywords in category_rules.items():
        if any(keyword in lowered for keyword in keywords):
            category = name
            break

    return ParsedTransaction(
        amount=amount,
        category=category,
        channel=channel,
        description=text[:180],
    )


@router.post("/chat", response_model=AssistantChatResponse)
async def chat(payload: AssistantChatRequest) -> AssistantChatResponse:
    # Try Gemini first, fall back to local reply
    prompt = (
        "You are a personal finance assistant for a Bangladesh-focused expense app. "
        "Give concise, practical advice in 2-3 sentences. Do not provide investment, legal, or tax guarantees.\n\n"
        f"User message: {payload.message}\n"
        f"App context JSON: {json.dumps(payload.context, ensure_ascii=False)}"
    )
    reply = await _call_gemini(prompt)
    if reply is None:
        reply = _local_chat_reply(payload.message, payload.context)
    return AssistantChatResponse(reply=reply.strip())


@router.post("/parse-sms", response_model=ParsedTransaction)
async def parse_sms(payload: SmsImportRequest) -> ParsedTransaction:
    # Try Gemini first, fall back to regex parsing
    if settings.GEMINI_API_KEY:
        prompt = (
            "Extract one expense or income transaction from this Bangladesh bank/mobile-wallet SMS. "
            "Return only JSON with keys amount, category, channel, description, txn_date. "
            "Use channel one of cash,bkash,nagad,rocket,bank. Use txn_date as YYYY-MM-DD or null.\n\n"
            f"SMS:\n{payload.message}"
        )
        gemini_result = await _call_gemini(prompt)
        if gemini_result:
            try:
                parsed = _json_from_text(gemini_result)
                return ParsedTransaction(**parsed)
            except Exception:
                pass
    return _fallback_parse_transaction(payload.message)


@router.post("/scan-receipt", response_model=ParsedTransaction)
async def scan_receipt(payload: ReceiptScanRequest) -> ParsedTransaction:
    if settings.GEMINI_API_KEY:
        source = payload.text or "Use the attached receipt image."
        prompt = (
            "Read this receipt and extract a single expense transaction. "
            "Return only JSON with keys amount, category, channel, description, txn_date. "
            "Use channel one of cash,bkash,nagad,rocket,bank. Use txn_date as YYYY-MM-DD or null.\n\n"
            f"Receipt text:\n{source}"
        )
        gemini_result = await _call_gemini(prompt, payload.image_base64, payload.mime_type)
        if gemini_result:
            try:
                parsed = _json_from_text(gemini_result)
                return ParsedTransaction(**parsed)
            except Exception:
                if payload.image_base64 and not payload.text:
                    raise
    return _fallback_parse_transaction(payload.text or "")
