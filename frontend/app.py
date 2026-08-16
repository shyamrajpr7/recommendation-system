import html
import json
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


# ---------------------------------------------------------------- CSS ----
st.markdown(
    """
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

    :root {
        --bg: #0b1120;
        --surface: #111a2e;
        --surface-2: #0f172a;
        --border: #243049;
        --text: #e2e8f0;
        --muted: #94a3b8;
        --accent-1: #38bdf8;
        --accent-2: #818cf8;
        --accent-3: #c084fc;
        --green: #10b981;
    }

    html, body, .stApp {
        background: var(--bg);
        color: var(--text);
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    }

    .stApp {
        background:
            radial-gradient(1200px 600px at 80% -10%, rgba(129, 140, 248, 0.12), transparent 60%),
            radial-gradient(1000px 500px at 10% 0%, rgba(56, 189, 248, 0.10), transparent 60%),
            var(--bg);
    }

    #MainMenu, footer { visibility: hidden; }

    .hero {
        text-align: center;
        padding: 2rem 1.5rem 1.6rem;
        border-radius: 20px;
        border: 1px solid var(--border);
        background: linear-gradient(135deg, rgba(17, 26, 46, 0.9) 0%, rgba(11, 17, 32, 0.9) 100%);
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
        margin-bottom: 1.4rem;
        position: relative;
        overflow: hidden;
    }
    .hero::before {
        content: "";
        position: absolute;
        inset: 0;
        background: radial-gradient(600px 300px at 50% -20%, rgba(56, 189, 248, 0.18), transparent 70%);
    }
    .hero-title {
        font-size: 2.6rem;
        font-weight: 800;
        letter-spacing: -0.02em;
        margin-bottom: 0.3rem;
        background: linear-gradient(90deg, #38bdf8, #818cf8, #c084fc, #38bdf8);
        background-size: 300% 100%;
        -webkit-background-clip: text;
        background-clip: text;
        -webkit-text-fill-color: transparent;
        animation: shimmer 8s linear infinite;
    }
    @keyframes shimmer {
        0% { background-position: 0% 50%; }
        100% { background-position: 300% 50%; }
    }
    .hero-sub { color: var(--muted); font-size: 1rem; }

    .search-card, .panel {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 16px;
        padding: 1.3rem 1.5rem 1.5rem;
        margin-bottom: 1.4rem;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
    }
    .chip-label {
        color: var(--muted);
        font-size: 0.82rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        margin: 0 0 0.6rem;
    }

    .movie-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 1.3rem;
    }
    .movie-card {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 18px;
        padding: 1.3rem;
        display: flex;
        flex-direction: column;
        gap: 0.7rem;
        transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;
    }
    .movie-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 18px 40px rgba(0, 0, 0, 0.45);
        border-color: rgba(129, 140, 248, 0.6);
    }
    .movie-title { font-size: 1.2rem; font-weight: 700; color: #f8fafc; line-height: 1.25; }
    .movie-meta { color: var(--muted); font-size: 0.88rem; display: flex; flex-wrap: wrap; gap: 0.5rem 0.9rem; }
    .movie-meta strong { color: #cbd5e1; }
    .badge-genre {
        display: inline-block;
        padding: 3px 12px;
        border-radius: 999px;
        font-size: 0.75rem;
        font-weight: 700;
        background: #0c4a6e; color: #7dd3fc;
    }
    .badge-year { background: #134e4a; color: #5eead4; padding: 3px 12px; border-radius: 999px; font-size: 0.75rem; font-weight: 700; }
    .stars { color: #fbbf24; letter-spacing: 0.1em; }
    .synopsis { color: #cbd5e1; font-size: 0.9rem; line-height: 1.55; }

    .showtime-card {
        background: var(--surface-2);
        border: 1px solid var(--border);
        border-radius: 12px;
        padding: 0.9rem 1.1rem;
        margin-bottom: 0.8rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1rem;
    }
    .showtime-time { font-size: 1.25rem; font-weight: 800; color: var(--accent-1); }
    .showtime-info { color: var(--muted); font-size: 0.85rem; }
    .showtime-price { color: #a7f3d0; font-weight: 700; }

    .screen-block {
        text-align: center;
        color: var(--muted);
        font-size: 0.8rem;
        letter-spacing: 0.5em;
        text-transform: uppercase;
        background: var(--surface-2);
        border: 1px solid var(--border);
        border-radius: 8px;
        padding: 0.5rem;
        margin: 0 auto 1.2rem;
        max-width: 70%;
    }

    .legend { display: flex; gap: 1.4rem; justify-content: center; color: var(--muted); font-size: 0.82rem; margin-bottom: 1rem; flex-wrap: wrap; }
    .legend span { display: inline-flex; align-items: center; gap: 0.4rem; }

    .ticket-card {
        background: linear-gradient(135deg, rgba(99, 102, 241, 0.12) 0%, rgba(168, 85, 247, 0.12) 100%);
        border: 1px solid rgba(168, 85, 247, 0.4);
        border-radius: 18px;
        padding: 1.5rem;
        margin-top: 1rem;
    }
    .ticket-ref { font-size: 1.6rem; font-weight: 800; color: #fbbf24; letter-spacing: 0.04em; }
    .ticket-meta { color: var(--muted); font-size: 0.92rem; line-height: 1.8; }
    .ticket-meta strong { color: #cbd5e1; }

    .empty-state { text-align: center; padding: 3rem 1.5rem; color: var(--muted); }
    .empty-icon { font-size: 3rem; margin-bottom: 0.6rem; }
    .empty-title { font-size: 1.4rem; font-weight: 700; color: var(--text); margin-bottom: 0.3rem; }

    .chat-bubble { padding: 0.7rem 1rem; border-radius: 12px; margin-bottom: 0.6rem; font-size: 0.92rem; line-height: 1.55; max-width: 85%; }
    .chat-user { background: #123042; color: #bae6fd; margin-left: auto; }
    .chat-ai { background: var(--surface-2); border: 1px solid var(--border); color: #e2e8f0; }

    .footer {
        margin-top: 2.4rem;
        padding-top: 1.1rem;
        border-top: 1px solid var(--border);
        text-align: center;
        color: var(--muted);
        font-size: 0.85rem;
    }
    .footer b { color: #cbd5e1; }
</style>
""",
    unsafe_allow_html=True,
)


