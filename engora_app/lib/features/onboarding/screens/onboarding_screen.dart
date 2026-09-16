import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedLevel;
  String? _selectedGoal;
  bool _loading = false;

  final List<Map<String, dynamic>> _levels = [
    {'value': 'A1', 'label': 'A1 - Beginner', 'desc': 'Just starting out'},
    {'value': 'A2', 'label': 'A2 - Elementary', 'desc': 'Basic communication'},
    {'value': 'B1', 'label': 'B1 - Intermediate', 'desc': 'Can handle most situations'},
    {'value': 'B2', 'label': 'B2 - Upper Intermediate', 'desc': 'Fluent in many topics'},
    {'value': 'C1', 'label': 'C1 - Advanced', 'desc': 'Near native fluency'},
  ];

  final List<Map<String, dynamic>> _goals = [
    {'value': 'daily_conversation', 'label': 'Daily Conversation', 'icon': '💬'},
    {'value': 'work', 'label': 'Work English', 'icon': '💼'},
    {'value': 'job_interview', 'label': 'Job Interview', 'icon': '🎯'},
    {'value': 'travel', 'label': 'Travel', 'icon': '✈️'},
    {'value': 'academic', 'label': 'Academic English', 'icon': '📚'},
    {'value': 'general', 'label': 'General English', 'icon': '🌍'},
  ];

  Future<void> _complete() async {
    if (_selectedLevel == null || _selectedGoal == null) return;
    setState(() => _loading = true);

    try {
      await ApiService().post(ApiConstants.onboarding, data: {
        'level': _selectedLevel,
        'goal': _selectedGoal,
      });

      if (mounted) {
        context.read<AuthProvider>().onboardingComplete();
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(
                  2,
                  (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _LevelPage(
                    levels: _levels,
                    selected: _selectedLevel,
                    onSelect: (v) => setState(() => _selectedLevel = v),
                  ),
                  _GoalPage(
                    goals: _goals,
                    selected: _selectedGoal,
                    onSelect: (v) => setState(() => _selectedGoal = v),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: _currentPage == 0 ? 'Next' : 'Start Learning',
                loading: _loading,
                width: double.infinity,
                onPressed: () {
                  if (_currentPage == 0) {
                    if (_selectedLevel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select your level')),
                      );
                      return;
                    }
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    if (_selectedGoal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select your goal')),
                      );
                      return;
                    }
                    _complete();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPage extends StatelessWidget {
  final List<Map<String, dynamic>> levels;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _LevelPage({
    required this.levels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎓', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            "What's your English level?",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Don't worry, you can change this later",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: levels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final level = levels[i];
                final isSelected = selected == level['value'];
                return GestureDetector(
                  onTap: () => onSelect(level['value']),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surface,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level['label'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                level['desc'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _GoalPage({
    required this.goals,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'What is your main goal?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'We will personalize your learning path',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: goals.length,
              itemBuilder: (_, i) {
                final goal = goals[i];
                final isSelected = selected == goal['value'];
                return GestureDetector(
                  onTap: () => onSelect(goal['value']),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surface,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(goal['icon'], style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          goal['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
