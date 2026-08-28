import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/widgets/automaton_diagnostic_highlight_bar.dart';

void main() {
  testWidgets('reflows at 320px with visible icon and text cues', (
    tester,
  ) async {
    await _pumpBar(tester, width: 320);

    expect(find.text('Conflicts (2)'), findsOneWidget);
    expect(find.text('Epsilon (1)'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.alt_route), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard toggles both diagnostic actions', (tester) async {
    final changes = <(AutomatonDiagnosticHighlightKind, bool)>[];
    await _pumpBar(tester, width: 720, changes: changes);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(changes, [
      (AutomatonDiagnosticHighlightKind.conflicts, true),
      (AutomatonDiagnosticHighlightKind.epsilon, true),
    ]);
  });

  testWidgets('semantics expose action, count, state, and purpose', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpBar(
      tester,
      width: 720,
      activeKind: AutomatonDiagnosticHighlightKind.conflicts,
    );

    final conflictData = tester
        .getSemantics(
          find.byKey(const ValueKey('highlight-conflicting-transitions')),
        )
        .getSemanticsData();
    expect(conflictData.label, contains('Clear the conflicting'));
    expect(conflictData.label, contains('2 found'));
    expect(conflictData.hint, contains('same input'));
    expect(conflictData.flagsCollection.isToggled, Tristate.isTrue);
    expect(conflictData.hasAction(SemanticsAction.tap), isTrue);

    final epsilonData = tester
        .getSemantics(
          find.byKey(const ValueKey('highlight-epsilon-transitions')),
        )
        .getSemanticsData();
    expect(epsilonData.label, contains('1 found'));
    expect(epsilonData.hint, contains('empty string'));
    expect(epsilonData.flagsCollection.isToggled, Tristate.isFalse);
    expect(epsilonData.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });
}

Future<void> _pumpBar(
  WidgetTester tester, {
  required double width,
  List<(AutomatonDiagnosticHighlightKind, bool)>? changes,
  AutomatonDiagnosticHighlightKind? activeKind,
}) async {
  tester.view.physicalSize = Size(width, 300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: AutomatonDiagnosticHighlightBar(
            activeKind: activeKind,
            conflictCount: 2,
            epsilonCount: 1,
            onConflictSelected: (selected) => changes?.add((
              AutomatonDiagnosticHighlightKind.conflicts,
              selected,
            )),
            onEpsilonSelected: (selected) => changes?.add((
              AutomatonDiagnosticHighlightKind.epsilon,
              selected,
            )),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
