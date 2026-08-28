import '../../algorithms/grammar_analyzer.dart';
import '../../algorithms/grammar_cnf_transformer.dart';
import '../../educational_content/educational_content_reference.dart';
import '../../models/grammar.dart';
import '../../models/lr1_models.dart';
import '../phrase_structure/legacy_context_free_grammar_adapter.dart';
import 'grammar_teaching_content.dart';

enum NormalizationTeachingStage { lambda, unit, useless, cnf }

enum NormalizationTeachingDiagnosticCode {
  validEquivalent,
  duplicate,
  invalidSymbol,
  invalidSyntax,
  outOfOrder,
  missingProduction,
  unexpectedProduction,
  sourceChanged,
  invalidPayload,
}

class NormalizationTeachingDiagnostic {
  const NormalizationTeachingDiagnostic({
    required this.code,
    this.line,
    this.detail,
    this.stage,
  });

  final NormalizationTeachingDiagnosticCode code;
  final int? line;
  final String? detail;
  final NormalizationTeachingStage? stage;

  Map<String, Object?> toJson() => {
    'code': code.name,
    'line': line,
    'detail': detail,
    'stage': stage?.name,
  };

  static NormalizationTeachingDiagnostic fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'normalization diagnostic');
    return NormalizationTeachingDiagnostic(
      code: NormalizationTeachingDiagnosticCode.values.byName(
        _string(map, 'code'),
      ),
      line: _nullableInt(map, 'line'),
      detail: _nullableString(map, 'detail'),
      stage: map['stage'] == null
          ? null
          : NormalizationTeachingStage.values.byName(_string(map, 'stage')),
    );
  }
}

class NormalizationTeachingState {
  NormalizationTeachingState({
    required this.selectedStage,
    required Map<NormalizationTeachingStage, String> drafts,
    required Map<
      NormalizationTeachingStage,
      List<NormalizationTeachingDiagnostic>
    >
    diagnostics,
    required Set<NormalizationTeachingStage> completedStages,
  }) : drafts = Map<NormalizationTeachingStage, String>.unmodifiable(drafts),
       diagnostics =
           Map<
             NormalizationTeachingStage,
             List<NormalizationTeachingDiagnostic>
           >.unmodifiable(
             diagnostics.map(
               (stage, values) => MapEntry(
                 stage,
                 List<NormalizationTeachingDiagnostic>.unmodifiable(values),
               ),
             ),
           ),
       completedStages = Set.unmodifiable(completedStages);

  final NormalizationTeachingStage selectedStage;
  final Map<NormalizationTeachingStage, String> drafts;
  final Map<NormalizationTeachingStage, List<NormalizationTeachingDiagnostic>>
  diagnostics;
  final Set<NormalizationTeachingStage> completedStages;

  Map<String, Object?> toJson() => {
    'selectedStage': selectedStage.name,
    'drafts': {for (final entry in drafts.entries) entry.key.name: entry.value},
    'diagnostics': {
      for (final entry in diagnostics.entries)
        entry.key.name: entry.value.map((item) => item.toJson()).toList(),
    },
    'completedStages': completedStages.map((stage) => stage.name).toList(),
  };

  static NormalizationTeachingState fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'normalization state');
    final rawDrafts = _objectMap(map['drafts'], 'normalization drafts');
    final rawDiagnostics = _objectMap(
      map['diagnostics'],
      'normalization diagnostics',
    );
    final rawCompleted = _list(map, 'completedStages');
    return NormalizationTeachingState(
      selectedStage: NormalizationTeachingStage.values.byName(
        _string(map, 'selectedStage'),
      ),
      drafts: {
        for (final stage in NormalizationTeachingStage.values)
          stage: _string(rawDrafts, stage.name),
      },
      diagnostics: {
        for (final stage in NormalizationTeachingStage.values)
          stage: (rawDiagnostics[stage.name] as List? ?? const [])
              .map(NormalizationTeachingDiagnostic.fromJson)
              .toList(),
      },
      completedStages: rawCompleted
          .map(
            (value) =>
                NormalizationTeachingStage.values.byName(value as String),
          )
          .toSet(),
    );
  }
}

