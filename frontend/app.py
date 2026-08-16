import html
import json
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

BACKEND_URL = "http://127.0.0.1:8000"


# ---------------------------------------------------------------- API ----
@st.cache_data(ttl=30, show_spinner=False)
def api_get(path: str):
    try:
        res = requests.get(f"{BACKEND_URL}{path}", timeout=10)
        return res.json()
    except Exception:
        return None


def api_post(path: str, payload: dict):
    res = requests.post(f"{BACKEND_URL}{path}", json=payload, timeout=30)
    if res.status_code >= 400:
        detail = res.json().get("detail")
        raise RuntimeError(detail if isinstance(detail, str) else str(detail))
    return res.json()


@st.cache_data(ttl=5, show_spinner=False)
def backend_online():
    try:
        res = requests.get(f"{BACKEND_URL}/health", timeout=2)
        return res.status_code == 200
    except Exception:
        return False


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

    ::-webkit-scrollbar { width: 10px; height: 10px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #223054; border-radius: 999px; border: 2px solid var(--bg); }
    ::-webkit-scrollbar-thumb:hover { background: #2e3f6e; }

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
    }
    .brand-sub { color: var(--muted-2); font-size: 0.8rem; margin-top: 0.15rem; }

    [data-testid="stSidebar"] .stRadio > label, [data-testid="stSidebar"] [role="radiogroup"] label { color: var(--muted); font-weight: 500; }
    [data-testid="stSidebar"] [role="radiogroup"] label:hover { color: var(--text); }
    [data-testid="stSidebar"] [role="radiogroup"] label p { font-size: 0.95rem; }

    .status-pill {
        display: inline-flex; align-items: center; gap: 0.45rem;
        padding: 0.35rem 0.8rem; border-radius: 999px;
        font-size: 0.78rem; font-weight: 700; border: 1px solid;
    }
    .status-on { background: rgba(16, 185, 129, 0.12); color: #6ee7b7; border-color: rgba(52, 211, 153, 0.35); }
    .status-off { background: rgba(248, 113, 113, 0.12); color: #fca5a5; border-color: rgba(248, 113, 113, 0.35); }
    .status-dot { width: 7px; height: 7px; border-radius: 50%; display: inline-block; }
    .status-on .status-dot { background: #34d399; box-shadow: 0 0 8px #34d399; }
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
        font-size: 0.72rem; font-weight: 700; letter-spacing: 0.22em; text-transform: uppercase;
        color: var(--accent-1);
        border: 1px solid rgba(56, 189, 248, 0.3);
        padding: 0.25rem 0.9rem; border-radius: 999px;
        background: rgba(56, 189, 248, 0.08);
        margin-bottom: 0.9rem;
    }
    .hero-title {
        font-family: 'Space Grotesk', sans-serif;
        font-size: 3rem; font-weight: 700; letter-spacing: -0.03em;
        background: linear-gradient(90deg, #38bdf8, #818cf8, #c084fc, #38bdf8);
        background-size: 300% 100%;
        -webkit-background-clip: text; background-clip: text;
        -webkit-text-fill-color: transparent;
        animation: shimmer 9s linear infinite;
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
    }
    .chip-label {
        color: var(--muted);
        font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.12em;
        margin: 0 0 0.7rem;
    }
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
    }
    .movie-card:hover {
        transform: translateY(-6px);
        box-shadow: 0 26px 60px rgba(0, 0, 0, 0.55);
        border-color: rgba(129, 140, 248, 0.55);
    }
    .movie-poster {
        position: relative;
        height: 150px;
        display: flex; align-items: flex-end;
        padding: 1rem 1.2rem 0.85rem;
        overflow: hidden;
    }
    .movie-poster::after {
        content: "";
        position: absolute; inset: 0;
        background: linear-gradient(180deg, rgba(7, 11, 22, 0) 20%, rgba(7, 11, 22, 0.92) 100%);
    }
    .movie-poster h3 {
        position: relative; z-index: 2;
        color: #fff; font-size: 1.45rem; font-weight: 700; line-height: 1.15;
        margin: 0; text-shadow: 0 2px 14px rgba(0, 0, 0, 0.5);
    }
    .movie-body { padding: 1.05rem 1.2rem 1.2rem; display: flex; flex-direction: column; gap: 0.7rem; flex: 1; }
    .movie-meta { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; color: var(--muted); font-size: 0.84rem; }
    .badge { display: inline-block; padding: 3px 11px; border-radius: 999px; font-size: 0.72rem; font-weight: 700; }
    .badge-genre { background: rgba(56, 189, 248, 0.12); color: #7dd3fc; border: 1px solid rgba(56, 189, 248, 0.25); }
    .badge-year { background: rgba(52, 211, 153, 0.12); color: #6ee7b7; border: 1px solid rgba(52, 211, 153, 0.25); }
    .badge-rank { background: rgba(251, 191, 36, 0.14); color: #fcd34d; border: 1px solid rgba(251, 191, 36, 0.3); }
    .stars { color: var(--gold); letter-spacing: 0.08em; font-size: 0.82rem; }
    .synopsis { color: #b6c4da; font-size: 0.9rem; line-height: 1.6; flex: 1; }

    .showtime-card {
        background: linear-gradient(135deg, rgba(14, 22, 40, 0.9), rgba(10, 16, 29, 0.9));
        border: 1px solid var(--border-soft);
        border-radius: 14px;
        padding: 0.95rem 1.2rem;
        margin-bottom: 0.8rem;
        display: flex; justify-content: space-between; align-items: center; gap: 1rem;
        transition: border-color 0.2s ease;
    }
    .showtime-card:hover { border-color: rgba(56, 189, 248, 0.45); }
    .showtime-time { font-family: 'Space Grotesk', sans-serif; font-size: 1.35rem; font-weight: 700; color: var(--accent-1); }
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
    }
    .legend { display: flex; gap: 1.3rem; justify-content: center; color: var(--muted); font-size: 0.8rem; margin-bottom: 1.2rem; flex-wrap: wrap; }
    .legend span { display: inline-flex; align-items: center; gap: 0.4rem; }

    .empty-state { text-align: center; padding: 3.4rem 1.5rem; color: var(--muted); }
    .empty-icon { font-size: 3.2rem; margin-bottom: 0.7rem; }
    .empty-title { font-size: 1.45rem; font-weight: 700; color: var(--text); margin-bottom: 0.35rem; font-family: 'Space Grotesk', sans-serif; }

    .stepper { display: flex; align-items: center; gap: 0; margin-bottom: 1.5rem; flex-wrap: wrap; }
    .step { display: flex; align-items: center; gap: 0.5rem; color: var(--muted-2); font-size: 0.82rem; font-weight: 600; }
    .step .step-dot {
        width: 26px; height: 26px; border-radius: 50%;
        display: flex; align-items: center; justify-content: center;
        font-size: 0.78rem; font-weight: 700;
        background: #0a101d; border: 1px solid #223052; color: var(--muted-2);
    }
    .step.active { color: var(--text); }
    .step.active .step-dot { background: linear-gradient(135deg, #38bdf8, #818cf8); border-color: transparent; color: #08111f; }
    .step.done .step-dot { background: rgba(52, 211, 153, 0.18); border-color: rgba(52, 211, 153, 0.4); color: #6ee7b7; }
    .step-line { flex: 1; height: 1px; background: #1a2744; margin: 0 0.8rem; min-width: 22px; }

    .chat-bubble { padding: 0.75rem 1.05rem; border-radius: 14px; margin-bottom: 0.7rem; font-size: 0.92rem; line-height: 1.6; max-width: 84%; }
    .chat-user { background: linear-gradient(135deg, rgba(56, 189, 248, 0.18), rgba(129, 140, 248, 0.14)); color: #cfe8ff; margin-left: auto; border: 1px solid rgba(56, 189, 248, 0.25); }
    .chat-ai { background: var(--surface-2); border: 1px solid var(--border-soft); color: #dbe7f5; }

    .footer {
        margin-top: 2.6rem;
        padding-top: 1.2rem;
        border-top: 1px solid var(--border-soft);
        text-align: center;
        color: var(--muted-2);
        font-size: 0.82rem;
    }
    .footer b { color: #aebfd8; font-weight: 600; }
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
    st.markdown(
        '<div style="color:#5b6f8f;font-size:0.75rem;margin-top:1.1rem;line-height:1.6;">'
        'FAISS retrieval · Sentence-Transformers · Groq AI · Razorpay</div>',
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
        st.markdown('<div class="chip-label">Filter <span>by genre</span></div>', unsafe_allow_html=True)
        genres = ["All"] + sorted({m["genre"] for m in movies})
        sel_genre = st.pills("Genre", genres, key="genre_pill", default="All", label_visibility="collapsed")

        st.markdown('<div class="movie-grid">', unsafe_allow_html=True)
        for m in movies:
            if sel_genre != "All" and m["genre"] != sel_genre:
                continue
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
    st.markdown('<div class="panel">', unsafe_allow_html=True)
    st.markdown('<div class="chip-label">Booking Summary</div>', unsafe_allow_html=True)
    st.markdown(
        f'<div class="movie-title">{html.escape(movie["title"])}</div>'
        f'<div class="showtime-info">{html.escape(showtime["theater_name"])} · {html.escape(showtime["screen_name"])} · '
        f'{html.escape(showtime["city"])} · {showtime["show_date"]} {showtime["show_time"]} · '
        f'<span class="showtime-price">₹{int(showtime["base_price"])}/seat</span></div>',
        unsafe_allow_html=True,
    )
    st.markdown("</div>", unsafe_allow_html=True)

    if not seat_map:
        st.error("Seat map unavailable.")
        return

    st.markdown('<div class="screen-block">Screen this way</div>', unsafe_allow_html=True)
    st.markdown(
        '<div class="legend"><span>🟩 Available</span><span>🟦 Selected</span>'
        '<span>🟥 Occupied</span><span>⬛ Blocked</span></div>',
        unsafe_allow_html=True,
    )

    seat_status = {}
    for row in seat_map["seats"]:
        for s in row:
            seat_status[s["seat"]] = s["status"]

    for row in seat_map["seats"]:
        cols = st.columns(len(row))
        for col, s in zip(cols, row):
            seat = s["seat"]
            disabled = s["status"] in ("occupied", "blocked")
            selected = seat in st.session_state.selected_seats
            if disabled:
                label = "🟥" if s["status"] == "occupied" else "⬛"
            else:
                label = "🟦" if selected else "🟩"
            col.button(f"{label} {seat}", key=f"seat_{seat}", disabled=disabled,
                       on_click=_toggle_seat, args=(seat,), use_container_width=True)

    selected = st.session_state.selected_seats
    total = len(selected) * showtime["base_price"]
    st.markdown(
        f'<div class="showtime-info" style="margin-top:0.8rem;"><strong style="color:#f8fafc;">{len(selected)}</strong> seat(s) selected: '
        f'<strong style="color:#fbbf24;">{", ".join(sorted(selected)) if selected else "—"}</strong> · '
        f'Total <strong style="color:#a7f3d0;">₹{int(total)}</strong></div>',
        unsafe_allow_html=True,
    )

    c1, c2, c3 = st.columns([1, 1, 3])
    c1.button("↩ Back to movie", on_click=_pick_movie, args=(movie["id"],))
    c2.button("↩ Back to showtimes", on_click=lambda: st.session_state.update(selected_showtime_id=None))
    if c3.button("Continue to payment →", use_container_width=True, disabled=not selected,
                 key="continue_to_payment"):
        st.session_state["show_payment_form"] = True

    if st.session_state.get("show_payment_form"):
        render_payment_step(showtime, movie)
    _footer()


# ============================================================ AI SEARCH
def page_ai_search():
    _hero("Semantic Search", "Find your next watch", "Vector matching across the catalog — grounded Groq explanations")
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
    st.markdown("</div>", unsafe_allow_html=True)

    if not query.strip():
        st.markdown(
            """
            <div class="empty-state">
                <div class="empty-icon">🔍</div>
                <div class="empty-title">Find your next watch</div>
                <div>Describe a plot, mood, or title — we match it semantically and explain why with Grok.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )
        _footer()
        return

    with st.spinner("Retrieving vector matches & generating grounded explanations..."):
        try:
            data = api_post("/recommend", {
                "query": query,
                "genre": genre if genre != "All" else None,
                "item_type": media if media != "All" else None,
                "top_k": 3,
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
    badge = '<span class="badge-genre">⚡ cached</span>' if is_cached else '<span class="badge-year">✨ fresh</span>'
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
        stars = "★" * round(rating / 2) + "☆" * (5 - round(rating / 2))
        cards.append(
            f'<div class="movie-card">'
            f'<div class="movie-title"><span class="badge-year">#{idx}</span> {title}</div>'
            f'<div class="movie-meta"><span class="badge-genre">{genre_v}</span><span>{type_label}</span>'
            f'<span>{year}</span><span class="stars">{stars}</span><span><strong>{rating}/10</strong></span>'
            f'<span>by <strong>{creator}</strong></span></div>'
            f'<div class="synopsis"><b>Synopsis:</b> {synopsis}</div>'
            f'<div class="synopsis" style="border-left:3px solid #6366f1;padding-left:0.7rem;color:#c7d2fe;">'
            f'<b>💡 Why recommended:</b> {explanation}</div>'
            f'<div class="showtime-info">Semantic match <strong style="color:#a7f3d0;">{sim}%</strong></div>'
            f'</div>'
        )
    st.markdown(f'<div class="movie-grid">{"".join(cards)}</div>', unsafe_allow_html=True)
    _footer()


# ============================================================ AI ASSISTANT
def page_chat():
    _hero("AI Concierge", "Ask anything", "Showtimes, movie picks, booking help — grounded in tonight's schedule")
    if not backend_online():
        st.error("Backend offline.")
        return

    st.session_state.setdefault("chat_history", [])

    def _send_chat():
        msg = st.session_state.get("chat_input", "").strip()
        if not msg:
            return
        st.session_state.chat_history.append({"role": "user", "content": msg})
        try:
            resp = api_post("/chat", {"message": msg, "history": st.session_state.chat_history[:-1]})
            st.session_state.chat_history.append({"role": "assistant", "content": resp["reply"]})
        except Exception as e:
            st.session_state.chat_history.append({"role": "assistant", "content": f"Error: {e}"})

    for msg in st.session_state.chat_history[-20:]:
        cls = "chat-user" if msg["role"] == "user" else "chat-ai"
        prefix = "🧑 " if msg["role"] == "user" else "🤖 "
        st.markdown(
            f'<div class="chat-bubble {cls}">{prefix}{html.escape(msg["content"]).replace(chr(10), "<br>")}</div>',
            unsafe_allow_html=True,
        )

    st.text_input("Message", key="chat_input", placeholder="e.g. 'what sci-fi is showing tonight?'")
    st.button("Send", on_click=_send_chat, use_container_width=True)
    st.caption("Powered by Grok (xAI). Requires XAI_API_KEY in the backend environment.")
    _footer()


# ============================================================ MY BOOKING
def page_my_booking():
    _hero("My Booking", "Your e-tickets", "Look up a booking by its reference")
    if not backend_online():
        st.error("Backend offline.")
        return

    st.markdown('<div class="search-card">', unsafe_allow_html=True)
    ref = st.text_input("Booking reference", key="lookup_ref", placeholder="e.g. CINE7PN9N8")
    if st.button("Check status", use_container_width=True) and ref.strip():
        try:
            data = api_get(f"/bookings/{ref.strip()}")
            if not data:
                st.error("Booking not found.")
            else:
                _render_ticket(data)
        except Exception:
            st.error("Booking not found.")
    st.markdown("</div>", unsafe_allow_html=True)
    _footer()


def _render_ticket(b):
    status_ok = b["status"] == "confirmed"
    status_color = "#10b981" if status_ok else "#fbbf24"
    st.markdown(
        f"""
        <div class="ticket-card">
            <div class="chip-label">Booking Reference</div>
            <div class="ticket-ref">{html.escape(b['booking_ref'])}</div>
            <div class="ticket-meta">
                <div><strong>{html.escape(b['movie_title'])}</strong> · {html.escape(b['movie_genre'])}</div>
                <div>{html.escape(b['theater_name'])} ({html.escape(b['city'])}) · {html.escape(b['screen_name'])}</div>
                <div>{b['show_date']} at <strong>{b['show_time']}</strong></div>
                <div>Seats: <strong>{", ".join(b['seats'])}</strong> · Amount <strong>₹{int(b['total_amount'])}</strong></div>
                <div>Status: <strong style="color:{status_color};">{html.escape(b['status']).upper()}</strong> · Payment: {html.escape(b['payment_status'])}</div>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )


# ============================================================ payment step
def render_payment_step(showtime, movie):
    st.markdown('<div class="panel">', unsafe_allow_html=True)
    st.markdown('<div class="chip-label">Confirm Booking</div>', unsafe_allow_html=True)
    seats = sorted(st.session_state.selected_seats)
    total = len(seats) * showtime["base_price"]
    st.markdown(
        f'<div class="movie-title">{html.escape(movie["title"])}</div>'
        f'<div class="showtime-info">{html.escape(showtime["theater_name"])} · {html.escape(showtime["screen_name"])} · '
        f'{html.escape(showtime["city"])} · {showtime["show_date"]} {showtime["show_time"]}</div>'
        f'<div class="showtime-info">Seats: <strong style="color:#fbbf24;">{", ".join(seats)}</strong> · '
        f'Total <strong style="color:#a7f3d0;">₹{int(total)}</strong></div>',
        unsafe_allow_html=True,
    )
    n1, n2 = st.columns(2)
    name = n1.text_input("Your name", key="book_name")
    email = n2.text_input("Your email", key="book_email")

    if st.button("💳 Proceed to payment", use_container_width=True, disabled=not (name.strip() and email.strip())):
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
        st.markdown(
            f"""
            <div class="ticket-card">
                <div class="chip-label">✅ Booking Confirmed</div>
                <div class="ticket-ref">{html.escape(b["booking_ref"])}</div>
                <div class="ticket-meta">
                    <div><strong>{html.escape(b["movie_title"])}</strong> · {html.escape(b["movie_genre"])}</div>
                    <div>{html.escape(b["theater_name"])} ({html.escape(b["city"])}) · {html.escape(b["screen_name"])}</div>
                    <div>{b["show_date"]} at <strong>{b["show_time"]}</strong></div>
                    <div>Seats: <strong>{", ".join(b["seats"])}</strong> · Paid <strong>₹{int(b["total_amount"])}</strong></div>
                    <div>Payment: <strong style="color:#10b981;">PAID</strong> · Ticket shown on the My Booking page</div>
                </div>
            </div>
            """,
            unsafe_allow_html=True,
        )
        st.success("Your e-ticket is ready. Keep the booking reference for entry.")
        if st.button("🎟️ Book another movie", key="book_again"):
            _clear_booking_flow()
            st.rerun()
        return

    st.markdown('<div class="ticket-card">', unsafe_allow_html=True)
    st.markdown(f'<div class="chip-label">Payment</div>', unsafe_allow_html=True)
    st.markdown(
        f'<div class="ticket-meta">Booking <strong>{html.escape(b["booking_ref"])}</strong> · '
        f'Amount <strong>₹{int(b["total_amount"])}</strong></div>',
        unsafe_allow_html=True,
    )
    if b["payment_mock"]:
        st.warning("Razorpay keys not configured — using simulated payment.")
        if st.button("✅ Simulate payment & confirm", key="mock_pay"):
            _do_verify(b["booking_ref"])
    else:
        if b.get("payment_url"):
            st.markdown(
                f'<a href="{html.escape(b["payment_url"])}" target="_blank" style="display:inline-block;margin:0.6rem 0;">'
                f'<span style="background:#1c64d8;color:#fff;padding:0.6rem 1.2rem;border-radius:10px;font-weight:700;">💳 Pay with Razorpay</span></a>',
                unsafe_allow_html=True,
            )
        if st.button("🔎 I've paid — check confirmation", key="check_pay"):
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
