import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../models/cinema.dart';
import '../services/cinema_service.dart';
import 'seat_screen.dart';

final bookingResultProvider = StateProvider<BookingResponse?>((ref) => null);

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedSeatsProvider);
    final bookingResult = ref.watch(bookingResultProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Payment', style: TextStyle(fontFamily: 'Space Grotesk')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          // Stepper
          Row(
            children: [
              _step(0, 'Movie', true),
              _line(),
              _step(1, 'Showtime', true),
              _line(),
              _step(2, 'Seats', true),
              _line(),
              _step(3, 'Payment', false),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          if (bookingResult == null) ...[
            // Booking form
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confirm Booking', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Text('Seats: ${selected.join(', ')}', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'Your name'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Your email'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _book,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('💳 Proceed to payment'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Ticket
            _TicketWidget(booking: bookingResult),
            const SizedBox(height: AppSpacing.xl),
            if (bookingResult.paymentMock)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verify,
                  child: const Text('✅ Simulate payment & confirm'),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(bookingResultProvider.notifier).state = null;
                  ref.read(selectedSeatsProvider.notifier).state = [];
                  context.go('/home');
                },
                child: const Text('🎟️ Book another movie'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step(int idx, String label, bool done) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done ? AppColors.primaryGradient : null,
            color: !done ? AppColors.surface2 : null,
            border: !done ? Border.all(color: AppColors.border) : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: done ? AppColors.text : AppColors.muted2)),
      ],
    );
  }

  Widget _line() => Expanded(child: Container(height: 1, color: AppColors.borderSoft));

  Future<void> _book() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter name and email');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      // TODO: get showtime_id from state
      final result = await ref.read(cinemaServiceProvider).createBooking(
        showtimeId: 1,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        seats: ref.read(selectedSeatsProvider),
      );
      ref.read(bookingResultProvider.notifier).state = result;
    } catch (e) {
      setState(() { _error = 'Booking failed: $e'; _loading = false; });
    }
  }

  Future<void> _verify() async {
    final booking = ref.read(bookingResultProvider);
    if (booking == null) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(cinemaServiceProvider).verifyPayment(booking.bookingRef);
      if (result.status == 'confirmed') {
        ref.read(bookingResultProvider.notifier).state = BookingResponse(
          bookingRef: booking.bookingRef, movieTitle: booking.movieTitle,
          movieGenre: booking.movieGenre, theaterName: booking.theaterName,
          screenName: booking.screenName, city: booking.city,
          showDate: booking.showDate, showTime: booking.showTime,
          seats: booking.seats, totalAmount: booking.totalAmount,
          status: 'confirmed', paymentStatus: 'paid',
          paymentMock: false, paymentEnabled: false,
        );
      }
    } catch (e) {
      setState(() => _error = 'Verification failed: $e');
    }
    setState(() => _loading = false);
  }
}

class _TicketWidget extends StatelessWidget {
  final BookingResponse booking;
  const _TicketWidget({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF101A30), Color(0xFF0B1323)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent3.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🎬 CINEREAD', style: TextStyle(color: AppColors.accent1, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(booking.bookingRef, style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.movieTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${booking.movieGenre} · ${booking.theaterName} (${booking.city})',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _infoBlock('Screen', booking.screenName),
                    _infoBlock('Show', '${booking.showDate}\n${booking.showTime}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoBlock('Seats', booking.seats.join(', ')),
                    _infoBlock('Amount', '₹${booking.totalAmount.toInt()}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoBlock('Payment', booking.paymentStatus),
                    _infoBlock('Status', booking.status.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
          // Stub with barcode
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), style: BorderStyle.solid)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white70, Colors.transparent, Colors.white70, Colors.transparent, Colors.white70],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('KEEP THIS REFERENCE', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: AppColors.muted2, fontSize: 9, letterSpacing: 0.1)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
