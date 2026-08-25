"""In-memory LRU cache for recommendation query results."""

import hashlib
from collections import OrderedDict
from typing import Any, Dict, Optional

class RecommendationCache:
    """In-memory LRU cache for recommendation query results.

    Stores both retrieval results and LLM-generated explanations keyed on
    the SHA-256 hash of the normalised query string combined with genre and
    item-type filters.  Bounded by ``max_entries`` (default 256); the
    least-recently-used entry is evicted when the cache is full.
    """
    MAX_ENTRIES = 256

    def __init__(self, max_entries: int = MAX_ENTRIES):
        self._cache: "OrderedDict[str, Dict[str, Any]]" = OrderedDict()
        self._max_entries = max_entries

    def _make_key(self, query: str, genre: Optional[str] = None, item_type: Optional[str] = None) -> str:
        norm_query = query.strip().lower()
        norm_genre = (genre or "all").strip().lower()
        norm_type = (item_type or "all").strip().lower()
        raw_key = f"{norm_query}|{norm_genre}|{norm_type}"
        return hashlib.sha256(raw_key.encode("utf-8")).hexdigest()

    def get(self, query: str, genre: Optional[str] = None, item_type: Optional[str] = None) -> Optional[Dict[str, Any]]:
        key = self._make_key(query, genre, item_type)
        if key not in self._cache:
            return None
        self._cache.move_to_end(key)
        return self._cache[key]

    def set(self, query: str, data: Dict[str, Any], genre: Optional[str] = None, item_type: Optional[str] = None):
        key = self._make_key(query, genre, item_type)
        if key in self._cache:
            self._cache.move_to_end(key)
        elif len(self._cache) >= self._max_entries:
            self._cache.popitem(last=False)
        self._cache[key] = data

    def clear(self):
        self._cache.clear()

    def __len__(self) -> int:
        return len(self._cache)

    def info(self) -> Dict[str, Any]:
        """Return cache statistics for monitoring."""
        return {
            "size": len(self._cache),
            "max_entries": self._max_entries,
            "utilization": round(len(self._cache) / self._max_entries, 2),
        }

# Global cache instance
cache_instance = RecommendationCache()
