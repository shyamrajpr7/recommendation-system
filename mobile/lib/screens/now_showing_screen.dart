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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand header
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.25), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.movie_filter_rounded, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CineRead', style: TextStyle(
                          fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text,
                        )),
                        Text('AI-Powered Cinema', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Section title
                Text('Now Showing', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Tap a movie to see showtimes and book seats',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
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
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: sel ? AppColors.accent1.withValues(alpha: 0.5) : AppColors.border),
                              ),
                              child: Text(g, style: TextStyle(
                                color: sel ? AppColors.accent1 : AppColors.muted,
                                fontSize: 12.5, fontWeight: FontWeight.w600,
                              )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
                child: Center(child: Text('No movies in this genre', style: TextStyle(color: AppColors.muted))),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, i) => _MovieCard(movie: filtered[i]),
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
            // Gradient poster header
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                  ),
                  // Genre badge
                  Positioned(
                    top: 10, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(movie.genre, style: const TextStyle(
                        color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w700,
                      )),
                    ),
                  ),
                  // Year badge
                  Positioned(
                    top: 10, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${movie.year}', style: const TextStyle(
                        color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w700,
                      )),
                    ),
                  ),
                  // Title
                  Positioned(
                    bottom: 10, left: 14, right: 14,
                    child: Text(
                      movie.title,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
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
                  // Synopsis
                  Text(
                    movie.synopsis,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  // Rating row
                  Row(
                    children: [
                      Text(
                        _stars(movie.rating),
                        style: TextStyle(color: AppColors.gold, fontSize: 13, letterSpacing: 0.06),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${movie.rating}/10',
                        style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      // Director
                      if (movie.director.isNotEmpty)
                        Text(
                          movie.director,
                          style: TextStyle(color: AppColors.muted2, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/showtimes/${movie.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent1,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Book now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
