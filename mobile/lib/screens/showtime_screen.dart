import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/app_dimens.dart';
import '../models/cinema.dart';
import '../services/cinema_service.dart';
import '../widgets/booking_stepper.dart';
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
                      const BookingStepper(current: 1),
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
                          height: 60,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: sel ? AppColors.primaryGradient : null,
                                      color: sel ? null : AppColors.surface2,
                                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                                      border: Border.all(color: sel ? Colors.transparent : AppColors.border),
                                      boxShadow: sel ? [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.25), blurRadius: 10)] : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(_dayOfWeek(d), style: TextStyle(
                                          color: sel ? Colors.white70 : AppColors.muted2,
                                          fontSize: 10, fontWeight: FontWeight.w600,
                                        )),
                                        const SizedBox(height: 2),
                                        Text('${_dayOfMonth(d)}', style: TextStyle(
                                          color: sel ? Colors.white : AppColors.text,
                                          fontSize: 16, fontWeight: FontWeight.w700,
                                        )),
                                        Text(_monthShort(d), style: TextStyle(
                                          color: sel ? Colors.white70 : AppColors.muted,
                                          fontSize: 10, fontWeight: FontWeight.w600,
                                        )),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        loading: () => const SizedBox(height: 60),
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

  String _dayOfWeek(String d) {
    try {
      final dt = DateTime.parse(d);
      final names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[dt.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  int _dayOfMonth(String d) {
    try {
      return DateTime.parse(d).day;
    } catch (_) {
      return 0;
    }
  }

  String _monthShort(String d) {
    try {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[DateTime.parse(d).month - 1];
    } catch (_) {
      return '';
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isEveningShow(st.showTime) ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                  size: 16,
                                  color: _isEveningShow(st.showTime) ? AppColors.accent2 : AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(st.showTime, style: const TextStyle(
                                  fontFamily: 'Space Grotesk', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent1,
                                )),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(st.theaterName, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                            Text('${st.screenName} \u2022 ${st.city}', style: TextStyle(color: AppColors.muted2, fontSize: 11)),
                          ],
                        ),
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

  bool _isEveningShow(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      return hour >= 16;
    } catch (_) {
      return false;
    }
  }
}
