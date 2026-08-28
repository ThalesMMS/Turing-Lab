import '../../models/derivation_tree.dart';
import '../../models/derivation_tree_node.dart';
import 'grammar_classification.dart';
import 'grammar_symbol.dart';
import 'phrase_structure_grammar.dart';
import 'production_application.dart';
import 'symbol_sequence.dart';

enum UserDerivationGrammarKind { contextFree, unrestricted }

enum UserDerivationMode {
  leftmost,
  rightmost,
  unrestrictedOccurrence,
  challengeEnforced,
}

enum UserDerivationHistoryPolicy { linearDiscardRedoOnApply }

enum UserDerivationStatus { active, success, localDeadEnd, invalidated }

enum UserDerivationDiagnosticCode {
  invalidGrammar,
  invalidTarget,
  incompatibleMode,
  missingChallenge,
  sourceChanged,
  targetChanged,
  sessionComplete,
  productionMissing,
  occurrenceDoesNotMatch,
  occurrenceRestricted,
  challengeProductionRestricted,
  challengeStepLimit,
  terminalMismatch,
  noAvailableProduction,
  invalidHistoryIndex,
  invalidPayload,
  unsupportedSchema,
}

class UserDerivationDiagnostic {
  const UserDerivationDiagnostic({
    required this.code,
    this.productionId,
    this.startIndex,
  });

  final UserDerivationDiagnosticCode code;
  final String? productionId;
  final int? startIndex;

  Map<String, Object?> toJson() => {
    'code': code.name,
    'productionId': productionId,
    'startIndex': startIndex,
  };

  static UserDerivationDiagnostic fromJson(Object? encoded) {
    if (encoded is! Map) {
      throw const FormatException('Derivation diagnostic must be an object.');
    }
    final map = Map<String, Object?>.from(encoded);
    final code = map['code'];
    final productionId = map['productionId'];
    final startIndex = map['startIndex'];
    if (code is! String || productionId is! String? || startIndex is! int?) {
      throw const FormatException('Malformed derivation diagnostic.');
    }
    return UserDerivationDiagnostic(
      code: UserDerivationDiagnosticCode.values.byName(code),
      productionId: productionId,
      startIndex: startIndex,
    );
  }
}

class UserDerivationChallenge {
  UserDerivationChallenge({
    required this.id,
    required this.enforcedMode,
    this.maxSteps,
    Iterable<String> allowedProductionIds = const <String>[],
  }) : allowedProductionIds = Set<String>.unmodifiable(allowedProductionIds) {
    if (enforcedMode == UserDerivationMode.challengeEnforced) {
      throw ArgumentError.value(
        enforcedMode,
        'enforcedMode',
        'A challenge must enforce a concrete occurrence mode.',
      );
    }
    if (maxSteps != null && maxSteps! < 0) {
      throw ArgumentError.value(maxSteps, 'maxSteps');
    }
  }

  final String id;
  final UserDerivationMode enforcedMode;
  final int? maxSteps;
  final Set<String> allowedProductionIds;

  Map<String, Object?> toJson() => {
    'id': id,
    'enforcedMode': enforcedMode.name,
    'maxSteps': maxSteps,
    'allowedProductionIds': allowedProductionIds.toList()..sort(),
  };

  static UserDerivationChallenge fromJson(Object? encoded) {
    if (encoded is! Map) {
      throw const FormatException('Derivation challenge must be an object.');
    }
    final map = Map<String, Object?>.from(encoded);
    final id = map['id'];
    final mode = map['enforcedMode'];
    final maxSteps = map['maxSteps'];
    final productionIds = map['allowedProductionIds'];
    if (id is! String ||
        mode is! String ||
        maxSteps is! int? ||
        productionIds is! List ||
        productionIds.any((value) => value is! String)) {
      throw const FormatException('Malformed derivation challenge.');
    }
    return UserDerivationChallenge(
      id: id,
      enforcedMode: UserDerivationMode.values.byName(mode),
      maxSteps: maxSteps,
      allowedProductionIds: productionIds.cast<String>(),
    );
  }
}

class UserDerivationStep {
  const UserDerivationStep({
    required this.productionId,
    required this.startIndex,
    required this.occurrenceIndex,
    required this.before,
    required this.after,
  });

  final String productionId;
  final int startIndex;
  final int occurrenceIndex;
  final GrammarSymbolSequence before;
  final GrammarSymbolSequence after;

