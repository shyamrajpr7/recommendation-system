import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../services/cinema_service.dart';

final chatHistoryProvider = StateProvider<List<Map<String, String>>>((ref) => []);

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});
  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _msgCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _loading) return;
    _msgCtrl.clear();

    final history = ref.read(chatHistoryProvider);
    ref.read(chatHistoryProvider.notifier).state = [...history, {'role': 'user', 'content': msg}];
    setState(() => _loading = true);

    try {
      final res = await ref.read(cinemaServiceProvider).chat(msg, history);
      final current = ref.read(chatHistoryProvider);
      ref.read(chatHistoryProvider.notifier).state = [...current, {'role': 'assistant', 'content': res.reply}];
    } catch (e) {
      final current = ref.read(chatHistoryProvider);
      ref.read(chatHistoryProvider.notifier).state = [...current, {'role': 'assistant', 'content': 'Error: $e'}];
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatHistoryProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Concierge', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('Ask about showtimes, movies, or booking help', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: history.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.muted2),
                    const SizedBox(height: AppSpacing.md),
                    Text('Ask the concierge anything', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: AppSpacing.xl),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _chip('🎬 what sci-fi is on tonight?'),
                        _chip('🍿 best family movie today'),
                        _chip('🕗 what time is Oppenheimer?'),
                      ],
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final msg = history[i];
                    final isUser = msg['role'] == 'user';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser)
                            Container(
                              width: 30, height: 30,
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.accent2, AppColors.accent3])),
                              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
                            ),
                          if (!isUser) const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppColors.accent1.withValues(alpha: 0.15)
                                    : AppColors.surface2,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isUser
                                      ? AppColors.accent1.withValues(alpha: 0.25)
                                      : AppColors.borderSoft,
                                ),
                              ),
                              child: Text(msg['content'] ?? '', style: TextStyle(
                                color: isUser ? Color(0xFFCFE8FF) : AppColors.text,
                                fontSize: 13, height: 1.55,
                              )),
                            ),
                          ),
                          if (isUser) const SizedBox(width: 8),
                          if (isUser)
                            Container(
                              width: 30, height: 30,
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                              child: const Center(child: Text('🧑', style: TextStyle(fontSize: 14))),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Loading indicator
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent1)),
              ),
            ),
          ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 8, AppSpacing.xxl, AppSpacing.xxl),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Ask about showtimes...'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                  child: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.accent1.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: AppColors.accent1, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
