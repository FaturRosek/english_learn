import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/learning_profile_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: home.refresh,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _Header(
                  name: auth.user?.fullName.split(' ').first ?? 'Learner',
                  streak: home.stats?.streak ?? 0,
                ),
              ),

              if (home.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Today's Practice Card
                SliverToBoxAdapter(
                  child: _TodaysPracticeCard(practice: home.todaysPractice),
                ),

                // Skill Progress
                SliverToBoxAdapter(
                  child: _SkillProgress(stats: home.stats),
                ),

                // Quick Practice
                SliverToBoxAdapter(
                  child: _QuickPractice(),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final int streak;

  const _Header({required this.name, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, $name! 👋',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ready to practice today?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TodaysPracticeCard extends StatelessWidget {
  final TodaysPractice? practice;

  const _TodaysPracticeCard({this.practice});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Focus',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              practice?.topic ?? 'Daily Conversation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (practice != null)
              ...practice!.skills.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        _skillEmoji(s.skill),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.skill} — ${s.minutes} min',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/speaking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Today\'s Practice',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _skillEmoji(String skill) {
    switch (skill.toLowerCase()) {
      case 'speaking':
        return '🎤';
      case 'writing':
        return '✍️';
      case 'listening':
        return '🎧';
      case 'vocabulary':
        return '📖';
      case 'grammar':
        return '📝';
      default:
        return '⭐';
    }
  }
}

class _SkillProgress extends StatelessWidget {
  final ProfileStats? stats;

  const _SkillProgress({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();

    final skills = [
      {'name': 'Speaking', 'value': stats!.skills.speaking, 'color': AppColors.speaking},
      {'name': 'Writing', 'value': stats!.skills.writing, 'color': AppColors.writing},
      {'name': 'Listening', 'value': stats!.skills.listening, 'color': AppColors.listening},
      {'name': 'Vocabulary', 'value': stats!.skills.vocabulary, 'color': AppColors.vocabulary},
      {'name': 'Grammar', 'value': stats!.skills.grammar, 'color': AppColors.grammar},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GestureDetector(
                onTap: () => context.push('/progress'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: skills
                .map(
                  (s) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _SkillBar(
                        name: s['name'] as String,
                        value: s['value'] as int,
                        color: s['color'] as Color,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  final String name;
  final int value;
  final Color color;

  const _SkillBar({
    required this.name,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              FractionallySizedBox(
                heightFactor: value / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$value%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          name,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _QuickPractice extends StatelessWidget {
  final List<Map<String, dynamic>> _options = const [
    {
      'label': 'Speaking',
      'icon': '🎤',
      'color': AppColors.speaking,
      'route': '/speaking',
    },
    {
      'label': 'Writing',
      'icon': '✍️',
      'color': AppColors.writing,
      'route': '/writing',
    },
    {
      'label': 'AI Tutor',
      'icon': '🤖',
      'color': AppColors.primary,
      'route': '/ai-tutor',
    },
    {
      'label': 'Vocabulary',
      'icon': '📖',
      'color': AppColors.vocabulary,
      'route': '/vocabulary',
    },
    {
      'label': 'Grammar',
      'icon': '📝',
      'color': AppColors.grammar,
      'route': '/grammar',
    },
    {
      'label': 'Listening',
      'icon': '🎧',
      'color': AppColors.listening,
      'route': '/listening',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Practice',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _options.length,
            itemBuilder: (_, i) {
              final opt = _options[i];
              return GestureDetector(
                onTap: () => context.push(opt['route'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: (opt['color'] as Color).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (opt['color'] as Color).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        opt['icon'] as String,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: opt['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        selectedIndex: _getIndex(location),
        onDestinationSelected: (i) {
          final routes = ['/home', '/progress', '/ai-tutor', '/vocabulary'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Vocabulary',
          ),
        ],
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/progress')) return 1;
    if (location.startsWith('/ai-tutor')) return 2;
    if (location.startsWith('/vocabulary')) return 3;
    return 0;
  }
}