  Map<String, Object?> toJson() => {
    'productionId': productionId,
    'startIndex': startIndex,
    'occurrenceIndex': occurrenceIndex,
    'before': before.toJson(),
    'after': after.toJson(),
  };

  static UserDerivationStep fromJson(Object? encoded) {
    if (encoded is! Map) {
      throw const FormatException('Derivation step must be an object.');
    }
    final map = Map<String, Object?>.from(encoded);
    final productionId = map['productionId'];
    final startIndex = map['startIndex'];
    final occurrenceIndex = map['occurrenceIndex'];
    if (productionId is! String ||
        startIndex is! int ||
        occurrenceIndex is! int) {
      throw const FormatException('Malformed derivation step.');
    }
    return UserDerivationStep(
      productionId: productionId,
      startIndex: startIndex,
      occurrenceIndex: occurrenceIndex,
      before: GrammarSymbolSequence.fromJson(map['before']),
      after: GrammarSymbolSequence.fromJson(map['after']),
    );
  }
}

class UserDerivationStartResult {
  const UserDerivationStartResult({
    this.session,
    this.diagnostics = const <UserDerivationDiagnostic>[],
  });

  final UserDerivationSession? session;
  final List<UserDerivationDiagnostic> diagnostics;
  bool get isSuccess => session != null;
}

class UserDerivationCommandResult {
  const UserDerivationCommandResult({
    required this.session,
    this.preview,
    this.diagnostics = const <UserDerivationDiagnostic>[],
  });

  final UserDerivationSession session;
  final ProductionApplication? preview;
  final List<UserDerivationDiagnostic> diagnostics;
  bool get isSuccess => diagnostics.isEmpty;
}

class UserDerivationRestoreResult {
  const UserDerivationRestoreResult({
    this.session,
    this.diagnostics = const <UserDerivationDiagnostic>[],
  });

  final UserDerivationSession? session;
  final List<UserDerivationDiagnostic> diagnostics;
  bool get isSuccess => session != null && diagnostics.isEmpty;
}

class UserDerivationSession {
  const UserDerivationSession._({
    required this.grammarKind,
    required this.sourceGrammarId,
    required this.sourceRevision,
    required this.target,
    required this.initialForm,
    required this.mode,
    required this.challenge,
    required this.steps,
    required this.cursor,
    required this.status,
    required this.diagnostics,
  });

  static const schemaId = 'turing-lab.user-derivation-session';
  static const schemaVersion = 1;

  final UserDerivationGrammarKind grammarKind;
  final String sourceGrammarId;
  final int sourceRevision;
  final GrammarSymbolSequence target;
  final GrammarSymbolSequence initialForm;
  final UserDerivationMode mode;
  final UserDerivationChallenge? challenge;
  final List<UserDerivationStep> steps;
  final int cursor;
  final UserDerivationStatus status;
  final List<UserDerivationDiagnostic> diagnostics;

  UserDerivationHistoryPolicy get historyPolicy =>
      UserDerivationHistoryPolicy.linearDiscardRedoOnApply;
  bool get canUndo => cursor > 0;
  bool get canRedo => cursor < steps.length;
  List<UserDerivationStep> get appliedSteps =>
      List<UserDerivationStep>.unmodifiable(steps.take(cursor));
  GrammarSymbolSequence get currentForm =>
      cursor == 0 ? initialForm : steps[cursor - 1].after;
  bool get isCurrent => status != UserDerivationStatus.invalidated;
  bool get isComplete => status == UserDerivationStatus.success;

