import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation.dart';
import 'api_client.dart';

class RecommendationService {
  final Dio _dio;
  RecommendationService(this._dio);

  Future<RecommendationResponse> recommend({
    required String query,
    String? genre,
    String? itemType,
    int topK = 3,
  }) async {
    final data = <String, dynamic>{
      'query': query,
      'top_k': topK,
    };
    if (genre != null) data['genre'] = genre;
    if (itemType != null) data['item_type'] = itemType;

    final res = await _dio.post('/recommend', data: data);
    return RecommendationResponse.fromJson(res.data);
  }

  Future<List<String>> fetchGenres() async {
    final res = await _dio.get('/genres');
    return List<String>.from(res.data['genres'] ?? []);
  }
}

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService(ref.watch(dioProvider));
});
