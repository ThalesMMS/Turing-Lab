import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/regex_to_fa_manual.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('RegexToFaManualSession AST snapshot', () {
    test('uses deterministic IDs and UTF-16 source spans', () {
      final first = _start('(a|😀)*b?');
      final second = _start('(a|😀)*b?');

      expect(first.ast.nodes.keys, second.ast.nodes.keys);
      expect(first.ast.rootId, 'ast_root');
      expect(first.ast.nodes['ast_root']!.span.start, 0);
      expect(first.ast.nodes['ast_root']!.span.end, '(a|😀)*b?'.length);
      expect(
        first.ast.nodes['ast_root_0']!.kind,
        RegexToFaAstNodeKind.kleeneStar,
      );
      expect(first.ast.nodes['ast_root_0']!.span.start, 0);
      expect(first.ast.nodes['ast_root_0']!.span.end, 7);
      expect(
        first.ast.nodes['ast_root_0_0']!.kind,
        RegexToFaAstNodeKind.union,
      );
      expect(first.ast.nodes['ast_root_0_0']!.span.start, 0);
      expect(first.ast.nodes['ast_root_0_0']!.span.end, 6);
      expect(first.ast.nodes['ast_root_0_0_1']!.value, '😀');
      expect(first.ast.nodes['ast_root_0_0_1']!.span.start, 3);
      expect(first.ast.nodes['ast_root_0_0_1']!.span.end, 5);
      expect(
        first.ast.nodes['ast_root_1']!.kind,
        RegexToFaAstNodeKind.optional,
      );
    });

    test('rejects an invalid source document', () {
      final result = RegexToFaManualSession.start(
        sourceDocument: _document(''),
        sourceRevision: 1,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.diagnostics.single.code,
        RegexToFaManualDiagnosticCode.invalidSource,
      );
    });

    test('covers every base node in the existing regex dialect', () {
      final expressions = <String, RegexToFaAstNodeKind>{
        'a': RegexToFaAstNodeKind.symbol,
        '.': RegexToFaAstNodeKind.dot,
        'ε': RegexToFaAstNodeKind.epsilon,
        '∅': RegexToFaAstNodeKind.emptyLanguage,
        '[a-c]': RegexToFaAstNodeKind.characterSet,
        r'\d': RegexToFaAstNodeKind.shortcut,
      };

      for (final entry in expressions.entries) {
        final session = _start(entry.key);
        expect(session.ast.nodes[session.ast.rootId]!.kind, entry.value);
        expect(
          session.ast.nodes[session.ast.rootId]!.canonicalExpression,
          entry.key,
        );
      }
    });
  });

  group('RegexToFaManualSession oracle', () {
    test('returns deterministic collision-safe canonical fragment IDs', () {
      final session = _start('a|b');
      final first = session.expectedFragment('ast_root_0').fragment!;
      final repeated = session.expectedFragment('ast_root_0').fragment!;
      final sibling = session.expectedFragment('ast_root_1').fragment!;

      expect(
        first.states.map((state) => state.id).toSet(),
        repeated.states.map((state) => state.id).toSet(),
      );
      expect(
        first.fsaTransitions.map((transition) => transition.id).toSet(),
        repeated.fsaTransitions.map((transition) => transition.id).toSet(),
      );
      expect(
        first.states.map((state) => state.id).toSet().intersection(
              sibling.states.map((state) => state.id).toSet(),
            ),
        isEmpty,
      );
    });

    test('accepts an isomorphic learner fragment with different IDs', () {
      final session = _start('a');
      final expected = session.expectedFragment(session.ast.rootId).fragment!;
      final learner = _rename(expected, 'learner');

      final structural = RegexToFaManualSession.compareStructure(
        learner,
        expected,
      );
      final result = session.createBase(
        nodeId: session.ast.rootId,
        candidate: learner,
      );

      expect(structural.isEquivalent, isTrue);
      expect(result.isSuccess, isTrue);
      expect(result.session.isComplete, isTrue);
      expect(result.session.exactComparison?.isEquivalent, isTrue);
    });

    test('rejects a structurally different candidate', () {
      final session = _start('a|b');
      var current = _applyExpected(session, 'ast_root_0');
      current = _applyExpected(current, 'ast_root_1');
      final wrong = current.expectedFragment('ast_root_0').fragment!;

      final result = current.combineUnion(
        nodeId: current.ast.rootId,
        candidate: wrong,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.diagnostics.single.code,
        RegexToFaManualDiagnosticCode.structureMismatch,
      );
    });

    test('rejects inconsistent entry and accepting flags', () {
      final session = _start('a');
      final expected = session.expectedFragment(session.ast.rootId).fragment!;
      final broken = _withoutInitialFlag(expected);

      final result = session.createBase(
        nodeId: session.ast.rootId,
        candidate: broken,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.diagnostics.single.code,
        RegexToFaManualDiagnosticCode.invalidCandidate,
      );
    });
  });

  group('RegexToFaManualSession commands', () {
    test('enforces postorder preconditions and action kinds', () {
      final session = _start('a|b');
      final expectedRoot =
          session.expectedFragment(session.ast.rootId).fragment!;

      final missingChildren = session.combineUnion(
        nodeId: session.ast.rootId,
        candidate: expectedRoot,
      );
      final wrongAction = session.createBase(
        nodeId: session.ast.rootId,
        candidate: expectedRoot,
      );

      expect(
        missingChildren.diagnostics.single.code,
        RegexToFaManualDiagnosticCode.missingChildFragment,
      );
      expect(
        wrongAction.diagnostics.single.code,
        RegexToFaManualDiagnosticCode.wrongAction,
      );
    });

    test('rejects state IDs colliding with an unrelated active fragment', () {
      var session = _start('ab');
      final left = _rename(
        session.expectedFragment('ast_root_0').fragment!,
        'shared',
      );
      session =
          session.createBase(nodeId: 'ast_root_0', candidate: left).session;
      final collidingRight = _rename(
        session.expectedFragment('ast_root_1').fragment!,
        'shared',
      );

      final result = session.createBase(
        nodeId: 'ast_root_1',
        candidate: collidingRight,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.diagnostics.single.code,
        RegexToFaManualDiagnosticCode.idCollision,
      );
    });

    test('completes all supported operator actions with exact evidence', () {
      for (final source in <String>['a|b', 'ab', 'a*', 'a+', 'a?']) {
        final completed = _complete(_start(source), 'ast_root');

        expect(completed.isComplete, isTrue, reason: source);
        expect(completed.activeFragments.keys, ['ast_root'], reason: source);
        expect(completed.exactComparison?.isEquivalent, isTrue, reason: source);
        expect(completed.actions.map((action) => action.id).toSet().length,
            completed.actions.length);
      }
    });

    test('supports base constructs from the existing dialect', () {
      for (final source in <String>[
        'ε',
        '∅',
        '[a-c]',
        r'\d',
        '.',
        r'\|',
        '😀',
      ]) {
        final completed = _complete(_start(source), 'ast_root');
        expect(completed.isComplete, isTrue, reason: source);
      }
    });

    test('undo, redo, restart, and branch preserve immutable history', () {
      final completed = _complete(_start('a|b'), 'ast_root');
      final originalActions = completed.actions;

      final undone = completed.undo().session;
      final redone = undone.redo().session;
      final restarted = completed.restart().session;

      expect(completed.isComplete, isTrue);
      expect(undone.isComplete, isFalse);
      expect(undone.canRedo, isTrue);
      expect(redone.isComplete, isTrue);
      expect(restarted.actions, isEmpty);
      expect(restarted.activeFragments, isEmpty);
      expect(completed.actions, same(originalActions));
    });

    test('source edits invalidate the session explicitly', () {
      final session = _start('a');
      final invalidated = session.invalidateIfSourceChanged(
        currentDocument: _document('b'),
        currentRevision: 2,
      );

      expect(invalidated.status, RegexToFaManualStatus.invalidated);
      expect(
        invalidated.diagnostics.single.code,
        RegexToFaManualDiagnosticCode.sourceChanged,
      );
      final expected = session.expectedFragment(session.ast.rootId).fragment!;
      final rejected = invalidated.createBase(
        nodeId: invalidated.ast.rootId,
        candidate: expected,
      );
      expect(rejected.isSuccess, isFalse);
      expect(
        rejected.diagnostics.single.code,
        RegexToFaManualDiagnosticCode.sourceChanged,
      );
    });
  });
}