# ------------------------------------------------------------- sidebar ----
with st.sidebar:
    st.markdown("### 🎬 CineRead")
    page = st.radio(
        "Navigate",
        ["🎟️ Now Showing", "✨ AI Search", "🤖 AI Assistant", "🎫 My Booking"],
        label_visibility="collapsed",
    )

    online = backend_online()
    st.markdown("---")
    if online:
        st.markdown("<span style='color:#10b981;font-weight:700;'>●</span> Backend online", unsafe_allow_html=True)
    else:
        st.markdown("<span style='color:#f87171;font-weight:700;'>●</span> Backend offline", unsafe_allow_html=True)


def _hero(sub: str):
    st.markdown(
        f"""
        <div class="hero">
            <div class="hero-title">🎬 CineRead</div>
            <div class="hero-sub">{sub}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def _footer():
    st.markdown(
        """
        <div class="footer">
            <b>CineRead Cinema</b> · FAISS + Sentence-Transformers + Grok · Razorpay checkout
        </div>
        """,
        unsafe_allow_html=True,
    )


# ============================================================ NOW SHOWING
def page_now_showing():
    _hero("Book movie tickets — AI-powered recommendations & instant confirmation")
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
        st.markdown('<div class="chip-label">Now Showing</div>', unsafe_allow_html=True)
        genre_filters = ["All"] + sorted({m["genre"] for m in movies})
        cols = st.columns(4)
        filter_col = cols[0]
        sel_genre = filter_col.selectbox("Filter by genre", genre_filters)

        st.markdown('<div class="movie-grid">', unsafe_allow_html=True)
        for m in movies:
            if sel_genre != "All" and m["genre"] != sel_genre:
                continue
            title = html.escape(m["title"])
            synopsis = html.escape(m["synopsis"])
            stars = "★" * round(m["rating"] / 2) + "☆" * (5 - round(m["rating"] / 2))
            st.markdown(
                f"""
                <div class="movie-card">
                    <div class="movie-title">{title}</div>
                    <div class="movie-meta">
                        <span class="badge-genre">{html.escape(m['genre'])}</span>
                        <span class="badge-year">{m['year']}</span>
                        <span class="stars">{stars}</span>
                        <span><strong>{m['rating']}/10</strong></span>
                    </div>
                    <div class="synopsis">{synopsis}</div>
                </div>
                """,
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
        st.markdown('<div class="panel">', unsafe_allow_html=True)
        st.markdown('<div class="chip-label">Selected Movie</div>', unsafe_allow_html=True)
        title = html.escape(movie["title"])
        synopsis = html.escape(movie["synopsis"])
        st.markdown(
            f'<div class="movie-title">{title}</div>'
            f'<div class="movie-meta"><span class="badge-genre">{html.escape(movie["genre"])}</span>'
            f'<span class="badge-year">{movie["year"]}</span>'
            f'<span class="stars">{"★" * round(movie["rating"] / 2) + "☆" * (5 - round(movie["rating"] / 2))}</span></div>'
            f'<div class="synopsis">{synopsis}</div>',
            unsafe_allow_html=True,
        )
        st.markdown("</div>", unsafe_allow_html=True)

        st.markdown('<div class="chip-label">Pick a Date</div>', unsafe_allow_html=True)
        cols = st.columns(len(dates))
        for col, d in zip(cols, dates):
            col.button(d, use_container_width=True, key=f"date_{d}")

        st.markdown('<div class="chip-label">Pick a Showtime</div>', unsafe_allow_html=True)
        showtimes = (api_get(f"/showtimes?movie_id={movie['id']}") or {}).get("showtimes", [])
        if not showtimes:
            st.info("No showtimes scheduled for this movie.")
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
    _hero("Semantic search across the catalog — grounded AI explanations")
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
    _hero("Ask anything — showtimes, movie picks, booking help")
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
    _hero("Look up a booking by reference")
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
