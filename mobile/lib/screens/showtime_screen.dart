import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../models/cinema.dart';
import '../services/cinema_service.dart';
import 'now_showing_screen.dart';

final showtimesProvider = FutureProvider.family<List<Showtime>, String?>((ref, date) async {
  return ref.read(cinemaServiceProvider).fetchShowtimes(date: date);
});

final datesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(cinemaServiceProvider).fetchDates();
});

final selectedDateProvider = StateProvider<String?>((ref) => null);

class ShowtimeScreen extends ConsumerWidget {
  final int movieId;
  const ShowtimeScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);
    final datesAsync = ref.watch(datesProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return moviesAsync.when(
      data: (movies) {
        final movie = movies.firstWhere((m) => m.id == movieId, orElse: () => movies.first);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180, pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/home'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(movie.title, style: const TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700)),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _palette(movie.title),
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
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
                      // Stepper
                      _Stepper(current: 1),
                      const SizedBox(height: AppSpacing.xl),
                      // Movie info
                      Wrap(
                        spacing: 8, runSpacing: 6,
                        children: [
                          _badge(movie.genre, AppColors.accent1.withValues(alpha: 0.12), AppColors.accent1),
                          _badge('${movie.year}', AppColors.success.withValues(alpha: 0.12), AppColors.success),
                          _badge('${movie.rating}/10', AppColors.gold.withValues(alpha: 0.14), AppColors.gold),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(movie.synopsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                      const SizedBox(height: AppSpacing.xxl),
                      // Date selector
                      Text('Select date', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      datesAsync.when(
                        data: (dates) => SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: dates.map((d) {
                              final sel = selectedDate == d;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => ref.read(selectedDateProvider.notifier).state = d,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: sel ? AppColors.accent1.withValues(alpha: 0.15) : AppColors.surface2,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: sel ? AppColors.accent1 : AppColors.border),
                                    ),
                                    child: Text(d, style: TextStyle(
                                      color: sel ? AppColors.accent1 : AppColors.muted,
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                    )),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        loading: () => const SizedBox(height: 40),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              // Showtimes
              _ShowtimeList(movieId: movieId),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent1)),
      ),
      error: (_, __) => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error loading movie', style: TextStyle(color: AppColors.error))),
      ),
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

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int current;
  const _Stepper({required this.current});
  @override
  Widget build(BuildContext context) {
    final steps = ['Movie', 'Showtime', 'Seats', 'Payment'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) return Expanded(child: Container(height: 1, color: AppColors.borderSoft));
        final idx = i ~/ 2;
        final done = idx < current;
        final active = idx == current;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (done || active) ? AppColors.primaryGradient : null,
                color: (!done && !active) ? AppColors.surface2 : null,
                border: (!done && !active) ? Border.all(color: AppColors.border) : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : Text('${idx + 1}', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.muted,
                      )),
              ),
            ),
            const SizedBox(width: 4),
            Text(steps[idx], style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? AppColors.text : AppColors.muted2,
            )),
          ],
        );
      }),
    );
  }
}

class _ShowtimeList extends ConsumerWidget {
  final int movieId;
  const _ShowtimeList({required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final showtimesAsync = ref.watch(showtimesProvider(date));

    return showtimesAsync.when(
      data: (showtimes) {
        final filtered = showtimes.where((s) => s.movieId == movieId).toList();
        if (filtered.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: Text('No showtimes available', style: TextStyle(color: AppColors.muted))),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          sliver: SliverList.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final st = filtered[i];
              return GestureDetector(
                onTap: () => context.push('/seats/${st.id}'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(st.showTime, style: const TextStyle(
                            fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent1,
                          )),
                          const SizedBox(height: 2),
                          Text('${st.theaterName} · ${st.screenName}', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                          Text(st.city, style: TextStyle(color: AppColors.muted2, fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${st.basePrice.toInt()}', style: const TextStyle(
                            fontFamily: 'Space Grotesk', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success,
                          )),
                          Text('${st.availableSeats} seats', style: TextStyle(color: AppColors.muted2, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: AppColors.muted2),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: AppColors.accent1)),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Center(child: Text('Failed to load showtimes', style: TextStyle(color: AppColors.error))),
      ),
    );
  }
}
