import 'batch_execution_models.dart';

final class BatchCaseComparison {
  const BatchCaseComparison({
    required this.caseId,
    required this.left,
    required this.right,
    required this.differs,
  });

  final String caseId;
  final BatchCaseResult left;
  final BatchCaseResult right;
  final bool differs;
}

final class BatchComparisonReport {
  BatchComparisonReport({
    required this.leftModelId,
    required this.rightModelId,
    required Iterable<BatchCaseComparison> cases,
  }) : cases = List<BatchCaseComparison>.unmodifiable(cases);

  final String leftModelId;
  final String rightModelId;
  final List<BatchCaseComparison> cases;

  bool get hasDifferences => cases.any((comparison) => comparison.differs);

  /// Batch comparison is finite evidence and never a general equivalence proof.
  bool get provesGeneralEquivalence => false;
}

final class BatchReportComparator {
  const BatchReportComparator._();

  static BatchComparisonReport compare(
    BatchExecutionReport left,
    BatchExecutionReport right,
  ) {
    if (left.results.length != right.results.length) {
      throw ArgumentError(
          'Batch reports must contain the same number of cases.');
    }
    final comparisons = <BatchCaseComparison>[];
    for (var index = 0; index < left.results.length; index++) {
      final leftResult = left.results[index];
      final rightResult = right.results[index];
      if (leftResult.inputCase.id != rightResult.inputCase.id ||
          leftResult.inputCase.input != rightResult.inputCase.input ||
          !_sameTokens(
              leftResult.inputCase.tokens, rightResult.inputCase.tokens)) {
        throw ArgumentError(
          'Batch reports must contain the same ordered input cases.',
        );
      }
      comparisons.add(
        BatchCaseComparison(
          caseId: leftResult.inputCase.id,
          left: leftResult,
          right: rightResult,
          differs: leftResult.outcome != rightResult.outcome ||
              !_sameStrings(leftResult.output, rightResult.output),
        ),
      );
    }
    return BatchComparisonReport(
      leftModelId: left.request.modelId,
      rightModelId: right.request.modelId,
      cases: comparisons,
    );
  }
}

bool _sameTokens(List<String>? left, List<String>? right) {
  if (left == null || right == null) return left == right;
  return _sameStrings(left, right);
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
