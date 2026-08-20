import re
from typing import List, Dict, Any

from backend.app.grok_client import grok_json

# Common function words that never count as evidence of fabrication.
_STOP_WORDS = {
    "the", "a", "an", "and", "or", "but", "of", "in", "on", "for", "to", "is",
    "are", "was", "were", "be", "been", "being", "it", "its", "this", "that",
    "these", "those", "with", "by", "from", "as", "at", "which", "who", "whom",
    "whose", "what", "when", "where", "why", "how", "if", "than", "then", "so",
    "because", "also", "more", "most", "less", "very", "such", "both", "each",
    "only", "just", "about", "into", "over", "under", "between", "not", "no",
    "yes", "you", "your", "they", "them", "their", "we", "our", "i", "my", "me",
    "he", "she", "him", "her", "his", "has", "have", "had", "do", "does", "did",
    "will", "would", "can", "could", "should", "may", "might", "must", "make",
    "makes", "made", "say", "says", "said", "tell", "tells", "told", "give",
    "gives", "given", "take", "takes", "taken", "find", "finds", "found", "seen",
    "story", "film", "movie", "book", "novel", "feature", "work", "plot", "title",
    "one", "two", "three", "yet", "although", "though", "even", "still",
    "already", "however", "therefore", "thus", "similar", "alike", "match",
    "matches", "matched", "recommend", "recommended", "suggest", "suggests",
    "suggested", "audience", "viewer", "reader", "fan", "fans", "perfect",
    "great", "greatest", "best", "good", "high", "highly", "rated",
    "rating", "well", "top", "part", "due", "likely"
}

def generate_explanations(query: str, candidates: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Generates grounded natural-language explanations for recommendations.
    Uses xAI Grok if XAI_API_KEY is configured, otherwise uses structured fallback.
    """
    if not candidates:
        return []

    prompt_context = []
    for i, cand in enumerate(candidates, 1):
        prompt_context.append(
            f"Candidate {i} (ID: {cand['id']}):\n"
            f"- Title: {cand['title']}\n"
            f"- Type: {cand['item_type']}\n"
            f"- Genre: {cand['genre']}\n"
            f"- Creator: {cand['creator']}\n"
            f"- Rating: {cand['rating']}/10\n"
            f"- Synopsis: {cand['synopsis']}\n"
        )

    formatted_candidates = "\n".join(prompt_context)

    system_prompt = (
        "You are a recommendation explanation system. You never recommend anything "
        "yourself; you only explain why the retrieved candidates were matched."
    )
    user_prompt = (
        f"User Query: \"{query}\"\n\n"
        f"Here are the top retrieved recommendations based on vector similarity:\n\n"
        f"{formatted_candidates}\n"
        f"STRICT RULES:\n"
        f"1. Provide a concise 2-3 sentence explanation for why each item fits the user's query.\n"
        f"2. Use ONLY facts provided in the supplied metadata above. Do NOT invent plot details, actors, cast, or unmentioned awards.\n"
        f"3. Return the output strictly as a JSON object matching this schema:\n"
        f"   {{\"explanations\": [{{\"id\": <item_id>, \"explanation\": \"<explanation_text>\"}}]}}\n"
    )

    parsed = grok_json([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ], temperature=0.2, max_tokens=1024)

    exp_by_id = {}
    if parsed and isinstance(parsed.get("explanations"), list):
        exp_by_id = {
            item["id"]: item["explanation"]
            for item in parsed["explanations"]
            if "id" in item and "explanation" in item
        }

    return _validate_candidates(query, candidates, exp_by_id)

def _validate_candidates(query: str, candidates: List[Dict[str, Any]], exp_by_id: Dict[Any, str]) -> List[Dict[str, Any]]:
    """
    Response validation (pipeline step 9):
    - Every candidate gets exactly one explanation (non-empty).
    - Each explanation is grounded in supplied metadata; fabricated-looking
      sentences are stripped, and fully-fabricated explanations are replaced
      with the grounded fallback.
    """
    validated = []
    for cand in candidates:
        cand_copy = dict(cand)
        exp = exp_by_id.get(cand["id"], "")
        if not isinstance(exp, str) or not exp.strip():
            cand_copy["ai_explanation"] = _fallback_explanation(query, cand)
        else:
            grounded = _strip_fabricated(query, cand, exp.strip())
            cand_copy["ai_explanation"] = grounded if grounded else _fallback_explanation(query, cand)
        validated.append(cand_copy)
    return validated

def _strip_fabricated(query: str, item: Dict[str, Any], explanation: str) -> str:
    """
    Basic keyword/entity grounding check. Builds the set of fact terms from the
    supplied metadata (title, genre, creator, rating, year, synopsis) plus the
    user query, then drops any sentence whose meaningful terms are absent from
    that set (those sentences reference invented facts).
    """
    fact_text = " ".join([
        str(item.get("title", "")),
        str(item.get("item_type", "")),
        str(item.get("genre", "")),
        str(item.get("creator", "")),
        str(item.get("rating", "")),
        str(item.get("year", "")),
        str(item.get("synopsis", "")),
        query,
    ])
    fact_lower = fact_text.lower()
    allowed_terms = set(re.findall(r"[a-z]+", fact_lower)) - _STOP_WORDS

    # Proper-noun/entity check: capitalized words in the explanation must
    # appear in the supplied metadata, otherwise they are invented entities.
    fact_capitalized = _capitalized_tokens(fact_text)

    sentences = re.split(r"(?<=[.!?])\s+", explanation)
    kept = []
    for sentence in sentences:
        terms = set(re.findall(r"[a-z]+", sentence.lower())) - _STOP_WORDS
        if not (terms & allowed_terms):
            continue
        sentence_caps = _capitalized_tokens(sentence)
        if sentence_caps and not sentence_caps <= fact_capitalized:
            continue
        kept.append(sentence)

    grounded = " ".join(kept).strip()
    return grounded if len(grounded) >= 10 else ""

_CAP_WORD = re.compile(r"\b[A-Z][a-zA-Z]*\b")

def _capitalized_tokens(text: str) -> set:
    """Lowercased capitalized words in a text, ignoring sentence-initial capitals."""
    text = re.sub(r"(^|[.!?]\s+)([A-Z])", lambda m: m.group(1) + m.group(2).lower(), text)
    text = text.replace("-", " ")
    return set(word.lower() for word in _CAP_WORD.findall(text))

def _fallback_explanation(query: str, item: Dict[str, Any]) -> str:
    """
    Grounded template fallback explanation based strictly on item metadata.
    """
    sim_pct = int(item.get("similarity_score", 0.8) * 100)
    return (
        f"Recommended for your search '{query}' because '{item['title']}' is a highly-rated ({item['rating']}/10) "
        f"{item['genre']} {item['item_type'].lower()} by {item['creator']}. "
        f"It matches your interest with a {sim_pct}% semantic similarity score based on its plot synopsis."
    )
