import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dmbs_frontend/main.dart';

void main() {
  testWidgets('Database Management App açılma testi', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: DatabaseManagementApp()),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
