// Basic smoke test for AfterCredits app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aftercredits/main.dart';

void main() {
  testWidgets('AfterCredits app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const AfterCreditsApp(showAppIntro: true),
    );
    // App should render without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
