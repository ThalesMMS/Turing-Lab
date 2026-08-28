import 'dart:collection';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/data/grammar/unrestricted_grammar_example_catalog.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/content/unrestricted_grammar_example_content_copy.dart';
import 'package:turing_lab/presentation/pages/unrestricted_grammar_page.dart';
import 'package:turing_lab/presentation/providers/formal_extension_editor_providers.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_registry_provider.dart';
import 'package:turing_lab/presentation/unrestricted_grammar/unrestricted_grammar_editor_controller.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_review_dialog.dart';
import 'package:turing_lab/presentation/workspaces/workspace_quick_action.dart';

// feature-localization-contract: grammar-unrestricted
void main() {
  // feature-localization-surface: localized-editor-fields
  // feature-localization-surface: localized-error
  // feature-localization-surface: localized-valid-simulation
  // feature-localization-surface: locale-switch-state-preservation
  // feature-localization-surface: formal-content-preservation
  // feature-localization-surface: localized-classification-analysis
  // feature-localization-surface: localized-bounded-derivation
  // feature-localization-surface: localized-manual-derivation
  // feature-localization-surface: localized-derivation-trace
  // feature-localization-surface: accessible-controls-and-status
  testWidgets(
    'unrestricted editor keeps authored grammar and derivation state in EN/PT',
    (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      final controller = UnrestrictedGrammarEditorController(_grammar());
      final container = await _pumpPage(
        tester,
        controller: controller,
        locale: locale,
      );

      expect(find.text('Productions'), findsOneWidget);
      final actions = container.read(
        workspaceQuickActionsProvider(
          UnrestrictedGrammarCapabilities.systemKey,
        ),
      )!;
      expect(actions.onEdit, isNotNull);
      expect(actions.onSimulate, isNotNull);
      expect(actions.onAlgorithms, isNotNull);
      actions.onEdit!();
      await tester.pumpAndSettle();
      expect(find.textContaining('Classification: regular'), findsOneWidget);
      for (final label in const ['Left-hand side', 'Right-hand side']) {
        expect(find.widgetWithText(TextField, label), findsOneWidget);
      }

      final left = find.byKey(const ValueKey('unrestricted-grammar-left'));
      final right = find.byKey(const ValueKey('unrestricted-grammar-right'));
      final add = find.byKey(const ValueKey('unrestricted-grammar-add'));
      await tester.enterText(left, 'not-json');
      await _tapInWorkspace(tester, add);
      expect(find.text('Invalid symbol vector'), findsOneWidget);
      expect(controller.grammar.productions, hasLength(1));

      await tester.enterText(left, '["n:UserStart_Ω"]');
      await tester.enterText(right, '["t:β"]');
      await _tapInWorkspace(tester, add);
      expect(controller.grammar.productions, hasLength(2));
      expect(
        controller.grammar.productions.last.left.symbols.single.value,
        'UserStart_Ω',
      );
      expect(
        controller.grammar.productions.last.right.symbols.single.value,
        'β',
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      actions.onSimulate!();
      await tester.pumpAndSettle();

      final input = find.byKey(const ValueKey('unrestricted-grammar-input'));
      final maximum = find.byKey(
        const ValueKey('unrestricted-grammar-max-expanded'),
      );
      final run = find.byKey(const ValueKey('unrestricted-grammar-run'));
      await tester.enterText(input, '["user-token"]');
      await tester.enterText(maximum, '0');
      await _tapInWorkspace(tester, run);
      expect(
        find.text('Inconclusive result: a bound was reached'),
        findsOneWidget,
      );

      await tester.enterText(maximum, '100');
      await _tapInWorkspace(tester, run);
      expect(find.text('Derivation found'), findsOneWidget);
      expect(find.textContaining('p1 @ 0'), findsOneWidget);

      final manual = find.byKey(
        const ValueKey('unrestricted-start-manual-derivation'),
      );
      await _tapInWorkspace(tester, manual);
      expect(
        find.byKey(const ValueKey('user-derivation-workspace')),
        findsOneWidget,
      );
      expect(find.text('Choose the next derivation move.'), findsOneWidget);

      final payloadBefore = controller.grammar.toJson();
      final canUndoBefore = controller.canUndo;
      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();

      for (final label in const [
        'Palavra de entrada',
        'Máximo de formas exploradas',
      ]) {
        expect(find.widgetWithText(TextField, label), findsOneWidget);
      }
      expect(find.text('Derivação encontrada'), findsOneWidget);
      expect(
        find.text('Escolha o próximo passo da derivação.'),
        findsOneWidget,
      );
      expect(controller.grammar.toJson(), payloadBefore);
      expect(controller.canUndo, canUndoBefore);
      expect(
        tester.widget<TextField>(input).controller!.text,
        '["user-token"]',
      );
      expect(tester.widget<TextField>(maximum).controller!.text, '100');
      expect(find.textContaining('n:UserStart_Ω → t:β'), findsOneWidget);

      final runSemantics = tester.getSemantics(run);
      expect(runSemantics.label, contains('Buscar derivação'));
      expect(tester.getSize(run).height, greaterThanOrEqualTo(48));

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      container
          .read(
            workspaceQuickActionsProvider(
              UnrestrictedGrammarCapabilities.systemKey,
            ),
          )!
          .onEdit!();
      await tester.pumpAndSettle();
      expect(find.textContaining('Classificação: regular'), findsOneWidget);
      expect(
        tester.widget<TextField>(left).controller!.text,
        '["n:UserStart_Ω"]',
      );
      expect(tester.widget<TextField>(right).controller!.text, '["t:β"]');
      expect(find.textContaining('n:UserStart_Ω → t:β'), findsWidgets);

      await tester.enterText(left, '[]');
      await tester.enterText(right, '[]');
      await _tapInWorkspace(tester, add);
      expect(find.textContaining('Classificação: inválida'), findsOneWidget);
      expect(
        find.textContaining('O lado esquerdo não pode ser vazio'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  // feature-localization-surface: localized-example-metadata
  // feature-localization-surface: contextual-help-registration
  testWidgets(
    'unrestricted workspace exposes real bilingual examples and help',
    (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      final controller = UnrestrictedGrammarEditorController(_grammar());
      final container = await _pumpPage(
        tester,
        controller: controller,
        locale: locale,
      );
      final presentation = container
          .read(workspacePresentationRegistryProvider)
          .moduleFor(UnrestrictedGrammarCapabilities.systemKey)!;
      expect(
        presentation.helpTopicId,
        HelpTopicIds.unrestrictedGrammarEditorOverview,
      );
      expect(presentation.quickActions, contains(WorkspaceQuickAction.help));
      expect(
        presentation.quickActions,
        isNot(contains(WorkspaceQuickAction.examples)),
      );
      expect(presentation.quickActions, contains(WorkspaceQuickAction.edit));
      expect(
        presentation.quickActions,
        contains(WorkspaceQuickAction.simulate),
      );
      expect(
        presentation.quickActions,
        contains(WorkspaceQuickAction.algorithms),
      );

      final originalPayload = controller.grammar.toJson();
      container
          .read(
            workspaceQuickActionsProvider(
              UnrestrictedGrammarCapabilities.systemKey,
            ),
          )!
          .onAlgorithms!();
      await tester.pumpAndSettle();

      final first =
          (await const UnrestrictedGrammarExampleCatalog().loadExamples())
              .first;
      final tile = find.byKey(
        ValueKey('unrestricted-grammar-example-${first.id}'),
      );
      final enCopy = UnrestrictedGrammarExampleContentCopies.resolve(
        id: first.id,
        languageCode: 'en',
      );
      expect(find.text(enCopy.title), findsOneWidget);
      expect(
        tester.getSemantics(tile).label,
        contains(enCopy.accessibleDescription),
      );

      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();
      final ptCopy = UnrestrictedGrammarExampleContentCopies.resolve(
        id: first.id,
        languageCode: 'pt-BR',
      );
      expect(find.text(ptCopy.title), findsOneWidget);
      final portugueseSemantics = tester.getSemantics(tile).label;
      expect(portugueseSemantics, contains(ptCopy.accessibleDescription));
      expect(
        portugueseSemantics,
        isNot(contains(enCopy.accessibleDescription)),
      );
      expect(controller.grammar.toJson(), originalPayload);

      locale.value = const Locale('pt');
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(tile).label,
        contains(ptCopy.accessibleDescription),
      );
      expect(controller.grammar.toJson(), originalPayload);

      final semanticTile = tester.widget<Semantics>(tile);
      expect(semanticTile.properties.onTap, isNotNull);
      semanticTile.properties.onTap!();
      await tester.pumpAndSettle();
      expect(controller.grammar.id, first.id);
      expect(
        controller.grammar.toJson(),
        (first.payload as UnrestrictedGrammar).toJson(),
      );
      expect(tester.takeException(), isNull);
    },
  );

  // feature-localization-surface: localized-import-export
  // feature-localization-surface: production-interoperability
  // feature-localization-surface: production-session-persistence
  // feature-localization-surface: all-declared-document-formats
  testWidgets(
    'unrestricted grammar exports in EN and imports and persists in PT',
    (tester) async {
      final picker = _FakeFilePicker();
      FilePicker.platform = picker;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final locale = ValueNotifier(const Locale('en'));
      final controller = UnrestrictedGrammarEditorController(_grammar());
      final container = await _pumpPage(
        tester,
        controller: controller,
        locale: locale,
      );
      final registry = container.read(documentInteroperabilityRegistryProvider);
      final imported = _importedGrammar();
      final descriptor = container
          .read(formalSystemRegistryProvider)
          .descriptorFor(UnrestrictedGrammarCapabilities.systemKey)!;
      final encodedJson =
          registry.encode(
                InteroperableDocument<Object>(
                  document: imported,
                  systemKey: UnrestrictedGrammarCapabilities.systemKey,
                  schema: descriptor.schema,
                ),
                format: DefaultFormalSystemIds.turingLabJsonFormat,
              )
              as CodecSuccess<EncodedDocument>;
      final encodedJflap =
          registry.encode(
                InteroperableDocument<Object>(
                  document: imported,
                  systemKey: UnrestrictedGrammarCapabilities.systemKey,
                  schema: descriptor.schema,
                ),
                format: DefaultFormalSystemIds.jflapXmlFormat,
              )
              as CodecSuccess<EncodedDocument>;

      container
          .read(
            workspaceQuickActionsProvider(
              UnrestrictedGrammarCapabilities.systemKey,
            ),
          )!
          .onEdit!();
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('unrestricted-grammar-file-operations')),
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('interoperability_export_turing-lab-json')),
      );
      expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
      expect(find.text('Review export'), findsOneWidget);
      picker.enqueueSaveResult('/mobile/unrestricted-grammar.json');
      await tester.tap(find.widgetWithText(FilledButton, 'Export file'));
      await tester.pumpAndSettle();
      expect(picker.lastSaveBytes, isNotNull);
      expect(picker.lastSaveBytes, isNotEmpty);
      expect(find.text('Document exported successfully.'), findsOneWidget);

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('interoperability_export_jflap-xml')),
      );
      expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
      expect(find.text('JFLAP XML'), findsWidgets);
      picker.enqueueSaveResult('/mobile/unrestricted-grammar.jff');
      await tester.tap(
        find.descendant(
          of: find.byType(DocumentInteroperabilityReviewDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        String.fromCharCodes(picker.lastSaveBytes!),
        contains('<structure>'),
      );

      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();
      picker.enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'gramatica-irrestrita.jff',
            size: encodedJflap.value.bytes.length,
            bytes: encodedJflap.value.bytes,
          ),
        ]),
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('interoperability_import_document')),
      );
      expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
      expect(find.text('Revisar importação'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(DocumentInteroperabilityReviewDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Documento importado com sucesso.'), findsOneWidget);
      expect(controller.grammar.terminals.single.value, 'payload_β');
      expect(controller.grammar.startSymbol.value, 'Start_Ω');

      picker.enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'gramatica-irrestrita.json',
            size: encodedJson.value.bytes.length,
            bytes: encodedJson.value.bytes,
          ),
        ]),
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('interoperability_import_document')),
      );
      expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
      expect(find.text('Turing Lab JSON'), findsWidgets);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Substituir documento'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Documento importado com sucesso.'), findsOneWidget);
      expect(controller.grammar.toJson(), imported.toJson());

      final session = container
          .read(formalSystemRegistryProvider)
          .moduleFor(UnrestrictedGrammarCapabilities.systemKey)!
          .session!;
      final restored =
          session.decodeSession(
                session.encodeSession(controller.grammar),
                schema: descriptor.schema,
              )
              as UnrestrictedGrammar;
      expect(restored.toJson(), controller.grammar.toJson());
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  required UnrestrictedGrammarEditorController controller,
  required ValueNotifier<Locale> locale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(locale.dispose);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final container = ProviderContainer(
    overrides: [
      unrestrictedGrammarEditorProvider.overrideWith((_) => controller),
    ],
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
          home: const Scaffold(body: UnrestrictedGrammarPage()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapInWorkspace(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

UnrestrictedGrammar _grammar() => UnrestrictedGrammar(
  id: 'user-grammar',
  name: 'User Ω grammar',
  revision: 7,
  terminals: const [
    TerminalGrammarSymbol('user-token'),
    TerminalGrammarSymbol('β'),
  ],
  nonterminals: const [NonterminalGrammarSymbol('UserStart_Ω')],
  startSymbol: const NonterminalGrammarSymbol('UserStart_Ω'),
  productions: [
    PhraseStructureProduction(
      id: 'p1',
      order: 0,
      left: GrammarSymbolSequence(const [
        NonterminalGrammarSymbol('UserStart_Ω'),
      ]),
      right: GrammarSymbolSequence(const [TerminalGrammarSymbol('user-token')]),
    ),
  ],
);

UnrestrictedGrammar _importedGrammar() => UnrestrictedGrammar(
  id: 'imported-user-grammar',
  name: 'Imported user grammar',
  revision: 11,
  terminals: const [TerminalGrammarSymbol('payload_β')],
  nonterminals: const [NonterminalGrammarSymbol('Start_Ω')],
  startSymbol: const NonterminalGrammarSymbol('Start_Ω'),
  productions: [
    PhraseStructureProduction(
      id: 'formal-production',
      order: 0,
      left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('Start_Ω')]),
      right: GrammarSymbolSequence(const [TerminalGrammarSymbol('payload_β')]),
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
