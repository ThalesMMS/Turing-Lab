import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as formal;
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/document_annotations_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_document_actions.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';

void main() {
  testWidgets(
    'production canvas exposes the note manager only through shared More',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final machine = _machine();
      final automatonNotifier = AutomatonStateNotifier()
        ..updateAutomaton(machine);
      final container = ProviderContainer(
        overrides: [
          automatonStateProvider.overrideWith((_) => automatonNotifier),
        ],
      );
      final canvasController = GraphViewCanvasController(
        automatonStateNotifier: automatonNotifier,
      )..synchronize(machine);
      final toolController = AutomatonCanvasToolController();
      final documentActions = AutomatonCanvasDocumentActionsController();
      addTearDown(container.dispose);
      addTearDown(canvasController.dispose);
      addTearDown(toolController.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: AutomatonGraphViewCanvas(
                      automaton: machine,
                      canvasKey: GlobalKey(),
                      controller: canvasController,
                      toolController: toolController,
                      documentActionsController: documentActions,
                      annotationConfig: AutomatonCanvasAnnotationConfig(
                        systemKey: DefaultFormalSystemIds.fsa,
                        documentId: machine.id,
                        documentRevision: '1',
                      ),
                    ),
                  ),
                  GraphViewCanvasToolbar(
                    controller: canvasController,
                    onAddState: () {},
                    onArrangeAutomaton: documentActions.arrange,
                    onImportAutomaton: documentActions.importAutomaton,
                    onDocumentNotes: documentActions.showDocumentNotes,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('automaton-layout-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('automaton-fragment-import-button')),
        findsNothing,
      );
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.byKey(const ValueKey('canvas-toolbar-overflow')));
      await tester.pumpAndSettle();
      expect(find.text('New note'), findsNothing);
      await tester.tap(find.text('Document notes'));
      await tester.pumpAndSettle();

      expect(find.text('Document notes'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Add note'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Note text'),
        'User-authored Ω note',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(container.read(documentAnnotationsProvider), isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Add note'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Note text'),
        'User-authored Ω note',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();
      final collection = annotationsForDocument(
        container.read(documentAnnotationsProvider),
        DefaultFormalSystemIds.fsa,
        machine.id,
      );
      expect(collection!.annotations.single.text, 'User-authored Ω note');

      await tester.tap(find.byTooltip('Undo note change'));
      await tester.pumpAndSettle();
      expect(
        annotationsForDocument(
          container.read(documentAnnotationsProvider),
          DefaultFormalSystemIds.fsa,
          machine.id,
        )!.annotations,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('note collections never bleed into another document', () {
    final notifier = DocumentAnnotationsNotifier();
    notifier.add(
      key: DefaultFormalSystemIds.fsa,
      documentId: 'document-a',
      documentRevision: '1',
      x: 0,
      y: 0,
      text: 'Private note A',
    );

    expect(
      annotationsForDocument(
        notifier.state,
        DefaultFormalSystemIds.fsa,
        'document-b',
      ),
      isNull,
    );
    final documentB = notifier.collectionFor(
      DefaultFormalSystemIds.fsa,
      documentId: 'document-b',
      documentRevision: '1',
    );
    expect(documentB.annotations, isEmpty);
    expect(notifier.canUndo(DefaultFormalSystemIds.fsa), isFalse);
  });
}

FSA _machine() {
  final state = formal.State(
    id: 'q-user',
    label: 'UserState_Ω',
    position: Vector2(120, 120),
    isInitial: true,
    isAccepting: true,
  );
  final now = DateTime.utc(2026, 8, 26);
  return FSA(
    id: 'overflow-document',
    name: 'User machine',
    states: {state},
    transitions: const <FSATransition>{},
    alphabet: const {'Ω'},
    initialState: state,
    acceptingStates: {state},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 320, 400),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}
