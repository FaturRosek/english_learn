import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/grammar_provider.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GrammarProvider>().loadGrammar();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Grammar'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.grammar,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.grammar,
          tabs: const [
            Tab(text: 'Lessons'),
            Tab(text: 'Weaknesses'),
            Tab(text: 'Ask AI'),
          ],
        ),
      ),
      body: Consumer<GrammarProvider>(
        builder: (context, grammar, _) {
          if (grammar.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.grammar),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _LessonsTab(grammar: grammar),
              _WeaknessesTab(grammar: grammar),
              _AskAiTab(grammar: grammar),
            ],
          );
        },
      ),
    );
  }
}

// ─── Tab 1: Lessons ─────────────────────────────────────────────────────────

class _LessonsTab extends StatelessWidget {
  final GrammarProvider grammar;

  const _LessonsTab({required this.grammar});

  @override
  Widget build(BuildContext context) {
    const levels = ['all', 'A1', 'A2', 'B1', 'B2', 'C1'];

    return Column(
      children: [
        // Recommended banner
        if (grammar.recommendedLesson != null)
          _RecommendedBanner(lesson: grammar.recommendedLesson!),

        // Level filter
        Container(
          color: AppColors.surface,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: levels.map((lvl) {
                final selected = grammar.selectedLevel == lvl;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(lvl == 'all' ? 'All' : lvl),
                    selected: selected,
                    onSelected: (_) => grammar.setLevel(lvl),
                    selectedColor: AppColors.grammar.withOpacity(0.15),
                    checkmarkColor: AppColors.grammar,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.grammar
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Lesson list
        Expanded(
          child: grammar.lessons.isEmpty
              ? const Center(
                  child: Text('No lessons for this level yet.',
                      style:
                          TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: grammar.lessons.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (ctx, i) =>
                      _LessonCard(lesson: grammar.lessons[i]),
                ),
        ),
      ],
    );
  }
}

class _RecommendedBanner extends StatelessWidget {
  final GrammarLesson lesson;

  const _RecommendedBanner({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.grammar, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recommended for you',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(lesson.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(lesson.level,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final GrammarLesson lesson;

  const _LessonCard({required this.lesson});

  Color get _levelColor {
    switch (lesson.level) {
      case 'A1':
      case 'A2':
        return AppColors.success;
      case 'B1':
      case 'B2':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showLessonDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.grammar.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_outlined,
                    color: AppColors.grammar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _LevelBadge(
                            level: lesson.level,
                            color: _levelColor),
                        const SizedBox(width: 8),
                        Text(lesson.category,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (lesson.completed)
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 22)
              else
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  void _showLessonDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LessonDetailSheet(lesson: lesson),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  final Color color;

  const _LevelBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(level,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _LessonDetailSheet extends StatelessWidget {
  final GrammarLesson lesson;

  const _LessonDetailSheet({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(lesson.title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Level ${lesson.level} · ${lesson.category}',
                      style: const TextStyle(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  const Text('Explanation',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grammar.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.grammar.withOpacity(0.2)),
                    ),
                    child: Text(lesson.explanation,
                        style: const TextStyle(
                            height: 1.6,
                            color: AppColors.textPrimary)),
                  ),
                  if (lesson.examples.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Examples',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 10),
                    ...lesson.examples.map((ex) => _ExampleItem(
                        sentence: ex['sentence'] ?? '',
                        translation: ex['translation'] ?? '')),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      lesson.completed = true;
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.grammar,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(lesson.completed
                        ? 'Completed ✓'
                        : 'Mark as Complete'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleItem extends StatelessWidget {
  final String sentence;
  final String translation;

  const _ExampleItem(
      {required this.sentence, required this.translation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sentence,
              style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(translation,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Tab 2: Weaknesses ──────────────────────────────────────────────────────

class _WeaknessesTab extends StatelessWidget {
  final GrammarProvider grammar;

  const _WeaknessesTab({required this.grammar});

  @override
  Widget build(BuildContext context) {
    if (grammar.weaknesses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✅', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text('No weaknesses detected yet!',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'Practice speaking and writing so the AI can identify grammar patterns you need to improve.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: grammar.weaknesses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) =>
          _WeaknessCard(weakness: grammar.weaknesses[i]),
    );
  }
}

class _WeaknessCard extends StatelessWidget {
  final GrammarWeakness weakness;

  const _WeaknessCard({required this.weakness});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(weakness.topic,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${weakness.errorCount} errors',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(weakness.recommendation,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text('Practice ${weakness.topic}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.grammar,
                side: const BorderSide(color: AppColors.grammar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Ask AI ──────────────────────────────────────────────────────────

class _AskAiTab extends StatefulWidget {
  final GrammarProvider grammar;

  const _AskAiTab({required this.grammar});

  @override
  State<_AskAiTab> createState() => _AskAiTabState();
}

class _AskAiTabState extends State<_AskAiTab> {
  final _controller = TextEditingController();

  static const _quickTopics = [
    '📌 Past Tense',
    '📌 Present Perfect',
    '📌 Conditionals',
    '📌 Passive Voice',
    '📌 Articles (a/an/the)',
    '📌 Countable & Uncountable',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask(String topic) async {
    final trimmed = topic.trim().replaceAll('📌 ', '');
    if (trimmed.isEmpty) return;
    _controller.clear();
    await widget.grammar.explainTopic(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final grammar = widget.grammar;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask about any grammar topic...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: _ask,
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => _ask(_controller.text),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.grammar,
                    padding: const EdgeInsets.all(14)),
                child: grammar.explaining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick topics
          const Text('Quick Topics',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTopics.map((topic) {
              return ActionChip(
                label: Text(topic),
                onPressed: () => _ask(topic),
                backgroundColor: AppColors.grammar.withOpacity(0.08),
                side: const BorderSide(
                    color: AppColors.grammar, width: 0.5),
                labelStyle: const TextStyle(
                    color: AppColors.grammar,
                    fontWeight: FontWeight.w500),
              );
            }).toList(),
          ),

          // Explanation result
          if (grammar.explaining) ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                      color: AppColors.grammar),
                  SizedBox(height: 12),
                  Text('AI is explaining...',
                      style: TextStyle(
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ] else if (grammar.explanation != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('AI Explanation',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.textHint),
                  onPressed: grammar.clearExplanation,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.grammar.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.grammar.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.grammar,
                    child: Text('AI',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      grammar.explanation!,
                      style: const TextStyle(
                          height: 1.7, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
