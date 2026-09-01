import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/moore_page.dart';
import 'package:turing_lab/presentation/transducers/graphview_transducer_canvas_controller.dart';
import 'package:turing_lab/presentation/transducers/moore_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/transducer_editor_state.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('secondary click opens Moore state options', (tester) async {
    final notifier = TransducerEditorNotifier<MooreMachine>(_machine());
    await _pumpWorkspace(tester, notifier: notifier);
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(find.text('Idle')),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transducer-state-label')), findsOneWidget);
    expect(find.byKey(const Key('transducer-state-output')), findsOneWidget);
  });

  testWidgets(
    'Moore publishes one action set and focuses wide Simulation without running',
    (tester) async {
      final notifier = TransducerEditorNotifier<MooreMachine>(_machine());
      final originalDocument = notifier.state.document;
      final triggerFocus = FocusNode(debugLabel: 'Play trigger');
      addTearDown(triggerFocus.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _pumpWorkspace(
        tester,
        notifier: notifier,
        triggerFocus: triggerFocus,
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MoorePage)),
      );
      final actions = container.read(
        workspaceQuickActionsProvider(TransducerFormalSystemIds.moore),
      );
      expect(actions?.onSimulate, isNotNull);
      expect(actions?.onHelp, isNull);
      expect(actions?.onAlgorithms, isNotNull);
      expect(actions?.onEdit, isNull);
      expect(actions?.onMetrics, isNull);
      expect(actions?.onProgress, isNull);
      expect(actions?.onExamples, isNull);
      expect(
        container.read(
          workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy),
        ),
        isNull,
      );

      triggerFocus.requestFocus();
      await tester.pump();
      expect(triggerFocus.hasPrimaryFocus, isTrue);
      actions!.onSimulate!();
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.simulationPanelId),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('transducer-simulation-input')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('transducer-simulation-input')),
            )
            .focusNode
            ?.hasFocus,
        isTrue,
      );
      expect(notifier.state.document, same(originalDocument));
      expect(notifier.state.lastExecution, isNull);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(
          WorkspaceDock.railButtonKey(
            AutomatonWorkspaceScaffold.simulationPanelId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(triggerFocus.hasPrimaryFocus, isTrue);

      final examplesActions = container.read(
        workspaceQuickActionsProvider(TransducerFormalSystemIds.moore),
      )!;
      // Examples now live inside the Algorithms & Examples dock panel.
      examplesActions.onAlgorithms!();
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.algorithmPanelId),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Examples'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('transducer-example-asset/moore_parity')),
        findsOneWidget,
      );
      expect(notifier.state.document, same(originalDocument));
      await tester.tap(
        find.descendant(
          of: find.byKey(
            const ValueKey('transducer-example-asset/moore_parity'),
          ),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.algorithmPanelId),
        ),
        findsNothing,
      );
      expect(notifier.state.document, isNot(same(originalDocument)));

      examplesActions.onSimulate!();
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.simulationPanelId),
        ),
        findsOneWidget,
      );
      tester.view.physicalSize = const Size(430, 900);
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceDock), findsNothing);
      examplesActions.onSimulate!();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('transducer-simulation-sheet')),
        findsOneWidget,
      );
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.simulationPanelId),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const Key('transducer-simulation-sheet')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('transducer-simulation-input')),
        findsNothing,
      );
      examplesActions.onSimulate!();
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.simulationPanelId),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Moore workspace exposes state output without acceptance semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final notifier = TransducerEditorNotifier<MooreMachine>(_machine());
      await _pumpWorkspace(tester, notifier: notifier);

      final canvas = tester.widget<AutomatonGraphViewCanvas>(
        find.byType(AutomatonGraphViewCanvas),
      );
      expect(canvas.customization!.supportsAcceptingStates, isFalse);
      expect(
        find.bySemanticsLabel(
          RegExp(r'State Idle.*Initial state.*State output idle'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Accepting state')), findsNothing);

      final controller =
          canvas.controller!
              as GraphViewTransducerCanvasController<MooreMachine>;
      final edge = controller.edges.single;
      final config = canvas.customization!.transitionConfigBuilder(controller);
      final payload =
          config.initialPayloadBuilder(edge)
              as AutomatonTransducerTransitionPayload;
      expect(payload.input, 'a');
      expect(payload.outputTokens, isEmpty);

      final overlay = config.overlayBuilder(
        tester.element(find.byType(AutomatonGraphViewCanvas)),
        AutomatonTransitionOverlayData(
          fromStateId: 'q0',
          toStateId: 'q1',
          transitionId: 'advance',
          worldAnchor: Offset.zero,
          payload: payload,
          edge: edge,
        ),
        AutomatonTransitionOverlayController(onSubmit: (_) {}, onCancel: () {}),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: overlay),
        ),
      );
      expect(
        find.byKey(const Key('transducer-transition-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('transducer-transition-output')),
        findsNothing,
      );

      semantics.dispose();
    },
  );

  testWidgets('Moore offers coordinated view-on-canvas playback', (
    tester,
  ) async {
    final notifier = TransducerEditorNotifier<MooreMachine>(_machine());
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _pumpWorkspace(tester, notifier: notifier);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoorePage)),
    );
    container
        .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.moore))!
        .onSimulate!();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transducer-simulation-input')),
      'a',
    );
    await tester.ensureVisible(find.byKey(const Key('transducer-run')));
    await tester.tap(find.byKey(const Key('transducer-run')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.ensureVisible(find.text('View on Canvas'));
    await tester.tap(find.text('View on Canvas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    final controller =
        tester
                .widget<AutomatonGraphViewCanvas>(
                  find.byType(AutomatonGraphViewCanvas),
                )
                .controller!
            as GraphViewTransducerCanvasController<MooreMachine>;
    expect(find.byKey(const Key('transducer-simulation-sheet')), findsNothing);
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);
    expect(notifier.state.activeTraceIndex, 0);
    expect(controller.highlightedTransitionIds, {'advance'});
    expect(controller.highlightNotifier.value.stateIds, {'q1'});

    await tester.tap(
      find.descendant(
        of: find.byType(CanvasSimulationPlaybackBar),
        matching: find.byTooltip('Close'),
      ),
    );
    await tester.pump();

    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
    expect(controller.highlightNotifier.value.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile Moore run keeps output trace and highlight through resize',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final notifier = TransducerEditorNotifier<MooreMachine>(_machine());
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _pumpWorkspace(
        tester,
        notifier: notifier,
        textScaler: const TextScaler.linear(2),
      );

      const moreKey = ValueKey('canvas-toolbar-overflow');
      expect(find.byKey(moreKey), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MoorePage)),
      );
      final actions = container.read(
        workspaceQuickActionsProvider(TransducerFormalSystemIds.moore),
      )!;
      actions.onSimulate!();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('transducer-simulation-sheet')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('transducer-simulation-input')),
        'a',
      );
      await tester.ensureVisible(find.byKey(const Key('transducer-run')));
      await tester.tap(find.byKey(const Key('transducer-run')));
      await tester.pump();

      expect(notifier.state.lastExecution, isA<TransducerSuccess>());
      expect(notifier.state.lastExecution!.output.values, ['idle', 'active']);
      expect(notifier.state.lastExecution!.trace, hasLength(1));
      expect(notifier.state.activeTraceIndex, 0);
      final output = find.byKey(const Key('transducer-simulation-output'));
      await tester.scrollUntilVisible(
        output,
        160,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(output, findsOneWidget);
      final canvas = tester.widget<AutomatonGraphViewCanvas>(
        find.byType(AutomatonGraphViewCanvas),
      );
      final controller =
          canvas.controller!
              as GraphViewTransducerCanvasController<MooreMachine>;
      expect(controller.highlightedTransitionIds, {'advance'});
      expect(controller.highlightNotifier.value.stateIds, {'q1'});

      await tester.tap(find.byKey(const Key('transducer-sheet-close')));
      await tester.pump(const Duration(milliseconds: 500));

      tester.view.physicalSize = const Size(1200, 900);
      await tester.pump();
      actions.onSimulate!();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byKey(moreKey), findsOneWidget);
      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.simulationPanelId),
        ),
        findsOneWidget,
      );
      expect(notifier.state.lastExecution, isA<TransducerSuccess>());
      expect(notifier.state.lastExecution!.output.values, ['idle', 'active']);
      expect(notifier.state.lastExecution!.trace, hasLength(1));
      expect(notifier.state.activeTraceIndex, 0);
      expect(controller.highlightedTransitionIds, {'advance'});
      expect(controller.highlightNotifier.value.stateIds, {'q1'});
      expect(find.bySemanticsLabel(RegExp('Accepting state')), findsNothing);

      semantics.dispose();
    },
  );
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required TransducerEditorNotifier<MooreMachine> notifier,
  TextScaler textScaler = TextScaler.noScaling,
  FocusNode? triggerFocus,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [mooreEditorProvider.overrideWith((_) => notifier)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: triggerFocus == null
          ? const MoorePage()
          : Focus(focusNode: triggerFocus, child: const MoorePage()),
    ),
  ),
);

MooreMachine _machine() => MooreMachine(
  id: const TransducerMachineId('moore-widget'),
  name: 'Moore widget',
  revision: const TransducerRevision(0),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: {
    const TransducerOutputSymbol('idle'),
    const TransducerOutputSymbol('active'),
  },
  states: [
    MooreState(
      id: const TransducerStateId('q0'),
      label: 'Idle',
      position: const TransducerPoint(60, 100),
      output: TransducerOutputWord.fromValues(const ['idle']),
      isInitial: true,
    ),
    MooreState(
      id: const TransducerStateId('q1'),
      label: 'Active',
      position: const TransducerPoint(220, 100),
      output: TransducerOutputWord.fromValues(const ['active']),
    ),
  ],
  transitions: const [
    MooreTransition(
      id: TransducerTransitionId('advance'),
      from: TransducerStateId('q0'),
      to: TransducerStateId('q1'),
      input: TransducerInputSymbol('a'),
    ),
  ],
);
