import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../services/recommendation_service.dart';
import '../models/recommendation.dart';

final _selectedGenreProvider = StateProvider<String>((ref) => 'All');
final _searchQueryProvider = StateProvider<String>((ref) => '');
final _searchResultProvider = StateProvider<RecommendationResponse?>((ref) => null);
final _searchLoadingProvider = StateProvider<bool>((ref) => false);
final _searchErrorProvider = StateProvider<String?>((ref) => null);

final _suggestionsProvider = FutureProvider<List<String>>((ref) async {
  try {
    return await ref.read(recommendationServiceProvider).fetchGenres();
  } catch (_) {
    return ['Action', 'Comedy', 'Drama', 'Horror', 'Sci-Fi', 'Thriller', 'Romance'];
  }
});

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});
  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _queryCtrl = TextEditingController();
  final _focus = FocusNode();
  static const _genres = ['All', 'Action', 'Comedy', 'Drama', 'Horror', 'Sci-Fi', 'Thriller', 'Romance'];

  @override
  void dispose() { _queryCtrl.dispose(); _focus.dispose(); super.dispose(); }

  void _fillSuggestion(String text) {
    _queryCtrl.text = text;
    _queryCtrl.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    _submit(text);
    _focus.unfocus();
  }

  Future<void> _submit([String? q]) async {
    final query = (q ?? _queryCtrl.text).trim();
    if (query.isEmpty) return;
    ref.read(_searchQueryProvider.notifier).state = query;
    ref.read(_searchLoadingProvider.notifier).state = true;
    ref.read(_searchErrorProvider.notifier).state = null;
    try {
      final genre = ref.read(_selectedGenreProvider);
      final r = await ref.read(recommendationServiceProvider).recommend(
        query: query,
        genre: genre == 'All' ? null : genre,
      );
      ref.read(_searchResultProvider.notifier).state = r;
    } catch (e) {
      ref.read(_searchErrorProvider.notifier).state = e.toString();
    }
    ref.read(_searchLoadingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(_suggestionsProvider).valueOrNull ?? [];
    final result = ref.watch(_searchResultProvider);
    final loading = ref.watch(_searchLoadingProvider);
    final error = ref.watch(_searchErrorProvider);
    final selectedGenre = ref.watch(_selectedGenreProvider);

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _searchBar(),
          const SizedBox(height: 12),
          _genreChips(selectedGenre),
          const SizedBox(height: 14),

          if (result == null && !loading && suggestions.isNotEmpty)
            _suggestionChips(suggestions),

          if (loading) const _LoadingCard(),

          if (error != null && !loading) _errorCard(error),

          if (result != null && !loading) ...[
            _resultHeader(result),
            const SizedBox(height: 10),
            if (result.recommendations.isEmpty)
              _emptyState()
            else
              ...result.recommendations.map((r) => _ResultCard(recommendation: r)),
          ],
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focus.hasFocus ? AppColors.accent1.withValues(alpha: 0.5) : AppColors.borderSoft,
          width: _focus.hasFocus ? 1.5 : 1,
        ),
        boxShadow: _focus.hasFocus ? [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.1), blurRadius: 12)] : null,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.auto_awesome, color: AppColors.accent1, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _queryCtrl,
              focusNode: _focus,
              decoration: InputDecoration(
                hintText: 'Describe your mood…',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              style: const TextStyle(fontSize: 14),
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (_queryCtrl.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: AppColors.muted2),
              onPressed: () {
                _queryCtrl.clear();
                ref.read(_searchResultProvider.notifier).state = null;
                ref.read(_searchErrorProvider.notifier).state = null;
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _genreChips(String selected) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = _genres[i];
          final active = selected == g;
          return GestureDetector(
            onTap: () {
              ref.read(_selectedGenreProvider.notifier).state = g;
              if (ref.read(_searchResultProvider) != null) _submit();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: active ? AppColors.primaryGradient : null,
                color: active ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: active ? Colors.transparent : AppColors.borderSoft),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_genreIcon(g), size: 14, color: active ? Colors.white : AppColors.accent1),
                  const SizedBox(width: 5),
                  Text(g, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _suggestionChips(List<String> suggestions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Try something', style: TextStyle(color: AppColors.muted2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: suggestions.take(5).map((s) {
              return GestureDetector(
                onTap: () => _fillSuggestion(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent1.withValues(alpha: 0.1), AppColors.accent2.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.accent3.withValues(alpha: 0.25)),
                  ),
                  child: Text(s, style: TextStyle(color: AppColors.accent1, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _resultHeader(RecommendationResponse r) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent1),
        const SizedBox(width: 6),
        Text('${r.totalResults} results', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(width: 8),
        if (r.cached)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 11, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Cached', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _errorCard(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(error, style: TextStyle(color: AppColors.error, fontSize: 13))),
      ]),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text('🎬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No recommendations', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Try a different mood or genre', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }

  IconData _genreIcon(String g) {
    switch (g) {
      case 'Action': return Icons.local_fire_department;
      case 'Comedy': return Icons.sentiment_very_satisfied;
      case 'Drama': return Icons.theater_comedy;
      case 'Horror': return Icons.psychology;
      case 'Sci-Fi': return Icons.rocket_launch;
      case 'Thriller': return Icons.bolt;
      case 'Romance': return Icons.favorite;
      default: return Icons.movie;
    }
  }
}

class _ResultCard extends StatelessWidget {
  final Recommendation recommendation;
  const _ResultCard({required this.recommendation});
  @override
  Widget build(BuildContext context) {
    final matchPct = (recommendation.similarityScore * 100).round();
    final matchColor = matchPct >= 85
        ? AppColors.success
        : matchPct >= 70
            ? AppColors.gold
            : AppColors.accent1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.accent1.withValues(alpha: 0.25), AppColors.accent2.withValues(alpha: 0.15), AppColors.accent3.withValues(alpha: 0.08)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10, left: 14,
                  child: matchPct > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('$matchPct%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Positioned(
                  top: 10, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
                    child: Text(recommendation.itemType, style: TextStyle(color: AppColors.muted2, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
                Positioned(
                  bottom: 14, left: 14, right: 14,
                  child: Text(
                    recommendation.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.15),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match bar
                if (matchPct > 0) _matchBar(matchPct, matchColor),
                const SizedBox(height: 10),
                // Genre + year + rating
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent1.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(recommendation.genre, style: TextStyle(color: AppColors.accent1, fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Text('${recommendation.year}', style: TextStyle(color: AppColors.muted2, fontSize: 11, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (recommendation.rating > 0)
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                          const SizedBox(width: 2),
                          Text('${recommendation.rating}', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                  ],
                ),
                // Synopsis
                if (recommendation.synopsis.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(recommendation.synopsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
                // AI explanation
                if (recommendation.aiExplanation.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent3.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent3.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: AppColors.accent3),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(recommendation.aiExplanation, style: TextStyle(color: AppColors.accent3, fontSize: 11.5, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Creator
                if (recommendation.creator.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(recommendation.creator, style: TextStyle(color: AppColors.muted2, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchBar(int pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Match', style: TextStyle(color: AppColors.muted2, fontSize: 10.5, fontWeight: FontWeight.w700)),
            Text('$pct%', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            children: [
              Container(height: 4, color: AppColors.surface2),
              FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent1),
            ),
            const SizedBox(width: 10),
            Text('AI is thinking…', style: TextStyle(color: AppColors.accent1, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 12,
              width: [150.0, 200.0, 120.0][i],
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(6)),
            ),
          )),
        ],
      ),
    );
  }
}
