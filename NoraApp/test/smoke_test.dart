import 'package:flutter_test/flutter_test.dart';
import 'package:nora_app/main.dart';

void main() {
  testWidgets('App smoke test - renders without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoraApp());

    // Allow animations/timers to complete.
    await tester.pump(const Duration(seconds: 4));

    // Verify the app builds successfully (basic smoke test).
    expect(find.byType(NoraApp), findsOneWidget);
  });
}
