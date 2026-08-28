import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/graph_layout/graph_layout.dart';
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
import 'package:vector_math/vector_math_64.dart';

// feature-localization-contract: automata-layout
void main() {
  // feature-localization-surface: localized-layout-controls
  // feature-localization-surface: localized-layout-constructive
  // feature-localization-surface: localized-layout-transforms
  // feature-localization-surface: localized-layout-restore
  // feature-localization-surface: localized-layout-confirmation
  // feature-localization-surface: locale-switch-state-preservation
  // feature-localization-surface: formal-content-preservation
  // feature-localization-surface: preview-selection-viewport-preservation
  // feature-localization-surface: undo-redo-preservation
  // feature-localization-surface: responsive-accessibility
  testWidgets(
    'layout workflow preserves preview, selection, viewport, and history in EN/PT',
    (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      final machine = _machine();
      final harness = await _pumpCanvas(
        tester,
        locale: locale,
        machine: machine,
        withFreeNote: true,
      );

      await tester.tap(find.text('Final_δ'), warnIfMissed: false);
      await tester.pump();
      final viewport =
          harness.controller.graphController.transformationController!;
      viewport.value = Matrix4.identity()
        ..translateByDouble(18, 24, 0, 1)
        ..scaleByDouble(1.15, 1.15, 1, 1);
      await tester.pump();
      final viewportBefore = viewport.value.clone();
      final documentBefore = harness.notifier.state.currentAutomaton!.toJson();

      final button = find.byKey(const ValueKey('canvas-toolbar-overflow'));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Canvas action: Arrange automaton states' &&
              widget.properties.hint ==
                  'Previews a layout before applying it to this automaton.',
        ),
        findsOneWidget,
      );
      expect(tester.getSize(button).shortestSide, greaterThanOrEqualTo(44));
      await tester.tap(find.text('Arrange automaton states'));
      await _waitForPreview(tester);

      expect(find.text('Arrange automaton states'), findsWidgets);
      _expectLocalizedPreviewAlternative(tester, languageCode: 'en');
      expect(
        find.textContaining('Changes remain a preview until you apply them.'),
        findsOneWidget,
      );
      expect(find.text('Keep selected states in place'), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('UserState_Ω'), findsWidgets);
      expect(find.text('Final_δ'), findsWidgets);
      _expectAlgorithmLabels(tester, _englishAlgorithms);
      _expectScopeLabels(tester, const [
        'All states',
        'Selected component',
        'Selected states',
      ]);

      final algorithm = find.byKey(const ValueKey('layout-algorithm-field'));
      tester
          .widget<DropdownButtonFormField<GraphLayoutAlgorithmId>>(algorithm)
          .onChanged!(GraphLayoutAlgorithmId.circle);
      await _waitForPreview(tester);
      final previewBefore = _positions(harness.controller);
      expect(harness.controller.canUndo, isFalse);

      locale.value = const Locale('pt', 'BR');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Organizar estados do autômato'), findsWidgets);
      _expectLocalizedPreviewAlternative(tester, languageCode: 'pt');
      expect(
        find.text('Manter os estados selecionados no lugar'),
        findsOneWidget,
      );
      expect(find.text('1 selecionado'), findsOneWidget);
      _expectAlgorithmLabels(tester, _portugueseAlgorithms);
      _expectScopeLabels(tester, const [
        'Todos os estados',
        'Componente selecionado',
        'Estados selecionados',
      ]);
      expect(
        tester
            .widget<DropdownButtonFormField<GraphLayoutAlgorithmId>>(algorithm)
            .initialValue,
        GraphLayoutAlgorithmId.circle,
      );
      expect(_positions(harness.controller), previewBefore);
      expect(viewport.value, viewportBefore);
      expect(harness.notifier.state.currentAutomaton!.toJson(), documentBefore);
      expect(find.text('UserState_Ω'), findsWidgets);
      expect(find.text('Final_δ'), findsWidgets);
      expect(tester.takeException(), isNull);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('layout-apply-button')),
      );
      expect(find.textContaining('estados organizados'), findsOneWidget);
      final arranged = _documentPositions(harness.notifier);
      expect(arranged, isNot(_sourcePositions));
      expect(harness.controller.canUndo, isTrue);

      locale.value = const Locale('pt');
      await tester.pumpAndSettle();
      expect(harness.controller.canUndo, isTrue);
      expect(viewport.value, viewportBefore);
      expect(find.text('UserState_Ω'), findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Ação do canvas: Organizar estados do autômato' &&
              widget.properties.hint ==
                  'Mostra uma prévia do layout antes de aplicá-lo a este autômato.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Organizar estados do autômato'));
      await _waitForPreview(tester);
      expect(
        find.text('Manter os estados selecionados no lugar'),
        findsOneWidget,
      );
      final restoreItem = tester
          .widget<DropdownButton<GraphLayoutAlgorithmId>>(
            find.descendant(
              of: algorithm,
              matching: find.byType(DropdownButton<GraphLayoutAlgorithmId>),
            ),
          )
          .items!
          .singleWhere((item) => item.value == GraphLayoutAlgorithmId.restore);
      expect(restoreItem.enabled, isTrue);

      tester
          .widget<DropdownButtonFormField<GraphLayoutAlgorithmId>>(algorithm)
          .onChanged!(GraphLayoutAlgorithmId.reflectVertical);
      await _waitForPreview(tester);
      expect(find.text('Transformar notas livres com o grafo'), findsOneWidget);
      expect(
        find.text('Notas anexadas sempre acompanham seu estado ou transição.'),
        findsOneWidget,
      );
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('layout-transform-free-notes')),
          )
          .onChanged!(true);
      await tester.pump();
      final noteBefore = _freeNote(harness.container);
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('layout-apply-button')),
      );
      final transformed = _documentPositions(harness.notifier);
      expect(transformed, isNot(arranged));
      expect(_freeNote(harness.container).x, isNot(noteBefore.x));
      expect(_freeNote(harness.container).text, 'User note β');
      expect(harness.controller.undo(), isTrue);
      expect(_documentPositions(harness.notifier), arranged);
      expect(_freeNote(harness.container).x, noteBefore.x);
      expect(harness.controller.redo(), isTrue);
      expect(_documentPositions(harness.notifier), transformed);

      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Organizar estados do autômato'));
      await _waitForPreview(tester);
      tester
          .widget<DropdownButtonFormField<GraphLayoutAlgorithmId>>(algorithm)
          .onChanged!(GraphLayoutAlgorithmId.restore);
      await _waitForPreview(tester);
      expect(find.text('Restaurar layout salvo'), findsOneWidget);
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('layout-apply-button')),
      );
      expect(_documentPositions(harness.notifier), _sourcePositions);
      expect(harness.controller.undo(), isTrue);
      expect(_documentPositions(harness.notifier), transformed);
      expect(find.text('UserState_Ω'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  // feature-localization-surface: localized-layout-empty-validation
  // feature-localization-surface: localized-layout-diagnostics
  // feature-localization-surface: localized-error
  testWidgets('empty and missing-selection diagnostics are localized', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('pt', 'BR'));
    final harness = await _pumpCanvas(
      tester,
      locale: locale,
      machine: _machine(),
    );
    await _openArrange(tester, 'Organizar estados do autômato');
    await _waitForPreview(tester);

    final scope = find.byKey(const ValueKey('layout-scope-field'));
    tester.widget<DropdownButtonFormField<GraphLayoutScope>>(scope).onChanged!(
      GraphLayoutScope.selectedNodes,
    );
    await _waitForSettledDiagnostic(tester);
    expect(
      find.text(
        'Selecione pelo menos um nó para o layout de nós selecionados.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('layout-apply-button')),
          )
          .onPressed,
      isNull,
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('layout-cancel-button')),
    );

    harness.notifier.updateAutomaton(_emptyMachine());
    await tester.pumpAndSettle();
    await _openArrange(tester, 'Organizar estados do autômato');
    await _waitForSettledDiagnostic(tester);
    expect(find.text('O grafo não tem nós para organizar.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _Harness {
  const _Harness({
    required this.container,
    required this.notifier,
    required this.controller,
  });

  final ProviderContainer container;
  final AutomatonStateNotifier notifier;
  final GraphViewCanvasController controller;
}

Future<_Harness> _pumpCanvas(
  WidgetTester tester, {
  required ValueNotifier<Locale> locale,
  required FSA machine,
  bool withFreeNote = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(locale.dispose);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final notifier = AutomatonStateNotifier()..updateAutomaton(machine);
  final controller = GraphViewCanvasController(automatonStateNotifier: notifier)
    ..synchronize(machine);
  final toolController = AutomatonCanvasToolController(
    AutomatonCanvasTool.selection,
  );
  final documentActions = AutomatonCanvasDocumentActionsController();
  addTearDown(controller.dispose);
  addTearDown(toolController.dispose);
  final container = ProviderContainer(
    overrides: [automatonStateProvider.overrideWith((_) => notifier)],
  );
  addTearDown(container.dispose);
  if (withFreeNote) {
    container
        .read(documentAnnotationsProvider.notifier)
        .add(
          key: DefaultFormalSystemIds.fsa,
          documentId: machine.id,
          documentRevision: '1',
          x: 12,
          y: 18,
          text: 'User note β',
        );
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Stack(
                children: [
                  Positioned.fill(
                    child: AutomatonGraphViewCanvas(
                      automaton: ref
                          .watch(automatonStateProvider)
                          .currentAutomaton,
                      canvasKey: GlobalKey(),
                      controller: controller,
                      toolController: toolController,
                      documentActionsController: documentActions,
                      annotationConfig: withFreeNote
                          ? AutomatonCanvasAnnotationConfig(
                              systemKey: DefaultFormalSystemIds.fsa,
                              documentId: machine.id,
                              documentRevision: '1',
                            )
                          : null,
                    ),
                  ),
                  GraphViewCanvasToolbar(
                    controller: controller,
                    onAddState: () {},
                    onArrangeAutomaton: documentActions.arrange,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(
    container: container,
    notifier: notifier,
    controller: controller,
  );
}

Future<void> _openArrange(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('canvas-toolbar-overflow')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
}

Future<void> _waitForPreview(WidgetTester tester) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    final apply = find.byKey(const ValueKey('layout-apply-button'));
    if (apply.evaluate().isNotEmpty &&
        tester.widget<FilledButton>(apply).onPressed != null) {
      await tester.pump();
      return;
    }
  }
  fail('Layout preview did not become applicable.');
}

Future<void> _waitForSettledDiagnostic(WidgetTester tester) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    final dialogProgress = find.descendant(
      of: find.byKey(const ValueKey('automaton-layout-dialog')),
      matching: find.byType(CircularProgressIndicator),
    );
    if (dialogProgress.evaluate().isEmpty) {
      await tester.pump();
      return;
    }
  }
  fail('Layout diagnostic did not settle.');
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
  await tester.pump(const Duration(milliseconds: 100));
}

void _expectAlgorithmLabels(WidgetTester tester, List<String> expected) {
  final dropdown = tester.widget<DropdownButton<GraphLayoutAlgorithmId>>(
    find.descendant(
      of: find.byKey(const ValueKey('layout-algorithm-field')),
      matching: find.byType(DropdownButton<GraphLayoutAlgorithmId>),
    ),
  );
  expect(
    dropdown.items!.map((item) => (item.child as Text).data).toList(),
    expected,
  );
}

void _expectScopeLabels(WidgetTester tester, List<String> expected) {
  final dropdown = tester.widget<DropdownButton<GraphLayoutScope>>(
    find.descendant(
      of: find.byKey(const ValueKey('layout-scope-field')),
      matching: find.byType(DropdownButton<GraphLayoutScope>),
    ),
  );
  expect(
    dropdown.items!.map((item) => (item.child as Text).data).toList(),
    expected,
  );
}

void _expectLocalizedPreviewAlternative(
  WidgetTester tester, {
  required String languageCode,
}) {
  final preview = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.image == true &&
        widget.properties.label != null,
  );
  expect(preview, findsOneWidget);
  final label = tester.widget<Semantics>(preview).properties.label!;
  if (languageCode == 'pt') {
    expect(label, contains('3 estados'));
    expect(label, contains('1 componente'));
  } else {
    expect(label, contains('3 states'));
    expect(label, contains('1 component'));
  }
}

Map<String, Offset> _positions(GraphViewCanvasController controller) => {
  for (final node in controller.nodes) node.id: Offset(node.x, node.y),
};

Map<String, Vector2> _documentPositions(AutomatonStateNotifier notifier) => {
  for (final state in notifier.state.currentAutomaton!.states)
    state.id: state.position,
};

DocumentAnnotation _freeNote(ProviderContainer container) =>
    annotationsForDocument(
      container.read(documentAnnotationsProvider),
      DefaultFormalSystemIds.fsa,
      'user-layout-machine',
    )!.annotations.single;

FSA _machine() {
  final start = formal.State(
    id: 'user-start',
    label: 'UserState_Ω',
    position: _sourcePositions['user-start']!,
    isInitial: true,
  );
  final middle = formal.State(
    id: 'middle',
    label: 'Middle_β',
    position: _sourcePositions['middle']!,
  );
  final end = formal.State(
    id: 'final',
    label: 'Final_δ',
    position: _sourcePositions['final']!,
    isAccepting: true,
  );
  final now = DateTime.utc(2026, 8, 26);
  return FSA(
    id: 'user-layout-machine',
    name: 'User automaton Ω',
    states: {start, middle, end},
    transitions: {
      FSATransition(
        id: 'edge-α',
        fromState: start,
        toState: middle,
        symbol: 'α',
      ),
      FSATransition(id: 'edge-β', fromState: middle, toState: end, symbol: 'β'),
    },
    alphabet: const {'α', 'β'},
    initialState: start,
    acceptingStates: {end},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 420, 320),
  );
}

FSA _emptyMachine() {
  final now = DateTime.utc(2026, 8, 26);
  return FSA(
    id: 'empty-layout-machine',
    name: 'Empty user automaton',
    states: const {},
    transitions: const {},
    alphabet: const {},
    acceptingStates: const {},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 420, 320),
  );
}

final _sourcePositions = <String, Vector2>{
  'user-start': Vector2(40, 40),
  'middle': Vector2(190, 70),
  'final': Vector2(320, 220),
};

const _englishAlgorithms = [
  'Circle',
  'Two circles',
  'Spiral',
  'Hierarchical',
  'Sugiyama layered',
  'Pack components',
  'Force-directed (seeded)',
  'Random (seeded)',
  'Reflect horizontally',
  'Reflect vertically',
  'Rotate 90 degrees',
  'Rotate 180 degrees',
  'Rotate 270 degrees',
  'Fit to viewport',
  'Fill viewport',
  'Restore saved layout',
];

const _portugueseAlgorithms = [
  'Círculo',
  'Dois círculos',
  'Espiral',
  'Hierárquico',
  'Sugiyama em camadas',
  'Agrupar componentes',
  'Direcionado por forças (com semente)',
  'Aleatório (com semente)',
  'Refletir horizontalmente',
  'Refletir verticalmente',
  'Girar 90 graus',
  'Girar 180 graus',
  'Girar 270 graus',
  'Ajustar à área visível',
  'Preencher a área visível',
  'Restaurar layout salvo',
];
