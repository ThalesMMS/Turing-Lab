import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';

class _TestCallbacks {
  int autoLayoutCallCount = 0;
  int clearCallCount = 0;
  int kleeneStarCallCount = 0;
  int reverseFsaCallCount = 0;
  String? lastRegexValue;

  void onClear() {
    clearCallCount++;
  }

  void onRegexToNfa(String regex) {
    lastRegexValue = regex;
  }

  void onAutoLayout() {
    autoLayoutCallCount++;
  }

  void onKleeneStar() {
    kleeneStarCallCount++;
  }

  void onReverseFsa() {
    reverseFsaCallCount++;
  }
}

class _MockFileOperationsService extends FileOperationsService {
  Future<FSA?> loadAutomatonFromFile(String path) async {
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
  Future<void> Function(FSA)? onUnionDfa,
  Future<void> Function(FSA)? onConcatenateFsa,
  VoidCallback? onKleeneStarFsa,
  VoidCallback? onReverseFsa,
  Future<void> Function(FSA)? onIntersectionDfa,
  Future<void> Function(FSA)? onDifferenceDfa,
  VoidCallback? onPrefixClosure,
  VoidCallback? onSuffixClosure,
  VoidCallback? onFsaToGrammar,
  VoidCallback? onAutoLayout,
  Future<void> Function(FSA)? onCompareEquivalence,
  bool? equivalenceResult,
  String? equivalenceDetails,
  FileOperationsService? fileService,
}) async {
  await tester.pumpWidget(
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
            onUnionDfa: onUnionDfa,
            onConcatenateFsa: onConcatenateFsa,
            onKleeneStarFsa: onKleeneStarFsa,
            onReverseFsa: onReverseFsa,
            onIntersectionDfa: onIntersectionDfa,
            onDifferenceDfa: onDifferenceDfa,
            onPrefixClosure: onPrefixClosure,
            onSuffixClosure: onSuffixClosure,
            onFsaToGrammar: onFsaToGrammar,
            onAutoLayout: onAutoLayout,
            onCompareEquivalence: onCompareEquivalence,
            equivalenceResult: equivalenceResult,
            equivalenceDetails: equivalenceDetails,
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

  group('AlgorithmPanel', () {
    testWidgets('renders all algorithm buttons and regex input', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.text('Algorithms'), findsOneWidget);
      expect(find.text('Regex to NFA'), findsOneWidget);
      expect(find.text('NFA to DFA'), findsOneWidget);
      expect(find.text('Remove λ-transitions'), findsOneWidget);
      expect(find.text('Minimize DFA'), findsOneWidget);
      expect(find.text('Complete DFA'), findsOneWidget);
      expect(find.text('Complement DFA'), findsOneWidget);
      expect(find.text('Union of DFAs'), findsOneWidget);
      expect(find.text('Concatenation of FSAs'), findsOneWidget);
      expect(find.text('Kleene Star'), findsOneWidget);
      expect(find.text('Reverse FSA'), findsOneWidget);
      expect(find.text('Intersection of DFAs'), findsOneWidget);
      expect(find.text('Difference of DFAs'), findsOneWidget);
      expect(find.text('Prefix Closure'), findsOneWidget);
      expect(find.text('Suffix Closure'), findsOneWidget);
      expect(find.text('FA to Regex'), findsOneWidget);
      expect(find.text('FSA to Grammar'), findsOneWidget);
      expect(find.text('Auto Layout'), findsOneWidget);
      expect(find.text('Compare Equivalence'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Regular Expression'),
        findsOneWidget,
      );
    });

    testWidgets('triggers auto layout callback when button is tapped', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onAutoLayout: callbacks.onAutoLayout);

      expect(callbacks.autoLayoutCallCount, 0);

      await tester.ensureVisible(find.text('Auto Layout'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto Layout'));
      await tester.pumpAndSettle();

      expect(callbacks.autoLayoutCallCount, 1);
    });

    testWidgets('triggers clear callback when button is tapped', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onClear: callbacks.onClear);

      expect(callbacks.clearCallCount, 0);

      await tester.ensureVisible(find.text('Clear'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(callbacks.clearCallCount, 1);
    });

    testWidgets('triggers Kleene star callback when button is tapped', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(
        tester,
        onKleeneStarFsa: callbacks.onKleeneStar,
      );

      await tester.ensureVisible(find.text('Kleene Star'));
      await tester.tap(find.text('Kleene Star'));
      await tester.pumpAndSettle();

      expect(callbacks.kleeneStarCallCount, 1);
    });

    testWidgets('triggers FSA reversal callback when button is tapped', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(
        tester,
        onReverseFsa: callbacks.onReverseFsa,
      );

      await tester.ensureVisible(find.text('Reverse FSA'));
      await tester.tap(find.text('Reverse FSA'));
      await tester.pumpAndSettle();

      expect(callbacks.reverseFsaCallCount, 1);
    });

    testWidgets('triggers regex to NFA callback when button is pressed', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onRegexToNfa: callbacks.onRegexToNfa);

      expect(callbacks.lastRegexValue, isNull);

      await tester.enterText(find.byType(TextField), '(a|b)*');
      await tester.tap(
        find.widgetWithIcon(ElevatedButton, Icons.arrow_forward),
      );
      await tester.pumpAndSettle();

      expect(callbacks.lastRegexValue, '(a|b)*');
    });

    testWidgets('triggers regex to NFA callback when enter is pressed', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onRegexToNfa: callbacks.onRegexToNfa);

      expect(callbacks.lastRegexValue, isNull);

      await tester.enterText(find.byType(TextField), 'a*b*');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(callbacks.lastRegexValue, 'a*b*');
    });

    testWidgets('does not trigger regex callback with empty input', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onRegexToNfa: callbacks.onRegexToNfa);

      expect(callbacks.lastRegexValue, isNull);

      await tester.tap(
        find.widgetWithIcon(ElevatedButton, Icons.arrow_forward),
      );
      await tester.pumpAndSettle();

      expect(callbacks.lastRegexValue, isNull);
    });

    testWidgets('displays equivalence result when result is true', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(
        tester,
        equivalenceResult: true,
        equivalenceDetails: 'The automata accept the same language',
      );

      expect(find.text('Automata are equivalent'), findsOneWidget);
      expect(
        find.text('The automata accept the same language'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays equivalence result when result is false', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(
        tester,
        equivalenceResult: false,
        equivalenceDetails: 'Distinguishing string: ab',
      );

      expect(find.text('Automata are not equivalent'), findsOneWidget);
      expect(find.text('Distinguishing string: ab'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays equivalence result with null result', (tester) async {
      await _pumpAlgorithmPanel(
        tester,
        equivalenceResult: null,
        equivalenceDetails: 'Comparison in progress',
      );

      expect(find.text('Equivalence comparison'), findsOneWidget);
      expect(find.text('Comparison in progress'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('does not display equivalence result when no data provided', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.text('Automata are equivalent'), findsNothing);
      expect(find.text('Automata are not equivalent'), findsNothing);
      expect(find.text('Equivalence comparison'), findsNothing);
    });

    testWidgets('displays correct icons for each algorithm button', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.byIcon(Icons.transform), findsWidgets);
      expect(find.byIcon(Icons.highlight_off), findsOneWidget);
      expect(find.byIcon(Icons.compress), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.flip), findsOneWidget);
      expect(find.byIcon(Icons.merge_type), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(find.byIcon(Icons.call_merge), findsOneWidget);
      expect(find.byIcon(Icons.call_split), findsOneWidget);
      expect(find.byIcon(Icons.vertical_align_top), findsOneWidget);
      expect(find.byIcon(Icons.vertical_align_bottom), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_motion), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('renders within a scrollable card', (tester) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses mock file service when provided', (tester) async {
      final mockFileService = _MockFileOperationsService();

      await _pumpAlgorithmPanel(tester, fileService: mockFileService);

      expect(find.byType(AlgorithmPanel), findsOneWidget);
    });

    testWidgets('displays descriptions for each algorithm button', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(tester);

      expect(
        find.text('Convert non-deterministic to deterministic automaton'),
        findsOneWidget,
      );
      expect(
        find.text('Eliminate epsilon transitions from the automaton'),
        findsOneWidget,
      );
      expect(
        find.text('Minimize deterministic finite automaton'),
        findsOneWidget,
      );
      expect(find.text('Add trap state to make DFA complete'), findsOneWidget);
      expect(
        find.text('Flip accepting states after completion'),
        findsOneWidget,
      );
      expect(
        find.text('Combine this DFA with another automaton from file'),
        findsOneWidget,
      );
    });

    testWidgets('displays regex input field with hint text', (tester) async {
      await _pumpAlgorithmPanel(tester);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.labelText, 'Regular Expression');
      expect(textField.decoration?.hintText, 'e.g., (a|b)*');
    });

    testWidgets('shows binary operation buttons', (tester) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.text('Union of DFAs'), findsOneWidget);
      expect(find.text('Concatenation of FSAs'), findsOneWidget);
      expect(find.text('Kleene Star'), findsOneWidget);
      expect(find.text('Reverse FSA'), findsOneWidget);
      expect(find.text('Intersection of DFAs'), findsOneWidget);
      expect(find.text('Difference of DFAs'), findsOneWidget);
    });

    testWidgets('displays correct button descriptions', (tester) async {
      await _pumpAlgorithmPanel(tester);

      expect(
        find.text('Accept all prefixes of the DFA language'),
        findsOneWidget,
      );
      expect(
        find.text('Accept all suffixes of the DFA language'),
        findsOneWidget,
      );
      expect(
        find.text('Convert finite automaton to regular expression'),
        findsOneWidget,
      );
      expect(
        find.text('Convert finite automaton to regular grammar'),
        findsOneWidget,
      );
      expect(find.text('Arrange states in a circle'), findsOneWidget);
      expect(find.text('Compare two DFAs for equivalence'), findsOneWidget);
      expect(find.text('Clear current automaton'), findsOneWidget);
    });

    testWidgets('displays title text with correct styling', (tester) async {
      await _pumpAlgorithmPanel(tester);

      final titleText = find.text('Algorithms');
      expect(titleText, findsOneWidget);

      final textWidget = tester.widget<Text>(titleText);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
