import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../algorithms/language_comparator.dart';
import '../algorithms/regex_to_nfa_converter.dart';
import '../models/equivalence_comparison_result.dart';
import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/regex_document.dart';
import '../models/state.dart';

enum RegexToFaAstNodeKind {
  symbol,
  dot,
  epsilon,
  emptyLanguage,
  characterSet,
  shortcut,
  union,
  concatenation,
  kleeneStar,
  plus,
  optional,
}

final class RegexToFaSourceSpan {
  const RegexToFaSourceSpan({required this.start, required this.end});

  final int start;
  final int end;

  int get length => end - start;
}

final class RegexToFaAstNodeSnapshot {
  RegexToFaAstNodeSnapshot({
    required this.id,
    required this.kind,
    required this.span,
    required this.canonicalExpression,
    this.value,
    List<String> childIds = const <String>[],
  }) : childIds = List<String>.unmodifiable(childIds);

  final String id;
  final RegexToFaAstNodeKind kind;
  final RegexToFaSourceSpan span;
  final String canonicalExpression;
  final String? value;
  final List<String> childIds;

  bool get isBase => switch (kind) {
        RegexToFaAstNodeKind.symbol ||
        RegexToFaAstNodeKind.dot ||
        RegexToFaAstNodeKind.epsilon ||
        RegexToFaAstNodeKind.emptyLanguage ||
        RegexToFaAstNodeKind.characterSet ||
        RegexToFaAstNodeKind.shortcut =>
          true,
        _ => false,
      };
}

final class RegexToFaAstSnapshot {
  RegexToFaAstSnapshot({
    required this.source,
    required this.rootId,
    required Map<String, RegexToFaAstNodeSnapshot> nodes,
  }) : nodes = Map<String, RegexToFaAstNodeSnapshot>.unmodifiable(nodes);

  final String source;
  final String rootId;
  final Map<String, RegexToFaAstNodeSnapshot> nodes;

  RegexToFaAstNodeSnapshot? node(String id) => nodes[id];
}

enum RegexToFaManualActionType {
  createBase,
  combineUnion,
  combineConcatenation,
  applyKleeneStar,
  applyPlus,
  applyOptional,
}

enum RegexToFaManualStatus { active, complete, invalidated }

enum RegexToFaManualDiagnosticCode {
  invalidSource,
  sourceChanged,
  unknownNode,
  wrongAction,
  fragmentAlreadyBuilt,
  missingChildFragment,
  invalidCandidate,
  idCollision,
  structureMismatch,
  comparisonFailed,
  languageMismatch,
  sessionComplete,
  invalidHistoryIndex,
}

final class RegexToFaManualDiagnostic {
  const RegexToFaManualDiagnostic({
    required this.code,
    required this.message,
    this.nodeId,
  });

  final RegexToFaManualDiagnosticCode code;
  final String message;
  final String? nodeId;
}

final class RegexToFaManualStartResult {
  RegexToFaManualStartResult({
    this.session,
    List<RegexToFaManualDiagnostic> diagnostics = const [],
  }) : diagnostics = List<RegexToFaManualDiagnostic>.unmodifiable(diagnostics);

  final RegexToFaManualSession? session;
  final List<RegexToFaManualDiagnostic> diagnostics;

  bool get isSuccess => session != null && diagnostics.isEmpty;
}

final class RegexToFaManualOracleResult {
  RegexToFaManualOracleResult({
    this.fragment,
    List<RegexToFaManualDiagnostic> diagnostics = const [],
  }) : diagnostics = List<RegexToFaManualDiagnostic>.unmodifiable(diagnostics);

  final FSA? fragment;
  final List<RegexToFaManualDiagnostic> diagnostics;

  bool get isSuccess => fragment != null && diagnostics.isEmpty;
}

final class RegexToFaManualCommandResult {
  RegexToFaManualCommandResult({
    required this.session,
    List<RegexToFaManualDiagnostic> diagnostics = const [],
  }) : diagnostics = List<RegexToFaManualDiagnostic>.unmodifiable(diagnostics);

  final RegexToFaManualSession session;
  final List<RegexToFaManualDiagnostic> diagnostics;

  bool get isSuccess => diagnostics.isEmpty;
}

final class RegexToFaStructuralComparison {
  const RegexToFaStructuralComparison({
    required this.isEquivalent,
    this.reason,
  });

