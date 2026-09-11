import 'package:flutter_test/flutter_test.dart';
import 'package:nora_app/main.dart';

void main() {
  testWidgets('Nora app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoraApp());

    // Verify splash screen loads
    await tester.pump(const Duration(seconds: 1));

    // The app should start without errors and show the splash brand.
    expect(find.text('Nora'), findsOneWidget);

    // Finish the splash transition so its delayed navigation timer is cleaned up.
    await tester.pump(const Duration(seconds: 2));
  });
}
