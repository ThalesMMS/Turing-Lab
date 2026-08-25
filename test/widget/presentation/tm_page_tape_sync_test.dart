import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/tm_page.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/collapsible_canvas_panel.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';
import 'package:turing_lab/presentation/widgets/tm_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/tm/tape_drawer.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';

import '../../support/workspace_dock_helpers.dart';

TMEditorNotifier _readyTmEditor({String blankSymbol = '_'}) {
  final notifier = TMEditorNotifier()
    ..upsertState(
      id: 'q0',
      label: 'q0',
      x: 0,
      y: 0,
      isInitial: true,
      isAccepting: true,
    );
  notifier.setTm(
    notifier.state.tm!.copyWith(
      tapeAlphabet: {'a', 'b', blankSymbol},
      blankSymbol: blankSymbol,
    ),
  );
  return notifier;
}

TMEditorNotifier _traceTmEditor() {
  final notifier = TMEditorNotifier()
    ..upsertState(
      id: 'q0',
      label: 'q0',
      x: 0,
      y: 0,
      isInitial: true,
    )
    ..upsertState(id: 'q1', label: 'q1', x: 120, y: 0)
    ..upsertState(
      id: 'q2',
      label: 'q2',
      x: 240,
      y: 0,
      isAccepting: true,
    )
    ..addOrUpdateTransition(
      id: 't0',
      fromStateId: 'q0',
      toStateId: 'q1',
      readSymbol: 'a',
      writeSymbol: 'X',
      direction: TapeDirection.right,
    )
    ..addOrUpdateTransition(
      id: 't1',
      fromStateId: 'q1',
      toStateId: 'q2',
      readSymbol: 'b',
      writeSymbol: 'Y',
      direction: TapeDirection.right,
    );
  notifier.setTm(
    notifier.state.tm!.copyWith(
      alphabet: {'a', 'b'},
      tapeAlphabet: {'a', 'b', 'X', 'Y', '_'},
      blankSymbol: '_',
    ),
  );
  return notifier;
}

Future<void> _pumpTmPage(
  WidgetTester tester, {
  required Size size,
  required TMEditorNotifier notifier,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        tmEditorProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
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
  await tester.pump();
  // Desktop keeps an indeterminate examples progress indicator alive while
  // assets load. Advance the finite GraphView fit animation explicitly.
  await tester.pump(const Duration(milliseconds: 700));
}

TMTapePanel _workspaceTapePanel(WidgetTester tester) {
  return tester
      .widgetList<TMTapePanel>(find.byType(TMTapePanel))
      .singleWhere((panel) => !panel.isSimulating);
}

Future<void> _pumpUntilWorkspaceTape(
  WidgetTester tester,
  List<String> expectedCells,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (listEquals(
      _workspaceTapePanel(tester).tapeState.cells,
      expectedCells,
    )) {
      return;
    }
  }
  fail('Timed out waiting for workspace tape $expectedCells');
}

