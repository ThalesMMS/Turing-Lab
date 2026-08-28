import 'dart:collection';

import 'phrase_structure_grammar.dart';
import 'production_application.dart';
import 'symbol_sequence.dart';
import 'user_derivation_session.dart';

enum UserDerivationHintOutcome {
  suggested,
  noSuggestion,
  boundedUnknown,
  cancelled,
  invalidSession,
}

enum UserDerivationHintLimit {
  depth,
  expandedForms,
  visitedForms,
  frontier,
  symbolCount,
  time,
}

class UserDerivationHintLimits {
  const UserDerivationHintLimits({
    this.maxDepth = 24,
    this.maxExpandedForms = 10000,
    this.maxVisitedForms = 20000,
    this.maxFrontierSize = 5000,
    this.maxSymbolCount = 128,
    this.timeLimit = const Duration(seconds: 3),
    this.yieldEvery = 64,
  });

  final int maxDepth;
  final int maxExpandedForms;
  final int maxVisitedForms;
  final int maxFrontierSize;
  final int maxSymbolCount;
  final Duration timeLimit;
  final int yieldEvery;

  bool get isValid =>
      maxDepth >= 0 &&
      maxExpandedForms >= 0 &&
      maxVisitedForms > 0 &&
      maxFrontierSize > 0 &&
      maxSymbolCount >= 0 &&
      !timeLimit.isNegative &&
      yieldEvery > 0;
}

class UserDerivationHintCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class UserDerivationHintStatistics {
  const UserDerivationHintStatistics({
    required this.expandedForms,
    required this.visitedForms,
    required this.frontierSize,
    required this.frontierPeak,
    required this.currentDepth,
    required this.elapsed,
  });

  final int expandedForms;
  final int visitedForms;
  final int frontierSize;
  final int frontierPeak;
  final int currentDepth;
  final Duration elapsed;

  Map<String, Object> toJson() => {
        'expandedForms': expandedForms,
        'visitedForms': visitedForms,
        'frontierSize': frontierSize,
        'frontierPeak': frontierPeak,
        'currentDepth': currentDepth,
        'elapsedMicroseconds': elapsed.inMicroseconds,
      };
}

class UserDerivationHintProgress {
  const UserDerivationHintProgress(this.statistics);

  final UserDerivationHintStatistics statistics;
}

class UserDerivationHintResult {
  UserDerivationHintResult({
    required this.outcome,
    required this.statistics,
    required List<UserDerivationStep> witness,
    this.suggestion,
    this.limit,
  }) : witness = List<UserDerivationStep>.unmodifiable(witness);

  final UserDerivationHintOutcome outcome;
  final UserDerivationHintStatistics statistics;
  final ProductionApplication? suggestion;
  final List<UserDerivationStep> witness;
  final UserDerivationHintLimit? limit;

  Map<String, Object?> toJson() => {
        'outcome': outcome.name,
        'statistics': statistics.toJson(),
        'suggestion': suggestion == null
            ? null
            : {
                'productionId': suggestion!.production.id,
                'startIndex': suggestion!.occurrence.startIndex,
                'occurrenceIndex': suggestion!.occurrence.occurrenceIndex,
              },
        'witness': witness.map((step) => step.toJson()).toList(growable: false),
        'limit': limit?.name,
      };
}

