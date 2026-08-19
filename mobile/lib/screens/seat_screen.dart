import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../models/cinema.dart';
import '../services/cinema_service.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/app_button.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: const BookingStepper(current: 2),
          ),
          Expanded(
            child: seatMapAsync.when(
              data: (seatMap) => _SeatGrid(seatMap: seatMap),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent1)),
              error: (_, __) => const Center(child: Text('Failed to load seats', style: TextStyle(color: AppColors.error))),
            ),
          ),
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
                AppButton(
                  label: selected.isEmpty ? 'Select seats' : 'Pay \u20B9${selected.length * 150}',
                  style: AppButtonStyle.gradient,
                  fullWidth: false,
                  onPressed: selected.isEmpty ? null : () => context.push('/payment'),
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

class _SeatGrid extends ConsumerWidget {
  final SeatMap seatMap;
  const _SeatGrid({required this.seatMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSeatsProvider);
    final rows = seatMap.seats;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            // Curved screen indicator
            SizedBox(
              width: 260,
              height: 50,
              child: CustomPaint(
                painter: _ScreenPainter(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('SCREEN', style: TextStyle(color: AppColors.muted2, fontSize: 9, letterSpacing: 0.2, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                      final isBlocked = seat == '\u00B7' || seat == '-';
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
                            child: Tooltip(
                              message: isOccupied
                                  ? '$seatId - Occupied'
                                  : isBlocked
                                      ? '$seatId - Blocked'
                                      : '$seatId - Available',
                              preferBelow: false,
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
                                    isOccupied ? '\u2715' : isBlocked ? '\u00B7' : seatId,
                                    style: TextStyle(
                                      color: isSelected || isOccupied ? Colors.white : AppColors.background,
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                    ),
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
      ),
    );
  }
}

class _ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accent1, AppColors.accent2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 20))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height);

    canvas.drawPath(path, paint);

    // Glow effect
    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.accent1.withValues(alpha: 0.3), AppColors.accent2.withValues(alpha: 0.3)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 20))
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
