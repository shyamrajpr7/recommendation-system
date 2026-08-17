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
  final _focus = FocusNode();
  BookingResponse? _booking;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _refCtrl.dispose(); _focus.dispose(); super.dispose(); }

  Future<void> _lookup() async {
    final refStr = _refCtrl.text.trim();
    if (refStr.isEmpty) return;
    _focus.unfocus();
    setState(() { _loading = true; _error = null; _booking = null; });
    try {
      final result = await ref.read(cinemaServiceProvider).fetchBooking(refStr);
      _booking = result;
    } catch (e) {
      _error = 'Booking not found. Please check your reference.';
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.confirmation_number_outlined, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('My Bookings', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Look up a booking by reference', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: AppSpacing.xxl),

        // Search card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('🎫 Find your e-ticket', style: TextStyle(color: AppColors.accent1, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Enter the booking reference you received at checkout',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Icon(Icons.search_rounded, size: 18, color: AppColors.muted2),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _refCtrl,
                        focusNode: _focus,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _lookup(),
                        decoration: InputDecoration(
                          hintText: 'e.g. CINE7PN9N8',
                          hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: _loading ? null : _lookup,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _loading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Error
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13))),
            ]),
          ),

        // Ticket
        if (_booking != null) _TicketWidget(booking: _booking!),

        // Empty state
        if (_booking == null && _error == null && !_loading)
          _emptyState(),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent1.withValues(alpha: 0.08), AppColors.accent2.withValues(alpha: 0.08)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.confirmation_number_outlined, size: 44, color: AppColors.accent1),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No ticket yet?', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Complete a booking and your e-ticket will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent3.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent1.withValues(alpha: 0.1), AppColors.accent2.withValues(alpha: 0.1)],
            ),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🎬 CINEREAD', style: TextStyle(
                color: AppColors.accent1, fontWeight: FontWeight.w700, fontSize: 14,
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Text(booking.bookingRef, style: TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12,
                )),
              ),
            ],
          ),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.movieTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('${booking.movieGenre} · ${booking.theaterName} (${booking.city})',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 18),
              _row('SCREEN', booking.screenName, 'SHOW', '${booking.showDate}\n${booking.showTime}'),
              const SizedBox(height: 14),
              _row('SEATS', booking.seats.join(', '), 'AMOUNT', '₹${booking.totalAmount.toInt()}'),
              const SizedBox(height: 14),
              _row('PAYMENT', booking.paymentStatus.toUpperCase(), 'STATUS', booking.status.toUpperCase()),
            ],
          ),
        ),
        // Barcode
        Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          padding: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12), style: BorderStyle.solid)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white70, Colors.transparent, Colors.white70, Colors.transparent, Colors.white70],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('KEEP THIS REFERENCE', style: TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
                  Text(booking.bookingRef, style: TextStyle(color: AppColors.muted2, fontSize: 8)),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _row(String l1, String v1, String l2, String v2) {
    return Row(
      children: [
        _info(l1, v1),
        const SizedBox(width: 20),
        _info(l2, v2),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.muted2, fontSize: 9, letterSpacing: 0.12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
        ],
      ),
    );
  }
}
