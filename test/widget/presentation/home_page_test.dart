import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/constants/help_topic_ids.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:turing_lab/presentation/pages/settings_page.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/mobile_navigation.dart';
import 'package:turing_lab/presentation/widgets/desktop_navigation.dart';

import 'examples_test_helpers.dart';

late SharedPreferences _prefs;

class _TestHomeNavigationNotifier extends HomeNavigationNotifier {
  final List<int> receivedIndices = [];

  @override
  void setIndex(int index) {
    receivedIndices.add(index);
    super.setIndex(index);
  }
}

class _TestSimulationHighlightService extends SimulationHighlightService {
  int clearCallCount = 0;

  @override
  void clear() {
    clearCallCount++;
    super.clear();
  }
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>?> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      pushedRoutes.add(route);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      replacedRoutes.add(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

Future<void> _pumpHomePage(
  WidgetTester tester, {
  required _TestHomeNavigationNotifier navigationNotifier,
  required _TestSimulationHighlightService highlightService,
  Size size = const Size(430, 932),
  Locale locale = const Locale('en'),
  List<NavigatorObserver> navigatorObservers = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
        examplesRepositoryProvider.overrideWithValue(TestExamplesRepository()),
        homeNavigationProvider.overrideWith((ref) {
          return navigationNotifier;
        }),
        canvasHighlightServiceProvider.overrideWithValue(highlightService),
      ],
      child: MaterialApp(
        home: const HomePage(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: navigatorObservers,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void _triggerEnabledAppBarAction(WidgetTester tester, IconData icon) {
  final appBarActionFinder = find.descendant(
    of: find.byType(AppBar),
    matching: find.widgetWithIcon(IconButton, icon),
  );
  final button = tester
      .widgetList<IconButton>(appBarActionFinder)
      .firstWhere((candidate) => candidate.onPressed != null);
  button.onPressed!.call();
}

void _expectFocusedHelpTopic(WidgetTester tester, String topicId) {
  final page = tester.widget<HelpPage>(find.byType(HelpPage));
  final node = find.byKey(ValueKey('help-node-$topicId'));
  expect(page.initialTopicId, topicId);
  expect(node, findsOneWidget);
  expect(tester.widget<InkWell>(node).focusNode?.hasFocus, isTrue);
  expect(find.byKey(ValueKey('help-body-$topicId')), findsOneWidget);
}

void _expectSinglePushTo<T>(
  _RecordingNavigatorObserver observer,
) {
  expect(observer.pushedRoutes, hasLength(1));
  final route = observer.pushedRoutes.single;
  expect(route, isA<MaterialPageRoute<dynamic>>());
  final page = (route as MaterialPageRoute<dynamic>)
      .builder(observer.navigator!.context);
  expect(page, isA<T>());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('HomePage', () {
    testWidgets(
      'renders mobile navigation with dynamic titles and actions below 1024 width',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(1);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(800, 1280),
        );

        expect(find.byType(MobileNavigation), findsOneWidget);
        expect(find.byType(DesktopNavigation), findsNothing);
        expect(find.text('Grammar'), findsWidgets);
        expect(find.text('Context-Free Grammars'), findsOneWidget);
        expect(find.text('Pumping'), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsWidgets);
        expect(find.byIcon(Icons.settings), findsWidgets);

        expect(highlightService.clearCallCount, 0);
      },
    );

    testWidgets(
      'renders desktop navigation rail with tooltips at 1024 width or above',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(1280, 900),
        );

        expect(find.byType(MobileNavigation), findsNothing);
        expect(find.byType(DesktopNavigation), findsOneWidget);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('FSA'), findsWidgets);
        expect(find.text('Pumping'), findsOneWidget);
        expect(
          find.byTooltip('Finite State Automata'),
          findsWidgets,
        );
        expect(find.byIcon(Icons.help_outline), findsWidgets);
        expect(find.byIcon(Icons.settings), findsWidgets);

        expect(highlightService.clearCallCount, 0);
      },
    );

    testWidgets('keeps Pumping Lemma navigation slot selectable', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()
        ..setIndex(HomeNavigationNotifier.pumpingLemmaIndex);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
      );

      expect(find.text('Pumping'), findsWidgets);
      expect(find.text('Pumping Lemma'), findsOneWidget);
      expect(
        navigationNotifier.receivedIndices,
        isNot(contains(HomeNavigationNotifier.regexIndex)),
      );
    });

