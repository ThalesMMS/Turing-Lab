import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_registry_provider.dart';
import 'package:turing_lab/presentation/widgets/navigation_item.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';
import 'package:turing_lab/presentation/widgets/workspace_selector.dart';
import 'package:turing_lab/presentation/workspaces/default_workspace_presentation_modules.dart';
import 'package:turing_lab/presentation/workspaces/workspace_presentation_module.dart';
import 'package:turing_lab/presentation/workspaces/workspace_presentation_registry.dart';
import 'package:turing_lab/presentation/workspaces/workspace_quick_action.dart';

import 'examples_test_helpers.dart';

const _expectedNavigation = <NavigationItem>[
  NavigationItem(
    label: 'FSA',
    icon: Icons.account_tree,
    description: 'Finite State Automata',
  ),
  NavigationItem(
    label: 'Grammar',
    icon: Icons.text_fields,
    description: 'Context-Free Grammars',
  ),
  NavigationItem(
    label: 'PDA',
    icon: Icons.storage,
    description: 'Pushdown Automata',
  ),
  NavigationItem(
    label: 'TM',
    icon: Icons.settings,
    description: 'Turing Machines',
  ),
  NavigationItem(
    label: 'Regex',
    icon: Icons.pattern,
    description: 'Regular Expressions',
  ),
  NavigationItem(
    label: 'Regular pumping',
    icon: Icons.games,
    description: 'Regular pumping lemma',
  ),
  NavigationItem(
    label: 'Context-free pumping',
    icon: Icons.schema_outlined,
    description: 'Context-free pumping lemma',
  ),
  NavigationItem(
    label: 'Mealy',
    icon: Icons.swap_horiz,
    description: 'Edit and simulate Mealy transducers.',
  ),
  NavigationItem(
    label: 'Moore',
    icon: Icons.multiline_chart,
    description: 'Edit and simulate Moore transducers.',
  ),
  NavigationItem(
    label: 'Unrestricted grammar',
    icon: Icons.schema,
    description:
        'Classify phrase-structure grammars and explore bounded derivations.',
  ),
  NavigationItem(
    label: 'L-system',
    icon: Icons.park_outlined,
    description: 'Expand parallel rewrite systems and render turtle graphics.',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  test('default presentation registry preserves typed keys and routes', () {
    final registry = WorkspacePresentationRegistry(
      buildDefaultWorkspacePresentationModules(
        FormalSystemRegistry.defaultRegistry,
      ),
    );

    expect(registry.modules.map((module) => module.key), const [
      DefaultFormalSystemIds.fsa,
      DefaultFormalSystemIds.grammar,
      DefaultFormalSystemIds.pda,
      DefaultFormalSystemIds.tm,
      DefaultFormalSystemIds.regex,
      DefaultFormalSystemIds.regularPumping,
      DefaultFormalSystemIds.contextFreePumping,
    ]);
    expect(registry.modules.map((module) => module.route.value), const [
      '/fsa',
      '/grammar',
      '/pda',
      '/tm',
      '/regex',
      '/pumping-lemma/regular',
      '/pumping-lemma/context-free',
    ]);
    for (final key in const [
      DefaultFormalSystemIds.regularPumping,
      DefaultFormalSystemIds.contextFreePumping,
    ]) {
      expect(
        registry.moduleFor(key)!.quickActions,
        contains(WorkspaceQuickAction.progress),
      );
    }
  });

  for (final scenario in const [
    ('mobile', Size(430, 932), true),
    ('tablet', Size(834, 1194), true),
    ('desktop', Size(1280, 900), false),
  ]) {
    testWidgets('preserves workspace order and navigation on ${scenario.$1}', (
      tester,
    ) async {
      final container = await _pumpHome(
        tester,
        preferences: preferences,
        size: scenario.$2,
      );
      addTearDown(container.dispose);

      final selector = tester.widget<WorkspaceSelector>(
        find.byType(WorkspaceSelector),
      );
      final items = selector.items;

      expect(
        items.map((item) => item.label),
        _expectedNavigation.map((item) => item.label),
      );
      expect(
        items.map((item) => item.icon),
        _expectedNavigation.map((item) => item.icon),
      );
      expect(
        items.map((item) => item.description),
        _expectedNavigation.map((item) => item.description),
      );
      expect(selector.compact, scenario.$3);
    });
  }

  testWidgets('preserves default workspace capability contracts', (
    tester,
  ) async {
    final container = await _pumpHome(
      tester,
      preferences: preferences,
      size: const Size(1280, 900),
    );
    addTearDown(container.dispose);

    const expected = <WorkspaceTab, _CapabilityExpectation>{
      WorkspaceTab.fsa: _CapabilityExpectation(
        simulate: _ActionAvailability.disabled,
        algorithms: _ActionAvailability.enabled,
      ),
      WorkspaceTab.grammar: _CapabilityExpectation(
        simulate: _ActionAvailability.disabled,
        algorithms: _ActionAvailability.enabled,
        edit: _ActionAvailability.enabled,
      ),
      WorkspaceTab.pda: _CapabilityExpectation(
        simulate: _ActionAvailability.disabled,
        algorithms: _ActionAvailability.enabled,
      ),
      WorkspaceTab.tm: _CapabilityExpectation(
        simulate: _ActionAvailability.disabled,
        algorithms: _ActionAvailability.enabled,
        metrics: _ActionAvailability.disabled,
      ),
      WorkspaceTab.regex: _CapabilityExpectation(
        simulate: _ActionAvailability.enabled,
        algorithms: _ActionAvailability.enabled,
      ),
      WorkspaceTab.pumping: _CapabilityExpectation(
        progress: _ActionAvailability.enabled,
      ),
    };

    for (final entry in expected.entries) {
      container.read(homeNavigationProvider.notifier).setIndex(entry.key.index);
      await tester.pumpAndSettle();

      final actions = container.read(
        workspaceQuickActionsProvider(entry.key.formalSystemKey),
      );
      expect(actions, isNotNull, reason: '${entry.key.name} did not publish');
      entry.value.verify(actions!, entry.key);
    }
  });

  testWidgets('extension module declarations match their published actions', (
    tester,
  ) async {
    final container = await _pumpHome(
      tester,
      preferences: preferences,
      size: const Size(1280, 900),
    );
    addTearDown(container.dispose);
    final registry = container.read(workspacePresentationRegistryProvider);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.play_arrow),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.auto_awesome),
      ),
      findsNothing,
    );

    for (final key in const [
      TransducerFormalSystemIds.mealy,
      TransducerFormalSystemIds.moore,
    ]) {
      expect(registry.moduleFor(key)!.quickActions, const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.simulate,
        WorkspaceQuickAction.algorithms,
      });
    }
    expect(
      registry
          .moduleFor(UnrestrictedGrammarCapabilities.systemKey)!
          .quickActions,
      const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.edit,
        WorkspaceQuickAction.simulate,
        WorkspaceQuickAction.algorithms,
      },
    );
    expect(registry.moduleFor(LSystemFormalSystemIds.key)!.quickActions, const {
      WorkspaceQuickAction.help,
      WorkspaceQuickAction.examples,
    });
    for (final key in const [
      UnrestrictedGrammarCapabilities.systemKey,
      LSystemFormalSystemIds.key,
    ]) {
      expect(
        registry
            .moduleFor(key)!
            .descriptor
            .capabilities
            .supports(FormalSystemCapability.examples),
        isTrue,
      );
    }
  });

  testWidgets(
    'both Pumping workspaces expose Progress in the compact app bar',
    (tester) async {
      final container = await _pumpHome(
        tester,
        preferences: preferences,
        size: const Size(430, 932),
      );
      addTearDown(container.dispose);
      final registry = container.read(workspacePresentationRegistryProvider);

      for (final key in const [
        DefaultFormalSystemIds.regularPumping,
        DefaultFormalSystemIds.contextFreePumping,
      ]) {
        container
            .read(homeNavigationProvider.notifier)
            .setIndex(registry.indexOfKey(key)!);
        await tester.pumpAndSettle();

        final progressAction = find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(
            const ValueKey('workspace-quick-action-progress'),
          ),
        );
        expect(progressAction, findsOneWidget, reason: '$key Progress action');
        expect(
          container.read(workspaceQuickActionsProvider(key))?.onProgress,
          isNotNull,
        );

        await tester.tap(progressAction);
        await tester.pumpAndSettle();
        expect(
          find.byType(BottomSheet),
          findsOneWidget,
          reason: '$key progress sheet',
        );
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byIcon(Icons.close),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      }
    },
  );

  testWidgets(
    'compact Home rapidly switches isolated Mealy and Moore action sets',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = await _pumpHome(
        tester,
        preferences: preferences,
        size: const Size(320, 900),
      );
      addTearDown(container.dispose);
      final registry = container.read(workspacePresentationRegistryProvider);

      for (final key in const [
        TransducerFormalSystemIds.mealy,
        TransducerFormalSystemIds.moore,
        TransducerFormalSystemIds.mealy,
      ]) {
        container
            .read(homeNavigationProvider.notifier)
            .setIndex(registry.indexOfKey(key)!);
        await tester.pumpAndSettle();

        expect(container.read(activeWorkspaceKeyProvider), key);
        final actions = container.read(workspaceQuickActionsProvider(key));
        expect(actions?.onSimulate, isNotNull);
        expect(actions?.onAlgorithms, isNotNull);
        expect(actions?.onExamples, isNull);
        expect(actions?.onEdit, isNull);
        final otherKey = key == TransducerFormalSystemIds.mealy
            ? TransducerFormalSystemIds.moore
            : TransducerFormalSystemIds.mealy;
        final otherActions = container.read(
          workspaceQuickActionsProvider(otherKey),
        );
        if (otherActions != null) {
          expect(actions!.onSimulate, isNot(same(otherActions.onSimulate)));
          expect(actions.onAlgorithms, isNot(same(otherActions.onAlgorithms)));
        }

        actions!.onSimulate!();
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('transducer-simulation-sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transducer-simulation-input')),
          findsOneWidget,
        );
        expect(find.byTooltip('Help'), findsOneWidget);
        expect(find.byTooltip('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('transducer-sheet-close')));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('wide Home reaches transducer surfaces through the dock rail', (
    tester,
  ) async {
    final container = await _pumpHome(
      tester,
      preferences: preferences,
      size: const Size(1280, 900),
    );
    addTearDown(container.dispose);
    final registry = container.read(workspacePresentationRegistryProvider);

    for (final key in const [
      TransducerFormalSystemIds.mealy,
      TransducerFormalSystemIds.moore,
    ]) {
      container
          .read(homeNavigationProvider.notifier)
          .setIndex(registry.indexOfKey(key)!);
      await tester.pumpAndSettle();

      // With examples consolidated behind Algorithms & Examples, the wide
      // app bar carries no transducer quick actions any more — parity with
      // FA/PDA/TM, whose wide surfaces live on the dock rail.
      final appBar = find.byType(AppBar);
      expect(
        find.descendant(of: appBar, matching: find.byIcon(Icons.play_arrow)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: appBar,
          matching: find.byIcon(Icons.school_outlined),
        ),
        findsNothing,
      );

      container.read(workspaceQuickActionsProvider(key))!.onSimulate!();
      await tester.pumpAndSettle();
      final input = find.byKey(const Key('transducer-simulation-input'));
      expect(input, findsOneWidget);
      expect(tester.widget<TextField>(input).focusNode?.hasFocus, isTrue);
      expect(container.read(activeWorkspaceKeyProvider), key);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'compact Home opens isolated Examples lists for both extension workspaces',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = await _pumpHome(
        tester,
        preferences: preferences,
        size: const Size(320, 900),
      );
      addTearDown(container.dispose);
      final registry = container.read(workspacePresentationRegistryProvider);

      for (final scenario in const [
        (
          UnrestrictedGrammarCapabilities.systemKey,
          Key('unrestricted-grammar-examples-list'),
        ),
        (LSystemFormalSystemIds.key, Key('l-system-examples-list')),
      ]) {
        container
            .read(homeNavigationProvider.notifier)
            .setIndex(registry.indexOfKey(scenario.$1)!);
        await tester.pumpAndSettle();
        await _pumpUntilExamplesEnabled(tester, container, scenario.$1);

        expect(container.read(activeWorkspaceKeyProvider), scenario.$1);
        final examplesAction = find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(
            const ValueKey('workspace-quick-action-examples'),
          ),
        );
        if (scenario.$1 == UnrestrictedGrammarCapabilities.systemKey) {
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.byKey(
                const ValueKey('workspace-quick-actions-overflow'),
              ),
            ),
            findsOneWidget,
          );
          // The examples list lives at the end of the Algorithms & Examples
          // surface now.
          container
              .read(workspaceQuickActionsProvider(scenario.$1))!
              .onAlgorithms!();
        } else {
          expect(examplesAction, findsOneWidget);
          await tester.tap(examplesAction);
        }
        await tester.pumpAndSettle();

        expect(find.byKey(scenario.$2), findsOneWidget);
        expect(find.byTooltip('Help'), findsOneWidget);
        expect(find.byTooltip('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);

        Navigator.of(tester.element(find.byKey(scenario.$2))).pop();
        await tester.pumpAndSettle();
      }

      expect(
        container
            .read(
              workspaceQuickActionsProvider(
                UnrestrictedGrammarCapabilities.systemKey,
              ),
            )
            ?.onAlgorithms,
        isNotNull,
      );
      expect(
        container
            .read(workspaceQuickActionsProvider(LSystemFormalSystemIds.key))
            ?.onExamples,
        isNotNull,
      );
    },
  );

  testWidgets(
    'wide Home keeps Examples reachable after body chips are removed',
    (tester) async {
      final container = await _pumpHome(
        tester,
        preferences: preferences,
        size: const Size(1280, 900),
      );
      addTearDown(container.dispose);
      final registry = container.read(workspacePresentationRegistryProvider);

      for (final key in const [
        UnrestrictedGrammarCapabilities.systemKey,
        LSystemFormalSystemIds.key,
      ]) {
        container
            .read(homeNavigationProvider.notifier)
            .setIndex(registry.indexOfKey(key)!);
        await tester.pumpAndSettle();
        await _pumpUntilExamplesEnabled(tester, container, key);

        if (key == UnrestrictedGrammarCapabilities.systemKey) {
          // Examples live at the end of the Algorithms & Examples dock panel.
          container.read(workspaceQuickActionsProvider(key))!.onAlgorithms!();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('unrestricted-grammar-examples-list')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          continue;
        }

        final examplesAction = find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(
            const ValueKey('workspace-quick-action-examples'),
          ),
        );
        expect(examplesAction, findsOneWidget);
        await tester.tap(examplesAction);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(tester.takeException(), isNull);

        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      }
    },
  );

  for (final scenario in const [
    ('mobile', Size(430, 932), true),
    ('tablet', Size(834, 1194), true),
    ('desktop', Size(1280, 900), false),
  ]) {
    testWidgets(
      'provider override navigates to a sample module on ${scenario.$1}',
      (tester) async {
        final coreRegistry = _coreRegistryWithSample();
        final presentationRegistry = WorkspacePresentationRegistry([
          ...buildDefaultWorkspacePresentationModules(coreRegistry),
          _samplePresentationModule(coreRegistry),
        ]);
        final container = await _pumpHome(
          tester,
          preferences: preferences,
          size: scenario.$2,
          coreRegistry: coreRegistry,
          presentationRegistry: presentationRegistry,
        );
        addTearDown(container.dispose);

        final sampleIndex = presentationRegistry.modules.length - 1;
        tester
            .widget<WorkspaceSelector>(find.byType(WorkspaceSelector))
            .onSelected(sampleIndex);
        await tester.pumpAndSettle();

        expect(find.text('Sample workspace page'), findsOneWidget);
        expect(container.read(activeWorkspaceKeyProvider), _sampleKey);

        final items = tester
            .widget<WorkspaceSelector>(find.byType(WorkspaceSelector))
            .items;
        expect(items.last.label, 'Sample');
        expect(items.last.description, 'Sample workspace');
        expect(items.last.icon, Icons.science);

        if (scenario.$3) {
          final quickActionBar = find.byType(WorkspaceQuickActionsBar);
          expect(
            find.descendant(
              of: quickActionBar,
              matching: find.byIcon(Icons.play_arrow),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: quickActionBar,
              matching: find.byIcon(Icons.auto_awesome),
            ),
            findsNothing,
          );
        }

        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byTooltip('Help'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<HelpPage>(find.byType(HelpPage)).initialTopicId,
          HelpTopicIds.gettingStartedQuickStart,
        );
      },
    );
  }

  testWidgets('unavailable help does not install a contextual action', (
    tester,
  ) async {
    final coreRegistry = _coreRegistryWithSample(
      helpAvailability: const UnavailableCapability(),
    );
    final presentationRegistry = WorkspacePresentationRegistry([
      ...buildDefaultWorkspacePresentationModules(coreRegistry),
      _samplePresentationModule(coreRegistry),
    ]);
    final container = await _pumpHome(
      tester,
      preferences: preferences,
      size: const Size(430, 932),
      coreRegistry: coreRegistry,
      presentationRegistry: presentationRegistry,
    );
    addTearDown(container.dispose);

    tester
        .widget<WorkspaceSelector>(find.byType(WorkspaceSelector))
        .onSelected(presentationRegistry.modules.length - 1);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Help'),
      ),
      findsNothing,
    );
  });
}

