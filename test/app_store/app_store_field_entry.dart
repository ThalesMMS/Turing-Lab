//
//  app_store_field_entry.dart
//  Turing Lab
//
//  Resolves the text field a capture step needs to fill. Fields are located by
//  semantics label so the harness never types into an arbitrary widget; the
//  legacy simulation input keeps a narrow positional fallback.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_store_capture_waits.dart';

/// Locates and fills labelled text fields during a capture.
class AppStoreFieldEntry {
  const AppStoreFieldEntry._();

  /// Label whose positional fallback predates the semantics annotations.
  static const String legacyInputLabel = 'Input String';

  /// Semantics label the simulation input exposes once annotated.
  static const String simulationInputLabel = 'Simulation input string';

  /// Returns the field matching [label], falling back to the last text field
  /// only for the legacy simulation input.
  static Finder locate(String label) {
    final semanticsFinder = find.bySemanticsLabel(label);
    if (semanticsFinder.evaluate().isNotEmpty) {
      return semanticsFinder;
    }
    if (label != legacyInputLabel) {
      return semanticsFinder;
    }
    final simulationFinder = find.bySemanticsLabel(simulationInputLabel);
    if (simulationFinder.evaluate().isNotEmpty) {
      return simulationFinder;
    }
    return find.byType(TextField).last;
  }

  /// Types [value] into the field named [label] and lets the frame settle.
  static Future<void> enter(
    WidgetTester tester,
    AppStoreCaptureWaits waits,
    String label,
    String value,
  ) async {
    final finder = locate(label);
    expect(finder, findsOneWidget, reason: 'Expected a unique field: $label');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, value);
    await waits.quiesce(tester);
  }
}
