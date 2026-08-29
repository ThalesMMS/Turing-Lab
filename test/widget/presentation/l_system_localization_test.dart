import 'dart:collection';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/data/l_systems/l_system_examples.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/content/l_system_example_content_copy.dart';
import 'package:turing_lab/presentation/l_systems/l_system_editor_controller.dart';
import 'package:turing_lab/presentation/pages/l_system_page.dart';
import 'package:turing_lab/presentation/providers/formal_extension_editor_providers.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_review_dialog.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

// feature-localization-contract: l-system-deterministic-context-free
// feature-localization-contract: l-system-workspace
void main() {
  // feature-localization-surface: localized-editor-fields
  // feature-localization-surface: localized-error
  // feature-localization-surface: localized-valid-simulation
  // feature-localization-surface: locale-switch-state-preservation
  // feature-localization-surface: formal-content-preservation
  // feature-localization-surface: localized-lsystem-settings
  // feature-localization-surface: localized-production-and-command-editing
  // feature-localization-surface: bounded-expansion-feedback
  // feature-localization-surface: turtle-rendering
  // feature-localization-surface: viewport-state-preservation
  testWidgets(
    'L-system editor expands and preserves formal and viewport state in EN/PT',
    (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      final controller = LSystemEditorController(document: _document());
      await _pumpPage(tester, controller: controller, locale: locale);

      final axiom = find.widgetWithText(TextField, 'Axiom tokens');
      final rules = find.widgetWithText(TextField, 'Parallel production rules');
      final commands = find.widgetWithText(TextField, 'Turtle command mapping');
      final iterations = find.widgetWithText(TextField, 'Iterations');
      expect(axiom, findsOneWidget);
      expect(rules, findsOneWidget);
      expect(commands, findsOneWidget);
      for (final label in const [
        'Iterations',
        'Angle °',
        'Step length',
        'Scale',
        'Heading °',
        'Origin X',
        'Origin Y',
        'Line width',
        'Width change',
        'Hue change °',
        'Random seed',
        'Context-ignored tokens',
      ]) {
        expect(find.widgetWithText(TextField, label), findsOneWidget);
      }
      expect(find.text('Generated tokens'), findsOneWidget);
      expect(controller.status, LSystemEditorStatus.complete);
      expect(controller.generation?.word.symbols, ['F_α', 'leaf', 'leaf']);
      expect(controller.geometry?.segmentCount, 3);
      expect(tester.takeException(), isNull);

      await tester.enterText(iterations, '-1');
      await _tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Apply and expand'),
      );
      expect(find.text('Iterations must be zero or greater.'), findsOneWidget);
      expect(controller.document.iterations, 2);

      await tester.enterText(iterations, '2');
      await tester.enterText(axiom, 'F_α leaf');
      await tester.enterText(rules, 'F_α -> F_α leaf');
      await tester.enterText(commands, 'F_α = drawForward\nleaf = drawForward');
      await _tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Apply and expand'),
      );
      expect(controller.status, LSystemEditorStatus.complete);
      expect(controller.document.axiom.symbols, ['F_α', 'leaf']);
      expect(controller.document.productions.single.predecessor, 'F_α');
      expect(
        controller.document.commandMapping.commands['F_α'],
        LSystemTurtleCommand.drawForward,
      );
      expect(controller.document.randomSeed, 29);
      expect(controller.document.ignoredContextSymbols, {'+'});
      expect(controller.generation?.word.symbols, [
        'F_α',
        'leaf',
        'leaf',
        'leaf',
      ]);

      await _tapVisible(tester, find.byTooltip('Zoom in'));
      final viewerBefore = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final viewportBefore = viewerBefore.transformationController!.value
          .clone();
      final documentBefore = controller.document.toJson();
      final generationBefore = controller.generation!.word.symbols.toList();
      final geometryBefore = controller.geometry!.segmentCoordinates.toList();
      final statusBefore = controller.status;
      final canUndoBefore = controller.canUndo;
      final canRedoBefore = controller.canRedo;

      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Tokens do axioma'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Regras de produção paralela'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Mapeamento de comandos da tartaruga'),
        findsOneWidget,
      );
      for (final label in const [
        'Iterações',
        'Ângulo °',
        'Comprimento do passo',
        'Escala',
        'Direção °',
        'Origem X',
        'Origem Y',
        'Largura da linha',
        'Variação da largura',
        'Variação do matiz °',
        'Semente aleatória',
        'Tokens ignorados no contexto',
      ]) {
        expect(find.widgetWithText(TextField, label), findsOneWidget);
      }
      expect(find.text('Tokens gerados'), findsOneWidget);
      expect(find.textContaining('Expansão concluída.'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('l-system-canvas'))).label,
        contains(
          'Renderização da tartaruga para a geração 2, 4 segmentos de linha, '
          'profundidade máxima de ramificação 0.',
        ),
      );
      expect(controller.document.toJson(), documentBefore);
      expect(controller.generation?.word.symbols, generationBefore);
      expect(controller.geometry?.segmentCoordinates, geometryBefore);
      expect(controller.status, statusBefore);
      expect(controller.canUndo, canUndoBefore);
      expect(controller.canRedo, canRedoBefore);
      final viewerAfter = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(viewerAfter.transformationController!.value, viewportBefore);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        'F_α leaf',
      );

      await controller.run(
        generation: 2,
        limits: const LSystemExpansionLimits(maximumSymbols: 1),
      );
      await tester.pump();
      expect(controller.status, LSystemEditorStatus.bounded);
      expect(
        find.textContaining('A expansão parou no limite de símbolos.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'L-system re-resolves retained diagnostics when the locale changes',
    (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      final controller = LSystemEditorController(
        document: _unsupportedDocument(),
      );
      await _pumpPage(tester, controller: controller, locale: locale);

      expect(controller.status, LSystemEditorStatus.invalid);
      expect(
        find.textContaining('Production IDs must be unique.'),
        findsOneWidget,
      );
      expect(find.textContaining('preserved but not expanded'), findsOneWidget);
      final retainedMessages = [
        for (final message in controller.messages) message.toJson(),
      ];

      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();

      expect(controller.status, LSystemEditorStatus.invalid);
      expect([
        for (final message in controller.messages) message.toJson(),
      ], retainedMessages);
      for (final message in const [
        'Os IDs das produções devem ser únicos.',
        'Sistemas L estocásticos são preservados, mas não expandidos.',
        'Sistemas L paramétricos são preservados, mas não expandidos.',
        'Sistemas L sensíveis ao contexto são preservados, mas não expandidos.',
      ]) {
        expect(find.textContaining(message), findsOneWidget);
      }
      expect(
        find.textContaining('Production IDs must be unique.'),
        findsNothing,
      );
      expect(find.textContaining('preserved but not expanded'), findsNothing);

      controller.replaceDocument(_invalidTurtleArgumentDocument());
      await controller.run();
      await tester.pumpAndSettle();
      expect(controller.status, LSystemEditorStatus.invalid);
      expect(
        find.textContaining(
          'O comando da tartaruga distance exige um número finito.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('requires a finite number'), findsNothing);

      controller.replaceDocument(_unrestoredBranchDocument());
      await controller.run();
      await tester.pumpAndSettle();
      expect(controller.status, LSystemEditorStatus.invalid);
      expect(
        find.textContaining(
          '1 estado de ramificação da tartaruga não foi restaurado.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('were not restored'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  // feature-localization-surface: localized-numeric-summaries
  testWidgets(
    'L-system localizes numeric summaries and slider semantics in EN/PT',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var semanticsDisposed = false;
      addTearDown(() {
        if (!semanticsDisposed) semantics.dispose();
      });
      final locale = ValueNotifier(const Locale('en'));
      final controller = LSystemEditorController(
        document: _numberFormatSliderDocument(),
      );
      await _pumpPage(tester, controller: controller, locale: locale);
      await controller.run(
        generation: 1000,
        limits: const LSystemExpansionLimits(maximumGenerations: 1000),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(slider).label, '1,000');
      final enSliderSemantics = find.semantics.byLabel(
        'Generation 1,000 of 1,000',
      );
      expect(enSliderSemantics, findsOneWidget);
      expect(
        enSliderSemantics.evaluate().single.getSemanticsData().value,
        '1,000',
      );

      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(slider).label, '1.000');
      final ptSliderSemantics = find.semantics.byLabel(
        'Geração 1.000 de 1.000',
      );
      expect(ptSliderSemantics, findsOneWidget);
      expect(
        ptSliderSemantics.evaluate().single.getSemanticsData().value,
        '1.000',
      );

      controller.replaceDocument(_numberFormatSummaryDocument());
      await controller.run();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('A geração 0 tem 1.000 tokens e 1.000 segmentos.'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byKey(const Key('l-system-canvas'))).label,
        contains(
          'Renderização da tartaruga para a geração 0, 1.000 segmentos de linha, '
          'profundidade máxima de ramificação 0.',
        ),
      );

      locale.value = const Locale('en');
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Generation 0 has 1,000 tokens and 1,000 segments.',
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byKey(const Key('l-system-canvas'))).label,
        contains(
          'Turtle rendering for generation 0, 1,000 line segments, '
          'maximum branch depth 0.',
        ),
      );

      semantics.dispose();
      semanticsDisposed = true;
    },
  );

  testWidgets(
    'L-system formats numeric editor drafts and parses PT decimal input',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var semanticsDisposed = false;
      addTearDown(() {
        if (!semanticsDisposed) {
          semantics.dispose();
        }
        tester.view.resetPhysicalSize();
      });
      final locale = ValueNotifier(const Locale('pt', 'BR'));
      final controller = LSystemEditorController(
        document: _numberFormatEditorDocument(),
      );
      await _pumpPage(tester, controller: controller, locale: locale);
      tester.view.physicalSize = const Size(900, 1600);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Iterações'))
            .controller
            ?.text,
        '1.000',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Escala'))
            .controller
            ?.text,
        '2,5',
      );
      expect(
        tester.getSemantics(find.text('Definição')).flagsCollection.isHeader,
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.text('Tokens gerados'))
            .flagsCollection
            .isHeader,
        isTrue,
      );

      await tester.enterText(find.widgetWithText(TextField, 'Escala'), '2,75');
      await _tapApply(tester, 'Aplicar e expandir');

      expect(controller.document.iterations, 1000);
      expect(controller.document.turtle.scale, 2.75);
      expect(find.textContaining('A geração 0 tem'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Escala'), '1.500');
      await _tapApply(tester, 'Aplicar e expandir');
      expect(controller.document.turtle.scale, 1500);

      await tester.enterText(find.widgetWithText(TextField, 'Escala'), '4,25');
      locale.value = const Locale('en');
      await tester.pumpAndSettle();
      expect(find.text('Definition'), findsOneWidget);
      expect(find.text('Generated tokens'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Definition')).flagsCollection.isHeader,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Scale'))
            .controller
            ?.text,
        '4,25',
      );
      await _tapApply(tester, 'Apply and expand');
      expect(controller.document.turtle.scale, 4.25);
      await tester.enterText(find.widgetWithText(TextField, 'Scale'), '3.125');
      await _tapApply(tester, 'Apply and expand');
      expect(controller.document.turtle.scale, 3.125);

      for (final malformed in const ['1..5', '1,2,3']) {
        await tester.enterText(
          find.widgetWithText(TextField, 'Scale'),
          malformed,
        );
        await _tapApply(tester, 'Apply and expand');
        expect(controller.document.turtle.scale, 3.125);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
      semanticsDisposed = true;
    },
  );

  // feature-localization-surface: localized-example-metadata
  testWidgets('L-system uses the real bilingual example catalog', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('en'));
    final controller = LSystemEditorController(document: _document());
    final container = await _pumpPage(
      tester,
      controller: controller,
      locale: locale,
    );
    final originalDocument = controller.document;

    container
        .read(workspaceQuickActionsProvider(LSystemFormalSystemIds.key))!
        .onExamples!();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('l-system-examples-list')), findsOneWidget);
    final first = LSystemExamples.values.first;
    final enCopy = LSystemExampleContentCopies.resolve(
      id: first.id,
      languageCode: 'en',
    );
    final tile = find.byKey(ValueKey('l-system-example-${first.id}'));
    expect(find.text(enCopy.title), findsOneWidget);
    expect(tester.getSemantics(tile).label, contains(enCopy.summary));

    locale.value = const Locale('pt');
    await tester.pumpAndSettle();
    final ptCopy = LSystemExampleContentCopies.resolve(
      id: first.id,
      languageCode: 'pt-BR',
    );
    expect(find.text(ptCopy.title), findsOneWidget);
    expect(find.text(enCopy.title), findsNothing);
    expect(tester.getSemantics(tile).label, contains(ptCopy.summary));
    expect(controller.document, same(originalDocument));

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(controller.document, same(first.document));
    expect(controller.document.axiom.symbols, first.document.axiom.symbols);
    expect(controller.generation, isNotNull);
    expect(controller.geometry, isNotNull);
    await _tapVisible(
      tester,
      find.byKey(const Key('l-system-file-operations')),
    );
    expect(find.text(ptCopy.title), findsOneWidget);
    expect(find.text(enCopy.title), findsNothing);
    expect(controller.document.name, enCopy.title);
    expect(tester.takeException(), isNull);
  });

  // feature-localization-surface: localized-import-export
  // feature-localization-surface: production-interoperability
  testWidgets(
    'L-system exports in EN and imports in PT through production UI',
    (tester) async {
      final picker = _FakeFilePicker();
      FilePicker.platform = picker;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final locale = ValueNotifier(const Locale('en'));
      final controller = LSystemEditorController(document: _document());
      final container = await _pumpPage(
        tester,
        controller: controller,
        locale: locale,
      );
      final registry = container.read(documentInteroperabilityRegistryProvider);
      final imported = _importedDocument();
      final encoded = registry.encode(
        InteroperableDocument<Object>(
          document: imported,
          systemKey: LSystemFormalSystemIds.key,
          schema: registry.formalSystems
              .descriptorFor(LSystemFormalSystemIds.key)!
              .schema,
        ),
        format: DefaultFormalSystemIds.turingLabJsonFormat,
      );
      expect(encoded, isA<CodecSuccess<EncodedDocument>>());
      final importBytes =
          (encoded as CodecSuccess<EncodedDocument>).value.bytes;

      await _tapVisible(
        tester,
        find.byKey(const Key('l-system-file-operations')),
      );
      final export = find.byKey(
        const ValueKey('interoperability_export_turing-lab-json'),
      );
      await _tapVisible(tester, export);
      expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
      expect(find.text('Review export'), findsOneWidget);
      picker.enqueueSaveResult('/mobile/l-system.json');
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
            name: 'sistema-l-importado.json',
            size: importBytes.length,
            bytes: importBytes,
          ),
        ]),
      );
      final import = find.byKey(
        const ValueKey('interoperability_import_document'),
      );
      await _tapVisible(tester, import);
      expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
      expect(find.text('Revisar importação'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Substituir documento'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Documento importado com sucesso.'), findsOneWidget);
      expect(controller.document.id, 'imported-l-system');
      expect(controller.document.name, 'User formal L-system');
      expect(controller.document.axiom.symbols, ['Formal_β', 'user-leaf']);
      expect(controller.document.productions.single.predecessor, 'Formal_β');
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  required LSystemEditorController controller,
  required ValueNotifier<Locale> locale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(locale.dispose);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final container = ProviderContainer(
    overrides: [lSystemEditorProvider.overrideWith((_) => controller)],
  );
  addTearDown(container.dispose);
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
            appBar: AppBar(
              leadingWidth: 80,
              leading: const WorkspaceQuickActionsBar(
                workspaceKey: LSystemFormalSystemIds.key,
              ),
            ),
            body: const LSystemPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  final scrollable = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  for (
    var attempt = 0;
    attempt < 12 && target.hitTestable().evaluate().isEmpty;
    attempt++
  ) {
    if (scrollable.evaluate().isEmpty) break;
    await tester.drag(scrollable.first, const Offset(0, -200));
    await tester.pump();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _tapApply(WidgetTester tester, String label) async {
  final target = find.widgetWithText(FilledButton, label);
  final scrollable = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  if (scrollable.evaluate().isNotEmpty &&
      target.hitTestable().evaluate().isEmpty) {
    final state = tester.state<ScrollableState>(scrollable.last);
    state.position.jumpTo(state.position.maxScrollExtent);
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

LSystemDocument _document() => LSystemDocument(
  id: 'l-system-localization',
  name: 'User-authored L-system',
  revision: 7,
  axiom: LSystemWord(const ['F_α']),
  productions: [
    LSystemProduction(
      id: 'formal-rule',
      predecessor: 'F_α',
      successor: LSystemWord(const ['F_α', 'leaf']),
    ),
  ],
  iterations: 2,
  turtle: LSystemTurtleSettings(angleDegrees: 72, stepLength: 3),
  commandMapping: LSystemCommandMapping({
    'F_α': LSystemTurtleCommand.drawForward,
    'leaf': LSystemTurtleCommand.drawForward,
  }),
  randomSeed: 29,
  ignoredContextSymbols: const ['+'],
);

LSystemDocument _numberFormatSliderDocument() => LSystemDocument(
  id: 'l-system-number-format-slider',
  name: 'Number format slider',
  revision: 0,
  axiom: LSystemWord(const ['F']),
  productions: [
    LSystemProduction(
      id: 'stable-rule',
      predecessor: 'F',
      successor: LSystemWord(const ['F']),
    ),
  ],
  iterations: 1000,
  turtle: LSystemTurtleSettings(),
  commandMapping: LSystemCommandMapping.standard,
);

LSystemDocument _numberFormatSummaryDocument() => LSystemDocument(
  id: 'l-system-number-format-summary',
  name: 'Number format summary',
  revision: 0,
  axiom: LSystemWord(List.filled(1000, 'F')),
  productions: const [],
  iterations: 0,
  turtle: LSystemTurtleSettings(),
  commandMapping: LSystemCommandMapping.standard,
);

LSystemDocument _numberFormatEditorDocument() => LSystemDocument(
  id: 'l-system-number-format-editor',
  name: 'Number format editor',
  revision: 0,
  axiom: LSystemWord(const ['F']),
  productions: const [],
  iterations: 1000,
  turtle: LSystemTurtleSettings(
    angleDegrees: 72,
    stepLength: 3.125,
    scale: 2.5,
    lineWidth: 1.25,
  ),
  commandMapping: LSystemCommandMapping.standard,
);

LSystemDocument _importedDocument() => LSystemDocument(
  id: 'imported-l-system',
  name: 'User formal L-system',
  revision: 11,
  axiom: LSystemWord(const ['Formal_β', 'user-leaf']),
  productions: [
    LSystemProduction(
      id: 'imported-formal-rule',
      predecessor: 'Formal_β',
      successor: LSystemWord(const ['Formal_β', 'user-leaf']),
    ),
  ],
  iterations: 1,
  turtle: LSystemTurtleSettings(angleDegrees: 35),
  commandMapping: LSystemCommandMapping({
    'Formal_β': LSystemTurtleCommand.drawForward,
    'user-leaf': LSystemTurtleCommand.drawForward,
  }),
  randomSeed: 41,
);

LSystemDocument _unsupportedDocument() => LSystemDocument(
  id: 'unsupported-l-system',
  name: 'Unsupported variants',
  revision: 0,
  axiom: LSystemWord(const ['F']),
  productions: [
    LSystemProduction(
      id: 'duplicate',
      predecessor: 'F',
      successor: LSystemWord(['F']),
    ),
    LSystemProduction(
      id: 'duplicate',
      predecessor: 'F',
      successor: LSystemWord(['F', 'F']),
    ),
  ],
  iterations: 1,
  turtle: LSystemTurtleSettings(),
  commandMapping: LSystemCommandMapping.standard,
  unsupportedVariants: LSystemUnsupportedVariant.values,
);

LSystemDocument _invalidTurtleArgumentDocument() => LSystemDocument(
  id: 'invalid-turtle-argument',
  name: 'Invalid turtle argument',
  revision: 0,
  axiom: LSystemWord(const ['distance(nope)']),
  productions: const [],
  iterations: 0,
  turtle: LSystemTurtleSettings(),
  commandMapping: LSystemCommandMapping.standard,
);

LSystemDocument _unrestoredBranchDocument() => LSystemDocument(
  id: 'unrestored-turtle-branch',
  name: 'Unrestored turtle branch',
  revision: 0,
  axiom: LSystemWord(const ['[']),
  productions: const [],
  iterations: 0,
  turtle: LSystemTurtleSettings(),
  commandMapping: LSystemCommandMapping.standard,
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
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    String? initialDirectory,
    bool lockParentWindow = false,
  }) async {
    lastSaveBytes = bytes;
    return _saveResults.isEmpty ? null : _saveResults.removeFirst();
  }
}