RegexToFaManualSession _start(String source) {
  final result = RegexToFaManualSession.start(
    sourceDocument: _document(source),
    sourceRevision: 1,
  );
  expect(result.diagnostics, isEmpty, reason: source);
  return result.session!;
}

RegexDocument _document(String source) => RegexDocument(
      id: 'regex-doc',
      name: 'Regex',
      source: source,
      alphabet: const ['a', 'b', 'c', '0', '1', '😀', '|'],
    );

RegexToFaManualSession _complete(
  RegexToFaManualSession session,
  String nodeId,
) {
  var current = session;
  final node = current.ast.nodes[nodeId]!;
  for (final childId in node.childIds) {
    current = _complete(current, childId);
  }
  return _applyExpected(current, nodeId);
}

RegexToFaManualSession _applyExpected(
  RegexToFaManualSession session,
  String nodeId,
) {
  final node = session.ast.nodes[nodeId]!;
  final candidate = session.expectedFragment(nodeId).fragment!;
  final result = switch (node.kind) {
    RegexToFaAstNodeKind.symbol ||
    RegexToFaAstNodeKind.dot ||
    RegexToFaAstNodeKind.epsilon ||
    RegexToFaAstNodeKind.emptyLanguage ||
    RegexToFaAstNodeKind.characterSet ||
    RegexToFaAstNodeKind.shortcut =>
      session.createBase(nodeId: nodeId, candidate: candidate),
    RegexToFaAstNodeKind.union =>
      session.combineUnion(nodeId: nodeId, candidate: candidate),
    RegexToFaAstNodeKind.concatenation =>
      session.combineConcat(nodeId: nodeId, candidate: candidate),
    RegexToFaAstNodeKind.kleeneStar =>
      session.applyStar(nodeId: nodeId, candidate: candidate),
    RegexToFaAstNodeKind.plus =>
      session.applyPlus(nodeId: nodeId, candidate: candidate),
    RegexToFaAstNodeKind.optional =>
      session.applyOptional(nodeId: nodeId, candidate: candidate),
  };
  expect(result.diagnostics, isEmpty, reason: '$nodeId ${node.kind.name}');
  return result.session;
}

