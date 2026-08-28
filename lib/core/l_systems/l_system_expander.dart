import 'dart:async';
import 'dart:math' as math;

import '../messages/structured_message.dart';
import 'l_system_model.dart';

final class LSystemCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
}

final class LSystemExpansionLimits {
  const LSystemExpansionLimits({
    this.maximumGenerations = 200,
    this.maximumSymbols = 1000000,
    this.maximumEstimatedBytes = 64 * 1024 * 1024,
    this.maximumElapsed = const Duration(seconds: 5),
    this.retainGenerations = true,
    this.maximumRetainedGenerations = 32,
    this.cancellationToken,
    this.cancellationCheckpoint,
    this.elapsedProvider,
  });

  final int maximumGenerations;
  final int maximumSymbols;
  final int maximumEstimatedBytes;
  final Duration maximumElapsed;
  final bool retainGenerations;
  final int maximumRetainedGenerations;
  final LSystemCancellationToken? cancellationToken;
  final bool Function(int generation, int processedSymbols)?
  cancellationCheckpoint;
  final Duration Function()? elapsedProvider;

  void validate() {
    if (maximumGenerations < 0 ||
        maximumSymbols < 0 ||
        maximumEstimatedBytes < 0 ||
        maximumElapsed.isNegative ||
        maximumRetainedGenerations < 0) {
      throw ArgumentError('L-system expansion limits must be non-negative.');
    }
  }
}

enum LSystemExpansionDiagnosticCode {
  duplicateProductionId,
  duplicatePredecessor,
  unsupportedVariant,
}

final class LSystemExpansionDiagnostic {
  const LSystemExpansionDiagnostic({
    required this.code,
    required this.structuredMessage,
    this.subject,
  });

  final LSystemExpansionDiagnosticCode code;
  final StructuredMessage structuredMessage;
  final String? subject;
}

final class LSystemProvenanceRun {
  const LSystemProvenanceRun({
    required this.sourceIndex,
    required this.outputStart,
    required this.outputEnd,
    this.productionId,
  });

  final int sourceIndex;
  final int outputStart;
  final int outputEnd;
  final String? productionId;
}

final class LSystemGeneration {
  LSystemGeneration({
    required this.index,
    required this.word,
    Iterable<LSystemProvenanceRun> provenance = const [],
  }) : provenance = List<LSystemProvenanceRun>.unmodifiable(provenance);

  final int index;
  final LSystemWord word;
  final List<LSystemProvenanceRun> provenance;
}

sealed class LSystemExpansionOutcome {
  const LSystemExpansionOutcome({
    required this.finalGeneration,
    required this.retainedGenerations,
  });

  final LSystemGeneration finalGeneration;
  final List<LSystemGeneration> retainedGenerations;
}

final class LSystemExpansionCompleted extends LSystemExpansionOutcome {
  const LSystemExpansionCompleted({
    required super.finalGeneration,
    required super.retainedGenerations,
  });
}

enum LSystemExpansionBoundKind {
  generations,
  symbols,
  estimatedMemory,
  elapsedTime,
}

final class LSystemExpansionBounded extends LSystemExpansionOutcome {
  const LSystemExpansionBounded({
    required super.finalGeneration,
    required super.retainedGenerations,
    required this.kind,
    required this.maximum,
    required this.estimate,
  });

  final LSystemExpansionBoundKind kind;
  final int maximum;
  final int estimate;
}

final class LSystemExpansionCancelled extends LSystemExpansionOutcome {
  const LSystemExpansionCancelled({
    required super.finalGeneration,
    required super.retainedGenerations,
    required this.processedSymbols,
  });

  final int processedSymbols;
}

final class LSystemExpansionInvalid extends LSystemExpansionOutcome {
  LSystemExpansionInvalid({
    required super.finalGeneration,
    required super.retainedGenerations,
    required Iterable<LSystemExpansionDiagnostic> diagnostics,
  }) : diagnostics = List<LSystemExpansionDiagnostic>.unmodifiable(diagnostics);

  final List<LSystemExpansionDiagnostic> diagnostics;
}

final class LSystemExpander {
  const LSystemExpander();

