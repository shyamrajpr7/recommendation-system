import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../models/cinema.dart';
import '../services/cinema_service.dart';

class MyBookingScreen extends ConsumerStatefulWidget {
  const MyBookingScreen({super.key});
  @override
  ConsumerState<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends ConsumerState<MyBookingScreen> {
  final _refCtrl = TextEditingController();
  BookingResponse? _booking;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _refCtrl.dispose(); super.dispose(); }

  Future<void> _lookup() async {
    final refStr = _refCtrl.text.trim();
    if (refStr.isEmpty) return;
    setState(() { _loading = true; _error = null; _booking = null; });
    try {
      final result = await ref.read(cinemaServiceProvider).fetchBooking(refStr);
      _booking = result;
    } catch (e) {
      _error = 'Booking not found';
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Text('My Bookings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('Look up a booking by reference', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: AppSpacing.xxl),
        // Search card
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
              Text('🎫 Find your e-ticket', style: TextStyle(color: AppColors.accent1, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: AppSpacing.sm),
              Text('Enter the booking reference you received at checkout', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _refCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. CINE7PN9N8'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _lookup,
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Check'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        if (_booking != null)
          _TicketWidget(booking: _booking!),
        if (_booking == null && _error == null && !_loading)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(children: [
              Icon(Icons.confirmation_number_outlined, size: 56, color: AppColors.muted2),
              const SizedBox(height: AppSpacing.md),
              Text('No ticket yet?', style: TextStyle(color: AppColors.muted)),
              Text('Complete a booking and your e-ticket will appear here',
                  style: TextStyle(color: AppColors.muted2, fontSize: 12)),
            ]),
          ),
      ],
    );
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
      child: Column(children: [
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
              Row(children: [
                _info('Screen', booking.screenName),
                _info('Show', '${booking.showDate}\n${booking.showTime}'),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _info('Seats', booking.seats.join(', ')),
                _info('Amount', '₹${booking.totalAmount.toInt()}'),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _info('Payment', booking.paymentStatus),
                _info('Status', booking.status.toUpperCase()),
              ]),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.white70, Colors.transparent, Colors.white70, Colors.transparent, Colors.white70]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('KEEP THIS REFERENCE', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  Widget _info(String label, String value) {
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
