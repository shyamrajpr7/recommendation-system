import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/app_dimens.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent1.withValues(alpha: 0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.movie_filter_rounded, size: 24, color: Colors.white),
                    ).animate().scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CineRead',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        Text('AI-Powered Cinema', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0),
                const SizedBox(height: 24),
                Text('Now Showing', style: Theme.of(context).textTheme.headlineMedium)
                    .animate().fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 4),
                Text(
                  'Tap a movie to see showtimes and book seats',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 16),
                // Genre pills
                genresAsync.when(
                  data: (genres) => SizedBox(
                    height: 34,
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
                                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                                border: Border.all(
                                  color: sel ? AppColors.accent1.withValues(alpha: 0.5) : AppColors.border,
                                ),
                              ),
                              child: Text(
                                g,
                                style: TextStyle(
                                  color: sel ? AppColors.accent1 : AppColors.muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  loading: () => const SizedBox(height: 34),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Movie grid
        moviesAsync.when(
          data: (movies) {
            final filtered = selectedGenre == 'All'
                ? movies
                : movies.where((m) => m.genre == selectedGenre).toList();
            if (filtered.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text('No movies in this genre', style: TextStyle(color: AppColors.muted)),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, i) => _MovieCard(
                  movie: filtered[i],
                  index: i,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.accent1)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load movies', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Movie movie;
  final int index;

  const _MovieCard({required this.movie, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = _palette(movie.title);
    return Hero(
      tag: 'movie-${movie.id}',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => context.push('/detail/${movie.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              border: Border.all(color: AppColors.borderSoft),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient poster header
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                          ),
                          child: Text(
                            movie.genre,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                          ),
                          child: Text(
                            '${movie.year}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 14,
                        right: 14,
                        child: Text(
                          movie.title,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.synopsis,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            _stars(movie.rating),
                            style: TextStyle(color: AppColors.gold, fontSize: 13, letterSpacing: 0.06),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${movie.rating}/10',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent1.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                            ),
                            child: Text(
                              'Book Now',
                              style: TextStyle(
                                color: AppColors.accent1,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 300 + (index * 80)),
          duration: 400.ms,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 300 + (index * 80)),
          duration: 400.ms,
        );
  }

  String _stars(double rating) {
    final full = rating ~/ 2;
    final half = (rating % 2) >= 1 ? 1 : 0;
    return '${'★' * full}${half == 1 ? '½' : ''}${'☆' * (5 - full - half)}';
  }

  List<Color> _palette(String title) {
    final palettes = [
      [const Color(0xFF1E3A5F), const Color(0xFF0D2137)],
      [const Color(0xFF3B1F6E), const Color(0xFF1A0F3A)],
      [const Color(0xFF5F1E3A), const Color(0xFF370D21)],
      [const Color(0xFF1E5F3A), const Color(0xFF0D3721)],
      [const Color(0xFF5F4A1E), const Color(0xFF372A0D)],
      [const Color(0xFF1E4A5F), const Color(0xFF0D2A37)],
    ];
    return palettes[title.hashCode.abs() % palettes.length];
  }
}
