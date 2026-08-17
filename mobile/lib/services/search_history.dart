import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/recommendation.dart';
import 'api_client.dart';

const _historyKey = 'search_history';

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<SearchHistoryEntry>>(
  (ref) => SearchHistoryNotifier(ref.read(secureStorageProvider)),
);

class SearchHistoryNotifier extends StateNotifier<List<SearchHistoryEntry>> {
  final FlutterSecureStorage _storage;
  SearchHistoryNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final raw = await _storage.read(key: _historyKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).map((e) => SearchHistoryEntry.fromJson(e)).toList();
      state = list;
    } catch (_) {}
  }

  Future<void> _save() async {
    final json = jsonEncode(state.map((e) => e.toJson()).toList());
    await _storage.write(key: _historyKey, value: json);
  }

  Future<void> add({
    required String query,
    String? genre,
    String? itemType,
    required int resultCount,
  }) async {
    final entry = SearchHistoryEntry(
      query: query,
      genre: genre,
      itemType: itemType,
      timestamp: DateTime.now(),
      resultCount: resultCount,
    );
    state = [entry, ...state.where((e) => e.query != query || e.genre != genre)].take(20).toList();
    await _save();
  }

  Future<void> remove(int index) async {
    state = [...state]..removeAt(index);
    await _save();
  }

  Future<void> clear() async {
    state = [];
    await _save();
  }
}
