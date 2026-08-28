import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/pda_simulation_panel.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  testWidgets('simulation panel stores the mode as a document edit',
      (tester) async {
    final source = _pda();
    final notifier = PDAEditorNotifier()..setPda(source);
    await _pumpPanel(tester, notifier, width: 308);

    await tester.tap(
      find.byKey(const ValueKey('pda-acceptance-mode-dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('empty stack').last);
    await tester.pumpAndSettle();

    final updated = notifier.currentPda!;
    expect(updated.acceptanceMode, PDAAcceptanceMode.emptyStack);
    expect(updated.modified.isAfter(source.modified), isTrue);
    expect(
      find.textContaining('final state ignored'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing the mode clears the previous simulation result',
      (tester) async {
    final notifier = PDAEditorNotifier()..setPda(_pda());
    await _pumpPanel(tester, notifier, width: 308);

    await tester.ensureVisible(find.text('Simulate PDA'));
    await tester.tap(find.text('Simulate PDA'));
    await _pumpUntilFound(tester, find.text('Accepted'));
    expect(find.text('Accepted'), findsOneWidget);

    final dropdown = find.byKey(
      const ValueKey('pda-acceptance-mode-dropdown'),
    );
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('empty stack').last);
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsNothing);
    expect(find.text('No simulation results yet'), findsOneWidget);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _pumpPanel(
  WidgetTester tester,
  PDAEditorNotifier notifier, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [pdaEditorProvider.overrideWith((ref) => notifier)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: PDASimulationPanel()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PDA _pda() {
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );
  return PDA(
    id: 'widget-pda',
    name: 'Widget PDA',
    states: {state},
    transitions: const {},
    alphabet: const {},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
  );
}
