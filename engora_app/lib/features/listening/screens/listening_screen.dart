import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/listening_provider.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListeningProvider>().loadExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ListeningProvider>(
      builder: (context, listening, _) {
        // Decide which view to show based on state
        return switch (listening.state) {
          ListeningState.idle => _ExerciseListView(listening: listening),
          ListeningState.playing ||
          ListeningState.paused =>
            _AudioPlayerView(listening: listening),
          ListeningState.answering => _QuestionsView(listening: listening),
          ListeningState.submitting => _SubmittingView(),
          ListeningState.result => _ResultView(listening: listening),
        };
      },
    );
  }
}

// ─── Exercise List ───────────────────────────────────────────────────────────

class _ExerciseListView extends StatelessWidget {
  final ListeningProvider listening;

  const _ExerciseListView({required this.listening});

  @override
  Widget build(BuildContext context) {
    const levels = ['all', 'A1', 'A2', 'B1', 'B2'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Listening Practice'),
        backgroundColor: AppColors.surface,
      ),
      body: listening.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.listening))
          : Column(
              children: [
                // Header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.listening, Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('👂', style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text(
                        'Train Your Ears',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Listen to conversations, answer questions, and review transcripts.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Level filter
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: levels.map((lvl) {
                        final selected = listening.selectedLevel == lvl;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(lvl == 'all' ? 'All Levels' : lvl),
                            selected: selected,
                            onSelected: (_) => listening.setLevel(lvl),
                            selectedColor:
                                AppColors.listening.withOpacity(0.15),
                            checkmarkColor: AppColors.listening,
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.listening
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

                // Exercise list
                Expanded(
                  child: listening.exercises.isEmpty
                      ? const Center(
                          child: Text('No exercises for this level.',
                              style: TextStyle(
                                  color: AppColors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: listening.exercises.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _ExerciseCard(
                            exercise: listening.exercises[i],
                            onTap: () =>
                                listening.startExercise(listening.exercises[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ListeningExercise exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  Color get _levelColor {
    switch (exercise.level) {
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
    final mins = (exercise.durationSeconds / 60).ceil();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.listening.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.headphones,
                    color: AppColors.listening, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _LevelBadge(
                            level: exercise.level,
                            color: _levelColor),
                        const SizedBox(width: 8),
                        Text(exercise.topic,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        const Icon(Icons.timer_outlined,
                            size: 12,
                            color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text('~$mins min',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${exercise.questions.length} comprehension questions',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle,
                  color: AppColors.listening, size: 30),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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

// ─── Audio Player View ───────────────────────────────────────────────────────

class _AudioPlayerView extends StatefulWidget {
  final ListeningProvider listening;

  const _AudioPlayerView({required this.listening});

  @override
  State<_AudioPlayerView> createState() => _AudioPlayerViewState();
}

class _AudioPlayerViewState extends State<_AudioPlayerView>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _progress = 0;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      // Simulate progress for demo (real: use just_audio)
      if (_isPlaying) _simulateProgress();
    });
  }

  void _simulateProgress() async {
    final exercise = widget.listening.currentExercise!;
    final steps = exercise.durationSeconds;
    for (var i = 0; i <= steps; i++) {
      if (!mounted || !_isPlaying) break;
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _progress = i / steps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.listening.currentExercise!;
    final listening = widget.listening;
    final mins = exercise.durationSeconds ~/ 60;
    final secs = exercise.durationSeconds % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(exercise.title),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => listening.reset(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Player card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.listening, Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // Sound wave animation
                  SizedBox(
                    height: 60,
                    child: _isPlaying
                        ? AnimatedBuilder(
                            animation: _waveCtrl,
                            builder: (_, __) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(7, (i) {
                                final height =
                                    12 + 24 * ((i % 3 == 0 ? _waveCtrl.value : (1 - _waveCtrl.value)));
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: 5,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          )
                        : const Icon(Icons.headphones,
                            color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text(exercise.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(exercise.topic,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          _formatTime(
                              (_progress * exercise.durationSeconds).round()),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      Text('${mins}m ${secs}s',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () =>
                            setState(() => _progress = 0),
                        icon: const Icon(Icons.replay,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: AppColors.listening,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => setState(
                            () => _progress = (_progress + 0.1).clamp(0, 1)),
                        icon: const Icon(Icons.forward_10,
                            color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Transcript toggle
            Card(
              child: ListTile(
                leading: const Icon(Icons.article_outlined,
                    color: AppColors.listening),
                title: const Text('Show Transcript'),
                trailing: Switch(
                  value: listening.showTranscript,
                  onChanged: (_) => listening.toggleTranscript(),
                  activeThumbColor: AppColors.listening,
                ),
              ),
            ),

            if (listening.showTranscript) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transcript',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    Text(
                      exercise.transcript,
                      style: const TextStyle(
                          height: 1.8,
                          color: AppColors.textPrimary,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info row
            Row(
              children: [
                const Icon(Icons.quiz_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${exercise.questions.length} comprehension questions after audio',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: listening.proceedToQuestions,
                icon: const Icon(Icons.quiz),
                label: const Text('Answer Questions'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.listening,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─── Questions View ──────────────────────────────────────────────────────────

class _QuestionsView extends StatelessWidget {
  final ListeningProvider listening;

  const _QuestionsView({required this.listening});

  @override
  Widget build(BuildContext context) {
    final exercise = listening.currentExercise!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Comprehension Questions'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => listening.reset(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${listening.userAnswers.length}/${exercise.questions.length} answered',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: exercise.questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) => _QuestionCard(
                index: i,
                question: exercise.questions[i],
                selectedAnswer:
                    listening.userAnswers[exercise.questions[i].id],
                onSelect: (ans) => listening.setAnswer(
                    exercise.questions[i].id, ans),
              ),
            ),
          ),
          // Submit bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border:
                  Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: listening.allAnswered()
                    ? listening.submitAnswers
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.listening,
                  disabledBackgroundColor: AppColors.border,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(
                  listening.allAnswered()
                      ? 'Submit Answers'
                      : 'Answer all questions to submit',
                  style: TextStyle(
                      color: listening.allAnswered()
                          ? Colors.white
                          : AppColors.textHint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final ListeningQuestion question;
  final String? selectedAnswer;
  final void Function(String) onSelect;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.listening.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.listening,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(question.question,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...question.options.map((opt) {
            final isSelected = selectedAnswer == opt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSelect(opt),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.listening.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.listening
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(opt,
                            style: TextStyle(
                                color: isSelected
                                    ? AppColors.listening
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ),
                      if (isSelected)
                        const Icon(Icons.radio_button_checked,
                            color: AppColors.listening, size: 18)
                      else
                        const Icon(Icons.radio_button_off,
                            color: AppColors.textHint, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Submitting ───────────────────────────────────────────────────────────────

class _SubmittingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.listening),
            SizedBox(height: 16),
            Text('Checking your answers...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Result View ─────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final ListeningProvider listening;

  const _ResultView({required this.listening});

  @override
  Widget build(BuildContext context) {
    final result = listening.result!;
    final exercise = listening.currentExercise!;
    final scoreColor = result.score >= 80
        ? AppColors.success
        : result.score >= 60
            ? AppColors.warning
            : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scoreColor, scoreColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    result.score >= 80
                        ? '🏆'
                        : result.score >= 60
                            ? '👍'
                            : '💪',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${result.score}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${result.correctCount} / ${result.totalQuestions} correct',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Feedback
            if (result.feedback.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(result.feedback,
                          style: const TextStyle(
                              height: 1.6,
                              color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Answer review
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Answer Review',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            ...exercise.questions.asMap().entries.map((entry) {
              final q = entry.value;
              final userAnswer = result.answers[q.id] ?? '';
              final isCorrect = userAnswer == q.correctAnswer;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.success.withOpacity(0.06)
                      : AppColors.error.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(q.question,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isCorrect) ...[
                      Text('Your answer: $userAnswer',
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12)),
                    ],
                    Text('Correct: ${q.correctAnswer}',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),

            // New vocabulary
            if (result.newVocabulary.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('New Vocabulary',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.newVocabulary
                    .map((w) => Chip(
                          label: Text(w),
                          backgroundColor:
                              AppColors.listening.withOpacity(0.1),
                          labelStyle: const TextStyle(
                              color: AppColors.listening,
                              fontWeight: FontWeight.w600),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: listening.reset,
                    icon: const Icon(Icons.list),
                    label: const Text('All Exercises'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.listening,
                      side: const BorderSide(color: AppColors.listening),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        listening.startExercise(exercise),
                    icon: const Icon(Icons.replay),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.listening,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
