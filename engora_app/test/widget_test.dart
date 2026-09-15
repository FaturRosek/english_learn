// Basic smoke test — verifies the app builds without throwing.
import 'package:flutter_test/flutter_test.dart';
import 'package:engora_app/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EngoraApp());
    // If no exception is thrown, the widget tree is valid.
    expect(tester.takeException(), isNull);
  });
}