class NormalizationTeachingRestoreResult {
  const NormalizationTeachingRestoreResult({
    this.session,
    this.diagnostics = const [],
  });

  final NormalizationTeachingSession? session;
  final List<NormalizationTeachingDiagnostic> diagnostics;
  bool get isSuccess => session != null && diagnostics.isEmpty;
}

class NormalizationTeachingSession {
  NormalizationTeachingSession._({
    required this.sourceGrammarId,
    required this.sourceRevision,
    required Map<NormalizationTeachingStage, Grammar> references,
    required List<NormalizationTeachingState> history,
    required this.cursor,
  }) : _references = Map.unmodifiable(references),
       history = List.unmodifiable(history);

  static const schemaId = 'turing-lab.grammar-normalization-teaching';
  static const schemaVersion = 1;
  static final contentReferences =
      List<EducationalContentReference>.unmodifiable([
        GrammarTeachingContent.normalizationLambda,
        GrammarTeachingContent.normalizationUnit,
        GrammarTeachingContent.normalizationUseless,
        GrammarTeachingContent.normalizationCnf,
      ]);

  final String sourceGrammarId;
  final int sourceRevision;
  final Map<NormalizationTeachingStage, Grammar> _references;
  final List<NormalizationTeachingState> history;
  final int cursor;

  NormalizationTeachingState get currentState => history[cursor];
  bool get canUndo => cursor > 0;
  bool get canRedo => cursor < history.length - 1;
  List<NormalizationTeachingDiagnostic> get currentDiagnostics =>
      currentState.diagnostics[currentState.selectedStage] ?? const [];

  Grammar referenceFor(NormalizationTeachingStage stage) => _references[stage]!;

  static NormalizationTeachingSession start(Grammar grammar) {
    final references = _buildReferences(grammar);
    final inputs = <NormalizationTeachingStage, Grammar>{
      NormalizationTeachingStage.lambda: grammar,
      NormalizationTeachingStage.unit:
          references[NormalizationTeachingStage.lambda]!,
      NormalizationTeachingStage.useless:
          references[NormalizationTeachingStage.unit]!,
      NormalizationTeachingStage.cnf:
          references[NormalizationTeachingStage.useless]!,
    };
    final state = NormalizationTeachingState(
      selectedStage: NormalizationTeachingStage.lambda,
      drafts: {
        for (final stage in NormalizationTeachingStage.values)
          stage: _draftFor(inputs[stage]!),
      },
      diagnostics: {
        for (final stage in NormalizationTeachingStage.values)
          stage: const <NormalizationTeachingDiagnostic>[],
      },
      completedStages: const {},
    );
    return NormalizationTeachingSession._(
      sourceGrammarId: grammar.id,
      sourceRevision: LegacyContextFreeGrammarAdapter.sourceRevision(grammar),
      references: references,
      history: [state],
      cursor: 0,
    );
  }

  NormalizationTeachingSession selectStage(NormalizationTeachingStage stage) {
    if (stage == currentState.selectedStage) return this;
    return _record(_copyState(selectedStage: stage));
  }

  NormalizationTeachingSession updateDraft(String draft) {
    final stage = currentState.selectedStage;
    if (currentState.drafts[stage] == draft) return this;
    final drafts = {...currentState.drafts, stage: draft};
    final diagnostics = {
      ...currentState.diagnostics,
      stage: const <NormalizationTeachingDiagnostic>[],
    };
    final completed = {...currentState.completedStages}..remove(stage);
    return _record(
      _copyState(
        drafts: drafts,
        diagnostics: diagnostics,
        completedStages: completed,
      ),
    );
  }

