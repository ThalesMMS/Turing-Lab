import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/production.dart';
import '../messages/structured_message.dart';
import '../utils/epsilon_utils.dart';
import 'pda_cfg_shortest_witness_messages.dart';
import 'pda_normalizer.dart';
import 'pda_simulator.dart';
import 'pda_to_cfg_converter.dart';
import 'pda_language_emptiness_messages.dart';

/// Resource bounds for the PDA-to-CFG construction and witness proof.
class PDALanguageEmptinessLimits {
  const PDALanguageEmptinessLimits({
    this.maxGeneratedProductions = 50000,
    this.maxFixedPointUpdates = 1000000,
    this.maxDerivationSteps = 100000,
  });

  final int maxGeneratedProductions;
  final int maxFixedPointUpdates;
  final int maxDerivationSteps;
}

/// Why a language-emptiness proof could not be completed.
enum PDALanguageEmptinessFailureKind {
  invalidInput,
  normalizationFailed,
  conversionFailed,
  resourceLimit,
  cancelled,
  internalConsistency,
}

/// A completed proof or a typed failure. Failures are never reported as empty.
sealed class PDALanguageEmptinessAnalysis {
  const PDALanguageEmptinessAnalysis();
}

class PDALanguageEmptinessFailure extends PDALanguageEmptinessAnalysis {
  const PDALanguageEmptinessFailure({
    required this.kind,
    required this.message,
    this.structuredMessage,
  });

  final PDALanguageEmptinessFailureKind kind;
  final String message;
  final StructuredMessage? structuredMessage;
}

/// One production application in a leftmost CFG derivation.
class CFGDerivationStep {
  CFGDerivationStep({
    required this.productionId,
    required List<String> productionLeft,
    required List<String> productionRight,
    required List<String> before,
    required List<String> after,
  }) : productionLeft = List<String>.unmodifiable(productionLeft),
       productionRight = List<String>.unmodifiable(productionRight),
       before = List<String>.unmodifiable(before),
       after = List<String>.unmodifiable(after);

  final String productionId;
  final List<String> productionLeft;
  final List<String> productionRight;
  final List<String> before;
  final List<String> after;
}

class PDALanguageEmptinessProof extends PDALanguageEmptinessAnalysis {
  PDALanguageEmptinessProof({
    required this.isEmpty,
    required this.acceptanceMode,
    required this.normalization,
    required this.grammar,
    required Set<String> productiveNonterminals,
    required List<String>? witnessSymbols,
    required this.witnessWord,
    required List<CFGDerivationStep> derivation,
    required this.witnessTrace,
  }) : productiveNonterminals = Set<String>.unmodifiable(
         productiveNonterminals,
       ),
       witnessSymbols = witnessSymbols == null
           ? null
           : List<String>.unmodifiable(witnessSymbols),
       derivation = List<CFGDerivationStep>.unmodifiable(derivation);

  final bool isEmpty;
  final PDAAcceptanceMode acceptanceMode;
  final PDANormalizationReport normalization;
  final Grammar grammar;
  final Set<String> productiveNonterminals;

  /// Atomic grammar terminals in the witness.
  ///
  /// Length is measured in terminal symbols, not Unicode code units. Thus a
  /// terminal such as `token` contributes one to [terminalSymbolLength].
  final List<String>? witnessSymbols;

  /// Simulator input obtained by concatenating [witnessSymbols].
  final String? witnessWord;
  final List<CFGDerivationStep> derivation;
  final PDASimulationResult? witnessTrace;

  PDA get normalizedPda => normalization.normalizedPda;

  int? get terminalSymbolLength => witnessSymbols?.length;
}

enum CFGShortestWitnessFailureKind {
  invalidGrammar,
  resourceLimit,
  cancelled,
  internalConsistency,
}

sealed class CFGShortestWitnessAnalysis {
  const CFGShortestWitnessAnalysis();
}

class CFGShortestWitnessFailure extends CFGShortestWitnessAnalysis {
  const CFGShortestWitnessFailure({
    required this.kind,
    required this.message,
    this.structuredMessage,
  });

  final CFGShortestWitnessFailureKind kind;
  final String message;
  final StructuredMessage? structuredMessage;
}

