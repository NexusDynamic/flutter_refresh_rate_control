// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_refresh_rate_control_example/main.dart';

void main() {
  testWidgets('Verify Refresh Rate Control app loads', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlutterRefreshRateControlExampleApp());

    // Wait for async operations to complete
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('Refresh Rate Control'), findsOneWidget);

    // Verify that control buttons are present
    expect(find.text('Enable High Refresh Rate'), findsOneWidget);
    expect(find.text('Refresh Info'), findsOneWidget);

    // Verify that platform info is displayed
    expect(find.textContaining('Platform:'), findsOneWidget);
  });
}
