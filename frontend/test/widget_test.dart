// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Auth screen displays', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(),
    ));

    // Adjusted expectation to match AuthScreen appBar title
    expect(find.text('Connexion'), findsOneWidget);

    // Verify that the text fields exist.
    expect(find.byType(TextField), findsWidgets);
  });
}
