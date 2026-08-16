import os
import json
import re
from typing import List, Dict, Any, Optional

# Check for Gemini API key
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

def generate_explanations(query: str, candidates: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Generates grounded natural-language explanations for recommendations.
    Uses Google Gemini API if GEMINI_API_KEY is configured, otherwise uses structured fallback.
    """
    if not candidates:
        return []

    # Attempt Gemini API call if key is available
    if GEMINI_API_KEY:
        try:
            from google import genai
            client = genai.Client(api_key=GEMINI_API_KEY)
            
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
            
            prompt = (
                f"You are a recommendation explanation system.\n"
                f"User Query: \"{query}\"\n\n"
                f"Here are the top retrieved recommendations based on vector similarity:\n\n"
                f"{formatted_candidates}\n"
                f"STRICT RULES:\n"
                f"1. Provide a concise 2-3 sentence explanation for why each item fits the user's query.\n"
                f"2. Use ONLY facts provided in the supplied metadata above. Do NOT invent plot details, actors, or unmentioned awards.\n"
                f"3. Return the output strictly as a JSON object matching this schema:\n"
                f"   {{\"explanations\": [{{\"id\": <item_id>, \"explanation\": \"<explanation_text>\"}}]}}\n"
            )

            response = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
                config={'response_mime_type': 'application/json'}
            )
            
            raw_text = response.text.strip()
            parsed = json.loads(raw_text)
            explanations_list = parsed.get("explanations", [])
            
            exp_by_id = {item["id"]: item["explanation"] for item in explanations_list if "id" in item and "explanation" in item}
            
            validated_candidates = []
            for cand in candidates:
                cand_copy = dict(cand)
                exp = exp_by_id.get(cand["id"], "").strip()
                # Basic validation: ensure non-empty and non-fabricated feel
                if exp:
                    cand_copy["ai_explanation"] = exp
                else:
                    cand_copy["ai_explanation"] = _fallback_explanation(query, cand)
                validated_candidates.append(cand_copy)
                
            return validated_candidates

        except Exception as e:
            print(f"[LLM Explainer] Gemini API call failed or unavailable ({e}). Using grounded fallback explanations.")

    # Fallback when API key is missing or call fails
    validated_candidates = []
    for cand in candidates:
        cand_copy = dict(cand)
        cand_copy["ai_explanation"] = _fallback_explanation(query, cand)
        validated_candidates.append(cand_copy)

    return validated_candidates

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
