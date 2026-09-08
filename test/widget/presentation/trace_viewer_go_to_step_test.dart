//
//  trace_viewer_go_to_step_test.dart
//  Turing Lab
//
//  Covers the go-to-step dialog of BaseTraceViewer: validation limits,
//  first/last step, long folded traces, playback interaction, cancel, and a
//  result replaced while the dialog is open.
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/base_trace_viewer.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/go_to_step_dialog.dart';

SimulationResult _result(int stepCount, {String prefix = 'q'}) {
  return SimulationResult.success(
    inputString: 'a' * stepCount,
    steps: [
      for (var i = 0; i < stepCount; i++)
        SimulationStep(
          currentState: '$prefix$i',
          remainingInput: 'a' * (stepCount - i - 1),
          stepNumber: i,
        ),
    ],
    executionTime: const Duration(milliseconds: 1),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required SimulationResult result,
  List<int>? changes,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BaseTraceViewer(
          result: result,
          title: 'Trace',
          highlightService: SimulationHighlightService(),
          animationSpeed: 10,
          onStepChanged: changes?.add,
          buildStepLine: (step, index) =>
              Text('${index + 1}. ${step.currentState}'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(BaseTraceViewer.goToStepKey));
  await tester.pumpAndSettle();
  expect(find.byType(GoToStepDialog), findsOneWidget);
}

Future<void> _enterAndConfirm(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(GoToStepDialog.fieldKey), value);
  await tester.tap(find.byKey(GoToStepDialog.confirmKey));
  await tester.pumpAndSettle();
}

void main() {
  group('parseGoToStep', () {
    test('maps 1-based input to zero-based indices within the trace', () {
      expect(parseGoToStep('1', 4).index, 0);
      expect(parseGoToStep(' 4 ', 4).index, 3);
      expect(parseGoToStep('3', 4).index, 2);
    });

    test('rejects empty, non-integer, zero, negative and too-large values', () {
      expect(parseGoToStep('', 4).error, GoToStepError.empty);
      expect(parseGoToStep('   ', 4).error, GoToStepError.empty);
      expect(parseGoToStep('abc', 4).error, GoToStepError.notInteger);
      expect(parseGoToStep('2.5', 4).error, GoToStepError.notInteger);
      expect(parseGoToStep('0', 4).error, GoToStepError.outOfRange);
      expect(parseGoToStep('-1', 4).error, GoToStepError.outOfRange);
      expect(parseGoToStep('5', 4).error, GoToStepError.outOfRange);
      expect(parseGoToStep('1', 0).error, GoToStepError.outOfRange);
    });
  });

  testWidgets('counter opens the dialog and confirming selects the step', (
    tester,
  ) async {
    final changes = <int>[];
    await _pump(tester, result: _result(4), changes: changes);
    expect(find.byTooltip('Go to step…'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);

    await _openDialog(tester);
    expect(find.text('Step number (1 to 4)'), findsOneWidget);
    await _enterAndConfirm(tester, '3');

    expect(find.byType(GoToStepDialog), findsNothing);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(changes.last, 2);
    final selectedRow = tester.getSemantics(find.text('3. q2'));
    expect(selectedRow.label, contains('Active step 3 of 4'));
  });

  testWidgets('submitting from the keyboard confirms the dialog', (
    tester,
  ) async {
    final changes = <int>[];
    await _pump(tester, result: _result(4), changes: changes);
    await _openDialog(tester);
    await tester.enterText(find.byKey(GoToStepDialog.fieldKey), '2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(GoToStepDialog), findsNothing);
    expect(changes.last, 1);
  });

  for (final (value, message) in const [
    ('', 'Enter a step number.'),
    ('abc', 'Enter a whole number.'),
    ('0', 'Enter a step between 1 and 4.'),
    ('-1', 'Enter a step between 1 and 4.'),
    ('5', 'Enter a step between 1 and 4.'),
  ]) {
    testWidgets('rejects "$value" without changing the selection', (
      tester,
    ) async {
      final changes = <int>[];
      await _pump(tester, result: _result(4), changes: changes);
      final changesBefore = List<int>.of(changes);
      await _openDialog(tester);
      await _enterAndConfirm(tester, value);

      expect(find.byType(GoToStepDialog), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(changes, changesBefore);
      expect(find.text('1 / 4'), findsOneWidget);

      // Fixing the value clears the error and applies.
      await _enterAndConfirm(tester, '4');
      expect(find.byType(GoToStepDialog), findsNothing);
      expect(find.text(message), findsNothing);
      expect(changes.last, 3);
    });
  }

  testWidgets('first and last steps are reachable', (tester) async {
    final changes = <int>[];
    await _pump(tester, result: _result(6), changes: changes);
    await _openDialog(tester);
    await _enterAndConfirm(tester, '6');
    expect(find.text('6 / 6'), findsOneWidget);
    expect(changes.last, 5);

    await _openDialog(tester);
    await _enterAndConfirm(tester, '1');
    expect(find.text('1 / 6'), findsOneWidget);
    expect(changes.last, 0);
  });

  testWidgets('long folded trace scrolls to the requested step and keeps '
      'it after expanding', (tester) async {
    await _pump(tester, result: _result(200));
    expect(find.text('Expand'), findsOneWidget);
    await _openDialog(tester);
    await _enterAndConfirm(tester, '150');

    expect(find.text('150 / 200'), findsOneWidget);
    expect(find.text('150. q149'), findsOneWidget);
    expect(find.textContaining('149 before'), findsOneWidget);

    await tester.tap(find.text('Expand'));
    await tester.pumpAndSettle();
    expect(find.text('150 / 200'), findsOneWidget);
    expect(find.text('150. q149'), findsOneWidget);
  });

  testWidgets('confirming during playback pauses and navigates', (
    tester,
  ) async {
    final changes = <int>[];
    await _pump(tester, result: _result(30), changes: changes);
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);

    await _openDialog(tester);
    await _enterAndConfirm(tester, '20');

    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.text('20 / 30'), findsOneWidget);
    expect(changes.last, 19);
    final settled = changes.length;
    await tester.pump(const Duration(milliseconds: 300));
    expect(changes.length, settled);
  });

  testWidgets('cancelling keeps the current step', (tester) async {
    final changes = <int>[];
    await _pump(tester, result: _result(4), changes: changes);
    await tester.tap(find.byTooltip('Next Step'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    final changesBefore = List<int>.of(changes);

    await _openDialog(tester);
    await tester.enterText(find.byKey(GoToStepDialog.fieldKey), '4');
    await tester.tap(find.byKey(GoToStepDialog.cancelKey));
    await tester.pumpAndSettle();

    expect(find.byType(GoToStepDialog), findsNothing);
    expect(find.text('2 / 4'), findsOneWidget);
    expect(changes, changesBefore);
  });

  testWidgets('replacing the result closes the dialog without applying', (
    tester,
  ) async {
    final changes = <int>[];
    await _pump(tester, result: _result(4), changes: changes);
    await _openDialog(tester);
    await tester.enterText(find.byKey(GoToStepDialog.fieldKey), '4');

    await _pump(
      tester,
      result: _result(2, prefix: 'p'),
      changes: changes,
    );

    expect(find.byType(GoToStepDialog), findsNothing);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(changes.last, 0);
    expect(changes.contains(3), isFalse);
  });

  testWidgets('empty trace shows no counter and no dialog', (tester) async {
    await _pump(tester, result: _result(0));
    expect(find.byKey(BaseTraceViewer.goToStepKey), findsNothing);
    expect(find.text('No steps recorded'), findsOneWidget);
  });

  testWidgets('localizes the dialog in Portuguese', (tester) async {
    await _pump(tester, result: _result(4), locale: const Locale('pt'));
    expect(find.byTooltip('Ir para o passo…'), findsOneWidget);
    await tester.tap(find.byKey(BaseTraceViewer.goToStepKey));
    await tester.pumpAndSettle();
    expect(find.text('Ir para o passo…'), findsOneWidget);
    expect(find.text('Número do passo (1 a 4)'), findsOneWidget);
    await _enterAndConfirm(tester, '9');
    expect(find.text('Informe um passo entre 1 e 4.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(GoToStepDialog), findsNothing);
  });
}