  NormalizationTeachingSession validateCurrent() {
    final stage = currentState.selectedStage;
    final validation = _validate(
      stage: stage,
      draft: currentState.drafts[stage]!,
      references: _references,
      sourceSymbols: {
        ..._references.values.expand((grammar) => grammar.terminals),
        ..._references.values.expand((grammar) => grammar.nonterminals),
      },
    );
    final diagnostics = {...currentState.diagnostics, stage: validation};
    final completed = {...currentState.completedStages};
    if (validation.length == 1 &&
        validation.single.code ==
            NormalizationTeachingDiagnosticCode.validEquivalent) {
      completed.add(stage);
    } else {
      completed.remove(stage);
    }
    return _record(
      _copyState(diagnostics: diagnostics, completedStages: completed),
    );
  }

  NormalizationTeachingSession undo() => canUndo
      ? NormalizationTeachingSession._(
          sourceGrammarId: sourceGrammarId,
          sourceRevision: sourceRevision,
          references: _references,
          history: history,
          cursor: cursor - 1,
        )
      : this;

  NormalizationTeachingSession redo() => canRedo
      ? NormalizationTeachingSession._(
          sourceGrammarId: sourceGrammarId,
          sourceRevision: sourceRevision,
          references: _references,
          history: history,
          cursor: cursor + 1,
        )
      : this;

  Map<String, Object?> toJson() => {
    'schema': {'id': schemaId, 'version': schemaVersion},
    'content': contentReferences
        .map((reference) => reference.toJson())
        .toList(growable: false),
    'sourceGrammarId': sourceGrammarId,
    'sourceRevision': sourceRevision,
    'history': history.map((state) => state.toJson()).toList(),
    'cursor': cursor,
  };

  static NormalizationTeachingRestoreResult restore(
    Object? encoded, {
    required Grammar grammar,
  }) {
    try {
      final map = _objectMap(encoded, 'normalization session');
      _checkSchema(map, schemaId, schemaVersion);
      _checkContentReferences(map['content'], contentReferences);
      final revision = LegacyContextFreeGrammarAdapter.sourceRevision(grammar);
      if (_string(map, 'sourceGrammarId') != grammar.id ||
          _int(map, 'sourceRevision') != revision) {
        return const NormalizationTeachingRestoreResult(
          diagnostics: [
            NormalizationTeachingDiagnostic(
              code: NormalizationTeachingDiagnosticCode.sourceChanged,
            ),
          ],
        );
      }
      final history = _list(
        map,
        'history',
      ).map(NormalizationTeachingState.fromJson).toList();
      final cursor = _int(map, 'cursor');
      if (history.isEmpty || cursor < 0 || cursor >= history.length) {
        throw const FormatException('Invalid normalization history cursor.');
      }
      return NormalizationTeachingRestoreResult(
        session: NormalizationTeachingSession._(
          sourceGrammarId: grammar.id,
          sourceRevision: revision,
          references: _buildReferences(grammar),
          history: history,
          cursor: cursor,
        ),
      );
    } on Object {
      return const NormalizationTeachingRestoreResult(
        diagnostics: [
          NormalizationTeachingDiagnostic(
            code: NormalizationTeachingDiagnosticCode.invalidPayload,
          ),
        ],
      );
    }
  }

  NormalizationTeachingState _copyState({
    NormalizationTeachingStage? selectedStage,
    Map<NormalizationTeachingStage, String>? drafts,
    Map<NormalizationTeachingStage, List<NormalizationTeachingDiagnostic>>?
    diagnostics,
    Set<NormalizationTeachingStage>? completedStages,
  }) => NormalizationTeachingState(
    selectedStage: selectedStage ?? currentState.selectedStage,
    drafts: drafts ?? currentState.drafts,
    diagnostics: diagnostics ?? currentState.diagnostics,
    completedStages: completedStages ?? currentState.completedStages,
  );

  NormalizationTeachingSession _record(NormalizationTeachingState state) {
    final nextHistory = [...history.take(cursor + 1), state];
    return NormalizationTeachingSession._(
      sourceGrammarId: sourceGrammarId,
      sourceRevision: sourceRevision,
      references: _references,
      history: nextHistory,
      cursor: nextHistory.length - 1,
    );
  }
}

