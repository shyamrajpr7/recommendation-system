import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../models/recommendation.dart';
import '../services/recommendation_service.dart';

final searchResultsProvider = StateProvider<RecommendationResponse?>((ref) => null);
final searchLoadingProvider = StateProvider<bool>((ref) => false);
final searchErrorProvider = StateProvider<String?>((ref) => null);
final searchGenreProvider = StateProvider<String?>((ref) => null);

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});
  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _queryCtrl = TextEditingController();

  @override
  void dispose() { _queryCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    ref.read(searchLoadingProvider.notifier).state = true;
    ref.read(searchErrorProvider.notifier).state = null;
    try {
      final genre = ref.read(searchGenreProvider);
      final result = await ref.read(recommendationServiceProvider).recommend(query: q, genre: genre);
      ref.read(searchResultsProvider.notifier).state = result;
    } catch (e) {
      ref.read(searchErrorProvider.notifier).state = 'Search failed. Is the backend running?';
    }
    ref.read(searchLoadingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(searchLoadingProvider);
    final error = ref.watch(searchErrorProvider);
    final results = ref.watch(searchResultsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Search', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('Semantic search with AI explanations', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: AppSpacing.xxl),
                TextField(
                  controller: _queryCtrl,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: "e.g. 'dream within a dream heist'",
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        if (loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.accent1)))
        else if (error != null)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(error, style: TextStyle(color: AppColors.error)),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(onPressed: _search, child: const Text('Retry')),
            ]),
          ))
        else if (results == null)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(children: [
              Icon(Icons.explore_rounded, size: 64, color: AppColors.muted2),
              const SizedBox(height: AppSpacing.lg),
              Text('Search for movies or books', style: TextStyle(color: AppColors.muted)),
            ]),
          ))
        else if (results.recommendations.isEmpty)
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: Text('No results found', style: TextStyle(color: AppColors.muted))),
          ))
        else
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            sliver: SliverList.separated(
              itemCount: results.recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _ResultCard(rec: results.recommendations[i], index: i),
            ),
          ),
      ],
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
        color: AppColors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _palette(rec.title), begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(children: [
              Positioned(top: 10, right: 14, child: Text('#${index + 1}', style: const TextStyle(fontFamily: 'Space Grotesk', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white70))),
              Positioned(top: 10, left: 14, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(99)),
                child: Text(rec.itemType, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
              )),
              Positioned(bottom: 10, left: 14, child: Text(rec.title, style: const TextStyle(fontFamily: 'Space Grotesk', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _badge(rec.genre, AppColors.accent1.withValues(alpha: 0.12), AppColors.accent1),
                  _badge('${rec.year}', AppColors.success.withValues(alpha: 0.12), AppColors.success),
                  _badge('${rec.rating}/10', AppColors.gold.withValues(alpha: 0.14), AppColors.gold),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: sim / 100, backgroundColor: AppColors.surface2, color: AppColors.accent2, minHeight: 6),
                  )),
                  const SizedBox(width: 8),
                  Text('$sim%', style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent2.withValues(alpha: 0.06),
                    border: Border(left: BorderSide(color: AppColors.accent2, width: 3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('💡 ${rec.aiExplanation}', maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12, height: 1.5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  List<Color> _palette(String t) {
    const p = [
      [Color(0xFF0EA5E9), Color(0xFF6366F1)],
      [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      [Color(0xFFF59E0B), Color(0xFFEF4444)],
      [Color(0xFF10B981), Color(0xFF0EA5E9)],
      [Color(0xFFF43F5E), Color(0xFF8B5CF6)],
    ];
    return p[t.codeUnits.fold(0, (a, b) => a + b) % p.length];
  }
}
