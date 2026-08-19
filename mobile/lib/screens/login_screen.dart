import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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
                Text('CineRead',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700))
                    .animate().fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.xs),
                Text('AI-powered cinema booking',
                    style: TextStyle(color: AppColors.muted, fontSize: 13))
                    .animate().fadeIn(delay: 150.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.section),
                AppTextField(
                  controller: _emailCtrl,
                  hintText: 'Email address',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideX(begin: 0.05, end: 0, delay: 200.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _passwordCtrl,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_rounded,
                  suffixIcon: _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  obscureText: _obscurePassword,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideX(begin: 0.05, end: 0, delay: 250.ms, duration: 400.ms),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot password?', style: TextStyle(color: AppColors.accent1, fontSize: 13)),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                AppButton(
                  label: 'Sign in',
                  loading: _loading,
                  style: AppButtonStyle.gradient,
                  onPressed: _submit,
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, delay: 350.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  const Expanded(child: Divider(color: AppColors.borderSoft)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text('or', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderSoft)),
                ]).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  style: AppButtonStyle.outlined,
                  onPressed: () {},
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text("Don't have an account? Sign up"),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