enum ParseTableTeachingKind { ll1, lr1 }

enum ParseTableTeachingDiagnosticCode {
  validEquivalent,
  validConflictChoice,
  validEmpty,
  incorrectEntry,
  sourceChanged,
  invalidPayload,
}

abstract final class ParseTableTeachingCellKey {
  static String ll(String nonTerminal, String lookahead) =>
      'll:$nonTerminal:$lookahead';
  static String lrAction(int state, String lookahead) =>
      'lr:action:$state:$lookahead';
  static String lrGoto(int state, String nonTerminal) =>
      'lr:goto:$state:$nonTerminal';
}

class ParseTableTeachingAlternative {
  const ParseTableTeachingAlternative({
    required this.id,
    required this.display,
  });

  final String id;
  final String display;
}

class ParseTableTeachingCellReference {
  ParseTableTeachingCellReference({
    required this.key,
    required this.row,
    required this.column,
    required this.section,
    required List<ParseTableTeachingAlternative> alternatives,
  }) : alternatives = List.unmodifiable(alternatives);

  final String key;
  final String row;
  final String column;
  final String section;
  final List<ParseTableTeachingAlternative> alternatives;
  bool get hasConflict => alternatives.length > 1;
}

class ParseTableTeachingDiagnostic {
  const ParseTableTeachingDiagnostic({required this.code, this.detail});

  final ParseTableTeachingDiagnosticCode code;
  final String? detail;
}

class ParseTableTeachingState {
  ParseTableTeachingState({required Map<String, String> drafts})
    : drafts = Map.unmodifiable(drafts);

  final Map<String, String> drafts;

  Map<String, Object?> toJson() => {'drafts': drafts};

  static ParseTableTeachingState fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'parse-table teaching state');
    final drafts = _objectMap(map['drafts'], 'parse-table drafts');
    return ParseTableTeachingState(
      drafts: drafts.map((key, value) => MapEntry(key, value as String)),
    );
  }
}

class ParseTableTeachingRestoreResult {
  const ParseTableTeachingRestoreResult({this.session, this.diagnostic});

  final ParseTableTeachingSession? session;
  final ParseTableTeachingDiagnostic? diagnostic;
  bool get isSuccess => session != null && diagnostic == null;
}

class ParseTableTeachingSession {
  ParseTableTeachingSession._({
    required this.kind,
    required this.sourceGrammarId,
    required this.sourceRevision,
    required Map<String, ParseTableTeachingCellReference> references,
    required List<ParseTableTeachingState> history,
    required this.cursor,
  }) : references = Map.unmodifiable(references),
       history = List.unmodifiable(history);

  static const schemaId = 'turing-lab.parse-table-teaching';
  static const schemaVersion = 1;

  final ParseTableTeachingKind kind;
  final String sourceGrammarId;
  final int sourceRevision;
  final Map<String, ParseTableTeachingCellReference> references;
  final List<ParseTableTeachingState> history;
  final int cursor;

  EducationalContentReference get contentReference => switch (kind) {
    ParseTableTeachingKind.ll1 => GrammarTeachingContent.parseTableLl1,
    ParseTableTeachingKind.lr1 => GrammarTeachingContent.parseTableLr1,
  };

  ParseTableTeachingState get currentState => history[cursor];
  bool get canUndo => cursor > 0;
  bool get canRedo => cursor < history.length - 1;
  String draftFor(String key) => currentState.drafts[key] ?? '';

  factory ParseTableTeachingSession.fromLl1(
    Grammar grammar,
    LL1ParseTable table,
  ) => ParseTableTeachingSession._start(
    kind: ParseTableTeachingKind.ll1,
    grammar: grammar,
    references: _llReferences(table),
  );

  factory ParseTableTeachingSession.fromLr1(
    Grammar grammar,
    LR1Construction construction,
  ) => ParseTableTeachingSession._start(
    kind: ParseTableTeachingKind.lr1,
    grammar: grammar,
    references: _lrReferences(construction),
  );

