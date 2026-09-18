import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/speaking/providers/speaking_provider.dart';
import 'features/writing/providers/writing_provider.dart';
import 'features/vocabulary/providers/vocabulary_provider.dart';
import 'features/grammar/providers/grammar_provider.dart';
import 'features/ai_tutor/providers/ai_tutor_provider.dart';
import 'features/progress/providers/progress_provider.dart';
import 'features/listening/providers/listening_provider.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/speaking/screens/speaking_screen.dart';
import 'features/writing/screens/writing_screen.dart';
import 'features/vocabulary/screens/vocabulary_screen.dart';
import 'features/grammar/screens/grammar_screen.dart';
import 'features/ai_tutor/screens/ai_tutor_screen.dart';
import 'features/progress/screens/progress_screen.dart';
import 'features/listening/screens/listening_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService().initialize();
  runApp(const EngoraApp());
}

class EngoraApp extends StatelessWidget {
  const EngoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => SpeakingProvider()),
        ChangeNotifierProvider(create: (_) => WritingProvider()),
        ChangeNotifierProvider(create: (_) => VocabularyProvider()),
        ChangeNotifierProvider(create: (_) => GrammarProvider()),
        ChangeNotifierProvider(create: (_) => AiTutorProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ListeningProvider()),
      ],
      child: _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final authProvider = context.read<AuthProvider>();
    authProvider.checkAuthStatus();

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        final isAuth = status == AuthStatus.authenticated;
        final isOnboarding = status == AuthStatus.onboarding;
        final isUnknown = status == AuthStatus.unknown;

        if (isUnknown) return null;

        final atLogin = state.matchedLocation == '/login';
        final atRegister = state.matchedLocation == '/register';
        final atOnboarding = state.matchedLocation == '/onboarding';

        if (!isAuth && !isOnboarding && !atLogin && !atRegister) return '/login';
        if (isOnboarding && !atOnboarding) return '/onboarding';
        if (isAuth && (atLogin || atRegister || atOnboarding)) return '/home';

        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/speaking', builder: (_, __) => const SpeakingScreen()),
        GoRoute(path: '/writing', builder: (_, __) => const WritingScreen()),
        GoRoute(path: '/vocabulary', builder: (_, __) => const VocabularyScreen()),
        GoRoute(path: '/grammar', builder: (_, __) => const GrammarScreen()),
        GoRoute(path: '/ai-tutor', builder: (_, __) => const AiTutorScreen()),
        GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
        GoRoute(path: '/listening', builder: (_, __) => const ListeningScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Engora — AI English Coach',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
