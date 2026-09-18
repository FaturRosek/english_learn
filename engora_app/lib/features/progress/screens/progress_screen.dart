import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/learning_profile_model.dart';
import '../providers/progress_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Progress'),
        backgroundColor: AppColors.surface,
        actions: [
          Consumer<ProgressProvider>(
            builder: (_, prog, __) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: prog.loading ? null : prog.refresh,
            ),
          ),
        ],
      ),
      body: Consumer<ProgressProvider>(
        builder: (context, prog, _) {
          if (prog.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (prog.error != null) {
            return _ErrorView(
                message: prog.error!, onRetry: prog.refresh);
          }
          if (prog.stats == null) {
            return const Center(
              child: Text('No progress data yet. Start practicing!',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return RefreshIndicator(
            onRefresh: prog.refresh,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _LevelCard(stats: prog.stats!)),
                SliverToBoxAdapter(
                    child: _StatsRow(stats: prog.stats!)),
                SliverToBoxAdapter(
                    child: _SkillProgressSection(
                        skills: prog.stats!.skills)),
                SliverToBoxAdapter(
                    child: _StrengthsWeaknesses(stats: prog.stats!)),
                if (prog.stats!.aiSummary != null)
                  SliverToBoxAdapter(
                      child: _AiSummaryCard(
                          summary: prog.stats!.aiSummary!)),
                SliverToBoxAdapter(
                    child: _LearningPathSection(stats: prog.stats!)),
                SliverToBoxAdapter(
                    child: _HistorySection(history: prog.history)),
                const SliverToBoxAdapter(
                    child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Level Card ──────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final ProfileStats stats;

  const _LevelCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Level',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                stats.level,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _goalLabel(stats.goal),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text('${stats.streak} day streak',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              _LevelProgress(level: stats.level),
            ],
          ),
        ],
      ),
    );
  }

  String _goalLabel(String goal) {
    const map = {
      'daily_conversation': 'Daily Conversation',
      'work': 'Work English',
      'job_interview': 'Job Interview',
      'travel': 'Travel',
      'academic': 'Academic',
      'general': 'General English',
    };
    return map[goal] ?? goal;
  }
}

class _LevelProgress extends StatelessWidget {
  final String level;

