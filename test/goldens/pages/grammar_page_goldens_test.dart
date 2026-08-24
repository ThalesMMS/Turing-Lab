//
//  grammar_page_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for Grammar page components (editor,
//  simulation, and algorithms), capturing snapshots of critical states:
//  desktop/tablet/mobile layouts, empty editor, and editors with regular and
//  context-free grammars. Guards visual consistency of the grammar UI across
//  changes and catches automatic regressions.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/presentation/pages/grammar_page.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';

late SharedPreferences _prefs;

// Test wrapper that provides GrammarProvider with optional initial grammar
class _GrammarPageTestWidget extends ConsumerWidget {
  final Grammar? grammar;
  final bool isMobile;

  const _GrammarPageTestWidget({this.grammar, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize grammar provider if grammar is provided
    if (grammar != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = ref.read(grammarProvider.notifier);
        provider.createNewGrammar(
          name: grammar!.name,
          startSymbol: grammar!.startSymbol,
          type: grammar!.type,
        );

        // Add productions
        for (final production in grammar!.productions) {
          provider.addProduction(
            leftSide: production.leftSide,
            rightSide: production.rightSide,
            isLambda: production.isLambda,
          );
        }
      });
    }

    return const GrammarPage();
  }
}

Future<void> _pumpGrammarPage(
  WidgetTester tester, {
  Grammar? grammar,
  Size size = const Size(1400, 900),
  bool isMobile = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidgetBuilder(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(_prefs)],
      child: MaterialApp(
        home: _GrammarPageTestWidget(grammar: grammar, isMobile: isMobile),
      ),
    ),
  );

  await tester.pumpAndSettle();
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

  group('Grammar Page Components golden tests', () {
    testGoldens('renders empty page in desktop layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpGrammarPage(
        tester,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'grammar_page_empty_desktop');
    });

    testGoldens('renders empty page in tablet layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpGrammarPage(
        tester,
        size: const Size(1200, 800),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'grammar_page_empty_tablet');
    });

    testGoldens('renders empty page in mobile layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpGrammarPage(
        tester,
        size: const Size(430, 932),
        isMobile: true,
      );

      await screenMatchesGolden(tester, 'grammar_page_empty_mobile');
    });

    testGoldens('renders page with simple regular grammar in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final grammar = Grammar.simpleRegular(
        id: 'test-regular',
        name: 'Simple Regular Grammar',
      );

      await _pumpGrammarPage(
        tester,
        grammar: grammar,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'grammar_page_regular_desktop');
    });

    testGoldens(
      'renders page with simple context-free grammar in desktop layout',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final grammar = Grammar.simpleContextFree(
          id: 'test-cfg',
          name: 'Simple CFG',
        );

        await _pumpGrammarPage(
          tester,
          grammar: grammar,
          size: const Size(1400, 900),
          isMobile: false,
        );

        await screenMatchesGolden(tester, 'grammar_page_cfg_desktop');
      },
    );

    testGoldens('renders page with complex grammar in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.utc(2024, 1, 1);
      const p1 = Production(
        id: 'p1',
        leftSide: ['S'],
        rightSide: ['a', 'S', 'b'],
        isLambda: false,
        order: 1,
      );
      const p2 = Production(
        id: 'p2',
        leftSide: ['S'],
        rightSide: ['a', 'B'],
        isLambda: false,
        order: 2,
      );
      const p3 = Production(
        id: 'p3',
        leftSide: ['B'],
        rightSide: ['b', 'B'],
        isLambda: false,
        order: 3,
      );
      const p4 = Production(
        id: 'p4',
        leftSide: ['B'],
        rightSide: [],
        isLambda: true,
        order: 4,
      );

      final grammar = Grammar(
        id: 'complex-cfg',
        name: 'Complex CFG',
        terminals: const {'a', 'b'},
        nonterminals: const {'S', 'B'},
        startSymbol: 'S',
        productions: {p1, p2, p3, p4},
        type: GrammarType.contextFree,
        created: now,
        modified: now,
      );

      await _pumpGrammarPage(
        tester,
        grammar: grammar,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'grammar_page_complex_desktop');
    });

    testGoldens('renders page with grammar in tablet layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final grammar = Grammar.simpleContextFree(
        id: 'test-cfg-tablet',
        name: 'CFG Tablet',
      );

      await _pumpGrammarPage(
        tester,
        grammar: grammar,
        size: const Size(1200, 800),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'grammar_page_cfg_tablet');
    });

    testGoldens('renders page with grammar in mobile layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final grammar = Grammar.simpleRegular(
        id: 'test-regular-mobile',
        name: 'Regular Mobile',
      );

      await _pumpGrammarPage(
        tester,
        grammar: grammar,
        size: const Size(430, 932),
        isMobile: true,
      );

      await screenMatchesGolden(tester, 'grammar_page_regular_mobile');
    });

    testGoldens('renders page with lambda production in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.utc(2024, 1, 1);
      const p1 = Production(
        id: 'p1',
        leftSide: ['S'],
        rightSide: ['a', 'S'],
        isLambda: false,
        order: 1,
      );
      const p2 = Production(
        id: 'p2',
        leftSide: ['S'],
        rightSide: [],
        isLambda: true,
        order: 2,
      );

      final grammar = Grammar(
        id: 'lambda-cfg',
        name: 'Lambda Productions',
        terminals: const {'a'},
        nonterminals: const {'S'},
        startSymbol: 'S',
        productions: {p1, p2},
        type: GrammarType.contextFree,
        created: now,
        modified: now,
      );

      await _pumpGrammarPage(
        tester,
        grammar: grammar,
        size: const Size(1400, 900),
        isMobile: false,
      );

      await screenMatchesGolden(tester, 'grammar_page_lambda_desktop');
    });
  });
}
