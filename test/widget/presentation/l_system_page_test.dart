import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/models/asset_example.dart';
import 'package:turing_lab/data/formal_systems/default_formal_system_registry.dart';
import 'package:turing_lab/data/l_systems/l_system_examples.dart';
import 'package:turing_lab/data/l_systems/l_system_module.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/content/l_system_example_content_copy.dart';
import 'package:turing_lab/presentation/l_systems/l_system_editor_controller.dart';
import 'package:turing_lab/presentation/pages/l_system_page.dart';
import 'package:turing_lab/presentation/providers/formal_extension_editor_providers.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_registry_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

final class _TestCatalog implements ExampleCatalogCapability<LSystemDocument> {
  const _TestCatalog(this.loader);

  final Future<List<AssetExample<LSystemDocument>>> Function() loader;

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.l-system.page-test');

  @override
  Future<List<AssetExample<LSystemDocument>>> loadExamples() => loader();
}

List<AssetExample<LSystemDocument>> _examples() => [
  for (final example in LSystemExamples.values.take(2))
    AssetExample<LSystemDocument>(
      id: example.id,
      name: example.name,
      description: example.description,
      category: ExampleCategory.lSystem,
      difficultyLevel: DifficultyLevel.medium,
      complexityLevel: ExampleComplexityLevel.medium,
      tags: const ['l-system'],
      payload: example.document,
    ),
];

List<AssetExample<LSystemDocument>> _allExamples() => [
  for (final example in LSystemExamples.values)
    AssetExample<LSystemDocument>(
      id: example.id,
      name: example.name,
      description: example.description,
      category: ExampleCategory.lSystem,
      difficultyLevel: DifficultyLevel.medium,
      complexityLevel: ExampleComplexityLevel.medium,
      tags: const ['l-system'],
      payload: example.document,
    ),
];

FormalSystemRegistry _registry(
  ExampleCatalogCapability<LSystemDocument> catalog,
) {
  final base = DefaultFormalSystemRegistry.registry;
  return FormalSystemRegistry(
    modules: [
      for (final module in base.modules)
        if (module.descriptor.key != LSystemFormalSystemIds.key) module,
      createRegisteredLSystemModule(examples: catalog),
    ],
    formats: base.formats.formats,
  );
}

