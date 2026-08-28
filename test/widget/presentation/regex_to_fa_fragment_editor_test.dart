import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/core/manual_conversions/regex_to_fa_session_factory.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/presentation/widgets/regex_to_fa_fragment_editor.dart';

void main() {
  testWidgets('builds a real learner FSA and passes the Thompson oracle', (
    tester,
  ) async {
    final session = _session('a');
    Map<String, Object?>? submitted;
    ManualConversionCommandResult? validation;
    await _pumpEditor(
      tester,
      requirement: session.currentRequirement!,
      onSubmit: (payload) {
        submitted = payload;
        final encoded = payload['fragment']! as Map;
        validation = RegexToFaSessionFactory.applyLearnerFragment(
          session: session,
          fragment: FSA.fromJson(Map<String, dynamic>.from(encoded)),
        );
      },
    );

    expect(find.text('Active syntax node'), findsOneWidget);
    expect(find.textContaining('ast_root · symbol · source [0, 1)'),
        findsOneWidget);
    expect(find.textContaining('2 states, 1 transitions'), findsOneWidget);
    expect(find.textContaining('JSON'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('regex-fa-add-state')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add state'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('regex-fa-state-id')),
          )
          .controller!
          .text,
      'ast_root_s0',
    );
    await tester.tap(find.byKey(const ValueKey('regex-fa-state-label')));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('regex-fa-add-state')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-state-accepting')));
    await tester.tap(find.byKey(const ValueKey('regex-fa-save-state')));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 of 2 expected'), findsOneWidget);
    expect(find.textContaining('ast_root_s0 · entry'), findsOneWidget);
    expect(find.textContaining('ast_root_s1 · accepting'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('regex-fa-add-transition')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-transition-to')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('q1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-symbol-a')));
    await tester.tap(find.byKey(const ValueKey('regex-fa-save-transition')));
    await tester.pumpAndSettle();

    final checkFragment = find.byKey(const ValueKey('regex-fa-check-fragment'));
    await tester.scrollUntilVisible(
      checkFragment,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(checkFragment);
    await tester.pump();

    expect(submitted, isNotNull);
    final fsa = FSA.fromJson(
      Map<String, dynamic>.from(submitted!['fragment']! as Map),
    );
    expect(fsa.states.map((state) => state.id),
        containsAll(['ast_root_s0', 'ast_root_s1']));
    expect(fsa.initialState!.id, 'ast_root_s0');
    expect(fsa.acceptingStates.single.id, 'ast_root_s1');
    expect(fsa.fsaTransitions.single.inputSymbols, {'a'});
    expect(validation!.isSuccess, isTrue);
    expect(validation!.session.isComplete, isTrue);
    expect(
      validation!.session.latestEvidence!.certainty,
      ManualConversionCertainty.exact,
    );
  });

  testWidgets('rejects duplicate state IDs next to the state ID field', (
    tester,
  ) async {
    final session = _session('a');
    await _pumpEditor(
      tester,
      requirement: session.currentRequirement!,
      onSubmit: (_) {},
    );

    await tester.tap(find.byKey(const ValueKey('regex-fa-add-state')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-save-state')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('regex-fa-add-state')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('regex-fa-state-id')),
      'ast_root_s0',
    );
    await tester.tap(find.byKey(const ValueKey('regex-fa-save-state')));
    await tester.pump();

    expect(find.text('Use a unique state ID.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add state'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('creates epsilon transitions without a raw symbol field', (
    tester,
  ) async {
    final session = _session('ε');
    ManualConversionCommandResult? validation;
    await _pumpEditor(
      tester,
      requirement: session.currentRequirement!,
      onSubmit: (payload) {
        validation = RegexToFaSessionFactory.applyLearnerFragment(
          session: session,
          fragment: FSA.fromJson(
            Map<String, dynamic>.from(payload['fragment']! as Map),
          ),
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('regex-fa-add-state')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-save-state')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-add-state')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-state-accepting')));
    await tester.tap(find.byKey(const ValueKey('regex-fa-save-state')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('regex-fa-add-transition')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-transition-to')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('q1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('regex-fa-transition-epsilon')));
    await tester.tap(find.byKey(const ValueKey('regex-fa-save-transition')));
    await tester.pumpAndSettle();

    final checkFragment = find.byKey(const ValueKey('regex-fa-check-fragment'));
    await tester.scrollUntilVisible(
      checkFragment,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(checkFragment);
    await tester.pump();

    expect(validation!.isSuccess, isTrue);
    final encoded = validation!.session.learnerArtifact!['fsa']! as Map;
    final learner = FSA.fromJson(Map<String, dynamic>.from(encoded));
    expect(learner.fsaTransitions.single.isEpsilonTransition, isTrue);
  });

  testWidgets('reflows at 320 px with 200 percent text and keeps semantics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = _session('(a|b)*');

    await _pumpEditor(
      tester,
      requirement: session.currentRequirement!,
      textScaler: const TextScaler.linear(2),
      onSubmit: (_) {},
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Active syntax node and fragment invariant'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Add state'), findsOneWidget);
    expect(find.bySemanticsLabel('Check fragment'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final addState = find.byKey(const ValueKey('regex-fa-add-state'));
    await tester.scrollUntilVisible(
      addState,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(addState);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('regex-fa-state-id')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('regex-fa-state-initial')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

ManualConversionSession _session(String source) {
  return RegexToFaSessionFactory.create(
    source: RegexDocument(
      id: 'regex-doc',
      name: 'Regex',
      source: source,
      alphabet: const ['a', 'b'],
    ),
    sourceRevision: 1,
  );
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required ManualConversionRequirement requirement,
  required ValueChanged<Map<String, Object?>> onSubmit,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RegexToFaFragmentEditor(
              requirement: requirement,
              onSubmit: onSubmit,
            ),
          ),
        ),
      ),
    ),
  );
}