  final bool isEquivalent;
  final String? reason;
}

final class RegexToFaManualAction {
  RegexToFaManualAction({
    required this.id,
    required this.type,
    required this.nodeId,
    required List<String> consumedNodeIds,
    required this.fragment,
    this.exactComparison,
  }) : consumedNodeIds = List<String>.unmodifiable(consumedNodeIds);

  final String id;
  final RegexToFaManualActionType type;
  final String nodeId;
  final List<String> consumedNodeIds;
  final FSA fragment;
  final EquivalenceComparisonResult? exactComparison;
}

/// Immutable command model for learner-driven Regex to epsilon-NFA work.
///
/// The production converter remains the only semantic oracle. Each submitted
/// fragment must be structurally isomorphic to the converter's Thompson result
/// for the corresponding syntax-tree node. The final fragment is also checked
/// by the exact finite-automata language comparator.
final class RegexToFaManualSession {
  RegexToFaManualSession._({
    required this.sourceDocument,
    required this.sourceRevision,
    required this.ast,
    required this.actions,
    required this.cursor,
    required this.activeFragments,
    required this.status,
    required this.diagnostics,
    required this.exactComparison,
  });

  static const schemaId = 'turing-lab.regex-to-fa-manual';
  static const schemaVersion = 1;

  final RegexDocument sourceDocument;
  final int sourceRevision;
  final RegexToFaAstSnapshot ast;
  final List<RegexToFaManualAction> actions;
  final int cursor;
  final Map<String, FSA> activeFragments;
  final RegexToFaManualStatus status;
  final List<RegexToFaManualDiagnostic> diagnostics;
  final EquivalenceComparisonResult? exactComparison;

  bool get canUndo => cursor > 0;
  bool get canRedo => cursor < actions.length;
  bool get isComplete => status == RegexToFaManualStatus.complete;

  static RegexToFaManualStartResult start({
    required RegexDocument sourceDocument,
    required int sourceRevision,
  }) {
    final documentErrors = sourceDocument.validate();
    final parsed = RegexToNFAConverter.parse(sourceDocument.source);
    if (documentErrors.isNotEmpty || parsed == null) {
      return RegexToFaManualStartResult(
        diagnostics: [
          RegexToFaManualDiagnostic(
            code: RegexToFaManualDiagnosticCode.invalidSource,
            message: documentErrors.isNotEmpty
                ? documentErrors.join(' ')
                : 'The regular expression is invalid.',
          ),
        ],
      );
    }

    final builder = _RegexAstSnapshotBuilder(sourceDocument.source);
    final root = builder.build(parsed, 'root');
    final ast = RegexToFaAstSnapshot(
      source: sourceDocument.source,
      rootId: root.id,
      nodes: builder.nodes,
    );
    return RegexToFaManualStartResult(
      session: RegexToFaManualSession._(
        sourceDocument: sourceDocument,
        sourceRevision: sourceRevision,
        ast: ast,
        actions: const <RegexToFaManualAction>[],
        cursor: 0,
        activeFragments: const <String, FSA>{},
        status: RegexToFaManualStatus.active,
        diagnostics: const <RegexToFaManualDiagnostic>[],
        exactComparison: null,
      ),
    );
  }

  RegexToFaManualOracleResult expectedFragment(String nodeId) {
    final node = ast.node(nodeId);
    if (node == null) {
      return RegexToFaManualOracleResult(
        diagnostics: [
          RegexToFaManualDiagnostic(
            code: RegexToFaManualDiagnosticCode.unknownNode,
            message: 'Unknown syntax-tree node $nodeId.',
            nodeId: nodeId,
          ),
        ],
      );
    }
    final converted = RegexToNFAConverter.convert(
      node.canonicalExpression,
      contextAlphabet: sourceDocument.alphabet.toSet(),
    );
    if (converted.isFailure || converted.data == null) {
      return RegexToFaManualOracleResult(
        diagnostics: [
          RegexToFaManualDiagnostic(
            code: RegexToFaManualDiagnosticCode.invalidSource,
            message: converted.error ?? 'The canonical conversion failed.',
            nodeId: nodeId,
          ),
        ],
      );
    }
    final namespace =
        'regex_manual_${_stableHash('${sourceDocument.id}|$sourceRevision|$nodeId')}';
    return RegexToFaManualOracleResult(
      fragment: _deterministicCopy(converted.data!, namespace),
    );
  }