Future<({ProviderContainer container, LSystemEditorController controller})>
_pumpPage(
  WidgetTester tester, {
  required ExampleCatalogCapability<LSystemDocument> catalog,
  Locale locale = const Locale('en'),
  ValueNotifier<Locale>? localeNotifier,
  Size size = const Size(900, 900),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = LSystemEditorController(
    document: LSystemExamples.values.first.document,
  );
  final container = ProviderContainer(
    overrides: [
      formalSystemRegistryProvider.overrideWithValue(_registry(catalog)),
      lSystemEditorProvider.overrideWith((ref) => controller),
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
  );
  await tester.pumpWidget(
    localeNotifier == null
        ? app(locale)
        : ValueListenableBuilder<Locale>(
            valueListenable: localeNotifier,
            builder: (context, activeLocale, child) => app(activeLocale),
          ),
  );
  await tester.pumpAndSettle();
  return (container: container, controller: controller);
}

Finder get _examplesAction =>
    find.byKey(const ValueKey('workspace-quick-action-examples'));

void main() {
  testWidgets(
    'keeps Examples visible and disabled while loading at 320 px and 200%',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var disposed = false;
      addTearDown(() {
        if (!disposed) semantics.dispose();
      });
      final completer = Completer<List<AssetExample<LSystemDocument>>>();
      final result = await _pumpPage(
        tester,
        catalog: _TestCatalog(() => completer.future),
        locale: const Locale('pt'),
        size: const Size(320, 700),
        textScale: 2,
      );

      expect(find.byType(Chip), findsNothing);
      expect(_examplesAction, findsOneWidget);
      final loadingActions = result.container.read(
        workspaceQuickActionsProvider(LSystemFormalSystemIds.key),
      );
      expect(loadingActions?.onExamples, isNotNull);
      expect(loadingActions?.examplesEnabled, isFalse);
      expect(loadingActions?.examplesTooltip, 'Carregando exemplos');
      final semanticsData = tester
          .getSemantics(_examplesAction)
          .getSemanticsData();
      expect(semanticsData.flagsCollection.isEnabled, Tristate.isFalse);
      expect(semanticsData.label, 'Carregando exemplos');
      expect(tester.takeException(), isNull);

      completer.complete(_examples());
      await tester.pumpAndSettle();

      final readyActions = result.container.read(
        workspaceQuickActionsProvider(LSystemFormalSystemIds.key),
      );
      expect(readyActions?.examplesEnabled, isTrue);
      expect(readyActions?.examplesTooltip, 'Algoritmos e Exemplos');
      expect(readyActions?.examplesIcon, Icons.auto_awesome);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      disposed = true;
    },
  );

  testWidgets('empty catalog leaves a localized unavailable action', (
    tester,
  ) async {
    final result = await _pumpPage(
      tester,
      catalog: _TestCatalog(() async => const []),
    );

    expect(_examplesAction, findsOneWidget);
    final actions = result.container.read(
      workspaceQuickActionsProvider(LSystemFormalSystemIds.key),
    );
    expect(actions?.examplesEnabled, isFalse);
    expect(actions?.examplesTooltip, 'No examples are available yet.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog failure leaves a localized unavailable action', (
    tester,
  ) async {
    final result = await _pumpPage(
      tester,
      catalog: _TestCatalog(
        () => Future.error(StateError('catalog unavailable')),
      ),
    );

    expect(_examplesAction, findsOneWidget);
    final actions = result.container.read(
      workspaceQuickActionsProvider(LSystemFormalSystemIds.key),
    );
    expect(actions?.examplesEnabled, isFalse);
    expect(actions?.examplesTooltip, 'Examples could not be loaded.');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selection replaces the document and reloads drafts and geometry',
    (tester) async {
      final examples = _examples();
      final selected = examples.last;
      final result = await _pumpPage(
        tester,
        catalog: _TestCatalog(() async => examples),
        locale: const Locale('pt'),
      );

      expect(
        result.container.read(
          workspaceQuickActionsProvider(DefaultFormalSystemIds.fsa),
        ),
        isNull,
      );
      expect(find.byKey(ObjectKey(result.controller.document)), findsOneWidget);

      await tester.tap(_examplesAction);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('l-system-examples-list')), findsOneWidget);
      expect(find.text('Curva de Koch'), findsOneWidget);
      expect(find.text('Triângulo de Sierpiński'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('l-system-example-${selected.id}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('l-system-examples-list')), findsNothing);
      expect(result.controller.document, same(selected.payload));
      expect(find.byKey(ObjectKey(selected.payload)), findsOneWidget);
      final axiom = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Tokens do axioma'),
      );
      expect(axiom.controller?.text, selected.payload.axiom.symbols.join(' '));
      expect(result.controller.generation, isNotNull);
      expect(result.controller.geometry, isNotNull);

      final directReplacement = examples.first.payload;
      result.controller.replaceDocument(directReplacement);
      await tester.pumpAndSettle();

      expect(find.byKey(ObjectKey(directReplacement)), findsOneWidget);
      final reloadedAxiom = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Tokens do axioma'),
      );
      expect(
        reloadedAxiom.controller?.text,
        directReplacement.axiom.symbols.join(' '),
      );
      expect(result.controller.geometry, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows all bilingual accessible copy and preserves the document on locale switch',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var semanticsDisposed = false;
      addTearDown(() {
        if (!semanticsDisposed) semantics.dispose();
      });
      final locale = ValueNotifier<Locale>(const Locale('en'));
      addTearDown(locale.dispose);
      final examples = _allExamples();
      final result = await _pumpPage(
        tester,
        catalog: _TestCatalog(() async => examples),
        localeNotifier: locale,
        size: const Size(320, 700),
        textScale: 2,
      );
      final originalDocument = result.controller.document;
      final originalFormalPayload = originalDocument.toJson();

      await tester.tap(_examplesAction);
      await tester.pumpAndSettle();
      final examplesList = find.byKey(const Key('l-system-examples-list'));
      final examplesScroll = find.descendant(
        of: examplesList,
        matching: find.byType(Scrollable),
      );
      expect(examplesList, findsOneWidget);
      expect(
        tester
            .getSemantics(find.text('Algorithms & Examples'))
            .flagsCollection
            .isHeader,
        isTrue,
      );

      for (final example in examples) {
        final copy = LSystemExampleContentCopies.resolve(
          id: example.id,
          languageCode: 'en',
        );
        final tile = find.byKey(ValueKey('l-system-example-${example.id}'));
        await tester.scrollUntilVisible(tile, 350, scrollable: examplesScroll);
        await tester.pumpAndSettle();
        expect(find.text(copy.title), findsOneWidget);
        expect(
          tester.getSemantics(tile).label,
          contains(copy.accessibleVisualizationDescription),
        );
        expect(tester.takeException(), isNull);
      }

      locale.value = const Locale('pt', 'BR');
      await tester.pumpAndSettle();
      await tester.fling(examplesList, const Offset(0, 5000), 1000);
      await tester.pumpAndSettle();

      expect(result.controller.document, same(originalDocument));
      expect(result.controller.document.toJson(), originalFormalPayload);
      expect(
        tester
            .getSemantics(find.text('Algoritmos e Exemplos'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      for (final example in examples) {
        final copy = LSystemExampleContentCopies.resolve(
          id: example.id,
          languageCode: 'pt-BR',
        );
        final tile = find.byKey(ValueKey('l-system-example-${example.id}'));
        await tester.scrollUntilVisible(tile, 350, scrollable: examplesScroll);
        await tester.pumpAndSettle();
        expect(find.text(copy.title), findsOneWidget);
        expect(
          tester.getSemantics(tile).label,
          contains(copy.accessibleVisualizationDescription),
        );
        expect(tester.takeException(), isNull);
      }

      await tester.fling(examplesList, const Offset(0, 5000), 1000);
      await tester.pumpAndSettle();
      final selected = examples.first;
      final selectedTile = find.byKey(
        ValueKey('l-system-example-${selected.id}'),
      );
      await tester.tap(selectedTile);
      await tester.pumpAndSettle();

      expect(result.controller.document, same(selected.payload));
      expect(result.controller.document.toJson(), selected.payload.toJson());
      expect(tester.takeException(), isNull);
      semantics.dispose();
      semanticsDisposed = true;
    },
  );
}
