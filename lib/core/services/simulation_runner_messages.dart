import '../messages/structured_message.dart';

/// Locale-neutral failures produced by simulation runner infrastructure.
abstract final class SimulationRunnerMessages {
  static StructuredMessage startFailed() => _failure('start-failed');

  static StructuredMessage executionFailed() => _failure('execution-failed');

  static StructuredMessage workerFailed() => _failure('worker-failed');

  static StructuredMessage workerExitedUnexpectedly() =>
      _failure('worker-exited-unexpectedly');

  static StructuredMessage invalidWorkerResponse() =>
      _failure('invalid-worker-response');

  static StructuredMessage _failure(String code) => StructuredMessage(
    namespace: 'service.simulation-runner',
    code: code,
    category: StructuredMessageCategory.simulation,
    severity: StructuredMessageSeverity.error,
  );
}