  RegexToFaManualCommandResult createBase({
    required String nodeId,
    required FSA candidate,
  }) {
    return _submit(
      nodeId: nodeId,
      candidate: candidate,
      type: RegexToFaManualActionType.createBase,
      allowedKinds: const {
        RegexToFaAstNodeKind.symbol,
        RegexToFaAstNodeKind.dot,
        RegexToFaAstNodeKind.epsilon,
        RegexToFaAstNodeKind.emptyLanguage,
        RegexToFaAstNodeKind.characterSet,
        RegexToFaAstNodeKind.shortcut,
      },
    );
  }

  RegexToFaManualCommandResult combineUnion({
    required String nodeId,
    required FSA candidate,
  }) {
    return _submit(
      nodeId: nodeId,
      candidate: candidate,
      type: RegexToFaManualActionType.combineUnion,
      allowedKinds: const {RegexToFaAstNodeKind.union},
    );
  }

  RegexToFaManualCommandResult combineConcat({
    required String nodeId,
    required FSA candidate,
  }) {
    return _submit(
      nodeId: nodeId,
      candidate: candidate,
      type: RegexToFaManualActionType.combineConcatenation,
      allowedKinds: const {RegexToFaAstNodeKind.concatenation},
    );
  }

  RegexToFaManualCommandResult applyStar({
    required String nodeId,
    required FSA candidate,
  }) {
    return _submit(
      nodeId: nodeId,
      candidate: candidate,
      type: RegexToFaManualActionType.applyKleeneStar,
      allowedKinds: const {RegexToFaAstNodeKind.kleeneStar},
    );
  }

  RegexToFaManualCommandResult applyPlus({
    required String nodeId,
    required FSA candidate,
  }) {
    return _submit(
      nodeId: nodeId,
      candidate: candidate,
      type: RegexToFaManualActionType.applyPlus,
      allowedKinds: const {RegexToFaAstNodeKind.plus},
    );
  }

  RegexToFaManualCommandResult applyOptional({
    required String nodeId,
    required FSA candidate,
  }) {
    return _submit(
      nodeId: nodeId,
      candidate: candidate,
      type: RegexToFaManualActionType.applyOptional,
      allowedKinds: const {RegexToFaAstNodeKind.optional},
    );
  }

  RegexToFaManualCommandResult undo() {
    if (!canUndo) return _historyFailure();
    return RegexToFaManualCommandResult(session: _atCursor(cursor - 1));
  }

  RegexToFaManualCommandResult redo() {
    if (!canRedo) return _historyFailure();
    return RegexToFaManualCommandResult(session: _atCursor(cursor + 1));
  }

  RegexToFaManualCommandResult restart() {
    return RegexToFaManualCommandResult(
      session: RegexToFaManualSession._(
        sourceDocument: sourceDocument,
        sourceRevision: sourceRevision,
        ast: ast,
        actions: const <RegexToFaManualAction>[],
        cursor: 0,
        activeFragments: const <String, FSA>{},
        status: RegexToFaManualStatus.active,
        diagnostics: const <RegexToFaManualDiagnostic>[],
        exactComparison: null,
      ),
    );
  }

  RegexToFaManualSession invalidateIfSourceChanged({
    required RegexDocument currentDocument,
    required int currentRevision,
  }) {
    final unchanged = currentRevision == sourceRevision &&
        currentDocument.id == sourceDocument.id &&
        currentDocument.source == sourceDocument.source &&
        _sameStrings(
          currentDocument.alphabet.toSet(),
          sourceDocument.alphabet.toSet(),
        );
    if (unchanged) return this;
    const diagnostic = RegexToFaManualDiagnostic(
      code: RegexToFaManualDiagnosticCode.sourceChanged,
      message: 'The source regular expression changed during construction.',
    );
    return RegexToFaManualSession._(
      sourceDocument: sourceDocument,
      sourceRevision: sourceRevision,
      ast: ast,
      actions: actions,
      cursor: cursor,
      activeFragments: activeFragments,
      status: RegexToFaManualStatus.invalidated,
      diagnostics: const [diagnostic],
      exactComparison: exactComparison,
    );
  }

