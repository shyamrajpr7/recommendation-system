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
  final _focus = FocusNode();
  bool _loading = false;

  @override
  void dispose() { _msgCtrl.dispose(); _focus.dispose(); super.dispose(); }

  void _fillSuggestion(String text) {
    _msgCtrl.text = text;
    _msgCtrl.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    _focus.requestFocus();
  }

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text('AI Concierge', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Ask about showtimes, movies, or booking help',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: history.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.md),
                  itemCount: history.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == history.length && _loading) return _typingIndicator();
                    final msg = history[i];
                    final isUser = msg['role'] == 'user';
                    return _chatBubble(msg['content'] ?? '', isUser);
                  },
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
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _focus,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask about showtimes...',
                      hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _msgCtrl.text.trim().isEmpty ? null : AppColors.primaryGradient,
                    color: _msgCtrl.text.trim().isEmpty ? AppColors.surface2 : null,
                  ),
                  child: Icon(
                    Icons.send_rounded, size: 20,
                    color: _msgCtrl.text.trim().isEmpty ? AppColors.muted2 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent1.withValues(alpha: 0.1), AppColors.accent2.withValues(alpha: 0.1)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.accent1),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Ask the concierge anything', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: AppSpacing.sm),
            Text('Showtimes, recommendations, or booking help', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip('🎬 what sci-fi is on tonight?'),
                _suggestionChip('🍿 best family movie today'),
                _suggestionChip('🕗 what time is Oppenheimer?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () => _fillSuggestion(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accent1.withValues(alpha: 0.08), AppColors.accent2.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.accent3.withValues(alpha: 0.2)),
        ),
        child: Text(text, style: TextStyle(color: AppColors.accent1, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _chatBubble(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.accent2, AppColors.accent3])),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(colors: [AppColors.accent1, AppColors.accent2])
                    : null,
                color: isUser ? null : AppColors.surface2,
                borderRadius: BorderRadius.circular(16),
                border: isUser ? null : Border.all(color: AppColors.borderSoft),
              ),
              child: Text(content, style: TextStyle(
                color: isUser ? Colors.white : AppColors.text,
                fontSize: 13, height: 1.55,
              )),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
              child: const Center(child: Text('🧑', style: TextStyle(fontSize: 14))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.accent2, AppColors.accent3])),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _Dot(delay: i * 200),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7, height: 7,
          decoration: BoxDecoration(color: AppColors.accent1, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
