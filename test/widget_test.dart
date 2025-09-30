import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Use your pubspec.yaml name here:
import 'package:cattlense_demo/main.dart'; // if pubspec name is catllense, use: package:catllense/main.dart

void main() {
  testWidgets('renders app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const CattlenseApp());
    expect(find.text('Cattlense'), findsOneWidget);
    expect(find.text('Open Camera / Gallery'), findsOneWidget);
  });

  testWidgets('opens picker bottom sheet', (WidgetTester tester) async {
    await tester.pumpWidget(const CattlenseApp());
    await tester.tap(find.text('Open Camera / Gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Open Camera'), findsOneWidget);
    expect(find.text('Open Gallery'), findsOneWidget);
  });
}