  static UserDerivationStartResult start({
    required PhraseStructureGrammar grammar,
    required GrammarSymbolSequence target,
    required UserDerivationMode mode,
    UserDerivationChallenge? challenge,
  }) {
    if (!PhraseGrammarClassifier.classify(grammar).isValid) {
      return const UserDerivationStartResult(
        diagnostics: [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.invalidGrammar,
          ),
        ],
      );
    }
    final targetValid = target.symbols.every(
      (symbol) =>
          symbol is TerminalGrammarSymbol && grammar.terminals.contains(symbol),
    );
    if (!targetValid) {
      return const UserDerivationStartResult(
        diagnostics: [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.invalidTarget,
          ),
        ],
      );
    }
    if (mode == UserDerivationMode.challengeEnforced && challenge == null) {
      return const UserDerivationStartResult(
        diagnostics: [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.missingChallenge,
          ),
        ],
      );
    }
    final effectiveMode = mode == UserDerivationMode.challengeEnforced
        ? challenge!.enforcedMode
        : mode;
    if (grammar is UnrestrictedGrammar &&
        effectiveMode != UserDerivationMode.unrestrictedOccurrence) {
      return const UserDerivationStartResult(
        diagnostics: [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.incompatibleMode,
          ),
        ],
      );
    }
    final initialForm = GrammarSymbolSequence([grammar.startSymbol]);
    final session = UserDerivationSession._(
      grammarKind: grammar is ContextFreeGrammar
          ? UserDerivationGrammarKind.contextFree
          : UserDerivationGrammarKind.unrestricted,
      sourceGrammarId: grammar.id,
      sourceRevision: grammar.revision,
      target: target,
      initialForm: initialForm,
      mode: mode,
      challenge: challenge,
      steps: const <UserDerivationStep>[],
      cursor: 0,
      status: UserDerivationStatus.active,
      diagnostics: const <UserDerivationDiagnostic>[],
    );
    return UserDerivationStartResult(
      session: session._withEvaluatedStatus(grammar),
    );
  }

  bool sourceMatches(PhraseStructureGrammar grammar) =>
      grammar.id == sourceGrammarId && grammar.revision == sourceRevision;

  List<ProductionApplication> availableApplications(
    PhraseStructureGrammar grammar,
  ) {
    if (!sourceMatches(grammar) ||
        status == UserDerivationStatus.invalidated ||
        status == UserDerivationStatus.success) {
      return const <ProductionApplication>[];
    }
    return _applicationsFor(this, grammar, currentForm);
  }

  UserDerivationCommandResult preview({
    required PhraseStructureGrammar grammar,
    required String productionId,
    required int startIndex,
  }) {
    final sourceDiagnostic = _sourceDiagnostic(grammar);
    if (sourceDiagnostic != null) {
      return UserDerivationCommandResult(
        session: invalidate(sourceDiagnostic),
        diagnostics: [sourceDiagnostic],
      );
    }
    if (status == UserDerivationStatus.success) {
      return UserDerivationCommandResult(
        session: this,
        diagnostics: const [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.sessionComplete,
          ),
        ],
      );
    }
    final productionExists = grammar.phraseProductions.any(
      (production) => production.id == productionId,
    );
    if (!productionExists) {
      return UserDerivationCommandResult(
        session: this,
        diagnostics: [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.productionMissing,
            productionId: productionId,
          ),
        ],
      );
    }
    final allMatches = PhraseProductionApplicator.allApplications(
      currentForm,
      grammar.phraseProductions,
    );
    final rawMatch = _findApplication(allMatches, productionId, startIndex);
    if (rawMatch == null) {
      return UserDerivationCommandResult(
        session: this,
        diagnostics: [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.occurrenceDoesNotMatch,
            productionId: productionId,
            startIndex: startIndex,
          ),
        ],
      );
    }
    final allowed = _findApplication(
      availableApplications(grammar),
      productionId,
      startIndex,
    );
    if (allowed == null) {
      final challengeRestricted =
          challenge != null &&
          challenge!.allowedProductionIds.isNotEmpty &&
          !challenge!.allowedProductionIds.contains(productionId);
      return UserDerivationCommandResult(
        session: this,
        diagnostics: [
          UserDerivationDiagnostic(
            code: challengeRestricted
                ? UserDerivationDiagnosticCode.challengeProductionRestricted
                : UserDerivationDiagnosticCode.occurrenceRestricted,
            productionId: productionId,
            startIndex: startIndex,
          ),
        ],
      );
    }
    return UserDerivationCommandResult(session: this, preview: allowed);
  }

  UserDerivationCommandResult apply({
    required PhraseStructureGrammar grammar,
    required String productionId,
    required int startIndex,
  }) {
    final previewResult = preview(
      grammar: grammar,
      productionId: productionId,
      startIndex: startIndex,
    );
    final application = previewResult.preview;
    if (application == null) return previewResult;
    final nextSteps = <UserDerivationStep>[
      ...steps.take(cursor),
      UserDerivationStep(
        productionId: application.production.id,
        startIndex: application.occurrence.startIndex,
        occurrenceIndex: application.occurrence.occurrenceIndex,
        before: application.before,
        after: application.after,
      ),
    ];
    final next = _copyWith(
      steps: nextSteps,
      cursor: nextSteps.length,
      status: UserDerivationStatus.active,
      diagnostics: const <UserDerivationDiagnostic>[],
    )._withEvaluatedStatus(grammar);
    return UserDerivationCommandResult(session: next, preview: application);
  }

  UserDerivationCommandResult undo(PhraseStructureGrammar grammar) {
    if (!canUndo) {
      return UserDerivationCommandResult(
        session: this,
        diagnostics: const [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.invalidHistoryIndex,
          ),
        ],
      );
    }
    return UserDerivationCommandResult(
      session: _copyWith(
        cursor: cursor - 1,
        status: UserDerivationStatus.active,
        diagnostics: const <UserDerivationDiagnostic>[],
      )._withEvaluatedStatus(grammar),
    );
  }

  UserDerivationCommandResult redo(PhraseStructureGrammar grammar) {
    if (!canRedo) {
      return UserDerivationCommandResult(
        session: this,
        diagnostics: const [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.invalidHistoryIndex,
          ),
        ],
      );
    }
    return UserDerivationCommandResult(
      session: _copyWith(
        cursor: cursor + 1,
        status: UserDerivationStatus.active,
        diagnostics: const <UserDerivationDiagnostic>[],
      )._withEvaluatedStatus(grammar),
    );
  }

  UserDerivationCommandResult restart(PhraseStructureGrammar grammar) =>
      UserDerivationCommandResult(
        session: _copyWith(
          steps: const <UserDerivationStep>[],
          cursor: 0,
          status: UserDerivationStatus.active,
          diagnostics: const <UserDerivationDiagnostic>[],
        )._withEvaluatedStatus(grammar),
      );

  UserDerivationCommandResult branchFromStep(
    PhraseStructureGrammar grammar,
    int stepIndex,
  ) {
    if (stepIndex < 0 || stepIndex > steps.length) {
      return UserDerivationCommandResult(
        session: this,
        diagnostics: const [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.invalidHistoryIndex,
          ),
        ],
      );
    }
    return UserDerivationCommandResult(
      session: _copyWith(
        cursor: stepIndex,
        status: UserDerivationStatus.active,
        diagnostics: const <UserDerivationDiagnostic>[],
      )._withEvaluatedStatus(grammar),
    );
  }

  UserDerivationSession invalidate(UserDerivationDiagnostic diagnostic) =>
      _copyWith(
        status: UserDerivationStatus.invalidated,
        diagnostics: [diagnostic],
      );

  UserDerivationStartResult forkForTarget({
    required PhraseStructureGrammar grammar,
    required GrammarSymbolSequence target,
  }) =>
      start(grammar: grammar, target: target, mode: mode, challenge: challenge);

  DerivationTree? buildCfgTree(PhraseStructureGrammar grammar) {
    if (grammarKind != UserDerivationGrammarKind.contextFree ||
        grammar is! ContextFreeGrammar ||
        !sourceMatches(grammar)) {
      return null;
    }
    final root = _MutableDerivationNode(grammar.startSymbol);
    final frontier = <_MutableDerivationNode>[root];
    final productions = {
      for (final production in grammar.productions) production.id: production,
    };
    for (final step in appliedSteps) {
      final production = productions[step.productionId];
      if (production == null || step.startIndex >= frontier.length) return null;
      final parent = frontier[step.startIndex];
      final replacement = production.right.symbols
          .map(_MutableDerivationNode.new)
          .toList(growable: false);
      parent.children = replacement.isEmpty
          ? [_MutableDerivationNode(const TerminalGrammarSymbol('ε'))]
          : replacement;
      frontier.replaceRange(step.startIndex, step.startIndex + 1, replacement);
    }
    DerivationTreeNode freeze(_MutableDerivationNode node) {
      return DerivationTreeNode(
        symbol: node.symbol.value,
        lexeme: node.symbol is TerminalGrammarSymbol && node.children.isEmpty
            ? node.symbol.value
            : null,
        children: node.children.map(freeze).toList(growable: false),
      );
    }

    return DerivationTree(root: freeze(root), isShallow: false);
  }

  Map<String, Object?> toJson() => {
    'schema': {'id': schemaId, 'version': schemaVersion},
    'grammarKind': grammarKind.name,
    'sourceGrammarId': sourceGrammarId,
    'sourceRevision': sourceRevision,
    'target': target.toJson(),
    'initialForm': initialForm.toJson(),
    'mode': mode.name,
    'challenge': challenge?.toJson(),
    'historyPolicy': historyPolicy.name,
    'steps': steps.map((step) => step.toJson()).toList(growable: false),
    'cursor': cursor,
    'status': status.name,
    'diagnostics': diagnostics
        .map((diagnostic) => diagnostic.toJson())
        .toList(growable: false),
  };

  Map<String, Object?> toStructuredReport() => {
    ...toJson(),
    'currentForm': currentForm.toJson(),
    'canUndo': canUndo,
    'canRedo': canRedo,
  };

  static UserDerivationRestoreResult restore(
    Object? encoded, {
    required PhraseStructureGrammar grammar,
  }) {
    try {
      if (encoded is! Map) {
        throw const FormatException('Derivation session must be an object.');
      }
      final map = Map<String, Object?>.from(encoded);
      final schema = map['schema'];
      if (schema is! Map || schema['id'] != schemaId) {
        return const UserDerivationRestoreResult(
          diagnostics: [
            UserDerivationDiagnostic(
              code: UserDerivationDiagnosticCode.invalidPayload,
            ),
          ],
        );
      }
      if (schema['version'] != schemaVersion) {
        return const UserDerivationRestoreResult(
          diagnostics: [
            UserDerivationDiagnostic(
              code: UserDerivationDiagnosticCode.unsupportedSchema,
            ),
          ],
        );
      }
      final sourceGrammarId = map['sourceGrammarId'];
      final sourceRevision = map['sourceRevision'];
      final cursor = map['cursor'];
      final rawSteps = map['steps'];
      final rawDiagnostics = map['diagnostics'];
      if (sourceGrammarId is! String ||
          sourceRevision is! int ||
          cursor is! int ||
          rawSteps is! List ||
          rawDiagnostics is! List ||
          map['grammarKind'] is! String ||
          map['mode'] is! String ||
          map['status'] is! String) {
        throw const FormatException('Malformed derivation session.');
      }
      final steps = rawSteps.map(UserDerivationStep.fromJson).toList();
      if (cursor < 0 || cursor > steps.length) {
        throw const FormatException('Invalid derivation history cursor.');
      }
      var session = UserDerivationSession._(
        grammarKind: UserDerivationGrammarKind.values.byName(
          map['grammarKind']! as String,
        ),
        sourceGrammarId: sourceGrammarId,
        sourceRevision: sourceRevision,
        target: GrammarSymbolSequence.fromJson(map['target']),
        initialForm: GrammarSymbolSequence.fromJson(map['initialForm']),
        mode: UserDerivationMode.values.byName(map['mode']! as String),
        challenge: map['challenge'] == null
            ? null
            : UserDerivationChallenge.fromJson(map['challenge']),
        steps: List<UserDerivationStep>.unmodifiable(steps),
        cursor: cursor,
        status: UserDerivationStatus.values.byName(map['status']! as String),
        diagnostics: List<UserDerivationDiagnostic>.unmodifiable(
          rawDiagnostics.map(UserDerivationDiagnostic.fromJson),
        ),
      );
      if (!session.sourceMatches(grammar)) {
        const diagnostic = UserDerivationDiagnostic(
          code: UserDerivationDiagnosticCode.sourceChanged,
        );
        session = session.invalidate(diagnostic);
        return UserDerivationRestoreResult(
          session: session,
          diagnostics: [diagnostic],
        );
      }
      if (!_historyMatchesGrammar(session, grammar)) {
        throw const FormatException(
          'Derivation history does not match source.',
        );
      }
      return UserDerivationRestoreResult(session: session);
    } on Object {
      return const UserDerivationRestoreResult(
        diagnostics: [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.invalidPayload,
          ),
        ],
      );
    }
  }

  UserDerivationSession _withEvaluatedStatus(PhraseStructureGrammar grammar) {
    if (!sourceMatches(grammar)) {
      return invalidate(
        const UserDerivationDiagnostic(
          code: UserDerivationDiagnosticCode.sourceChanged,
        ),
      );
    }
    if (currentForm == target && _isTerminalOnly(currentForm, grammar)) {
      return _copyWith(
        status: UserDerivationStatus.success,
        diagnostics: const <UserDerivationDiagnostic>[],
      );
    }
    if (_isTerminalOnly(currentForm, grammar)) {
      return _copyWith(
        status: UserDerivationStatus.localDeadEnd,
        diagnostics: const [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.terminalMismatch,
          ),
        ],
      );
    }
    final challengeLimit = challenge?.maxSteps;
    if (challengeLimit != null && cursor >= challengeLimit) {
      return _copyWith(
        status: UserDerivationStatus.localDeadEnd,
        diagnostics: const [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.challengeStepLimit,
          ),
        ],
      );
    }
    if (_applicationsFor(this, grammar, currentForm).isEmpty) {
      return _copyWith(
        status: UserDerivationStatus.localDeadEnd,
        diagnostics: const [
          UserDerivationDiagnostic(
            code: UserDerivationDiagnosticCode.noAvailableProduction,
          ),
        ],
      );
    }
    return _copyWith(
      status: UserDerivationStatus.active,
      diagnostics: const <UserDerivationDiagnostic>[],
    );
  }

  UserDerivationDiagnostic? _sourceDiagnostic(PhraseStructureGrammar grammar) =>
      sourceMatches(grammar)
      ? null
      : const UserDerivationDiagnostic(
          code: UserDerivationDiagnosticCode.sourceChanged,
        );

  UserDerivationSession _copyWith({
    List<UserDerivationStep>? steps,
    int? cursor,
    UserDerivationStatus? status,
    List<UserDerivationDiagnostic>? diagnostics,
  }) => UserDerivationSession._(
    grammarKind: grammarKind,
    sourceGrammarId: sourceGrammarId,
    sourceRevision: sourceRevision,
    target: target,
    initialForm: initialForm,
    mode: mode,
    challenge: challenge,
    steps: List<UserDerivationStep>.unmodifiable(steps ?? this.steps),
    cursor: cursor ?? this.cursor,
    status: status ?? this.status,
    diagnostics: List<UserDerivationDiagnostic>.unmodifiable(
      diagnostics ?? this.diagnostics,
    ),
  );
}

