"""CineRead Cinema API — FastAPI app with recommendation, cinema, and chat endpoints."""

import json
import hashlib
import os
import time
from fastapi import FastAPI, HTTPException, Query, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from typing import List, Optional
from pydantic import BaseModel

from dotenv import load_dotenv

load_dotenv()

from backend.app.database import (
    init_db,
    get_items_by_ids,
    get_genres,
    get_movies,
    get_movie,
    get_theaters,
    get_showtimes,
    get_showtime,
    get_seat_map,
    create_booking,
    get_booking,
    update_booking_payment,
    set_booking_payment_link,
    get_upcoming_dates,
)
from backend.app.vector_store import VectorStore
from backend.app.cache import cache_instance
from backend.app.llm_explainer import generate_explanations
from backend.app.chat import chat_reply
from backend.app.payment import create_payment_link, fetch_payment_link_status, payment_enabled
from backend.app.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    ItemRecommendation,
    GenresResponse,
    MovieListResponse,
    Movie,
    TheaterListResponse,
    Theater,
    ShowtimeListResponse,
    Showtime,
    SeatMapResponse,
    BookingRequest,
    BookingResponse,
    BookingVerifyRequest,
    BookingVerifyResponse,
    ChatRequest,
    ChatResponse,
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("[Startup] Initializing SQLite Metadata Database...")
    init_db()
    print("[Startup] Loading Vector Store & Indexing Items...")
    VectorStore.get_instance()
    print(f"[Startup] Razorpay payment: {'enabled' if payment_enabled() else 'mock fallback (set RAZORPAY_KEY_ID/SECRET)'}")
    print("[Startup] Cinema Booking Backend Ready!")
    yield