    testWidgets('exposes primary navigation and app actions to semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var semanticsDisposed = false;
      addTearDown(() {
        if (!semanticsDisposed) {
          semantics.dispose();
          semanticsDisposed = true;
        }
      });

      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
      );

      expect(find.bySemanticsLabel('Navigate to FSA'), findsOneWidget);
      expect(find.bySemanticsLabel('Navigate to Regex'), findsOneWidget);
      final appBarHelp = find.descendant(
        of: find.byType(AppBar),
        matching: find.bySemanticsLabel('Help'),
      );
      expect(appBarHelp, findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(
        tester
            .getSemantics(appBarHelp)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Settings'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      semantics.dispose();
      semanticsDisposed = true;
    });

    testWidgets('renders navigation and app actions in Portuguese', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(1);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
        locale: const Locale('pt'),
      );

      expect(find.text('Gramática'), findsWidgets);
      expect(find.text('Gramáticas livres de contexto'), findsOneWidget);
      expect(find.byTooltip('Ajuda'), findsOneWidget);
      expect(find.byTooltip('Configurações'), findsOneWidget);
      expect(find.bySemanticsLabel('Navegar para Regex'), findsOneWidget);
    });

    testWidgets('updates page view and provider when tapping navigation', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(1);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
      );

      final navigationFinder = find.byType(MobileNavigation);

      await tester.tap(
        find.descendant(of: navigationFinder, matching: find.text('Regex')),
      );
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.page, closeTo(4, 0.001));
      expect(navigationNotifier.receivedIndices.contains(4), isTrue);
      expect(find.text('Regex'), findsWidgets);
      expect(find.text('Regular Expressions'), findsOneWidget);

      await tester.tap(
        find.descendant(of: navigationFinder, matching: find.text('PDA')),
      );
      await tester.pumpAndSettle();

      expect(pageView.controller?.page, closeTo(2, 0.001));
      expect(navigationNotifier.receivedIndices.contains(2), isTrue);
      expect(find.text('PDA'), findsWidgets);
      expect(find.text('Pushdown Automata'), findsOneWidget);
    });

    testWidgets('updates page view via navigation rail on desktop layout', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
        size: const Size(1400, 1080),
      );

      expect(find.byType(DesktopNavigation), findsOneWidget);

      await tester.tap(find.byTooltip('Regular Expressions').first);
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.page, closeTo(4, 0.001));
      expect(navigationNotifier.receivedIndices.contains(4), isTrue);
      expect(find.text('Regex'), findsWidgets);
      expect(find.text('Regular Expressions'), findsWidgets);
    });

    testWidgets(
      'regex DFA conversion stores completed DFA and switches to FSA workspace',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()
          ..setIndex(HomeNavigationNotifier.regexIndex);
        final highlightService = _TestSimulationHighlightService();
        final mockNavigatorObserver = _RecordingNavigatorObserver();

        bool hasCompleteAlphabetCoverage(AutomatonStateProviderState state) {
          final currentAutomaton = state.currentAutomaton;
          if (currentAutomaton == null) {
            return false;
          }
          if (currentAutomaton.states.isEmpty ||
              currentAutomaton.alphabet.isEmpty) {
            return false;
          }

          return currentAutomaton.states.every(
            (automatonState) => currentAutomaton.alphabet.every(
              (symbol) => currentAutomaton.fsaTransitions.any(
                (transition) =>
                    transition.fromState == automatonState &&
                    transition.inputSymbols.contains(symbol),
              ),
            ),
          );
        }

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(1400, 1080),
          navigatorObservers: [mockNavigatorObserver],
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomePage)),
          listen: false,
        );

        await tester.enterText(
          find.byKey(const ValueKey('regex_input_field')),
          'a',
        );
        await tester.pump();

        final convertToDfaButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Convert to DFA'),
            matching: find.byType(ElevatedButton),
          ),
        );
        convertToDfaButton.onPressed!.call();
        await tester.pumpAndSettle();

        final automatonState = container.read(automatonStateProvider);
        final currentAutomaton = automatonState.currentAutomaton;

        expect(currentAutomaton, isNotNull);
        expect(currentAutomaton!.isDeterministic, isTrue);
        expect(hasCompleteAlphabetCoverage(automatonState), isTrue);
        expect(
          container.read(homeNavigationProvider),
          HomeNavigationNotifier.fsaIndex,
        );
        expect(
          navigationNotifier.receivedIndices,
          contains(HomeNavigationNotifier.fsaIndex),
        );
        expect(mockNavigatorObserver.pushedRoutes, isEmpty);
        expect(mockNavigatorObserver.replacedRoutes, isEmpty);
        expect(find.text('FSA'), findsWidgets);
        expect(find.text('Finite State Automata'), findsWidgets);
      },
    );

    testWidgets(
      'regex NFA conversion stores the NFA and switches to FSA workspace',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()
          ..setIndex(HomeNavigationNotifier.regexIndex);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(1400, 1080),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomePage)),
          listen: false,
        );

        await tester.enterText(
          find.byKey(const ValueKey('regex_input_field')),
          'a',
        );
        await tester.pump();
        final convertToNfaButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Convert to NFA'),
            matching: find.byType(ElevatedButton),
          ),
        );
        convertToNfaButton.onPressed!.call();
        await tester.pumpAndSettle();

        expect(
          container.read(automatonStateProvider).currentAutomaton,
          isNotNull,
        );
        expect(
          container.read(homeNavigationProvider),
          HomeNavigationNotifier.fsaIndex,
        );
        expect(find.text('Finite State Automata'), findsWidgets);
      },
    );

    testWidgets(
      'regex NFA cancel preserves a loaded automaton with Portuguese copy',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()
          ..setIndex(HomeNavigationNotifier.regexIndex);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(1400, 1080),
          locale: const Locale('pt'),
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomePage)),
          listen: false,
        );
        container.read(automatonStateProvider.notifier).addState(
              id: 'loaded-state',
              label: 'loaded',
              x: 120,
              y: 120,
              isInitial: true,
            );
        final loadedAutomaton =
            container.read(automatonStateProvider).currentAutomaton;

        await tester.enterText(
          find.byKey(const ValueKey('regex_input_field')),
          'a',
        );
        await tester.pump();
        final convertToNfaButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Converter para AFN'),
            matching: find.byType(ElevatedButton),
          ),
        );
        convertToNfaButton.onPressed!.call();
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Já existe um autômato carregado. Deseja substituí-lo?',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(
          container.read(automatonStateProvider).currentAutomaton,
          same(loadedAutomaton),
        );
        expect(
          container.read(homeNavigationProvider),
          HomeNavigationNotifier.regexIndex,
        );
      },
    );

    testWidgets('regex DFA replace confirms and opens the new automaton', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()
        ..setIndex(HomeNavigationNotifier.regexIndex);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
        size: const Size(1400, 1080),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
        listen: false,
      );
      container.read(automatonStateProvider.notifier).addState(
            id: 'loaded-state',
            label: 'loaded',
            x: 120,
            y: 120,
            isInitial: true,
          );
      final loadedAutomaton =
          container.read(automatonStateProvider).currentAutomaton;

      await tester.enterText(
        find.byKey(const ValueKey('regex_input_field')),
        'a',
      );
      await tester.pump();
      final convertToDfaButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Convert to DFA'),
          matching: find.byType(ElevatedButton),
        ),
      );
      convertToDfaButton.onPressed!.call();
      await tester.pumpAndSettle();

      expect(
        find.text('An automaton is already loaded. Do you want to replace it?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();

      expect(
        container.read(automatonStateProvider).currentAutomaton,
        isNot(same(loadedAutomaton)),
      );
      expect(
        container.read(homeNavigationProvider),
        HomeNavigationNotifier.fsaIndex,
      );
    });

    testWidgets(
      'Home and local FSA Help agree and back preserves the automaton',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(430, 932),
        );

        final canvas = tester.widget<AutomatonGraphViewCanvas>(
          find.byType(AutomatonGraphViewCanvas),
        );
        canvas.controller!.addStateAt(const Offset(180, 240));
        await tester.pumpAndSettle();
        final stateIdsBeforeHelp =
            canvas.controller!.nodes.map((node) => node.id).toSet();

        _triggerEnabledAppBarAction(tester, Icons.help_outline);
        await tester.pumpAndSettle();

        _expectFocusedHelpTopic(tester, HelpTopicIds.fsaTheoryDfa);

        await tester.pageBack();
        await tester.pumpAndSettle();

        final restoredCanvas = tester.widget<AutomatonGraphViewCanvas>(
          find.byType(AutomatonGraphViewCanvas),
        );
        expect(restoredCanvas.controller, same(canvas.controller));
        expect(
          restoredCanvas.controller!.nodes.map((node) => node.id).toSet(),
          stateIdsBeforeHelp,
        );

        await tester.tap(find.byIcon(Icons.open_in_full));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('canvas-toolbar-overflow')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Help & Shortcuts').last);
        await tester.pumpAndSettle();

        _expectFocusedHelpTopic(tester, HelpTopicIds.fsaTheoryDfa);
      },
    );

    testWidgets('pushes HelpPage from app bar on desktop layout', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
      final highlightService = _TestSimulationHighlightService();
      final observer = _RecordingNavigatorObserver();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
        size: const Size(1400, 1080),
        navigatorObservers: [observer],
      );

      _triggerEnabledAppBarAction(tester, Icons.help_outline);
      await tester.pumpAndSettle();

      _expectSinglePushTo<HelpPage>(observer);
      _expectFocusedHelpTopic(tester, HelpTopicIds.fsaEditorOverview);
    });

    for (final scenario in const [
      (
        'Grammar',
        HomeNavigationNotifier.grammarIndex,
        HelpTopicIds.grammarEditorOverview,
      ),
      (
        'Regex',
        HomeNavigationNotifier.regexIndex,
        HelpTopicIds.regexEditorInput,
      ),
      (
        'Pumping Lemma',
        HomeNavigationNotifier.pumpingLemmaIndex,
        HelpTopicIds.pumpingEditorGame,
      ),
    ]) {
      testWidgets('Home ${scenario.$1} Help opens its empty workspace topic', (
        tester,
      ) async {
        final navigationNotifier = _TestHomeNavigationNotifier()
          ..setIndex(scenario.$2);
        final highlightService = _TestSimulationHighlightService();
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(430, 1100),
        );

        _triggerEnabledAppBarAction(tester, Icons.help_outline);
        await tester.pumpAndSettle();
        _expectFocusedHelpTopic(tester, scenario.$3);
      });
    }

    testWidgets('Home Grammar Help follows populated workspace state', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()
        ..setIndex(HomeNavigationNotifier.grammarIndex);
      final highlightService = _TestSimulationHighlightService();
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
        listen: false,
      );
      container.read(grammarProvider.notifier).addProduction(
        leftSide: const ['S'],
        rightSide: const ['a'],
      );
      await tester.pumpAndSettle();

      _triggerEnabledAppBarAction(tester, Icons.help_outline);
      await tester.pumpAndSettle();
      _expectFocusedHelpTopic(tester, HelpTopicIds.grammarTheoryCfg);
    });

    testWidgets('Home Regex Help follows valid workspace state',
        (tester) async {
      final navigationNotifier = _TestHomeNavigationNotifier()
        ..setIndex(HomeNavigationNotifier.regexIndex);
      final highlightService = _TestSimulationHighlightService();
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
        size: const Size(1400, 1080),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomePage)),
        listen: false,
      );
      container.read(regexEditorProvider.notifier).validateRegex('a*');
      await tester.pumpAndSettle();

      _triggerEnabledAppBarAction(tester, Icons.help_outline);
      await tester.pumpAndSettle();
      _expectFocusedHelpTopic(tester, HelpTopicIds.regexEditorConversions);
    });

    testWidgets('Home Regex exposes Algorithms at the upper left on mobile', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()
        ..setIndex(HomeNavigationNotifier.regexIndex);
      final highlightService = _TestSimulationHighlightService();
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
        size: const Size(430, 932),
      );

      final algorithms = find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Algorithms'),
      );
      expect(algorithms, findsOneWidget);
      expect(tester.getCenter(algorithms).dx, lessThan(100));
      expect(find.text('Convert to NFA'), findsNothing);

      await tester.tap(algorithms);
      await tester.pumpAndSettle();
      final exampleL10n = AppLocalizationsEn();
      for (final example in const [
        'Regex - Repetição de A',
        'Regex - Termina com AB',
        'Regex - Binário iniciado por 0',
        'Regex - Pares AB ou BA',
        'Regex - Blocos de A e B',
      ]) {
        expect(
          find.text(exampleL10n.localizedExampleName(example)),
          findsOneWidget,
        );
      }
    });

    for (final scenario in [
      ('mobile', const Size(430, 932)),
      ('desktop', const Size(1400, 1080)),
    ]) {
      testWidgets('pushes SettingsPage from app bar on ${scenario.$1} layout', (
        tester,
      ) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
        final highlightService = _TestSimulationHighlightService();
        final observer = _RecordingNavigatorObserver();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: scenario.$2,
          navigatorObservers: [observer],
        );

        _triggerEnabledAppBarAction(tester, Icons.settings);
        await tester.pumpAndSettle();

        _expectSinglePushTo<SettingsPage>(observer);
      });
    }
  });
}