class CFGShortestWitnessProof extends CFGShortestWitnessAnalysis {
  CFGShortestWitnessProof({
    required this.isEmpty,
    required Set<String> productiveNonterminals,
    required List<String>? witnessSymbols,
    required List<CFGDerivationStep> derivation,
  }) : productiveNonterminals = Set<String>.unmodifiable(
         productiveNonterminals,
       ),
       witnessSymbols = witnessSymbols == null
           ? null
           : List<String>.unmodifiable(witnessSymbols),
       derivation = List<CFGDerivationStep>.unmodifiable(derivation);

  final bool isEmpty;
  final Set<String> productiveNonterminals;
  final List<String>? witnessSymbols;
  final List<CFGDerivationStep> derivation;
}

/// Computes CFG productivity while retaining a deterministic shortest witness.
class CFGShortestWitnessAnalyzer {
  const CFGShortestWitnessAnalyzer._();

  static CFGShortestWitnessAnalysis analyze(
    Grammar grammar, {
    int maxFixedPointUpdates = 1000000,
    int maxDerivationSteps = 100000,
    bool Function()? isCancelled,
  }) {
    if (maxFixedPointUpdates <= 0 || maxDerivationSteps <= 0) {
      return CFGShortestWitnessFailure(
        kind: CFGShortestWitnessFailureKind.invalidGrammar,
        message: 'CFG analysis limits must be greater than zero.',
        structuredMessage: CfgShortestWitnessMessages.invalidLimits(),
      );
    }
    if (isCancelled?.call() == true) {
      return CFGShortestWitnessFailure(
        kind: CFGShortestWitnessFailureKind.cancelled,
        message: 'CFG shortest-witness analysis was cancelled.',
        structuredMessage: CfgShortestWitnessMessages.cancelled(),
      );
    }

    final validationError = _validateGrammar(grammar);
    if (validationError != null) {
      return CFGShortestWitnessFailure(
        kind: CFGShortestWitnessFailureKind.invalidGrammar,
        message: validationError.message,
        structuredMessage: validationError.structuredMessage,
      );
    }

    final productions = grammar.productions.toList()..sort(_compareProductions);
    final best = <String, _WitnessChoice>{};
    var updateCount = 0;
    var changed = true;

    while (changed) {
      changed = false;
      for (final production in productions) {
        if (isCancelled?.call() == true) {
          return CFGShortestWitnessFailure(
            kind: CFGShortestWitnessFailureKind.cancelled,
            message: 'CFG shortest-witness analysis was cancelled.',
            structuredMessage: CfgShortestWitnessMessages.cancelled(),
          );
        }

        final candidate = _candidateFor(production, grammar, best);
        if (candidate == null) continue;

        final nonterminal = production.leftSide.single;
        final current = best[nonterminal];
        if (current == null || _compareChoices(candidate, current) < 0) {
          if (updateCount >= maxFixedPointUpdates) {
            return CFGShortestWitnessFailure(
              kind: CFGShortestWitnessFailureKind.resourceLimit,
              message:
                  'CFG productivity update limit exceeded '
                  '($maxFixedPointUpdates).',
              structuredMessage: CfgShortestWitnessMessages.productivityLimit(
                maxFixedPointUpdates,
              ),
            );
          }
          best[nonterminal] = candidate;
          updateCount++;
          changed = true;
        }
      }
    }

    final startChoice = best[grammar.startSymbol];
    if (startChoice == null) {
      return CFGShortestWitnessProof(
        isEmpty: true,
        productiveNonterminals: best.keys.toSet(),
        witnessSymbols: null,
        derivation: const [],
      );
    }

    final derivation = _buildLeftmostDerivation(
      grammar,
      best,
      maxDerivationSteps: maxDerivationSteps,
      isCancelled: isCancelled,
    );
    if (derivation is CFGShortestWitnessFailure) return derivation;
    final steps = derivation as List<CFGDerivationStep>;
    final derivedSymbols = steps.isEmpty
        ? <String>[grammar.startSymbol]
        : steps.last.after;
    if (!_listEquals(derivedSymbols, startChoice.symbols)) {
      return CFGShortestWitnessFailure(
        kind: CFGShortestWitnessFailureKind.internalConsistency,
        message: 'The reconstructed CFG derivation does not match its witness.',
        structuredMessage: CfgShortestWitnessMessages.witnessMismatch(),
      );
    }

    return CFGShortestWitnessProof(
      isEmpty: false,
      productiveNonterminals: best.keys.toSet(),
      witnessSymbols: startChoice.symbols,
      derivation: steps,
    );
  }

