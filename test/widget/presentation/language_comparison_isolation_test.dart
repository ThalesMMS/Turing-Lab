//
//  language_comparison_isolation_test.dart
//  Turing Lab
//
//  Regression suite proving that the read-only canvases inside
//  LanguageComparisonViewer are inert with respect to the main FSA workspace.
//  Opening, tapping, dragging, resizing and disposing a comparison canvas must
//  leave the shared automaton provider, the main canvas highlight channel, the
//  undo history and the selected editing tool exactly as they were.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/equivalence_comparison_result.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_highlight_channel.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_viewer.dart';
import 'package:turing_lab/presentation/widgets/read_only_fsa_graphview_canvas.dart';

/// Highlight channel that records every payload it is handed.
///
/// Stands in for whatever channel the workspace installed: if the comparison
/// surface ever replaced it, [SimulationHighlightService.channel] would stop
/// being this instance.
class _RecordingHighlightChannel implements HighlightChannel {
  int clearCount = 0;
  final List<SimulationHighlight> sent = [];

  @override
  void clear() => clearCount++;

  @override
  void send(SimulationHighlight highlight) => sent.add(highlight);
}

FSA _buildFsa({
  required String id,
  required String labelPrefix,
  required int stateCount,
}) {
  final states = <automaton_state.State>[];
  for (var i = 0; i < stateCount; i++) {
    states.add(
      automaton_state.State(
        id: '$id-q$i',
        label: '$labelPrefix$i',
        position: Vector2(120 + i * 180.0, 160),
        isInitial: i == 0,
        isAccepting: i == stateCount - 1,
      ),
    );
  }

  final transitions = <FSATransition>{};
  for (var i = 0; i < stateCount - 1; i++) {
    transitions.add(
      FSATransition.deterministic(
        id: '$id-t$i',
        fromState: states[i],
        toState: states[i + 1],
        symbol: 'a',
      ),
    );
  }

  return FSA(
    id: id,
    name: id,
    states: states.toSet(),
    transitions: transitions,
    alphabet: const {'a', 'b'},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime.utc(2026, 1, 1),
    modified: DateTime.utc(2026, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

EquivalenceComparisonResult _comparisonResult() {
  return EquivalenceComparisonResult(
    originalAutomaton: _buildFsa(id: 'cmp-a', labelPrefix: 'A', stateCount: 3),
    comparedAutomaton: _buildFsa(id: 'cmp-b', labelPrefix: 'B', stateCount: 3),
    productAutomaton: _buildFsa(id: 'cmp-p', labelPrefix: 'P', stateCount: 3),
    isEquivalent: false,
    distinguishingString: 'ab',
    steps: const [
      {'type': 'initialization', 'description': 'Initialize construction'},
    ],
    executionTimeMs: 12,
    timestamp: DateTime.utc(2026, 1, 1),
  );
}

/// Everything the workspace owns, so a test can assert it was left untouched.
///
/// The harness keeps one container, one canvas controller, one highlight
/// service and one tool controller for the whole test, and re-pumps the same
/// tree with or without the comparison surface. That is what makes "opening"
/// and "disposing" a comparison canvas observable rather than a fresh mount.
class _WorkspaceHarness {
  _WorkspaceHarness({
    required this.tester,
    required this.container,
    required this.canvasController,
    required this.highlightService,
    required this.highlightChannel,
    required this.toolController,
    required this.mainAutomaton,
    required this.mountMainCanvas,
  });

  final WidgetTester tester;
  final ProviderContainer container;
  final GraphViewCanvasController canvasController;
  final SimulationHighlightService highlightService;
  final HighlightChannel highlightChannel;
  final AutomatonCanvasToolController toolController;
  final FSA mainAutomaton;
  final bool mountMainCanvas;

  AutomatonStateProviderState get providerState =>
      container.read(automatonStateProvider);

  Future<void> pump({required bool showComparison}) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ProviderScope(
          overrides: [
            canvasHighlightServiceProvider.overrideWithValue(highlightService),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  if (mountMainCanvas)
                    SizedBox(
                      height: 240,
                      child: AutomatonGraphViewCanvas(
                        automaton: mainAutomaton,
                        canvasKey: _mainCanvasKey,
                        controller: canvasController,
                        toolController: toolController,
                      ),
                    ),
                  if (showComparison)
                    Expanded(
                      child: LanguageComparisonViewer(
                        comparisonResult: _comparisonResult(),
                        showProductAutomaton: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final GlobalKey _mainCanvasKey = GlobalKey();
}

Future<_WorkspaceHarness> _createWorkspace(
  WidgetTester tester, {
  bool mountMainCanvas = true,
  HighlightChannel? highlightChannel,
  Size window = const Size(1200, 900),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = window;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  final container = ProviderContainer();
  final mainAutomaton = _buildFsa(
    id: 'main',
    labelPrefix: 'M',
    stateCount: 3,
  );
  container.read(automatonStateProvider.notifier).updateAutomaton(
        mainAutomaton,
      );

  final canvasController = GraphViewCanvasController(
    automatonStateNotifier: container.read(automatonStateProvider.notifier),
  );
  canvasController.synchronize(mainAutomaton);

  // Mirrors fsa_page.dart: the workspace owns the highlight service and the
  // channel that feeds its canvas controller.
  final channel =
      highlightChannel ?? GraphViewSimulationHighlightChannel(canvasController);
  final highlightService = SimulationHighlightService(channel: channel);
  final toolController = AutomatonCanvasToolController(
    AutomatonCanvasTool.addState,
  );

  addTearDown(() {
    canvasController.dispose();
    toolController.dispose();
    container.dispose();
  });

  return _WorkspaceHarness(
    tester: tester,
    container: container,
    canvasController: canvasController,
    highlightService: highlightService,
    highlightChannel: channel,
    toolController: toolController,
    mainAutomaton: mainAutomaton,
    mountMainCanvas: mountMainCanvas,
  );
}

void _expectWorkspaceUntouched(
  _WorkspaceHarness harness,
  AutomatonStateProviderState stateBefore, {
  required String phase,
}) {
  expect(
    identical(harness.providerState, stateBefore),
    isTrue,
    reason: 'automatonStateProvider was replaced during $phase',
  );
  expect(
    identical(harness.providerState.currentAutomaton, harness.mainAutomaton),
    isTrue,
    reason: 'the workspace automaton was mutated during $phase',
  );
  expect(
    identical(harness.highlightService.channel, harness.highlightChannel),
    isTrue,
    reason: 'the main canvas highlight channel was replaced during $phase',
  );
  expect(
    harness.highlightService.dispatchCount,
    0,
    reason: 'the main highlight service emitted during $phase',
  );
  expect(
    harness.canvasController.canUndo,
    isFalse,
    reason: 'undo history changed during $phase',
  );
  expect(
    harness.canvasController.canRedo,
    isFalse,
    reason: 'redo history changed during $phase',
  );
  expect(
    harness.toolController.activeTool,
    AutomatonCanvasTool.addState,
    reason: 'the selected editing tool changed during $phase',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageComparisonViewer isolation', () {
    testWidgets('opening the comparison surface leaves the workspace alone', (
      tester,
    ) async {
      final harness = await _createWorkspace(tester);
      await harness.pump(showComparison: false);

      final stateBefore = harness.providerState;
      expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNothing);

      await harness.pump(showComparison: true);

      expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(3));
      _expectWorkspaceUntouched(harness, stateBefore, phase: 'open');
    });

    testWidgets(
      'tapping, dragging and long-pressing a comparison canvas is inert',
      (tester) async {
        final harness = await _createWorkspace(tester);
        await harness.pump(showComparison: true);
        final stateBefore = harness.providerState;

        final nodeA = find.text('A1');
        expect(nodeA, findsOneWidget);

        await tester.tap(nodeA, warnIfMissed: false);
        await tester.pumpAndSettle();
        _expectWorkspaceUntouched(harness, stateBefore, phase: 'tap');

        await tester.drag(nodeA, const Offset(80, 60), warnIfMissed: false);
        await tester.pumpAndSettle();
        _expectWorkspaceUntouched(harness, stateBefore, phase: 'node drag');

        await tester.longPress(nodeA, warnIfMissed: false);
        await tester.pumpAndSettle();
        _expectWorkspaceUntouched(harness, stateBefore, phase: 'long press');

        final canvasCenter = tester.getCenter(
          find.byType(ReadOnlyFsaGraphViewCanvas).first,
        );
        await tester.dragFrom(canvasCenter, const Offset(-120, -40));
        await tester.pumpAndSettle();
        _expectWorkspaceUntouched(harness, stateBefore, phase: 'canvas pan');

        await tester.tapAt(canvasCenter);
        await tester.pumpAndSettle();
        _expectWorkspaceUntouched(
          harness,
          stateBefore,
          phase: 'empty canvas tap',
        );
      },
    );

    testWidgets('collapsing and expanding the product canvas is inert', (
      tester,
    ) async {
      final harness = await _createWorkspace(tester);
      await harness.pump(showComparison: true);
      final stateBefore = harness.providerState;

      final productLabel = AppLocalizations.of(
        tester.element(find.byType(LanguageComparisonViewer)),
      ).productAutomaton;

      for (final phase in ['collapse', 'expand']) {
        await tester.ensureVisible(find.text(productLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(productLabel));
        await tester.pumpAndSettle();
        _expectWorkspaceUntouched(harness, stateBefore, phase: phase);
      }

      expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(3));
    });

    testWidgets('resizing the comparison surface is inert', (tester) async {
      final harness = await _createWorkspace(tester);
      await harness.pump(showComparison: true);
      final stateBefore = harness.providerState;

      for (final size in const [
        Size(480, 900),
        Size(320, 700),
        Size(1400, 1000),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        _expectWorkspaceUntouched(harness, stateBefore, phase: 'resize $size');
      }
    });

    testWidgets('disposing the comparison surface is inert', (tester) async {
      final recording = _RecordingHighlightChannel();
      final harness = await _createWorkspace(
        tester,
        highlightChannel: recording,
      );
      await harness.pump(showComparison: true);
      final stateBefore = harness.providerState;

      await harness.pump(showComparison: false);

      expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNothing);
      _expectWorkspaceUntouched(harness, stateBefore, phase: 'dispose');
      expect(recording.sent, isEmpty);
      expect(recording.clearCount, 0);
    });

    testWidgets(
      'control: an editable canvas that owns its controller does claim it',
      (tester) async {
        // Guards the assertions above from going vacuous. If installing a
        // highlight channel ever stopped happening at all, this case would
        // fail and the isolation cases would keep passing for the wrong
        // reason.
        final recording = _RecordingHighlightChannel();
        final harness = await _createWorkspace(
          tester,
          mountMainCanvas: false,
          highlightChannel: recording,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: harness.container,
            child: ProviderScope(
              overrides: [
                canvasHighlightServiceProvider.overrideWithValue(
                  harness.highlightService,
                ),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: AutomatonGraphViewCanvas(
                    automaton: harness.mainAutomaton,
                    canvasKey: GlobalKey(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          identical(harness.highlightService.channel, recording),
          isFalse,
          reason: 'an editable canvas installs its own highlight channel',
        );
      },
    );

    testWidgets(
      'a comparison surface mounted alone never claims the highlight channel',
      (tester) async {
        final recording = _RecordingHighlightChannel();
        final harness = await _createWorkspace(
          tester,
          mountMainCanvas: false,
          highlightChannel: recording,
        );
        await harness.pump(showComparison: true);
        final stateBefore = harness.providerState;

        expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(3));
        expect(
          identical(harness.highlightService.channel, recording),
          isTrue,
          reason: 'the comparison canvases installed their own channel',
        );

        await tester.drag(
          find.text('B1'),
          const Offset(50, 50),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        _expectWorkspaceUntouched(harness, stateBefore, phase: 'solo drag');
        expect(recording.sent, isEmpty);
        expect(recording.clearCount, 0);
      },
    );
  });
}
