import 'dart:collection';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/transducers/moore_example_catalog.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/moore_page.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/transducers/moore_workspace_definition.dart';
import 'package:turing_lab/presentation/transducers/transducer_editor_state.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_review_dialog.dart';

// feature-localization-contract: transducer-moore
void main() {
  // feature-localization-surface: localized-error
  // feature-localization-surface: localized-valid-simulation
  // feature-localization-surface: localized-comparison-result
  // feature-localization-surface: locale-switch-state-preservation
  // feature-localization-surface: localized-example-metadata
  // feature-localization-surface: formal-content-preservation
  testWidgets(
    'Moore runs, compares, and loads examples across EN/PT at 320 px',
    (tester) async {
      final examples = await MooreExampleCatalog().loadExamples();
      final parity = examples
          .singleWhere((example) => example.id == 'asset/moore_parity')
          .payload;
      final notifier = TransducerEditorNotifier<MooreMachine>(parity);
      final locale = ValueNotifier(const Locale('en'));
      final container = await _pumpWorkspace(tester, notifier, locale);
      _openSimulation(container);
      await tester.pumpAndSettle();
      final originalDocument = notifier.state.document;

      final input = find.byKey(const Key('transducer-simulation-input'));
      await _runSimulation(tester, input: input, value: '1');
      expect(
        find.text(
          'The simulation completed after one input token. '
          '2 output tokens were produced.',
        ),
        findsOneWidget,
      );
      expect(notifier.state.lastExecution, isA<TransducerSuccess>());
      expect(notifier.state.lastExecution?.output.values, ['even', 'odd']);
      expect(notifier.state.lastExecution?.trace, hasLength(1));

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
      expect(notifier.state.document.states.first.label, 'Even');
      expect(notifier.state.document.states.first.output.values, ['even']);

      await _runSimulation(tester, input: input, value: '0');
      expect(
        find.text(
          'A simulação terminou após um token de entrada. '
          '2 tokens de saída foram produzidos.',
        ),
        findsOneWidget,
      );
      expect(notifier.state.lastExecution?.output.values, ['even', 'even']);
      expect(notifier.state.lastExecution?.trace, hasLength(1));

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
      expect(find.text('Saída de paridade por estado'), findsOneWidget);
      expect(find.text('Controle de venda'), findsOneWidget);
      expect(find.text('Parity state output'), findsNothing);
      await tester.tap(find.text('Saída de paridade por estado'));
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
      expect(find.text('Saída de paridade por estado'), findsOneWidget);
      final partialTile = find.byKey(
        const ValueKey('transducer-example-asset/moore_partial'),
      );
      final loadPartial = find.descendant(
        of: partialTile,
        matching: find.text('Carregar exemplo'),
      );
      await _scrollUntilBuilt(
        tester,
        partialTile,
        scrollDelta: const Offset(0, -400),
      );
      expect(find.text('Máquina de Moore parcial'), findsOneWidget);
      tester
          .widget<FilledButton>(
            find.ancestor(of: loadPartial, matching: find.byType(FilledButton)),
          )
          .onPressed!();
      await tester.pump();

      expect(notifier.state.document.id.value, 'moore_partial');
      expect(notifier.state.document.name, 'Partial Moore machine');
      expect(notifier.state.document.states.first.label, 'Off');
      expect(notifier.state.document.states.first.output.values, ['off']);
      expect(tester.takeException(), isNull);
    },
  );

  // feature-localization-surface: localized-editor-fields
  testWidgets('Moore edits alphabet fields without losing formal content', (
    tester,
  ) async {
    final notifier = TransducerEditorNotifier<MooreMachine>(_machine());
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
    await tester.enterText(outputAlphabet, 'idle\nactive');
    await _scrollUntilBuilt(tester, apply, scrollDelta: const Offset(0, -300));
    tester.widget<FilledButton>(apply).onPressed!();
    await tester.pump();

    expect(
      notifier.state.document.inputAlphabet.map((symbol) => symbol.value),
      unorderedEquals(['a', 'b']),
    );
    expect(
      notifier.state.document.outputAlphabet.map((symbol) => symbol.value),
      unorderedEquals(['idle', 'active']),
    );
    expect(notifier.state.document.states.first.label, 'Idle');
    expect(notifier.state.document.states.first.output.values, ['idle']);
    expect(notifier.state.document.transitions.single.input.value, 'a');

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
    expect(
      tester.widget<TextField>(outputAlphabet).controller?.text,
      'idle\nactive',
    );
    await _scrollUntilBuilt(tester, apply, scrollDelta: const Offset(0, -300));
    expect(find.text('Aplicar alfabetos'), findsOneWidget);
    expect(notifier.state.document.states.first.label, 'Idle');
    expect(notifier.state.document.states.first.output.values, ['idle']);
    expect(tester.takeException(), isNull);
  });

  // feature-localization-surface: localized-import-export
  testWidgets('Moore exports in EN and imports in PT through production UI', (
    tester,
  ) async {
    final picker = _FakeFilePicker();
    FilePicker.platform = picker;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    final notifier = TransducerEditorNotifier<MooreMachine>(_machine());
    final locale = ValueNotifier(const Locale('en'));
    final container = await _pumpWorkspace(tester, notifier, locale);
    final registry = container.read(documentInteroperabilityRegistryProvider);
    final imported = _importedMachine();
    final encoded = registry.encode(
      InteroperableDocument<Object>(
        document: imported,
        systemKey: TransducerFormalSystemIds.moore,
        schema: registry.formalSystems
            .descriptorFor(TransducerFormalSystemIds.moore)!
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
        matching: find.text('Moore'),
      ),
      findsOneWidget,
    );
    picker.enqueueSaveResult('/mobile/moore.json');
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
        matching: find.text('Moore'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Substituir documento'));
    await tester.pumpAndSettle();

    expect(find.text('Documento importado com sucesso.'), findsOneWidget);
    expect(notifier.state.document.id.value, 'imported-moore');
    expect(notifier.state.document.name, 'User formal document');
    expect(notifier.state.document.states.single.label, 'Formal label');
    expect(notifier.state.document.states.single.output.values, ['z']);
    expect(notifier.state.document.transitions.single.input.value, 'a');
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<ProviderContainer> _pumpWorkspace(
  WidgetTester tester,
  TransducerEditorNotifier<MooreMachine> notifier,
  ValueNotifier<Locale> locale,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(locale.dispose);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [mooreEditorProvider.overrideWith((_) => notifier)],
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
          home: const MoorePage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MoorePage)),
  );
  return container;
}

void _openSimulation(ProviderContainer container) {
  container
      .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.moore))!
      .onSimulate!();
}

