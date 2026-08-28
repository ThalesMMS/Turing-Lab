part of '../grammar_analyzer.dart';

class GrammarLeftRecursionAnalyzer {
  const GrammarLeftRecursionAnalyzer(this.context);

  final GrammarAnalysisContext context;

  bool hasLeftCornerCycle() {
    final nullable = GrammarNullableFirstFollowAnalyzer(
      context,
    ).computeNullableNonTerminals();
    final graph = <String, Set<String>>{
      for (final nonTerminal in context.nonTerminals) nonTerminal: <String>{},
    };
    for (final production in context.productions) {
      if (production.leftSide.length != 1) {
        continue;
      }
      final left = production.leftSide.single;
      if (!graph.containsKey(left)) continue;
      for (final corner in context.normalizedRight(production)) {
        if (context.isEpsilonToken(corner)) continue;
        if (!graph.containsKey(corner)) break;
        graph[left]!.add(corner);
        if (!nullable.contains(corner)) break;
      }
    }

    bool visit(String node, Set<String> visiting, Set<String> visited) {
      if (visiting.contains(node)) return true;
      if (!visited.add(node)) return false;
      visiting.add(node);
      for (final next in graph[node]!) {
        if (visit(next, visiting, visited)) return true;
      }
      visiting.remove(node);
      return false;
    }

    final visited = <String>{};
    return graph.keys.any((node) => visit(node, <String>{}, visited));
  }
}

class GrammarLeftRecursionTransformer {
  const GrammarLeftRecursionTransformer(this.context);

  final GrammarAnalysisContext context;