  static ({String message, StructuredMessage structuredMessage})?
  _validateGrammar(Grammar grammar) {
    if (!grammar.nonterminals.contains(grammar.startSymbol)) {
      return (
        message: 'The CFG start symbol must be a declared nonterminal.',
        structuredMessage: CfgShortestWitnessMessages.missingStartSymbol(),
      );
    }
    final ambiguousSymbols = grammar.terminals.intersection(
      grammar.nonterminals,
    );
    if (ambiguousSymbols.isNotEmpty) {
      return (
        message: 'CFG terminals and nonterminals must be disjoint.',
        structuredMessage: CfgShortestWitnessMessages.overlappingSymbolSets(),
      );
    }
    for (final production in grammar.productions) {
      if (production.leftSide.length != 1 ||
          !grammar.nonterminals.contains(production.leftSide.single)) {
        return (
          message:
              'Production ${production.id} must have one declared '
              'nonterminal on its left side.',
          structuredMessage: CfgShortestWitnessMessages.invalidProductionLeft(
            production.id,
          ),
        );
      }
      if ((production.isLambda && production.rightSide.isNotEmpty) ||
          (!production.isLambda && production.rightSide.isEmpty)) {
        return (
          message:
              'Production ${production.id} has inconsistent lambda metadata.',
          structuredMessage:
              CfgShortestWitnessMessages.inconsistentLambdaMetadata(
                production.id,
              ),
        );
      }
      final epsilonCount = production.rightSide.where(isEpsilonSymbol).length;
      if (epsilonCount > 0 && production.rightSide.length != 1) {
        final message =
            'Production ${production.id} mixes epsilon with other symbols.';
        return (
          message: message,
          structuredMessage: CfgShortestWitnessMessages.epsilonMixed(
            production.id,
          ),
        );
      }
      for (final symbol in production.rightSide) {
        if (!grammar.nonterminals.contains(symbol) &&
            !grammar.terminals.contains(symbol) &&
            !isEpsilonSymbol(symbol)) {
          return (
            message:
                'Production ${production.id} uses undeclared symbol $symbol.',
            structuredMessage: CfgShortestWitnessMessages.undeclaredSymbol(
              productionId: production.id,
              symbol: symbol,
            ),
          );
        }
      }
    }
    return null;
  }

  static _WitnessChoice? _candidateFor(
    Production production,
    Grammar grammar,
    Map<String, _WitnessChoice> best,
  ) {
    final symbols = <String>[];
    var height = 1;
    if (!production.isLambda) {
      for (final symbol in production.rightSide) {
        if (isEpsilonSymbol(symbol)) continue;
        if (grammar.nonterminals.contains(symbol)) {
          final child = best[symbol];
          if (child == null) return null;
          symbols.addAll(child.symbols);
          if (child.height + 1 > height) {
            height = child.height + 1;
          }
        } else {
          symbols.add(symbol);
        }
      }
    }
    return _WitnessChoice(
      production: production,
      symbols: List<String>.unmodifiable(symbols),
      height: height,
    );
  }

