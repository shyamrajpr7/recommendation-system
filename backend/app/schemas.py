from pydantic import BaseModel, Field
from typing import List, Optional

class RecommendationRequest(BaseModel):
    query: str = Field(..., min_length=1, description="Movie/book title or preference description")
    genre: Optional[str] = Field(None, description="Optional genre filter")
    item_type: Optional[str] = Field(None, description="Optional item type filter: Movie, Book, or All")
    top_k: int = Field(3, ge=1, le=10, description="Number of recommendations to return")

class ItemRecommendation(BaseModel):
    id: int
    title: str
    item_type: str
    genre: str
    rating: float
    synopsis: str
    creator: str
    year: int
    similarity_score: float
    ai_explanation: str

class RecommendationResponse(BaseModel):
    query: str
    genre_filter: Optional[str] = None
    item_type_filter: Optional[str] = None
    cached: bool = False
    total_results: int
    recommendations: List[ItemRecommendation]

class GenresResponse(BaseModel):
    genres: List[str]