  RegexToFaManualCommandResult _submit({
    required String nodeId,
    required FSA candidate,
    required RegexToFaManualActionType type,
    required Set<RegexToFaAstNodeKind> allowedKinds,
  }) {
    if (status == RegexToFaManualStatus.invalidated) {
      return RegexToFaManualCommandResult(
        session: this,
        diagnostics: diagnostics,
      );
    }
    if (status == RegexToFaManualStatus.complete) {
      return _failure(
        RegexToFaManualDiagnosticCode.sessionComplete,
        'The construction is already complete.',
        nodeId,
      );
    }
    final node = ast.node(nodeId);
    if (node == null) {
      return _failure(
        RegexToFaManualDiagnosticCode.unknownNode,
        'Unknown syntax-tree node $nodeId.',
        nodeId,
      );
    }
    if (!allowedKinds.contains(node.kind)) {
      return _failure(
        RegexToFaManualDiagnosticCode.wrongAction,
        'Action ${type.name} is not valid for ${node.kind.name}.',
        nodeId,
      );
    }
    if (activeFragments.containsKey(nodeId)) {
      return _failure(
        RegexToFaManualDiagnosticCode.fragmentAlreadyBuilt,
        'A fragment for $nodeId is already active.',
        nodeId,
      );
    }
    for (final childId in node.childIds) {
      if (!activeFragments.containsKey(childId)) {
        return _failure(
          RegexToFaManualDiagnosticCode.missingChildFragment,
          'Build child fragment $childId before $nodeId.',
          nodeId,
        );
      }
    }

    final candidateError = _candidateError(candidate);
    if (candidateError != null) {
      return _failure(
        RegexToFaManualDiagnosticCode.invalidCandidate,
        candidateError,
        nodeId,
      );
    }
    final collision = _collidingStateId(candidate, node.childIds.toSet());
    if (collision != null) {
      return _failure(
        RegexToFaManualDiagnosticCode.idCollision,
        'State ID $collision collides with an unrelated active fragment.',
        nodeId,
      );
    }

    final expectedResult = expectedFragment(nodeId);
    if (!expectedResult.isSuccess) {
      return RegexToFaManualCommandResult(
        session: this,
        diagnostics: expectedResult.diagnostics,
      );
    }
    final structural = compareStructure(candidate, expectedResult.fragment!);
    if (!structural.isEquivalent) {
      return _failure(
        RegexToFaManualDiagnosticCode.structureMismatch,
        structural.reason ?? 'The submitted fragment is not canonical.',
        nodeId,
      );
    }

    EquivalenceComparisonResult? exactComparison;
    if (nodeId == ast.rootId) {
      final comparison = LanguageComparator.compareLanguages(
        candidate,
        expectedResult.fragment!,
      );
      if (comparison.isFailure || comparison.data == null) {
        return _failure(
          RegexToFaManualDiagnosticCode.comparisonFailed,
          comparison.error ?? 'The exact language comparison failed.',
          nodeId,
        );
      }
      exactComparison = comparison.data!;
      if (!exactComparison.isEquivalent) {
        return _failure(
          RegexToFaManualDiagnosticCode.languageMismatch,
          'The completed automaton is not language-equivalent. '
          'Counterexample: ${exactComparison.distinguishingString ?? 'unknown'}.',
          nodeId,
        );
      }
    }

    final baseActions = actions.take(cursor).toList(growable: true);
    final action = RegexToFaManualAction(
      id: _actionId(type, nodeId, candidate, cursor),
      type: type,
      nodeId: nodeId,
      consumedNodeIds: node.childIds,
      fragment: candidate,
      exactComparison: exactComparison,
    );
    baseActions.add(action);
    final next = RegexToFaManualSession._(
      sourceDocument: sourceDocument,
      sourceRevision: sourceRevision,
      ast: ast,
      actions: List<RegexToFaManualAction>.unmodifiable(baseActions),
      cursor: baseActions.length,
      activeFragments: const <String, FSA>{},
      status: RegexToFaManualStatus.active,
      diagnostics: const <RegexToFaManualDiagnostic>[],
      exactComparison: null,
    )._atCursor(baseActions.length);
    return RegexToFaManualCommandResult(session: next);
  }

