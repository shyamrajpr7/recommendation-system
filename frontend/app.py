import html
import requests
import streamlit as st

# Page Configuration
st.set_page_config(
    page_title="CineRead — AI Movie & Book Recommender",
    page_icon="🎬",
    layout="wide",
    initial_sidebar_state="expanded",
)

BACKEND_URL = "http://127.0.0.1:8000"


@st.cache_data(ttl=30, show_spinner=False)
def fetch_genres():
    try:
        res = requests.get(f"{BACKEND_URL}/genres", timeout=3)
        if res.status_code == 200:
            return res.json().get("genres", [])
    except Exception:
        pass
    return ["Sci-Fi", "Fantasy", "Thriller", "Action", "Drama",
            "Mystery", "Non-Fiction", "Comedy", "Romance"]


@st.cache_data(ttl=5, show_spinner=False)
def backend_online():
    try:
        res = requests.get(f"{BACKEND_URL}/health", timeout=2)
        return res.status_code == 200
    except Exception:
        return False


def recommend(query, genre, item_type):
    payload = {"query": query, "genre": genre, "item_type": item_type, "top_k": 3}
    response = requests.post(f"{BACKEND_URL}/recommend", json=payload, timeout=15)
    response.raise_for_status()
    return response.json()


def stars(rating):
    filled = round(rating / 2)
    return "★" * filled + "☆" * (5 - filled)


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

    /* Hide default streamlit chrome */
    #MainMenu, footer { visibility: hidden; }

    /* --------------------------------------------------- hero ---- */
    .hero {
        text-align: center;
        padding: 2.4rem 1.5rem 2rem;
        border-radius: 20px;
        border: 1px solid var(--border);
        background: linear-gradient(135deg, rgba(17, 26, 46, 0.9) 0%, rgba(11, 17, 32, 0.9) 100%);
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
        margin-bottom: 1.8rem;
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
        font-size: 3rem;
        font-weight: 800;
        letter-spacing: -0.02em;
        margin-bottom: 0.4rem;
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
    .hero-sub {
        color: var(--muted);
        font-size: 1.05rem;
        font-weight: 400;
    }

    /* --------------------------------------------------- search ---- */
    .search-card {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 16px;
        padding: 1.4rem 1.6rem 1.6rem;
        margin-bottom: 1.6rem;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
    }
    .chip-label {
        color: var(--muted);
        font-size: 0.85rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        margin: 0 0 0.6rem;
    }

    /* -------------------------------------------------- results ---- */
    .result-meta {
        display: flex;
        align-items: center;
        gap: 0.8rem;
        color: var(--muted);
        margin: 0.2rem 0 1.2rem;
        font-size: 0.95rem;
    }
    .cache-badge {
        background: #2b2440;
        color: #fbbf24;
        padding: 4px 12px;
        border-radius: 999px;
        font-size: 0.78rem;
        font-weight: 700;
        letter-spacing: 0.03em;
    }
    .fresh-badge {
        background: #123042;
        color: #38bdf8;
        padding: 4px 12px;
        border-radius: 999px;
        font-size: 0.78rem;
        font-weight: 700;
        letter-spacing: 0.03em;
    }

    .rec-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
        gap: 1.4rem;
    }
    .rec-card {
        background: var(--surface);
        border: 1px solid var(--border);
        border-radius: 18px;
        padding: 1.5rem;
        display: flex;
        flex-direction: column;
        gap: 0.9rem;
        transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;
        position: relative;
    }
    .rec-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 18px 40px rgba(0, 0, 0, 0.45);
        border-color: rgba(129, 140, 248, 0.6);
    }
    .card-top {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 0.8rem;
    }
    .rank {
        flex: 0 0 auto;
        width: 34px;
        height: 34px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 0.95rem;
        color: #fff;
        background: linear-gradient(135deg, var(--accent-1), var(--accent-2));
        box-shadow: 0 4px 12px rgba(56, 189, 248, 0.35);
    }
    .card-title {
        font-size: 1.3rem;
        font-weight: 700;
        color: #f8fafc;
        line-height: 1.2;
    }
    .card-year {
        color: var(--muted);
        font-weight: 600;
        font-size: 0.95rem;
        white-space: nowrap;
    }
    .badge-movie, .badge-book {
        display: inline-block;
        padding: 3px 12px;
        border-radius: 999px;
        font-size: 0.75rem;
        font-weight: 700;
        letter-spacing: 0.03em;
    }
    .badge-movie { background: #0c4a6e; color: #7dd3fc; }
    .badge-book  { background: #134e4a; color: #5eead4; }

    .meta-row {
        display: flex;
        align-items: center;
        flex-wrap: wrap;
        gap: 0.5rem 0.9rem;
        color: var(--muted);
        font-size: 0.88rem;
    }
    .meta-row strong { color: #cbd5e1; font-weight: 600; }
    .stars { color: #fbbf24; letter-spacing: 0.1em; }

    .score-box {
        background: var(--surface-2);
        border-radius: 10px;
        padding: 0.7rem 0.9rem;
    }
    .score-label {
        display: flex;
        justify-content: space-between;
        font-size: 0.8rem;
        color: var(--muted);
        margin-bottom: 0.4rem;
    }
    .score-label b { color: #a7f3d0; font-weight: 700; }
    .score-track {
        height: 7px;
        background: #1e293b;
        border-radius: 999px;
        overflow: hidden;
    }
    .score-fill {
        height: 100%;
        border-radius: 999px;
        background: linear-gradient(90deg, #10b981, #38bdf8);
        transition: width 0.8s ease;
    }

    .synopsis-box {
        background: var(--surface-2);
        border-left: 3px solid #6366f1;
        padding: 0.75rem 0.95rem;
        border-radius: 8px;
        color: #cbd5e1;
        font-size: 0.9rem;
        line-height: 1.55;
    }
    .synopsis-box b, .ai-box b { color: #a5b4fc; font-weight: 600; }

    .ai-box {
        margin-top: auto;
        background: linear-gradient(135deg, rgba(99, 102, 241, 0.14) 0%, rgba(168, 85, 247, 0.14) 100%);
        border: 1px solid rgba(168, 85, 247, 0.35);
        padding: 0.85rem 1rem;
        border-radius: 10px;
        color: #e2e8f0;
        font-size: 0.92rem;
        line-height: 1.6;
    }

    /* ------------------------------------------------- empty state ---- */
    .empty-state {
        text-align: center;
        padding: 3.5rem 1.5rem;
        color: var(--muted);
    }
    .empty-icon { font-size: 3.2rem; margin-bottom: 0.8rem; }
    .empty-title { font-size: 1.5rem; font-weight: 700; color: var(--text); margin-bottom: 0.4rem; }

    /* ------------------------------------------------------ footer ---- */
    .footer {
        margin-top: 2.6rem;
        padding-top: 1.2rem;
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

# --------------------------------------------------------------- hero ----
st.markdown(
    """
    <div class="hero">
        <div class="hero-title">🎬 CineRead Recommender</div>
        <div class="hero-sub">Vector search · Semantic embeddings · Grounded AI rationale</div>
    </div>
    """,
    unsafe_allow_html=True,
)

# ------------------------------------------------------------ sidebar ----
with st.sidebar:
    st.markdown("##### ⚙️ Filter Preferences")

    genres = fetch_genres()
    selected_genre = st.selectbox("Genre", ["All"] + genres, index=0)
    selected_type = st.radio("Media Type", ["All", "Movie", "Book"], index=0, horizontal=True)

    online = backend_online()
    st.markdown("---")
    if online:
        st.markdown("<span style='color:#10b981;font-weight:700;'>●</span> Backend online", unsafe_allow_html=True)
    else:
        st.markdown("<span style='color:#f87171;font-weight:700;'>●</span> Backend offline", unsafe_allow_html=True)
    st.caption("Start it with: `uvicorn backend.app.main:app --port 8000`")

# ------------------------------------------------------------- search ----
st.markdown('<div class="search-card">', unsafe_allow_html=True)
st.markdown('<div class="chip-label">Popular Search Ideas</div>', unsafe_allow_html=True)

st.session_state.setdefault("input_text", "")
st.session_state.setdefault("query_to_search", "")


def _apply_preset(query):
    st.session_state.input_text = query
    st.session_state.query_to_search = query


def _find():
    st.session_state.query_to_search = st.session_state.input_text.strip()


def _clear():
    st.session_state.input_text = ""
    st.session_state.query_to_search = ""


preset_cols = st.columns(4)
PRESETS = {
    "🪐 Space & Time": "mind bending sci-fi about space exploration and time dilation",
    "🕵️ Crime & Mystery": "dark atmospheric psychological thriller with serial killer detective mystery",
    "💻 Cyberpunk": "cyberpunk computer hackers entering virtual matrix reality",
    "⚡ Habit Mastery": "practical framework for self improvement daily habits",
}
for col, (label, q) in zip(preset_cols, PRESETS.items()):
    col.button(label, use_container_width=True, on_click=_apply_preset, args=(q,))

st.text_input(
    "Search by title, plot concept, or mood:",
    key="input_text",
    placeholder="e.g. 'dream within a dream corporate heist' or 'wizard school fantasy quest'",
)

c1, c2 = st.columns([4, 1])
c1.button("✨ Find Recommendations", use_container_width=True, on_click=_find)
c2.button("🗑 Clear", use_container_width=True, on_click=_clear)

st.markdown("</div>", unsafe_allow_html=True)

# ---------------------------------------------------------- empty state ----
if not st.session_state.query_to_search:
    st.markdown(
        """
        <div class="empty-state">
            <div class="empty-icon">🎯</div>
            <div class="empty-title">Find your next favorite</div>
            <div>Type a title, describe a plot, or pick a mood above — we'll match it semantically and explain why.</div>
        </div>
        """,
        unsafe_allow_html=True,
    )
    st.stop()

# ------------------------------------------------------------- results ----
with st.spinner("Retrieving vector matches & generating grounded explanations..."):
    try:
        data = recommend(
            st.session_state.query_to_search,
            selected_genre if selected_genre != "All" else None,
            selected_type if selected_type != "All" else None,
        )
        recommendations = data.get("recommendations", [])
        is_cached = data.get("cached", False)

        badge = '<span class="cache-badge">⚡ Served from cache</span>' if is_cached \
            else '<span class="fresh-badge">✨ Fresh retrieval & AI explanation</span>'
        st.markdown(
            f'<div class="result-meta"><b style="color:#f8fafc;">{len(recommendations)}'
            f'{" match" if len(recommendations) == 1 else " matches"}</b> for '
            f'<i>“{html.escape(st.session_state.query_to_search)}”</i>{badge}</div>',
            unsafe_allow_html=True,
        )

        if not recommendations:
            st.info("No matching items found for your criteria. Try adjusting the genre or media type filter.")
        else:
            cards = []
            for idx, rec in enumerate(recommendations, 1):
                title = html.escape(str(rec["title"]))
                year = html.escape(str(rec.get("year", "")))
                genre = html.escape(str(rec["genre"]))
                creator = html.escape(str(rec["creator"]))
                synopsis = " ".join(html.escape(str(rec["synopsis"])).split())
                explanation = " ".join(html.escape(str(rec["ai_explanation"])).split())
                rating = float(rec["rating"])
                sim = int(float(rec["similarity_score"]) * 100)
                type_badge = "badge-movie" if rec["item_type"] == "Movie" else "badge-book"
                type_icon = "🎬" if rec["item_type"] == "Movie" else "📚"

                cards.append(f"""
                    <div class="rec-card">
                        <div class="card-top">
                            <div class="rank">#{idx}</div>
                            <div class="card-title">{title}</div>
                            <div class="card-year">{year}</div>
                        </div>
                        <div>
                            <span class="{type_badge}">{type_icon} {html.escape(str(rec['item_type']))}</span>
                        </div>
                        <div class="meta-row">
                            <span>Genre: <strong>{genre}</strong></span>
                            <span>By <strong>{creator}</strong></span>
                            <span class="stars">{stars(rating)}</span>
                            <span><strong>{rating}/10</strong></span>
                        </div>
                        <div class="score-box">
                            <div class="score-label"><span>Semantic match</span><b>{sim}%</b></div>
                            <div class="score-track"><div class="score-fill" style="width:{sim}%"></div></div>
                        </div>
                        <div class="synopsis-box"><b>Synopsis:</b> {synopsis}</div>
                        <div class="ai-box"><b>💡 Why recommended:</b> {explanation}</div>
                    </div>
                """.strip())

            st.markdown(f'<div class="rec-grid">{"".join(cards)}</div>', unsafe_allow_html=True)

    except requests.exceptions.ConnectionError:
        st.error("❌ Could not reach the FastAPI backend. Start it with "
                 "`uvicorn backend.app.main:app --port 8000` and reload this page.")
    except Exception as e:
        st.error(f"An error occurred: {html.escape(str(e))}")

# -------------------------------------------------------------- footer ----
st.markdown(
    """
    <div class="footer">
        <b>CineRead</b> · FAISS + Sentence-Transformers + Gemini · retrieval and explanation are strictly separated
    </div>
    """,
    unsafe_allow_html=True,
)
