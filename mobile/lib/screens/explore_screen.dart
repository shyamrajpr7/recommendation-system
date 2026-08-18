import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/app_dimens.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const _categories = [
    _Cat('Trending Now', Icons.trending_up_rounded, Color(0xFF38BDF8)),
    _Cat('New Releases', Icons.new_releases_rounded, Color(0xFF818CF8)),
    _Cat('Top Rated', Icons.star_rounded, Color(0xFFFCD34D)),
    _Cat('Hidden Gems', Icons.diamond_rounded, Color(0xFFA78BFA)),
    _Cat('Award Winners', Icons.emoji_events_rounded, Color(0xFF6EE7B7)),
    _Cat('Coming Soon', Icons.upcoming_rounded, Color(0xFFF87171)),
  ];

  static const _featured = [
    _Feat('Oppenheimer', 'Sci-Fi \u00b7 Drama', 2023, 8.5),
    _Feat('Dune: Part Two', 'Sci-Fi \u00b7 Adventure', 2024, 8.7),
    _Feat('The Batman', 'Action \u00b7 Crime', 2022, 7.8),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore', style: Theme.of(context).textTheme.headlineMedium)
                    .animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),
                const SizedBox(height: 4),
                Text('Discover movies by category',
                    style: TextStyle(color: AppColors.muted, fontSize: 13))
                    .animate().fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
                      const SizedBox(width: 12),
                      Text('Search movies, genres...', style: TextStyle(color: AppColors.muted2, fontSize: 14)),
                      const Spacer(),
                      Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.accent3),
                    ]),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 28),
                Text('Featured', style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text))
                    .animate().fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _buildFeatured(_featured[i], i),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
            child: Text('Browse Categories', style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text))
                .animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
            delegate: SliverChildBuilderDelegate((_, i) => _buildCategory(_categories[i], i), childCount: _categories.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildFeatured(_Feat item, int index) {
    final palettes = [
      [const Color(0xFF1E3A5F), const Color(0xFF0D2137)],
      [const Color(0xFF3B1F6E), const Color(0xFF1A0F3A)],
      [const Color(0xFF5F1E3A), const Color(0xFF370D21)],
    ];
    final colors = palettes[index % palettes.length];
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)]),
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              ),
            ),
          ),
          Positioned(bottom: 14, left: 14, right: 14, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(fontFamily: 'Space Grotesk', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text(item.genre, style: TextStyle(color: Colors.white70, fontSize: 11)),
                const Spacer(),
                Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 2),
                Text('${item.rating}', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ],
          )),
          Positioned(top: 12, right: 12, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
            child: Text('${item.year}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
          )),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: 300 + index * 100), duration: 400.ms)
          .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: 300 + index * 100), duration: 400.ms),
    );
  }

  Widget _buildCategory(_Cat cat, int index) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(cat.icon, size: 20, color: cat.color),
            ),
            const SizedBox(height: 10),
            Text(cat.name, style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 400 + index * 80), duration: 400.ms)
          .scale(begin: const Offset(0.9, 0.9), delay: Duration(milliseconds: 400 + index * 80), duration: 300.ms),
    );
  }
}

class _Cat {
  final String name;
  final IconData icon;
  final Color color;
  const _Cat(this.name, this.icon, this.color);
}

class _Feat {
  final String title;
  final String genre;
  final int year;
  final double rating;
  const _Feat(this.title, this.genre, this.year, this.rating);
}