  RegexToFaManualSession _atCursor(int nextCursor) {
    final fragments = <String, FSA>{};
    EquivalenceComparisonResult? completion;
    for (final action in actions.take(nextCursor)) {
      for (final consumed in action.consumedNodeIds) {
        fragments.remove(consumed);
      }
      fragments[action.nodeId] = action.fragment;
      if (action.nodeId == ast.rootId) completion = action.exactComparison;
    }
    final complete = fragments.length == 1 &&
        fragments.containsKey(ast.rootId) &&
        completion?.isEquivalent == true;
    return RegexToFaManualSession._(
      sourceDocument: sourceDocument,
      sourceRevision: sourceRevision,
      ast: ast,
      actions: actions,
      cursor: nextCursor,
      activeFragments: Map<String, FSA>.unmodifiable(fragments),
      status: complete
          ? RegexToFaManualStatus.complete
          : RegexToFaManualStatus.active,
      diagnostics: const <RegexToFaManualDiagnostic>[],
      exactComparison: complete ? completion : null,
    );
  }

  RegexToFaManualCommandResult _historyFailure() {
    return _failure(
      RegexToFaManualDiagnosticCode.invalidHistoryIndex,
      'No history entry is available in that direction.',
      null,
    );
  }

  RegexToFaManualCommandResult _failure(
    RegexToFaManualDiagnosticCode code,
    String message,
    String? nodeId,
  ) {
    return RegexToFaManualCommandResult(
      session: this,
      diagnostics: [
        RegexToFaManualDiagnostic(
          code: code,
          message: message,
          nodeId: nodeId,
        ),
      ],
    );
  }

  String? _collidingStateId(FSA candidate, Set<String> consumedNodeIds) {
    final reserved = <String>{};
    for (final entry in activeFragments.entries) {
      if (!consumedNodeIds.contains(entry.key)) {
        reserved.addAll(entry.value.states.map((state) => state.id));
      }
    }
    for (final state in candidate.states) {
      if (reserved.contains(state.id)) return state.id;
    }
    return null;
  }

  static RegexToFaStructuralComparison compareStructure(
    FSA candidate,
    FSA expected,
  ) {
    if (!_sameStrings(candidate.alphabet, expected.alphabet)) {
      return const RegexToFaStructuralComparison(
        isEquivalent: false,
        reason: 'The fragment alphabet does not match the canonical fragment.',
      );
    }
    if (candidate.states.length != expected.states.length ||
        candidate.fsaTransitions.length != expected.fsaTransitions.length) {
      return const RegexToFaStructuralComparison(
        isEquivalent: false,
        reason: 'The fragment has the wrong number of states or transitions.',
      );
    }

    final candidateStates = candidate.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final expectedStates = expected.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final choices = <String, List<State>>{};
    for (final state in candidateStates) {
      final signature = _vertexSignature(candidate, state);
      choices[state.id] = expectedStates
          .where((other) => _vertexSignature(expected, other) == signature)
          .toList(growable: false);
      if (choices[state.id]!.isEmpty) {
        return const RegexToFaStructuralComparison(
          isEquivalent: false,
          reason: 'Initial, accepting, or transition-degree invariants differ.',
        );
      }
    }
    candidateStates.sort((a, b) {
      final count = choices[a.id]!.length.compareTo(choices[b.id]!.length);
      return count != 0 ? count : a.id.compareTo(b.id);
    });

    final mapping = <String, String>{};
    final used = <String>{};
    bool search(int index) {
      if (index == candidateStates.length) {
        return _sameCounts(
          _transitionMultiset(candidate, mapping),
          _transitionMultiset(expected, const <String, String>{}),
        );
      }
      final state = candidateStates[index];
      for (final target in choices[state.id]!) {
        if (!used.add(target.id)) continue;
        mapping[state.id] = target.id;
        if (_partialTransitionsMatch(candidate, expected, mapping) &&
            search(index + 1)) {
          return true;
        }
        mapping.remove(state.id);
        used.remove(target.id);
      }
      return false;
    }

    return search(0)
        ? const RegexToFaStructuralComparison(isEquivalent: true)
        : const RegexToFaStructuralComparison(
            isEquivalent: false,
            reason: 'The transition topology is not Thompson-canonical.',
          );
  }
}

final class _RegexAstSnapshotBuilder {
  _RegexAstSnapshotBuilder(this.source);

