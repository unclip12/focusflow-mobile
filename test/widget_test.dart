import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow_mobile/app.dart';

void main() {
  testWidgets('FocusFlow smoke test', (WidgetTester tester) async {
    // Pump the app wrapped in ProviderScope (same as main.dart)
    // Hive init is skipped in widget tests — just verify the widget tree builds
    await tester.pumpWidget(
      const ProviderScope(child: FocusFlowApp()),
    );
  });
}
