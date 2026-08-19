import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/app_dimens.dart';
import '../models/cinema.dart';
import '../services/cinema_service.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import 'seat_screen.dart';

final bookingResultProvider = StateProvider<BookingResponse?>((ref) => null);

enum _PaymentMethod { upi, card, wallet }

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  _PaymentMethod _paymentMethod = _PaymentMethod.upi;

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
        title: const Text('Payment', style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BookingStepper(current: 3),
          const SizedBox(height: 24),

          if (bookingResult == null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent1.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Confirm Booking', style: TextStyle(color: AppColors.accent1, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_seat_rounded, size: 18, color: AppColors.accent1),
                          const SizedBox(width: 8),
                          Text('${selected.length} seat(s): ${selected.join(', ')}',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _nameCtrl,
                      hintText: 'Your name',
                      prefixIcon: Icons.person_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _emailCtrl,
                      hintText: 'Your email',
                      prefixIcon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('Payment Method', style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _paymentOption(_PaymentMethod.upi, Icons.qr_code_rounded, 'UPI'),
                        const SizedBox(width: 10),
                        _paymentOption(_PaymentMethod.card, Icons.credit_card_rounded, 'Card'),
                        const SizedBox(width: 10),
                        _paymentOption(_PaymentMethod.wallet, Icons.account_balance_wallet_rounded, 'Wallet'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    AppButton(
                      label: 'Proceed to payment',
                      icon: Icons.payment_rounded,
                      style: AppButtonStyle.gradient,
                      loading: _loading,
                      onPressed: _book,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _ETicketWidget(booking: bookingResult),
            const SizedBox(height: 20),
            if (bookingResult.paymentMock && bookingResult.status != 'confirmed')
              AppButton(
                label: 'Simulate payment & confirm',
                icon: Icons.check_circle_rounded,
                style: AppButtonStyle.filled,
                color: AppColors.success,
                loading: _loading,
                onPressed: _verify,
              ),
            if (bookingResult.status == 'confirmed')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Your e-ticket is ready. Keep the booking reference for entry.',
                        style: TextStyle(color: AppColors.success, fontSize: 13))),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Book another movie',
              icon: Icons.movie_filter_rounded,
              style: AppButtonStyle.outlined,
              onPressed: () {
                ref.read(bookingResultProvider.notifier).state = null;
                ref.read(selectedSeatsProvider.notifier).state = [];
                context.go('/home');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentOption(_PaymentMethod method, IconData icon, String label) {
    final selected = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _paymentMethod = method);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.borderSoft,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: selected ? Colors.white : AppColors.muted),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontSize: 12, fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _book() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(cinemaServiceProvider).createBooking(
        showtimeId: 1,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        seats: ref.read(selectedSeatsProvider),
      );
      ref.read(bookingResultProvider.notifier).state = result;
    } catch (e) {
      setState(() {
        _error = 'Booking failed: $e';
        _loading = false;
      });
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

class _ETicketWidget extends StatelessWidget {
  final BookingResponse booking;
  const _ETicketWidget({required this.booking});

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
              Text('CINEREAD', style: TextStyle(
                fontFamily: 'Space Grotesk', color: AppColors.accent1, fontWeight: FontWeight.w700, fontSize: 14,
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(booking.bookingRef, style: TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12,
                )),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.movieTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('${booking.movieGenre} \u2022 ${booking.theaterName} (${booking.city})',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 18),
              _row('SCREEN', booking.screenName, 'SHOW', '${booking.showDate}\n${booking.showTime}'),
              const SizedBox(height: 14),
              _row('SEATS', booking.seats.join(', '), 'AMOUNT', '\u20B9${booking.totalAmount.toInt()}'),
              const SizedBox(height: 14),
              _row('PAYMENT', booking.paymentStatus.toUpperCase(), 'STATUS', booking.status.toUpperCase()),
            ],
          ),
        ),
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
                    gradient: const LinearGradient(
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
