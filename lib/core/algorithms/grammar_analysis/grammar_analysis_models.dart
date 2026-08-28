part of '../grammar_analyzer.dart';

class GrammarAnalysisReport<T> {
  final T value;
  final List<String> notes;
  final List<StructuredMessage> structuredNotes;
  final List<String> derivations;
  final List<StructuredMessage> structuredDerivations;
  final List<String> conflicts;
  final List<StructuredMessage> structuredConflicts;
  final List<GrammarTransformationStep> steps;
  final List<GrammarAnalysisStructuredTransformationStep> structuredSteps;

  const GrammarAnalysisReport({
    required this.value,
    this.notes = const [],
    this.structuredNotes = const [],
    this.derivations = const [],
    this.structuredDerivations = const [],
    this.conflicts = const [],
    this.structuredConflicts = const [],
    this.steps = const [],
    this.structuredSteps = const [],
  });
}

class LL1ParseTable {
  final Map<String, Map<String, List<List<String>>>> table;
  final Set<String> terminals;
  final Map<String, Map<String, List<LL1ParseTableEntry>>> entryTable;
  final List<LL1ParseTableConflict> typedConflicts;

  LL1ParseTable({
    required Map<String, Map<String, List<List<String>>>> table,
    required Set<String> terminals,
    Map<String, Map<String, List<LL1ParseTableEntry>>> entryTable = const {},
    List<LL1ParseTableConflict> typedConflicts = const [],
  }) : table = Map<String, Map<String, List<List<String>>>>.unmodifiable(
         table.map(
           (nonTerminal, row) => MapEntry(
             nonTerminal,
             Map<String, List<List<String>>>.unmodifiable(
               row.map(
                 (lookahead, entries) => MapEntry(
                   lookahead,
                   List<List<String>>.unmodifiable(
                     entries.map(List<String>.unmodifiable),
                   ),
                 ),
               ),
             ),
           ),
         ),
       ),
       terminals = Set<String>.unmodifiable(terminals),
       entryTable =
           Map<String, Map<String, List<LL1ParseTableEntry>>>.unmodifiable(
             entryTable.map(
               (nonTerminal, row) => MapEntry(
                 nonTerminal,
                 Map<String, List<LL1ParseTableEntry>>.unmodifiable(
                   row.map(
                     (lookahead, entries) => MapEntry(
                       lookahead,
                       List<LL1ParseTableEntry>.unmodifiable(entries),
                     ),
                   ),
                 ),
               ),
             ),
           ),
       typedConflicts = List<LL1ParseTableConflict>.unmodifiable(
         typedConflicts,
       );

  Set<String> get nonTerminals => table.keys.toSet();

  List<LL1ParseTableEntry> entriesAt(String nonTerminal, String terminal) =>
      entryTable[nonTerminal]?[terminal] ?? const <LL1ParseTableEntry>[];
}

/// Why a production was placed in an LL(1) table cell.
enum LL1TablePlacement { first, follow }

/// A production entry with stable identity and construction provenance.
class LL1ParseTableEntry {
  LL1ParseTableEntry({
    required this.productionId,
    required this.leftSide,
    required List<String> rightSide,
    required Set<LL1TablePlacement> placements,
    this.productionOrder = 0,
  }) : rightSide = List<String>.unmodifiable(rightSide),
       placements = Set<LL1TablePlacement>.unmodifiable(placements);

  final String productionId;
  final String leftSide;
  final List<String> rightSide;
  final Set<LL1TablePlacement> placements;
  final int productionOrder;

  String get display =>
      '$leftSide → ${rightSide.isEmpty ? 'ε' : rightSide.join(' ')}';
}

enum LL1ConflictKind { firstFirst, firstFollow }

/// A typed LL(1) conflict tied to its table cell and source productions.
class LL1ParseTableConflict {
  LL1ParseTableConflict({
    required this.nonTerminal,
    required this.lookahead,
    required this.kind,
    required List<LL1ParseTableEntry> entries,
  }) : entries = List<LL1ParseTableEntry>.unmodifiable(entries);

  final String nonTerminal;
  final String lookahead;
  final LL1ConflictKind kind;
  final List<LL1ParseTableEntry> entries;

  String get alternativesDisplay => entries
      .map((entry) => '${entry.productionId} ${entry.display}')
      .join(' | ');

  String get formalKind => switch (kind) {
    LL1ConflictKind.firstFirst => 'FIRST/FIRST',
    LL1ConflictKind.firstFollow => 'FIRST/FOLLOW',
  };

  String get formalDescription =>
      '$formalKind [$nonTerminal, $lookahead]: $alternativesDisplay';

  StructuredMessage get descriptionMessage => StructuredMessage(
    namespace: 'grammar.ll1-conflict',
    code: 'detected',
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'kind': StructuredMessageArgument.outcome(switch (kind) {
        LL1ConflictKind.firstFirst => 'first-first',
        LL1ConflictKind.firstFollow => 'first-follow',
      }, role: 'll1-conflict-kind'),
      'non-terminal': StructuredMessageArgument.symbol(
        nonTerminal,
        role: 'grammar-nonterminal',
      ),
      'lookahead': StructuredMessageArgument.symbol(
        lookahead,
        role: 'grammar-lookahead',
      ),
      'alternatives': StructuredMessageArgument.literal(
        alternativesDisplay,
        role: 'grammar-productions',
      ),
    },
  );
}

enum GrammarAmbiguityEvidence { ll1ConflictHeuristic }

enum GrammarAmbiguityLimitation { ll1ConflictsDoNotDecideAmbiguity }

/// Explicitly incomplete ambiguity assessment used by the focused analyzer.
class GrammarAmbiguityAssessment {
  const GrammarAmbiguityAssessment({
    required this.appearsLl1,
    required this.evidence,
    required this.isComplete,
    required this.limitation,
    required this.conflicts,
  });

  final bool appearsLl1;
  final GrammarAmbiguityEvidence evidence;
  final bool isComplete;
  final GrammarAmbiguityLimitation limitation;
  final List<String> conflicts;
}
