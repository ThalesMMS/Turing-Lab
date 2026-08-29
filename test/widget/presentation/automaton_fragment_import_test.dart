import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/automaton_fragments/automaton_fragments.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_fragment_import.dart';

// feature-localization-contract: automata-conversions-and-fragments
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets('preserves structured registry failures for localized copy', (
    tester,
  ) async {
    final picker = _FragmentFilePicker();
    FilePicker.platform = picker;
    picker.result = FilePickerResult([
      PlatformFile(
        name: 'unknown.bin',
        size: 3,
        bytes: Uint8List.fromList(const [0, 1, 2]),
      ),
    ]);
    final destination = _fsa('destination');
    final notifier = AutomatonStateNotifier()..updateAutomaton(destination);
    final controller = GraphViewCanvasController(
      automatonStateNotifier: notifier,
    )..synchronize(destination);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AutomatonFragmentImportButton(
              systemKey: DefaultFormalSystemIds.fsa,
              destination: destination,
              controller: controller,
              documentId: destination.id,
              documentRevision: '1',
              onCommitted: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('automaton-fragment-import-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('No registered codec recognizes this document.'),
      findsOneWidget,
    );
    expect(find.text('interop.registry.document-unrecognized'), findsNothing);
  });

  testWidgets('localizes raw codec failures in English and Portuguese', (
    tester,
  ) async {
    const source = '<structure><type>fa</type></structure>';
    final cases =
        <({Locale locale, String title, String expected, String forbidden})>[
          (
            locale: const Locale('en'),
            title: 'Cannot import automaton',
            expected: 'JFLAP FSA is missing <automaton>.',
            forbidden: 'A sintaxe do documento é inválida ou está incompleta.',
          ),
          (
            locale: const Locale('pt', 'BR'),
            title: 'Não foi possível importar o autômato',
            expected: 'O FSA JFLAP não contém <automaton>.',
            forbidden: 'JFLAP FSA is missing <automaton>.',
          ),
        ];

    for (final testCase in cases) {
      final picker = _FragmentFilePicker();
      FilePicker.platform = picker;
      picker.result = FilePickerResult([
        PlatformFile(
          name: 'missing-automaton.jff',
          size: source.length,
          bytes: Uint8List.fromList(utf8.encode(source)),
        ),
      ]);
      final destination = _fsa('destination');
      final notifier = AutomatonStateNotifier()..updateAutomaton(destination);
      final controller = GraphViewCanvasController(
        automatonStateNotifier: notifier,
      )..synchronize(destination);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: testCase.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AutomatonFragmentImportButton(
                systemKey: DefaultFormalSystemIds.fsa,
                destination: destination,
                controller: controller,
                documentId: destination.id,
                documentRevision: '1',
                onCommitted: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('automaton-fragment-import-button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(testCase.title), findsOneWidget);
      expect(find.text(testCase.expected), findsOneWidget);
      expect(find.text(testCase.forbidden), findsNothing);
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'review exposes scope, placement, exact changes, and cancellation',
    (tester) async {
      AutomatonFragmentPlan? result;
      await tester.pumpWidget(
        _ReviewHarness(
          destination: _fsa('destination'),
          source: _fsa('source', symbol: 'b'),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();

      expect(find.text('Preview automaton import'), findsOneWidget);
      expect(find.byKey(const ValueKey('fragment-state-q0')), findsOneWidget);
      expect(find.byKey(const ValueKey('fragment-state-q1')), findsOneWidget);
      expect(find.textContaining('2 states, 1 transition'), findsOneWidget);
      expect(find.text('• Input alphabet adds: b.'), findsOneWidget);
      expect(find.text('• Initial state remains q0.'), findsOneWidget);
      expect(find.text('Insertion anchor'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('fragment-apply-button')),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const ValueKey('fragment-state-q0')));
      await tester.tap(find.byKey(const ValueKey('fragment-state-q1')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('fragment-apply-button')),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    },
  );

  testWidgets('PDA semantic conflicts require visible explicit choices', (
    tester,
  ) async {
    AutomatonFragmentPlan? result;
    await tester.pumpWidget(
      _ReviewHarness(
        destination: _pda(
          'destination',
          acceptance: PDAAcceptanceMode.finalState,
          stack: 'Z',
        ),
        source: _pda(
          'source',
          acceptance: PDAAcceptanceMode.emptyStack,
          stack: 'S',
        ),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();

    final applyFinder = find.byKey(const ValueKey('fragment-apply-button'));
    expect(tester.widget<FilledButton>(applyFinder).onPressed, isNull);
    expect(
      find.byKey(const ValueKey('fragment-pda-acceptance-resolution')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fragment-pda-stack-resolution')),
      findsOneWidget,
    );

    final acceptanceFinder = find.byKey(
      const ValueKey('fragment-pda-acceptance-resolution'),
    );
    final stackFinder = find.byKey(
      const ValueKey('fragment-pda-stack-resolution'),
    );
    await tester.ensureVisible(acceptanceFinder);
    await tester.tap(acceptanceFinder);
    await tester.ensureVisible(stackFinder);
    await tester.tap(stackFinder);
    await tester.pump();
    expect(tester.widget<FilledButton>(applyFinder).onPressed, isNotNull);

    await tester.ensureVisible(applyFinder);
    await tester.tap(applyFinder);
    await tester.pumpAndSettle();
    expect(result?.canCommit, isTrue);
    expect(
      (result!.preview! as PDA).acceptanceMode,
      PDAAcceptanceMode.finalState,
    );
  });

  testWidgets('localizes PDA fragment diagnostics in Portuguese', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReviewHarness(
        locale: const Locale('pt', 'BR'),
        destination: _pda(
          'destination',
          acceptance: PDAAcceptanceMode.finalState,
          stack: 'Z',
        ),
        source: _pda(
          'source',
          acceptance: PDAAcceptanceMode.emptyStack,
          stack: 'S',
        ),
        onResult: (_) {},
      ),
    );

    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Os modos de aceitação dos APs são diferentes e exigem um plano de conversão explícito.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Os símbolos iniciais da pilha dos APs são diferentes e exigem um plano de conversão explícito.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('PDA acceptance modes differ'), findsNothing);
    expect(
      find.textContaining('PDA initial stack symbols differ'),
      findsNothing,
    );
  });

  testWidgets('formats and parses insertion anchors in the active locale', (
    tester,
  ) async {
    Future<String> openAndReadAnchorX(Locale locale) async {
      await tester.pumpWidget(
        _ReviewHarness(
          locale: locale,
          destination: _fsa('destination'),
          source: _fsa('source'),
          onResult: (_) {},
        ),
      );
      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();
      final value = tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!
          .text;
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      return value;
    }

    expect(await openAndReadAnchorX(const Locale('en')), '120.0');
    expect(await openAndReadAnchorX(const Locale('pt', 'BR')), '120,0');

    AutomatonFragmentPlan? result;
    await tester.pumpWidget(
      _ReviewHarness(
        locale: const Locale('pt', 'BR'),
        destination: _fsa('destination'),
        source: _fsa('source'),
        initialAnchor: Vector2(500, 600),
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '500,5');
    await tester.pump();
    final apply = find.byKey(const ValueKey('fragment-apply-button'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();

    final importedState = (result!.preview! as FSA).states.singleWhere(
      (state) => state.id == 'import_source_q0',
    );
    expect(importedState.position.x, closeTo(500.5, 0.001));

    for (final testCase in const [
      (input: '100,5', expectedPosition: 180.5),
      (input: '1,000', expectedPosition: 1000.0),
    ]) {
      result = null;
      await tester.pumpWidget(
        _ReviewHarness(
          locale: const Locale('en'),
          destination: _fsa(
            'destination',
          ).copyWith(bounds: const math.Rectangle<double>(0, 0, 2000, 2000)),
          source: _fsa('source'),
          initialAnchor: Vector2.zero(),
          onResult: (value) => result = value,
        ),
      );
      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, testCase.input);
      await tester.pump();
      final applyButton = find.byKey(const ValueKey('fragment-apply-button'));
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      final parsedState = (result!.preview! as FSA).states.singleWhere(
        (state) => state.id == 'import_source_q0',
      );
      expect(parsedState.position.x, closeTo(testCase.expectedPosition, 0.001));
    }
  });

  testWidgets(
    'review remains scrollable on a narrow high-text-scale viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(2),
          ),
          child: _ReviewHarness(
            destination: _fsa('destination'),
            source: _fsa('source'),
            onResult: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'review localizes state selection semantics at narrow high text scale',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      Widget review(Locale locale) => _ReviewHarness(
        locale: locale,
        destination: _fsa('destination'),
        source: _fsa('source'),
        onResult: (_) {},
      );

      await tester.pumpWidget(review(const Locale('en')));
      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('fragment-state-q0')))
            .label,
        'State q0.',
      );
      final stateData = tester
          .getSemantics(find.byKey(const ValueKey('fragment-state-q0')))
          .getSemanticsData();
      expect(stateData.flagsCollection.isChecked, ui.CheckedState.isTrue);
      expect(stateData.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(review(const Locale('pt', 'BR')));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('fragment-state-q0')))
            .label,
        'Estado q0.',
      );
      expect(tester.takeException(), isNull);

      semantics.dispose();
    },
  );

  testWidgets(
    'review localizes visible import controls at narrow high text scale',
    (tester) async {
      final semantics = tester.ensureSemantics();
      AutomatonFragmentPlan? result;
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(
        _ReviewHarness(
          locale: const Locale('pt', 'BR'),
          destination: _fsa('destination'),
          source: _fsa('source'),
          onResult: (value) => result = value,
        ),
      );
      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();

      expect(find.text('Prévia da importação do autômato'), findsOneWidget);
      expect(find.text('Estados a importar'), findsOneWidget);
      expect(find.text('Âncora de inserção'), findsOneWidget);
      expect(find.text('Alterações exatas'), findsOneWidget);
      expect(find.text('Aplicar'), findsOneWidget);
      expect(find.text('Apply'), findsNothing);
      final state = find.byKey(const ValueKey('fragment-state-q1'));
      final otherState = find.byKey(const ValueKey('fragment-state-q0'));
      await tester.ensureVisible(state);
      await tester.tap(state);
      await tester.ensureVisible(otherState);
      await tester.tap(otherState);
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('fragment-apply-button')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(otherState);
      await tester.tap(state);
      await tester.pump();
      final apply = find.byKey(const ValueKey('fragment-apply-button'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(result?.canCommit, isTrue);
      expect(
        (result!.preview! as FSA).states.map((item) => item.id),
        containsAll(<String>['q0', 'q1']),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

final class _FragmentFilePicker extends FilePicker {
  FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => result;
}

class _ReviewHarness extends StatelessWidget {
  const _ReviewHarness({
    this.locale,
    required this.destination,
    required this.source,
    this.initialAnchor,
    required this.onResult,
  });

  final Locale? locale;
  final Object destination;
  final Object source;
  final Vector2? initialAnchor;
  final ValueChanged<AutomatonFragmentPlan?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () async {
                onResult(
                  await showAutomatonFragmentReviewDialog(
                    context,
                    destination: destination,
                    source: source,
                    destinationRevision: '1',
                    initialAnchor: initialAnchor ?? Vector2(120, 180),
                  ),
                );
              },
              child: const Text('Open review'),
            ),
          ),
        ),
      ),
    );
  }
}

FSA _fsa(String id, {String symbol = 'a'}) {
  final now = DateTime.utc(2026, 8, 25);
  final q0 = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return FSA(
    id: id,
    name: id,
    states: {q0, q1},
    transitions: <Transition>{
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: {symbol},
      ),
    },
    alphabet: {symbol},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
  );
}

PDA _pda(
  String id, {
  required PDAAcceptanceMode acceptance,
  required String stack,
}) {
  final fsa = _fsa(id);
  return PDA(
    id: id,
    name: id,
    states: fsa.states,
    transitions: const {},
    alphabet: const {},
    initialState: fsa.initialState,
    acceptingStates: fsa.acceptingStates,
    created: fsa.created,
    modified: fsa.modified,
    bounds: fsa.bounds,
    stackAlphabet: {stack},
    initialStackSymbol: stack,
    acceptanceMode: acceptance,
  );
}
