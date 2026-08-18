import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/app_dimens.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<_FavItem> _items = [
    _FavItem('Inception', 'Sci-Fi', 2010, 8.8, true),
    _FavItem('Interstellar', 'Sci-Fi', 2014, 8.6, true),
    _FavItem('The Dark Knight', 'Action', 2008, 9.0, true),
    _FavItem('Parasite', 'Thriller', 2019, 8.5, true),
    _FavItem('Everything Everywhere', 'Sci-Fi', 2022, 7.8, true),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 4),
        Text('Favorites', style: Theme.of(context).textTheme.headlineMedium)
            .animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),
        const SizedBox(height: 4),
        Text('${_items.where((i) => i.liked).length} movies saved',
            style: TextStyle(color: AppColors.muted, fontSize: 13))
            .animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 24),
        if (_items.isEmpty)
          _buildEmptyState()
        else
          ...List.generate(_items.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFavCard(_items[i], i),
          )),
      ],
    );
  }

  Widget _buildFavCard(_FavItem item, int index) {
    final palettes = [
      [const Color(0xFF1E3A5F), const Color(0xFF0D2137)],
      [const Color(0xFF3B1F6E), const Color(0xFF1A0F3A)],
      [const Color(0xFF5F1E3A), const Color(0xFF370D21)],
      [const Color(0xFF1E5F3A), const Color(0xFF0D3721)],
      [const Color(0xFF5F4A1E), const Color(0xFF372A0D)],
    ];
    final colors = palettes[index % palettes.length];

    return Dismissible(
      key: ValueKey('${item.title}-$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _items.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} removed from favorites')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.borderSoft),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Center(
                child: Text(
                  item.title[0],
                  style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(item.genre, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('${item.year}', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 2),
                    Text('${item.rating}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            ),
            // Like button with bounce
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => item.liked = !item.liked);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.liked ? AppColors.error.withValues(alpha: 0.15) : AppColors.surface2,
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    item.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(item.liked),
                    color: item.liked ? AppColors.error : AppColors.muted,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + index * 80), duration: 400.ms)
        .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: 200 + index * 80), duration: 400.ms);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: AppColors.muted2),
            const SizedBox(height: 16),
            Text('No favorites yet', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Tap the heart icon on any movie to save it here', style: TextStyle(color: AppColors.muted, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }
}

class _FavItem {
  final String title;
  final String genre;
  final int year;
  final double rating;
  bool liked;

  _FavItem(this.title, this.genre, this.year, this.rating, this.liked);
}
