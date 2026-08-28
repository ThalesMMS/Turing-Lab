import 'dart:convert';

import 'batch_execution_models.dart';

final class BatchReportEncoder {
  const BatchReportEncoder._();

  static String json(BatchExecutionReport report) =>
      '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n';

  static String csv(BatchExecutionReport report) {
    final buffer = StringBuffer()..writeln(_csvHeaders.join(','));
    for (final result in report.results) {
      final limits = report.request.limitsFor(result.inputCase.id);
      final cells = <Object?>[
        report.request.modelId,
        report.request.modelRevision,
        report.request.strategyId,
        report.request.tokenizationMode.name,
        limits.maxSteps,
        limits.maxConfigurations,
        limits.timeout.inMicroseconds,
        report.request.traceRetention.name,
        result.inputCase.id,
        result.inputCase.input,
        result.outcome.name,
        result.output.join(' '),
        result.metrics['steps'],
        result.metrics['configurations'],
        result.elapsed.inMicroseconds,
        result.diagnosticCode,
        result.message,
        if (result.structuredMessage case final message?)
          jsonEncode(message.toJson())
        else
          null,
      ];
      buffer.writeln(cells.map(_csvCell).join(','));
    }
    return buffer.toString();
  }
}

const _csvHeaders = [
  'modelId',
  'modelRevision',
  'strategyId',
  'tokenizationMode',
  'maxSteps',
  'maxConfigurations',
  'timeoutMicros',
  'traceRetention',
  'caseId',
  'input',
  'outcome',
  'output',
  'steps',
  'configurations',
  'elapsedMicros',
  'diagnosticCode',
  'message',
  'structuredMessage',
];

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  if (!text.contains(RegExp('[,"\\r\\n]'))) return text;
  return '"${text.replaceAll('"', '""')}"';
}
