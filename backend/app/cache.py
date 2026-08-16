import hashlib
from typing import Dict, Any, Optional, Tuple

class RecommendationCache:
    """
    In-memory dictionary cache keyed on normalized query and filter criteria.
    Stores both the retrieval results and the LLM-generated explanations.
    Bounded by MAX_ENTRIES; oldest entry evicted when full.
    """
    MAX_ENTRIES = 256

    def __init__(self, max_entries: int = MAX_ENTRIES):
        self._cache: Dict[str, Dict[str, Any]] = {}
        self._order: List[str] = []
        self._max_entries = max_entries

    def _make_key(self, query: str, genre: Optional[str] = None, item_type: Optional[str] = None) -> str:
        norm_query = query.strip().lower()
        norm_genre = (genre or "all").strip().lower()
        norm_type = (item_type or "all").strip().lower()
        raw_key = f"{norm_query}|{norm_genre}|{norm_type}"
        return hashlib.sha256(raw_key.encode("utf-8")).hexdigest()

    def get(self, query: str, genre: Optional[str] = None, item_type: Optional[str] = None) -> Optional[Dict[str, Any]]:
        key = self._make_key(query, genre, item_type)
        return self._cache.get(key)

    def set(self, query: str, data: Dict[str, Any], genre: Optional[str] = None, item_type: Optional[str] = None):
        key = self._make_key(query, genre, item_type)
        if key not in self._cache:
            self._order.append(key)
            if len(self._order) > self._max_entries:
                oldest = self._order.pop(0)
                self._cache.pop(oldest, None)
        self._cache[key] = data

    def clear(self):
        self._cache.clear()
        self._order.clear()

# Global cache instance
cache_instance = RecommendationCache()
