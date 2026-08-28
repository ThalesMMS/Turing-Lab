import 'dart:collection';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/transducers/mealy_example_catalog.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/mealy_page.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/transducers/mealy_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/transducer_editor_state.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_review_dialog.dart';

// feature-localization-contract: transducer-mealy
void main() {
  // feature-localization-surface: localized-error
  // feature-localization-surface: localized-valid-simulation
  // feature-localization-surface: localized-comparison-result
  // feature-localization-surface: locale-switch-state-preservation
  // feature-localization-surface: localized-example-metadata
  // feature-localization-surface: formal-content-preservation
  testWidgets(
    'Mealy runs, compares, and loads examples across EN/PT at 320 px',
    (tester) async {
      final examples = await MealyExampleCatalog().loadExamples();
      final identity = examples
          .singleWhere((example) => example.id == 'mealy.identity')
          .payload;
      final notifier = TransducerEditorNotifier<MealyMachine>(identity);
      final locale = ValueNotifier(const Locale('en'));
      final container = await _pumpWorkspace(tester, notifier, locale);
      _openSimulation(container);
      await tester.pumpAndSettle();
      final originalDocument = notifier.state.document;

      final input = find.byKey(const Key('transducer-simulation-input'));
      await _runSimulation(tester, input: input, value: '0');
      expect(
        find.text(
          'The simulation completed after one input token. '
          'One output token was produced.',
        ),
        findsOneWidget,
      );
      expect(notifier.state.lastExecution, isA<TransducerSuccess>());
      expect(notifier.state.lastExecution?.output.values, ['0']);

      await _runSimulation(tester, input: input, value: 'outside');
      expect(
        find.text('Input symbol "outside" is outside the input alphabet.'),
        findsOneWidget,
      );
      final originalOutcome = notifier.state.lastExecution;
      expect(originalOutcome, isA<TransducerInvalidInput>());

      locale.value = const Locale('pt');
      await tester.pumpAndSettle();

      expect(
        find.text(
          'O símbolo de entrada "outside" não pertence ao alfabeto de entrada.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(input).controller?.text, 'outside');
      expect(notifier.state.document, same(originalDocument));
      expect(notifier.state.lastExecution, same(originalOutcome));
      expect(notifier.state.document.states.single.label, 'q0');

      await _runSimulation(tester, input: input, value: '1');
      expect(
        find.text(
          'A simulação terminou após um token de entrada. '
          'Um token de saída foi produzido.',
        ),
        findsOneWidget,
      );
      expect(notifier.state.lastExecution?.output.values, ['1']);

      await _closeCompactSheet(tester);
      _openTools(container);
      await _pumpSurface(tester);
      await tester.tap(find.text('Comparar saídas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final selector = find.byKey(
        const ValueKey('select_transducer_comparison_machine'),
      );
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Transdutor identidade'), findsOneWidget);
      expect(find.text('Saída de paridade'), findsOneWidget);
      expect(find.text('Identity transducer'), findsNothing);
      await tester.tap(find.text('Transdutor identidade'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final compare = find.byKey(const ValueKey('compare_transducers'));
      await tester.ensureVisible(compare);
      await tester.tap(compare);
      await tester.pump();
      expect(find.text('Exatamente equivalentes'), findsOneWidget);

      await _closeCompactSheet(tester);
      await _openExamples(tester, container);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Transdutor identidade'), findsOneWidget);
      final parityTile = find.byKey(
        const ValueKey('transducer-example-mealy.parity'),
      );
      final loadParity = find.descendant(
        of: parityTile,
        matching: find.text('Carregar exemplo'),
      );
      await _scrollUntilBuilt(
        tester,
        loadParity,
        scrollDelta: const Offset(0, -400),
      );
      // Invoke the button directly: taller example cards (e.g. suggested
      // simulations) can leave the button partially obscured at 320 px.
      tester
          .widget<FilledButton>(
            find.ancestor(of: loadParity, matching: find.byType(FilledButton)),
          )
          .onPressed!();
      await tester.pump();

      expect(notifier.state.document.id.value, 'mealy_parity');
      expect(notifier.state.document.name, 'Parity output');
      expect(notifier.state.document.states.first.label, 'even');
      expect(tester.takeException(), isNull);
    },
  );

  // feature-localization-surface: localized-editor-fields
  testWidgets('Mealy edits alphabet fields without losing formal content', (
    tester,
  ) async {
    final notifier = TransducerEditorNotifier<MealyMachine>(_machine());
    final locale = ValueNotifier(const Locale('en'));
    final container = await _pumpWorkspace(tester, notifier, locale);
    _openTools(container);
    await _pumpSurface(tester);
    await _selectToolsTab(tester, Icons.tune);

    final inputAlphabet = find.byKey(const Key('transducer-input-alphabet'));
    final outputAlphabet = find.byKey(const Key('transducer-output-alphabet'));
    final apply = find.byKey(const Key('transducer-apply-alphabets'));
    await tester.ensureVisible(inputAlphabet);
    expect(
      tester.widget<TextField>(inputAlphabet).decoration?.labelText,
      'Input alphabet',
    );
    await tester.enterText(inputAlphabet, 'a\nb');
    await _scrollUntilBuilt(
      tester,
      outputAlphabet,
      scrollDelta: const Offset(0, -300),
    );
    expect(
      tester.widget<TextField>(outputAlphabet).decoration?.labelText,
      'Output alphabet',
    );
    await tester.enterText(outputAlphabet, 'x\ny');
    await _scrollUntilBuilt(tester, apply, scrollDelta: const Offset(0, -300));
    tester.widget<FilledButton>(apply).onPressed!();
    await tester.pump();

    expect(
      notifier.state.document.inputAlphabet.map((symbol) => symbol.value),
      unorderedEquals(['a', 'b']),
    );
    expect(
      notifier.state.document.outputAlphabet.map((symbol) => symbol.value),
      unorderedEquals(['x', 'y']),
    );
    expect(notifier.state.document.states.single.label, 'Idle');
    expect(notifier.state.document.transitions.single.output.values, ['x']);

    locale.value = const Locale('pt');
    await _pumpSurface(tester);
    await _scrollUntilBuilt(
      tester,
      inputAlphabet,
      scrollDelta: const Offset(0, 600),
    );
    expect(
      tester.widget<TextField>(inputAlphabet).decoration?.labelText,
      'Alfabeto de entrada',
    );
    expect(tester.widget<TextField>(inputAlphabet).controller?.text, 'a\nb');
    await _scrollUntilBuilt(
      tester,
      outputAlphabet,
      scrollDelta: const Offset(0, -300),
    );
    expect(
      tester.widget<TextField>(outputAlphabet).decoration?.labelText,
      'Alfabeto de saída',
    );
    expect(tester.widget<TextField>(outputAlphabet).controller?.text, 'x\ny');
    await _scrollUntilBuilt(tester, apply, scrollDelta: const Offset(0, -300));
    expect(find.text('Aplicar alfabetos'), findsOneWidget);
    expect(notifier.state.document.states.single.label, 'Idle');
    expect(tester.takeException(), isNull);
  });

  // feature-localization-surface: localized-import-export
  testWidgets('Mealy exports in EN and imports in PT through production UI', (
    tester,
  ) async {
    final picker = _FakeFilePicker();
    FilePicker.platform = picker;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    final notifier = TransducerEditorNotifier<MealyMachine>(_machine());
    final locale = ValueNotifier(const Locale('en'));
    final container = await _pumpWorkspace(tester, notifier, locale);
    final registry = container.read(documentInteroperabilityRegistryProvider);
    final imported = _importedMachine();
    final encoded = registry.encode(
      InteroperableDocument<Object>(
        document: imported,
        systemKey: TransducerFormalSystemIds.mealy,
        schema: registry.formalSystems
            .descriptorFor(TransducerFormalSystemIds.mealy)!
            .schema,
      ),
      format: DefaultFormalSystemIds.turingLabJsonFormat,
    );
    expect(encoded, isA<CodecSuccess<EncodedDocument>>());
    final importBytes = (encoded as CodecSuccess<EncodedDocument>).value.bytes;

    _openTools(container);
    await _pumpSurface(tester);
    await _selectToolsTab(tester, Icons.tune);
    final export = find.byKey(
      const ValueKey('interoperability_export_turing-lab-json'),
    );
    await _scrollUntilBuilt(tester, export, scrollDelta: const Offset(0, -500));
    tester.widget<ElevatedButton>(export).onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
    expect(find.text('Review export'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DocumentInteroperabilityReviewDialog),
        matching: find.text('Mealy'),
      ),
      findsOneWidget,
    );
    picker.enqueueSaveResult('/mobile/mealy.json');
    await tester.tap(find.widgetWithText(FilledButton, 'Export file'));
    await tester.pumpAndSettle();
    expect(picker.lastSaveBytes, isNotNull);
    expect(picker.lastSaveBytes, isNotEmpty);
    expect(find.text('Document exported successfully.'), findsOneWidget);

    locale.value = const Locale('pt');
    await tester.pumpAndSettle();
    picker.enqueuePickResult(
      FilePickerResult([
        PlatformFile(
          name: 'maquina-importada.json',
          size: importBytes.length,
          bytes: importBytes,
        ),
      ]),
    );
    final import = find.byKey(
      const ValueKey('interoperability_import_document'),
    );
    tester.widget<ElevatedButton>(import).onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
    expect(find.text('Revisar importação'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DocumentInteroperabilityReviewDialog),
        matching: find.text('Mealy'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Substituir documento'));
    await tester.pumpAndSettle();

    expect(find.text('Documento importado com sucesso.'), findsOneWidget);
    expect(notifier.state.document.id.value, 'imported-mealy');
    expect(notifier.state.document.name, 'User formal document');
    expect(notifier.state.document.states.single.label, 'Formal label');
    expect(notifier.state.document.transitions.single.output.values, ['z']);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester,
  TransducerEditorNotifier<MealyMachine> notifier,
  ValueNotifier<Locale> locale,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(locale.dispose);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [mealyEditorProvider.overrideWith((_) => notifier)],
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
          home: const MealyPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MealyPage)),
  );
  return container;
}

void _openSimulation(ProviderContainer container) {
  container
      .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy))!
      .onSimulate!();
}

void _openTools(ProviderContainer container) {
  container
      .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.mealy))!
      .onAlgorithms!();
}

Future<void> _openExamples(
  WidgetTester tester,
  ProviderContainer container,
) async {
  // Examples live inside the Algorithms & Examples sheet as the third tab.
  _openTools(container);
  await _pumpSurface(tester);
  await _selectToolsTab(tester, Icons.school_outlined, index: 2);
}

Future<void> _runSimulation(
  WidgetTester tester, {
  required Finder input,
  required String value,
}) async {
  await tester.enterText(input, value);
  final run = find.byKey(const Key('transducer-run'));
  await tester.ensureVisible(run);
  await tester.tap(run);
  await tester.pump();
}

Future<void> _selectToolsTab(
  WidgetTester tester,
  IconData icon, {
  int index = 1,
}) async {
  final tab = find.descendant(
    of: find.byKey(const Key('transducer-tools-sheet')),
    matching: find.byIcon(icon),
  );
  await tester.ensureVisible(tab);
  DefaultTabController.of(tester.element(tab)).index = index;
  await _pumpSurface(tester);
  expect(DefaultTabController.of(tester.element(tab)).index, index);
}

Future<void> _closeCompactSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('transducer-sheet-close')));
  await _pumpSurface(tester);
}