  final String source;
  final Map<String, RegexToFaAstNodeSnapshot> nodes = {};

  RegexToFaAstNodeSnapshot build(RegexNode node, String path) {
    final childNodes = <RegexToFaAstNodeSnapshot>[];
    final kind = switch (node) {
      SymbolNode() => RegexToFaAstNodeKind.symbol,
      DotNode() => RegexToFaAstNodeKind.dot,
      EpsilonNode() => RegexToFaAstNodeKind.epsilon,
      EmptyLanguageNode() => RegexToFaAstNodeKind.emptyLanguage,
      SetNode() => RegexToFaAstNodeKind.characterSet,
      ShortcutNode() => RegexToFaAstNodeKind.shortcut,
      UnionNode() => RegexToFaAstNodeKind.union,
      ConcatenationNode() => RegexToFaAstNodeKind.concatenation,
      KleeneStarNode() => RegexToFaAstNodeKind.kleeneStar,
      PlusNode() => RegexToFaAstNodeKind.plus,
      QuestionNode() => RegexToFaAstNodeKind.optional,
      _ => throw ArgumentError('Unsupported regex node ${node.runtimeType}.'),
    };
    switch (node) {
      case UnionNode(:final left, :final right):
      case ConcatenationNode(:final left, :final right):
        childNodes.add(build(left, '${path}_0'));
        childNodes.add(build(right, '${path}_1'));
      case KleeneStarNode(:final child):
      case PlusNode(:final child):
      case QuestionNode(:final child):
        childNodes.add(build(child, '${path}_0'));
      case _:
        break;
    }

    var span = _spanFor(node, childNodes);
    span = _expandGrouping(source, span);
    final canonical = switch (node) {
      SymbolNode() ||
      DotNode() ||
      EpsilonNode() ||
      EmptyLanguageNode() ||
      SetNode() ||
      ShortcutNode() =>
        source.substring(span.start, span.end),
      UnionNode() =>
        '(${childNodes[0].canonicalExpression}|${childNodes[1].canonicalExpression})',
      ConcatenationNode() =>
        '(${childNodes[0].canonicalExpression})(${childNodes[1].canonicalExpression})',
      KleeneStarNode() => '(${childNodes.single.canonicalExpression})*',
      PlusNode() => '(${childNodes.single.canonicalExpression})+',
      QuestionNode() => '(${childNodes.single.canonicalExpression})?',
      _ => throw StateError('Unsupported regex node ${node.runtimeType}.'),
    };
    final value = switch (node) {
      SymbolNode(:final symbol) => symbol,
      ShortcutNode(:final code) => code,
      SetNode(:final symbols) => (symbols.toList()..sort()).join(),
      EpsilonNode() => 'ε',
      EmptyLanguageNode() => '∅',
      DotNode() => '.',
      _ => null,
    };
    final snapshot = RegexToFaAstNodeSnapshot(
      id: 'ast_$path',
      kind: kind,
      span: span,
      canonicalExpression: canonical,
      value: value,
      childIds: childNodes.map((child) => child.id).toList(growable: false),
    );
    nodes[snapshot.id] = snapshot;
    return snapshot;
  }

  RegexToFaSourceSpan _spanFor(
    RegexNode node,
    List<RegexToFaAstNodeSnapshot> children,
  ) {
    if (children.length == 2) {
      return RegexToFaSourceSpan(
        start: children.first.span.start,
        end: children.last.span.end,
      );
    }
    if (children.length == 1) {
      final operatorEnd =
          node.position == null ? children.single.span.end : node.position! + 1;
      return RegexToFaSourceSpan(
        start: children.single.span.start,
        end: math.max(children.single.span.end, operatorEnd),
      );
    }
    final start = node.position ?? 0;
    final end = switch (node) {
      SetNode() => _characterClassEnd(source, start),
      ShortcutNode() => _escapedTokenEnd(source, start),
      SymbolNode() when start < source.length && source[start] == '\\' =>
        _escapedTokenEnd(source, start),
      _ => _nextRuneEnd(source, start),
    };
    return RegexToFaSourceSpan(start: start, end: end);
  }
}

