import 'derivation_tree.dart';
import 'derivation_tree_node.dart';
import 'grammar.dart';
import 'production.dart';
import '../messages/structured_message.dart';

enum LR1ConstructionOutcome {
  completed,
  invalidGrammar,
  cancelled,
  stateLimit,
  itemLimit,
  timeLimit,
}

class LR1ConstructionResult {
  const LR1ConstructionResult({
    required this.outcome,
    this.construction,
    this.message,
    this.structuredMessage,
  });

  final LR1ConstructionOutcome outcome;
  final LR1Construction? construction;
  final String? message;
  final StructuredMessage? structuredMessage;

  bool get isCompleted => outcome == LR1ConstructionOutcome.completed;
}

class LR1Item {
  LR1Item({
    required this.productionId,
    required this.leftSide,
    required List<String> rightSide,
    required this.dotPosition,
    required this.lookahead,
    required this.productionOrder,
    this.isAugmented = false,
  }) : rightSide = List<String>.unmodifiable(rightSide);

  final String productionId;
  final String leftSide;
  final List<String> rightSide;
  final int dotPosition;
  final String lookahead;
  final int productionOrder;
  final bool isAugmented;

  String? get symbolAfterDot =>
      dotPosition < rightSide.length ? rightSide[dotPosition] : null;

  bool get isComplete => dotPosition == rightSide.length;

  String get stableKey =>
      '$productionId\u0000$productionOrder\u0000$dotPosition\u0000$lookahead';

  String get display {
    final symbols = <String>[...rightSide];
    symbols.insert(dotPosition, '·');
    return '[$leftSide → ${symbols.join(' ')}, $lookahead]';
  }

  LR1Item advance() => LR1Item(
    productionId: productionId,
    leftSide: leftSide,
    rightSide: rightSide,
    dotPosition: dotPosition + 1,
    lookahead: lookahead,
    productionOrder: productionOrder,
    isAugmented: isAugmented,
  );

  @override
  bool operator ==(Object other) =>
      other is LR1Item && other.stableKey == stableKey;

  @override
  int get hashCode => stableKey.hashCode;
}

class LR1State {
  LR1State({
    required this.index,
    required List<LR1Item> items,
    required List<String> viablePrefix,
  }) : items = List<LR1Item>.unmodifiable(items),
       viablePrefix = List<String>.unmodifiable(viablePrefix);

  final int index;
  final List<LR1Item> items;
  final List<String> viablePrefix;

  String get id => 'I$index';
}

class LR1Transition {
  LR1Transition({
    required this.fromState,
    required this.toState,
    required this.symbol,
    required List<LR1Item> sourceItems,
  }) : sourceItems = List<LR1Item>.unmodifiable(sourceItems);

  final int fromState;
  final int toState;
  final String symbol;
  final List<LR1Item> sourceItems;
}

enum LR1ActionKind { shift, reduce, accept }

class LR1Action {
  LR1Action({
    required this.kind,
    this.targetState,
    this.productionId,
    this.productionLeftSide,
    List<String>? productionRightSide,
    this.productionOrder,
    required List<LR1Item> sourceItems,
  }) : productionRightSide = productionRightSide == null
           ? null
           : List<String>.unmodifiable(productionRightSide),
       sourceItems = List<LR1Item>.unmodifiable(sourceItems);

  final LR1ActionKind kind;
  final int? targetState;
  final String? productionId;
  final String? productionLeftSide;
  final List<String>? productionRightSide;
  final int? productionOrder;
  final List<LR1Item> sourceItems;

  String get stableKey => switch (kind) {
    LR1ActionKind.shift => 'shift:$targetState',
    LR1ActionKind.reduce => 'reduce:$productionId:$productionOrder',
    LR1ActionKind.accept => 'accept',
  };

  String get display => switch (kind) {
    LR1ActionKind.shift => 's$targetState',
    LR1ActionKind.reduce => 'r$productionId',
    LR1ActionKind.accept => 'acc',
  };
}

enum LR1ConflictKind { shiftReduce, reduceReduce }

class LR1Conflict {
  LR1Conflict({
    required this.state,
    required this.lookahead,
    required this.kind,
    required List<LR1Action> actions,
    required List<String> viablePrefix,
  }) : actions = List<LR1Action>.unmodifiable(actions),
       viablePrefix = List<String>.unmodifiable(viablePrefix);

  final int state;
  final String lookahead;
  final LR1ConflictKind kind;
  final List<LR1Action> actions;
  final List<String> viablePrefix;

  String get stateId => 'I$state';
}

