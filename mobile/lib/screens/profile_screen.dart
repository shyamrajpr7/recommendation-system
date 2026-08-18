import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/app_dimens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _avatarController;
  late Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _avatarScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeOutBack),
    );
    _avatarController.forward();
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineMedium)
            .animate().fadeIn(duration: 400.ms)
            .slideX(begin: -0.05, end: 0),
        const SizedBox(height: AppSpacing.xxxl),
        // Avatar
        Center(
          child: ScaleTransition(
            scale: _avatarScale,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent1.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, size: 48, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Name
        Center(
          child: Text(
            'Guest User',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'guest@cineread.app',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxxl),
        // Stats
        Row(
          children: [
            Expanded(child: _buildStat('Bookings', '12', Icons.confirmation_number_rounded, 0)),
            const SizedBox(width: 12),
            Expanded(child: _buildStat('Favorites', '8', Icons.favorite_rounded, 100)),
            const SizedBox(width: 12),
            Expanded(child: _buildStat('Reviews', '24', Icons.rate_review_rounded, 200)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        // Action items
        _buildActionTile(Icons.edit_rounded, 'Edit Profile', 'Update your information'),
        const SizedBox(height: AppSpacing.md),
        _buildActionTile(Icons.notifications_rounded, 'Notifications', 'Manage alerts'),
        const SizedBox(height: AppSpacing.md),
        _buildActionTile(Icons.help_rounded, 'Help & Support', 'Get assistance'),
        const SizedBox(height: AppSpacing.md),
        _buildActionTile(Icons.info_outline_rounded, 'About', 'CineRead v1.0.0'),
        const SizedBox(height: AppSpacing.xxxl),
        // Logout
        SizedBox(
          width: double.infinity,
          height: AppDimens.buttonHeight,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
            ),
            child: const Text('Log out'),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildStat(String label, String value, IconData icon, int delayMs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.accent1),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 300 + delayMs), duration: 400.ms)
        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 300 + delayMs), duration: 400.ms);
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Icon(icon, size: 20, color: AppColors.accent1),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.muted),
        ],
      ),
    );
  }
}