const _sampleKey = FormalSystemKey(
  type: FormalSystemTypeId('sample'),
  variant: FormalSystemVariantId('test'),
);

FormalSystemRegistry _coreRegistryWithSample({
  CapabilityAvailability helpAvailability = const SupportedCapability(),
}) => FormalSystemRegistry(
  modules: [
    ...DefaultFormalSystemModules.modules,
    DescriptorFormalSystemModule(
      FormalSystemDescriptor(
        key: _sampleKey,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('test.sample'),
          version: DocumentSchemaVersion(1),
        ),
        route: const WorkspaceRouteId('/sample'),
        category: FormalSystemCategory.learning,
        localizationNamespace: const CapabilityNamespaceId('formal.sample'),
        semanticsNamespace: const CapabilityNamespaceId('semantics.sample'),
        capabilities: FormalSystemCapabilities(
          simulation: const SupportedCapability(),
          analysis: const UnavailableCapability(),
          help: helpAvailability,
        ),
      ),
    ),
  ],
  formats: DefaultFormalSystemModules.formats,
);

WorkspacePresentationModule _samplePresentationModule(
  FormalSystemRegistry registry,
) => WorkspacePresentationModule(
  descriptor: registry.descriptorFor(_sampleKey)!,
  icon: Icons.science,
  pageBuilder: (_) => const _SampleWorkspacePage(),
  helpTopicId: HelpTopicIds.gettingStartedQuickStart,
  navigationLabel: (_) => 'Sample',
  navigationDescription: (_) => 'Sample workspace',
  quickActions: const {
    WorkspaceQuickAction.help,
    WorkspaceQuickAction.simulate,
    WorkspaceQuickAction.algorithms,
  },
);

