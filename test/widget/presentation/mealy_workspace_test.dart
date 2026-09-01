import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/mealy_page.dart';
import 'package:turing_lab/presentation/transducers/graphview_transducer_canvas_controller.dart';
import 'package:turing_lab/presentation/transducers/mealy_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/transducer_editor_state.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';

void main() {
  testWidgets('secondary click opens Mealy state options', (tester) async {
    final notifier = TransducerEditorNotifier<MealyMachine>(_machine());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mealyEditorProvider.overrideWith((_) => notifier)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealyPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(find.text('Idle')),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transducer-state-label')), findsOneWidget);
  });

  testWidgets(
    'Mealy publishes one action set and opens compact Simulation without running',
    (tester) async {
      final notifier = TransducerEditorNotifier<MealyMachine>(_machine());
      final originalDocument = notifier.state.document;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mealyEditorProvider.overrideWith((_) => notifier)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MealyPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MealyPage)),
      );
      final actions = container.read(
        workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy),
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
          workspaceQuickActionsProvider(TransducerFormalSystemIds.moore),
        ),
        isNull,
      );
      expect(
        find.byKey(const Key('transducer-simulation-input')),
        findsNothing,
      );

      actions!.onSimulate!();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('transducer-simulation-sheet')),
        findsOneWidget,
      );
      final input = find.byKey(const Key('transducer-simulation-input'));
      expect(input, findsOneWidget);
      expect(notifier.state.document, same(originalDocument));
      expect(notifier.state.lastExecution, isNull);
      await tester.enterText(input, 'b');
      await tester.tap(find.byKey(const Key('transducer-sheet-close')));
      await tester.pumpAndSettle();
      expect(input, findsNothing);
      expect(notifier.state.document, same(originalDocument));
      expect(notifier.state.lastExecution, isNull);

      actions.onSimulate!();
      await tester.pumpAndSettle();

      expect(input, findsOneWidget);
      expect(tester.widget<TextField>(input).controller?.text, isEmpty);
      expect(notifier.state.document, same(originalDocument));
      expect(notifier.state.lastExecution, isNull);

      await tester.tap(find.byKey(const Key('transducer-sheet-close')));
      await tester.pumpAndSettle();
      actions.onAlgorithms!();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('transducer-tools-sheet')), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);

      // The examples now live inside the Algorithms & Examples sheet.
      await tester.tap(find.byIcon(Icons.school_outlined));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('transducer-example-mealy.identity')),
        findsOneWidget,
      );
      expect(notifier.state.document, same(originalDocument));
      await tester.tap(find.byKey(const Key('transducer-sheet-close')));
      await tester.pumpAndSettle();
      expect(notifier.state.document, same(originalDocument));
    },
  );

  testWidgets('Mealy offers view-on-canvas playback for a compact run', (
    tester,
  ) async {
    final notifier = TransducerEditorNotifier<MealyMachine>(_machine());
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mealyEditorProvider.overrideWith((_) => notifier)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealyPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MealyPage)),
    );
    container
        .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy))!
        .onSimulate!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('transducer-simulation-input')),
      'b\nb',
    );
    final run = find.byKey(const Key('transducer-run'));
    await tester.ensureVisible(run);
    await tester.tap(run);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    final viewOnCanvas = find.text('View on Canvas');
    await tester.ensureVisible(viewOnCanvas);
    await tester.tap(viewOnCanvas);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // The sheet closes and the playback bar takes over the canvas.
    expect(find.byKey(const Key('transducer-simulation-sheet')), findsNothing);
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);
    final canvas = tester.widget<AutomatonGraphViewCanvas>(
      find.byType(AutomatonGraphViewCanvas),
    );
    final controller =
        canvas.controller! as GraphViewTransducerCanvasController<MealyMachine>;
    expect(controller.highlightedTransitionIds, {'empty'});
    expect(notifier.state.activeTraceIndex, 0);

    await tester.tap(
      find.descendant(
        of: find.byType(CanvasSimulationPlaybackBar),
        matching: find.byTooltip('Next Step'),
      ),
    );
    await tester.pump();
    expect(notifier.state.activeTraceIndex, 1);
    expect(find.text('Step 2 of 2'), findsOneWidget);

    container
        .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy))!
        .onSimulate!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    final traceTiles = find.byType(ListTile);
    expect(traceTiles, findsNWidgets(2));
    expect(tester.widget<ListTile>(traceTiles.at(1)).selected, isTrue);
    await tester.tap(traceTiles.first);
    await tester.pump();
    expect(notifier.state.activeTraceIndex, 0);
    expect(find.text('Step 1 of 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('transducer-sheet-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
    expect(controller.highlightNotifier.value.isEmpty, isTrue);

    tester.view.physicalSize = const Size(430, 900);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Mealy invalidates canvas playback when the revision changes', (
    tester,
  ) async {
    final notifier = TransducerEditorNotifier<MealyMachine>(_machine());
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mealyEditorProvider.overrideWith((_) => notifier)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealyPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MealyPage)),
    );
    container
        .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy))!
        .onSimulate!();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transducer-simulation-input')),
      'b',
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
            as GraphViewTransducerCanvasController<MealyMachine>;
    expect(find.byType(CanvasSimulationPlaybackBar), findsOneWidget);
    expect(controller.highlightedTransitionIds, {'empty'});

    notifier.replaceDocument(
      notifier.state.document.copyWith(revision: const TransducerRevision(1)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(notifier.state.document.id.value, 'mealy-widget');
    expect(notifier.state.lastExecution, isNull);
    expect(find.byType(CanvasSimulationPlaybackBar), findsNothing);
    expect(controller.highlightNotifier.value.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mealy Play safely opens Simulation for an empty machine', (
    tester,
  ) async {
    final notifier = TransducerEditorNotifier<MealyMachine>(
      createEmptyMealyMachine(),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mealyEditorProvider.overrideWith((_) => notifier)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealyPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MealyPage)),
    );
    container
        .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy))!
        .onSimulate!();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('transducer-simulation-input')),
      findsOneWidget,
    );
    expect(notifier.state.lastExecution, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile Mealy binding exposes edge output and keeps trace on resize',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final notifier = TransducerEditorNotifier<MealyMachine>(_machine());
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mealyEditorProvider.overrideWith((_) => notifier)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const MealyPage(),
          ),
        ),
      );

      const moreKey = ValueKey('canvas-toolbar-overflow');
      expect(find.byKey(moreKey), findsOneWidget);

      final canvas = tester.widget<AutomatonGraphViewCanvas>(
        find.byType(AutomatonGraphViewCanvas),
      );
      expect(canvas.customization!.supportsAcceptingStates, isFalse);
      expect(find.bySemanticsLabel(RegExp('Accepting state')), findsNothing);

      final controller =
          canvas.controller!
              as GraphViewTransducerCanvasController<MealyMachine>;
      final edge = controller.edges.single;
      final semanticsDetails = canvas.customization!.edgeSemanticsDetails!(
        AppLocalizations.of(
          tester.element(find.byType(AutomatonGraphViewCanvas)),
        ),
        edge,
      );
      expect(semanticsDetails, contains('Input b'));
      expect(semanticsDetails, contains('empty output'));
      final config = canvas.customization!.transitionConfigBuilder(controller);
      final payload =
          config.initialPayloadBuilder(edge)
              as AutomatonTransducerTransitionPayload;
      expect(payload.input, 'b');
      expect(payload.outputTokens, isEmpty);
      final overlay = config.overlayBuilder(
        tester.element(find.byType(AutomatonGraphViewCanvas)),
        AutomatonTransitionOverlayData(
          fromStateId: 'q0',
          toStateId: 'q0',
          transitionId: 'empty',
          worldAnchor: Offset.zero,
          payload: payload,
          edge: edge,
        ),
        AutomatonTransitionOverlayController(onSubmit: (_) {}, onCancel: () {}),
      );
      expect(
        find.descendant(
          of: find.byType(AutomatonGraphViewCanvas),
          matching: find.byKey(const Key('transducer-transition-output')),
        ),
        findsNothing,
      );
      expect(overlay, isNotNull);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MealyPage)),
      );
      container
          .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy))!
          .onSimulate!();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transducer-simulation-input')),
        'b',
      );
      await tester.ensureVisible(find.byKey(const Key('transducer-run')));
      await tester.tap(find.byKey(const Key('transducer-run')));
      await tester.pump();

      expect(notifier.state.lastExecution, isA<TransducerSuccess>());
      expect(notifier.state.lastExecution!.output.values, isEmpty);
      expect(notifier.state.activeTraceIndex, 0);
      expect(controller.highlightedTransitionIds, {'empty'});

      tester.view.physicalSize = const Size(1200, 900);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(moreKey), findsOneWidget);
      expect(notifier.state.lastExecution, isA<TransducerSuccess>());
      expect(controller.highlightedTransitionIds, {'empty'});
      semantics.dispose();
    },
  );
}

MealyMachine _machine() => MealyMachine(
  id: const TransducerMachineId('mealy-widget'),
  name: 'Mealy widget',
  revision: const TransducerRevision(0),
  inputAlphabet: {const TransducerInputSymbol('b')},
  outputAlphabet: {const TransducerOutputSymbol('x')},
  states: const [
    MealyState(
      id: TransducerStateId('q0'),
      label: 'Idle',
      position: TransducerPoint(120, 120),
      isInitial: true,
    ),
  ],
  transitions: const [
    MealyTransition(
      id: TransducerTransitionId('empty'),
      from: TransducerStateId('q0'),
      to: TransducerStateId('q0'),
      input: TransducerInputSymbol('b'),
      output: TransducerOutputWord.empty,
    ),
  ],
);