  LSystemExpansionOutcome expand(
    LSystemDocument system, {
    int? generations,
    LSystemExpansionLimits limits = const LSystemExpansionLimits(),
  }) {
    limits.validate();
    final target = generations ?? system.iterations;
    final initial = LSystemGeneration(index: 0, word: system.axiom);
    final retained = <LSystemGeneration>[if (limits.retainGenerations) initial];
    final invalid = _validate(system, initial, retained);
    if (invalid != null) return invalid;
    if (target < 0 || target > limits.maximumGenerations) {
      return LSystemExpansionBounded(
        finalGeneration: initial,
        retainedGenerations: retained,
        kind: LSystemExpansionBoundKind.generations,
        maximum: limits.maximumGenerations,
        estimate: target,
      );
    }
    final bySymbol = _indexProductions(system.productions);
    final random = math.Random(system.randomSeed);
    final stopwatch = Stopwatch()..start();
    var current = initial;
    for (var index = 1; index <= target; index++) {
      final estimate = _estimate(current.word, bySymbol);
      final bounded = _bounded(current, retained, estimate, limits, stopwatch);
      if (bounded != null) return bounded;
      final output = <String>[];
      final provenance = <LSystemProvenanceRun>[];
      for (
        var sourceIndex = 0;
        sourceIndex < current.word.symbols.length;
        sourceIndex++
      ) {
        if (sourceIndex % 256 == 0) {
          final timeBound = _timeBounded(current, retained, limits, stopwatch);
          if (timeBound != null) return timeBound;
        }
        if (_cancelled(limits, index, sourceIndex)) {
          return LSystemExpansionCancelled(
            finalGeneration: current,
            retainedGenerations: retained,
            processedSymbols: sourceIndex,
          );
        }
        final symbol = current.word.symbols[sourceIndex];
        final production = _selectProduction(
          system,
          current.word,
          sourceIndex,
          bySymbol[symbol] ?? const [],
          random,
        );
        final replacement = production?.successor.symbols ?? [symbol];
        final start = output.length;
        output.addAll(replacement);
        provenance.add(
          LSystemProvenanceRun(
            sourceIndex: sourceIndex,
            outputStart: start,
            outputEnd: output.length,
            productionId: production?.id,
          ),
        );
      }
      current = LSystemGeneration(
        index: index,
        word: LSystemWord(output),
        provenance: provenance,
      );
      _retain(retained, current, limits);
    }
    return LSystemExpansionCompleted(
      finalGeneration: current,
      retainedGenerations: List.unmodifiable(retained),
    );
  }

