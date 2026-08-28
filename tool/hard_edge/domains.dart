import 'generation.dart';
import 'models.dart';

final class GeneratedState {
  const GeneratedState({
    required this.id,
    required this.initial,
    required this.accepting,
  });

  final String id;
  final bool initial;
  final bool accepting;

  Map<String, Object?> toJson() => {
        'accepting': accepting,
        'id': id,
        'initial': initial,
      };
}

final class GeneratedTransition {
  GeneratedTransition({
    required this.id,
    required this.fromId,
    required this.toId,
    required Iterable<String> readTokens,
    Iterable<String> writeTokens = const [],
  })  : readTokens = List.unmodifiable(readTokens),
        writeTokens = List.unmodifiable(writeTokens);

  final String id;
  final String fromId;
  final String toId;
  final List<String> readTokens;
  final List<String> writeTokens;

  Map<String, Object?> toJson() => {
        'fromId': fromId,
        'id': id,
        'readTokens': readTokens,
        'toId': toId,
        'writeTokens': writeTokens,
      };
}

final class GeneratedProduction {
  GeneratedProduction({
    required this.id,
    required Iterable<String> leftTokens,
    required Iterable<String> rightTokens,
  })  : leftTokens = List.unmodifiable(leftTokens),
        rightTokens = List.unmodifiable(rightTokens);

  final String id;
  final List<String> leftTokens;
  final List<String> rightTokens;

  Map<String, Object?> toJson() => {
        'id': id,
        'leftTokens': leftTokens,
        'rightTokens': rightTokens,
      };
}

enum GeneratedRegexKind { empty, epsilon, symbol, union, concatenation, star }

final class GeneratedRegexAst {
  GeneratedRegexAst({
    required this.kind,
    this.symbol,
    Iterable<GeneratedRegexAst> children = const [],
  }) : children = List.unmodifiable(children);

  final GeneratedRegexKind kind;
  final String? symbol;
  final List<GeneratedRegexAst> children;

  int get nodeCount =>
      1 + children.fold(0, (total, child) => total + child.nodeCount);

  Map<String, Object?> toJson() => {
        'children': children.map((child) => child.toJson()).toList(),
        'kind': kind.name,
        if (symbol != null) 'symbol': symbol,
      };
}

final class GeneratedAutomaton {
  GeneratedAutomaton({
    required this.id,
    required Iterable<String> alphabet,
    required Iterable<GeneratedState> states,
    required Iterable<GeneratedTransition> transitions,
    this.malformation,
  })  : alphabet = List.unmodifiable(alphabet),
        states = List.unmodifiable(states),
        transitions = List.unmodifiable(transitions);

  final String id;
  final List<String> alphabet;
  final List<GeneratedState> states;
  final List<GeneratedTransition> transitions;
  final String? malformation;

  GeneratedAutomaton copyWith({
    Iterable<String>? alphabet,
    Iterable<GeneratedState>? states,
    Iterable<GeneratedTransition>? transitions,
  }) =>
      GeneratedAutomaton(
        id: id,
        alphabet: alphabet ?? this.alphabet,
        states: states ?? this.states,
        transitions: transitions ?? this.transitions,
        malformation: malformation,
      );

  Map<String, Object?> toJson() => {
        'alphabet': alphabet,
        'id': id,
        if (malformation != null) 'malformation': malformation,
        'states': states.map((state) => state.toJson()).toList(),
        'transitions':
            transitions.map((transition) => transition.toJson()).toList(),
      };
}

final class GeneratedGrammar {
  GeneratedGrammar({
    required this.id,
    required Iterable<String> terminals,
    required Iterable<String> nonterminals,
    required this.startSymbol,
    required Iterable<GeneratedProduction> productions,
    this.malformation,
  })  : terminals = List.unmodifiable(terminals),
        nonterminals = List.unmodifiable(nonterminals),
        productions = List.unmodifiable(productions);

  final String id;
  final List<String> terminals;
  final List<String> nonterminals;
  final String startSymbol;
  final List<GeneratedProduction> productions;
  final String? malformation;

  GeneratedGrammar copyWith({
    Iterable<String>? terminals,
    Iterable<String>? nonterminals,
    Iterable<GeneratedProduction>? productions,
  }) =>
      GeneratedGrammar(
        id: id,
        terminals: terminals ?? this.terminals,
        nonterminals: nonterminals ?? this.nonterminals,
        startSymbol: startSymbol,
        productions: productions ?? this.productions,
        malformation: malformation,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        if (malformation != null) 'malformation': malformation,
        'nonterminals': nonterminals,
        'productions':
            productions.map((production) => production.toJson()).toList(),
        'startSymbol': startSymbol,
        'terminals': terminals,
      };
}