List<ProductionApplication> userDerivationApplicationsFor(
  UserDerivationSession session,
  PhraseStructureGrammar grammar,
  GrammarSymbolSequence form,
) => _applicationsFor(session, grammar, form);

List<ProductionApplication> _applicationsFor(
  UserDerivationSession session,
  PhraseStructureGrammar grammar,
  GrammarSymbolSequence form,
) {
  var applications = PhraseProductionApplicator.allApplications(
    form,
    grammar.phraseProductions,
  );
  final challenge = session.challenge;
  if (challenge != null && challenge.allowedProductionIds.isNotEmpty) {
    applications = applications
        .where(
          (application) => challenge.allowedProductionIds.contains(
            application.production.id,
          ),
        )
        .toList(growable: false);
  }
  final effectiveMode = session.mode == UserDerivationMode.challengeEnforced
      ? session.challenge!.enforcedMode
      : session.mode;
  if (effectiveMode == UserDerivationMode.unrestrictedOccurrence) {
    return List<ProductionApplication>.unmodifiable(applications);
  }
  final nonterminalPositions = <int>[
    for (var index = 0; index < form.length; index++)
      if (form[index] is NonterminalGrammarSymbol) index,
  ];
  if (nonterminalPositions.isEmpty) return const <ProductionApplication>[];
  final requiredPosition = effectiveMode == UserDerivationMode.leftmost
      ? nonterminalPositions.first
      : nonterminalPositions.last;
  return List<ProductionApplication>.unmodifiable(
    applications.where(
      (application) => application.occurrence.startIndex == requiredPosition,
    ),
  );
}

