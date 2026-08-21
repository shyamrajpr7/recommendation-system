"""OpenAI-compatible LLM client supporting Groq and xAI Grok."""

import os
import re
import json
import requests
from typing import List, Dict, Any, Optional

from dotenv import load_dotenv

load_dotenv()

XAI_API_URL = os.environ.get("XAI_API_URL", "https://api.x.ai/v1/chat/completions")
XAI_MODEL = os.environ.get("XAI_MODEL", "grok-2-latest")
GROQ_API_URL = os.environ.get("GROQ_API_URL", "https://api.groq.com/openai/v1/chat/completions")
GROQ_MODEL = os.environ.get("GROQ_MODEL", "qwen/qwen3.6-27b")


def _provider_config() -> Dict[str, str]:
    """Picks the active LLM provider from the environment.

    GROQ_API_KEY takes priority, then XAI_API_KEY / GROK_API_KEY.
    Returns a dict with api_key, url, and model, or empty when none set.
    """
    groq_key = os.environ.get("GROQ_API_KEY")
    if groq_key:
        return {"api_key": groq_key, "url": GROQ_API_URL, "model": GROQ_MODEL}
    api_key = os.environ.get("XAI_API_KEY") or os.environ.get("GROK_API_KEY")
    if api_key:
        return {"api_key": api_key, "url": XAI_API_URL, "model": XAI_MODEL}
    return {}


def grok_chat(
    messages: List[Dict[str, str]],
    model: Optional[str] = None,
    temperature: float = 0.2,
    max_tokens: int = 1024,
    timeout: int = 60,
) -> Optional[str]:
    """Sends a chat request to the configured LLM provider (OpenAI-compatible).

    Supports Groq (GROQ_API_KEY) and xAI's Grok (XAI_API_KEY/GROK_API_KEY).
    Returns the assistant message content, or None when no API key is set or
    the call fails (callers fall back to grounded templates).
    """
    cfg = _provider_config()
    if not cfg:
        return None

    payload = {
        "model": model or cfg["model"],
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }

    try:
        resp = requests.post(
            cfg["url"],
            json=payload,
            headers={"Authorization": f"Bearer {cfg['api_key']}"},
            timeout=timeout,
        )
        resp.raise_for_status()
        data = resp.json()
        return (data.get("choices") or [{}])[0].get("message", {}).get("content")
    except Exception as e:
        print(f"[Grok] API call failed ({e}).")
        return None


def grok_json(messages: List[Dict[str, str]], **kwargs) -> Optional[Dict[str, Any]]:
    """Like grok_chat but expects a JSON object in the reply and parses it."""
    content = grok_chat(messages, **kwargs)
    if not content:
        return None

    stripped = re.sub(r"```(?:json)?\s*", "", content).strip()
    try:
        return json.loads(stripped)
    except Exception:
        # Fall back to the first {...} block in the reply
        match = re.search(r"\{.*\}", stripped, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(0))
            except Exception:
                pass
    return None
