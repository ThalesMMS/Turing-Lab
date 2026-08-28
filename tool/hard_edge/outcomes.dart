import 'package:turing_lab/core/batch_execution/batch_execution_models.dart';

/// Shared outcome vocabulary used by generated cases and oracle comparisons.
///
/// Every [BatchOutcomeCode] has a distinct value here. In particular, resource
/// exhaustion, cancellation, and stale requests are never folded into
/// rejection.
enum VerificationOutcomeCode {
  accepted,
  rejected,
  output,
  undefinedTransition,
  conflict,
  invalidInput,
  boundedUnknown,
  timeout,
  configurationLimit,
  provenCycle,
  cancelled,
  modelError,
  staleRequest;

  factory VerificationOutcomeCode.fromBatch(BatchOutcomeCode outcome) =>
      switch (outcome) {
        BatchOutcomeCode.accepted => VerificationOutcomeCode.accepted,
        BatchOutcomeCode.rejected => VerificationOutcomeCode.rejected,
        BatchOutcomeCode.output => VerificationOutcomeCode.output,
        BatchOutcomeCode.undefinedTransition =>
          VerificationOutcomeCode.undefinedTransition,
        BatchOutcomeCode.conflict => VerificationOutcomeCode.conflict,
        BatchOutcomeCode.invalidInput => VerificationOutcomeCode.invalidInput,
        BatchOutcomeCode.boundedUnknown =>
          VerificationOutcomeCode.boundedUnknown,
        BatchOutcomeCode.timeout => VerificationOutcomeCode.timeout,
        BatchOutcomeCode.configurationLimit =>
          VerificationOutcomeCode.configurationLimit,
        BatchOutcomeCode.provenCycle => VerificationOutcomeCode.provenCycle,
        BatchOutcomeCode.cancelled => VerificationOutcomeCode.cancelled,
        BatchOutcomeCode.modelError => VerificationOutcomeCode.modelError,
        BatchOutcomeCode.staleRequest => VerificationOutcomeCode.staleRequest,
      };

  BatchOutcomeCode toBatch() => switch (this) {
        VerificationOutcomeCode.accepted => BatchOutcomeCode.accepted,
        VerificationOutcomeCode.rejected => BatchOutcomeCode.rejected,
        VerificationOutcomeCode.output => BatchOutcomeCode.output,
        VerificationOutcomeCode.undefinedTransition =>
          BatchOutcomeCode.undefinedTransition,
        VerificationOutcomeCode.conflict => BatchOutcomeCode.conflict,
        VerificationOutcomeCode.invalidInput => BatchOutcomeCode.invalidInput,
        VerificationOutcomeCode.boundedUnknown =>
          BatchOutcomeCode.boundedUnknown,
        VerificationOutcomeCode.timeout => BatchOutcomeCode.timeout,
        VerificationOutcomeCode.configurationLimit =>
          BatchOutcomeCode.configurationLimit,
        VerificationOutcomeCode.provenCycle => BatchOutcomeCode.provenCycle,
        VerificationOutcomeCode.cancelled => BatchOutcomeCode.cancelled,
        VerificationOutcomeCode.modelError => BatchOutcomeCode.modelError,
        VerificationOutcomeCode.staleRequest => BatchOutcomeCode.staleRequest,
      };

  bool get isInconclusive => switch (this) {
        VerificationOutcomeCode.boundedUnknown ||
        VerificationOutcomeCode.timeout ||
        VerificationOutcomeCode.configurationLimit ||
        VerificationOutcomeCode.cancelled ||
        VerificationOutcomeCode.staleRequest =>
          true,
        _ => false,
      };

  bool get isDefinitive => !isInconclusive;
}