  factory ParseTableTeachingSession._start({
    required ParseTableTeachingKind kind,
    required Grammar grammar,
    required Map<String, ParseTableTeachingCellReference> references,
  }) {
    return ParseTableTeachingSession._(
      kind: kind,
      sourceGrammarId: grammar.id,
      sourceRevision: LegacyContextFreeGrammarAdapter.sourceRevision(grammar),
      references: references,
      history: [
        ParseTableTeachingState(
          drafts: {for (final key in references.keys) key: ''},
        ),
      ],
      cursor: 0,
    );
  }

  ParseTableTeachingSession editCell(String key, String value) {
    if (!references.containsKey(key)) return this;
    return _record(
      ParseTableTeachingState(drafts: {...currentState.drafts, key: value}),
    );
  }

  ParseTableTeachingSession chooseAlternative(String key, String id) {
    final reference = references[key];
    if (reference == null ||
        !reference.alternatives.any((alternative) => alternative.id == id)) {
      return this;
    }
    return editCell(key, id);
  }

  ParseTableTeachingDiagnostic validationFor(String key) {
    final reference = references[key];
    if (reference == null) {
      return const ParseTableTeachingDiagnostic(
        code: ParseTableTeachingDiagnosticCode.incorrectEntry,
      );
    }
    final draft = draftFor(key).trim();
    if (reference.alternatives.isEmpty && draft.isEmpty) {
      return const ParseTableTeachingDiagnostic(
        code: ParseTableTeachingDiagnosticCode.validEmpty,
      );
    }
    final matches = reference.alternatives.any(
      (alternative) => draft == alternative.id || draft == alternative.display,
    );
    if (!matches) {
      return const ParseTableTeachingDiagnostic(
        code: ParseTableTeachingDiagnosticCode.incorrectEntry,
      );
    }
    return ParseTableTeachingDiagnostic(
      code: reference.hasConflict
          ? ParseTableTeachingDiagnosticCode.validConflictChoice
          : ParseTableTeachingDiagnosticCode.validEquivalent,
    );
  }

  ParseTableTeachingSession undo() => canUndo
      ? ParseTableTeachingSession._(
          kind: kind,
          sourceGrammarId: sourceGrammarId,
          sourceRevision: sourceRevision,
          references: references,
          history: history,
          cursor: cursor - 1,
        )
      : this;

  ParseTableTeachingSession redo() => canRedo
      ? ParseTableTeachingSession._(
          kind: kind,
          sourceGrammarId: sourceGrammarId,
          sourceRevision: sourceRevision,
          references: references,
          history: history,
          cursor: cursor + 1,
        )
      : this;

  Map<String, Object?> toJson() => {
    'schema': {'id': schemaId, 'version': schemaVersion},
    'content': contentReference.toJson(),
    'kind': kind.name,
    'sourceGrammarId': sourceGrammarId,
    'sourceRevision': sourceRevision,
    'history': history.map((state) => state.toJson()).toList(),
    'cursor': cursor,
  };

  static ParseTableTeachingRestoreResult restoreLl1(
    Object? encoded, {
    required Grammar grammar,
    required LL1ParseTable table,
  }) => _restore(
    encoded,
    kind: ParseTableTeachingKind.ll1,
    grammar: grammar,
    references: _llReferences(table),
  );

  static ParseTableTeachingRestoreResult restoreLr1(
    Object? encoded, {
    required Grammar grammar,
    required LR1Construction construction,
  }) => _restore(
    encoded,
    kind: ParseTableTeachingKind.lr1,
    grammar: grammar,
    references: _lrReferences(construction),
  );