  Result<GrammarAnalysisReport<Grammar>> removeLeftRecursion() {
    final grammar = context.grammarSnapshot();
    if (context.productions.isEmpty) {
      final message = GrammarAnalysisMessages.emptyProductions();
      return Failure(message.stableCode, structuredMessage: message);
    }
    if (!GrammarLeftRecursionAnalyzer(context).hasLeftCornerCycle()) {
      return ResultFactory.success(
        GrammarReportComposer.compose(
          value: grammar,
          structuredNotes: [GrammarAnalysisMessages.noLeftRecursion()],
        ),
      );
    }

    final orderedNonTerminals = context.orderedNonTerminals();
    final working = <String, List<Production>>{
      for (final nonTerminal in orderedNonTerminals)
        nonTerminal: <Production>[],
    };
    for (final production in context.productions) {
      if (production.leftSide.isEmpty) continue;
      (working[production.leftSide.first] ??= <Production>[]).add(production);
    }

    final newNonTerminals = Set<String>.from(context.nonTerminals);
    final usedProductionIds = context.productions
        .map((production) => production.id)
        .toSet();
    final notes = <String>[
      'Processing order: ${orderedNonTerminals.join(', ')}.',
    ];
    final structuredNotes = <StructuredMessage>[
      GrammarAnalysisMessages.processingOrder(orderedNonTerminals.join(', ')),
    ];
    final derivations = <String>[];
    final structuredDerivations = <StructuredMessage>[];
    final steps = <GrammarTransformationStep>[];
    final structuredSteps = <GrammarAnalysisStructuredTransformationStep>[];
    var currentGrammar = grammar;
    var stepCounter = 0;

    Grammar snapshot() => _snapshot(grammar, working, newNonTerminals);

    for (var i = 0; i < orderedNonTerminals.length; i++) {
      final currentNonTerminal = orderedNonTerminals[i];
      for (var j = 0; j < i; j++) {
        final earlierNonTerminal = orderedNonTerminals[j];
        final substitutions = List<Production>.from(
          working[currentNonTerminal]!.where((production) {
            final right = context.normalizedRight(production);
            return right.isNotEmpty && right.first == earlierNonTerminal;
          }),
        );

        for (final source in substitutions) {
          final before = currentGrammar;
          final sourceRight = context.normalizedRight(source);
          final suffix = sourceRight.sublist(1);
          final replacements = <Production>[];
          for (final earlier in working[earlierNonTerminal]!) {
            final combined = <String>[
              ...context.normalizedRight(earlier),
              ...suffix,
            ];
            replacements.add(
              Production(
                id: _uniqueProductionId(
                  '${source.id}_via_${earlier.id}',
                  usedProductionIds,
                ),
                leftSide: [currentNonTerminal],
                rightSide: combined,
                isLambda: combined.isEmpty,
                order: source.order,
              ),
            );
          }

          final current = working[currentNonTerminal]!;
          final sourceIndex = current.indexOf(source);
          if (sourceIndex < 0) continue;
          current
            ..removeAt(sourceIndex)
            ..insertAll(sourceIndex, replacements);
          working[currentNonTerminal] = _deduplicateProductions(current);

          final after = snapshot();
          final replacementText = replacements.isEmpty
              ? 'no alternatives'
              : replacements.map(_describeProduction).join(' | ');
          notes.add(
            'Substitution step: replaced ${_describeProduction(source)} using $earlierNonTerminal.',
          );
          structuredNotes.add(
            GrammarAnalysisMessages.substitutionNote(
              production: _describeProduction(source),
              via: earlierNonTerminal,
            ),
          );
          derivations.add(
            'Substitution: ${_describeProduction(source)} ⇒ $replacementText',
          );
          structuredDerivations.add(
            GrammarAnalysisMessages.substitutionDerivation(
              production: _describeProduction(source),
              replacements: replacementText,
            ),
          );
          final step = GrammarTransformationStep(
            id: 'left_recursion_substitution_${stepCounter++}',
            operation:
                'Substitution for $currentNonTerminal via $earlierNonTerminal',
            rationale:
                'Replace the leading $earlierNonTerminal with its current alternatives before processing $currentNonTerminal.',
            before: before,
            after: after,
            changedSymbols: {currentNonTerminal, earlierNonTerminal},
            changedProductionIds: {
              source.id,
              ...replacements.map((production) => production.id),
            },
          );
          steps.add(step);
          structuredSteps.add(
            GrammarAnalysisStructuredTransformationStep(
              legacyStep: step,
              operationMessage: GrammarAnalysisMessages.substitutionOperation(
                current: currentNonTerminal,
                via: earlierNonTerminal,
              ),
              rationaleMessage: GrammarAnalysisMessages.substitutionRationale(
                current: currentNonTerminal,
                via: earlierNonTerminal,
              ),
            ),
          );
          currentGrammar = after;
        }
      }

      final currentProductions = working[currentNonTerminal]!;
      final recursive = currentProductions.where((production) {
        final right = context.normalizedRight(production);
        return right.isNotEmpty && right.first == currentNonTerminal;
      }).toList();
      if (recursive.isEmpty) continue;

      final before = currentGrammar;
      final nonRecursive = currentProductions
          .where((production) => !recursive.contains(production))
          .toList();
      final productiveRecursive = recursive
          .where((production) => context.normalizedRight(production).length > 1)
          .toList();
      final changedProductionIds = recursive
          .map((production) => production.id)
          .toSet();
      String rationale;
      String derivation;
      late StructuredMessage rationaleMessage;
      late StructuredMessage derivationMessage;
      String? prime;

      if (productiveRecursive.isEmpty) {
        working[currentNonTerminal] = nonRecursive;
        rationale =
            'Remove vacuous $currentNonTerminal → $currentNonTerminal alternatives, which add no strings to the language.';
        derivation =
            'Direct recursion: removed ${recursive.map(_describeProduction).join(' | ')}.';
        rationaleMessage =
            GrammarAnalysisMessages.removeVacuousRecursionRationale(
              currentNonTerminal,
            );
        derivationMessage = GrammarAnalysisMessages.vacuousRecursionDerivation(
          recursive.map(_describeProduction).join(' | '),
        );
      } else if (nonRecursive.isEmpty) {
        working[currentNonTerminal] = <Production>[];
        rationale =
            '$currentNonTerminal has no terminating alternative, so its recursive-only productions derive no terminal strings.';
        derivation =
            'Direct recursion: removed recursive-only alternatives for $currentNonTerminal.';
        rationaleMessage = GrammarAnalysisMessages.recursiveOnlyRationale(
          currentNonTerminal,
        );
        derivationMessage = GrammarAnalysisMessages.recursiveOnlyDerivation(
          currentNonTerminal,
        );
      } else {
        final introducedPrime = _generatePrimeSymbol(
          currentNonTerminal,
          newNonTerminals,
        );
        prime = introducedPrime;
        newNonTerminals.add(introducedPrime);
        final rewrittenBase = nonRecursive.map((production) {
          final right = <String>[
            ...context.normalizedRight(production),
            introducedPrime,
          ];
          changedProductionIds.add(production.id);
          return Production(
            id: production.id,
            leftSide: [currentNonTerminal],
            rightSide: right,
            order: production.order,
          );
        }).toList();
        final rewrittenRecursive = productiveRecursive.map((production) {
          final right = <String>[
            ...context.normalizedRight(production).sublist(1),
            introducedPrime,
          ];
          return Production(
            id: production.id,
            leftSide: [introducedPrime],
            rightSide: right,
            order: production.order,
          );
        }).toList();
        final epsilonId = _uniqueProductionId(
          '${grammar.id}_${introducedPrime}_epsilon',
          usedProductionIds,
        );
        final epsilon = Production(
          id: epsilonId,
          leftSide: [introducedPrime],
          rightSide: const [],
          isLambda: true,
          order: currentProductions.length,
        );
        changedProductionIds.add(epsilonId);
        working[currentNonTerminal] = rewrittenBase;
        working[introducedPrime] = [...rewrittenRecursive, epsilon];
        notes.add(
          'Direct-recursion step: introduced $introducedPrime for $currentNonTerminal.',
        );
        structuredNotes.add(
          GrammarAnalysisMessages.directRecursionIntroduced(
            introduced: introducedPrime,
            nonTerminal: currentNonTerminal,
          ),
        );
        rationale =
            'Move the recursive suffixes of $currentNonTerminal to $introducedPrime and add a terminating ε alternative.';
        derivation =
            'Direct recursion: rewrote $currentNonTerminal with $introducedPrime.';
        rationaleMessage =
            GrammarAnalysisMessages.moveRecursiveSuffixesRationale(
              nonTerminal: currentNonTerminal,
              introduced: introducedPrime,
            );
        derivationMessage =
            GrammarAnalysisMessages.directRecursionRewrittenDerivation(
              nonTerminal: currentNonTerminal,
              introduced: introducedPrime,
            );
      }

      final after = snapshot();
      derivations.add(derivation);
      structuredDerivations.add(derivationMessage);
      final step = GrammarTransformationStep(
        id: 'left_recursion_direct_${stepCounter++}',
        operation: 'Direct recursion removal for $currentNonTerminal',
        rationale: rationale,
        before: before,
        after: after,
        changedSymbols: {currentNonTerminal, if (prime != null) prime},
        changedProductionIds: changedProductionIds,
      );
      steps.add(step);
      structuredSteps.add(
        GrammarAnalysisStructuredTransformationStep(
          legacyStep: step,
          operationMessage: GrammarAnalysisMessages.directRecursionOperation(
            currentNonTerminal,
          ),
          rationaleMessage: rationaleMessage,
        ),
      );
      currentGrammar = after;
    }

    if (GrammarLeftRecursionAnalyzer(
      GrammarAnalysisContext(currentGrammar),
    ).hasLeftCornerCycle()) {
      final message = GrammarAnalysisMessages.leftCornerCycleRemains();
      return Failure(
        'Ordered substitution left a cycle in the left-corner relation.',
        structuredMessage: message,
      );
    }

    notes.add('Removed direct and indirect left recursion.');
    structuredNotes.add(GrammarAnalysisMessages.leftRecursionRemoved());
    return ResultFactory.success(
      GrammarReportComposer.compose(
        value: currentGrammar,
        notes: notes,
        structuredNotes: structuredNotes,
        derivations: derivations,
        structuredDerivations: structuredDerivations,
        steps: steps,
        structuredSteps: structuredSteps,
      ),
    );
  }

