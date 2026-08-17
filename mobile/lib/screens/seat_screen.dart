import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../models/cinema.dart';
import '../services/cinema_service.dart';

final seatMapProvider = FutureProvider.family<SeatMap, int>((ref, showtimeId) async {
  return ref.read(cinemaServiceProvider).fetchSeats(showtimeId);
});

final selectedSeatsProvider = StateProvider<List<String>>((ref) => []);

class SeatScreen extends ConsumerWidget {
  final int showtimeId;
  const SeatScreen({super.key, required this.showtimeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seatMapAsync = ref.watch(seatMapProvider(showtimeId));
    final selected = ref.watch(selectedSeatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Select Seats', style: TextStyle(fontFamily: 'Space Grotesk')),
      ),
      body: Column(
        children: [
          Expanded(
            child: seatMapAsync.when(
              data: (seatMap) => _SeatGrid(seatMap: seatMap),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent1)),
              error: (_, __) => const Center(child: Text('Failed to load seats', style: TextStyle(color: AppColors.error))),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.accent1, 'Selected'),
                const SizedBox(width: 16),
                _legendDot(AppColors.success, 'Available'),
                const SizedBox(width: 16),
                _legendDot(AppColors.muted2, 'Occupied'),
                const SizedBox(width: 16),
                _legendDot(AppColors.surface3, 'Blocked'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Booking bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selected.isEmpty ? 'No seats selected' : '${selected.length} seat(s): ${selected.join(', ')}',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty ? null : () => context.push('/payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent1,
                    disabledBackgroundColor: AppColors.surface2,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    selected.isEmpty ? 'Select seats' : 'Pay',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}

class _SeatGrid extends ConsumerWidget {
  final SeatMap seatMap;
  const _SeatGrid({required this.seatMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSeatsProvider);
    final rows = seatMap.seats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          // Screen indicator
          Container(
            width: 200, height: 4,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 4),
          Text('SCREEN', style: TextStyle(color: AppColors.muted2, fontSize: 10, letterSpacing: 0.15)),
          const SizedBox(height: AppSpacing.xxl),
          // Column numbers
          if (rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: List.generate(rows[0].length, (c) => Expanded(
                  child: Center(
                    child: Text('${c + 1}', style: TextStyle(color: AppColors.muted2, fontSize: 10)),
                  ),
                )),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          // Seat grid
          ...List.generate(rows.length, (r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  // Row letter
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + r),
                        style: TextStyle(color: AppColors.muted2, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  // Seats
                  ...List.generate(rows[r].length, (c) {
                    final seat = rows[r][c];
                    final seatId = '${String.fromCharCode(65 + r)}${c + 1}';
                    final isOccupied = seat == 'X';
                    final isBlocked = seat == '·' || seat == '-';
                    final isSelected = selected.contains(seatId);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: GestureDetector(
                          onTap: isOccupied || isBlocked ? null : () {
                            final current = ref.read(selectedSeatsProvider);
                            if (isSelected) {
                              ref.read(selectedSeatsProvider.notifier).state =
                                  current.where((s) => s != seatId).toList();
                            } else {
                              ref.read(selectedSeatsProvider.notifier).state = [...current, seatId];
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent1
                                  : isOccupied
                                      ? AppColors.muted2
                                      : isBlocked
                                          ? AppColors.surface3
                                          : AppColors.success,
                              borderRadius: BorderRadius.circular(6),
                              border: isSelected
                                  ? Border.all(color: AppColors.accent1, width: 1.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.3), blurRadius: 6)]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                isOccupied ? '✕' : isBlocked ? '·' : seatId,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : isOccupied ? AppColors.background : AppColors.background,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
