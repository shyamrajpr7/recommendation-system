import hashlib
from typing import Dict, Any, Optional, Tuple

class RecommendationCache:
    """
    In-memory dictionary cache keyed on normalized query and filter criteria.
    Stores both the retrieval results and the LLM-generated explanations.
    """
    def __init__(self):
        self._cache: Dict[str, Dict[str, Any]] = {}

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
        self._cache[key] = data

    def clear(self):
        self._cache.clear()

# Global cache instance
cache_instance = RecommendationCache()
