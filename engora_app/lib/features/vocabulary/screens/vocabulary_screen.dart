import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/vocabulary_provider.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocabularyProvider>().loadVocabulary();
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
        title: const Text('Vocabulary'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.vocabulary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.vocabulary,
          tabs: const [
            Tab(text: 'My Words'),
            Tab(text: 'Review'),
            Tab(text: 'Quiz'),
          ],
        ),
      ),
      body: Consumer<VocabularyProvider>(
        builder: (context, vocab, _) {
          if (vocab.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.vocabulary),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _MyWordsTab(vocab: vocab),
              _ReviewTab(vocab: vocab),
              _QuizTab(vocab: vocab),
            ],
          );
        },
      ),
    );
  }
}

// ─── Tab 1: My Words ────────────────────────────────────────────────────────

class _MyWordsTab extends StatelessWidget {
  final VocabularyProvider vocab;

  const _MyWordsTab({required this.vocab});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatsRow(vocab: vocab),
        _SearchAndFilter(vocab: vocab),
        Expanded(
          child: vocab.words.isEmpty
              ? _EmptyWords(onAdd: () => _showAddWordDialog(context, vocab))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vocab.words.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _VocabCard(item: vocab.words[i]),
                ),
        ),
      ],
    );
  }

  void _showAddWordDialog(BuildContext context, VocabularyProvider vocab) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Word'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. negotiate',
            prefixIcon: Icon(Icons.add_circle_outline),
          ),
          textCapitalization: TextCapitalization.none,
          onSubmitted: (_) => _submit(ctx, vocab, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vocabulary),
            onPressed: () => _submit(ctx, vocab, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
      BuildContext ctx, VocabularyProvider vocab, String text) async {
    if (text.trim().isEmpty) return;
    Navigator.pop(ctx);
    final item = await vocab.addWord(text.trim());
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(item != null
              ? '"${item.word}" added to your vocabulary!'
              : 'Failed to add word. Try again.'),
          backgroundColor: item != null ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

class _StatsRow extends StatelessWidget {
  final VocabularyProvider vocab;

  const _StatsRow({required this.vocab});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: vocab.totalWords.toString(),
            color: AppColors.vocabulary,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Mastered',
            value: vocab.masteredWords.toString(),
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'To Review',
            value: vocab.reviewWords.length.toString(),
            color: AppColors.warning,
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _MyWordsTab(vocab: vocab)
                ._showAddWordDialog(context, vocab),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.vocabulary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  final VocabularyProvider vocab;

  const _SearchAndFilter({required this.vocab});

  @override
  Widget build(BuildContext context) {
    const sources = ['all', 'manual', 'speaking', 'writing', 'listening'];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search words...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textHint),
              suffixIcon: vocab.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => vocab.setSearch(''),
                    )
                  : null,
            ),
            onChanged: vocab.setSearch,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sources.map((s) {
                final selected = vocab.filterSource == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s == 'all' ? 'All' : s),
                    selected: selected,
                    onSelected: (_) => vocab.setFilter(s),
                    selectedColor: AppColors.vocabulary.withOpacity(0.15),
                    checkmarkColor: AppColors.vocabulary,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.vocabulary
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
        ],
      ),
    );
  }
}

class _VocabCard extends StatelessWidget {
  final VocabularyItem item;

