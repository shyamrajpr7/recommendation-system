import sqlite3
import os
import json
import random
import string
from datetime import date, timedelta, datetime
from typing import List, Dict, Any, Optional

from data.seed_data import (
    SEED_ITEMS,
    THEATERS,
    SCREENS,
    SHOW_TIMES,
    SHOWTIME_DAYS_AHEAD,
    NOW_SHOWING,
)

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data", "recommendations.db")

def _get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = _get_conn()
    cursor = conn.cursor()

    # ---- Catalog (movies & books) ----
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS movies_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        item_type TEXT NOT NULL,
        genre TEXT NOT NULL,
        rating REAL NOT NULL,
        synopsis TEXT NOT NULL,
        creator TEXT NOT NULL,
        year INTEGER NOT NULL
    );
    """)

    cursor.execute("SELECT COUNT(*) FROM movies_books;")
    if cursor.fetchone()[0] == 0:
        for item in SEED_ITEMS:
            cursor.execute("""
            INSERT INTO movies_books (title, item_type, genre, rating, synopsis, creator, year)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (item["title"], item["item_type"], item["genre"], item["rating"], item["synopsis"], item["creator"], item["year"]))
        conn.commit()

    # ---- Theaters ----
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS theaters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        city TEXT NOT NULL
    );
    """)

    # ---- Screens (auditoriums inside a theater) ----
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS screens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        theater_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        rows INTEGER NOT NULL,
        cols INTEGER NOT NULL,
        base_price REAL NOT NULL,
        FOREIGN KEY (theater_id) REFERENCES theaters(id)
    );
    """)

    # ---- Showtimes ----
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS showtimes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movie_id INTEGER NOT NULL,
        screen_id INTEGER NOT NULL,
        show_date TEXT NOT NULL,
        show_time TEXT NOT NULL,
        base_price REAL NOT NULL,
        blocked_seats TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (movie_id) REFERENCES movies_books(id),
        FOREIGN KEY (screen_id) REFERENCES screens(id)
    );
    """)

    # ---- Bookings ----
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_ref TEXT NOT NULL UNIQUE,
        showtime_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        customer_email TEXT NOT NULL,
        seats TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_id TEXT,
        payment_link_id TEXT,
        payment_status TEXT NOT NULL DEFAULT 'pending',
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (showtime_id) REFERENCES showtimes(id)
    );
    """)

    conn.commit()
    conn.close()

    seed_cinema()


