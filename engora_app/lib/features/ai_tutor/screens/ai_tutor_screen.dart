import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/ai_tutor_provider.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(AiTutorProvider tutor, String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    _focusNode.requestFocus();
    await tutor.sendMessage(text.trim());
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Tutor',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Personal English Coach',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        actions: [
          Consumer<AiTutorProvider>(
            builder: (_, tutor, __) => tutor.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Clear conversation',
                    onPressed: () => _confirmClear(context, tutor),
                  ),
          ),
        ],
      ),
      body: Consumer<AiTutorProvider>(
        builder: (context, tutor, _) {
          return Column(
            children: [
              Expanded(
                child: tutor.isEmpty
                    ? _WelcomeView(
                        onSuggestionTap: (text) => _send(tutor, text))
                    : _ChatView(
                        tutor: tutor,
                        scrollController: _scrollController,
                      ),
              ),
              _InputBar(
                controller: _inputController,
                focusNode: _focusNode,
                loading: tutor.loading,
                onSend: (text) => _send(tutor, text),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context, AiTutorProvider tutor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Conversation'),
        content: const Text(
            'This will delete the entire conversation. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              tutor.clearConversation();
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome / Empty state ───────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  final void Function(String) onSuggestionTap;

  const _WelcomeView({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi! I\'m your AI Tutor',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ask me anything about English — grammar, vocabulary, pronunciation, or just chat!',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Capabilities
          _SectionTitle(title: 'What I can do'),
          const SizedBox(height: 12),
          _CapabilityRow(
            icon: '💬',
            title: 'Free Conversation',
            subtitle: 'Chat about any topic in English',
          ),
          _CapabilityRow(
            icon: '❓',
            title: 'Ask Anything',
            subtitle: 'Grammar rules, vocab differences, expressions',
          ),
          _CapabilityRow(
            icon: '✏️',
            title: 'Sentence Correction',
            subtitle: 'Type a sentence and I\'ll fix it',
          ),
          _CapabilityRow(
            icon: '📖',
            title: 'Grammar Explanation',
            subtitle: 'Level-appropriate explanations',
          ),

          const SizedBox(height: 28),
          _SectionTitle(title: 'Quick Start'),
          const SizedBox(height: 12),
          ...AiTutorProvider.suggestions.map((s) => _SuggestionTile(
                icon: s['icon']!,
                text: s['text']!,
                onTap: () => onSuggestionTap(s['text']!),
              )),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _CapabilityRow(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback onTap;

  const _SuggestionTile(
      {required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chat View ───────────────────────────────────────────────────────────────

class _ChatView extends StatelessWidget {
  final AiTutorProvider tutor;
  final ScrollController scrollController;

  const _ChatView(
      {required this.tutor, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: tutor.messages.length + (tutor.loading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == tutor.messages.length) {
          return _TypingIndicator();
        }
        final msg = tutor.messages[i];
        return _MessageBubble(message: msg);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TutorMessage message;

  const _MessageBubble({required this.message});

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      Radius.circular(_isUser ? 18 : 4),
                  bottomRight:
                      Radius.circular(_isUser ? 4 : 18),
                ),
                border: _isUser
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: _isUser
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (_isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceVariant,
              child:
                  Icon(Icons.person, color: AppColors.textSecondary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 150),
                const SizedBox(width: 4),
                _Dot(delay: 300),
              ],
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
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.textHint,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Input Bar ───────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final void Function(String) onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              onSubmitted: loading ? null : onSend,
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: loading
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary),
                    ),
                  )
                : FilledButton(
                    onPressed: () => onSend(controller.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(44, 44),
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.send, size: 20),
                  ),
          ),
        ],
      ),
    );
  }
}