  static ParseTableTeachingRestoreResult _restore(
    Object? encoded, {
    required ParseTableTeachingKind kind,
    required Grammar grammar,
    required Map<String, ParseTableTeachingCellReference> references,
  }) {
    try {
      final map = _objectMap(encoded, 'parse-table teaching session');
      _checkSchema(map, schemaId, schemaVersion);
      _checkContentReference(
        map['content'],
        kind == ParseTableTeachingKind.ll1
            ? GrammarTeachingContent.parseTableLl1
            : GrammarTeachingContent.parseTableLr1,
      );
      final revision = LegacyContextFreeGrammarAdapter.sourceRevision(grammar);
      if (_string(map, 'kind') != kind.name ||
          _string(map, 'sourceGrammarId') != grammar.id ||
          _int(map, 'sourceRevision') != revision) {
        return const ParseTableTeachingRestoreResult(
          diagnostic: ParseTableTeachingDiagnostic(
            code: ParseTableTeachingDiagnosticCode.sourceChanged,
          ),
        );
      }
      final history = _list(
        map,
        'history',
      ).map(ParseTableTeachingState.fromJson).toList();
      final cursor = _int(map, 'cursor');
      if (history.isEmpty || cursor < 0 || cursor >= history.length) {
        throw const FormatException('Invalid parse-table history cursor.');
      }
      for (final state in history) {
        if (state.drafts.keys.any((key) => !references.containsKey(key))) {
          throw const FormatException('Unknown parse-table cell.');
        }
      }
      return ParseTableTeachingRestoreResult(
        session: ParseTableTeachingSession._(
          kind: kind,
          sourceGrammarId: grammar.id,
          sourceRevision: revision,
          references: references,
          history: history,
          cursor: cursor,
        ),
      );
    } on Object {
      return const ParseTableTeachingRestoreResult(
        diagnostic: ParseTableTeachingDiagnostic(
          code: ParseTableTeachingDiagnosticCode.invalidPayload,
        ),
      );
    }
  }

  ParseTableTeachingSession _record(ParseTableTeachingState state) {
    final nextHistory = [...history.take(cursor + 1), state];
    return ParseTableTeachingSession._(
      kind: kind,
      sourceGrammarId: sourceGrammarId,
      sourceRevision: sourceRevision,
      references: references,
      history: nextHistory,
      cursor: nextHistory.length - 1,
    );
  }
}

Map<NormalizationTeachingStage, Grammar> _buildReferences(Grammar grammar) {
  final result = GrammarCnfTransformer.toCnf(grammar);
  if (!result.isSuccess || result.data == null) {
    throw StateError(result.error ?? 'Unable to build CNF teaching stages.');
  }
  final report = result.data!;
  Grammar after(String id, Grammar fallback) {
    for (final step in report.steps) {
      if (step.id == id) return step.after;
    }
    return fallback;
  }

  final start = after('cnf.start_symbol', grammar);
  final lambda = after('cnf.epsilon', start);
  final unit = after('cnf.unit', lambda);
  final useless = after('cnf.useless', unit);
  Grammar stable(Grammar value) =>
      value.copyWith(created: grammar.created, modified: grammar.modified);
  return {
    NormalizationTeachingStage.lambda: stable(lambda),
    NormalizationTeachingStage.unit: stable(unit),
    NormalizationTeachingStage.useless: stable(useless),
    NormalizationTeachingStage.cnf: stable(report.grammar),
  };
}

