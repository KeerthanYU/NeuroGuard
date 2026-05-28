// Basic widget test for NeuroGuard custom widgets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroguard/core/widgets/common_widgets.dart';

void main() {
  testWidgets('GlassCard renders child widget correctly', (WidgetTester tester) async {
    // Build a simple GlassCard with a text child inside a MaterialApp
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('Test Child Text'),
          ),
        ),
      ),
    );

    // Verify that the custom GlassCard rendered its child successfully
    expect(find.text('Test Child Text'), findsOneWidget);
    expect(find.byType(GlassCard), findsOneWidget);
  });
}
