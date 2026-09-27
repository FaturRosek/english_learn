import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('shell + pushed detail navigation', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) => Scaffold(
              body: shell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: shell.goBranch,
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home'),
                  NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: 'Progress'),
                ],
              ),
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, __) => Scaffold(
                      appBar: AppBar(title: const Text('Home')),
                      body: Builder(
                        builder: (context) => ElevatedButton(
                          onPressed: () => context.push('/speaking'),
                          child: const Text('open speaking'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(path: '/progress', builder: (_, __) => const Scaffold(body: Center(child: Text('progress')))),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/speaking',
            builder: (_, __) => Scaffold(appBar: AppBar(title: const Text('Speaking'))),
          ),
        ],
      );
    });

    testWidgets('home tab shows bottom nav, no back button', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('switching tabs keeps bottom nav and omits back button', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BackButton), findsNothing,
          reason: 'tab-to-tab must not stack a route to pop');
    });

    testWidgets('pushed detail route shows back button and covers bottom nav', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open speaking'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing,
          reason: 'pushed detail must cover the shell nav, leaving back button as the way out');
    });
  });
}