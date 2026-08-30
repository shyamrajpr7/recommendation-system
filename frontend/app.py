import html
import json
import os
import random
import zlib
import requests
import streamlit as st

# Page Configuration
st.set_page_config(
    page_title="CineRead — Cinema Booking & AI Recommender",
    page_icon="🎬",
    layout="wide",
    initial_sidebar_state="expanded",
)

BACKEND_URL = os.environ.get("CINEREAD_API_URL", "http://127.0.0.1:8000")


# ---------------------------------------------------------------- API ----
@st.cache_data(ttl=30, show_spinner=False)
def api_get(path: str):
    try:
        res = requests.get(f"{BACKEND_URL}{path}", timeout=10)
        return res.json()
    except Exception:
        return None


def api_post(path: str, payload: dict, timeout: int = 30):
    res = requests.post(f"{BACKEND_URL}{path}", json=payload, timeout=timeout)
    if res.status_code >= 400:
        detail = res.json().get("detail")
        raise RuntimeError(detail if isinstance(detail, str) else str(detail))
    return res.json()


@st.cache_data(ttl=5, show_spinner=False)
def backend_health():
    try:
        res = requests.get(f"{BACKEND_URL}/health", timeout=2)
        return res.json() if res.status_code == 200 else None
    except Exception:
        return None


def backend_online():
    return backend_health() is not None


# --------------------------------------------------------------- state ----
st.session_state.setdefault("selected_movie_id", None)
st.session_state.setdefault("selected_showtime_id", None)
st.session_state.setdefault("selected_seats", [])
st.session_state.setdefault("booking_result", None)


def _clear_booking_flow():
    st.session_state.selected_movie_id = None
    st.session_state.selected_showtime_id = None
    st.session_state.selected_seats = []
    st.session_state.booking_result = None
    st.session_state["show_payment_form"] = False
    st.session_state.pop("confirmed_booking_ref", None)
    st.session_state.pop("verified", None)


def _pick_movie(movie_id):
    st.session_state.selected_movie_id = movie_id
    st.session_state.selected_showtime_id = None
    st.session_state.selected_seats = []
    st.session_state.booking_result = None
    st.session_state["show_payment_form"] = False
    st.session_state.pop("confirmed_booking_ref", None)
    st.session_state.pop("verified", None)


def _pick_showtime(showtime_id):
    st.session_state.selected_showtime_id = showtime_id
    st.session_state.selected_seats = []
    st.session_state["show_payment_form"] = False
    st.session_state.pop("confirmed_booking_ref", None)
    st.session_state.pop("verified", None)


def _toggle_seat(seat):
    if seat in st.session_state.selected_seats:
        st.session_state.selected_seats.remove(seat)
    else:
        st.session_state.selected_seats.append(seat)


def _set_search_query(example):
    st.session_state.search_input = example


def _book_from_search(movie_id):
    _pick_movie(movie_id)
    st.session_state["nav_radio"] = "🎟️ Now Showing"


# ----------------------------------------------------------- helpers ----
_PALETTES = [
    ("#0ea5e9", "#6366f1"),
    ("#8b5cf6", "#ec4899"),
    ("#f59e0b", "#ef4444"),
    ("#10b981", "#0ea5e9"),
    ("#f43f5e", "#8b5cf6"),
    ("#14b8a6", "#6366f1"),
    ("#f97316", "#eab308"),
    ("#06b6d4", "#3b82f6"),
]


def _palette(title: str):
    c1, c2 = _PALETTES[zlib.crc32(title.encode()) % len(_PALETTES)]
    return f"linear-gradient(135deg, {c1} 0%, {c2} 100%)"


def _stars(rating: float) -> str:
    filled = round(rating / 2)
    return "★" * filled + "☆" * (5 - filled)


