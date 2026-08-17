import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../models/recommendation.dart';
import '../services/recommendation_service.dart';
import '../services/search_history.dart';

final searchResultsProvider = StateProvider<RecommendationResponse?>((ref) => null);
final searchLoadingProvider = StateProvider<bool>((ref) => false);
final searchErrorProvider = StateProvider<String?>((ref) => null);
final selectedGenreProvider = StateProvider<String?>((ref) => null);
final selectedTypeProvider = StateProvider<String?>((ref) => null);
final genresProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(recommendationServiceProvider).fetchGenres();
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryCtrl = TextEditingController();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;

    ref.read(searchLoadingProvider.notifier).state = true;
    ref.read(searchErrorProvider.notifier).state = null;
    ref.read(searchResultsProvider.notifier).state = null;

    final genre = ref.read(selectedGenreProvider);
    final itemType = ref.read(selectedTypeProvider);

    try {
      final result = await ref.read(recommendationServiceProvider).recommend(
            query: q,
            genre: genre,
            itemType: itemType,
          );
      ref.read(searchResultsProvider.notifier).state = result;
      // Save to history
      ref.read(searchHistoryProvider.notifier).add(
            query: q,
            genre: genre,
            itemType: itemType,
            resultCount: result.totalResults,
          );
    } catch (e) {
      ref.read(searchErrorProvider.notifier).state =
          e is Exception ? e.toString() : 'Search failed. Please try again.';
    } finally {
      ref.read(searchLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(searchLoadingProvider);
    final error = ref.watch(searchErrorProvider);
    final results = ref.watch(searchResultsProvider);
    final genresAsync = ref.watch(genresProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Semantic Search', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Find your next watch — powered by AI',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextField(
                  controller: _queryCtrl,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: "e.g. 'dream within a dream heist'",
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                    suffixIcon: _queryCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _queryCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Genre chips
                genresAsync.when(
                  data: (genres) => Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _FilterChip(
                        label: 'All genres',
                        selected: ref.watch(selectedGenreProvider) == null,
                        onTap: () => ref.read(selectedGenreProvider.notifier).state = null,
                      ),
                      ...genres.take(8).map((g) => _FilterChip(
                            label: g,
                            selected: ref.watch(selectedGenreProvider) == g,
                            onTap: () => ref.read(selectedGenreProvider.notifier).state = g,
                          )),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        if (loading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent1),
            ),
          )
        else if (error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(onPressed: _search, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (results == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(Icons.explore_rounded, size: 64, color: AppColors.muted2),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Describe a plot, mood, or title',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Search history
                  Consumer(builder: (_, ref, _) {
                    final history = ref.watch(searchHistoryProvider);
                    if (history.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent searches',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.muted),
                              ),
                              TextButton(
                                onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
                                child: Text('Clear', style: TextStyle(color: AppColors.muted2, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        ...history.take(5).map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: 3),
                              child: GestureDetector(
                                onTap: () {
                                  _queryCtrl.text = entry.query;
                                  _search();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderSoft),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.history_rounded, size: 16, color: AppColors.muted2),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(entry.query, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      ),
                                      Text(
                                        '${entry.resultCount} results',
                                        style: TextStyle(color: AppColors.muted2, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                    );
                  }),
                ],
              ),
            ),
          )
        else if (results.recommendations.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 56, color: AppColors.muted2),
                  const SizedBox(height: AppSpacing.md),
                  Text('No results found', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Try adjusting genre or query',
                    style: TextStyle(color: AppColors.muted2, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl),
            sliver: SliverList.separated(
              itemCount: results.recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final rec = results.recommendations[index];
                return GestureDetector(
                  onTap: () => context.push('/recommendation/$index'),
                  child: _ResultCard(rec: rec, index: index),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent1.withValues(alpha: 0.15) : AppColors.surface2,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.accent1.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent1 : AppColors.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Recommendation rec;
  final int index;
  const _ResultCard({required this.rec, required this.index});

  @override
  Widget build(BuildContext context) {
    final sim = (rec.similarityScore * 100).round();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _palette(rec.title),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 14,
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      rec.itemType,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 14,
                  child: Text(
                    rec.title,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _badge(rec.genre, AppColors.accent1.withValues(alpha: 0.12), AppColors.accent1),
                    _badge('${rec.year}', AppColors.success.withValues(alpha: 0.12), AppColors.success),
                    _badge('${rec.rating}/10', AppColors.gold.withValues(alpha: 0.14), AppColors.gold),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  rec.synopsis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: sim / 100,
                          backgroundColor: AppColors.surface2,
                          color: AppColors.accent2,
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$sim%', style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent2.withValues(alpha: 0.06),
                    border: Border(
                      left: BorderSide(color: AppColors.accent2, width: 3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    rec.aiExplanation,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  List<Color> _palette(String title) {
    const palettes = [
      [Color(0xFF0EA5E9), Color(0xFF6366F1)],
      [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      [Color(0xFFF59E0B), Color(0xFFEF4444)],
      [Color(0xFF10B981), Color(0xFF0EA5E9)],
      [Color(0xFFF43F5E), Color(0xFF8B5CF6)],
      [Color(0xFF14B8A6), Color(0xFF6366F1)],
    ];
    final hash = title.codeUnits.fold(0, (a, b) => a + b);
    return palettes[hash % palettes.length];
  }
}
