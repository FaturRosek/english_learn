import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:engora_app/core/widgets/scaffold_with_nav_bar.dart';

void main() {
  // Mirrors the real route tree in main.dart. Tab screens replicate the
  // real AppBar pattern: leading arrow_back that goes to '/home'.
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, navigationShell) =>
              ScaffoldWithNavBar(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const _Stub('home', hasBack: false),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/progress',
                builder: (_, __) => const _Stub('progress', hasBack: true),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/ai-tutor',
                builder: (_, __) => const _Stub('ai-tutor', hasBack: true),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/vocabulary',
                builder: (_, __) => const _Stub('vocabulary', hasBack: true),
              ),
            ]),
          ],
        ),
      ],
    );
  });

  for (final loc in ['/progress', '/ai-tutor', '/vocabulary']) {
    testWidgets('$loc shows back button and returns to home', (tester) async {
      router.go(loc);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);

      final back = find.byIcon(Icons.arrow_back);
      print('$loc -> backButtons=${back.evaluate().length}');
      expect(back, findsWidgets, reason: '$loc must expose a back button');

      await tester.tap(back.first);
      await tester.pumpAndSettle();

      // Branches stay alive in the indexed stack, so assert on the router/
      // nav-bar selection rather than on tree contents.
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      print('$loc -> after back, selectedIndex=${navBar.selectedIndex}');
      expect(navBar.selectedIndex, 0,
          reason: 'back button must land on the Home tab');
    });
  }
}

class _Stub extends StatelessWidget {
  final String label;
  final bool hasBack;
  const _Stub(this.label, {required this.hasBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        leading: hasBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
              )
            : null,
      ),
      body: Center(child: Text(label)),
    );
  }
}