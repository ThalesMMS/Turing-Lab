//
//  algorithm_panel_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for the algorithm panel, capturing snapshots
//  of critical states: empty panel, algorithm buttons, regex input, equivalence
//  results, step-by-step mode, and responsive layouts. Guards visual
//  consistency of the algorithm UI across changes and catches automatic
//  regressions.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';

class _MockFileOperationsService extends FileOperationsService {
  Future<String?> loadAutomatonFromFile(String path) async {
    return null;
  }
}

Future<void> _pumpAlgorithmPanel(
  WidgetTester tester, {
  VoidCallback? onNfaToDfa,
  VoidCallback? onMinimizeDfa,
  VoidCallback? onClear,
  Function(String)? onRegexToNfa,
  VoidCallback? onFaToRegex,
  VoidCallback? onRemoveLambda,
  VoidCallback? onCompleteDfa,
  VoidCallback? onComplementDfa,
  VoidCallback? onPrefixClosure,
  VoidCallback? onSuffixClosure,
  VoidCallback? onFsaToGrammar,
  VoidCallback? onAutoLayout,
  bool? equivalenceResult,
  String? equivalenceDetails,
  ValueChanged<bool>? onStepByStepModeChanged,
  Size size = const Size(400, 900),
}) async {
  final fileService = _MockFileOperationsService();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidgetBuilder(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AlgorithmPanel(
            onNfaToDfa: onNfaToDfa,
            onMinimizeDfa: onMinimizeDfa,
            onClear: onClear,
            onRegexToNfa: onRegexToNfa,
            onFaToRegex: onFaToRegex,
            onRemoveLambda: onRemoveLambda,
            onCompleteDfa: onCompleteDfa,
            onComplementDfa: onComplementDfa,
            onPrefixClosure: onPrefixClosure,
            onSuffixClosure: onSuffixClosure,
            onFsaToGrammar: onFsaToGrammar,
            onAutoLayout: onAutoLayout,
            equivalenceResult: equivalenceResult,
            equivalenceDetails: equivalenceDetails,
            onStepByStepModeChanged: onStepByStepModeChanged,
            fileService: fileService,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlgorithmPanel golden tests', () {
    testGoldens('renders empty panel in desktop layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(tester, size: const Size(400, 900));

      await screenMatchesGolden(tester, 'algorithm_panel_empty_desktop');
    });

    testGoldens('renders empty panel in tablet layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(tester, size: const Size(350, 800));

      await screenMatchesGolden(tester, 'algorithm_panel_empty_tablet');
    });

    testGoldens('renders empty panel in mobile layout', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(tester, size: const Size(320, 700));

      await screenMatchesGolden(tester, 'algorithm_panel_empty_mobile');
    });

    testGoldens('renders panel with all callbacks enabled', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onMinimizeDfa: () {},
        onClear: () {},
        onRegexToNfa: (regex) {},
        onFaToRegex: () {},
        onRemoveLambda: () {},
        onCompleteDfa: () {},
        onComplementDfa: () {},
        onPrefixClosure: () {},
        onSuffixClosure: () {},
        onFsaToGrammar: () {},
        onAutoLayout: () {},
        onStepByStepModeChanged: (enabled) {},
        size: const Size(400, 900),
      );

      await screenMatchesGolden(tester, 'algorithm_panel_all_enabled');
    });

    testGoldens('renders panel with regex input filled', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onRegexToNfa: (regex) {},
        onClear: () {},
        size: const Size(400, 900),
      );

      // Enter regex text
      await tester.enterText(find.byType(TextField), '(a|b)*c');
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'algorithm_panel_regex_filled');
    });

    testGoldens('renders panel with equivalence result positive', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onClear: () {},
        equivalenceResult: true,
        equivalenceDetails: 'Automata are equivalent',
        size: const Size(400, 900),
      );

      await screenMatchesGolden(tester, 'algorithm_panel_equivalence_true');
    });

    testGoldens('renders panel with equivalence result negative', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onClear: () {},
        equivalenceResult: false,
        equivalenceDetails: 'Automata are not equivalent: counterexample "ab"',
        size: const Size(400, 900),
      );

      await screenMatchesGolden(tester, 'algorithm_panel_equivalence_false');
    });

    testGoldens('renders panel with step-by-step mode enabled', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onClear: () {},
        onStepByStepModeChanged: (enabled) {},
        size: const Size(400, 900),
      );

      // Enable step-by-step mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'algorithm_panel_step_mode_enabled');
    });

    testGoldens('renders scrolled panel showing bottom buttons', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onMinimizeDfa: () {},
        onClear: () {},
        onAutoLayout: () {},
        onFsaToGrammar: () {},
        size: const Size(400, 600),
      );

      // Scroll to bottom to see Clear and Auto Layout buttons
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'algorithm_panel_scrolled_bottom');
    });

    testGoldens('renders panel with partial callbacks in mobile layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onMinimizeDfa: () {},
        onClear: () {},
        // Other callbacks left as null to show disabled state
        size: const Size(320, 700),
      );

      await screenMatchesGolden(tester, 'algorithm_panel_partial_mobile');
    });

    testGoldens('renders panel focusing on conversion algorithms', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onRemoveLambda: () {},
        onMinimizeDfa: () {},
        onRegexToNfa: (regex) {},
        onFaToRegex: () {},
        size: const Size(400, 700),
      );

      await screenMatchesGolden(tester, 'algorithm_panel_conversions');
    });

    testGoldens('renders panel with regex and equivalence in tablet layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onRegexToNfa: (regex) {},
        onClear: () {},
        equivalenceResult: true,
        equivalenceDetails: 'The two automata accept the same language',
        size: const Size(350, 800),
      );

      // Enter regex
      await tester.enterText(find.byType(TextField), 'a*b+');
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'algorithm_panel_regex_equiv_tablet');
    });

    testGoldens('renders compact panel with essential operations', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpAlgorithmPanel(
        tester,
        onNfaToDfa: () {},
        onMinimizeDfa: () {},
        onCompleteDfa: () {},
        onComplementDfa: () {},
        onClear: () {},
        onAutoLayout: () {},
        size: const Size(380, 650),
      );

      await screenMatchesGolden(tester, 'algorithm_panel_compact');
    });
  });
}
