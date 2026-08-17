import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

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

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
                  width: 72, height: 72,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.movie_filter_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Create account', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text('Start your cinema journey', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.section),
                TextFormField(
                  controller: _nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Full name'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
                  decoration: const InputDecoration(hintText: 'Email address'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  decoration: const InputDecoration(hintText: 'Password'),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Create account'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(onPressed: () => context.go('/login'), child: const Text('Already have an account? Sign in')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