  static Object _buildLeftmostDerivation(
    Grammar grammar,
    Map<String, _WitnessChoice> best, {
    required int maxDerivationSteps,
    required bool Function()? isCancelled,
  }) {
    final sententialForm = <String>[grammar.startSymbol];
    final steps = <CFGDerivationStep>[];

    while (true) {
      if (isCancelled?.call() == true) {
        return CFGShortestWitnessFailure(
          kind: CFGShortestWitnessFailureKind.cancelled,
          message: 'CFG derivation reconstruction was cancelled.',
          structuredMessage: CfgShortestWitnessMessages.cancelled(),
        );
      }
      final index = sententialForm.indexWhere(grammar.nonterminals.contains);
      if (index < 0) return steps;
      if (steps.length >= maxDerivationSteps) {
        return CFGShortestWitnessFailure(
          kind: CFGShortestWitnessFailureKind.resourceLimit,
          message:
              'CFG derivation step limit exceeded '
              '($maxDerivationSteps).',
          structuredMessage: CfgShortestWitnessMessages.derivationLimit(
            maxDerivationSteps,
          ),
        );
      }

      final nonterminal = sententialForm[index];
      final choice = best[nonterminal];
      if (choice == null) {
        return CFGShortestWitnessFailure(
          kind: CFGShortestWitnessFailureKind.internalConsistency,
          message:
              'No productive choice exists for $nonterminal during '
              'derivation reconstruction.',
          structuredMessage: CfgShortestWitnessMessages.missingProductiveChoice(
            nonterminal,
          ),
        );
      }
      final production = choice.production;
      final replacement = production.isLambda
          ? const <String>[]
          : production.rightSide.where((symbol) => !isEpsilonSymbol(symbol));
      final before = List<String>.of(sententialForm);
      sententialForm.replaceRange(index, index + 1, replacement);
      steps.add(
        CFGDerivationStep(
          productionId: production.id,
          productionLeft: production.leftSide,
          productionRight: production.isLambda
              ? const <String>[]
              : production.rightSide,
          before: before,
          after: sententialForm,
        ),
      );
    }
  }
}

/// Decides PDA language emptiness through mode-aware normalization and a CFG.
class PDALanguageEmptinessAnalyzer {
  const PDALanguageEmptinessAnalyzer._();

