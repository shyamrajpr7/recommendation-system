import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import 'search_screen.dart';

class RecommendationDetailScreen extends ConsumerWidget {
  final int index;
  const RecommendationDetailScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    final rec = results?.recommendations[index];

    if (rec == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Recommendation')),
        body: const Center(child: Text('No data available')),
      );
    }

    final sim = (rec.similarityScore * 100).round();
    final grad = _palette(rec.title);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                rec.title,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 60,
                      right: 20,
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          rec.itemType,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge(rec.genre, AppColors.accent1.withValues(alpha: 0.12), AppColors.accent1),
                      _badge('${rec.year}', AppColors.success.withValues(alpha: 0.12), AppColors.success),
                      _badge('★ ${rec.rating}/10', AppColors.gold.withValues(alpha: 0.14), AppColors.gold),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Creator
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 18, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        'by ${rec.creator}',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Match bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Semantic match', style: TextStyle(color: AppColors.muted2, fontSize: 12, letterSpacing: 0.08)),
                      Text('$sim%', style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: sim / 100,
                      backgroundColor: AppColors.surface2,
                      color: AppColors.accent2,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Synopsis
                  Text('Synopsis', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.accent1)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    rec.synopsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.65),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Why recommended
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.accent2.withValues(alpha: 0.06),
                      border: Border(
                        left: BorderSide(color: AppColors.accent2, width: 3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why recommended',
                          style: TextStyle(
                            color: AppColors.accent2,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.06,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          rec.aiExplanation,
                          style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 14, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
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