final class GeneratedTransducer {
  GeneratedTransducer({
    required this.id,
    required Iterable<String> inputAlphabet,
    required Iterable<String> outputAlphabet,
    required Iterable<GeneratedState> states,
    required Iterable<GeneratedTransition> transitions,
    this.malformation,
  })  : inputAlphabet = List.unmodifiable(inputAlphabet),
        outputAlphabet = List.unmodifiable(outputAlphabet),
        states = List.unmodifiable(states),
        transitions = List.unmodifiable(transitions);

  final String id;
  final List<String> inputAlphabet;
  final List<String> outputAlphabet;
  final List<GeneratedState> states;
  final List<GeneratedTransition> transitions;
  final String? malformation;

  GeneratedTransducer copyWith({
    Iterable<String>? inputAlphabet,
    Iterable<String>? outputAlphabet,
    Iterable<GeneratedState>? states,
    Iterable<GeneratedTransition>? transitions,
  }) =>
      GeneratedTransducer(
        id: id,
        inputAlphabet: inputAlphabet ?? this.inputAlphabet,
        outputAlphabet: outputAlphabet ?? this.outputAlphabet,
        states: states ?? this.states,
        transitions: transitions ?? this.transitions,
        malformation: malformation,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'inputAlphabet': inputAlphabet,
        if (malformation != null) 'malformation': malformation,
        'outputAlphabet': outputAlphabet,
        'states': states.map((state) => state.toJson()).toList(),
        'transitions':
            transitions.map((transition) => transition.toJson()).toList(),
      };
}

final class GeneratedLSystem {
  GeneratedLSystem({
    required this.id,
    required Iterable<String> alphabet,
    required Iterable<String> axiomTokens,
    required Iterable<GeneratedProduction> productions,
    required this.iterations,
    this.malformation,
  })  : alphabet = List.unmodifiable(alphabet),
        axiomTokens = List.unmodifiable(axiomTokens),
        productions = List.unmodifiable(productions);

  final String id;
  final List<String> alphabet;
  final List<String> axiomTokens;
  final List<GeneratedProduction> productions;
  final int iterations;
  final String? malformation;

  GeneratedLSystem copyWith({
    Iterable<String>? alphabet,
    Iterable<String>? axiomTokens,
    Iterable<GeneratedProduction>? productions,
    int? iterations,
  }) =>
      GeneratedLSystem(
        id: id,
        alphabet: alphabet ?? this.alphabet,
        axiomTokens: axiomTokens ?? this.axiomTokens,
        productions: productions ?? this.productions,
        iterations: iterations ?? this.iterations,
        malformation: malformation,
      );

  Map<String, Object?> toJson() => {
        'alphabet': alphabet,
        'axiomTokens': axiomTokens,
        'id': id,
        'iterations': iterations,
        if (malformation != null) 'malformation': malformation,
        'productions':
            productions.map((production) => production.toJson()).toList(),
      };
}

final class SymbolGenerator implements DomainGenerator<String> {
  const SymbolGenerator();

  static const _portableSymbols = ['a', 'b', '0', 'β', '🙂', 'token'];

  @override
  String generate(GenerationContext context) {
    if (context.mode == GenerationMode.malformed) return '';
    if (context.mode == GenerationMode.boundaryValid) return 'token';
    return context.random.choose(_portableSymbols);
  }
}

final class AlphabetGenerator implements DomainGenerator<List<String>> {
  const AlphabetGenerator();

  @override
  List<String> generate(GenerationContext context) {
    if (context.mode == GenerationMode.malformed &&
        context.budget.maxSymbols == 0) {
      throw ArgumentError(
        'Malformed alphabet generation requires maxSymbols greater than zero.',
      );
    }
    final count = context.size(
      maximum: context.budget.maxSymbols,
      minimum: context.mode == GenerationMode.malformed &&
              context.budget.maxSymbols > 0
          ? 1
          : 0,
    );
    final candidates = <String>[
      ...SymbolGenerator._portableSymbols,
      for (var index = SymbolGenerator._portableSymbols.length;
          index < count;
          index++)
        'symbol-$index',
    ];
    final alphabet = context.random.shuffled(candidates).take(count).toList();
    if (context.mode == GenerationMode.malformed && alphabet.isNotEmpty) {
      alphabet[alphabet.length - 1] = '';
    }
    return List.unmodifiable(alphabet);
  }
}