  Grammar _snapshot(
    Grammar original,
    Map<String, List<Production>> working,
    Set<String> nonTerminals,
  ) {
    final productions = <Production>[];
    var order = 0;
    for (final alternatives in working.values) {
      for (final production in alternatives) {
        productions.add(production.copyWith(order: order++));
      }
    }
    return GrammarAnalysisContext(
      original.copyWith(
        nonterminals: Set<String>.from(nonTerminals),
        productions: productions.toSet(),
      ),
    ).grammarSnapshot();
  }

  List<Production> _deduplicateProductions(List<Production> productions) {
    final seen = <String>{};
    final result = <Production>[];
    for (final production in productions) {
      final right = context.normalizedRight(production);
      final key =
          '${production.leftSide.join('\u0000')}\u0001'
          '${right.join('\u0000')}';
      if (seen.add(key)) result.add(production);
    }
    return result;
  }

  static String _uniqueProductionId(String base, Set<String> used) {
    var candidate = base;
    var suffix = 2;
    while (!used.add(candidate)) {
      candidate = '${base}_$suffix';
      suffix++;
    }
    return candidate;
  }

  String _describeProduction(Production production) {
    return '${production.leftSide.join(' ')} → '
        '${GrammarAnalysisContext.formatSymbols(context.normalizedRight(production))}';
  }

  static String _generatePrimeSymbol(String base, Set<String> existing) {
    var candidate = "$base'";
    while (existing.contains(candidate)) {
      candidate = "$candidate'";
    }
    return candidate;
  }
}
