import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  double _passwordStrength = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String value) {
    double strength = 0;
    if (value.length >= 6) strength += 0.25;
    if (value.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(value)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(value) || RegExp(r'[^A-Za-z0-9]').hasMatch(value)) strength += 0.25;
    setState(() => _passwordStrength = strength);
  }

  Color _strengthColor() {
    if (_passwordStrength <= 0.25) return AppColors.error;
    if (_passwordStrength <= 0.5) return AppColors.warning;
    if (_passwordStrength <= 0.75) return AppColors.gold;
    return AppColors.success;
  }

  String _strengthLabel() {
    if (_passwordStrength <= 0.25) return 'Weak';
    if (_passwordStrength <= 0.5) return 'Fair';
    if (_passwordStrength <= 0.75) return 'Good';
    return 'Strong';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.movie_filter_rounded, size: 36, color: Colors.white),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: AppSpacing.xxl),
                Text('Create account',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700))
                    .animate().fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.xs),
                Text('Start your cinema journey',
                    style: TextStyle(color: AppColors.muted, fontSize: 13))
                    .animate().fadeIn(delay: 150.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.section),
                AppTextField(
                  controller: _nameCtrl,
                  hintText: 'Full name',
                  prefixIcon: Icons.person_rounded,
                  keyboardType: TextInputType.name,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideX(begin: 0.05, end: 0, delay: 200.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _emailCtrl,
                  hintText: 'Email address',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideX(begin: 0.05, end: 0, delay: 250.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _passwordCtrl,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_rounded,
                  suffixIcon: _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  obscureText: _obscurePassword,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  onChanged: _updatePasswordStrength,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideX(begin: 0.05, end: 0, delay: 300.ms, duration: 400.ms),
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          backgroundColor: AppColors.surface3,
                          valueColor: AlwaysStoppedAnimation(_strengthColor()),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_strengthLabel(),
                        style: TextStyle(color: _strengthColor(), fontSize: 12, fontWeight: FontWeight.w600)),
                  ]).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                ],
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Create account',
                  loading: _loading,
                  style: AppButtonStyle.gradient,
                  onPressed: _submit,
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, delay: 350.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign in'),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text.rich(
                    TextSpan(
                      text: 'By signing up, you agree to our ',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(color: AppColors.accent1, fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(color: AppColors.accent1, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