List<NormalizationTeachingDiagnostic> _validate({
  required NormalizationTeachingStage stage,
  required String draft,
  required Map<NormalizationTeachingStage, Grammar> references,
  required Set<String> sourceSymbols,
}) {
  final parsed = _parseDraft(draft);
  if (parsed.diagnostics.isNotEmpty) return parsed.diagnostics;
  final diagnostics = <NormalizationTeachingDiagnostic>[];
  for (final entry in parsed.shapes.entries) {
    for (final symbol in [entry.value.left, ...entry.value.right]) {
      if (!sourceSymbols.contains(symbol)) {
        diagnostics.add(
          NormalizationTeachingDiagnostic(
            code: NormalizationTeachingDiagnosticCode.invalidSymbol,
            line: entry.key,
            detail: symbol,
          ),
        );
      }
    }
  }
  if (diagnostics.isNotEmpty) return diagnostics;

  final actual = parsed.shapes.values.toSet();
  final expected = _shapes(references[stage]!);
  if (_setEquals(actual, expected) && parsed.duplicates.isEmpty) {
    return const [
      NormalizationTeachingDiagnostic(
        code: NormalizationTeachingDiagnosticCode.validEquivalent,
      ),
    ];
  }
  final currentIndex = NormalizationTeachingStage.values.indexOf(stage);
  for (
    var index = currentIndex + 1;
    index < NormalizationTeachingStage.values.length;
    index++
  ) {
    final later = NormalizationTeachingStage.values[index];
    if (_setEquals(actual, _shapes(references[later]!))) {
      return [
        NormalizationTeachingDiagnostic(
          code: NormalizationTeachingDiagnosticCode.outOfOrder,
          stage: later,
        ),
      ];
    }
  }
  for (final duplicate in parsed.duplicates) {
    diagnostics.add(
      NormalizationTeachingDiagnostic(
        code: NormalizationTeachingDiagnosticCode.duplicate,
        line: duplicate,
      ),
    );
  }
  if (diagnostics.isNotEmpty) return diagnostics;
  for (final missing in expected.difference(actual)) {
    diagnostics.add(
      NormalizationTeachingDiagnostic(
        code: NormalizationTeachingDiagnosticCode.missingProduction,
        detail: missing.display,
      ),
    );
  }
  for (final unexpected in actual.difference(expected)) {
    diagnostics.add(
      NormalizationTeachingDiagnostic(
        code: NormalizationTeachingDiagnosticCode.unexpectedProduction,
        detail: unexpected.display,
      ),
    );
  }
  return diagnostics;
}

({
  Map<int, _ProductionShape> shapes,
  List<int> duplicates,
  List<NormalizationTeachingDiagnostic> diagnostics,
})
_parseDraft(String draft) {
  final shapes = <int, _ProductionShape>{};
  final seen = <_ProductionShape>{};
  final duplicates = <int>[];
  final diagnostics = <NormalizationTeachingDiagnostic>[];
  final lines = draft.split('\n');
  for (var index = 0; index < lines.length; index++) {
    final raw = lines[index].trim();
    if (raw.isEmpty) continue;
    final arrow = raw.contains('→') ? '→' : '->';
    final parts = raw.split(arrow);
    if (parts.length != 2 ||
        parts.first.trim().split(RegExp(r'\s+')).length != 1) {
      diagnostics.add(
        NormalizationTeachingDiagnostic(
          code: NormalizationTeachingDiagnosticCode.invalidSyntax,
          line: index + 1,
        ),
      );
      continue;
    }
    final left = parts.first.trim();
    final rhs = parts.last.trim();
    final right = rhs.isEmpty || _isEpsilon(rhs)
        ? const <String>[]
        : rhs.split(RegExp(r'\s+'));
    final shape = _ProductionShape(left, right);
    if (!seen.add(shape)) duplicates.add(index + 1);
    shapes[index + 1] = shape;
  }
  return (shapes: shapes, duplicates: duplicates, diagnostics: diagnostics);
}

Set<_ProductionShape> _shapes(Grammar grammar) => grammar.productions
    .map(
      (production) => _ProductionShape(
        production.leftSide.single,
        production.isLambda ? const [] : production.rightSide,
      ),
    )
    .toSet();

String _draftFor(Grammar grammar) {
  final productions = grammar.productions.toList()
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  return productions
      .map((production) {
        final right = production.isLambda || production.rightSide.isEmpty
            ? 'ε'
            : production.rightSide.join(' ');
        return '${production.leftSide.single} -> $right';
      })
      .join('\n');
}

class _ProductionShape {
  _ProductionShape(this.left, List<String> right)
    : right = List.unmodifiable(right);

  final String left;
  final List<String> right;
  String get display => '$left → ${right.isEmpty ? 'ε' : right.join(' ')}';

