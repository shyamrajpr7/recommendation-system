import sqlite3
import os
from typing import List, Dict, Any, Optional

from data.seed_data import SEED_ITEMS

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data", "recommendations.db")

def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
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
    count = cursor.fetchone()[0]
    
    if count == 0:
        for item in SEED_ITEMS:
            cursor.execute("""
            INSERT INTO movies_books (title, item_type, genre, rating, synopsis, creator, year)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (item["title"], item["item_type"], item["genre"], item["rating"], item["synopsis"], item["creator"], item["year"]))
        conn.commit()
    conn.close()

def get_all_items() -> List[Dict[str, Any]]:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM movies_books;")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

def get_items_by_ids(ids: List[int]) -> Dict[int, Dict[str, Any]]:
    if not ids:
        return {}
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    placeholders = ",".join(["?"] * len(ids))
    cursor.execute(f"SELECT * FROM movies_books WHERE id IN ({placeholders});", ids)
    rows = cursor.fetchall()
    conn.close()
    return {row["id"]: dict(row) for row in rows}

def get_genres() -> List[str]:
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT DISTINCT genre FROM movies_books ORDER BY genre ASC;")
    genres = [row[0] for row in cursor.fetchall()]
    conn.close()
    return genres

if __name__ == "__main__":
    init_db()
    items = get_all_items()
    print(f"Database initialized with {len(items)} items.")