# ---------------------------------------------------------------- CSS ----
st.markdown(
    """
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Space+Grotesk:wght@500;600;700&display=swap');

    :root {
        --bg: #070b16;
        --surface: #0d1424;
        --surface-2: #0a101d;
        --surface-3: #111a2e;
        --border: #1e2a44;
        --border-soft: rgba(148, 163, 184, 0.14);
        --text: #e6edf7;
        --muted: #8ba0bf;
        --muted-2: #5b6f8f;
        --accent-1: #38bdf8;
        --accent-2: #818cf8;
        --accent-3: #c084fc;
        --gold: #fbbf24;
        --green: #34d399;
        --red: #f87171;
        --radius: 18px;
    }

    html, body, .stApp {
        background: var(--bg);
        color: var(--text);
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    }

    .stApp {
        background:
            radial-gradient(1100px 520px at 85% -10%, rgba(139, 92, 246, 0.14), transparent 60%),
            radial-gradient(900px 460px at 5% -5%, rgba(56, 189, 248, 0.10), transparent 60%),
            radial-gradient(1200px 700px at 50% 120%, rgba(244, 63, 94, 0.05), transparent 55%),
            var(--bg);
    }

    h1, h2, h3, h4 { font-family: 'Space Grotesk', sans-serif; letter-spacing: -0.02em; }
    #MainMenu, footer { visibility: hidden; }

    [data-testid="stBaseButton"]:focus-visible {
        outline: 2px solid #818cf8;
        outline-offset: 2px;
        box-shadow: 0 0 0 4px rgba(129, 140, 248, 0.25);
    }
    input, textarea, [data-testid="stSelectbox"] [data-baseweb="select"]:focus-within { outline-offset: 2px; }

    ::-webkit-scrollbar { width: 10px; height: 10px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #223054; border-radius: 999px; border: 2px solid var(--bg); }
    ::-webkit-scrollbar-thumb:hover { background: #2e3f6e; }

    ::selection { background: rgba(129, 140, 248, 0.45); color: #fff; text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3); }
    ::-moz-selection { background: rgba(129, 140, 248, 0.45); color: #fff; }

    [data-testid="stSidebar"] {
        background: linear-gradient(180deg, #0b1222 0%, #080d1a 100%);
        border-right: 1px solid var(--border);
    }
    [data-testid="stSidebar"] .stMarkdown { color: var(--muted); }
    .brand-block { padding: 0.2rem 0 0.6rem; }
    .brand-title {
        font-family: 'Space Grotesk', sans-serif;
        font-size: 1.5rem;
        font-weight: 700;
        letter-spacing: -0.02em;
        background: linear-gradient(90deg, #38bdf8, #818cf8, #c084fc);
        -webkit-background-clip: text;
        background-clip: text;
        -webkit-text-fill-color: transparent;
        animation: brand-fade-in 0.6s ease-out;
        transition: filter 0.25s ease;
    }
    .brand-title:hover { filter: brightness(1.2) drop-shadow(0 0 10px rgba(129, 140, 248, 0.45)); }
    @keyframes brand-fade-in {
        from { opacity: 0; transform: translateX(-8px); }
        to { opacity: 1; transform: translateX(0); }
    }
    .brand-sub { color: var(--muted-2); font-size: 0.8rem; margin-top: 0.15rem; }

    [data-testid="stBaseButton-pills"] {
        transition: transform 0.15s ease, box-shadow 0.2s ease;
    }
    [data-testid="stBaseButton-pills"]:hover { transform: translateY(-1px); box-shadow: 0 3px 12px rgba(56, 189, 248, 0.15); }
    [data-testid="stBaseButton-pills"][aria-pressed="true"] {
        background: linear-gradient(135deg, #38bdf8, #818cf8) !important;
        color: #08111f !important; font-weight: 700;
        box-shadow: 0 4px 16px rgba(129, 140, 248, 0.35);
    }

    [data-testid="stSidebar"] .stRadio > label, [data-testid="stSidebar"] [role="radiogroup"] label { color: var(--muted); font-weight: 500; }
    [data-testid="stSidebar"] [role="radiogroup"] label:hover { color: var(--text); }
    [data-testid="stSidebar"] [role="radiogroup"] label p { font-size: 0.95rem; }

    .status-pill {
        display: inline-flex; align-items: center; gap: 0.45rem;
        padding: 0.35rem 0.8rem; border-radius: 999px;
        font-size: 0.78rem; font-weight: 700; border: 1px solid;
    }
    .status-pill:hover { filter: brightness(1.1); }
    .status-on { background: rgba(16, 185, 129, 0.12); color: #6ee7b7; border-color: rgba(52, 211, 153, 0.35); }
    .status-off { background: rgba(248, 113, 113, 0.12); color: #fca5a5; border-color: rgba(248, 113, 113, 0.35); }
    .status-dot { width: 7px; height: 7px; border-radius: 50%; display: inline-block; }
    .status-on .status-dot { background: #34d399; box-shadow: 0 0 8px #34d399; animation: pulse-dot 2s ease-in-out infinite; }
    @keyframes pulse-dot {
        0%, 100% { box-shadow: 0 0 4px #34d399; }
        50% { box-shadow: 0 0 14px #34d399, 0 0 24px rgba(52, 211, 153, 0.3); }
    }
    .status-off .status-dot { background: #f87171; box-shadow: 0 0 8px #f87171; }

    .hero {
        text-align: center;
        padding: 2.4rem 1.6rem 2rem;
        border-radius: 24px;
        border: 1px solid var(--border-soft);
        background:
            radial-gradient(700px 320px at 50% -30%, rgba(129, 140, 248, 0.22), transparent 65%),
            linear-gradient(135deg, rgba(17, 26, 46, 0.85) 0%, rgba(8, 13, 26, 0.9) 100%);
        box-shadow: 0 24px 70px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.04);
        margin-bottom: 1.6rem;
        position: relative;
        overflow: hidden;
    }
    .hero::after {
        content: "";
        position: absolute; inset: 0;
        background: repeating-linear-gradient(90deg, transparent, transparent 2px, rgba(255,255,255,0.008) 3px, transparent 4px);
        pointer-events: none;
    }
    .hero-kicker {
        display: inline-block;
        font-size: 0.72rem; font-weight: 700; letter-spacing: 0.26em; text-transform: uppercase;
        color: var(--accent-1);
        border: 1px solid rgba(56, 189, 248, 0.3);
        padding: 0.25rem 0.9rem; border-radius: 999px;
        background: rgba(56, 189, 248, 0.08);
        margin-bottom: 0.9rem;
        animation: pulse-badge 3s ease-in-out infinite;
    }
    @keyframes pulse-badge {
        0%, 100% { box-shadow: 0 0 0 0 rgba(56, 189, 248, 0.25); }
        50% { box-shadow: 0 0 18px 4px rgba(56, 189, 248, 0.15); }
    }
    .hero-title {
        font-family: 'Space Grotesk', sans-serif;
        font-size: 3rem; font-weight: 700; letter-spacing: -0.03em;
        background: linear-gradient(90deg, #38bdf8, #818cf8, #c084fc, #38bdf8);
        background-size: 300% 100%;
        -webkit-background-clip: text; background-clip: text;
        -webkit-text-fill-color: transparent;
        animation: shimmer 9s linear infinite;
        display: inline-block;
    }
    .hero-title::after {
        content: "";
        display: block;
        height: 3px;
        margin: 0.5rem auto 0;
        width: 60%;
        border-radius: 999px;
        background: linear-gradient(90deg, transparent, #38bdf8, #818cf8, #c084fc, transparent);
        opacity: 0.5;
    }
    @keyframes shimmer {
        0% { background-position: 0% 50%; }
        100% { background-position: 300% 50%; }
    }
    .hero-sub { color: var(--muted); font-size: 1rem; margin-top: 0.4rem; }

    .panel, .search-card {
        background: var(--surface);
        border: 1px solid var(--border-soft);
        border-radius: var(--radius);
        padding: 1.4rem 1.6rem 1.6rem;
        margin-bottom: 1.4rem;
        box-shadow: 0 14px 40px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255,255,255,0.03);
        transition: border-color 0.3s ease, box-shadow 0.3s ease;
    }
    .search-card:hover {
        border-color: rgba(129, 140, 248, 0.4);
        box-shadow: 0 14px 40px rgba(0, 0, 0, 0.3), 0 0 30px rgba(129, 140, 248, 0.1);
    }
    .chip-label {
        color: var(--muted);
        font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.12em;
        margin: 0 0 0.7rem;
        transition: color 0.25s ease, letter-spacing 0.25s ease;
    }
    .chip-label:hover { color: #a5b4fc; letter-spacing: 0.16em; }
    .chip-label span { color: var(--accent-2); }

    .movie-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(310px, 1fr));
        gap: 1.4rem;
    }
    .movie-card {
        background: var(--surface);
        border: 1px solid var(--border-soft);
        border-radius: 20px;
        overflow: hidden;
        display: flex;
        flex-direction: column;
        transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;
        animation: card-in 0.45s ease-out;
    }
    @keyframes card-in {
        from { opacity: 0; transform: translateY(10px); }
        to { opacity: 1; transform: translateY(0); }
    }
    .movie-card:hover {
        transform: translateY(-6px);
        box-shadow:
            0 26px 60px rgba(0, 0, 0, 0.55),
            0 0 40px rgba(129, 140, 248, 0.18),
            0 0 80px rgba(56, 189, 248, 0.08);
        border-color: rgba(129, 140, 248, 0.55);
    }
    .movie-poster {
        position: relative;
        height: 150px;
        display: flex; align-items: flex-end;
        padding: 1rem 1.2rem 0.85rem;
        overflow: hidden;
    }
    .movie-card:hover .movie-poster h3 { text-shadow: 0 2px 14px rgba(0, 0, 0, 0.5), 0 0 22px rgba(129, 140, 248, 0.25); color: #e9efff; }
    .movie-poster::after {
        content: "";
        position: absolute; inset: 0;
        background: linear-gradient(180deg, rgba(7, 11, 22, 0) 20%, rgba(7, 11, 22, 0.92) 100%);
    }
    .movie-poster h3 {
        position: relative; z-index: 2;
        color: #fff; font-size: 1.45rem; font-weight: 700; line-height: 1.15;
        margin: 0; text-shadow: 0 2px 14px rgba(0, 0, 0, 0.5);
        transition: transform 0.25s ease;
    }
    .movie-card:hover .movie-poster h3 { transform: scale(1.03); }
    .movie-body { padding: 1.05rem 1.2rem 1.2rem; display: flex; flex-direction: column; gap: 0.7rem; flex: 1; }
    .movie-meta { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; color: var(--muted); font-size: 0.84rem; }
    .badge { display: inline-block; padding: 3px 11px; border-radius: 999px; font-size: 0.72rem; font-weight: 700; transition: transform 0.2s ease, box-shadow 0.2s ease; }
    .badge:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3); }
    .badge-genre { background: rgba(56, 189, 248, 0.12); color: #7dd3fc; border: 1px solid rgba(56, 189, 248, 0.25); }
    .badge-year { background: rgba(52, 211, 153, 0.12); color: #6ee7b7; border: 1px solid rgba(52, 211, 153, 0.25); }
    .badge-rank { background: rgba(251, 191, 36, 0.14); color: #fcd34d; border: 1px solid rgba(251, 191, 36, 0.3); }
    .badge-cached { background: rgba(56, 189, 248, 0.12); color: #7dd3fc; border: 1px solid rgba(56, 189, 248, 0.25); }
    .badge-fresh { background: rgba(52, 211, 153, 0.12); color: #6ee7b7; border: 1px solid rgba(52, 211, 153, 0.25); }
    .stars { color: var(--gold); letter-spacing: 0.08em; font-size: 0.82rem; }
    .synopsis { color: #b6c4da; font-size: 0.9rem; line-height: 1.6; flex: 1; }

    .showtime-card {
        background: linear-gradient(135deg, rgba(14, 22, 40, 0.9), rgba(10, 16, 29, 0.9));
        border: 1px solid var(--border-soft);
        border-radius: 14px;
        padding: 0.95rem 1.2rem;
        margin-bottom: 0.8rem;
        display: flex; justify-content: space-between; align-items: center; gap: 1rem;
        transition: border-color 0.2s ease, background 0.3s ease;
    }
    .showtime-card:hover { border-color: rgba(56, 189, 248, 0.45); box-shadow: 0 4px 24px rgba(56, 189, 248, 0.12); background: linear-gradient(135deg, rgba(20, 32, 58, 0.95), rgba(14, 22, 40, 0.95)); }
    .showtime-time { font-family: 'Space Grotesk', sans-serif; font-size: 1.35rem; font-weight: 700; color: var(--accent-1); transition: color 0.25s ease, transform 0.25s ease; }
    .showtime-card:hover .showtime-time { color: #7dd3fc; transform: translateX(3px); }
    .showtime-info { color: var(--muted); font-size: 0.85rem; line-height: 1.5; }
    .showtime-price { color: #a7f3d0; font-weight: 700; font-size: 1.05rem; }

    .screen-block {
        text-align: center;
        color: var(--muted-2); font-size: 0.72rem; letter-spacing: 0.45em; text-transform: uppercase;
        background: linear-gradient(180deg, rgba(56, 189, 248, 0.10), rgba(56, 189, 248, 0.02));
        border: 1px solid rgba(56, 189, 248, 0.18);
        border-radius: 10px; padding: 0.55rem;
        margin: 0 auto 1.4rem; max-width: 72%;
        box-shadow: 0 4px 30px rgba(56, 189, 248, 0.08) inset;
        animation: screen-fade 1.2s ease-out;
        transition: box-shadow 0.3s ease, background 0.3s ease;
    }
    .screen-block:hover { box-shadow: 0 4px 34px rgba(56, 189, 248, 0.18) inset; background: linear-gradient(180deg, rgba(56, 189, 248, 0.16), rgba(56, 189, 248, 0.04)); }
    @keyframes screen-fade {
        from { opacity: 0; transform: translateY(6px); }
        to { opacity: 1; transform: translateY(0); }
    }
    .legend { display: flex; gap: 1.3rem; justify-content: center; color: var(--muted); font-size: 0.8rem; margin-bottom: 1.2rem; flex-wrap: wrap; }
    .legend span { display: inline-flex; align-items: center; gap: 0.4rem; }
    .seat-legend-dot { width: 18px; height: 18px; border-radius: 6px; display: inline-block; transition: transform 0.2s ease, box-shadow 0.2s ease; }
    .legend span:hover .seat-legend-dot { transform: scale(1.2); box-shadow: 0 2px 10px rgba(0, 0, 0, 0.4); }
    .legend-avail { background: #16233f; border: 1px solid #2c3f66; }
    .legend-sel { background: linear-gradient(135deg, #38bdf8, #818cf8); }
    .legend-occ { background: repeating-linear-gradient(45deg, rgba(248,113,113,0.35), rgba(248,113,113,0.35) 3px, rgba(248,113,113,0.12) 3px, rgba(248,113,113,0.12) 6px); border: 1px solid rgba(248,113,113,0.4); }
    .legend-blk { background: #0a101d; border: 1px dashed #2c3f66; }

    .st-key-seat_map { padding: 1.2rem 0.4rem 0.2rem; }
    .st-key-seat_map [data-testid="stBaseButton"] {
        min-height: 40px; border-radius: 9px; font-size: 0.82rem; font-weight: 700;
        transition: transform 0.12s ease, box-shadow 0.2s ease, background 0.3s ease, color 0.3s ease, border-color 0.3s ease;
    }
    .st-key-seat_map [data-testid="stBaseButton"]:hover:not(:disabled) { transform: translateY(-2px); }
    .st-key-seat_map [data-testid="stBaseButton-secondary"] {
        background: #16233f; color: #c9d8f2; border: 1px solid #2c3f66;
        box-shadow: inset 0 1px 0 rgba(255,255,255,0.06);
    }
    .st-key-seat_map [data-testid="stBaseButton-secondary"]:hover {
        background: #1c2b4e; border-color: #3c5290; box-shadow: 0 6px 18px rgba(56, 189, 248, 0.2);
    }
    .st-key-seat_map [data-testid="stBaseButton-primary"] {
        background: linear-gradient(135deg, #38bdf8, #818cf8); color: #08111f;
        border: 1px solid rgba(255,255,255,0.2); box-shadow: 0 6px 22px rgba(129, 140, 248, 0.4);
    }
    .seat-rowlabel { color: var(--muted-2); font-family: 'Space Grotesk', sans-serif; font-weight: 700; font-size: 0.95rem; text-align: center; padding-top: 0.55rem; }
    .seat-chip { height: 40px; border-radius: 9px; font-size: 0.82rem; font-weight: 700; display: flex; align-items: center; justify-content: center; font-family: 'Space Grotesk', sans-serif; }
    .seat-occ { background: repeating-linear-gradient(45deg, rgba(248,113,113,0.35), rgba(248,113,113,0.35) 3px, rgba(248,113,113,0.12) 3px, rgba(248,113,113,0.12) 6px); color: rgba(248, 113, 113, 0.75); border: 1px solid rgba(248,113,113,0.35); }
    .seat-blk { background: #0a101d; color: #33415f; border: 1px dashed #223052; }
    .seat-cols-header { color: var(--muted-2); font-size: 0.75rem; text-align: center; padding-bottom: 0.3rem; }

    .booking-bar {
        position: sticky; bottom: 14px; z-index: 40; margin-top: 1.1rem;
        display: flex; justify-content: space-between; align-items: center; gap: 1rem; flex-wrap: wrap;
        padding: 0.95rem 1.4rem; border-radius: 16px;
        border: 1px solid rgba(129, 140, 248, 0.35);
        border-top: 3px solid;
        border-image: linear-gradient(90deg, #38bdf8, #818cf8, #34d399) 1;
        background: rgba(13, 20, 36, 0.88);
        backdrop-filter: blur(14px);
        box-shadow: 0 18px 50px rgba(0, 0, 0, 0.55);
    }
    .booking-bar .bb-total {
        font-family: 'Space Grotesk', sans-serif; font-size: 1.3rem; font-weight: 700;
        background: linear-gradient(135deg, #34d399, #38bdf8);
        -webkit-background-clip: text; background-clip: text;
        -webkit-text-fill-color: transparent;
    }

    [data-testid="stBaseButton-primary"] {
        transition: box-shadow 0.25s ease, transform 0.2s ease, background 0.3s ease;
        background: linear-gradient(135deg, #38bdf8 0%, #818cf8 100%) !important;
        color: #08111f !important;
        border: 1px solid rgba(255, 255, 255, 0.18) !important;
        box-shadow: 0 4px 16px rgba(129, 140, 248, 0.25) !important;
    }
    [data-testid="stBaseButton-primary"]:hover {
        background: linear-gradient(135deg, #7dd3fc 0%, #a5b4fc 100%) !important;
        box-shadow: 0 6px 24px rgba(129, 140, 248, 0.45);
        transform: translateY(-1px);
    }
    .booking-bar .bb-seats { color: var(--muted); font-size: 0.88rem; }

    .ticket-wrap {
        position: relative;
        max-width: 640px;
        margin: 1.2rem auto 0;
        background: linear-gradient(150deg, #101a30 0%, #0b1323 100%);
        border: 1px solid rgba(139, 92, 246, 0.35);
        border-radius: 20px;
        overflow: hidden;
        box-shadow: 0 24px 70px rgba(0, 0, 0, 0.55);
        animation: ticket-in 0.55s ease-out;
        transition: box-shadow 0.3s ease, transform 0.3s ease;
    }
    .ticket-wrap:hover { transform: translateY(-3px); box-shadow: 0 30px 80px rgba(0, 0, 0, 0.65), 0 0 40px rgba(139, 92, 246, 0.12); }
    @keyframes ticket-in {
        from { opacity: 0; transform: translateY(14px); }
        to { opacity: 1; transform: translateY(0); }
    }
    .ticket-head {
        padding: 1.1rem 1.4rem;
        display: flex; justify-content: space-between; align-items: center;
        border-bottom: 1px dashed rgba(148, 163, 184, 0.25);
        background: linear-gradient(90deg, rgba(56,189,248,0.10), rgba(139,92,246,0.10));
    }
    .ticket-brand { font-family: 'Space Grotesk', sans-serif; font-weight: 700; color: var(--accent-1); font-size: 1rem; letter-spacing: 0.04em; }
    .ticket-ref { font-family: 'Space Grotesk', sans-serif; font-size: 1.15rem; font-weight: 700; color: var(--gold); letter-spacing: 0.05em; }
    .ticket-body { padding: 1.3rem 1.4rem 1.1rem; }
    .ticket-movie { font-size: 1.35rem; font-weight: 700; color: #fff; margin-bottom: 0.15rem; }
    .ticket-sub { color: var(--muted); font-size: 0.85rem; margin-bottom: 1.1rem; }
    .ticket-details { display: grid; grid-template-columns: 1fr 1fr; gap: 0.9rem 1.2rem; }
    .ticket-cell .tc-label { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.1em; color: var(--muted-2); margin-bottom: 0.2rem; }
    .ticket-cell .tc-value { font-weight: 700; color: #dbe7f5; font-size: 0.95rem; }
    .ticket-status { display: inline-block; padding: 4px 12px; border-radius: 999px; font-size: 0.75rem; font-weight: 800; letter-spacing: 0.06em; }
    .ts-confirmed { background: rgba(52, 211, 153, 0.15); color: #6ee7b7; border: 1px solid rgba(52, 211, 153, 0.35); animation: status-glow 2.5s ease-in-out infinite; }
    @keyframes status-glow {
        0%, 100% { box-shadow: 0 0 0 0 rgba(52, 211, 153, 0.2); }
        50% { box-shadow: 0 0 14px 2px rgba(52, 211, 153, 0.25); }
    }
    .ts-pending { background: rgba(251, 191, 36, 0.15); color: #fcd34d; border: 1px solid rgba(251, 191, 36, 0.35); }
    .ticket-stub {
        margin: 0.2rem 1.4rem 1.2rem;
        border-top: 1px dashed rgba(148, 163, 184, 0.25);
        padding-top: 0.9rem;
        display: flex; justify-content: space-between; align-items: center; gap: 1rem;
    }
    .ticket-barcode {
        height: 42px; flex: 1;
        background: repeating-linear-gradient(90deg, #dbe7f5 0 2px, transparent 2px 5px, #dbe7f5 5px 6px, transparent 6px 9px, #dbe7f5 9px 12px, transparent 12px 14px);
        -webkit-mask-image: linear-gradient(90deg, transparent 2%, #000 8%, #000 92%, transparent 98%);
        mask-image: linear-gradient(90deg, transparent 2%, #000 8%, #000 92%, transparent 98%);
        opacity: 0.55;
        animation: barcode-shimmer 4s ease-in-out infinite;
    }
    @keyframes barcode-shimmer {
        0%, 100% { opacity: 0.55; }
        50% { opacity: 0.75; }
    }

    .rec-poster {
        position: relative;
        height: 128px;
        display: flex; align-items: flex-end;
        padding: 1rem 1.2rem 0.8rem;
        overflow: hidden;
    }
    .rec-poster::after {
        content: "";
        position: absolute; inset: 0;
        background: linear-gradient(180deg, rgba(7, 11, 22, 0) 20%, rgba(7, 11, 22, 0.94) 100%);
    }
    .rec-poster h3 {
        position: relative; z-index: 2;
        color: #fff; font-size: 1.3rem; font-weight: 700; line-height: 1.15;
        margin: 0; text-shadow: 0 2px 14px rgba(0, 0, 0, 0.55);
    }
    .rec-rank {
        position: absolute; top: 0.7rem; right: 0.9rem; z-index: 3;
        font-family: 'Space Grotesk', sans-serif; font-weight: 800; font-size: 1.7rem;
        color: rgba(255, 255, 255, 0.9); text-shadow: 0 2px 18px rgba(0, 0, 0, 0.6);
        background: rgba(7, 11, 22, 0.45); border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 12px; padding: 0.15rem 0.55rem; backdrop-filter: blur(4px);
    }
    .rec-type {
        position: absolute; top: 0.8rem; left: 0.9rem; z-index: 3;
        background: rgba(7, 11, 22, 0.65); backdrop-filter: blur(6px);
        border: 1px solid rgba(255, 255, 255, 0.18);
        color: #e2e8f0; font-size: 0.7rem; font-weight: 700; letter-spacing: 0.08em;
        padding: 4px 11px; border-radius: 999px;
    }
    .match-bar {
        height: 8px; border-radius: 999px; overflow: hidden;
        background: #0b1220; border: 1px solid #1c2a49;
    }
    .match-fill {
        height: 100%; border-radius: 999px;
        background: linear-gradient(90deg, #38bdf8, #818cf8, #a78bfa, #38bdf8);
        background-size: 200% 100%;
        animation: match-fill-flow 3s ease infinite;
        box-shadow: 0 0 12px rgba(129, 140, 248, 0.6);
    }
    @keyframes match-fill-flow {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
    }
    .why-box {
        background: rgba(99, 102, 241, 0.08);
        border: 1px solid rgba(129, 140, 248, 0.28);
        border-left: 3px solid #6366f1;
        border-radius: 12px;
        padding: 0.7rem 0.85rem;
        color: #c7d2fe; font-size: 0.85rem; line-height: 1.55;
        transition: box-shadow 0.25s ease, background 0.25s ease;
    }
    .why-box:hover { background: rgba(99, 102, 241, 0.12); box-shadow: 0 0 16px rgba(129, 140, 248, 0.15); transform: translateY(-2px); }
    .why-box b { color: #a5b4fc; }
    .search-meta { display: flex; align-items: center; justify-content: space-between; gap: 0.8rem; }
    .match-pct { font-family: 'Space Grotesk', sans-serif; font-weight: 700; font-size: 0.85rem; white-space: nowrap; background: linear-gradient(90deg, #38bdf8, #a78bfa); -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; }
    .match-lbl { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.1em; color: var(--muted-2); margin-bottom: 0.35rem; }

    .empty-state { text-align: center; padding: 3.4rem 1.5rem; color: var(--muted); }
    .empty-icon { font-size: 3.2rem; margin-bottom: 0.7rem; animation: float-icon 3.5s ease-in-out infinite; }
    .empty-state:hover .empty-icon { animation: float-icon 1.4s ease-in-out infinite, icon-tilt 2.2s ease-in-out infinite; filter: drop-shadow(0 0 18px rgba(129, 140, 248, 0.35)); }
    @keyframes icon-tilt {
        0%, 100% { transform: translateY(0) rotate(-4deg); }
        50% { transform: translateY(-8px) rotate(4deg); }
    }
    @keyframes float-icon {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-8px); }
    }
    .empty-title { font-size: 1.45rem; font-weight: 700; color: var(--text); margin-bottom: 0.35rem; font-family: 'Space Grotesk', sans-serif; background: linear-gradient(90deg, #e6edf7, #38bdf8); -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; }

    .stepper { display: flex; align-items: center; gap: 0; margin-bottom: 1.5rem; flex-wrap: wrap; }
    .step { display: flex; align-items: center; gap: 0.5rem; color: var(--muted-2); font-size: 0.82rem; font-weight: 600; }
    .step .step-dot {
        width: 26px; height: 26px; border-radius: 50%;
        display: flex; align-items: center; justify-content: center;
        font-size: 0.78rem; font-weight: 700;
        background: #0a101d; border: 1px solid #223052; color: var(--muted-2);
    }
    .step.active { color: var(--text); }
    .step.active .step-dot { background: linear-gradient(135deg, #38bdf8, #818cf8); border-color: transparent; color: #08111f; box-shadow: 0 0 14px rgba(129, 140, 248, 0.45); }
    .step.done .step-dot { background: rgba(52, 211, 153, 0.18); border-color: rgba(52, 211, 153, 0.4); color: #6ee7b7; }
    .step-line { flex: 1; height: 1px; background: linear-gradient(90deg, #223052, #38bdf8, #223052); margin: 0 0.8rem; min-width: 22px; }

    .chat-row { display: flex; align-items: flex-start; gap: 0.6rem; margin-bottom: 0.8rem; animation: fade-in-chat 0.35s ease-out; }
    @keyframes fade-in-chat {
        from { opacity: 0; transform: translateY(8px); }
        to { opacity: 1; transform: translateY(0); }
    }
    .chat-row.user { justify-content: flex-end; }
    .chat-avatar {
        width: 34px; height: 34px; border-radius: 50%; flex: 0 0 auto;
        display: flex; align-items: center; justify-content: center;
        font-size: 1rem; margin-top: 0.15rem;
        transition: transform 0.25s ease, box-shadow 0.25s ease;
    }
    .chat-avatar:hover { transform: scale(1.12); box-shadow: 0 4px 14px rgba(129, 140, 248, 0.35); }
    .chat-avatar.user { background: linear-gradient(135deg, #38bdf8, #818cf8); }
    .chat-avatar.ai { background: linear-gradient(135deg, #6366f1, #a855f7); }
    .chat-bubble { padding: 0.75rem 1.05rem; border-radius: 16px; font-size: 0.92rem; line-height: 1.6; max-width: 78%; }
    .chat-user { background: linear-gradient(135deg, rgba(56, 189, 248, 0.18), rgba(129, 140, 248, 0.14)); color: #cfe8ff; border: 1px solid rgba(56, 189, 248, 0.25); }
    .chat-ai { background: var(--surface-2); border: 1px solid var(--border-soft); border-left: 3px solid #6366f1; color: #dbe7f5; }
    .chat-wrap {
        background: linear-gradient(150deg, rgba(13, 20, 38, 0.55), rgba(9, 14, 26, 0.55));
        border: 1px solid var(--border-soft);
        border-bottom: 2px solid;
        border-image: linear-gradient(90deg, transparent, #6366f1, transparent) 1;
        border-radius: 18px;
        padding: 1.1rem 1.2rem;
        margin-bottom: 1rem;
    }
    .chat-chip {
        display: inline-block;
        background: rgba(56, 189, 248, 0.1);
        border: 1px solid rgba(56, 189, 248, 0.3);
        color: #7dd3fc;
        border-radius: 999px;
        padding: 6px 14px;
        margin: 0 0.4rem 0.4rem 0;
        font-size: 0.8rem;
        font-weight: 600;
        cursor: pointer;
        transition: background 0.2s ease, transform 0.2s ease, box-shadow 0.2s ease;
    }
    .chat-chip:hover { background: rgba(56, 189, 248, 0.2); transform: scale(1.05); box-shadow: 0 4px 16px rgba(56, 189, 248, 0.2); }

    .footer {
        margin-top: 2.6rem;
        padding-top: 1.2rem;
        border-top: 1px solid var(--border-soft);
        text-align: center;
        color: var(--muted-2);
        font-size: 0.82rem;
    }
    .footer b { color: #aebfd8; font-weight: 600; transition: color 0.25s ease, text-shadow 0.25s ease; }
    .footer b:hover { color: #7dd3fc; text-shadow: 0 0 12px rgba(56, 189, 248, 0.4); }
</style>
""",
    unsafe_allow_html=True,
)


