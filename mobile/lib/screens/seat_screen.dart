import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
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
        title: const Text('Select Seats', style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Stepper
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _BookingStepper(current: 2),
          ),
          // Seat area
          Expanded(
            child: seatMapAsync.when(
              data: (seatMap) => _SeatGrid(seatMap: seatMap),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent1)),
              error: (_, __) => const Center(child: Text('Failed to load seats', style: TextStyle(color: AppColors.error))),
            ),
          ),
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend(AppColors.accent1, 'Selected'),
                const SizedBox(width: 16),
                _legend(AppColors.success, 'Available'),
                const SizedBox(width: 16),
                _legend(AppColors.muted2, 'Occupied'),
                const SizedBox(width: 16),
                _legend(AppColors.surface3, 'Blocked'),
              ],
            ),
          ),
          // Booking bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.borderSoft)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selected.isEmpty ? 'No seats selected' : '${selected.length} seat(s)',
                        style: TextStyle(color: selected.isEmpty ? AppColors.muted : AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (selected.isNotEmpty)
                        Text(
                          selected.join(', '),
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty ? null : () => context.push('/payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent1,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surface2,
                    disabledForegroundColor: AppColors.muted2,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    selected.isEmpty ? 'Select seats' : 'Pay ₹${selected.length * 150}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
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
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (done || active) ? AppColors.primaryGradient : null,
                color: (!done && !active) ? AppColors.surface2 : null,
                border: (!done && !active) ? Border.all(color: AppColors.border) : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.muted)),
              ),
            ),
            const SizedBox(width: 4),
            Text(steps[idx], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.text : AppColors.muted2)),
          ],
        );
      }),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Screen with glow
          SizedBox(
            width: 220,
            child: Column(
              children: [
                Container(
                  width: 220, height: 6,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)],
                  ),
                ),
                const SizedBox(height: 2),
                Text('SCREEN', style: TextStyle(color: AppColors.muted2, fontSize: 9, letterSpacing: 0.2, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Column numbers
          if (rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                children: List.generate(rows[0].length, (c) => Expanded(
                  child: Center(child: Text('${c + 1}', style: TextStyle(color: AppColors.muted2, fontSize: 9.5, fontWeight: FontWeight.w600))),
                )),
              ),
            ),
          const SizedBox(height: 8),
          // Seats
          ...List.generate(rows.length, (r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + r),
                        style: TextStyle(color: AppColors.muted2, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
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
                            ref.read(selectedSeatsProvider.notifier).state =
                                isSelected ? current.where((s) => s != seatId).toList() : [...current, seatId];
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent1
                                  : isOccupied ? AppColors.muted2 : isBlocked ? AppColors.surface3 : AppColors.success,
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: isSelected ? [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.35), blurRadius: 8)] : null,
                            ),
                            child: Center(
                              child: Text(
                                isOccupied ? '✕' : isBlocked ? '·' : seatId,
                                style: TextStyle(
                                  color: isSelected || isOccupied ? Colors.white : AppColors.background,
                                  fontSize: 10, fontWeight: FontWeight.w700,
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