final class WordGenerator implements DomainGenerator<List<String>> {
  const WordGenerator({this.alphabet});

  final List<String>? alphabet;

  @override
  List<String> generate(GenerationContext context) {
    final symbols = alphabet ?? const AlphabetGenerator().generate(context);
    if (symbols.isEmpty) {
      if (context.mode == GenerationMode.malformed) {
        throw ArgumentError(
          'Malformed word generation requires at least one symbol slot.',
        );
      }
      return const [];
    }
    if (context.mode == GenerationMode.malformed &&
        context.budget.maxWordLength == 0) {
      throw ArgumentError(
        'Malformed word generation requires maxWordLength greater than zero.',
      );
    }
    final length = context.size(
      maximum: context.budget.maxWordLength,
      minimum: context.mode == GenerationMode.malformed &&
              context.budget.maxWordLength > 0
          ? 1
          : 0,
    );
    if (context.mode == GenerationMode.malformed) {
      if (length == 0) return const [];
      return List.unmodifiable([
        for (var index = 0; index < length; index++)
          if (index == length - 1) '' else _token(context, symbols, index),
      ]);
    }
    return List.unmodifiable([
      for (var index = 0; index < length; index++)
        _token(context, symbols, index),
    ]);
  }
}

final class StateGenerator implements DomainGenerator<GeneratedState> {
  const StateGenerator();

  @override
  GeneratedState generate(GenerationContext context) => GeneratedState(
        id: context.mode == GenerationMode.malformed
            ? ''
            : context.nextId('state'),
        initial: true,
        accepting: context.random.nextBool(),
      );
}

final class TransitionGenerator
    implements DomainGenerator<GeneratedTransition> {
  const TransitionGenerator({this.stateIds, this.alphabet});

  final List<String>? stateIds;
  final List<String>? alphabet;

  @override
  GeneratedTransition generate(GenerationContext context) {
    final states = stateIds ?? const ['state-000000'];
    final symbols = alphabet ?? const ['a'];
    final malformed = context.mode == GenerationMode.malformed;
    return GeneratedTransition(
      id: context.nextId('transition'),
      fromId: malformed ? 'missing-state' : context.random.choose(states),
      toId: context.random.choose(states),
      readTokens: symbols.isEmpty || context.random.nextInt(4) == 0
          ? const []
          : [context.random.choose(symbols)],
    );
  }
}

final class ProductionGenerator
    implements DomainGenerator<GeneratedProduction> {
  const ProductionGenerator({this.nonterminals, this.terminals});

  final List<String>? nonterminals;
  final List<String>? terminals;

  @override
  GeneratedProduction generate(GenerationContext context) {
    final variables = nonterminals ?? const ['S'];
    final symbols = terminals ?? const ['a'];
    final malformed = context.mode == GenerationMode.malformed;
    return GeneratedProduction(
      id: context.nextId('production'),
      leftTokens: malformed ? const [] : [context.random.choose(variables)],
      rightTokens: symbols.isEmpty || context.random.nextInt(4) == 0
          ? const []
          : [context.random.choose(symbols)],
    );
  }
}

final class RegexAstGenerator implements DomainGenerator<GeneratedRegexAst> {
  const RegexAstGenerator({this.alphabet});

  final List<String>? alphabet;

  @override
  GeneratedRegexAst generate(GenerationContext context) {
    if (context.mode == GenerationMode.malformed) {
      return GeneratedRegexAst(kind: GeneratedRegexKind.symbol);
    }
    final symbols = alphabet ?? const ['a', 'token'];
    final maximum = context.budget.maxRegexNodes;
    GeneratedRegexAst node(int available) {
      if (available <= 1) return _regexLeaf(context, symbols);
      final compoundKinds = <GeneratedRegexKind>[
        GeneratedRegexKind.star,
        if (available >= 3) ...[
          GeneratedRegexKind.union,
          GeneratedRegexKind.concatenation,
        ],
      ];
      final makeCompound = context.mode == GenerationMode.boundaryValid ||
          context.random.nextBool();
      if (!makeCompound) return _regexLeaf(context, symbols);
      final kind = context.random.choose(compoundKinds);
      if (kind == GeneratedRegexKind.star) {
        return GeneratedRegexAst(kind: kind, children: [node(available - 1)]);
      }
      final childBudget = available - 1;
      final leftBudget = context.mode == GenerationMode.boundaryValid
          ? childBudget ~/ 2
          : 1 + context.random.nextInt(childBudget - 1);
      return GeneratedRegexAst(
        kind: kind,
        children: [node(leftBudget), node(childBudget - leftBudget)],
      );
    }

    return node(maximum);
  }
}