# ------------------------------------------------------------- sidebar ----
with st.sidebar:
    st.markdown(
        """
        <div class="brand-block">
            <div class="brand-title">CineRead</div>
            <div class="brand-sub">Cinema booking · AI concierge</div>
        </div>
        """,
        unsafe_allow_html=True,
    )
    page = st.radio(
        "Navigate",
        ["🎟️ Now Showing", "✨ AI Search", "🤖 AI Assistant", "🎫 My Booking"],
        key="nav_radio",
        label_visibility="collapsed",
    )
    online = backend_online()
    st.markdown("---")
    cls = "status-on" if online else "status-off"
    label = "Backend online" if online else "Backend offline"
    st.markdown(
        f'<span class="status-pill {cls}"><span class="status-dot"></span>{label}</span>',
        unsafe_allow_html=True,
    )
    if online:
        stats = api_get("/stats")
        version = (backend_health() or {}).get("version", "")
        badges = []
        if stats:
            badges += [
                f'<span class="badge badge-genre">🎬 {stats["movies"]} movies</span>',
                f'<span class="badge badge-year">🗓️ {stats["showtimes"]} shows</span>',
                f'<span class="badge badge-rank">🏛️ {stats["theaters"]} theaters</span>',
            ]
        if version:
            badges.append(f'<span class="badge badge-cached">⚙️ API v{version}</span>')
        if badges:
            st.markdown(
                '<div style="display:flex;gap:0.5rem;flex-wrap:wrap;margin-top:0.8rem;">'
                + "".join(badges) + "</div>",
                unsafe_allow_html=True,
            )
    st.markdown(
        '<div style="color:#5b6f8f;font-size:0.75rem;margin-top:1.1rem;line-height:1.6;">'
        'FAISS retrieval · Sentence-Transformers · Groq AI · Razorpay payments</div>',
        unsafe_allow_html=True,
    )