class LR1ParseTable {
  LR1ParseTable({
    required Map<int, Map<String, List<LR1Action>>> actions,
    required Map<int, Map<String, int>> gotos,
    required Map<int, Map<String, List<LR1Item>>> gotoSources,
    required List<LR1Conflict> conflicts,
    required Set<String> terminals,
    required Set<String> nonTerminals,
  }) : actions = Map<int, Map<String, List<LR1Action>>>.unmodifiable(
         actions.map(
           (state, row) => MapEntry(
             state,
             Map<String, List<LR1Action>>.unmodifiable(
               row.map(
                 (lookahead, cell) =>
                     MapEntry(lookahead, List<LR1Action>.unmodifiable(cell)),
               ),
             ),
           ),
         ),
       ),
       gotos = Map<int, Map<String, int>>.unmodifiable(
         gotos.map(
           (state, row) => MapEntry(state, Map<String, int>.unmodifiable(row)),
         ),
       ),
       gotoSources = Map<int, Map<String, List<LR1Item>>>.unmodifiable(
         gotoSources.map(
           (state, row) => MapEntry(
             state,
             Map<String, List<LR1Item>>.unmodifiable(
               row.map(
                 (symbol, items) =>
                     MapEntry(symbol, List<LR1Item>.unmodifiable(items)),
               ),
             ),
           ),
         ),
       ),
       conflicts = List<LR1Conflict>.unmodifiable(conflicts),
       terminals = Set<String>.unmodifiable(terminals),
       nonTerminals = Set<String>.unmodifiable(nonTerminals);

  final Map<int, Map<String, List<LR1Action>>> actions;
  final Map<int, Map<String, int>> gotos;
  final Map<int, Map<String, List<LR1Item>>> gotoSources;
  final List<LR1Conflict> conflicts;
  final Set<String> terminals;
  final Set<String> nonTerminals;

  List<LR1Action> actionsAt(int state, String lookahead) =>
      actions[state]?[lookahead] ?? const <LR1Action>[];

  int? gotoAt(int state, String nonTerminal) => gotos[state]?[nonTerminal];

  List<LR1Item> gotoSourceItemsAt(int state, String nonTerminal) =>
      gotoSources[state]?[nonTerminal] ?? const <LR1Item>[];
}

class LR1Construction {
  LR1Construction({
    required this.sourceGrammar,
    required this.augmentedProduction,
    required List<LR1State> states,
    required List<LR1Transition> transitions,
    required this.table,
  }) : states = List<LR1State>.unmodifiable(states),
       transitions = List<LR1Transition>.unmodifiable(transitions);

  final Grammar sourceGrammar;
  final Production augmentedProduction;
  final List<LR1State> states;
  final List<LR1Transition> transitions;
  final LR1ParseTable table;
}

enum LR1ParseOutcome {
  accepted,
  rejected,
  invalidGrammar,
  tokenizationFailure,
  conflict,
  cancelled,
  timedOut,
  resourceLimit,
  tableConstructionFailure,
}

enum LR1ParseDiagnostic {
  emptyActionCell,
  missingGoto,
  conflict,
  cancelled,
  timedOut,
  resourceLimit,
  invalidParserState,
}

class LR1ParseStep {
  LR1ParseStep({
    required this.stepNumber,
    required List<int> stateStackBefore,
    required List<String> symbolStackBefore,
    required List<String> remainingInput,
    required this.lookahead,
    required this.lookupState,
    this.action,
    this.reducedProductionId,
    this.popCount = 0,
    required List<int> stateStackAfter,
    required List<String> symbolStackAfter,
    this.partialTree,
    this.diagnostic,
    this.structuredMessage,
    required this.message,
  }) : stateStackBefore = List<int>.unmodifiable(stateStackBefore),
       symbolStackBefore = List<String>.unmodifiable(symbolStackBefore),
       remainingInput = List<String>.unmodifiable(remainingInput),
       stateStackAfter = List<int>.unmodifiable(stateStackAfter),
       symbolStackAfter = List<String>.unmodifiable(symbolStackAfter);

  final int stepNumber;
  final List<int> stateStackBefore;
  final List<String> symbolStackBefore;
  final List<String> remainingInput;
  final String lookahead;
  final int lookupState;
  final LR1Action? action;
  final String? reducedProductionId;
  final int popCount;
  final List<int> stateStackAfter;
  final List<String> symbolStackAfter;
  final DerivationTree? partialTree;
  final LR1ParseDiagnostic? diagnostic;
  final StructuredMessage? structuredMessage;
  final String message;
}

class LR1ParseResult {
  LR1ParseResult({
    required this.inputString,
    required this.outcome,
    required List<LR1ParseStep> steps,
    required this.executionTime,
    this.tree,
    this.message,
    this.structuredMessage,
    this.farthestPosition = 0,
    Set<String> expectedTerminals = const {},
    this.construction,
  }) : steps = List<LR1ParseStep>.unmodifiable(steps),
       expectedTerminals = Set<String>.unmodifiable(expectedTerminals);

  final String inputString;
  final LR1ParseOutcome outcome;
  final List<LR1ParseStep> steps;
  final Duration executionTime;
  final DerivationTree? tree;
  final String? message;
  final StructuredMessage? structuredMessage;
  final int farthestPosition;
  final Set<String> expectedTerminals;
  final LR1Construction? construction;

  bool get accepted => outcome == LR1ParseOutcome.accepted;
}

DerivationTree lr1TreeFromNode(DerivationTreeNode node) =>
    DerivationTree(root: node, isShallow: false);
