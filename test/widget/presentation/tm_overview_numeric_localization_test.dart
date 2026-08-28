import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  for (final scenario in const [
    (locale: Locale('en'), count: '1,000', label: 'States', metrics: 'Metrics'),
    (
      locale: Locale('pt', 'BR'),
      count: '1.000',
      label: 'Estados',
      metrics: 'Métricas',
    ),
  ]) {
    testWidgets(
      'formats large TM overview counts in ${scenario.locale.languageCode}',
      (tester) async {
        tester.view
          ..physicalSize = const Size(800, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final notifier = TMEditorNotifier()..setTm(_largeMachine());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [tmEditorProvider.overrideWith((_) => notifier)],
            child: MaterialApp(
              locale: scenario.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                appBar: AppBar(
                  leading: const WorkspaceQuickActionsBar(tab: WorkspaceTab.tm),
                  leadingWidth: 144,
                ),
                body: const TMPage(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));

        await tester.tap(find.byTooltip(scenario.metrics));
        await tester.pumpAndSettle();

        expect(
          find.text('${scenario.label}: ${scenario.count}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

TM _largeMachine() {
  final states = <automaton_state.State>{};
  automaton_state.State? initial;
  automaton_state.State? accepting;
  for (var index = 0; index < 1000; index++) {
    final state = automaton_state.State(
      id: 'q$index',
      label: 'q$index',
      position: Vector2((index % 40) * 20.0, (index ~/ 40) * 20.0),
      isInitial: index == 0,
      isAccepting: index == 999,
    );
    states.add(state);
    if (index == 0) initial = state;
    if (index == 999) accepting = state;
  }
  return TM(
    id: 'large-overview',
    name: 'Large overview',
    states: states,
    transitions: const {},
    alphabet: const {'0'},
    initialState: initial,
    acceptingStates: {accepting!},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: const {'0', 'B'},
  );
}
