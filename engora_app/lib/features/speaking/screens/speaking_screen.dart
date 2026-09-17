import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/speaking_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showFeedback = false;

  // Situation options
  final List<Map<String, dynamic>> _situations = const [
    {'label': 'Daily Conversation', 'icon': '💬', 'value': 'Daily Conversation'},
    {'label': 'Job Interview', 'icon': '🎯', 'value': 'Job Interview'},
    {'label': 'Travel', 'icon': '✈️', 'value': 'Travel'},
    {'label': 'Workplace', 'icon': '💼', 'value': 'Workplace'},
    {'label': 'Restaurant', 'icon': '🍽️', 'value': 'Restaurant'},
    {'label': 'Making Friends', 'icon': '🤝', 'value': 'Making Friends'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await context.read<SpeakingProvider>().sendTextMessage(text);
    _scrollToBottom();
  }

  Future<void> _endSession() async {
    final speaking = context.read<SpeakingProvider>();
    final feedback = await speaking.endSession();
    if (feedback != null && mounted) {
      setState(() => _showFeedback = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speaking = context.watch<SpeakingProvider>();

    if (_showFeedback && speaking.feedback != null) {
      return _FeedbackScreen(
        feedback: speaking.feedback!,
        onDone: () {
          speaking.reset();
          Navigator.of(context).pop();
        },
        onPracticeAgain: () {
          setState(() => _showFeedback = false);
          speaking.reset();
        },
      );
    }

    if (!speaking.hasSession) {
      return _SituationPickerScreen(
        situations: _situations,
        onStart: (situation) async {
          await speaking.startSession(situation: situation);
          _scrollToBottom();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Speaking Practice'),
        actions: [
          TextButton(
            onPressed: speaking.loading ? null : _endSession,
            child: const Text('End & Review'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: speaking.messages.length,
              itemBuilder: (_, i) {
                final msg = speaking.messages[i];
                return _MessageBubble(
                  message: msg.content,
                  isUser: msg.role == 'user',
                );
              },
            ),
          ),

          if (speaking.state == SpeakingState.processing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('AI is thinking...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),

          // Input area
          _InputBar(
            controller: _textController,
            onSend: _sendMessage,
            enabled: !speaking.loading && speaking.state != SpeakingState.processing,
          ),
        ],
      ),
    );
  }
}

class _SituationPickerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> situations;
  final Future<void> Function(String) onStart;

  const _SituationPickerScreen({
    required this.situations,
    required this.onStart,
  });

  @override
  State<_SituationPickerScreen> createState() => _SituationPickerScreenState();
}

class _SituationPickerScreenState extends State<_SituationPickerScreen> {
  String? _selected;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speaking Practice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎤', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Choose a Situation',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Practice English in real-life scenarios',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: widget.situations.length,
              itemBuilder: (_, i) {
                final s = widget.situations[i];
                final isSelected = _selected == s['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selected = s['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.speaking.withOpacity(0.1)
                          : AppColors.surface,
                      border: Border.all(
                        color: isSelected ? AppColors.speaking : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s['icon'], style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          s['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected
                                ? AppColors.speaking
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Start Conversation',
              loading: _loading,
              width: double.infinity,
              onPressed: _selected == null
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await widget.onStart(_selected!);
                      if (mounted) setState(() => _loading = false);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _MessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: AppColors.primary, size: 18),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type your response...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackScreen extends StatelessWidget {
  final Map<String, dynamic> feedback;
  final VoidCallback onDone;
  final VoidCallback onPracticeAgain;

  const _FeedbackScreen({
    required this.feedback,
    required this.onDone,
    required this.onPracticeAgain,
  });

  @override
  Widget build(BuildContext context) {
    final score = feedback['overallScore'] as int? ?? 0;
    final corrections =
        feedback['corrections'] as List<dynamic>? ?? [];
    final strengths = feedback['strengths'] as List<dynamic>? ?? [];
    final improvements = feedback['improvements'] as List<dynamic>? ?? [];
    final summary = feedback['summary'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Session Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_scoreColor(score), _scoreColor(score).withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Overall Score',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ScoreChip(
                          label: 'Grammar',
                          score: feedback['grammarScore'] as int? ?? 0),
                      _ScoreChip(
                          label: 'Vocab',
                          score: feedback['vocabularyScore'] as int? ?? 0),
                      _ScoreChip(
                          label: 'Fluency',
                          score: feedback['fluencyScore'] as int? ?? 0),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Summary
            if (summary.isNotEmpty) ...[
              Text('📝 Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(summary, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(height: 24),
            ],

            // Corrections
            if (corrections.isNotEmpty) ...[
              Text('✏️ Corrections', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...corrections.take(5).map((c) {
                final correction = c as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.close, color: AppColors.error, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              correction['original'] ?? '',
                              style: const TextStyle(
                                color: AppColors.error,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check, color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              correction['corrected'] ?? '',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((correction['explanation'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          correction['explanation'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Strengths
            if (strengths.isNotEmpty) ...[
              Text('💪 Strengths', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...strengths.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.toString())),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Improvements
            if (improvements.isNotEmpty) ...[
              Text('🎯 To Improve', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...improvements.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, color: AppColors.primary, size: 20),
                        const SizedBox(width: 4),
                        Expanded(child: Text(s.toString())),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
            ],

            AppButton(
              label: 'Practice Again',
              onPressed: onPracticeAgain,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Done',
              onPressed: onDone,
              outlined: true,
              width: double.infinity,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    return AppColors.warning;
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreChip({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
