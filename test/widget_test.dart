import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Basic Flutter test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('DailyDhan'),
        ),
      ),
    );

    expect(find.text('DailyDhan'), findsOneWidget);
  });
}