void _openTools(ProviderContainer container) {
  container
      .read(workspaceQuickActionsProvider(TransducerFormalSystemIds.moore))!
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

MooreMachine _machine() => MooreMachine(
  id: const TransducerMachineId('moore-localization'),
  name: 'User-authored machine',
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
      position: const TransducerPoint(120, 120),
      output: TransducerOutputWord.fromValues(const ['idle']),
      isInitial: true,
    ),
  ],
  transitions: const [
    MooreTransition(
      id: TransducerTransitionId('loop'),
      from: TransducerStateId('q0'),
      to: TransducerStateId('q0'),
      input: TransducerInputSymbol('a'),
    ),
  ],
);

MooreMachine _importedMachine() => MooreMachine(
  id: const TransducerMachineId('imported-moore'),
  name: 'User formal document',
  revision: const TransducerRevision(7),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: {const TransducerOutputSymbol('z')},
  states: [
    MooreState(
      id: const TransducerStateId('formal'),
      label: 'Formal label',
      position: const TransducerPoint(80, 90),
      output: TransducerOutputWord.fromValues(const ['z']),
      isInitial: true,
    ),
  ],
  transitions: const [
    MooreTransition(
      id: TransducerTransitionId('formal-loop'),
      from: TransducerStateId('formal'),
      to: TransducerStateId('formal'),
      input: TransducerInputSymbol('a'),
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