String? _candidateError(FSA candidate) {
  final errors = candidate.validate();
  if (errors.isNotEmpty) return errors.join(' ');
  if (candidate.initialState == null) {
    return 'A fragment must have an initial state.';
  }
  final stateIds = <String>{};
  for (final state in candidate.states) {
    if (state.id.trim().isEmpty || !stateIds.add(state.id)) {
      return 'Fragment state IDs must be non-empty and unique.';
    }
    if (state.isInitial != (candidate.initialState?.id == state.id)) {
      return 'Initial-state flags must match the fragment initial state.';
    }
    if (state.isAccepting != candidate.acceptingStates.contains(state)) {
      return 'Accepting-state flags must match the accepting-state set.';
    }
  }
  final transitionIds = <String>{};
  for (final transition in candidate.fsaTransitions) {
    if (transition.id.trim().isEmpty || !transitionIds.add(transition.id)) {
      return 'Fragment transition IDs must be non-empty and unique.';
    }
  }
  return null;
}

FSA _deterministicCopy(FSA source, String namespace) {
  final states = source.states.toList()
    ..sort((a, b) {
      final aOrder = _stateLabelOrder(a.label);
      final bOrder = _stateLabelOrder(b.label);
      final byOrder = aOrder.compareTo(bOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  final stateMap = <String, State>{};
  for (var index = 0; index < states.length; index++) {
    final old = states[index];
    stateMap[old.id] = State(
      id: '${namespace}_s$index',
      label: 'q$index',
      position: Vector2(100 + (index % 6) * 100, 100 + (index ~/ 6) * 100),
      isInitial: source.initialState?.id == old.id,
      isAccepting: source.acceptingStates.contains(old),
      type: old.type,
      properties: old.properties,
    );
  }
  final stateIndex = {
    for (var index = 0; index < states.length; index++) states[index].id: index,
  };
  final transitions = source.fsaTransitions.toList()
    ..sort((a, b) {
      final aKey = _orderedTransitionKey(a, stateIndex);
      final bKey = _orderedTransitionKey(b, stateIndex);
      return aKey.compareTo(bKey);
    });
  final copiedTransitions = <FSATransition>{};
  for (var index = 0; index < transitions.length; index++) {
    final old = transitions[index];
    copiedTransitions.add(
      FSATransition(
        id: '${namespace}_t$index',
        fromState: stateMap[old.fromState.id]!,
        toState: stateMap[old.toState.id]!,
        inputSymbols: old.inputSymbols,
        lambdaSymbol: old.lambdaSymbol,
      ),
    );
  }
  final copiedStates = stateMap.values.toSet();
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return FSA(
    id: '${namespace}_fsa',
    name: 'Regex fragment',
    states: copiedStates,
    transitions: copiedTransitions,
    alphabet: source.alphabet,
    initialState:
        source.initialState == null ? null : stateMap[source.initialState!.id],
    acceptingStates:
        source.acceptingStates.map((state) => stateMap[state.id]!).toSet(),
    created: epoch,
    modified: epoch,
    bounds: math.Rectangle<double>(
      0,
      0,
      math.max(200, math.min(6, states.length) * 100 + 100),
      math.max(200, ((states.length + 5) ~/ 6) * 100 + 100),
    ),
  );
}

int _stateLabelOrder(String label) {
  final match = RegExp(r'^q(\d+)$').firstMatch(label);
  return match == null ? 1 << 30 : int.parse(match.group(1)!);
}

String _orderedTransitionKey(
  FSATransition transition,
  Map<String, int> stateIndex,
) {
  return '${stateIndex[transition.fromState.id]}|'
      '${stateIndex[transition.toState.id]}|${_edgeLabel(transition)}|'
      '${transition.id}';
}

String _vertexSignature(FSA automaton, State state) {
  final outgoing = automaton.fsaTransitions
      .where((transition) => transition.fromState.id == state.id)
      .map(_edgeLabel)
      .toList()
    ..sort();
  final incoming = automaton.fsaTransitions
      .where((transition) => transition.toState.id == state.id)
      .map(_edgeLabel)
      .toList()
    ..sort();
  final loops = automaton.fsaTransitions
      .where((transition) =>
          transition.fromState.id == state.id &&
          transition.toState.id == state.id)
      .map(_edgeLabel)
      .toList()
    ..sort();
  return '${automaton.initialState?.id == state.id}|'
      '${automaton.acceptingStates.contains(state)}|'
      '${_encodeStrings(outgoing)}|${_encodeStrings(incoming)}|'
      '${_encodeStrings(loops)}';
}

String _edgeLabel(FSATransition transition) {
  if (transition.lambdaSymbol != null) return 'epsilon';
  final symbols = transition.inputSymbols.toList()..sort();
  return 'symbols:${_encodeStrings(symbols)}';
}

Map<String, int> _transitionMultiset(
  FSA automaton,
  Map<String, String> mapping,
) {
  final result = <String, int>{};
  for (final transition in automaton.fsaTransitions) {
    final from = mapping[transition.fromState.id] ?? transition.fromState.id;
    final to = mapping[transition.toState.id] ?? transition.toState.id;
    final key = _encodeStrings([from, to, _edgeLabel(transition)]);
    result[key] = (result[key] ?? 0) + 1;
  }
  return result;
}

bool _partialTransitionsMatch(
  FSA candidate,
  FSA expected,
  Map<String, String> mapping,
) {
  final candidateCounts = <String, int>{};
  for (final transition in candidate.fsaTransitions) {
    final from = mapping[transition.fromState.id];
    final to = mapping[transition.toState.id];
    if (from == null || to == null) continue;
    final key = _encodeStrings([from, to, _edgeLabel(transition)]);
    candidateCounts[key] = (candidateCounts[key] ?? 0) + 1;
  }
  final expectedCounts = _transitionMultiset(expected, const {});
  for (final entry in candidateCounts.entries) {
    if ((expectedCounts[entry.key] ?? 0) < entry.value) return false;
  }
  return true;
}

bool _sameStrings(Set<String> first, Set<String> second) {
  return first.length == second.length && first.containsAll(second);
}

bool _sameCounts(Map<String, int> first, Map<String, int> second) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (second[entry.key] != entry.value) return false;
  }
  return true;
}

String _actionId(
  RegexToFaManualActionType type,
  String nodeId,
  FSA candidate,
  int cursor,
) {
  final stateIds = candidate.states.map((state) => state.id).toList()..sort();
  final transitions = candidate.fsaTransitions
      .map((transition) => _encodeStrings([
            transition.id,
            transition.fromState.id,
            transition.toState.id,
            _edgeLabel(transition),
          ]))
      .toList()
    ..sort();
  return 'action_${cursor}_${_stableHash(_encodeStrings([
        type.name,
        nodeId,
        _encodeStrings(stateIds),
        _encodeStrings(transitions),
      ]))}';
}

