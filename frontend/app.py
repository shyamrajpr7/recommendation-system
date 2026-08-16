import streamlit as st
import requests
import json

# Page Configuration
st.set_page_config(
    page_title="CineRead - AI Movie & Book Recommender",
    page_icon="🎬",
    layout="wide",
    initial_sidebar_state="expanded"
)

BACKEND_URL = "http://127.0.0.1:8000"

# Modern CSS Styling
st.markdown("""
<style>
    /* Dark glassmorphism container styling */
    .main-header {
        text-align: center;
        padding: 1.5rem 0 1rem 0;
        background: linear-gradient(135deg, #1e1e2f 0%, #0f172a 100%);
        border-radius: 16px;
        margin-bottom: 2rem;
        border: 1px solid rgba(255, 255, 255, 0.1);
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
    }
    
    .main-title {
        font-size: 2.8rem;
        font-weight: 800;
        background: linear-gradient(90deg, #38bdf8, #818cf8, #c084fc);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin-bottom: 0.3rem;
    }
    
    .sub-title {
        color: #94a3b8;
        font-size: 1.1rem;
        font-weight: 400;
    }
    
    /* Recommendation Card Styling */
    .rec-card {
        background: #1e293b;
        border-radius: 14px;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
        border: 1px solid #334155;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
    }
    
    .rec-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 12px 24px rgba(0, 0, 0, 0.4);
        border-color: #38bdf8;
    }
    
    .card-title {
        font-size: 1.4rem;
        font-weight: 700;
        color: #f8fafc;
        margin-bottom: 0.4rem;
    }

    .badge-movie {
        background-color: #0284c7;
        color: white;
        padding: 4px 10px;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .badge-book {
        background-color: #0d9488;
        color: white;
        padding: 4px 10px;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .badge-score {
        background: linear-gradient(90deg, #10b981, #059669);
        color: white;
        padding: 4px 12px;
        border-radius: 20px;
        font-size: 0.85rem;
        font-weight: 700;
        float: right;
    }

    .badge-cache {
        background: #334155;
        color: #fbbf24;
        padding: 4px 10px;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: 600;
    }

    .synopsis-box {
        background-color: #0f172a;
        border-left: 3px solid #6366f1;
        padding: 0.8rem 1rem;
        border-radius: 6px;
        color: #cbd5e1;
        font-size: 0.95rem;
        margin: 0.8rem 0;
    }

    .ai-explanation-box {
        background: linear-gradient(135deg, rgba(99, 102, 241, 0.15) 0%, rgba(168, 85, 247, 0.15) 100%);
        border: 1px solid rgba(168, 85, 247, 0.3);
        padding: 0.9rem 1.1rem;
        border-radius: 10px;
        color: #e2e8f0;
        font-size: 0.95rem;
        line-height: 1.5;
        margin-top: 0.8rem;
    }
</style>
""", unsafe_allow_html=True)

# Header Section
st.markdown("""
<div class="main-header">
    <div class="main-title">🎬 CineRead Recommender</div>
    <div class="sub-title">FAISS Vector Search + Sentence Transformers + Grounded Gemini AI Rationale</div>
</div>
""", unsafe_allow_html=True)

# Sidebar Configuration
with st.sidebar:
    st.header("⚙️ Filter Preferences")
    
    # Fetch genres dynamically from backend
    genres = ["All"]
    try:
        res = requests.get(f"{BACKEND_URL}/genres", timeout=3)
        if res.status_code == 200:
            genres += res.json().get("genres", [])
    except Exception:
        genres += ["Sci-Fi", "Fantasy", "Thriller", "Action", "Drama", "Mystery", "Non-Fiction", "Comedy", "Romance"]

    selected_genre = st.selectbox("Filter by Genre", genres, index=0)
    selected_type = st.radio("Media Type", ["All", "Movie", "Book"], index=0, horizontal=True)

    st.markdown("---")
    st.subheader("💡 System Architecture")
    st.markdown("""
    - **Vector Index**: FAISS (Inner Product Cosine Similarity)
    - **Embeddings**: `sentence-transformers/all-MiniLM-L6-v2`
    - **Metadata**: SQLite Database
    - **LLM Rationale**: Gemini 2.5 Flash
    - **Cache**: In-Memory Keyed Store
    """)

