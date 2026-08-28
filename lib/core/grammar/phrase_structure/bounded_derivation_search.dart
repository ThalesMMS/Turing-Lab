import 'dart:collection';

import 'grammar_classification.dart';
import 'grammar_symbol.dart';
import 'phrase_structure_grammar.dart';
import 'production_application.dart';
import 'symbol_sequence.dart';

final class DerivationCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

final class DerivationSearchLimits {
  const DerivationSearchLimits({
    this.maxExpandedForms = 10000,
    this.maxVisitedForms = 20000,
    this.maxFrontierSize = 5000,
    this.maxSymbolCount = 128,
    this.yieldEvery = 64,
    this.timeLimit,
  })  : assert(maxExpandedForms >= 0),
        assert(maxVisitedForms > 0),
        assert(maxFrontierSize > 0),
        assert(maxSymbolCount >= 0),
        assert(yieldEvery > 0);

  final int maxExpandedForms;
  final int maxVisitedForms;
  final int maxFrontierSize;
  final int maxSymbolCount;
  final int yieldEvery;
  final Duration? timeLimit;
}

sealed class DerivationSearchOutcome {
  const DerivationSearchOutcome({
    required this.exploredForms,
    required this.frontierPeak,
  });

  final int exploredForms;
  final int frontierPeak;
}

final class DerivationAccepted extends DerivationSearchOutcome {
  const DerivationAccepted({
    required super.exploredForms,
    required super.frontierPeak,
    required this.witness,
  });

  final List<ProductionApplication> witness;
}

final class DerivationExhausted extends DerivationSearchOutcome {
  const DerivationExhausted({
    required super.exploredForms,
    required super.frontierPeak,
  });
}

final class DerivationBoundedUnknown extends DerivationSearchOutcome {
  const DerivationBoundedUnknown({
    required super.exploredForms,
    required super.frontierPeak,
  });
}

final class DerivationCancelled extends DerivationSearchOutcome {
  const DerivationCancelled({
    required super.exploredForms,
    required super.frontierPeak,
  });
}

final class DerivationInvalid extends DerivationSearchOutcome {
  const DerivationInvalid({
    required super.exploredForms,
    required super.frontierPeak,
    required this.diagnostics,
  });

  final List<PhraseGrammarDiagnostic> diagnostics;
}

abstract final class BoundedDerivationSearch {
  static Future<DerivationSearchOutcome> run({
    required UnrestrictedGrammar grammar,
    required GrammarSymbolSequence input,
    DerivationSearchLimits limits = const DerivationSearchLimits(),
    DerivationCancellationToken? cancellationToken,
  }) async {
    final report = PhraseGrammarClassifier.classify(grammar);
    final inputValid = input.symbols.every(
      (symbol) =>
          symbol is TerminalGrammarSymbol && grammar.terminals.contains(symbol),
    );
    if (!report.isValid || !inputValid) {
      return DerivationInvalid(
        exploredForms: 0,
        frontierPeak: 0,
        diagnostics: [
          ...report.errors,
          if (!inputValid)
            const PhraseGrammarDiagnostic(
              code: PhraseGrammarDiagnosticCode.invalidInputSymbol,
              severity: PhraseGrammarDiagnosticSeverity.error,
            ),
        ],
      );
    }

    final start = GrammarSymbolSequence([grammar.startSymbol]);
    final queue = ListQueue<_SearchNode>()
      ..add(_SearchNode(form: start, witness: const []));
    final visited = <String>{start.stableKey};
    var explored = 0;
    var frontierPeak = 1;
    var truncated = false;
    final stopwatch = Stopwatch()..start();

    while (queue.isNotEmpty) {
      if (cancellationToken?.isCancelled == true) {
        return DerivationCancelled(
          exploredForms: explored,
          frontierPeak: frontierPeak,
        );
      }
      final node = queue.removeFirst();
      if (node.form == input) {
        return DerivationAccepted(
          exploredForms: explored,
          frontierPeak: frontierPeak,
          witness: node.witness,
        );
      }
      final timeLimit = limits.timeLimit;
      if (timeLimit != null && stopwatch.elapsed >= timeLimit) {
        truncated = true;
        break;
      }
      if (explored >= limits.maxExpandedForms) {
        truncated = true;
        break;
      }
      explored++;
      for (final application in PhraseProductionApplicator.allApplications(
        node.form,
        grammar.productions,
      )) {
        if (application.after.length > limits.maxSymbolCount) {
          truncated = true;
          continue;
        }
        final key = application.after.stableKey;
        if (visited.contains(key)) continue;
        if (visited.length >= limits.maxVisitedForms ||
            queue.length >= limits.maxFrontierSize) {
          truncated = true;
          continue;
        }
        visited.add(key);
        queue.add(_SearchNode(
          form: application.after,
          witness: List.unmodifiable([...node.witness, application]),
        ));
        if (queue.length > frontierPeak) frontierPeak = queue.length;
      }
      if (explored % limits.yieldEvery == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    return truncated
        ? DerivationBoundedUnknown(
            exploredForms: explored,
            frontierPeak: frontierPeak,
          )
        : DerivationExhausted(
            exploredForms: explored,
            frontierPeak: frontierPeak,
          );
  }
}

final class _SearchNode {
  const _SearchNode({required this.form, required this.witness});

  final GrammarSymbolSequence form;
  final List<ProductionApplication> witness;
}