Future<void> _pumpSurface(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

Future<void> _scrollUntilBuilt(
  WidgetTester tester,
  Finder target, {
  required Offset scrollDelta,
}) async {
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    final list = find.byType(ListView).hitTestable().last;
    final scrollable = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(
      (position.pixels - scrollDelta.dy).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    await tester.pump();
    await tester.pump();
  }
  expect(target, findsOneWidget);
}

MealyMachine _machine() => MealyMachine(
  id: const TransducerMachineId('mealy-localization'),
  name: 'User-authored machine',
  revision: const TransducerRevision(0),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: {const TransducerOutputSymbol('x')},
  states: const [
    MealyState(
      id: TransducerStateId('q0'),
      label: 'Idle',
      position: TransducerPoint(120, 120),
      isInitial: true,
    ),
  ],
  transitions: [
    MealyTransition(
      id: const TransducerTransitionId('loop'),
      from: const TransducerStateId('q0'),
      to: const TransducerStateId('q0'),
      input: const TransducerInputSymbol('a'),
      output: TransducerOutputWord.fromValues(['x']),
    ),
  ],
);

MealyMachine _importedMachine() => MealyMachine(
  id: const TransducerMachineId('imported-mealy'),
  name: 'User formal document',
  revision: const TransducerRevision(7),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: {const TransducerOutputSymbol('z')},
  states: const [
    MealyState(
      id: TransducerStateId('formal'),
      label: 'Formal label',
      position: TransducerPoint(80, 90),
      isInitial: true,
    ),
  ],
  transitions: [
    MealyTransition(
      id: const TransducerTransitionId('formal-loop'),
      from: const TransducerStateId('formal'),
      to: const TransducerStateId('formal'),
      input: const TransducerInputSymbol('a'),
      output: TransducerOutputWord.fromValues(['z']),
    ),
  ],
);

final class _FakeFilePicker extends FilePicker {
  final Queue<FilePickerResult?> _pickResults = Queue<FilePickerResult?>();
  final Queue<String?> _saveResults = Queue<String?>();
  Uint8List? lastSaveBytes;

  void enqueuePickResult(FilePickerResult? result) => _pickResults.add(result);

  void enqueueSaveResult(String? result) => _saveResults.add(result);

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
  }) async => _pickResults.isEmpty ? null : _pickResults.removeFirst();

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    lastSaveBytes = bytes;
    return _saveResults.isEmpty ? null : _saveResults.removeFirst();
  }
}