abstract final class UserDerivationHintSearch {
  static Future<UserDerivationHintResult> run({
    required UserDerivationSession session,
    required PhraseStructureGrammar grammar,
    UserDerivationHintLimits limits = const UserDerivationHintLimits(),
    UserDerivationHintCancellationToken? cancellationToken,
    void Function(UserDerivationHintProgress progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final queue = ListQueue<_HintNode>();
    final visited = <String>{session.currentForm.stableKey};
    var expanded = 0;
    var frontierPeak = 1;
    var currentDepth = 0;
    UserDerivationHintLimit? reachedLimit;

    UserDerivationHintStatistics statistics() => UserDerivationHintStatistics(
          expandedForms: expanded,
          visitedForms: visited.length,
          frontierSize: queue.length,
          frontierPeak: frontierPeak,
          currentDepth: currentDepth,
          elapsed: stopwatch.elapsed,
        );

    UserDerivationHintResult result(
      UserDerivationHintOutcome outcome, {
      ProductionApplication? suggestion,
      List<UserDerivationStep> witness = const <UserDerivationStep>[],
    }) {
      stopwatch.stop();
      return UserDerivationHintResult(
        outcome: outcome,
        statistics: statistics(),
        suggestion: suggestion,
        witness: witness,
        limit: reachedLimit,
      );
    }

    if (!limits.isValid ||
        !session.sourceMatches(grammar) ||
        session.status == UserDerivationStatus.invalidated) {
      return result(UserDerivationHintOutcome.invalidSession);
    }
    if (session.status == UserDerivationStatus.success) {
      return result(UserDerivationHintOutcome.noSuggestion);
    }
    if (session.currentForm.length > limits.maxSymbolCount) {
      reachedLimit = UserDerivationHintLimit.symbolCount;
      return result(UserDerivationHintOutcome.boundedUnknown);
    }
    queue.add(
      _HintNode(
        form: session.currentForm,
        path: const <UserDerivationStep>[],
        first: null,
      ),
    );

    while (queue.isNotEmpty) {
      if (cancellationToken?.isCancelled == true) {
        return result(UserDerivationHintOutcome.cancelled);
      }
      if (stopwatch.elapsed >= limits.timeLimit) {
        reachedLimit = UserDerivationHintLimit.time;
        return result(UserDerivationHintOutcome.boundedUnknown);
      }
      if (expanded >= limits.maxExpandedForms) {
        reachedLimit = UserDerivationHintLimit.expandedForms;
        return result(UserDerivationHintOutcome.boundedUnknown);
      }
      final node = queue.removeFirst();
      currentDepth = node.path.length;
      final challengeLimit = session.challenge?.maxSteps;
      if (challengeLimit != null &&
          session.cursor + node.path.length >= challengeLimit) {
        continue;
      }
      final applications = userDerivationApplicationsFor(
        session,
        grammar,
        node.form,
      );
      if (applications.isEmpty) continue;
      if (node.path.length >= limits.maxDepth) {
        reachedLimit ??= UserDerivationHintLimit.depth;
        continue;
      }
      expanded++;
      for (final application in applications) {
        final step = UserDerivationStep(
          productionId: application.production.id,
          startIndex: application.occurrence.startIndex,
          occurrenceIndex: application.occurrence.occurrenceIndex,
          before: application.before,
          after: application.after,
        );
        final path = <UserDerivationStep>[...node.path, step];
        final first = node.first ?? application;
        if (application.after == session.target) {
          return result(
            UserDerivationHintOutcome.suggested,
            suggestion: first,
            witness: path,
          );
        }
        if (application.after.length > limits.maxSymbolCount) {
          reachedLimit ??= UserDerivationHintLimit.symbolCount;
          continue;
        }
        final key = application.after.stableKey;
        if (!visited.add(key)) continue;
        if (visited.length > limits.maxVisitedForms) {
          visited.remove(key);
          reachedLimit ??= UserDerivationHintLimit.visitedForms;
          continue;
        }
        if (queue.length >= limits.maxFrontierSize) {
          reachedLimit ??= UserDerivationHintLimit.frontier;
          continue;
        }
        queue.add(_HintNode(form: application.after, path: path, first: first));
        if (queue.length > frontierPeak) frontierPeak = queue.length;
      }
      if (expanded % limits.yieldEvery == 0) {
        onProgress?.call(UserDerivationHintProgress(statistics()));
        await Future<void>.delayed(Duration.zero);
      }
    }
    return result(
      reachedLimit == null
          ? UserDerivationHintOutcome.noSuggestion
          : UserDerivationHintOutcome.boundedUnknown,
    );
  }
}

class _HintNode {
  const _HintNode({
    required this.form,
    required this.path,
    required this.first,
  });

  final GrammarSymbolSequence form;
  final List<UserDerivationStep> path;
  final ProductionApplication? first;
}