String _encodeStrings(Iterable<String> values) =>
    values.map((value) => '${value.length}:$value').join();

int _stableHash(String input) {
  var hash = 0x811c9dc5;
  for (final byte in input.codeUnits) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

RegexToFaSourceSpan _expandGrouping(
  String source,
  RegexToFaSourceSpan original,
) {
  var start = original.start;
  var end = original.end;
  while (start > 0 && end < source.length && source[start - 1] == '(') {
    final close = _matchingParenthesis(source, start - 1);
    if (close != end) break;
    start--;
    end++;
  }
  return RegexToFaSourceSpan(start: start, end: end);
}

int _matchingParenthesis(String source, int open) {
  var depth = 0;
  var escaped = false;
  var inClass = false;
  for (var index = open; index < source.length; index++) {
    final char = source[index];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (char == '\\') {
      escaped = true;
      continue;
    }
    if (char == '[') inClass = true;
    if (char == ']') inClass = false;
    if (inClass) continue;
    if (char == '(') depth++;
    if (char == ')' && --depth == 0) return index;
  }
  return -1;
}

int _characterClassEnd(String source, int start) {
  var escaped = false;
  for (var index = start + 1; index < source.length; index++) {
    final char = source[index];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (char == '\\') {
      escaped = true;
      continue;
    }
    if (char == ']') return index + 1;
  }
  return _nextRuneEnd(source, start);
}

int _escapedTokenEnd(String source, int start) {
  final next = start + 1;
  return next < source.length ? _nextRuneEnd(source, next) : next;
}

int _nextRuneEnd(String source, int start) {
  if (start >= source.length) return source.length;
  final first = source.codeUnitAt(start);
  final isHighSurrogate = first >= 0xd800 && first <= 0xdbff;
  return math.min(source.length, start + (isHighSurrogate ? 2 : 1));
}
