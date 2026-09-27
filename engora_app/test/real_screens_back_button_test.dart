import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:engora_app/features/progress/providers/progress_provider.dart';
import 'package:engora_app/features/progress/screens/progress_screen.dart';
import 'package:engora_app/features/ai_tutor/providers/ai_tutor_provider.dart';
import 'package:engora_app/features/ai_tutor/screens/ai_tutor_screen.dart';
import 'package:engora_app/features/vocabulary/providers/vocabulary_provider.dart';
import 'package:engora_app/features/vocabulary/screens/vocabulary_screen.dart';
import 'package:engora_app/features/speaking/providers/speaking_provider.dart';
import 'package:engora_app/features/speaking/screens/speaking_screen.dart';
import 'package:engora_app/features/writing/providers/writing_provider.dart';
import 'package:engora_app/features/writing/screens/writing_screen.dart';
import 'package:engora_app/features/grammar/providers/grammar_provider.dart';
import 'package:engora_app/features/grammar/screens/grammar_screen.dart';
import 'package:engora_app/features/listening/providers/listening_provider.dart';
import 'package:engora_app/features/listening/screens/listening_screen.dart';

void main() {
  // Tab screens get an *explicit* `leading` back button (added by us).
  // Detail entry screens get an *auto-implied* back button when pushed.
  // This test pumps the REAL production screens to confirm each has one.

  Widget wrap(Widget home) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProgressProvider()),
          ChangeNotifierProvider(create: (_) => AiTutorProvider()),
          ChangeNotifierProvider(create: (_) => VocabularyProvider()),
          ChangeNotifierProvider(create: (_) => SpeakingProvider()),
          ChangeNotifierProvider(create: (_) => WritingProvider()),
          ChangeNotifierProvider(create: (_) => GrammarProvider()),
          ChangeNotifierProvider(create: (_) => ListeningProvider()),
        ],
        child: MaterialApp(home: home),
      );

  // Ahem fallback font in tests renders ~2x wider than Inter; use a wide
  // viewport so layout-overflow noise does not mask the back-button check.
  void useTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
  }

  // Tab screens — explicit leading must render regardless of nav stack.
  testWidgets('ProgressScreen shows back button', (tester) async {
    useTestViewport(tester);
    await tester.pumpWidget(wrap(const ProgressScreen()));
    await tester.pump();
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
  testWidgets('AiTutorScreen shows back button', (tester) async {
    useTestViewport(tester);
    await tester.pumpWidget(wrap(const AiTutorScreen()));
    await tester.pump();
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
  testWidgets('VocabularyScreen shows back button', (tester) async {
    useTestViewport(tester);
    await tester.pumpWidget(wrap(const VocabularyScreen()));
    await tester.pump();
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  // Detail entry screens — pushed onto a Navigator; auto-implied leading.
  Future<void> pushAndCheck(WidgetTester tester, Widget screen) async {
    useTestViewport(tester);
    late NavigatorState nav;
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      nav = Navigator.of(context);
      return const Scaffold(body: SizedBox.shrink());
    })));
    nav.push(MaterialPageRoute(builder: (_) => screen));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  }

  testWidgets('SpeakingScreen entry shows back button', (tester) =>
      pushAndCheck(tester, const SpeakingScreen()));
  testWidgets('WritingScreen entry shows back button', (tester) =>
      pushAndCheck(tester, const WritingScreen()));
  testWidgets('GrammarScreen entry shows back button', (tester) =>
      pushAndCheck(tester, const GrammarScreen()));
  testWidgets('ListeningScreen entry shows back button', (tester) =>
      pushAndCheck(tester, const ListeningScreen()));
}