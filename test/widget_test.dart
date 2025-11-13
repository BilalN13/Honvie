import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('HonVie Test')),
        ),
      ),
    );

    expect(find.text('HonVie Test'), findsOneWidget);
  });
}