# ------------------------------------------------------------- chrome ----
def _hero(kicker: str, title: str, sub: str):
    st.markdown(
        f"""<div class="hero"><div class="hero-kicker">{html.escape(kicker)}</div>"""
        f"""<div class="hero-title">{html.escape(title)}</div>"""
        f"""<div class="hero-sub">{html.escape(sub)}</div></div>""",
        unsafe_allow_html=True,
    )


def _footer():
    st.markdown(
        '<div class="footer"><b>CineRead Cinema</b> · FAISS + Sentence-Transformers + Groq AI · Razorpay checkout</div>',
        unsafe_allow_html=True,
    )


def _stepper(steps: list, current: int):
    parts = []
    for i, name in enumerate(steps):
        state = "active" if i == current else ("done" if i < current else "")
        dot = "✓" if i < current else str(i + 1)
        parts.append(
            f'<div class="step {state}"><span class="step-dot">{dot}</span>{name}</div>'
        )
        if i < len(steps) - 1:
            parts.append('<div class="step-line"></div>')
    st.markdown(f'<div class="stepper">{"".join(parts)}</div>', unsafe_allow_html=True)


# ============================================================ NOW SHOWING
def page_now_showing():
    _hero("Now Showing", "CineRead", "Book movie tickets — AI recommendations, live seat maps, instant confirmation")
    if not backend_online():
        st.error("Backend offline. Start it with `uvicorn backend.app.main:app --port 8000`.")
        return

    data = api_get("/movies")
    if not data:
        st.error("Could not load movies.")
        return
    all_movies = data["movies"]
    all_showtimes = (api_get("/showtimes") or {}).get("showtimes", [])
    now_showing_ids = {s["movie_id"] for s in all_showtimes}
    movies = [m for m in all_movies if m["id"] in now_showing_ids]
    dates = (api_get("/dates") or {}).get("dates", [])
    by_id = {m["id"]: m for m in all_movies}

    # --- Step 0/1: pick a movie ---
    if st.session_state.selected_movie_id is None:
        st.markdown('<div class="chip-label">Filter <span>by title</span></div>', unsafe_allow_html=True)
        title_query = st.text_input(
            "Search movies by title",
            key="movie_title_filter",
            placeholder="Type a movie title…",
            label_visibility="collapsed",
        ).strip().lower()

        st.markdown('<div class="chip-label">Filter <span>by genre</span></div>', unsafe_allow_html=True)
        genres = ["All"] + sorted({m["genre"] for m in movies})
        sel_genre = st.pills("Genre", genres, key="genre_pill", default="All", label_visibility="collapsed")

        st.markdown('<div class="chip-label">Sort <span>movies</span></div>', unsafe_allow_html=True)
        sort_by = st.selectbox(
            "Sort movies",
            ["Rating (high → low)", "Year (new → old)", "Title (A → Z)"],
            key="movie_sort",
            label_visibility="collapsed",
        )
        sort_keys = {
            "Rating (high → low)": lambda m: (-m["rating"], m["title"]),
            "Year (new → old)": lambda m: (-m["year"], m["title"]),
            "Title (A → Z)": lambda m: m["title"].lower(),
        }
        visible = sorted(
            [
                m for m in movies
                if (sel_genre == "All" or m["genre"] == sel_genre)
                and (not title_query or title_query in m["title"].lower())
            ],
            key=sort_keys[sort_by],
        )

        if not visible:
            st.info(f"No movies match “{title_query}”. Clear the search to see all titles.")
        else:
            if st.button("🎲 Surprise me", key="surprise_me", use_container_width=False):
                _pick_movie(random.choice(visible)["id"])
                st.rerun()
            st.markdown('<div class="movie-grid">', unsafe_allow_html=True)
            for m in visible:
                title = html.escape(m["title"])
                synopsis = html.escape(m["synopsis"])
                stars = _stars(m["rating"])
                grad = _palette(m["title"])
                st.markdown(
                    f'<div class="movie-card">'
                    f'<div class="movie-poster" style="background:{grad};"><h3>{title}</h3></div>'
                    f'<div class="movie-body">'
                    f'<div class="movie-meta"><span class="badge badge-genre">{html.escape(m["genre"])}</span>'
                    f'<span class="badge badge-year">{m["year"]}</span>'
                    f'<span class="stars">{stars}</span>'
                    f'<span style="color:var(--muted);font-weight:700;">{m["rating"]}/10</span></div>'
                    f'<div class="synopsis">{synopsis}</div>'
                    f'</div></div>',
                    unsafe_allow_html=True,
                )
                st.button("🎟️ Book Tickets", key=f"book_{m['id']}", use_container_width=True,
                          on_click=_pick_movie, args=(m["id"],))
            st.markdown("</div>", unsafe_allow_html=True)
        _footer()
        return

    movie = by_id.get(st.session_state.selected_movie_id)
    if not movie:
        _clear_booking_flow()
        st.rerun()

    # --- Step 2: pick a date + showtime ---
    if st.session_state.selected_showtime_id is None:
        _stepper(["Movie", "Showtime", "Seats", "Payment"], 1)
        st.markdown('<div class="panel">', unsafe_allow_html=True)
        st.markdown('<div class="chip-label">Selected Movie</div>', unsafe_allow_html=True)
        title = html.escape(movie["title"])
        synopsis = html.escape(movie["synopsis"])
        grad = _palette(movie["title"])
        st.markdown(
            f'<div style="display:flex;gap:1.2rem;align-items:center;flex-wrap:wrap;">'
            f'<div style="width:110px;height:150px;border-radius:14px;background:{grad};'
            f'flex-shrink:0;display:flex;align-items:flex-end;padding:0.7rem;'
            f'box-shadow:0 12px 34px rgba(0,0,0,0.5);">'
            f'<span style="color:#fff;font-weight:700;font-family:Space Grotesk;font-size:0.95rem;line-height:1.15;">{title}</span></div>'
            f'<div style="flex:1;min-width:260px;">'
            f'<div class="movie-meta" style="margin-bottom:0.5rem;">'
            f'<span class="badge badge-genre">{html.escape(movie["genre"])}</span>'
            f'<span class="badge badge-year">{movie["year"]}</span>'
            f'<span class="stars">{_stars(movie["rating"])}</span></div>'
            f'<div class="synopsis">{synopsis}</div>'
            f'</div></div>',
            unsafe_allow_html=True,
        )
        st.markdown("</div>", unsafe_allow_html=True)

        st.markdown('<div class="chip-label">Pick a Date</div>', unsafe_allow_html=True)
        sel_date = st.segmented_control("Date", dates, key="date_ctl", default=dates[0] if dates else None,
                                        label_visibility="collapsed")

        st.markdown('<div class="chip-label">Pick a Showtime</div>', unsafe_allow_html=True)
        q = f"/showtimes?movie_id={movie['id']}"
        if sel_date:
            q += f"&show_date={sel_date}"
        showtimes = (api_get(q) or {}).get("showtimes", [])
        if not showtimes:
            st.info("No showtimes scheduled for this movie on that date.")
            _footer()
            return
        for st_obj in showtimes:
            left, right = st.columns([3, 1])
            left.markdown(
                f'<div class="showtime-card"><div><div class="showtime-time">{html.escape(st_obj["show_time"])}</div>'
                f'<div class="showtime-info">{html.escape(st_obj["theater_name"])} · {html.escape(st_obj["screen_name"])} · {html.escape(st_obj["city"])} · {st_obj["show_date"]}</div></div>'
                f'<div class="showtime-price">₹{int(st_obj["base_price"])}</div></div>',
                unsafe_allow_html=True,
            )
            right.button("Select", key=f"st_{st_obj['id']}", on_click=_pick_showtime, args=(st_obj["id"],))
        _footer()
        return

    # --- Step 3: seat selection ---
    showtime = next(
        (s for s in (api_get(f"/showtimes?movie_id={movie['id']}") or {}).get("showtimes", [])
         if s["id"] == st.session_state.selected_showtime_id),
        None,
    )
    if not showtime:
        _clear_booking_flow()
        st.rerun()

    seat_map = api_get(f"/seats?showtime_id={showtime['id']}")
    available_count = (
        sum(1 for row in seat_map["seats"] for s in row if s["status"] == "available")
        if seat_map else 0
    )
    _stepper(["Movie", "Showtime", "Seats", "Payment"], 2)
    st.markdown('<div class="panel">', unsafe_allow_html=True)
    st.markdown('<div class="chip-label">Booking Summary</div>', unsafe_allow_html=True)
    st.markdown(
        f'<div style="font-size:1.35rem;font-weight:700;color:#fff;">{html.escape(movie["title"])}</div>'
        f'<div class="showtime-info" style="margin-top:0.25rem;">{html.escape(showtime["theater_name"])} · '
        f'{html.escape(showtime["screen_name"])} · {html.escape(showtime["city"])} · '
        f'{showtime["show_date"]} at <strong style="color:var(--accent-1);">{showtime["show_time"]}</strong> · '
        f'<span style="color:#a7f3d0;font-weight:700;">₹{int(showtime["base_price"])}/seat</span> · '
        f'<strong style="color:var(--accent-2);">{available_count} seats available</strong></div>',
        unsafe_allow_html=True,
    )
    st.markdown("</div>", unsafe_allow_html=True)

    if not seat_map:
        st.error("Seat map unavailable.")
        return

    st.markdown('<div class="screen-block">Screen this way</div>', unsafe_allow_html=True)
    st.markdown(
        '<div class="legend">'
        '<span><span class="seat-legend-dot legend-avail"></span>Available</span>'
        '<span><span class="seat-legend-dot legend-sel"></span>Selected</span>'
        '<span><span class="seat-legend-dot legend-occ"></span>Occupied</span>'
        '<span><span class="seat-legend-dot legend-blk"></span>Blocked</span>'
        '</div>',
        unsafe_allow_html=True,
    )

    seat_status = {}
    for row in seat_map["seats"]:
        for s in row:
            seat_status[s["seat"]] = s["status"]

    with st.container(key="seat_map"):
        rows_n = len(seat_map["seats"])
        cols_n = len(seat_map["seats"][0]) if rows_n else 0

        header_cols = st.columns(cols_n + 1)
        header_cols[0].markdown("")
        for c_idx, s in enumerate(seat_map["seats"][0]):
            with header_cols[c_idx + 1]:
                st.markdown(f'<div class="seat-cols-header">{c_idx + 1}</div>', unsafe_allow_html=True)

        for r_idx, row in enumerate(seat_map["seats"]):
            cols = st.columns(cols_n + 1)
            cols[0].markdown(f'<div class="seat-rowlabel">{chr(65 + r_idx)}</div>', unsafe_allow_html=True)
            for c_idx, s in enumerate(row):
                with cols[c_idx + 1]:
                    seat = s["seat"]
                    if s["status"] == "occupied":
                        st.markdown(f'<div class="seat-chip seat-occ">✕</div>', unsafe_allow_html=True)
                    elif s["status"] == "blocked":
                        st.markdown(f'<div class="seat-chip seat-blk">·</div>', unsafe_allow_html=True)
                    else:
                        selected = seat in st.session_state.selected_seats
                        st.button(
                            seat,
                            key=f"seat_{seat}",
                            type="primary" if selected else "secondary",
                            use_container_width=True,
                            on_click=_toggle_seat,
                            args=(seat,),
                        )

    selected = st.session_state.selected_seats
    total = len(selected) * showtime["base_price"]

    c1, c2, c3 = st.columns([1, 1, 3])
    c1.button("↩ Back to movies", on_click=_pick_movie, args=(movie["id"],))
    c2.button("↩ Showtimes", on_click=lambda: st.session_state.update(selected_showtime_id=None))

    st.markdown(
        f'<div class="booking-bar">'
        f'<div><div class="bb-seats">{"No seats selected" if not selected else f"{len(selected)} seat(s): " + ", ".join(sorted(selected))}</div>'
        f'<div style="color:var(--muted);font-size:0.8rem;">Confirm seats to continue</div></div>'
        f'<div class="bb-total">₹{int(total)}</div>'
        f'</div>',
        unsafe_allow_html=True,
    )
    if c3.button("Continue to payment →", use_container_width=True, disabled=not selected,
                 key="continue_to_payment"):
        st.session_state["show_payment_form"] = True

    if st.session_state.get("show_payment_form"):
        render_payment_step(showtime, movie)
    _footer()