final class TapeGenerator implements DomainGenerator<List<String>> {
  const TapeGenerator({this.alphabet});

  final List<String>? alphabet;

  @override
  List<String> generate(GenerationContext context) => _sequence(
        context,
        alphabet ?? const ['0', '1', '□'],
        context.budget.maxTapeCells,
      );
}

final class StackGenerator implements DomainGenerator<List<String>> {
  const StackGenerator({this.alphabet});

  final List<String>? alphabet;

  @override
  List<String> generate(GenerationContext context) => _sequence(
        context,
        alphabet ?? const ['Z', 'A', 'token'],
        context.budget.maxStackDepth,
      );
}

final class AutomatonGenerator implements DomainGenerator<GeneratedAutomaton> {
  const AutomatonGenerator();

  @override
  GeneratedAutomaton generate(GenerationContext context) {
    final alphabet = const AlphabetGenerator().generate(context);
    final stateCount = context.size(
      maximum: context.budget.maxStates,
      minimum: context.budget.maxStates == 0 ? 0 : 1,
    );
    final states = [
      for (var index = 0; index < stateCount; index++)
        GeneratedState(
          id: context.nextId('state'),
          initial: index == 0,
          accepting: context.random.nextBool(),
        ),
    ];
    final transitionCount = states.isEmpty
        ? 0
        : context.size(
            maximum: context.budget.maxTransitions,
            minimum: context.mode == GenerationMode.malformed &&
                    context.budget.maxTransitions > 0
                ? 1
                : 0,
          );
    final transitions = [
      for (var index = 0; index < transitionCount; index++)
        const TransitionGenerator().generateWith(
          context,
          stateIds: states.map((state) => state.id).toList(),
          alphabet: alphabet,
          malformed: context.mode == GenerationMode.malformed && index == 0,
        ),
    ];
    return GeneratedAutomaton(
      id: context.nextId('automaton'),
      alphabet: alphabet,
      states: states,
      transitions: transitions,
      malformation: context.mode == GenerationMode.malformed
          ? 'dangling-transition-source'
          : null,
    );
  }
}

final class GrammarGenerator implements DomainGenerator<GeneratedGrammar> {
  const GrammarGenerator();

  @override
  GeneratedGrammar generate(GenerationContext context) {
    final terminals = const AlphabetGenerator().generate(context);
    final variableCount = context.size(
      maximum: context.budget.maxSymbols,
      minimum: context.budget.maxSymbols == 0 ? 0 : 1,
    );
    final nonterminals = [
      for (var index = 0; index < variableCount; index++)
        index == 0 ? 'S' : 'N$index',
    ];
    final productionCount = nonterminals.isEmpty
        ? 0
        : context.size(
            maximum: context.budget.maxProductions,
            minimum: context.mode == GenerationMode.malformed &&
                    context.budget.maxProductions > 0
                ? 1
                : 0,
          );
    final productions = [
      for (var index = 0; index < productionCount; index++)
        ProductionGenerator(
          nonterminals: nonterminals,
          terminals: terminals,
        ).generateWith(
          context,
          malformed: context.mode == GenerationMode.malformed && index == 0,
        ),
    ];
    return GeneratedGrammar(
      id: context.nextId('grammar'),
      terminals: terminals,
      nonterminals: nonterminals,
      startSymbol: nonterminals.isEmpty ? '' : nonterminals.first,
      productions: productions,
      malformation: context.mode == GenerationMode.malformed
          ? 'empty-production-left'
          : null,
    );
  }
}

final class TransducerGenerator
    implements DomainGenerator<GeneratedTransducer> {
  const TransducerGenerator();

  @override
  GeneratedTransducer generate(GenerationContext context) {
    final inputAlphabet = const AlphabetGenerator().generate(context);
    final outputAlphabet = const AlphabetGenerator().generate(context);
    final stateCount = context.size(
      maximum: context.budget.maxStates,
      minimum: context.budget.maxStates == 0 ? 0 : 1,
    );
    final states = [
      for (var index = 0; index < stateCount; index++)
        GeneratedState(
          id: context.nextId('state'),
          initial: index == 0,
          accepting: context.random.nextBool(),
        ),
    ];
    final transitionCount = states.isEmpty
        ? 0
        : context.size(
            maximum: context.budget.maxTransitions,
            minimum: context.mode == GenerationMode.malformed &&
                    context.budget.maxTransitions > 0
                ? 1
                : 0,
          );
    final transitions = [
      for (var index = 0; index < transitionCount; index++)
        GeneratedTransition(
          id: context.nextId('transition'),
          fromId: context.mode == GenerationMode.malformed && index == 0
              ? 'missing-state'
              : context.random.choose(states).id,
          toId: context.random.choose(states).id,
          readTokens: inputAlphabet.isEmpty
              ? const []
              : [context.random.choose(inputAlphabet)],
          writeTokens: outputAlphabet.isEmpty
              ? const []
              : [context.random.choose(outputAlphabet)],
        ),
    ];
    return GeneratedTransducer(
      id: context.nextId('transducer'),
      inputAlphabet: inputAlphabet,
      outputAlphabet: outputAlphabet,
      states: states,
      transitions: transitions,
      malformation: context.mode == GenerationMode.malformed
          ? 'dangling-transition-source'
          : null,
    );
  }
}

