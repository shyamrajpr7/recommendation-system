class Recommendation {
  final String title;
  final String genre;
  final String creator;
  final int year;
  final String synopsis;
  final String aiExplanation;
  final double rating;
  final double similarityScore;
  final String itemType;

  Recommendation({
    required this.title,
    required this.genre,
    required this.creator,
    required this.year,
    required this.synopsis,
    required this.aiExplanation,
    required this.rating,
    required this.similarityScore,
    required this.itemType,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      title: json['title'] ?? '',
      genre: json['genre'] ?? '',
      creator: json['creator'] ?? '',
      year: json['year'] ?? 0,
      synopsis: json['synopsis'] ?? '',
      aiExplanation: json['ai_explanation'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      similarityScore: (json['similarity_score'] ?? 0).toDouble(),
      itemType: json['item_type'] ?? 'Movie',
    );
  }
}

class RecommendationResponse {
  final String query;
  final bool cached;
  final int totalResults;
  final List<Recommendation> recommendations;

  RecommendationResponse({
    required this.query,
    required this.cached,
    required this.totalResults,
    required this.recommendations,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      query: json['query'] ?? '',
      cached: json['cached'] ?? false,
      totalResults: json['total_results'] ?? 0,
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .map((r) => Recommendation.fromJson(r))
          .toList(),
    );
  }
}

class SearchHistoryEntry {
  final String query;
  final String? genre;
  final String? itemType;
  final DateTime timestamp;
  final int resultCount;

  SearchHistoryEntry({
    required this.query,
    this.genre,
    this.itemType,
    required this.timestamp,
    required this.resultCount,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'genre': genre,
        'itemType': itemType,
        'timestamp': timestamp.toIso8601String(),
        'resultCount': resultCount,
      };

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      query: json['query'] ?? '',
      genre: json['genre'],
      itemType: json['itemType'],
      timestamp: DateTime.parse(json['timestamp']),
      resultCount: json['resultCount'] ?? 0,
    );
  }
}
