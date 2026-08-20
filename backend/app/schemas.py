"""Pydantic request/response models for the CineRead Cinema API."""

from pydantic import BaseModel, Field
from typing import List, Literal, Optional

# --------------------------------------------------------------------------
# Recommendation
# --------------------------------------------------------------------------

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

# --------------------------------------------------------------------------
# Cinema
# --------------------------------------------------------------------------

class Movie(BaseModel):
    id: int
    title: str
    genre: str
    rating: float
    synopsis: str
    creator: str
    year: int

class MovieListResponse(BaseModel):
    movies: List[Movie]

class Theater(BaseModel):
    id: int
    name: str
    city: str

class TheaterListResponse(BaseModel):
    theaters: List[Theater]

class Showtime(BaseModel):
    id: int
    movie_id: int
    movie_title: str
    movie_genre: str
    show_date: str
    show_time: str
    base_price: float
    screen_name: str
    theater_name: str
    city: str

class ShowtimeListResponse(BaseModel):
    showtimes: List[Showtime]

class Seat(BaseModel):
    seat: str
    status: Literal["available", "occupied", "blocked"]

class SeatMapResponse(BaseModel):
    showtime_id: int
    rows: int
    cols: int
    seats: List[List[Seat]]
    occupied_count: int

class BookingRequest(BaseModel):
    showtime_id: int
    customer_name: str = Field(..., min_length=2, max_length=120)
    customer_email: str = Field(..., min_length=5, max_length=200)
    seats: List[str] = Field(..., min_length=1, max_length=10)

class BookingResponse(BaseModel):
    booking_ref: str
    showtime_id: int
    movie_title: str
    movie_genre: str
    show_date: str
    show_time: str
    theater_name: str
    screen_name: str
    city: str
    seats: List[str]
    total_amount: float
    status: str
    payment_status: str
    payment_link_id: Optional[str] = None
    payment_url: Optional[str] = None
    payment_mock: bool = False
    payment_enabled: bool = False

class BookingVerifyRequest(BaseModel):
    booking_ref: str

class BookingVerifyResponse(BaseModel):
    booking_ref: str
    status: str
    payment_status: str
    payment_id: Optional[str] = None

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    history: List[dict] = Field(default_factory=list, description="Prior messages [{role, content}]")

class ChatResponse(BaseModel):
    reply: str
    used_ai: bool