final class LSystemGenerator implements DomainGenerator<GeneratedLSystem> {
  const LSystemGenerator();

  @override
  GeneratedLSystem generate(GenerationContext context) {
    final alphabet = const AlphabetGenerator().generate(context);
    final axiom = WordGenerator(alphabet: alphabet).generate(context);
    final productionCount = alphabet.isEmpty
        ? 0
        : context.size(
            maximum: context.budget.maxProductions,
            minimum: context.mode == GenerationMode.malformed &&
                    context.budget.maxProductions > 0
                ? 1
                : 0,
          );
    final productions = [
      for (var index = 0; index < productionCount; index++)
        GeneratedProduction(
          id: context.nextId('production'),
          leftTokens: context.mode == GenerationMode.malformed && index == 0
              ? const []
              : [context.random.choose(alphabet)],
          rightTokens: WordGenerator(alphabet: alphabet).generate(context),
        ),
    ];
    return GeneratedLSystem(
      id: context.nextId('l-system'),
      alphabet: alphabet,
      axiomTokens: axiom,
      productions: productions,
      iterations: context.size(maximum: context.budget.maxIterations),
      malformation: context.mode == GenerationMode.malformed
          ? 'empty-production-left'
          : null,
    );
  }
}

extension on TransitionGenerator {
  GeneratedTransition generateWith(
    GenerationContext context, {
    required List<String> stateIds,
    required List<String> alphabet,
    required bool malformed,
  }) =>
      GeneratedTransition(
        id: context.nextId('transition'),
        fromId: malformed ? 'missing-state' : context.random.choose(stateIds),
        toId: context.random.choose(stateIds),
        readTokens: alphabet.isEmpty || context.random.nextInt(4) == 0
            ? const []
            : [context.random.choose(alphabet)],
      );
}

extension on ProductionGenerator {
  GeneratedProduction generateWith(
    GenerationContext context, {
    required bool malformed,
  }) =>
      GeneratedProduction(
        id: context.nextId('production'),
        leftTokens:
            malformed ? const [] : [context.random.choose(nonterminals!)],
        rightTokens: terminals!.isEmpty || context.random.nextInt(4) == 0
            ? const []
            : [context.random.choose(terminals!)],
      );
}

String _token(GenerationContext context, List<String> symbols, int index) {
  if (symbols.isEmpty) return 'token-$index';
  return context.random.choose(symbols);
}

GeneratedRegexAst _regexLeaf(
  GenerationContext context,
  List<String> symbols, {
  GeneratedRegexKind? kind,
}) {
  final leafKind = switch (kind) {
    GeneratedRegexKind.empty ||
    GeneratedRegexKind.epsilon ||
    GeneratedRegexKind.symbol =>
      kind!,
    _ => context.random.choose(const [
        GeneratedRegexKind.empty,
        GeneratedRegexKind.epsilon,
        GeneratedRegexKind.symbol,
      ]),
  };
  return GeneratedRegexAst(
    kind: leafKind,
    symbol: leafKind == GeneratedRegexKind.symbol
        ? _token(context, symbols, 0)
        : null,
  );
}

List<String> _sequence(
  GenerationContext context,
  List<String> alphabet,
  int maximum,
) {
  if (context.mode == GenerationMode.malformed && maximum == 0) {
    throw ArgumentError(
      'Malformed sequence generation requires a positive size budget.',
    );
  }
  final length = context.size(
    maximum: maximum,
    minimum: context.mode == GenerationMode.malformed && maximum > 0 ? 1 : 0,
  );
  final result = [
    for (var index = 0; index < length; index++)
      _token(context, alphabet, index),
  ];
  if (context.mode == GenerationMode.malformed) {
    if (result.isNotEmpty) {
      result[result.length - 1] = '';
    }
  }
  return List.unmodifiable(result);
}
