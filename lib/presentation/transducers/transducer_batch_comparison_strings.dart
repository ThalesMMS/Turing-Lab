import 'package:flutter/foundation.dart';

@immutable
final class TransducerBatchComparisonStrings {
  const TransducerBatchComparisonStrings({
    required this.batchTitle,
    required this.batchInputLabel,
    required this.batchInputHelper,
    required this.runBatch,
    required this.batchEmpty,
    required this.batchSuccess,
    required this.batchUndefined,
    required this.batchInvalidMachine,
    required this.batchInvalidInput,
    required this.batchCancelled,
    required this.batchBounded,
    required this.comparisonTitle,
    required this.comparisonModeLabel,
    required this.exactMode,
    required this.boundedMode,
    required this.boundLabel,
    required this.chooseMachine,
    required this.machineSelectionFailed,
    required this.compare,
    required this.noComparisonMachine,
    required this.exactEquivalent,
    required this.exactDifferent,
    required this.boundedDifferent,
    required this.boundedInconclusive,
    required this.comparisonInvalid,
    required this.inputLabel,
    required this.outputLabel,
    required this.leftOutputLabel,
    required this.rightOutputLabel,
    required this.witnessLabel,
    required this.invalidBatchLine,
    required this.selectedMachine,
    required this.exploredPairs,
  });

  final String batchTitle;
  final String batchInputLabel;
  final String batchInputHelper;
  final String runBatch;
  final String batchEmpty;
  final String batchSuccess;
  final String batchUndefined;
  final String batchInvalidMachine;
  final String batchInvalidInput;
  final String batchCancelled;
  final String batchBounded;
  final String comparisonTitle;
  final String comparisonModeLabel;
  final String exactMode;
  final String boundedMode;
  final String boundLabel;
  final String chooseMachine;
  final String machineSelectionFailed;
  final String compare;
  final String noComparisonMachine;
  final String exactEquivalent;
  final String exactDifferent;
  final String boundedDifferent;
  final String boundedInconclusive;
  final String comparisonInvalid;
  final String inputLabel;
  final String outputLabel;
  final String leftOutputLabel;
  final String rightOutputLabel;
  final String witnessLabel;
  final String Function(int line) invalidBatchLine;
  final String Function(String name) selectedMachine;
  final String Function(int count) exploredPairs;
}