  const _LevelProgress({required this.level});

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  Widget build(BuildContext context) {
    final idx = _levels.indexOf(level);
    return Row(
      children: List.generate(_levels.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: i <= idx
                  ? Colors.white
                  : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                _levels[i],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: i <= idx
                      ? AppColors.primary
                      : Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ProfileStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            icon: '🎯',
            value: stats.totalSessions.toString(),
            label: 'Sessions',
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: '⏱️',
            value: '${stats.totalMinutes}m',
            label: 'Practice Time',
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: '🏆',
            value: '${stats.longestStreak}d',
            label: 'Best Streak',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatCard(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Skill Progress ──────────────────────────────────────────────────────────

class _SkillProgressSection extends StatelessWidget {
  final SkillStats skills;

  const _SkillProgressSection({required this.skills});

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Speaking', skills.speaking, AppColors.speaking, '🗣️'),
      ('Writing', skills.writing, AppColors.writing, '✍️'),
      ('Listening', skills.listening, AppColors.listening, '👂'),
      ('Vocabulary', skills.vocabulary, AppColors.vocabulary, '📚'),
      ('Grammar', skills.grammar, AppColors.grammar, '📐'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skill Progress',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: entries.map((e) {
                final (name, value, color, emoji) = e;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _SkillBar(
                    emoji: emoji,
                    name: name,
                    value: value,
                    color: color,
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

class _SkillBar extends StatelessWidget {
  final String emoji;
  final String name;
  final int value;
  final Color color;

  const _SkillBar({
    required this.emoji,
    required this.name,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: AppColors.textPrimary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: AppColors.surfaceVariant,
                color: color,
                minHeight: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text('$value%',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      ],
    );
  }
}

// ─── Strengths & Weaknesses ──────────────────────────────────────────────────

class _StrengthsWeaknesses extends StatelessWidget {
  final ProfileStats stats;

  const _StrengthsWeaknesses({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.strengths.isEmpty && stats.weaknesses.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.strengths.isNotEmpty)
            Expanded(
              child: _TagsCard(
                title: 'Strengths',
                tags: stats.strengths,
                color: AppColors.success,
                icon: Icons.trending_up,
              ),
            ),
          if (stats.strengths.isNotEmpty && stats.weaknesses.isNotEmpty)
            const SizedBox(width: 10),
          if (stats.weaknesses.isNotEmpty)
            Expanded(
              child: _TagsCard(
                title: 'Weaknesses',
                tags: stats.weaknesses,
                color: AppColors.warning,
                icon: Icons.flag_outlined,
              ),
            ),
        ],
      ),
    );
  }
}

class _TagsCard extends StatelessWidget {
  final String title;
  final List<String> tags;
  final Color color;
  final IconData icon;

  const _TagsCard({
    required this.title,
    required this.tags,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── AI Summary ──────────────────────────────────────────────────────────────

class _AiSummaryCard extends StatelessWidget {
  final String summary;

  const _AiSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Insight',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(summary,
                    style: const TextStyle(
                        height: 1.6,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Learning Path ───────────────────────────────────────────────────────────

class _LearningPathSection extends StatelessWidget {
  final ProfileStats stats;

  const _LearningPathSection({required this.stats});

  // Build a simple path based on level + goal
  List<_PathStep> _buildPath() {
    final level = stats.level;
    final goal = stats.goal;

    final base = <_PathStep>[
      _PathStep(title: 'Level $level', subtitle: 'Current level', done: true),
    ];

    if (goal == 'job_interview' || goal == 'work') {
      base.addAll([
        _PathStep(
            title: 'Workplace Vocabulary',
            subtitle: 'Professional terms',
            done: stats.skills.vocabulary > 40),
        _PathStep(
            title: 'Professional Writing',
            subtitle: 'Emails & reports',
            done: stats.skills.writing > 50),
        _PathStep(
            title: 'Job Interview Speaking',
            subtitle: 'Fluency & confidence',
            done: stats.skills.speaking > 60),
        _PathStep(
            title: 'Mock Interview',
            subtitle: 'Full simulation',
            done: false),
      ]);
    } else if (goal == 'travel') {
      base.addAll([
        _PathStep(
            title: 'Travel Phrases',
            subtitle: 'Essential expressions',
            done: stats.skills.vocabulary > 30),
        _PathStep(
            title: 'Listening Practice',
            subtitle: 'Understand native speakers',
            done: stats.skills.listening > 40),
        _PathStep(
            title: 'Conversation Practice',
            subtitle: 'Hotels, restaurants, transport',
            done: stats.skills.speaking > 50),
      ]);
    } else {
      base.addAll([
        _PathStep(
            title: 'Basic Conversation',
            subtitle: 'Everyday topics',
            done: stats.skills.speaking > 30),
        _PathStep(
            title: 'Core Grammar',
            subtitle: 'Tenses & sentence structure',
            done: stats.skills.grammar > 40),
        _PathStep(
            title: 'Vocabulary Expansion',
            subtitle: '500+ words',
            done: stats.skills.vocabulary > 50),
        _PathStep(
            title: 'Fluent Speaking',
            subtitle: 'Natural conversations',
            done: stats.skills.speaking > 70),
      ]);
    }

    return base;
  }

  @override
  Widget build(BuildContext context) {
    final path = _buildPath();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Learning Path',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(path.length, (i) {
                final step = path[i];
                final isLast = i == path.length - 1;
                return _PathStepRow(
                    step: step, isLast: isLast, index: i);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathStep {
  final String title;
  final String subtitle;
  final bool done;

  const _PathStep(
      {required this.title,
      required this.subtitle,
      required this.done});
}

class _PathStepRow extends StatelessWidget {
  final _PathStep step;
  final bool isLast;
  final int index;

  const _PathStepRow(
      {required this.step, required this.isLast, required this.index});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step.done
                        ? AppColors.success
                        : index == 0
                            ? AppColors.primary
                            : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    step.done
                        ? Icons.check
                        : index == 0
                            ? Icons.star
                            : Icons.lock_outline,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: step.done
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: step.done
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          decoration: step.done
                              ? TextDecoration.lineThrough
                              : null)),
                  Text(step.subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint)),
                ],
              ),
            ),
          ),
          if (step.done)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.check_circle,
                  color: AppColors.success, size: 16),
            ),
        ],
      ),
    );
  }
}

// ─── Practice History ────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final List<PracticeHistoryItem> history;

  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Practice',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'No practice history yet.\nStart your first session!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...history.take(10).map((h) => _HistoryItem(item: h)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final PracticeHistoryItem item;

  const _HistoryItem({required this.item});

  Color get _typeColor {
    switch (item.type) {
      case 'speaking':
        return AppColors.speaking;
      case 'writing':
        return AppColors.writing;
      case 'listening':
        return AppColors.listening;
      default:
        return AppColors.primary;
    }
  }

  String get _typeEmoji {
    switch (item.type) {
      case 'speaking':
        return '🗣️';
      case 'writing':
        return '✍️';
      case 'listening':
        return '👂';
      default:
        return '📖';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(_typeEmoji,
                    style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.topic.isNotEmpty ? item.topic : item.type,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${item.durationMinutes} min · ${_formatDate(item.completedAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (item.score > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _scoreColor(item.score).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${item.score}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(item.score)),
              ),
            ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