  Future<LSystemExpansionOutcome> expandAsync(
    LSystemDocument system, {
    int? generations,
    LSystemExpansionLimits limits = const LSystemExpansionLimits(),
    int yieldEverySymbols = 512,
  }) async {
    limits.validate();
    if (yieldEverySymbols <= 0) {
      throw ArgumentError.value(
        yieldEverySymbols,
        'yieldEverySymbols',
        'Must be positive.',
      );
    }
    final target = generations ?? system.iterations;
    final initial = LSystemGeneration(index: 0, word: system.axiom);
    final retained = <LSystemGeneration>[if (limits.retainGenerations) initial];
    final invalid = _validate(system, initial, retained);
    if (invalid != null) return invalid;
    if (target < 0 || target > limits.maximumGenerations) {
      return LSystemExpansionBounded(
        finalGeneration: initial,
        retainedGenerations: retained,
        kind: LSystemExpansionBoundKind.generations,
        maximum: limits.maximumGenerations,
        estimate: target,
      );
    }
    final bySymbol = _indexProductions(system.productions);
    final random = math.Random(system.randomSeed);
    final stopwatch = Stopwatch()..start();
    var current = initial;
    for (var index = 1; index <= target; index++) {
      final estimate = _estimate(current.word, bySymbol);
      final bounded = _bounded(current, retained, estimate, limits, stopwatch);
      if (bounded != null) return bounded;
      final output = <String>[];
      final provenance = <LSystemProvenanceRun>[];
      for (
        var sourceIndex = 0;
        sourceIndex < current.word.symbols.length;
        sourceIndex++
      ) {
        if (sourceIndex > 0 && sourceIndex % yieldEverySymbols == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        if (sourceIndex % yieldEverySymbols == 0) {
          final timeBound = _timeBounded(current, retained, limits, stopwatch);
          if (timeBound != null) return timeBound;
        }
        if (_cancelled(limits, index, sourceIndex)) {
          return LSystemExpansionCancelled(
            finalGeneration: current,
            retainedGenerations: retained,
            processedSymbols: sourceIndex,
          );
        }
        final symbol = current.word.symbols[sourceIndex];
        final production = _selectProduction(
          system,
          current.word,
          sourceIndex,
          bySymbol[symbol] ?? const [],
          random,
        );
        final replacement = production?.successor.symbols ?? [symbol];
        final start = output.length;
        output.addAll(replacement);
        provenance.add(
          LSystemProvenanceRun(
            sourceIndex: sourceIndex,
            outputStart: start,
            outputEnd: output.length,
            productionId: production?.id,
          ),
        );
      }
      current = LSystemGeneration(
        index: index,
        word: LSystemWord(output),
        provenance: provenance,
      );
      _retain(retained, current, limits);
    }
    return LSystemExpansionCompleted(
      finalGeneration: current,
      retainedGenerations: List.unmodifiable(retained),
    );
  }

  static LSystemExpansionInvalid? _validate(
    LSystemDocument system,
    LSystemGeneration initial,
    List<LSystemGeneration> retained,
  ) {
    final diagnostics = <LSystemExpansionDiagnostic>[];
    final ids = <String>{};
    for (final production in system.productions) {
      if (!ids.add(production.id)) {
        diagnostics.add(
          LSystemExpansionDiagnostic(
            code: LSystemExpansionDiagnosticCode.duplicateProductionId,
            structuredMessage: StructuredMessage(
              namespace: 'l-system.expansion',
              code: 'duplicate-production-id',
              category: StructuredMessageCategory.validation,
              severity: StructuredMessageSeverity.error,
              arguments: {
                'production': StructuredMessageArgument.identifier(
                  production.id,
                  role: 'production-id',
                ),
              },
              source: StructuredMessageSource(
                kind: 'l-system-production',
                identifier: production.id,
              ),
            ),
            subject: production.id,
          ),
        );
      }
    }
    for (final variant in system.unsupportedVariants) {
      diagnostics.add(
        LSystemExpansionDiagnostic(
          code: LSystemExpansionDiagnosticCode.unsupportedVariant,
          structuredMessage: StructuredMessage(
            namespace: 'l-system.expansion',
            code: 'unsupported-variant',
            category: StructuredMessageCategory.validation,
            severity: StructuredMessageSeverity.error,
            arguments: {
              'variant': StructuredMessageArgument.outcome(
                variant.name,
                role: 'l-system-variant',
              ),
            },
            source: StructuredMessageSource(
              kind: 'l-system-variant',
              identifier: variant.name,
            ),
          ),
          subject: variant.name,
        ),
      );
    }
    if (diagnostics.isEmpty) return null;
    return LSystemExpansionInvalid(
      finalGeneration: initial,
      retainedGenerations: retained,
      diagnostics: diagnostics,
    );
  }

  static int _estimate(
    LSystemWord word,
    Map<String, List<LSystemProduction>> bySymbol,
  ) {
    var result = 0;
    for (final symbol in word.symbols) {
      final candidates = bySymbol[symbol];
      result += candidates == null || candidates.isEmpty
          ? 1
          : candidates
                .map((production) => production.successor.length)
                .reduce(math.max);
      if (result > 0x7fffffff) return 0x7fffffff;
    }
    return result;
  }

  static Map<String, List<LSystemProduction>> _indexProductions(
    Iterable<LSystemProduction> productions,
  ) {
    final result = <String, List<LSystemProduction>>{};
    for (final production in productions) {
      result.putIfAbsent(production.predecessor, () => []).add(production);
    }
    return result;
  }

  static LSystemProduction? _selectProduction(
    LSystemDocument system,
    LSystemWord source,
    int sourceIndex,
    List<LSystemProduction> candidates,
    math.Random random,
  ) {
    final matching = candidates
        .where(
          (production) => _matchesContext(
            source.symbols,
            sourceIndex,
            production,
            system.ignoredContextSymbols,
          ),
        )
        .toList(growable: false);
    if (matching.isEmpty) return null;
    if (matching.length == 1) return matching.single;
    final total = matching.fold<double>(
      0,
      (sum, production) => sum + production.weight,
    );
    var selected = random.nextDouble() * total;
    for (final production in matching) {
      selected -= production.weight;
      if (selected < 0) return production;
    }
    return matching.last;
  }

  static bool _matchesContext(
    List<String> source,
    int center,
    LSystemProduction production,
    Set<String> ignored,
  ) {
    var sourceIndex = center - 1;
    for (
      var contextIndex = production.leftContext.length - 1;
      contextIndex >= 0;
      contextIndex--
    ) {
      while (sourceIndex >= 0 && ignored.contains(source[sourceIndex])) {
        sourceIndex--;
      }
      if (sourceIndex < 0 ||
          source[sourceIndex] != production.leftContext.symbols[contextIndex]) {
        return false;
      }
      sourceIndex--;
    }
    sourceIndex = center + 1;
    for (final expected in production.rightContext.symbols) {
      while (sourceIndex < source.length &&
          ignored.contains(source[sourceIndex])) {
        sourceIndex++;
      }
      if (sourceIndex >= source.length || source[sourceIndex] != expected) {
        return false;
      }
      sourceIndex++;
    }
    return true;
  }

  static LSystemExpansionBounded? _bounded(
    LSystemGeneration current,
    List<LSystemGeneration> retained,
    int estimate,
    LSystemExpansionLimits limits,
    Stopwatch stopwatch,
  ) {
    if (estimate > limits.maximumSymbols) {
      return LSystemExpansionBounded(
        finalGeneration: current,
        retainedGenerations: List.unmodifiable(retained),
        kind: LSystemExpansionBoundKind.symbols,
        maximum: limits.maximumSymbols,
        estimate: estimate,
      );
    }
    final estimatedBytes = estimate * 16;
    if (estimatedBytes > limits.maximumEstimatedBytes) {
      return LSystemExpansionBounded(
        finalGeneration: current,
        retainedGenerations: List.unmodifiable(retained),
        kind: LSystemExpansionBoundKind.estimatedMemory,
        maximum: limits.maximumEstimatedBytes,
        estimate: estimatedBytes,
      );
    }
    final elapsed = limits.elapsedProvider?.call() ?? stopwatch.elapsed;
    if (elapsed > limits.maximumElapsed) {
      return LSystemExpansionBounded(
        finalGeneration: current,
        retainedGenerations: List.unmodifiable(retained),
        kind: LSystemExpansionBoundKind.elapsedTime,
        maximum: limits.maximumElapsed.inMicroseconds,
        estimate: elapsed.inMicroseconds,
      );
    }
    return null;
  }

  static LSystemExpansionBounded? _timeBounded(
    LSystemGeneration current,
    List<LSystemGeneration> retained,
    LSystemExpansionLimits limits,
    Stopwatch stopwatch,
  ) {
    final elapsed = limits.elapsedProvider?.call() ?? stopwatch.elapsed;
    if (elapsed <= limits.maximumElapsed) return null;
    return LSystemExpansionBounded(
      finalGeneration: current,
      retainedGenerations: List.unmodifiable(retained),
      kind: LSystemExpansionBoundKind.elapsedTime,
      maximum: limits.maximumElapsed.inMicroseconds,
      estimate: elapsed.inMicroseconds,
    );
  }

  static bool _cancelled(
    LSystemExpansionLimits limits,
    int generation,
    int processed,
  ) =>
      (limits.cancellationToken?.isCancelled ?? false) ||
      (limits.cancellationCheckpoint?.call(generation, processed) ?? false);

  static void _retain(
    List<LSystemGeneration> retained,
    LSystemGeneration generation,
    LSystemExpansionLimits limits,
  ) {
    if (!limits.retainGenerations || limits.maximumRetainedGenerations == 0) {
      return;
    }
    retained.add(generation);
    while (retained.length > limits.maximumRetainedGenerations) {
      retained.removeAt(0);
    }
  }
}
