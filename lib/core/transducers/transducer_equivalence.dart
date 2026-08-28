import 'dart:collection';

import 'transducer_analysis.dart';
import 'transducer_models.dart';
import 'transducer_simulator.dart';
import 'transducer_symbols.dart';

sealed class TransducerComparisonSemantics {
  const TransducerComparisonSemantics();
}

final class ExactTransducerComparison extends TransducerComparisonSemantics {
  const ExactTransducerComparison();
}

final class BoundedTransducerComparison extends TransducerComparisonSemantics {
  const BoundedTransducerComparison({required this.maxInputLength});

  final int maxInputLength;
}

enum TransducerComparisonKind { equivalent, different, inconclusive, invalid }

final class TransducerComparisonResult {
  const TransducerComparisonResult({
    required this.kind,
    required this.isExact,
    required this.exploredPairs,
    this.bound,
    this.witness,
    this.leftOutput,
    this.rightOutput,
  });

  final TransducerComparisonKind kind;
  final bool isExact;
  final int exploredPairs;
  final int? bound;
  final TransducerInputWord? witness;
  final TransducerOutputWord? leftOutput;
  final TransducerOutputWord? rightOutput;
}

abstract final class TransducerEquivalenceComparator {
  static TransducerComparisonResult compare(
    DeterministicTransducerSimulator left,
    DeterministicTransducerSimulator right, {
    required TransducerComparisonSemantics semantics,
  }) =>
      switch (semantics) {
        ExactTransducerComparison() => _compareExact(left, right),
        BoundedTransducerComparison(:final maxInputLength) => _compareBounded(
            left,
            right,
            maxInputLength,
          ),
      };
}

TransducerComparisonResult _compareExact(
  DeterministicTransducerSimulator left,
  DeterministicTransducerSimulator right,
) {
  final leftAnalysis = TransducerAnalyzer.analyze(left.machine);
  final rightAnalysis = TransducerAnalyzer.analyze(right.machine);
  if (!leftAnalysis.isStructurallyValid ||
      !rightAnalysis.isStructurallyValid ||
      !leftAnalysis.isComplete ||
      !rightAnalysis.isComplete ||
      !_setEquals(left.machine.inputAlphabet, right.machine.inputAlphabet)) {
    return const TransducerComparisonResult(
      kind: TransducerComparisonKind.invalid,
      isExact: false,
      exploredPairs: 0,
    );
  }
  final leftInitial = left.uniqueInitialState!;
  final rightInitial = right.uniqueInitialState!;
  final leftInitialOutput = left.emissionRule.initialOutput(leftInitial);
  final rightInitialOutput = right.emissionRule.initialOutput(rightInitial);
  if (leftInitialOutput != rightInitialOutput) {
    return TransducerComparisonResult(
      kind: TransducerComparisonKind.different,
      isExact: true,
      exploredPairs: 1,
      witness: TransducerInputWord.empty,
      leftOutput: leftInitialOutput,
      rightOutput: rightInitialOutput,
    );
  }

  final alphabet = left.machine.inputAlphabet.toList()..sort();
  final queue = Queue<
      ({
        TransducerState left,
        TransducerState right,
        TransducerInputWord prefix
      })>()
    ..add((
      left: leftInitial,
      right: rightInitial,
      prefix: TransducerInputWord.empty
    ));
  final visited = <(String, String)>{};
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (!visited.add((current.left.id.value, current.right.id.value))) continue;
    for (final input in alphabet) {
      final leftTransition = (left.transitionIndex
              .lookup(current.left.id, input) as TransducerTransitionFound)
          .transition;
      final rightTransition = (right.transitionIndex
              .lookup(current.right.id, input) as TransducerTransitionFound)
          .transition;
      final leftTarget = left.stateFor(leftTransition.to)!;
      final rightTarget = right.stateFor(rightTransition.to)!;
      final leftEmission =
          left.emissionRule.transitionOutput(leftTransition, leftTarget);
      final rightEmission =
          right.emissionRule.transitionOutput(rightTransition, rightTarget);
      final witness = TransducerInputWord([
        ...current.prefix.symbols,
        input,
      ]);
      if (leftEmission != rightEmission) {
        final leftRun = left.run(witness);
        final rightRun = right.run(witness);
        return TransducerComparisonResult(
          kind: TransducerComparisonKind.different,
          isExact: true,
          exploredPairs: visited.length,
          witness: witness,
          leftOutput: leftRun.output,
          rightOutput: rightRun.output,
        );
      }
      queue.add((left: leftTarget, right: rightTarget, prefix: witness));
    }
  }
  return TransducerComparisonResult(
    kind: TransducerComparisonKind.equivalent,
    isExact: true,
    exploredPairs: visited.length,
  );
}

TransducerComparisonResult _compareBounded(
  DeterministicTransducerSimulator left,
  DeterministicTransducerSimulator right,
  int bound,
) {
  if (bound < 0 ||
      !_setEquals(left.machine.inputAlphabet, right.machine.inputAlphabet)) {
    return TransducerComparisonResult(
      kind: TransducerComparisonKind.invalid,
      isExact: false,
      exploredPairs: 0,
      bound: bound,
    );
  }
  var explored = 0;
  for (final input in _shortlex(left.machine.inputAlphabet, bound)) {
    final leftRun = left.run(input);
    final rightRun = right.run(input);
    explored++;
    if (leftRun is TransducerInvalidMachine ||
        leftRun is TransducerInvalidInput ||
        rightRun is TransducerInvalidMachine ||
        rightRun is TransducerInvalidInput) {
      return TransducerComparisonResult(
        kind: TransducerComparisonKind.invalid,
        isExact: false,
        exploredPairs: explored,
        bound: bound,
      );
    }
    if (leftRun is! TransducerSuccess || rightRun is! TransducerSuccess) {
      return TransducerComparisonResult(
        kind: TransducerComparisonKind.inconclusive,
        isExact: false,
        exploredPairs: explored,
        bound: bound,
      );
    }
    if (leftRun.output != rightRun.output) {
      return TransducerComparisonResult(
        kind: TransducerComparisonKind.different,
        isExact: false,
        exploredPairs: explored,
        bound: bound,
        witness: input,
        leftOutput: leftRun.output,
        rightOutput: rightRun.output,
      );
    }
  }
  return TransducerComparisonResult(
    kind: TransducerComparisonKind.inconclusive,
    isExact: false,
    exploredPairs: explored,
    bound: bound,
  );
}

Iterable<TransducerInputWord> _shortlex(
  Set<TransducerInputSymbol> alphabet,
  int bound,
) sync* {
  final symbols = alphabet.toList()..sort();
  yield TransducerInputWord.empty;
  var current = <List<TransducerInputSymbol>>[const []];
  for (var length = 1; length <= bound; length++) {
    final next = <List<TransducerInputSymbol>>[];
    for (final prefix in current) {
      for (final symbol in symbols) {
        final word = [...prefix, symbol];
        next.add(word);
        yield TransducerInputWord(word);
      }
    }
    current = next;
  }
}

bool _setEquals<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);
