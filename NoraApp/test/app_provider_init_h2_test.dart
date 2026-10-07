import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nora_app/main.dart';
import 'package:nora_app/providers/app_provider.dart';
import 'package:provider/provider.dart';

/// H2 regression: `AppProvider.init()` existed but had no callers anywhere in
/// the app, so `_weeklyAppUsage` was never populated and the Stats weekly
/// app-usage chart (`stats_screen.dart` → `provider.weeklyAppUsage`) always
/// rendered its placeholder week. Startup now wires it in `main.dart`'s
/// post-frame callback (the M24 pattern).
void main() {
  testWidgets('AppProvider.init() runs during startup (H2)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NoraApp());
    // Let the splash delay elapse so nothing is left pending.
    await tester.pump(const Duration(seconds: 2));

    final context = tester.element(find.byType(MaterialApp));
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    expect(appProvider.isInitialized, isTrue,
        reason: 'init() must be invoked at startup — without it the weekly '
            'app-usage chart never receives real data');

    // Repeated persona rebuilds re-run the post-frame callback, so init()
    // must stay idempotent: a second call returns without notifying.
    var notified = 0;
    void listener() => notified++;
    appProvider.addListener(listener);
    await appProvider.init();
    appProvider.removeListener(listener);
    expect(notified, 0, reason: 'init() is guarded by _isInitialized');

    // Dispose the tree so init()'s 5-minute refresh timer is cancelled
    // before the test's fake clock ends.
    await tester.pumpWidget(const SizedBox());
  });
}
