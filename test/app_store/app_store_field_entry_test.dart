//
//  app_store_field_entry_test.dart
//  Turing Lab
//
//  Widget coverage for the labelled field lookup the capture harness relies
//  on, so a screenshot never types into an arbitrary text field.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_store_capture_waits.dart';
import 'app_store_field_entry.dart';

void main() {
  const waits = AppStoreCaptureWaits(
    frameBudget: 60,
    stageTimeout: Duration(seconds: 5),
    viewport: Size(800, 600),
  );

  group('AppStoreFieldEntry', () {
    testWidgets('rejects generic TextField fallback for non input labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(),
                TextField(),
              ],
            ),
          ),
        ),
      );

      await expectLater(
        AppStoreFieldEntry.enter(tester, waits, 'Regex Pattern', 'ab*'),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('keeps legacy Input String TextField fallback', (
      tester,
    ) async {
      final firstController = TextEditingController();
      final secondController = TextEditingController();
      addTearDown(firstController.dispose);
      addTearDown(secondController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: firstController),
                TextField(controller: secondController),
              ],
            ),
          ),
        ),
      );

      await AppStoreFieldEntry.enter(
        tester,
        waits,
        AppStoreFieldEntry.legacyInputLabel,
        'ba',
      );

      expect(firstController.text, isEmpty);
      expect(secondController.text, equals('ba'));
    });
  });
}