def seed_cinema():
    """Seeds theaters/screens once and regenerates fresh showtimes on every
    startup so the demo always has upcoming showings."""
    conn = _get_conn()
    cursor = conn.cursor()

    # Theaters + screens (idempotent)
    if cursor.execute("SELECT COUNT(*) FROM theaters").fetchone()[0] == 0:
        theater_ids = {}
        for theater in THEATERS:
            cursor.execute("INSERT INTO theaters (name, city) VALUES (?, ?)",
                           (theater["name"], theater["city"]))
            theater_ids[theater["name"]] = cursor.lastrowid
        for theater_name, screen_name, rows, cols, price in SCREENS:
            cursor.execute(
                "INSERT INTO screens (theater_id, name, rows, cols, base_price) VALUES (?, ?, ?, ?, ?)",
                (theater_ids[theater_name], screen_name, rows, cols, price))

    # Always rebuild showtimes + bookings so dates stay in the future
    cursor.execute("DELETE FROM bookings")
    cursor.execute("DELETE FROM showtimes")

    movie_rows = cursor.execute(
        "SELECT id, title FROM movies_books WHERE item_type = 'Movie' AND title IN (%s)"
        % ",".join("?" * len(NOW_SHOWING)), NOW_SHOWING).fetchall()
    movie_ids = [row["id"] for row in movie_rows]

    screen_rows = cursor.execute("SELECT id, rows, cols, base_price FROM screens").fetchall()
    screen_ids = [row["id"] for row in screen_rows]

    random.seed(20260711)  # deterministic blockouts for a stable demo
    for movie_idx, movie_id in enumerate(movie_ids):
        for day_offset in range(SHOWTIME_DAYS_AHEAD):
            show_date = (date.today() + timedelta(days=day_offset)).isoformat()
            screen = screen_rows[(movie_idx + day_offset) % len(screen_ids)]
            show_time = SHOW_TIMES[(movie_idx + day_offset) % len(SHOW_TIMES)]
            price = screen["base_price"]

            blocked = _pick_blocked_seats(screen["rows"], screen["cols"])

            cursor.execute(
                "INSERT INTO showtimes (movie_id, screen_id, show_date, show_time, base_price, blocked_seats) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (movie_id, screen["id"], show_date, show_time, price, json.dumps(blocked)))

    conn.commit()
    conn.close()


def _pick_blocked_seats(rows: int, cols: int, count: int = 4) -> List[str]:
    letters = string.ascii_uppercase[:rows]
    candidates = [f"{letter}{col}" for letter in letters for col in range(1, cols + 1)]
    return random.sample(candidates, min(count, len(candidates)))


# --------------------------------------------------------------------------
# Catalog helpers (recommendation pipeline)
# --------------------------------------------------------------------------

def get_all_items() -> List[Dict[str, Any]]:
    conn = _get_conn()
    rows = conn.execute("SELECT * FROM movies_books;").fetchall()
    conn.close()
    return [dict(row) for row in rows]


def get_items_by_ids(ids: List[int]) -> Dict[int, Dict[str, Any]]:
    if not ids:
        return {}
    conn = _get_conn()
    placeholders = ",".join(["?"] * len(ids))
    rows = conn.execute(f"SELECT * FROM movies_books WHERE id IN ({placeholders});", ids).fetchall()
    conn.close()
    return {row["id"]: dict(row) for row in rows}


def get_genres() -> List[str]:
    conn = _get_conn()
    genres = [row[0] for row in conn.execute("SELECT DISTINCT genre FROM movies_books ORDER BY genre ASC;")]
    conn.close()
    return genres


# --------------------------------------------------------------------------
# Cinema helpers
# --------------------------------------------------------------------------

def get_movies() -> List[Dict[str, Any]]:
    conn = _get_conn()
    rows = conn.execute("SELECT * FROM movies_books WHERE item_type = 'Movie' ORDER BY title;").fetchall()
    conn.close()
    return [dict(row) for row in rows]


def get_movie(movie_id: int) -> Optional[Dict[str, Any]]:
    conn = _get_conn()
    row = conn.execute("SELECT * FROM movies_books WHERE id = ?;", (movie_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def get_theaters() -> List[Dict[str, Any]]:
    conn = _get_conn()
    rows = conn.execute("SELECT * FROM theaters ORDER BY name;").fetchall()
    conn.close()
    return [dict(row) for row in rows]


def get_showtimes(movie_id: Optional[int] = None, show_date: Optional[str] = None) -> List[Dict[str, Any]]:
    conn = _get_conn()
    query = """
        SELECT s.id, s.show_date, s.show_time, s.base_price,
               s.movie_id, m.title AS movie_title, m.genre AS movie_genre,
               s.screen_id, sc.name AS screen_name, sc.rows AS screen_rows, sc.cols AS screen_cols,
               t.id AS theater_id, t.name AS theater_name, t.city
        FROM showtimes s
        JOIN movies_books m ON m.id = s.movie_id
        JOIN screens sc ON sc.id = s.screen_id
        JOIN theaters t ON t.id = sc.theater_id
    """
    conditions, params = [], []
    if movie_id is not None:
        conditions.append("s.movie_id = ?")
        params.append(movie_id)
    if show_date:
        conditions.append("s.show_date = ?")
        params.append(show_date)
    if conditions:
        query += " WHERE " + " AND ".join(conditions)
    query += " ORDER BY s.show_date, s.show_time"
    rows = conn.execute(query, params).fetchall()
    conn.close()
    return [dict(row) for row in rows]


def get_showtime(showtime_id: int) -> Optional[Dict[str, Any]]:
    conn = _get_conn()
    row = conn.execute("""
        SELECT s.id, s.show_date, s.show_time, s.base_price, s.blocked_seats,
               s.movie_id, m.title AS movie_title, m.item_type, m.genre, m.rating,
               m.synopsis, m.creator, m.year,
               s.screen_id, sc.name AS screen_name, sc.rows AS screen_rows, sc.cols AS screen_cols,
               t.id AS theater_id, t.name AS theater_name, t.city
        FROM showtimes s
        JOIN movies_books m ON m.id = s.movie_id
        JOIN screens sc ON sc.id = s.screen_id
        JOIN theaters t ON t.id = sc.theater_id
        WHERE s.id = ?
    """, (showtime_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def get_booked_seats(showtime_id: int) -> List[str]:
    conn = _get_conn()
    rows = conn.execute(
        "SELECT seats FROM bookings WHERE showtime_id = ? AND status IN ('pending', 'confirmed')",
        (showtime_id,)).fetchall()
    conn.close()
    booked = []
    for row in rows:
        booked.extend(json.loads(row["seats"]))
    return booked


def get_seat_map(showtime_id: int) -> Optional[Dict[str, Any]]:
    showtime = get_showtime(showtime_id)
    if not showtime:
        return None
    rows, cols = showtime["screen_rows"], showtime["screen_cols"]
    blocked = set(json.loads(showtime["blocked_seats"]))
    occupied = set(get_booked_seats(showtime_id))

    seats = []
    for row_idx in range(rows):
        letter = string.ascii_uppercase[row_idx]
        seat_row = []
        for col in range(1, cols + 1):
            seat = f"{letter}{col}"
            seat_row.append({
                "seat": seat,
                "status": "blocked" if seat in blocked else ("occupied" if seat in occupied else "available"),
            })
        seats.append(seat_row)
    return {
        "showtime_id": showtime_id,
        "rows": rows,
        "cols": cols,
        "seats": seats,
        "occupied_count": len(blocked | occupied),
    }


def create_booking(showtime_id: int, customer_name: str, customer_email: str,
                   seats: List[str], payment_id: Optional[str] = None,
                   payment_link_id: Optional[str] = None) -> Dict[str, Any]:
    conn = _get_conn()
    cursor = conn.cursor()
    showtime = conn.execute("SELECT * FROM showtimes WHERE id = ?;", (showtime_id,)).fetchone()
    if not showtime:
        conn.close()
        raise ValueError("Showtime not found")
    total = showtime["base_price"] * len(seats)
    booking_ref = _new_booking_ref(conn)
    now = datetime.utcnow().isoformat(timespec="seconds")
    cursor.execute("""
        INSERT INTO bookings (booking_ref, showtime_id, customer_name, customer_email,
                              seats, total_amount, payment_id, payment_link_id, payment_status, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending', ?)
    """, (booking_ref, showtime_id, customer_name, customer_email,
          json.dumps(seats), total, payment_id, payment_link_id, now))
    conn.commit()
    booking = dict(conn.execute("SELECT * FROM bookings WHERE booking_ref = ?;", (booking_ref,)).fetchone())
    conn.close()
    return booking


def _new_booking_ref(conn) -> str:
    import hashlib
    while True:
        ref = "CINE" + ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        if not conn.execute("SELECT 1 FROM bookings WHERE booking_ref = ?;", (ref,)).fetchone():
            return ref


def get_booking(booking_ref: str) -> Optional[Dict[str, Any]]:
    conn = _get_conn()
    row = conn.execute("""
        SELECT b.*, s.show_date, s.show_time, s.base_price,
               m.title AS movie_title, m.genre AS movie_genre,
               sc.name AS screen_name, t.name AS theater_name, t.city
        FROM bookings b
        JOIN showtimes s ON s.id = b.showtime_id
        JOIN movies_books m ON m.id = s.movie_id
        JOIN screens sc ON sc.id = s.screen_id
        JOIN theaters t ON t.id = sc.theater_id
        WHERE b.booking_ref = ?
    """, (booking_ref,)).fetchone()
    conn.close()
    return dict(row) if row else None


def update_booking_payment(booking_ref: str, payment_status: str, status: str,
                           payment_id: Optional[str] = None):
    conn = _get_conn()
    conn.execute(
        "UPDATE bookings SET payment_status = ?, status = ?, payment_id = COALESCE(?, payment_id) WHERE booking_ref = ?",
        (payment_status, status, payment_id, booking_ref))
    conn.commit()
    conn.close()


def set_booking_payment_link(booking_ref: str, payment_link_id: str):
    conn = _get_conn()
    conn.execute("UPDATE bookings SET payment_link_id = ? WHERE booking_ref = ?",
                 (payment_link_id, booking_ref))
    conn.commit()
    conn.close()


def get_upcoming_dates() -> List[str]:
    return [(date.today() + timedelta(days=d)).isoformat() for d in range(SHOWTIME_DAYS_AHEAD)]


if __name__ == "__main__":
    init_db()
    print("Cinema DB seeded.")
