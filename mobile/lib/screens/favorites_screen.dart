import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/app_dimens.dart';

enum _SortBy { name, year, rating }

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

  bool _isGrid = false;
  _SortBy _sortBy = _SortBy.rating;
  bool _sortAsc = false;

  List<_FavItem> get _sortedItems {
    final list = List<_FavItem>.from(_items);
    switch (_sortBy) {
      case _SortBy.name:
        list.sort((a, b) => _sortAsc ? a.title.compareTo(b.title) : b.title.compareTo(a.title));
      case _SortBy.year:
        list.sort((a, b) => _sortAsc ? a.year.compareTo(b.year) : b.year.compareTo(a.year));
      case _SortBy.rating:
        list.sort((a, b) => _sortAsc ? a.rating.compareTo(b.rating) : b.rating.compareTo(a.rating));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedItems;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Favorites', style: Theme.of(context).textTheme.headlineMedium)
                      .animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),
                  const SizedBox(height: 4),
                  Text('${_items.where((i) => i.liked).length} movies saved',
                      style: TextStyle(color: AppColors.muted, fontSize: 13))
                      .animate().fadeIn(delay: 100.ms, duration: 400.ms),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isGrid = !_isGrid),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Icon(
                  _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  size: 20,
                  color: AppColors.accent1,
                ),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          ],
        ),
        const SizedBox(height: 16),
        // Sort row
        Row(
          children: [
            _buildSortChip('Rating', _SortBy.rating),
            const SizedBox(width: 8),
            _buildSortChip('Year', _SortBy.year),
            const SizedBox(width: 8),
            _buildSortChip('Name', _SortBy.name),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _sortAsc = !_sortAsc),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Icon(
                  _sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 16),
        if (items.isEmpty)
          _buildEmptyState()
        else if (_isGrid)
          _buildGrid(items)
        else
          ...List.generate(items.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFavCard(items[i], i),
          )),
      ],
    );
  }

  Widget _buildSortChip(String label, _SortBy value) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent1.withValues(alpha: 0.15) : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
            color: selected ? AppColors.accent1.withValues(alpha: 0.5) : AppColors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent1 : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<_FavItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildGridCard(items[i], i),
    );
  }

  Widget _buildGridCard(_FavItem item, int index) {
    final palettes = [
      [const Color(0xFF1E3A5F), const Color(0xFF0D2137)],
      [const Color(0xFF3B1F6E), const Color(0xFF1A0F3A)],
      [const Color(0xFF5F1E3A), const Color(0xFF370D21)],
      [const Color(0xFF1E5F3A), const Color(0xFF0D3721)],
      [const Color(0xFF5F4A1E), const Color(0xFF372A0D)],
    ];
    final colors = palettes[index % palettes.length];

    return GestureDetector(
      onTap: () => context.push('/home'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.borderSoft),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Center(
                  child: Text(
                    item.title[0],
                    style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${item.genre} \u2022 ${item.year}', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                        const SizedBox(width: 2),
                        Text('${item.rating}', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() => item.liked = !item.liked);
                          },
                          child: Icon(
                            item.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: item.liked ? AppColors.error : AppColors.muted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 60), duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
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
        setState(() => _items.removeWhere((e) => e.title == item.title));
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
      child: GestureDetector(
        onTap: () => context.push('/home'),
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
                width: 80,
                height: 80,
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
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: const Text('Discover Movies', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
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