FSA _rename(FSA source, String prefix) {
  final oldStates = source.states.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final states = <String, State>{};
  for (var index = 0; index < oldStates.length; index++) {
    final old = oldStates[index];
    states[old.id] = old.copyWith(
      id: '${prefix}_s$index',
      position: Vector2(index * 17, index * 29),
    );
  }
  final oldTransitions = source.fsaTransitions.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final transitions = <FSATransition>{};
  for (var index = 0; index < oldTransitions.length; index++) {
    final old = oldTransitions[index];
    transitions.add(
      old.copyWith(
        id: '${prefix}_t$index',
        fromState: states[old.fromState.id],
        toState: states[old.toState.id],
      ),
    );
  }
  return FSA(
    id: '${prefix}_fsa',
    name: source.name,
    states: states.values.toSet(),
    transitions: transitions,
    alphabet: source.alphabet,
    initialState:
        source.initialState == null ? null : states[source.initialState!.id],
    acceptingStates:
        source.acceptingStates.map((state) => states[state.id]!).toSet(),
    created: source.created,
    modified: source.modified,
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}

FSA _withoutInitialFlag(FSA source) {
  final states = <String, State>{
    for (final state in source.states)
      state.id: state.copyWith(isInitial: false),
  };
  final transitions = source.fsaTransitions
      .map(
        (transition) => transition.copyWith(
          fromState: states[transition.fromState.id],
          toState: states[transition.toState.id],
        ),
      )
      .toSet();
  return source.copyWith(
    states: states.values.toSet(),
    transitions: transitions,
    initialState: states[source.initialState!.id],
    acceptingStates:
        source.acceptingStates.map((state) => states[state.id]!).toSet(),
  );
}