app = FastAPI(
    title="CineRead Cinema API",
    description="Movie ticketing + vector search + grounded AI explanations (Groq/xAI)",
    version="2.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "CineRead Cinema API", "version": "2.0.0"}


@app.get("/genres", response_model=GenresResponse)
def list_genres():
    return GenresResponse(genres=get_genres())


@app.post("/recommend", response_model=RecommendationResponse)
def get_recommendations(payload: RecommendationRequest):
    query = payload.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Search query cannot be empty.")

    genre = payload.genre.strip() if payload.genre and payload.genre.strip() else None
    item_type = payload.item_type.strip() if payload.item_type and payload.item_type.strip() else None

    known_genres = {g.lower(): g for g in get_genres()}
    if genre and genre.lower() != "all" and genre.lower() not in known_genres:
        raise HTTPException(status_code=400, detail=f"Unknown genre '{genre}'. Known genres: {', '.join(sorted(known_genres.values()))}.")

    if item_type and item_type.lower() not in ("all", "movie", "book"):
        raise HTTPException(status_code=400, detail="item_type must be one of: Movie, Book, All.")

    cached_data = cache_instance.get(query, genre, item_type)
    if cached_data:
        response = dict(cached_data)
        response["cached"] = True
        return response

    vector_store = VectorStore.get_instance()
    search_results = vector_store.search(
        query=query,
        top_k=payload.top_k,
        genre_filter=genre,
        item_type_filter=item_type
    )

    if not search_results:
        return {
            "query": query,
            "genre_filter": genre,
            "item_type_filter": item_type,
            "cached": False,
            "total_results": 0,
            "recommendations": []
        }

    candidate_ids = [item_id for item_id, _ in search_results]
    score_by_id = {item_id: score for item_id, score in search_results}
    items_dict = get_items_by_ids(candidate_ids)

    candidates = []
    for item_id in candidate_ids:
        item = items_dict.get(item_id)
        if item:
            item_copy = dict(item)
            item_copy["similarity_score"] = score_by_id.get(item_id, 0.0)
            candidates.append(item_copy)

    candidates_with_explanations = generate_explanations(query, candidates)

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
    cache_instance.set(query, response_dict, genre, item_type)
    return response_dict


# --------------------------------------------------------------------------
# Cinema endpoints
# --------------------------------------------------------------------------

@app.get("/movies", response_model=MovieListResponse)
def list_movies(genre: Optional[str] = None):
    movies = get_movies(genre=(genre or "").strip() or None)
    return MovieListResponse(movies=[Movie(**m) for m in movies])


@app.get("/movies/{movie_id}", response_model=Movie)
def movie_detail(movie_id: int):
    movie = get_movie(movie_id)
    if not movie or movie["item_type"] != "Movie":
        raise HTTPException(status_code=404, detail="Movie not found")
    return Movie(**movie)


@app.get("/theaters", response_model=TheaterListResponse)
def list_theaters():
    theaters = get_theaters()
    return TheaterListResponse(theaters=[Theater(**t) for t in theaters])


@app.get("/dates")
def list_dates():
    return {"dates": get_upcoming_dates()}


@app.get("/stats")
def catalog_stats():
    movies = get_movies()
    showtimes = get_showtimes()
    return {
        "movies": len(movies),
        "showtimes": len(showtimes),
        "theaters": len(get_theaters()),
        "show_dates": len(get_upcoming_dates()),
    }


@app.get("/showtimes", response_model=ShowtimeListResponse)
def list_showtimes(movie_id: Optional[int] = None, show_date: Optional[str] = None):
    showtimes = get_showtimes(movie_id=movie_id, show_date=show_date)
    return ShowtimeListResponse(showtimes=[Showtime(**s) for s in showtimes])


@app.get("/seats", response_model=SeatMapResponse)
def seats_for_showtime(showtime_id: int = Query(...)):
    seat_map = get_seat_map(showtime_id)
    if not seat_map:
        raise HTTPException(status_code=404, detail="Showtime not found")
    return SeatMapResponse(**seat_map)


@app.post("/bookings", response_model=BookingResponse)
def make_booking(payload: BookingRequest):
    showtime = get_showtime(payload.showtime_id)
    if not showtime:
        raise HTTPException(status_code=404, detail="Showtime not found")

    if len(set(payload.seats)) != len(payload.seats):
        raise HTTPException(status_code=400, detail="Duplicate seats in request: " + ", ".join(sorted(set(s for s in payload.seats if payload.seats.count(s) > 1))))

    seat_map = get_seat_map(payload.showtime_id)
    available = {
        s["seat"]
        for row in seat_map["seats"] for s in row
        if s["status"] == "available"
    }
    invalid = [seat for seat in payload.seats if seat not in available]
    if invalid:
        raise HTTPException(status_code=409, detail=f"Seat(s) no longer available: {', '.join(invalid)}")

    try:
        booking = create_booking(
            showtime_id=payload.showtime_id,
            customer_name=payload.customer_name.strip(),
            customer_email=payload.customer_email.strip(),
            seats=sorted(payload.seats),
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    amount = booking["total_amount"]
    description = f"CineRead booking {booking['booking_ref']}: {showtime['movie_title']} {showtime['show_date']} {showtime['show_time']}"
    link = create_payment_link(
        amount_inr=amount,
        description=description,
        customer_name=booking["customer_name"],
        customer_email=booking["customer_email"],
        booking_ref=booking["booking_ref"],
    )

    if link.get("payment_link_id"):
        set_booking_payment_link(booking["booking_ref"], link["payment_link_id"])

    return BookingResponse(
        booking_ref=booking["booking_ref"],
        showtime_id=showtime["id"],
        movie_title=showtime["movie_title"],
        movie_genre=showtime["genre"],
        show_date=showtime["show_date"],
        show_time=showtime["show_time"],
        theater_name=showtime["theater_name"],
        screen_name=showtime["screen_name"],
        city=showtime["city"],
        seats=json.loads(booking["seats"]),
        total_amount=amount,
        status=booking["status"],
        payment_status=booking["payment_status"],
        payment_link_id=link.get("payment_link_id"),
        payment_url=link.get("short_url"),
        payment_mock=link.get("mock", False),
        payment_enabled=payment_enabled(),
    )


@app.get("/bookings/{booking_ref}", response_model=BookingResponse)
def booking_status(booking_ref: str):
    booking = get_booking(booking_ref)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return BookingResponse(
        booking_ref=booking["booking_ref"],
        showtime_id=booking["showtime_id"],
        movie_title=booking["movie_title"],
        movie_genre=booking["movie_genre"],
        show_date=booking["show_date"],
        show_time=booking["show_time"],
        theater_name=booking["theater_name"],
        screen_name=booking["screen_name"],
        city=booking["city"],
        seats=json.loads(booking["seats"]),
        total_amount=booking["total_amount"],
        status=booking["status"],
        payment_status=booking["payment_status"],
        payment_link_id=booking["payment_link_id"],
        payment_url=None,
        payment_mock=not payment_enabled(),
        payment_enabled=payment_enabled(),
    )


@app.post("/bookings/{booking_ref}/verify", response_model=BookingVerifyResponse)
def verify_booking(booking_ref: str):
    booking = get_booking(booking_ref)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    link_id = booking.get("payment_link_id")
    if not link_id:
        raise HTTPException(status_code=400, detail="Booking has no payment link yet")

    try:
        result = fetch_payment_link_status(link_id)
        payment_status = result.get("status", "unknown")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Payment gateway error: {e}")

    if payment_status == "paid":
        update_booking_payment(
            booking["booking_ref"], "paid", "confirmed",
            payment_id=result.get("payment_id"))
        return BookingVerifyResponse(
            booking_ref=booking["booking_ref"],
            status="confirmed",
            payment_status="paid",
            payment_id=result.get("payment_id"),
        )

    # Payment not yet completed — keep booking pending but allow retry
    update_booking_payment(booking["booking_ref"], payment_status, "pending")
    return BookingVerifyResponse(
        booking_ref=booking["booking_ref"],
        status="pending",
        payment_status=payment_status,
    )


# --------------------------------------------------------------------------
# Auth (simple JWT-based)
# --------------------------------------------------------------------------

_SECRET = os.environ.get("AUTH_SECRET", "cineread-dev-secret-key-change-in-production")
_users: dict[str, dict] = {}  # email -> {name, email, password_hash}


class SignupRequest(BaseModel):
    name: str
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    name: str
    email: str


def _hash_pw(pw: str) -> str:
    return hashlib.sha256(pw.encode()).hexdigest()


def _make_token(email: str) -> str:
    payload = f"{email}:{int(time.time())}"
    sig = hashlib.sha256(f"{payload}:{_SECRET}".encode()).hexdigest()[:16]
    return f"{payload}:{sig}"


def _verify_token(token: str) -> Optional[str]:
    try:
        parts = token.rsplit(":", 1)
        if len(parts) != 2:
            return None
        payload, sig = parts
        expected = hashlib.sha256(f"{payload}:{_SECRET}".encode()).hexdigest()[:16]
        if sig != expected:
            return None
        email = payload.rsplit(":", 1)[0]
        return email
    except Exception:
        return None


def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    email = _verify_token(authorization.removeprefix("Bearer ").strip())
    if not email or email not in _users:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return email


@app.post("/auth/signup", response_model=AuthResponse)
def signup(payload: SignupRequest):
    email = payload.email.strip().lower()
    if email in _users:
        raise HTTPException(status_code=400, detail="Email already registered")
    _users[email] = {
        "name": payload.name.strip(),
        "email": email,
        "password_hash": _hash_pw(payload.password),
    }
    token = _make_token(email)
    return AuthResponse(access_token=token, name=_users[email]["name"], email=email)


@app.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest):
    email = payload.email.strip().lower()
    user = _users.get(email)
    if not user or user["password_hash"] != _hash_pw(payload.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    token = _make_token(email)
    return AuthResponse(access_token=token, name=user["name"], email=email)


@app.get("/auth/me")
def get_me(email: str = Depends(get_current_user)):
    user = _users[email]
    return {"name": user["name"], "email": user["email"]}


# --------------------------------------------------------------------------
# Chat
# --------------------------------------------------------------------------

@app.post("/chat", response_model=ChatResponse)
def chat(payload: ChatRequest):
    return ChatResponse(**chat_reply(payload.message, payload.history))
