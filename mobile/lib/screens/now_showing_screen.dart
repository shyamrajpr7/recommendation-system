import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../models/cinema.dart';
import '../services/cinema_service.dart';

final moviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.read(cinemaServiceProvider).fetchMovies();
});

final genresProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(cinemaServiceProvider).fetchGenres();
});

final selectedGenreFilterProvider = StateProvider<String>((ref) => 'All');

class NowShowingScreen extends ConsumerWidget {
  const NowShowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);
    final genresAsync = ref.watch(genresProvider);
    final selectedGenre = ref.watch(selectedGenreFilterProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.movie_filter_rounded, size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CineRead', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text('AI-Powered Cinema', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Now Showing', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap a movie to see showtimes and book seats',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Genre filter pills
                genresAsync.when(
                  data: (genres) => SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', ...genres].map((g) {
                        final sel = selectedGenre == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => ref.read(selectedGenreFilterProvider.notifier).state = g,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.accent1.withValues(alpha: 0.15) : AppColors.surface2,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: sel ? AppColors.accent1.withValues(alpha: 0.4) : AppColors.border),
                              ),
                              child: Text(g, style: TextStyle(
                                color: sel ? AppColors.accent1 : AppColors.muted,
                                fontSize: 13, fontWeight: FontWeight.w600,
                              )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  loading: () => const SizedBox(height: 36),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        moviesAsync.when(
          data: (movies) {
            final filtered = selectedGenre == 'All'
                ? movies
                : movies.where((m) => m.genre == selectedGenre).toList();
            if (filtered.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('No movies in this genre', style: TextStyle(color: AppColors.muted))),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _MovieCard(movie: filtered[i]),
                  childCount: filtered.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 14, mainAxisSpacing: 14,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.accent1)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Failed to load movies', style: TextStyle(color: AppColors.error))),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Movie movie;
  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    final colors = _palette(movie.title);
    return GestureDetector(
      onTap: () => context.push('/showtimes/${movie.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSoft),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 8, left: 10,
                      child: Text(
                        movie.title,
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _badge(movie.genre, AppColors.accent1.withValues(alpha: 0.12), AppColors.accent1),
                        const Spacer(),
                        Text('${movie.year}', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(_stars(movie.rating), style: TextStyle(color: AppColors.gold, fontSize: 12, letterSpacing: 0.08)),
                        const SizedBox(width: 4),
                        Text('${movie.rating}', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/showtimes/${movie.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent1,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Book now', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  String _stars(double rating) {
    final filled = (rating / 2).round();
    return '★' * filled + '☆' * (5 - filled);
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
