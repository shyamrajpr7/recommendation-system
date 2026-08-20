"""Razorpay payment link integration with mock fallback for local dev."""

import os
import requests
from typing import Dict, Any, Optional

RAZORPAY_BASE = "https://api.razorpay.com/v1"


def _auth() -> Optional[tuple]:
    """(key_id, key_secret) from env, or None if not configured."""
    key_id = os.environ.get("RAZORPAY_KEY_ID")
    key_secret = os.environ.get("RAZORPAY_KEY_SECRET")
    if key_id and key_secret:
        return (key_id, key_secret)
    return None


def payment_enabled() -> bool:
    return _auth() is not None


def create_payment_link(
    amount_inr: float,
    description: str,
    customer_name: str,
    customer_email: str,
    booking_ref: str,
) -> Dict[str, Any]:
    """Creates a Razorpay Payment Link. Returns dict with payment_link_id,
    short_url, and mock flag. When keys are missing, returns a simulated link
    so the booking flow still works in local dev."""
    auth = _auth()
    amount_paise = int(round(amount_inr * 100))
    if auth is None:
        return {
            "payment_link_id": f"mock_link_{booking_ref}",
            "short_url": None,
            "mock": True,
            "amount_inr": amount_inr,
        }

    payload = {
        "amount": amount_paise,
        "currency": "INR",
        "accept_partial": False,
        "description": description[:450],
        "customer": {
            "name": customer_name[:200],
            "email": customer_email[:200],
            "contact": "+910000000000",
        },
        "notify": {"email": True, "sms": False},
        "reference_id": booking_ref,
        "callback_url": "https://example.com/razorpay-callback",
        "callback_method": "get",
    }
    resp = requests.post(
        f"{RAZORPAY_BASE}/payment_links",
        json=payload,
        auth=auth,
        timeout=20,
    )
    resp.raise_for_status()
    data = resp.json()
    return {
        "payment_link_id": data.get("id"),
        "short_url": data.get("short_url"),
        "mock": False,
        "amount_inr": amount_inr,
    }


def fetch_payment_link_status(payment_link_id: str) -> Dict[str, Any]:
    """Queries Razorpay for a payment link's status."""
    auth = _auth()
    if auth is None:
        # Mock: a simulated link is considered paid once verification is called
        return {"status": "paid", "payments": [{"status": "captured", "id": f"mock_pay_{payment_link_id}"}]}

    resp = requests.get(f"{RAZORPAY_BASE}/payment_links/{payment_link_id}", auth=auth, timeout=20)
    resp.raise_for_status()
    data = resp.json()
    payments = data.get("payments", []) or []
    status = "paid" if data.get("status") == "paid" else data.get("status", "unknown")
    payment_id = payments[0].get("id") if payments else None
    return {"status": status, "payments": payments, "payment_id": payment_id}
