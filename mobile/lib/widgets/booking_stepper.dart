import 'package:flutter/material.dart';
import '../theme/colors.dart';

class BookingStepper extends StatelessWidget {
  final int current;
  const BookingStepper({super.key, required this.current});

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
              width: 28,
              height: 28,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.muted,
                      )),
              ),
            ),
            const SizedBox(width: 6),
            Text(steps[idx], style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.text : done ? AppColors.muted : AppColors.muted2,
            )),
          ],
        );
      }),
    );
  }
}
