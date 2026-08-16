import os
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer
from typing import List, Tuple, Dict, Any, Optional
from backend.app.database import get_all_items

MODEL_NAME = "all-MiniLM-L6-v2"

class VectorStore:
    _instance = None

    def __init__(self):
        print(f"Loading embedding model '{MODEL_NAME}'...")
        self.model = SentenceTransformer(MODEL_NAME)
        self.index = None
        self.item_ids = []  # Index row -> DB item ID mapping
        self.items_by_id = {}
        self.build_index()

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def build_index(self):
        items = get_all_items()
        if not items:
            raise ValueError("No items found in metadata database to index.")

        print(f"Building FAISS index for {len(items)} items...")
        self.item_ids = []
        self.items_by_id = {}
        texts = []

        for item in items:
            item_id = item["id"]
            self.item_ids.append(item_id)
            self.items_by_id[item_id] = item
            
            # Rich combined text representation
            text = f"{item['title']} ({item['item_type']}, {item['year']}, {item['genre']}) by {item['creator']}. {item['synopsis']}"
            texts.append(text)

        embeddings = self.model.encode(texts, show_progress_bar=False, convert_to_numpy=True)
        embeddings = embeddings.astype(np.float32)
        
        # Normalize vectors for Cosine Similarity using Inner Product
        faiss.normalize_L2(embeddings)
        
        dimension = embeddings.shape[1]
        self.index = faiss.IndexFlatIP(dimension)
        self.index.add(embeddings)
        print(f"FAISS index built successfully with {self.index.ntotal} vectors.")

    def search(
        self,
        query: str,
        top_k: int = 3,
        genre_filter: Optional[str] = None,
        item_type_filter: Optional[str] = None
    ) -> List[Tuple[int, float]]:
        """
        Runs cosine similarity search on the query vector.
        Returns a list of (item_id, similarity_score) tuples.
        """
        if not self.index or self.index.ntotal == 0:
            return []

        # Encode and normalize query
        query_emb = self.model.encode([query], show_progress_bar=False, convert_to_numpy=True).astype(np.float32)
        faiss.normalize_L2(query_emb)

        # Retrieve a larger pool (e.g. 20) to handle genre/type filtering
        fetch_k = min(self.index.ntotal, max(top_k * 5, 20))
        distances, indices = self.index.search(query_emb, fetch_k)

        results = []
        for idx, score in zip(indices[0], distances[0]):
            if idx == -1:
                continue
            item_id = self.item_ids[idx]
            item = self.items_by_id.get(item_id)

            if not item:
                continue

            # Apply genre filter if provided
            if genre_filter and genre_filter.strip() and genre_filter.lower() != "all":
                if item["genre"].lower() != genre_filter.strip().lower():
                    continue

            # Apply item_type filter if provided
            if item_type_filter and item_type_filter.strip() and item_type_filter.lower() != "all":
                if item["item_type"].lower() != item_type_filter.strip().lower():
                    continue

            # Similarity score bounded between 0.0 and 1.0
            similarity = float(max(0.0, min(1.0, float(score))))
            results.append((item_id, similarity))

            if len(results) >= top_k:
                break

        return results

if __name__ == "__main__":
    from backend.app.database import init_db
    init_db()
    store = VectorStore.get_instance()
    res = store.search("mind-bending sci-fi space exploration", top_k=3)
    print("Search results:", res)
