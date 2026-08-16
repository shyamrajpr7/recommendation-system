from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import List, Optional

from backend.app.database import init_db, get_items_by_ids, get_genres
from backend.app.vector_store import VectorStore
from backend.app.cache import cache_instance
from backend.app.llm_explainer import generate_explanations
from backend.app.schemas import RecommendationRequest, RecommendationResponse, ItemRecommendation, GenresResponse

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize DB & FAISS Index on app startup
    print("[Startup] Initializing SQLite Metadata Database...")
    init_db()
    print("[Startup] Loading Vector Store & Indexing Items...")
    VectorStore.get_instance()
    print("[Startup] Recommendation Backend Ready!")
    yield

app = FastAPI(
    title="Movie & Book Recommendation API",
    description="Vector Similarity Search + Grounded LLM Explanation Service",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for Streamlit frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "Recommendation Backend API"}

@app.get("/genres", response_model=GenresResponse)
def list_genres():
    genres = get_genres()
    return GenresResponse(genres=genres)

@app.post("/recommend", response_model=RecommendationResponse)
def get_recommendations(payload: RecommendationRequest):
    query = payload.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Search query cannot be empty.")

    genre = payload.genre.strip() if payload.genre and payload.genre.strip() else None
    item_type = payload.item_type.strip() if payload.item_type and payload.item_type.strip() else None

    # Step 4: In-Memory Cache Check
    cached_data = cache_instance.get(query, genre, item_type)
    if cached_data:
        response = dict(cached_data)
        response["cached"] = True
        return response

    # Step 5: Vector Similarity Retrieval via FAISS
    vector_store = VectorStore.get_instance()
    search_results = vector_store.search(
        query=query,
        top_k=payload.top_k,
        genre_filter=genre,
        item_type_filter=item_type
    )

    if not search_results:
        response_payload = {
            "query": query,
            "genre_filter": genre,
            "item_type_filter": item_type,
            "cached": False,
            "total_results": 0,
            "recommendations": []
        }
        return response_payload

    # Step 6: Metadata Lookup from SQLite
    candidate_ids = [item_id for item_id, _ in search_results]
    score_by_id = {item_id: score for item_id, score in search_results}
    items_dict = get_items_by_ids(candidate_ids)

    # Assemble candidate metadata objects in FAISS similarity ranking order
    candidates = []
    for item_id in candidate_ids:
        item = items_dict.get(item_id)
        if item:
            item_copy = dict(item)
            item_copy["similarity_score"] = score_by_id.get(item_id, 0.0)
            candidates.append(item_copy)

    # Step 7 & 8: Context Building & LLM Explanation Call
    candidates_with_explanations = generate_explanations(query, candidates)

    # Step 9: Response formatting & Pydantic mapping
    recommendations = []
    for cand in candidates_with_explanations:
        recommendations.append(
            ItemRecommendation(
                id=cand["id"],
                title=cand["title"],
                item_type=cand["item_type"],
                genre=cand["genre"],
                rating=float(cand["rating"]),
                synopsis=cand["synopsis"],
                creator=cand["creator"],
                year=int(cand["year"]),
                similarity_score=round(float(cand["similarity_score"]), 4),
                ai_explanation=cand["ai_explanation"]
            )
        )

    response_dict = {
        "query": query,
        "genre_filter": genre,
        "item_type_filter": item_type,
        "cached": False,
        "total_results": len(recommendations),
        "recommendations": [rec.model_dump() for rec in recommendations]
    }

    # Store result in Cache before returning
    cache_instance.set(query, response_dict, genre, item_type)

    return response_dict