# ============================================================ AI SEARCH
def page_ai_search():
    _hero("Semantic Search", "Find your next watch", "Vector matching across the catalog — grounded AI explanations")
    if not backend_online():
        st.error("Backend offline. Start it with `uvicorn backend.app.main:app --port 8000`.")
        return

    st.markdown('<div class="search-card">', unsafe_allow_html=True)
    st.markdown('<div class="chip-label">Search</div>', unsafe_allow_html=True)
    genres = (api_get("/genres") or {}).get("genres", [])
    g1, g2, g3 = st.columns([3, 1, 1])
    query = g1.text_input("Search by title, plot concept, or mood:",
                          key="search_input",
                          placeholder="e.g. 'dream within a dream heist' or 'space survival'")
    genre = g2.selectbox("Genre", ["All"] + genres)
    media = g3.selectbox("Type", ["All", "Movie", "Book"])
    top_k = st.slider("Number of results", min_value=1, max_value=5, value=3, key="top_k_slider")
    st.markdown("</div>", unsafe_allow_html=True)

    if not query.strip():
        st.markdown(
            """
            <div class="empty-state">
                <div class="empty-icon">🔍</div>
                <div class="empty-title">Find your next watch</div>
                <div>Describe a plot, mood, or title — we match it semantically and explain why with AI.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )
        st.markdown('<div class="chip-label">Try <span>an example</span></div>', unsafe_allow_html=True)
        examples = [
            "a dream within a dream heist",
            "space survival epic",
            "feel-good time travel romance",
        ]
        example_cols = st.columns(len(examples))
        for col, example in zip(example_cols, examples):
            col.button(example, key=f"example_{zlib.crc32(example.encode())}",
                       use_container_width=True, on_click=_set_search_query, args=(example,))
        _footer()
        return

    with st.spinner("Retrieving vector matches & generating grounded explanations..."):
        try:
            data = api_post("/recommend", {
                "query": query,
                "genre": genre if genre != "All" else None,
                "item_type": media if media != "All" else None,
                "top_k": top_k,
            })
        except Exception as e:
            st.error(f"❌ {html.escape(str(e))}")
            _footer()
            return

    recs = data.get("recommendations", [])
    if not recs:
        st.info("No matching items found for your criteria. Try adjusting the genre or media type filter.")
        _footer()
        return

    is_cached = data.get("cached", False)
    badge = '<span class="badge badge-cached">⚡ cached</span>' if is_cached else '<span class="badge badge-fresh">✨ fresh</span>'
    st.markdown(
        f'<div class="showtime-info"><strong style="color:#f8fafc;">{len(recs)}</strong> match(es) for '
        f'<i>“{html.escape(query)}”</i> {badge}</div>',
        unsafe_allow_html=True,
    )

    cards = []
    for idx, rec in enumerate(recs, 1):
        title = html.escape(str(rec["title"]))
        year = html.escape(str(rec.get("year", "")))
        genre_v = html.escape(str(rec["genre"]))
        creator = html.escape(str(rec["creator"]))
        synopsis = html.escape(str(rec["synopsis"]))
        explanation = html.escape(str(rec["ai_explanation"]))
        rating = float(rec["rating"])
        sim = int(float(rec["similarity_score"]) * 100)
        type_label = "🎬 Movie" if rec["item_type"] == "Movie" else "📚 Book"
        stars = _stars(rating)
        grad = _palette(str(rec["title"]))
        cards.append(
            f'<div class="movie-card">'
            f'<div class="rec-poster" style="background:{grad};">'
            f'<div class="rec-rank">#{idx}</div>'
            f'<div class="rec-type">{type_label}</div>'
            f'<h3>{title}</h3></div>'
            f'<div class="movie-body">'
            f'<div class="movie-meta">'
            f'<span class="badge-genre">{genre_v}</span>'
            f'<span>{year}</span>'
            f'<span class="stars">{stars}</span>'
            f'<span><strong style="color:#f8fafc;">{rating}/10</strong></span>'
            f'</div>'
            f'<div class="synopsis">{synopsis}</div>'
            f'<div class="match-lbl">Semantic match</div>'
            f'<div class="match-bar"><div class="match-fill" style="width:{min(sim, 100)}%;"></div></div>'
            f'<div class="search-meta">'
            f'<span style="color:var(--muted);font-size:0.82rem;">by <strong style="color:#aebfd8;">{creator}</strong></span>'
            f'<span class="match-pct">{sim}%</span></div>'
            f'<div class="why-box"><b>💡 Why recommended:</b> {explanation}</div>'
            f'</div>'
            f'</div>'
        )
    st.markdown(f'<div class="movie-grid">{"".join(cards)}</div>', unsafe_allow_html=True)

    showtime_movie_ids = {s["movie_id"] for s in (api_get("/showtimes") or {}).get("showtimes", [])}
    bookable = [r for r in recs if r["item_type"] == "Movie" and r["id"] in showtime_movie_ids]
    if bookable:
        st.markdown('<div class="chip-label">Book <span>a result</span></div>', unsafe_allow_html=True)
        book_cols = st.columns(len(bookable))
        for col, rec in zip(book_cols, bookable):
            col.button(
                f"🎟️ {rec['title']}",
                key=f"book_rec_{rec['id']}",
                use_container_width=True,
                on_click=_book_from_search,
                args=(rec["id"],),
            )
    _footer()


# ============================================================ AI ASSISTANT
def page_chat():
    _hero("AI Concierge", "Ask anything", "Showtimes, movie picks, booking help — grounded in tonight's schedule")
    if not backend_online():
        st.error("Backend offline.")
        return

    st.session_state.setdefault("chat_history", [])
    presets = [
        "🎬 what sci-fi is on tonight?",
        "🍿 best family movie today",
        "🕗 what time is Oppenheimer?",
    ]

    def _do_send(message):
        message = message.strip()
        if not message:
            return
        st.session_state.chat_history.append({"role": "user", "content": message})
        try:
            resp = api_post("/chat", {"message": message, "history": st.session_state.chat_history[:-1]})
            st.session_state.chat_history.append({"role": "assistant", "content": resp["reply"]})
        except Exception as e:
            st.session_state.chat_history.append({"role": "assistant", "content": f"Error: {e}"})

    def _send_chat():
        _do_send(st.session_state.get("chat_input", ""))

    if not st.session_state.chat_history:
        st.markdown(
            '<div class="empty-state">'
            '<div class="empty-icon">🤖</div>'
            '<div class="empty-title">Ask the concierge</div>'
            '<div>Showtimes, movie picks, booking help — grounded in tonight\'s schedule.</div>'
            '</div>',
            unsafe_allow_html=True,
        )
        st.markdown('<div class="chip-label">Try <span>asking</span></div>', unsafe_allow_html=True)
        preset_cols = st.columns(len(presets))
        for col, preset in zip(preset_cols, presets):
            col.button(preset, key=f"preset_{zlib.crc32(preset.encode())}",
                       use_container_width=True, on_click=_do_send, args=(preset,))

    msgs = "".join(
        f'<div class="chat-row {"user" if m["role"] == "user" else "ai"}">'
        f'<div class="chat-avatar {"user" if m["role"] == "user" else "ai"}">{"🧑" if m["role"] == "user" else "🤖"}</div>'
        f'<div class="chat-bubble {"chat-user" if m["role"] == "user" else "chat-ai"}">'
        f'{html.escape(m["content"]).replace(chr(10), "<br>")}</div>'
        f'</div>'
        for m in st.session_state.chat_history[-20:]
    )
    if msgs:
        st.markdown(f'<div class="chat-wrap">{msgs}</div>', unsafe_allow_html=True)

    st.text_input("Message", key="chat_input", placeholder="e.g. 'what sci-fi is showing tonight?'")
    c_send, c_clear = st.columns([3, 1])
    c_send.button("Send", on_click=_send_chat, use_container_width=True)
    if c_clear.button("🗑️ Clear", use_container_width=True):
        st.session_state.chat_history = []
        st.rerun()
    st.caption("Powered by Groq. Responses are grounded in tonight's schedule.")
    _footer()


# ============================================================ MY BOOKING
def page_my_booking():
    _hero("My Booking", "Your e-tickets", "Look up a booking by its reference")
    if not backend_online():
        st.error("Backend offline.")
        return

    st.markdown(
        '<div class="search-card">'
        '<div class="chip-label">🎫 Find your e-ticket</div>'
        '<div style="color:var(--muted);font-size:0.88rem;margin:-0.3rem 0 0.9rem;">'
        'Enter the booking reference you received at checkout — your ticket unlocks instantly.</div>',
        unsafe_allow_html=True,
    )
    ref = st.text_input("Booking reference", key="lookup_ref",
                        placeholder="e.g. CINE7PN9N8").strip().upper()
    if st.button("Check status", use_container_width=True, type="primary") and ref:
        try:
            data = api_get(f"/bookings/{ref}")
            if not data:
                st.error("Booking not found.")
            else:
                _render_ticket(data)
        except Exception:
            st.error("Booking not found.")
    st.markdown("</div>", unsafe_allow_html=True)

    if not ref:
        st.markdown(
            '<div class="empty-state">'
            '<div class="empty-icon">🎟️</div>'
            '<div class="empty-title">No ticket yet?</div>'
            '<div>Complete a booking and your e-ticket reference will unlock it here.</div>'
            '</div>',
            unsafe_allow_html=True,
        )
    _footer()


def _render_ticket(b):
    status_ok = b["status"] == "confirmed"
    ts_cls = "ts-confirmed" if status_ok else "ts-pending"
    ts_label = b["status"].upper()
    seats = ", ".join(b["seats"])
    st.code(b["booking_ref"], language=None)
    ticket_text = (
        "CINEREAD E-TICKET\n"
        "=================\n"
        f"Booking : {b['booking_ref']}\n"
        f"Movie   : {b['movie_title']} ({b['movie_genre']})\n"
        f"Theater : {b['theater_name']} — {b['screen_name']}, {b['city']}\n"
        f"Show    : {b['show_date']} at {b['show_time']}\n"
        f"Seats   : {seats}\n"
        f"Amount  : Rs.{int(b['total_amount'])}\n"
        f"Status  : {ts_label} (payment: {b['payment_status']})\n"
    )
    st.download_button(
        "⬇️ Download e-ticket (.txt)",
        data=ticket_text,
        file_name=f"{b['booking_ref']}.txt",
        mime="text/plain",
        use_container_width=True,
    )
    st.markdown(
        f'<div class="ticket-wrap">'
        f'<div class="ticket-head"><div class="ticket-brand">🎬 CINEREAD</div>'
        f'<div class="ticket-ref">{html.escape(b["booking_ref"])}</div></div>'
        f'<div class="ticket-body">'
        f'<div class="ticket-movie">{html.escape(b["movie_title"])}</div>'
        f'<div class="ticket-sub">{html.escape(b["movie_genre"])} · {html.escape(b["theater_name"])} ({html.escape(b["city"])})</div>'
        f'<div class="ticket-details">'
        f'<div class="ticket-cell"><div class="tc-label">Screen</div><div class="tc-value">{html.escape(b["screen_name"])}</div></div>'
        f'<div class="ticket-cell"><div class="tc-label">Show</div><div class="tc-value">{b["show_date"]} · {b["show_time"]}</div></div>'
        f'<div class="ticket-cell"><div class="tc-label">Seats</div><div class="tc-value">{html.escape(seats)}</div></div>'
        f'<div class="ticket-cell"><div class="tc-label">Amount</div><div class="tc-value">₹{int(b["total_amount"])}</div></div>'
        f'<div class="ticket-cell"><div class="tc-label">Payment</div><div class="tc-value" style="text-transform:capitalize;">{html.escape(b["payment_status"])}</div></div>'
        f'<div class="ticket-cell"><div class="tc-label">Status</div><div class="tc-value"><span class="ticket-status {ts_cls}">{ts_label}</span></div></div>'
        f'</div></div>'
        f'<div class="ticket-stub"><div class="ticket-barcode"></div>'
        f'<div style="font-family:Space Grotesk;font-weight:700;color:#8ba0bf;font-size:0.8rem;white-space:nowrap;">KEEP THIS REFERENCE</div></div>'
        f'</div>',
        unsafe_allow_html=True,
    )


# ============================================================ payment step
def render_payment_step(showtime, movie):
    st.markdown('<div class="panel">', unsafe_allow_html=True)
    st.markdown('<div class="chip-label">Confirm Booking</div>', unsafe_allow_html=True)
    seats = sorted(st.session_state.selected_seats)
    total = len(seats) * showtime["base_price"]
    st.markdown(
        f'<div style="font-size:1.35rem;font-weight:700;color:#fff;">{html.escape(movie["title"])}</div>'
        f'<div class="showtime-info" style="margin-top:0.25rem;">{html.escape(showtime["theater_name"])} · '
        f'{html.escape(showtime["screen_name"])} · {html.escape(showtime["city"])} · '
        f'{showtime["show_date"]} at {showtime["show_time"]}</div>'
        f'<div class="showtime-info" style="margin-top:0.5rem;">Seats: <strong style="color:var(--gold);">{", ".join(seats)}</strong> · '
        f'Total <strong style="color:#a7f3d0;">₹{int(total)}</strong></div>',
        unsafe_allow_html=True,
    )
    n1, n2 = st.columns(2)
    name = n1.text_input("Your name", key="book_name", placeholder="Full name")
    email = n2.text_input("Your email", key="book_email", placeholder="you@example.com")

    if st.button("💳 Proceed to payment", use_container_width=True, type="primary",
                 disabled=not (name.strip() and email.strip())):
        try:
            result = api_post("/bookings", {
                "showtime_id": showtime["id"],
                "customer_name": name.strip(),
                "customer_email": email.strip(),
                "seats": seats,
            })
            st.session_state.booking_result = result
            st.session_state.selected_seats = []
            st.rerun()
        except Exception as e:
            st.error(f"❌ {html.escape(str(e))}")
    st.markdown("</div>", unsafe_allow_html=True)

    if st.session_state.get("booking_result"):
        _render_payment_gateway(st.session_state.booking_result)


def _render_payment_gateway(b):
    if st.session_state.get("confirmed_booking_ref") == b["booking_ref"]:
        _render_ticket(b)
        st.success("Your e-ticket is ready. Keep the booking reference for entry.")
        if st.button("🎟️ Book another movie", key="book_again"):
            _clear_booking_flow()
            st.rerun()
        return

    st.markdown('<div class="ticket-wrap">', unsafe_allow_html=True)
    st.markdown('<div class="ticket-head"><div class="ticket-brand">💳 PAYMENT</div>'
                f'<div class="ticket-ref">{html.escape(b["booking_ref"])}</div></div>', unsafe_allow_html=True)
    st.markdown(
        f'<div class="ticket-body">'
        f'<div class="ticket-details">'
        f'<div class="ticket-cell"><div class="tc-label">Booking</div><div class="tc-value">{html.escape(b["booking_ref"])}</div></div>'
        f'<div class="ticket-cell"><div class="tc-label">Amount</div><div class="tc-value">₹{int(b["total_amount"])}</div></div>'
        f'<div class="ticket-cell"><div class="tc-label">Movie</div><div class="tc-value">{html.escape(b["movie_title"])}</div></div>'
        f'<div class="ticket-cell"><div class="tc-label">Seats</div><div class="tc-value">{", ".join(b["seats"])}</div></div>'
        f'</div></div>',
        unsafe_allow_html=True,
    )
    if b["payment_mock"]:
        st.warning("Razorpay keys not configured — using simulated payment.")
        if st.button("✅ Simulate payment & confirm", key="mock_pay", type="primary", use_container_width=True):
            _do_verify(b["booking_ref"])
    else:
        if b.get("payment_url"):
            st.markdown(
                f'<a href="{html.escape(b["payment_url"])}" target="_blank" style="display:block;text-align:center;margin:0.8rem 0;">'
                f'<span style="display:inline-block;background:linear-gradient(135deg,#1c64d8,#2563eb);color:#fff;padding:0.7rem 1.6rem;border-radius:12px;font-weight:700;">💳 Pay with Razorpay</span></a>',
                unsafe_allow_html=True,
            )
        if st.button("🔎 I've paid — check confirmation", key="check_pay", use_container_width=True):
            _do_verify(b["booking_ref"])
    st.markdown("</div>", unsafe_allow_html=True)


def _do_verify(booking_ref):
    try:
        res = api_post(f"/bookings/{booking_ref}/verify", {"booking_ref": booking_ref})
        st.session_state["verified"] = res
        if res.get("status") == "confirmed":
            st.session_state["confirmed_booking_ref"] = booking_ref
    except Exception as e:
        st.error(f"❌ {html.escape(str(e))}")
    st.rerun()


# ============================================================ main dispatch
if page == "🎟️ Now Showing":
    page_now_showing()
elif page == "✨ AI Search":
    page_ai_search()
elif page == "🤖 AI Assistant":
    page_chat()
elif page == "🎫 My Booking":
    page_my_booking()
