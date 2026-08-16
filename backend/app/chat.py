from typing import List, Dict, Any

from backend.app.grok_client import grok_chat
from backend.app.database import get_movies, get_showtimes, get_theaters, get_upcoming_dates

_SYSTEM_PROMPT = (
    "You are 'CineRead Assistant', the helpful AI concierge for a movie-theater "
    "ticketing app. You help users discover movies, choose showtimes, pick seats, "
    "and complete bookings. You know the current movie catalog, theaters, and "
    "schedules supplied below.\n"
    "RULES:\n"
    "1. Only recommend movies that exist in the provided catalog.\n"
    "2. Only mention theaters, dates, and showtimes that exist in the provided schedule.\n"
    "3. Be concise (2-4 sentences). Do not invent prices, seats, or availability.\n"
    "4. If you don't know, say so and suggest browsing the Now Showing list.\n"
    "5. For booking steps, explain: pick a showtime, choose seats, enter name/email, pay via Razorpay.\n"
)


def _build_context() -> str:
    movies = get_movies()
    showtimes = get_showtimes()
    theaters = get_theaters()
    dates = get_upcoming_dates()

    movie_lines = "\n".join(
        f"- {m['title']} ({m['year']}, {m['genre']}, {m['rating']}/10): {m['synopsis'][:140]}"
        for m in movies[:20]
    )
    show_lines = "\n".join(
        f"- {s['movie_title']} @ {s['theater_name']} {s['screen_name']} on {s['show_date']} {s['show_time']} (Rs {int(s['base_price'])})"
        for s in showtimes[:40]
    )
    theater_lines = ", ".join(f"{t['name']} ({t['city']})" for t in theaters)
    date_lines = ", ".join(dates)

    return (
        f"CURRENT SHOWING DATES: {date_lines}\n\n"
        f"MOVIE CATALOG:\n{movie_lines or '(none)'}\n\n"
        f"UPCOMING SHOWTIMES (sample):\n{show_lines or '(none)'}\n\n"
        f"THEATERS: {theater_lines or '(none)'}\n"
    )


def chat_reply(message: str, history: List[Dict[str, str]]) -> Dict[str, Any]:
    messages = [{"role": "system", "content": _SYSTEM_PROMPT + "\n\n" + _build_context()}]
    for h in history[-8:]:
        role = h.get("role")
        content = h.get("content", "")
        if role in ("user", "assistant") and content:
            messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": message})

    reply = grok_chat(messages, temperature=0.4, max_tokens=600)
    if reply:
        return {"reply": reply.strip(), "used_ai": True}
    return {
        "reply": "I couldn't reach the AI right now. Try browsing 'Now Showing' to pick a movie and showtime.",
        "used_ai": False,
    }
