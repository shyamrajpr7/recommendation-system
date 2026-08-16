# Movie & Book Recommendation System

A full-stack recommendation web app that retrieves items with vector similarity search and explains each recommendation with a grounded LLM rationale.

## Architecture

```
┌──────────────┐   HTTP    ┌───────────────────────────────────────────┐
│  Streamlit   │ ────────► │  FastAPI /recommend                       │
│  Frontend    │ ◄──────── │  1. Validate input                        │
└──────────────┘   JSON    │  2. Check in-memory cache (normalized key)│
                           │  3. Embed query (sentence-transformers)   │
                           │  4. FAISS cosine similarity (top 3)       │
                           │  5. Metadata lookup (SQLite)              │
                           │  6. Build context prompt                  │
                           │  7. LLM explanation (JSON, grounded)      │
                           │  8. Validate + cache + respond            │
                           └───────────────────────────────────────────┘
```

- **Frontend**: Streamlit (`frontend/app.py`)
- **Backend**: FastAPI (`backend/app/main.py`)
- **Retrieval**: `sentence-transformers` (`all-MiniLM-L6-v2`) + FAISS inner-product index
- **Metadata**: SQLite with 32 seeded movies/books
- **LLM**: Google Gemini 2.5 Flash (structured JSON output)
- **Cache**: in-memory dict keyed on normalized query + filters

Retrieval and generation are strictly separated: the LLM only explains the
items the retriever hands it; it never invents recommendations.

## Setup

```bash
pip install -r requirements.txt
export GEMINI_API_KEY="your-key"   # optional; falls back to template explanations
uvicorn backend.app.main:app --reload --port 8000   # backend
streamlit run frontend/app.py                       # frontend
```

Open http://localhost:8501 in the browser.

## Endpoints

- `GET /health` — liveness check
- `GET /genres` — list known genres for the filter dropdown
- `POST /recommend` — body: `{"query": "...", "genre": "Sci-Fi", "item_type": "Movie", "top_k": 3}`

## Project layout

```
backend/app/
  main.py          # FastAPI app + /recommend pipeline orchestration
  schemas.py       # Pydantic request/response models
  database.py      # SQLite init, seed data, metadata queries
  vector_store.py  # embedding model + FAISS index build/search
  llm_explainer.py # grounded LLM explanation (Gemini + fallback)
  cache.py         # in-memory cache keyed on normalized query
data/              # generated SQLite DB lives here
frontend/app.py    # Streamlit UI
```
