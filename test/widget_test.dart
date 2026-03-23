import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Renderiza un MaterialApp base', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Smoke test'),
        ),
      ),
    );

    expect(find.text('Smoke test'), findsOneWidget);
  });
}