ProductionApplication? _findApplication(
  Iterable<ProductionApplication> applications,
  String productionId,
  int startIndex,
) {
  for (final application in applications) {
    if (application.production.id == productionId &&
        application.occurrence.startIndex == startIndex) {
      return application;
    }
  }
  return null;
}

bool _isTerminalOnly(
  GrammarSymbolSequence form,
  PhraseStructureGrammar grammar,
) => form.symbols.every(
  (symbol) =>
      symbol is TerminalGrammarSymbol && grammar.terminals.contains(symbol),
);

bool _historyMatchesGrammar(
  UserDerivationSession session,
  PhraseStructureGrammar grammar,
) {
  var form = session.initialForm;
  for (final step in session.steps) {
    if (step.before != form) return false;
    final matches = PhraseProductionApplicator.allApplications(
      form,
      grammar.phraseProductions,
    );
    final match = _findApplication(matches, step.productionId, step.startIndex);
    if (match == null ||
        match.occurrence.occurrenceIndex != step.occurrenceIndex ||
        match.after != step.after) {
      return false;
    }
    form = step.after;
  }
  return true;
}

class _MutableDerivationNode {
  _MutableDerivationNode(this.symbol);

  final PhraseGrammarSymbol symbol;
  List<_MutableDerivationNode> children = const [];
}