class _SampleWorkspacePage extends ConsumerWidget {
  const _SampleWorkspacePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    publishWorkspaceQuickActionsForKey(
      ref,
      _sampleKey,
      WorkspaceQuickActions(onSimulate: () {}, onAlgorithms: () {}),
    );
    return const Center(child: Text('Sample workspace page'));
  }
}

enum _ActionAvailability { unavailable, disabled, enabled }

class _CapabilityExpectation {
  const _CapabilityExpectation({
    this.simulate = _ActionAvailability.unavailable,
    this.algorithms = _ActionAvailability.unavailable,
    this.edit = _ActionAvailability.unavailable,
    this.metrics = _ActionAvailability.unavailable,
    this.progress = _ActionAvailability.unavailable,
  });

  final _ActionAvailability simulate;
  final _ActionAvailability algorithms;
  final _ActionAvailability edit;
  final _ActionAvailability metrics;
  final _ActionAvailability progress;

  void verify(WorkspaceQuickActions actions, WorkspaceTab tab) {
    expect(actions.onHelp, isNotNull, reason: '${tab.name} help');
    _expectAction(
      actions.onSimulate,
      actions.simulateEnabled,
      simulate,
      '${tab.name} simulate',
    );
    _expectAction(
      actions.onAlgorithms,
      actions.algorithmsEnabled,
      algorithms,
      '${tab.name} algorithms',
    );
    _expectAction(
      actions.onEdit,
      actions.editEnabled,
      edit,
      '${tab.name} edit',
    );
    _expectAction(
      actions.onMetrics,
      actions.metricsEnabled,
      metrics,
      '${tab.name} metrics',
    );
    _expectAction(
      actions.onProgress,
      actions.progressEnabled,
      progress,
      '${tab.name} progress',
    );
    expect(actions.onExamples, isNull, reason: '${tab.name} examples');
  }