void main() {
  testWidgets('TM mobile tape inspector collapses out of the canvas', (
    tester,
  ) async {
    final notifier = _readyTmEditor();
    await _pumpTmPage(
      tester,
      size: const Size(800, 900),
      notifier: notifier,
    );

    expect(find.byType(CollapsibleCanvasPanel), findsOneWidget);
    expect(find.byType(TMTapePanel), findsOneWidget);

    // Tapping the panel body (outside interactive children) collapses it.
    await tester.tapAt(
      tester.getTopLeft(find.byType(CollapsibleCanvasPanel)) +
          const Offset(4, 4),
    );
    await tester.pump();

    expect(find.byType(TMTapePanel), findsNothing);
    expect(
      tester.getSize(find.byType(CollapsibleCanvasPanel)),
      const Size.square(48),
    );
  });

  for (final width in const [1200.0, 1500.0]) {
    testWidgets('TM at ${width.toInt()}px docks tape outside the canvas', (
      tester,
    ) async {
      final notifier = _readyTmEditor();
      await _pumpTmPage(
        tester,
        size: Size(width, 900),
        notifier: notifier,
      );

      final canvasRect = tester.getRect(find.byType(TMCanvasGraphView));
      final tapeRect = tester.getRect(find.byType(TMTapePanel).first);

      expect(canvasRect.overlaps(tapeRect), isFalse);
    });
  }

  testWidgets('TMPage initializes its tape from the loaded machine blank', (
    tester,
  ) async {
    final notifier = _readyTmEditor();
    await _pumpTmPage(
      tester,
      size: const Size(800, 900),
      notifier: notifier,
    );

    final workspaceTape = _workspaceTapePanel(tester).tapeState;
    expect(workspaceTape.cells, isEmpty);
    expect(workspaceTape.headPosition, 0);
    expect(workspaceTape.blankSymbol, '_');
  });

  testWidgets(
    'TMPage resets the mobile tape when the machine changes after sheet close',
    (tester) async {
      final notifier = _readyTmEditor();
      await _pumpTmPage(
        tester,
        size: const Size(800, 900),
        notifier: notifier,
      );

      await tester.tap(find.byTooltip('Simulate'));
      await tester.pumpAndSettle();
      final simulationPanel = tester.widget<TMSimulationPanel>(
        find.byType(TMSimulationPanel),
      );
      simulationPanel.onTapeChanged!(
        const TapeState(
          cells: ['X', 'b'],
          headPosition: 1,
          blankSymbol: '_',
        ),
      );
      await tester.pump();
      expect(_workspaceTapePanel(tester).tapeState.cells, ['X', 'b']);

      Navigator.of(tester.element(find.byType(TMSimulationPanel))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(TMSimulationPanel), findsNothing);

      notifier.setTm(
        notifier.state.tm!.copyWith(
          id: 'replacement-tm',
          name: 'Replacement TM',
          tapeAlphabet: {'#'},
          blankSymbol: '#',
        ),
      );
      await tester.pumpAndSettle();

      final resetTape = _workspaceTapePanel(tester).tapeState;
      expect(resetTape.cells, isEmpty);
      expect(resetTape.headPosition, 0);
      expect(resetTape.blankSymbol, '#');
    },
  );

  testWidgets('TMPage mobile simulation and trace drive the workspace tape', (
    tester,
  ) async {
    final notifier = _traceTmEditor();
    await _pumpTmPage(
      tester,
      size: const Size(800, 900),
      notifier: notifier,
    );

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(find.text('Simulate TM'));
    await _pumpUntilWorkspaceTape(tester, const ['a', 'b']);

    var tape = _workspaceTapePanel(tester).tapeState;
    expect(tape.cells, ['a', 'b']);
    expect(tape.headPosition, 0);
    expect(tape.blankSymbol, '_');

    await tester.tap(find.byTooltip('Next Step'));
    await _pumpUntilWorkspaceTape(tester, const ['X', 'b']);
    tape = _workspaceTapePanel(tester).tapeState;
    expect(tape.cells, ['X', 'b']);
    expect(tape.headPosition, 1);

    await tester.tap(find.byTooltip('Previous Step'));
    await _pumpUntilWorkspaceTape(tester, const ['a', 'b']);
    tape = _workspaceTapePanel(tester).tapeState;
    expect(tape.cells, ['a', 'b']);
    expect(tape.headPosition, 0);
  });

  for (final layout in <({String name, Size size, bool opensSheet})>[
    (name: 'mobile', size: const Size(800, 900), opensSheet: true),
    (name: 'desktop', size: const Size(1600, 900), opensSheet: false),
  ]) {
    testWidgets(
      'TMPage ${layout.name} projects simulation tape changes into the workspace',
      (tester) async {
        final notifier = _readyTmEditor();
        await _pumpTmPage(tester, size: layout.size, notifier: notifier);

        if (layout.opensSheet) {
          await tester.tap(find.byTooltip('Simulate'));
          await tester.pumpAndSettle();
        } else {
          await openWorkspaceSimulationPanel(tester);
        }

        final simulationPanel = tester.widget<TMSimulationPanel>(
          find.byType(TMSimulationPanel),
        );
        expect(simulationPanel.onTapeChanged, isNotNull);

        simulationPanel.onTapeChanged!(
          const TapeState(
            cells: ['X', 'b'],
            headPosition: 1,
            blankSymbol: '_',
          ),
        );
        await tester.pump();

        final workspaceTape = _workspaceTapePanel(tester).tapeState;
        expect(workspaceTape.cells, ['X', 'b']);
        expect(workspaceTape.headPosition, 1);
        expect(workspaceTape.blankSymbol, '_');
      },
    );
  }
}