  static PDALanguageEmptinessAnalysis analyze(
    PDA pda, {
    required PDAAcceptanceMode acceptanceMode,
    PDALanguageEmptinessLimits limits = const PDALanguageEmptinessLimits(),
    bool Function()? isCancelled,
    bool replayWitness = true,
  }) {
    if (limits.maxGeneratedProductions <= 0 ||
        limits.maxFixedPointUpdates <= 0 ||
        limits.maxDerivationSteps <= 0) {
      return PDALanguageEmptinessFailure(
        kind: PDALanguageEmptinessFailureKind.invalidInput,
        message: 'PDA language-analysis limits must be greater than zero.',
        structuredMessage: PdaLanguageEmptinessMessages.invalidLimits(),
      );
    }
    if (isCancelled?.call() == true) {
      return PDALanguageEmptinessFailure(
        kind: PDALanguageEmptinessFailureKind.cancelled,
        message: 'PDA language-emptiness analysis was cancelled.',
        structuredMessage: PdaLanguageEmptinessMessages.cancelled(),
      );
    }

    // The triple CFG construction derives runs that pop the initial stack.
    // Normalizing to combined final-and-empty acceptance preserves the source
    // mode while satisfying that construction's precondition.
    final normalization = PDANormalizer.normalize(
      pda,
      sourceMode: acceptanceMode,
      targetForm: PDANormalForm.finalStateAndEmptyStackAndSinglePop,
    );
    if (normalization.isFailure) {
      return PDALanguageEmptinessFailure(
        kind: PDALanguageEmptinessFailureKind.normalizationFailed,
        message: normalization.error!,
        structuredMessage: normalization.structuredError,
      );
    }

    final report = normalization.data!;
    final conversion = PDAtoCFGConverter.convert(
      report.normalizedPda,
      maxGeneratedProductions: limits.maxGeneratedProductions,
      isCancelled: isCancelled,
    );
    if (conversion.isFailure) {
      final error = conversion.error!;
      if (error == PDAtoCFGConverter.cancellationError) {
        return PDALanguageEmptinessFailure(
          kind: PDALanguageEmptinessFailureKind.cancelled,
          message: error,
          structuredMessage: conversion.structuredError,
        );
      }
      if (error.startsWith(PDAtoCFGConverter.productionLimitErrorPrefix)) {
        return PDALanguageEmptinessFailure(
          kind: PDALanguageEmptinessFailureKind.resourceLimit,
          message: error,
          structuredMessage: conversion.structuredError,
        );
      }
      return PDALanguageEmptinessFailure(
        kind: PDALanguageEmptinessFailureKind.conversionFailed,
        message: error,
        structuredMessage: conversion.structuredError,
      );
    }

    final grammar = conversion.data!.grammar;
    final cfgAnalysis = CFGShortestWitnessAnalyzer.analyze(
      grammar,
      maxFixedPointUpdates: limits.maxFixedPointUpdates,
      maxDerivationSteps: limits.maxDerivationSteps,
      isCancelled: isCancelled,
    );
    if (cfgAnalysis is CFGShortestWitnessFailure) {
      return PDALanguageEmptinessFailure(
        kind: switch (cfgAnalysis.kind) {
          CFGShortestWitnessFailureKind.cancelled =>
            PDALanguageEmptinessFailureKind.cancelled,
          CFGShortestWitnessFailureKind.resourceLimit =>
            PDALanguageEmptinessFailureKind.resourceLimit,
          CFGShortestWitnessFailureKind.invalidGrammar =>
            PDALanguageEmptinessFailureKind.conversionFailed,
          CFGShortestWitnessFailureKind.internalConsistency =>
            PDALanguageEmptinessFailureKind.internalConsistency,
        },
        message: cfgAnalysis.message,
        structuredMessage: cfgAnalysis.structuredMessage,
      );
    }

    final cfgProof = cfgAnalysis as CFGShortestWitnessProof;
    if (cfgProof.isEmpty) {
      return PDALanguageEmptinessProof(
        isEmpty: true,
        acceptanceMode: acceptanceMode,
        normalization: report,
        grammar: grammar,
        productiveNonterminals: cfgProof.productiveNonterminals,
        witnessSymbols: null,
        witnessWord: null,
        derivation: const [],
        witnessTrace: null,
      );
    }

    final witnessSymbols = cfgProof.witnessSymbols!;
    final witnessWord = witnessSymbols.join();
    PDASimulationResult? trace;
    if (replayWitness) {
      final replay = PDASimulator.simulateNPDA(
        pda,
        witnessWord,
        mode: acceptanceMode,
        stepByStep: true,
      );
      if (replay.isFailure || replay.data?.accepted != true) {
        final detail = replay.error ?? replay.data?.errorMessage ?? 'rejected';
        return PDALanguageEmptinessFailure(
          kind: PDALanguageEmptinessFailureKind.internalConsistency,
          message:
              'The CFG witness could not be replayed by the source PDA: '
              '$detail.',
          structuredMessage:
              replay.structuredError ??
              replay.data?.structuredMessage ??
              PdaLanguageEmptinessMessages.witnessReplayFailed(),
        );
      }
      trace = replay.data;
    }

    return PDALanguageEmptinessProof(
      isEmpty: false,
      acceptanceMode: acceptanceMode,
      normalization: report,
      grammar: grammar,
      productiveNonterminals: cfgProof.productiveNonterminals,
      witnessSymbols: witnessSymbols,
      witnessWord: witnessWord,
      derivation: cfgProof.derivation,
      witnessTrace: trace,
    );
  }
}

class _WitnessChoice {
  const _WitnessChoice({
    required this.production,
    required this.symbols,
    required this.height,
  });

  final Production production;
  final List<String> symbols;
  final int height;
}

int _compareChoices(_WitnessChoice left, _WitnessChoice right) {
  final byLength = left.symbols.length.compareTo(right.symbols.length);
  if (byLength != 0) return byLength;
  for (var index = 0; index < left.symbols.length; index++) {
    final bySymbol = left.symbols[index].compareTo(right.symbols[index]);
    if (bySymbol != 0) return bySymbol;
  }
  final byHeight = left.height.compareTo(right.height);
  if (byHeight != 0) return byHeight;
  return _compareProductions(left.production, right.production);
}

int _compareProductions(Production left, Production right) {
  final byOrder = left.order.compareTo(right.order);
  if (byOrder != 0) return byOrder;
  final byId = left.id.compareTo(right.id);
  if (byId != 0) return byId;
  final byLeft = left.leftSide
      .join('\u0000')
      .compareTo(right.leftSide.join('\u0000'));
  if (byLeft != 0) return byLeft;
  return left.rightSide
      .join('\u0000')
      .compareTo(right.rightSide.join('\u0000'));
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
