import os
import requests
from typing import List, Dict, Any, Optional

XAI_API_URL = os.environ.get("XAI_API_URL", "https://api.x.ai/v1/chat/completions")
XAI_MODEL = os.environ.get("XAI_MODEL", "grok-2-latest")


def grok_chat(
    messages: List[Dict[str, str]],
    model: Optional[str] = None,
    temperature: float = 0.2,
    max_tokens: int = 1024,
    timeout: int = 60,
) -> Optional[str]:
    """Sends a chat request to xAI's Grok API (OpenAI-compatible).

    Returns the assistant message content, or None when no API key is set or
    the call fails (callers fall back to grounded templates).
    """
    api_key = os.environ.get("XAI_API_KEY") or os.environ.get("GROK_API_KEY")
    if not api_key:
        return None

    payload = {
        "model": model or XAI_MODEL,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }

    try:
        resp = requests.post(
            XAI_API_URL,
            json=payload,
            headers={"Authorization": f"Bearer {api_key}"},
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
    import re
    import json

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