  void _expectAction(
    VoidCallback? callback,
    bool enabled,
    _ActionAvailability availability,
    String reason,
  ) {
    switch (availability) {
      case _ActionAvailability.unavailable:
        expect(callback, isNull, reason: reason);
      case _ActionAvailability.disabled:
        expect(callback, isNotNull, reason: reason);
        expect(enabled, isFalse, reason: reason);
      case _ActionAvailability.enabled:
        expect(callback, isNotNull, reason: reason);
        expect(enabled, isTrue, reason: reason);
    }
  }
}

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  required SharedPreferences preferences,
  required Size size,
  FormalSystemRegistry? coreRegistry,
  WorkspacePresentationRegistry? presentationRegistry,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      examplesRepositoryProvider.overrideWithValue(TestExamplesRepository()),
      canvasHighlightServiceProvider.overrideWithValue(
        SimulationHighlightService(),
      ),
      if (coreRegistry != null)
        formalSystemRegistryProvider.overrideWithValue(coreRegistry),
      if (presentationRegistry != null)
        workspacePresentationRegistryProvider.overrideWithValue(
          presentationRegistry,
        ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _pumpUntilExamplesEnabled(
  WidgetTester tester,
  ProviderContainer container,
  FormalSystemKey key,
) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    final actions = container.read(workspaceQuickActionsProvider(key));
    if (actions?.examplesEnabled ?? false) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  fail('Timed out waiting for the Examples action for $key.');
}
