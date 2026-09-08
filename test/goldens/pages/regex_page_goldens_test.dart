//
//  regex_page_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for Regex page components, capturing
//  snapshots of critical states: desktop/tablet/mobile layouts, empty form,
//  regex validation, string tests, equivalence comparison, and FA→Regex
//  conversion results. Guards visual consistency of the regular-expression UI
//  across changes and catches automatic regressions.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/regex_page.dart';
import 'package:turing_lab/presentation/providers/automaton_algorithm_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import '../../support/workspace_dock_helpers.dart';

late SharedPreferences _prefs;

// Test notifier for overriding algorithm state
class _TestAlgorithmNotifier extends AutomatonAlgorithmNotifier {
  final AlgorithmOperationState _initialState;

  _TestAlgorithmNotifier(super.ref, this._initialState) {
    state = _initialState;
  }
}

// Test wrapper that sets up provider scope
class _RegexPageTestWidget extends StatelessWidget {
  final Size screenSize;
  final AlgorithmOperationState? algorithmState;

  const _RegexPageTestWidget({required this.screenSize, this.algorithmState});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
        if (algorithmState != null)
          automatonAlgorithmProvider.overrideWith(
            (ref) => _TestAlgorithmNotifier(ref, algorithmState!),
          ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const RegexPage(),
        ),
      ),
    );
  }
}

Future<void> _pumpRegexPage(
  WidgetTester tester, {
  Size size = const Size(1400, 900),
  AlgorithmOperationState? algorithmState,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  // `pumpWidgetBuilder` defaults to an 800x600 surface, which would render
  // every case in the compact band regardless of the requested size. The page
  // picks its band from the incoming constraints, so the surface has to match.
  await tester.pumpWidgetBuilder(
    _RegexPageTestWidget(screenSize: size, algorithmState: algorithmState),
    surfaceSize: size,
  );

  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.byType(ErrorWidget), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await initializeSharedPreferences();
  });

  tearDownAll(() async {
    await resetDependencies();
  });

  group('Regex Page golden tests', () {
    testGoldens('renders empty page in desktop layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(1400, 900));

      await screenMatchesGolden(tester, 'regex_page_empty_desktop');
    });

    testGoldens('renders empty page in tablet layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(1200, 800));

      await screenMatchesGolden(tester, 'regex_page_empty_tablet');
    });

    testGoldens('renders empty page in mobile layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(430, 932));

      await screenMatchesGolden(tester, 'regex_page_empty_mobile');
    });

    testGoldens('renders page with valid regex input in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(1400, 900));

      // Enter valid regex
      await tester.enterText(
        find.byKey(const ValueKey('regex_input_field')),
        'a*b+',
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'regex_page_valid_regex_desktop');
    });

    testGoldens('renders page with invalid regex input in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(1400, 900));

      // Enter invalid regex (unbalanced parentheses)
      await tester.enterText(
        find.byKey(const ValueKey('regex_input_field')),
        '(a*b+',
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'regex_page_invalid_regex_desktop');
    });

    testGoldens('renders page with test string match in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(1400, 900));

      // Enter valid regex
      await tester.enterText(
        find.byKey(const ValueKey('regex_input_field')),
        'a*b+',
      );
      await tester.pumpAndSettle();

      // Enter matching test string
      await openWorkspaceSimulationPanel(tester);
      await tester.enterText(
        find.byKey(const ValueKey('regex_test_input_field')),
        'aaabbb',
      );
      await tester.pumpAndSettle();

      expect(find.text('Matches!'), findsOneWidget);
      await screenMatchesGolden(tester, 'regex_page_test_match_desktop');
    });

    testGoldens('renders page with test string non-match in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(1400, 900));

      // Enter valid regex
      await tester.enterText(
        find.byKey(const ValueKey('regex_input_field')),
        'a*b+',
      );
      await tester.pumpAndSettle();

      // Enter non-matching test string
      await openWorkspaceSimulationPanel(tester);
      await tester.enterText(
        find.byKey(const ValueKey('regex_test_input_field')),
        'bbbaa',
      );
      await tester.pumpAndSettle();

      expect(find.text('Does not match'), findsOneWidget);
      await screenMatchesGolden(tester, 'regex_page_test_nomatch_desktop');
    });

    testGoldens('renders page with comparison input in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(1400, 900));

      // Enter first regex
      await tester.enterText(
        find.byKey(const ValueKey('regex_input_field')),
        'a*b+',
      );
      await tester.pumpAndSettle();

      await openWorkspaceAlgorithmsPanel(tester);
      final comparisonField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                lookupAppLocalizations(const Locale('en')).comparisonRegexHint,
      );
      await tester.ensureVisible(comparisonField);
      await tester.enterText(comparisonField, 'a*b');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(comparisonField).controller!.text, 'a*b');

      await screenMatchesGolden(tester, 'regex_page_comparison_desktop');
    });

    testGoldens('renders page with FA to Regex result in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Create algorithm state with conversion result
      const algorithmState = AlgorithmOperationState(
        rawRegexResult: '(a|b)*c',
        simplifiedRegexResult: '(a|b)*c',
      );

      await _pumpRegexPage(
        tester,
        size: const Size(1400, 900),
        algorithmState: algorithmState,
      );

      await openWorkspaceAlgorithmsPanel(tester);
      final result = find.text('(a|b)*c').last;
      await tester.ensureVisible(result);
      await tester.pumpAndSettle();
      expect(result, findsOneWidget);
      await screenMatchesGolden(tester, 'regex_page_fa_to_regex_desktop');
    });

    testGoldens('renders page with all features in tablet layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(1200, 800));

      // Enter valid regex
      await tester.enterText(
        find.byKey(const ValueKey('regex_input_field')),
        'a*b+',
      );
      await tester.pumpAndSettle();

      // Enter test string
      await openWorkspaceSimulationPanel(tester);
      await tester.enterText(
        find.byKey(const ValueKey('regex_test_input_field')),
        'aaabbb',
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'regex_page_features_tablet');
    });

    testGoldens('renders page with input and validation in mobile layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpRegexPage(tester, size: const Size(430, 932));

      // Enter valid regex
      await tester.enterText(
        find.byKey(const ValueKey('regex_input_field')),
        'a+b*',
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'regex_page_input_mobile');
    });
  });
}
