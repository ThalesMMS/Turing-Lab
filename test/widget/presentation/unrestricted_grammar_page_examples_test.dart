import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/asset_example.dart';
import 'package:turing_lab/data/formal_systems/default_formal_system_registry.dart';
import 'package:turing_lab/data/grammar/unrestricted_grammar_example_catalog.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/content/unrestricted_grammar_example_content_copy.dart';
import 'package:turing_lab/presentation/content/example_suggested_simulations.dart';
import 'package:turing_lab/presentation/pages/unrestricted_grammar_page.dart';
import 'package:turing_lab/presentation/providers/formal_extension_editor_providers.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/unrestricted_grammar/unrestricted_grammar_editor_controller.dart';

void main() {
  testWidgets(
    'publishes loading then enabled examples and replaces the active grammar',
    (tester) async {
      final completer = Completer<List<AssetExample<Object>>>();
      final initial = _grammar('initial');
      final first = _example('an-bn-cn', _grammar('first'));
      final second = _example('context-copying', _grammar('second'));
      final controller = UnrestrictedGrammarEditorController(initial);
      final container = await _pumpPage(
        tester,
        catalog: _TestExampleCatalog(() => completer.future),
        controller: controller,
        size: const Size(400, 900),
      );

      var actions = container.read(
        workspaceQuickActionsProvider(
          UnrestrictedGrammarCapabilities.systemKey,
        ),
      );
      // Examples are consolidated behind Algorithms & Examples: no standalone
      // quick action remains.
      expect(actions?.onExamples, isNull);
      expect(actions?.onAlgorithms, isNotNull);
      expect(actions?.algorithmsTooltip, 'Algorithms & Examples');
      expect(find.byIcon(Icons.school_outlined), findsNothing);

      completer.complete([first, second]);
      await tester.pumpAndSettle();
      actions = container.read(
        workspaceQuickActionsProvider(
          UnrestrictedGrammarCapabilities.systemKey,
        ),
      );

      actions!.onAlgorithms!();
      await tester.pumpAndSettle();
      expect(find.text('Algorithms & Examples'), findsOneWidget);
      expect(find.text('Examples'), findsOneWidget);
      expect(
        find.byKey(const Key('unrestricted-grammar-examples-list')),
        findsOneWidget,
      );
      expect(find.text('a^n b^n c^n'), findsOneWidget);
      final secondTile = find.byKey(
        const ValueKey('unrestricted-grammar-example-context-copying'),
      );
      await tester.ensureVisible(secondTile);
      await tester.pumpAndSettle();
      expect(find.text('Context copying with a marker'), findsOneWidget);
      expect(tester.getSize(secondTile).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);

      await tester.tap(secondTile);
      await tester.pumpAndSettle();
      expect(controller.grammar.id, 'second');
      // Applying an example closes the hosting surface.
      expect(find.text('Context copying with a marker'), findsNothing);

      controller.undo();
      expect(controller.grammar.id, initial.id);
    },
  );

  testWidgets('shows the empty-state message when the catalog is empty', (
    tester,
  ) async {
    final container = await _pumpPage(
      tester,
      catalog: _TestExampleCatalog(() async => const []),
      controller: UnrestrictedGrammarEditorController(_grammar('initial')),
    );
    await tester.pumpAndSettle();

    final actions = container.read(
      workspaceQuickActionsProvider(UnrestrictedGrammarCapabilities.systemKey),
    );
    expect(actions?.onExamples, isNull);
    actions!.onAlgorithms!();
    await tester.pumpAndSettle();
    expect(find.text('Examples'), findsOneWidget);
    expect(find.text('No examples are available yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the failure message when loading fails', (tester) async {
    final container = await _pumpPage(
      tester,
      catalog: _TestExampleCatalog(
        () => Future.error(StateError('catalog unavailable')),
      ),
      controller: UnrestrictedGrammarEditorController(_grammar('initial')),
    );
    await tester.pumpAndSettle();

    final actions = container.read(
      workspaceQuickActionsProvider(UnrestrictedGrammarCapabilities.systemKey),
    );
    expect(actions?.onExamples, isNull);
    actions!.onAlgorithms!();
    await tester.pumpAndSettle();
    expect(find.text('Examples'), findsOneWidget);
    expect(find.text('Examples could not be loaded.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses Portuguese copy in the examples action and sheet', (
    tester,
  ) async {
    final container = await _pumpPage(
      tester,
      catalog: const UnrestrictedGrammarExampleCatalog(),
      controller: UnrestrictedGrammarEditorController(_grammar('initial')),
      locale: const Locale('pt'),
    );
    await tester.pumpAndSettle();

    final actions = container.read(
      workspaceQuickActionsProvider(UnrestrictedGrammarCapabilities.systemKey),
    );
    expect(actions?.algorithmsTooltip, 'Algoritmos e Exemplos');
    actions!.onAlgorithms!();
    await tester.pumpAndSettle();

    expect(find.text('Exemplos'), findsOneWidget);
    expect(find.text('a^n b^n c^n'), findsOneWidget);
    expect(find.text('Cópia de contexto com marcador'), findsOneWidget);
    expect(find.text('Gramática irrestrita gerada por MT'), findsOneWidget);
    expect(find.byTooltip('Fechar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'localizes all example content and preserves editor state at 320px and 200 percent',
    (tester) async {
      final locale = ValueNotifier(const Locale('en'));
      addTearDown(locale.dispose);
      final grammar = _userGrammar();
      final controller = UnrestrictedGrammarEditorController(grammar);
      final container = await _pumpPage(
        tester,
        catalog: const UnrestrictedGrammarExampleCatalog(),
        controller: controller,
        size: const Size(320, 700),
        textScale: 2,
        localeListenable: locale,
      );
      await tester.pumpAndSettle();
      var actions = container.read(
        workspaceQuickActionsProvider(
          UnrestrictedGrammarCapabilities.systemKey,
        ),
      )!;
      actions.onEdit!();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('unrestricted-grammar-left')),
        'UserStart Ω',
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      actions.onSimulate!();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('unrestricted-grammar-input')),
        'user-token',
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      final originalPayload = controller.grammar.toJson();

      actions.onAlgorithms!();
      await tester.pumpAndSettle();
      final list = find.byKey(const Key('unrestricted-grammar-examples-list'));
      final scrollable = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      final examples = await const UnrestrictedGrammarExampleCatalog()
          .loadExamples();

      for (final example in examples) {
        final copy = UnrestrictedGrammarExampleContentCopies.resolve(
          id: example.id,
          languageCode: 'en',
        );
        final tile = find.byKey(
          ValueKey('unrestricted-grammar-example-${example.id}'),
        );
        await tester.scrollUntilVisible(tile, 300, scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(find.text(copy.title), findsOneWidget);
        expect(
          tester.getSemantics(tile).label,
          contains(copy.accessibleDescription),
        );
        final suggestions = ExampleSuggestedSimulations.resolve(example.id);
        expect(suggestions, isNotEmpty);
        expect(
          tester.getSemantics(tile).label,
          contains('Suggested simulation: ${suggestions.join(', ')}.'),
        );
        expect(tester.takeException(), isNull);
      }

      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();

      expect(list, findsOneWidget);
      final visiblePortugueseCopy =
          UnrestrictedGrammarExampleContentCopies.resolve(
            id: 'tm-generated',
            languageCode: 'pt-BR',
          );
      final visiblePortugueseTile = find.byKey(
        const ValueKey('unrestricted-grammar-example-tm-generated'),
      );
      expect(find.text(visiblePortugueseCopy.title), findsOneWidget);
      expect(
        tester.getSemantics(visiblePortugueseTile).label,
        contains(visiblePortugueseCopy.accessibleDescription),
      );
      expect(controller.grammar, same(grammar));
      expect(controller.grammar.toJson(), originalPayload);
      // The sheet was opened under the previous locale, so close it via the
      // locale-independent close icon.
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();
      actions = container.read(
        workspaceQuickActionsProvider(
          UnrestrictedGrammarCapabilities.systemKey,
        ),
      )!;
      actions.onEdit!();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('unrestricted-grammar-left')),
            )
            .controller!
            .text,
        'UserStart Ω',
      );
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      actions.onSimulate!();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('unrestricted-grammar-input')),
            )
            .controller!
            .text,
        'user-token',
      );
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      actions.onAlgorithms!();
      await tester.pumpAndSettle();
      final portugueseScrollable = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final example in examples) {
        final copy = UnrestrictedGrammarExampleContentCopies.resolve(
          id: example.id,
          languageCode: 'pt-BR',
        );
        final tile = find.byKey(
          ValueKey('unrestricted-grammar-example-${example.id}'),
        );
        await tester.scrollUntilVisible(
          tile,
          300,
          scrollable: portugueseScrollable,
        );
        await tester.pumpAndSettle();
        expect(find.text(copy.title), findsOneWidget);
        expect(
          tester.getSemantics(tile).label,
          contains(copy.accessibleDescription),
        );
        final suggestions = ExampleSuggestedSimulations.resolve(example.id);
        expect(suggestions, isNotEmpty);
        expect(
          tester.getSemantics(tile).label,
          contains('Simulação sugerida: ${suggestions.join(', ')}.'),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  required ExampleCatalogCapability<Object> catalog,
  required UnrestrictedGrammarEditorController controller,
  Locale locale = const Locale('en'),
  ValueNotifier<Locale>? localeListenable,
  Size size = const Size(800, 900),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final registry = _registryWith(catalog);
  final container = ProviderContainer(
    overrides: [
      formalSystemRegistryProvider.overrideWithValue(registry),
      unrestrictedGrammarEditorProvider.overrideWith((ref) => controller),
    ],
  );
  addTearDown(container.dispose);
  Widget app(Locale activeLocale) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: activeLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const Scaffold(body: UnrestrictedGrammarPage()),
    ),
  );
  await tester.pumpWidget(
    localeListenable == null
        ? app(locale)
        : ValueListenableBuilder<Locale>(
            valueListenable: localeListenable,
            builder: (context, activeLocale, child) => app(activeLocale),
          ),
  );
  await tester.pump();
  return container;
}

FormalSystemRegistry _registryWith(ExampleCatalogCapability<Object> catalog) {
  final defaults = DefaultFormalSystemRegistry.registry;
  final module = defaults.moduleFor(UnrestrictedGrammarCapabilities.systemKey)!;
  return FormalSystemRegistry(
    modules: [_TestFormalSystemModule(module, catalog)],
    formats: defaults.formats.formats,
  );
}

final class _TestFormalSystemModule implements FormalSystemModule<Object> {
  const _TestFormalSystemModule(this._base, this.examples);

  final FormalSystemModule<Object> _base;

  @override
  FormalSystemDescriptor get descriptor => _base.descriptor;

  @override
  List<DocumentCodecCapability<Object>> get codecs => _base.codecs;

  @override
  List<ConversionCapability<Object, Object>> get conversions =>
      _base.conversions;

  @override
  final ExampleCatalogCapability<Object> examples;

  @override
  SessionCapability<Object>? get session => _base.session;
}

final class _TestExampleCatalog implements ExampleCatalogCapability<Object> {
  const _TestExampleCatalog(this._load);

  final Future<List<AssetExample<Object>>> Function() _load;

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.grammar.unrestricted.test');

  @override
  Future<List<AssetExample<Object>>> loadExamples() => _load();
}

AssetExample<Object> _example(String name, UnrestrictedGrammar grammar) =>
    AssetExample<Object>(
      id: name,
      name: name,
      description: '$name description',
      category: ExampleCategory.unrestrictedGrammar,
      difficultyLevel: DifficultyLevel.medium,
      complexityLevel: ExampleComplexityLevel.medium,
      tags: const ['test'],
      payload: grammar,
    );

UnrestrictedGrammar _grammar(String id) => UnrestrictedGrammar(
  id: id,
  name: id,
  revision: 0,
  terminals: const [TerminalGrammarSymbol('a')],
  nonterminals: const [NonterminalGrammarSymbol('S')],
  startSymbol: const NonterminalGrammarSymbol('S'),
  productions: const [],
);

UnrestrictedGrammar _userGrammar() => UnrestrictedGrammar(
  id: 'user-grammar',
  name: 'User Ω grammar',
  revision: 7,
  terminals: const [TerminalGrammarSymbol('user-token')],
  nonterminals: const [NonterminalGrammarSymbol('UserStart')],
  startSymbol: const NonterminalGrammarSymbol('UserStart'),
  productions: [
    PhraseStructureProduction(
      id: 'user-production',
      order: 0,
      left: GrammarSymbolSequence(const [
        NonterminalGrammarSymbol('UserStart'),
      ]),
      right: GrammarSymbolSequence(const [TerminalGrammarSymbol('user-token')]),
    ),
  ],
);
