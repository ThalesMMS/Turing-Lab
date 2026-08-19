import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/help_page.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:turing_lab/presentation/pages/settings_page.dart';
import 'package:turing_lab/presentation/widgets/context_aware_help_panel.dart';
import 'package:turing_lab/presentation/widgets/mobile_navigation.dart';
import 'package:turing_lab/presentation/widgets/desktop_navigation.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';

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
      expect(find.bySemanticsLabel('Help'), findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Help'))
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

        await tester.tap(find.text('Convert to DFA'));
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
      'opens consolidated workspace help from app bar on mobile layout',
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

        _triggerEnabledAppBarAction(tester, Icons.help_outline);
        await tester.pumpAndSettle();

        expect(find.byType(ContextAwareHelpPanel), findsOneWidget);

        await tester
            .tap(find.widgetWithIcon(TextButton, Icons.menu_book_outlined));
        await tester.pumpAndSettle();

        expect(find.byType(ContextAwareHelpPanel), findsNothing);
        expect(find.byType(HelpPage), findsOneWidget);
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
