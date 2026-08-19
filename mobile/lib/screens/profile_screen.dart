import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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

  final _activities = const [
    ('Booked', 'Inception - 2 days ago', Icons.confirmation_number_rounded, AppColors.accent1),
    ('Favorited', 'Interstellar - 5 days ago', Icons.favorite_rounded, AppColors.error),
    ('Reviewed', 'The Dark Knight - 1 week ago', Icons.rate_review_rounded, AppColors.gold),
    ('Searched', 'Sci-fi movies - 1 week ago', Icons.search_rounded, AppColors.accent2),
  ];

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
        // Avatar with edit overlay
        Center(
          child: ScaleTransition(
            scale: _avatarScale,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Photo picker coming soon'), duration: Duration(seconds: 1)),
                );
              },
              child: Stack(
                children: [
                  Container(
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
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSoft, width: 2),
                      ),
                      child: Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.accent1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text('Guest User', style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 4),
        Center(
          child: Text('guest@cineread.app', style: TextStyle(color: AppColors.muted, fontSize: 14)),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 8),
        // Membership badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.gold.withValues(alpha: 0.15), AppColors.gold.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Text('Gold Member since 2024', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
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
        const SizedBox(height: AppSpacing.xxl),
        // Activity timeline
        Text('Recent Activity', style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 12),
        ...List.generate(_activities.length, (i) {
          final a = _activities[i];
          return _buildActivityTile(a.$1, a.$2, a.$3, a.$4, i);
        }),
        const SizedBox(height: AppSpacing.xxl),
        // Action items
        _buildActionTile(Icons.edit_rounded, 'Edit Profile', 'Update your information', () {}),
        const SizedBox(height: AppSpacing.md),
        _buildActionTile(Icons.notifications_rounded, 'Notifications', 'Manage alerts', () => context.go('/settings')),
        const SizedBox(height: AppSpacing.md),
        _buildActionTile(Icons.help_rounded, 'Help & Support', 'Get assistance', () {}),
        const SizedBox(height: AppSpacing.md),
        _buildActionTile(Icons.info_outline_rounded, 'About', 'CineRead v1.0.0', () {}),
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

  Widget _buildActivityTile(String action, String detail, IconData icon, Color color, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (index < _activities.length - 1)
                Container(width: 1.5, height: 16, color: AppColors.borderSoft),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(detail, style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 400 + index * 80), duration: 400.ms);
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
          Text(value, style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 300 + delayMs), duration: 400.ms)
        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 300 + delayMs), duration: 400.ms);
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
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
      ),
    );
  }
}