  @override
  bool operator ==(Object other) =>
      other is _ProductionShape &&
      other.left == left &&
      _listEquals(other.right, right);

  @override
  int get hashCode => Object.hash(left, Object.hashAll(right));
}

Map<String, ParseTableTeachingCellReference> _llReferences(
  LL1ParseTable table,
) {
  final references = <String, ParseTableTeachingCellReference>{};
  for (final nonTerminal in table.nonTerminals) {
    for (final terminal in table.terminals) {
      final key = ParseTableTeachingCellKey.ll(nonTerminal, terminal);
      references[key] = ParseTableTeachingCellReference(
        key: key,
        row: nonTerminal,
        column: terminal,
        section: 'LL(1)',
        alternatives: [
          for (final entry in table.entriesAt(nonTerminal, terminal))
            ParseTableTeachingAlternative(
              id: entry.productionId,
              display: '${entry.productionId}: ${entry.display}',
            ),
        ],
      );
    }
  }
  return references;
}

Map<String, ParseTableTeachingCellReference> _lrReferences(
  LR1Construction construction,
) {
  final references = <String, ParseTableTeachingCellReference>{};
  for (final state in construction.states) {
    for (final terminal in construction.table.terminals) {
      final key = ParseTableTeachingCellKey.lrAction(state.index, terminal);
      references[key] = ParseTableTeachingCellReference(
        key: key,
        row: state.id,
        column: terminal,
        section: 'ACTION',
        alternatives: [
          for (final action in construction.table.actionsAt(
            state.index,
            terminal,
          ))
            ParseTableTeachingAlternative(
              id: action.stableKey,
              display: action.display,
            ),
        ],
      );
    }
    for (final nonTerminal in construction.table.nonTerminals) {
      final key = ParseTableTeachingCellKey.lrGoto(state.index, nonTerminal);
      final target = construction.table.gotoAt(state.index, nonTerminal);
      references[key] = ParseTableTeachingCellReference(
        key: key,
        row: state.id,
        column: nonTerminal,
        section: 'GOTO',
        alternatives: target == null
            ? const []
            : [
                ParseTableTeachingAlternative(
                  id: target.toString(),
                  display: target.toString(),
                ),
              ],
      );
    }
  }
  return references;
}

bool _isEpsilon(String value) {
  final normalized = value.toLowerCase();
  return value == 'ε' || value == 'λ' || normalized == 'lambda';
}

bool _setEquals<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Map<String, Object?> _objectMap(Object? value, String label) {
  if (value is! Map) throw FormatException('$label must be an object.');
  return Map<String, Object?>.from(value);
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String) throw FormatException('$key must be a string.');
  return value;
}

String? _nullableString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value != null && value is! String) {
    throw FormatException('$key must be a string or null.');
  }
  return value as String?;
}

int _int(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

int? _nullableInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value != null && value is! int) {
    throw FormatException('$key must be an integer or null.');
  }
  return value as int?;
}

List<Object?> _list(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! List) throw FormatException('$key must be a list.');
  return value;
}

void _checkSchema(Map<String, Object?> map, String id, int version) {
  final schema = _objectMap(map['schema'], 'schema');
  if (schema['id'] != id || schema['version'] != version) {
    throw const FormatException('Unsupported teaching-session schema.');
  }
}

void _checkContentReference(
  Object? encoded,
  EducationalContentReference expected,
) {
  if (encoded == null) return;
  final actual = EducationalContentReference.fromJson(encoded);
  if (actual != expected) {
    throw const EducationalContentReferenceException(
      EducationalContentReferenceErrorCode.unsupportedContent,
    );
  }
}

void _checkContentReferences(
  Object? encoded,
  List<EducationalContentReference> expected,
) {
  if (encoded == null) return;
  if (encoded is! List || encoded.length != expected.length) {
    throw const EducationalContentReferenceException(
      EducationalContentReferenceErrorCode.invalidContentSet,
    );
  }
  for (var index = 0; index < expected.length; index++) {
    _checkContentReference(encoded[index], expected[index]);
  }
}
