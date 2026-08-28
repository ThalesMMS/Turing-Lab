import 'pumping_decomposition.dart';
import 'pumping_lemma_problem.dart';
import 'pumping_lemma_progress.dart';
import 'pumping_lemma_session.dart';

sealed class PumpingLemmaDocument {
  const PumpingLemmaDocument({
    required this.problem,
    required this.progress,
  });

  factory PumpingLemmaDocument.fromJson(Map<String, Object?> json) {
    final schema = Map<String, Object?>.from(json['schema']! as Map);
    if (schema['id'] != 'turing-lab.pumping-lemma' || schema['version'] != 1) {
      throw const FormatException('Unsupported pumping lemma schema.');
    }
    final problem = PumpingLemmaProblem.fromJson(
      Map<String, Object?>.from(json['problem']! as Map),
    );
    final progress = PumpingLemmaEnvironmentProgress.fromJson(
      Map<String, Object?>.from(json['progress']! as Map),
    );
    final session = Map<String, Object?>.from(json['session']! as Map);
    return switch (problem.theorem) {
      PumpingLemmaTheorem.regular => RegularPumpingLemmaDocument(
          problem: problem,
          session: PumpingLemmaSession<RegularPumpingDecomposition>.fromJson(
            session,
          ),
          progress: progress,
        ),
      PumpingLemmaTheorem.contextFree => ContextFreePumpingLemmaDocument(
          problem: problem,
          session:
              PumpingLemmaSession<ContextFreePumpingDecomposition>.fromJson(
            session,
          ),
          progress: progress,
        ),
    };
  }

  final PumpingLemmaProblem problem;
  final PumpingLemmaEnvironmentProgress progress;

  PumpingLemmaTheorem get theorem => problem.theorem;
  PumpingLemmaSession<PumpingDecomposition> get erasedSession;

  Map<String, Object?> toJson() => {
        'schema': {'id': 'turing-lab.pumping-lemma', 'version': 1},
        'problem': problem.toJson(),
        'session': erasedSession.toJson(),
        'progress': progress.toJson(),
      };
}

final class RegularPumpingLemmaDocument extends PumpingLemmaDocument {
  RegularPumpingLemmaDocument({
    required PumpingLemmaProblem problem,
    required this.session,
    required super.progress,
  }) : super(problem: problem) {
    if (problem.theorem != PumpingLemmaTheorem.regular ||
        session.theorem != PumpingLemmaTheorem.regular) {
      throw ArgumentError('A regular document requires regular state.');
    }
  }

  final PumpingLemmaSession<RegularPumpingDecomposition> session;

  @override
  PumpingLemmaSession<PumpingDecomposition> get erasedSession =>
      PumpingLemmaSession<PumpingDecomposition>.fromJson(session.toJson());
}

final class ContextFreePumpingLemmaDocument extends PumpingLemmaDocument {
  ContextFreePumpingLemmaDocument({
    required PumpingLemmaProblem problem,
    required this.session,
    required super.progress,
  }) : super(problem: problem) {
    if (problem.theorem != PumpingLemmaTheorem.contextFree ||
        session.theorem != PumpingLemmaTheorem.contextFree) {
      throw ArgumentError('A context-free document requires CFL state.');
    }
  }

  final PumpingLemmaSession<ContextFreePumpingDecomposition> session;

  @override
  PumpingLemmaSession<PumpingDecomposition> get erasedSession =>
      PumpingLemmaSession<PumpingDecomposition>.fromJson(session.toJson());
}