  const _VocabCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: _sourceColor(item.source).withOpacity(0.12),
          child: Text(
            item.word.substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: _sourceColor(item.source),
                fontWeight: FontWeight.w700),
          ),
        ),
        title: Row(
          children: [
            Text(item.word,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(width: 8),
            if (item.mastered)
              const Icon(Icons.verified,
                  size: 16, color: AppColors.success),
          ],
        ),
        subtitle: Text(
          '${item.partOfSpeech} · ${item.indonesianMeaning}',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(item.definition,
              style: const TextStyle(color: AppColors.textSecondary)),
          if (item.examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...item.examples.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style:
                            TextStyle(color: AppColors.vocabulary)),
                    Expanded(
                      child: Text(e,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _SourceBadge(source: item.source),
              const Spacer(),
              Text(
                'Reviewed ${item.reviewCount}×',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _sourceColor(String source) {
    switch (source) {
      case 'speaking':
        return AppColors.speaking;
      case 'writing':
        return AppColors.writing;
      case 'listening':
        return AppColors.listening;
      default:
        return AppColors.vocabulary;
    }
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final color = source == 'speaking'
        ? AppColors.speaking
        : source == 'writing'
            ? AppColors.writing
            : source == 'listening'
                ? AppColors.listening
                : AppColors.vocabulary;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        source,
        style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyWords extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyWords({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📚', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('No words yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Words from your speaking, writing, and listening sessions will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add a Word'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vocabulary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Review ──────────────────────────────────────────────────────────

class _ReviewTab extends StatelessWidget {
  final VocabularyProvider vocab;

  const _ReviewTab({required this.vocab});

  @override
  Widget build(BuildContext context) {
    if (vocab.reviewWords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text('All caught up!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'No words to review right now. Keep practicing to add more to your list.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.schedule,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                '${vocab.reviewWords.length} word(s) need review',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vocab.reviewWords.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) =>
                _VocabCard(item: vocab.reviewWords[i]),
          ),
        ),
      ],
    );
  }
}

// ─── Tab 3: Quiz ────────────────────────────────────────────────────────────

class _QuizTab extends StatefulWidget {
  final VocabularyProvider vocab;

  const _QuizTab({required this.vocab});

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  List<VocabularyQuiz>? _quizzes;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  bool _finished = false;

  void _startQuiz() {
    final source = widget.vocab.reviewWords.isNotEmpty
        ? widget.vocab.reviewWords
        : widget.vocab.words;
    if (source.isEmpty) return;
    setState(() {
      _quizzes = widget.vocab.generateQuiz(source);
      _currentIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _correctCount = 0;
      _finished = false;
    });
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final correct = _quizzes![_currentIndex].correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (answer == correct) _correctCount++;
    });
  }

  void _next() {
    if (_currentIndex + 1 >= _quizzes!.length) {
      setState(() => _finished = true);
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vocab.words.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Add some words first to start a quiz.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    if (_quizzes == null) return _buildStartScreen();
    if (_finished) return _buildResultScreen();
    return _buildQuestion();
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('Vocabulary Quiz',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Test yourself on up to 10 words from your collection.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Quiz'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vocabulary,
                  minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final quiz = _quizzes![_currentIndex];
    final total = _quizzes!.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress
          Row(
            children: [
              Text('${_currentIndex + 1}/$total',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / total,
                    backgroundColor: AppColors.border,
                    color: AppColors.vocabulary,
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Question card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.vocabulary, Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('What does this mean?',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Text(
                  quiz.word,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Options
          ...quiz.options.map((opt) {
            Color? bg;
            Color textColor = AppColors.textPrimary;
            if (_answered) {
              if (opt == quiz.correctAnswer) {
                bg = AppColors.success.withOpacity(0.15);
                textColor = AppColors.success;
              } else if (opt == _selectedAnswer) {
                bg = AppColors.error.withOpacity(0.1);
                textColor = AppColors.error;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _selectAnswer(opt),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: bg ?? AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _answered && opt == quiz.correctAnswer
                          ? AppColors.success
                          : _answered && opt == _selectedAnswer
                              ? AppColors.error
                              : AppColors.border,
                      width: _answered &&
                              (opt == quiz.correctAnswer ||
                                  opt == _selectedAnswer)
                          ? 2
                          : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(opt,
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500)),
                      ),
                      if (_answered && opt == quiz.correctAnswer)
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 20),
                      if (_answered &&
                          opt == _selectedAnswer &&
                          opt != quiz.correctAnswer)
                        const Icon(Icons.cancel,
                            color: AppColors.error, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (_answered)
            FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vocabulary,
                  minimumSize: const Size.fromHeight(48)),
              child: Text(_currentIndex + 1 >= _quizzes!.length
                  ? 'See Results'
                  : 'Next'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final total = _quizzes!.length;
    final pct = (_correctCount / total * 100).round();
    final color = pct >= 80
        ? AppColors.success
        : pct >= 60
            ? AppColors.vocabulary
            : AppColors.warning;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pct >= 80 ? '🏆' : pct >= 60 ? '👍' : '💪',
                style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              '$pct%',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: color),
            ),
            const SizedBox(height: 4),
            Text('$_correctCount / $total correct',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              pct >= 80
                  ? 'Excellent! Keep it up!'
                  : pct >= 60
                      ? 'Good job! Keep practicing.'
                      : 'Don\'t give up — practice makes perfect!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vocabulary,
                  minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      ),
    );
  }
}