# Sample Query Presets
st.markdown("##### 🔍 Popular Search Ideas:")
preset_cols = st.columns(4)
sample_query = ""

if preset_cols[0].button("🪐 Space & Time Dilations"):
    sample_query = "mind bending sci-fi about space exploration and time dilation"
if preset_cols[1].button("🕵️ Dark Crime & Mystery"):
    sample_query = "dark atmospheric psychological thriller with serial killer detective mystery"
if preset_cols[2].button("💻 Cyberpunk Dystopia"):
    sample_query = "cyberpunk computer hackers entering virtual matrix reality"
if preset_cols[3].button("⚡ Self Habit Mastery"):
    sample_query = "practical framework for self improvement daily habits"

# Search Form
with st.form("recommendation_form"):
    user_query = st.text_input(
        "Enter a title, plot concept, or mood preference:",
        value=sample_query if sample_query else "",
        placeholder="e.g. 'dream within a dream corporate heist' or 'magic wizard school fantasy quest'",
    )
    submit_button = st.form_submit_button("✨ Find Recommendations", use_container_width=True)

# Process Search
if submit_button or user_query:
    if not user_query.strip():
        st.warning("Please enter a search query or select a preset idea above.")
    else:
        with st.spinner("Retrieving vector matches & generating grounded explanations..."):
            payload = {
                "query": user_query.strip(),
                "genre": selected_genre if selected_genre != "All" else None,
                "item_type": selected_type if selected_type != "All" else None,
                "top_k": 3
            }
            
            try:
                response = requests.post(f"{BACKEND_URL}/recommend", json=payload, timeout=10)
                
                if response.status_code == 200:
                    data = response.json()
                    recommendations = data.get("recommendations", [])
                    is_cached = data.get("cached", False)
                    
                    # Status info bar
                    cache_badge = "⚡ Served from In-Memory Cache" if is_cached else "✨ Fresh Retrieval & AI Explanation"
                    st.markdown(f"**Found {len(recommendations)} recommendations** &nbsp;&nbsp;|&nbsp;&nbsp; `<span class='badge-cache'>{cache_badge}</span>`", unsafe_allow_html=True)
                    st.markdown("<br>", unsafe_allow_html=True)
                    
                    if not recommendations:
                        st.info("No matching items found for your criteria. Try adjusting the genre or media type filter.")
                    else:
                        for rec in recommendations:
                            type_badge_class = "badge-movie" if rec["item_type"] == "Movie" else "badge-book"
                            type_icon = "🎬" if rec["item_type"] == "Movie" else "📚"
                            sim_percent = int(rec["similarity_score"] * 100)
                            
                            st.markdown(f"""
                            <div class="rec-card">
                                <div>
                                    <span class="badge-score">🎯 {sim_percent}% Match</span>
                                    <span class="card-title">{rec['title']}</span> ({rec['year']})
                                </div>
                                <div style="margin-top: 0.5rem; margin-bottom: 0.5rem;">
                                    <span class="{type_badge_class}">{type_icon} {rec['item_type']}</span> &nbsp;
                                    <span style="color: #94a3b8; font-size: 0.9rem;">Genre: <strong>{rec['genre']}</strong> &nbsp;|&nbsp; Creator: <strong>{rec['creator']}</strong> &nbsp;|&nbsp; Rating: <strong>⭐ {rec['rating']}/10</strong></span>
                                </div>
                                <div class="synopsis-box">
                                    <strong>Plot Synopsis:</strong> {rec['synopsis']}
                                </div>
                                <div class="ai-explanation-box">
                                    <strong>💡 Why Recommended:</strong> {rec['ai_explanation']}
                                </div>
                            </div>
                            """, unsafe_allow_html=True)

                else:
                    st.error(f"Backend API returned error ({response.status_code}): {response.text}")
                    
            except requests.exceptions.ConnectionError:
                st.error("❌ Could not connect to FastAPI Backend server. Make sure `uvicorn backend.app.main:app` is running on http://127.0.0.1:8000!")
            except Exception as e:
                st.error(f"An error occurred: {str(e)}")
