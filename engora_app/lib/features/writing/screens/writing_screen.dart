import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/writing_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WritingPrompt? _selectedPrompt;
  bool _showFeedback = false;
  final TextEditingController _freeWritingController = TextEditingController();
  final TextEditingController _guidedWritingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WritingProvider>().loadPrompts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _freeWritingController.dispose();
    _guidedWritingController.dispose();
    super.dispose();
  }

  Future<void> _submitWriting(bool isGuided) async {
    final writing = context.read<WritingProvider>();
    final text = isGuided
        ? _guidedWritingController.text
        : _freeWritingController.text;

    if (text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write more before submitting')),
      );
      return;
    }

    final feedback = await writing.submitWriting(
      text: text,
      promptText: isGuided
          ? (_selectedPrompt?.title ?? 'Guided Writing')
          : 'Free Writing',
      promptId: isGuided ? _selectedPrompt?.id : null,
    );

    if (feedback != null && mounted) {
      setState(() => _showFeedback = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final writing = context.watch<WritingProvider>();

    if (_showFeedback && writing.currentFeedback != null) {
      return _WritingFeedbackScreen(
        originalText: _tabController.index == 1
            ? _guidedWritingController.text
            : _freeWritingController.text,
        feedback: writing.currentFeedback!,
        onDone: () {
          writing.clearFeedback();
          setState(() => _showFeedback = false);
          Navigator.of(context).pop();
        },
        onWriteAgain: () {
          writing.clearFeedback();
          setState(() {
            _showFeedback = false;
            _freeWritingController.clear();
            _guidedWritingController.clear();
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Practice'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Free Writing'),
            Tab(text: 'Guided Writing'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Free Writing tab
          _FreeWritingTab(
            controller: _freeWritingController,
            submitting: writing.submitting,
            onSubmit: () => _submitWriting(false),
          ),
          // Guided Writing tab
          _GuidedWritingTab(
            prompts: writing.prompts,
            selectedPrompt: _selectedPrompt,
            controller: _guidedWritingController,
            loading: writing.loading,
            submitting: writing.submitting,
            onSelectPrompt: (p) => setState(() => _selectedPrompt = p),
            onSubmit: () => _submitWriting(true),
          ),
        ],
      ),
    );
  }
}

class _FreeWritingTab extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  const _FreeWritingTab({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.writing.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.writing.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('✍️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Free Writing',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.writing,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Write anything in English. AI will analyze and correct it.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.writing.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Start writing here... You can write about anything: your day, your thoughts, a story...',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: AppColors.writing, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: AppButton(
            label: 'Submit for AI Review',
            loading: submitting,
            width: double.infinity,
            onPressed: onSubmit,
          ),
        ),
      ],
    );
  }
}

class _GuidedWritingTab extends StatelessWidget {
  final List<WritingPrompt> prompts;
  final WritingPrompt? selectedPrompt;
  final TextEditingController controller;
  final bool loading;
  final bool submitting;
  final ValueChanged<WritingPrompt> onSelectPrompt;
  final VoidCallback onSubmit;

  const _GuidedWritingTab({
    required this.prompts,
    required this.selectedPrompt,
    required this.controller,
    required this.loading,
    required this.submitting,
    required this.onSelectPrompt,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPrompt == null) {
      // Show prompt selection
      return loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Choose a Writing Topic',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a topic and write based on the guide',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ...prompts.map((p) => _PromptCard(
                      prompt: p,
                      onTap: () => onSelectPrompt(p),
                    )),
              ],
            );
    }

    // Writing area with selected prompt
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prompt header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.writing.withOpacity(0.15),
                        AppColors.writing.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.writing.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            selectedPrompt!.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.writing,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.writing.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedPrompt!.level,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.writing,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedPrompt!.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (selectedPrompt!.guidePoints != null) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 10),
                        ...selectedPrompt!.guidePoints!.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.writing,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Write your response here...',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: AppColors.writing, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: AppButton(
            label: 'Submit for AI Review',
            loading: submitting,
            width: double.infinity,
            onPressed: onSubmit,
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  final WritingPrompt prompt;
  final VoidCallback onTap;

  const _PromptCard({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prompt.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.writing.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      prompt.level,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.writing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _WritingFeedbackScreen extends StatelessWidget {
  final String originalText;
  final WritingFeedback feedback;
  final VoidCallback onDone;
  final VoidCallback onWriteAgain;

  const _WritingFeedbackScreen({
    required this.originalText,
    required this.feedback,
    required this.onDone,
    required this.onWriteAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Writing Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score overview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _scoreColor(feedback.overallScore),
                    _scoreColor(feedback.overallScore).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${feedback.overallScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Overall Score',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MiniScore(label: 'Grammar', score: feedback.grammarScore),
                      _MiniScore(label: 'Vocab', score: feedback.vocabularyScore),
                      _MiniScore(label: 'Clarity', score: feedback.clarityScore),
                      _MiniScore(label: 'Spelling', score: feedback.spellingScore),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Summary
            Text('📝 Feedback', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(feedback.summary),
            ),
            const SizedBox(height: 24),

            // Corrected text
            if (feedback.correctedText.isNotEmpty &&
                feedback.correctedText != originalText) ...[
              Text('✅ Corrected Version',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feedback.correctedText,
                  style: const TextStyle(height: 1.6),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Corrections
            if (feedback.corrections.isNotEmpty) ...[
              Text('✏️ Corrections',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...feedback.corrections.take(6).map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['original'] ?? '',
                          style: const TextStyle(
                            color: AppColors.error,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['corrected'] ?? '',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((c['explanation'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            c['explanation'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // New vocabulary
            if (feedback.newVocabulary.isNotEmpty) ...[
              Text('📖 New Vocabulary',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: feedback.newVocabulary
                    .map((w) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.vocabulary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.vocabulary.withOpacity(0.3)),
                          ),
                          child: Text(
                            w,
                            style: const TextStyle(
                              color: AppColors.vocabulary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            AppButton(
              label: 'Write Again',
              onPressed: onWriteAgain,
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

class _MiniScore extends StatelessWidget {
  final String label;
  final int score;

  const _MiniScore({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
