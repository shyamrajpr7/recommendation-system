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
        final colors = _palette(movie.title);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // App bar with gradient
              SliverAppBar(
                expandedHeight: 200, pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.go('/home'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(movie.title, style: const TextStyle(
                    fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white,
                  )),
                  background: Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stepper (step 2 active)
                      _BookingStepper(current: 1),
                      const SizedBox(height: 20),
                      // Movie info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(movie.title, style: const TextStyle(
                              fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700,
                            )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 6,
                              children: [
                                _badge(movie.genre, AppColors.accent1.withValues(alpha: 0.12), AppColors.accent1),
                                _badge('${movie.year}', AppColors.success.withValues(alpha: 0.12), AppColors.success),
                                _badge('${movie.rating}/10', AppColors.gold.withValues(alpha: 0.14), AppColors.gold),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(movie.synopsis, maxLines: 3, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Date selector
                      Text('Select date', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      datesAsync.when(
                        data: (dates) => SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: dates.map((d) {
                              final sel = selectedDate == d;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => ref.read(selectedDateProvider.notifier).state = d,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: sel ? AppColors.primaryGradient : null,
                                      color: sel ? null : AppColors.surface2,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: sel ? Colors.transparent : AppColors.border),
                                      boxShadow: sel ? [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.25), blurRadius: 10)] : null,
                                    ),
                                    child: Text(_formatDate(d), style: TextStyle(
                                      color: sel ? Colors.white : AppColors.muted,
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                    )),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        loading: () => const SizedBox(height: 42),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                      Text('Available showtimes', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              // Showtime list
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
        body: Center(child: Text('Error loading', style: TextStyle(color: AppColors.error))),
      ),
    );
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d);
      final now = DateTime.now();
      final names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      if (isToday) return 'Today';
      return '${names[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return d;
    }
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

class _BookingStepper extends StatelessWidget {
  final int current;
  const _BookingStepper({required this.current});
  @override
  Widget build(BuildContext context) {
    final steps = ['Movie', 'Showtime', 'Seats', 'Payment'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) return Expanded(child: Container(height: 1.5, color: AppColors.borderSoft));
        final idx = i ~/ 2;
        final done = idx < current;
        final active = idx == current;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (done || active) ? AppColors.primaryGradient : null,
                color: (!done && !active) ? AppColors.surface2 : null,
                border: (!done && !active) ? Border.all(color: AppColors.border) : null,
                boxShadow: active ? [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.3), blurRadius: 8)] : null,
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
            const SizedBox(width: 6),
            Text(steps[idx], style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? AppColors.text : done ? AppColors.muted : AppColors.muted2,
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
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: AppColors.muted2),
                  const SizedBox(height: 12),
                  Text(date == null ? 'Pick a date to see showtimes' : 'No showtimes for this date',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final st = filtered[i];
              return GestureDetector(
                onTap: () => context.push('/seats/${st.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      // Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(st.showTime, style: const TextStyle(
                            fontFamily: 'Space Grotesk', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent1,
                          )),
                          const SizedBox(height: 3),
                          Text(st.theaterName, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          Text('${st.screenName} · ${st.city}', style: TextStyle(color: AppColors.muted2, fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      // Price & seats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${st.basePrice.toInt()}', style: const TextStyle(
                            fontFamily: 'Space Grotesk', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.success,
                          )),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text('${st.availableSeats} seats', style: TextStyle(
                              color: AppColors.success, fontSize: 10.5, fontWeight: FontWeight.w600,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: AppColors.muted2, size: 22),
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
        child: Center(child: Text('Failed to load', style: TextStyle(color: AppColors.error))),
      ),
    );
  }
}
