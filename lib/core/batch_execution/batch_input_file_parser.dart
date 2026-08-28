import 'dart:convert';

import '../messages/structured_message.dart';
import 'batch_execution_models.dart';
import 'batch_input_generator.dart';

final class BatchInputFileParser {
  const BatchInputFileParser._();

  static List<BatchInputCase> parseUtf8(
    List<int> bytes, {
    required String filename,
    int maxCases = 10000,
  }) {
    if (maxCases <= 0) {
      throw ArgumentError.value(maxCases, 'maxCases', 'must be positive');
    }
    final source = utf8.decode(bytes, allowMalformed: false);
    final extension = filename.toLowerCase().split('.').last;
    final cases = extension == 'csv' ? csv(source) : multiline(source);
    if (cases.length > maxCases) {
      throw BatchInputFormatException(
        _importMessage(
          'case-limit',
          arguments: {
            'count': StructuredMessageArgument.count(cases.length),
            'bound': StructuredMessageArgument.bound(maxCases),
          },
        ),
      );
    }
    return cases;
  }

  static List<BatchInputCase> multiline(String source) =>
      BatchInputGenerator.multiline(source);

  static List<BatchInputCase> csv(String source) {
    final rows = _csvRows(source);
    if (rows.isEmpty) return const [];
    final header = rows.first.map((cell) => cell.trim().toLowerCase()).toList();
    final inputColumn = header.indexOf('input');
    final idColumn = header.indexOf('id');
    final hasHeader = inputColumn >= 0;
    final resolvedInputColumn = hasHeader ? inputColumn : 0;
    final start = hasHeader ? 1 : 0;
    final cases = <BatchInputCase>[];
    final ids = <String>{};
    for (var rowIndex = start; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.length <= resolvedInputColumn) {
        throw BatchInputFormatException(
          _importMessage(
            'missing-input-column',
            arguments: {
              'row': StructuredMessageArgument.integer(
                rowIndex + 1,
                role: 'row-number',
              ),
            },
          ),
        );
      }
      final fallbackId = 'row-${(rowIndex + 1).toString().padLeft(6, '0')}';
      final rawId = hasHeader && idColumn >= 0 && idColumn < row.length
          ? row[idColumn]
          : fallbackId;
      final id = rawId.trim().isEmpty ? fallbackId : rawId.trim();
      if (!ids.add(id)) {
        throw BatchInputFormatException(
          _importMessage(
            'duplicate-case-id',
            arguments: {
              'case': StructuredMessageArgument.identifier(id, role: 'case'),
            },
          ),
        );
      }
      cases.add(BatchInputCase(id: id, input: row[resolvedInputColumn]));
    }
    return List<BatchInputCase>.unmodifiable(cases);
  }
}

List<List<String>> _csvRows(String source) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  var afterQuote = false;

  void finishField() {
    row.add(field.toString());
    field = StringBuffer();
    afterQuote = false;
  }

  void finishRow() {
    finishField();
    rows.add(row);
    row = <String>[];
  }

  for (var index = 0; index < source.length; index++) {
    final char = source[index];
    if (quoted) {
      if (char == '"') {
        if (index + 1 < source.length && source[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = false;
          afterQuote = true;
        }
      } else {
        field.write(char);
      }
      continue;
    }
    if (afterQuote && char != ',' && char != '\r' && char != '\n') {
      throw BatchInputFormatException(
        _importMessage('characters-after-closing-quote'),
      );
    }
    switch (char) {
      case '"':
        if (field.isNotEmpty) {
          throw BatchInputFormatException(
            _importMessage('quote-requires-empty-field'),
          );
        }
        quoted = true;
      case ',':
        finishField();
      case '\r':
        if (index + 1 < source.length && source[index + 1] == '\n') index++;
        finishRow();
      case '\n':
        finishRow();
      default:
        field.write(char);
    }
  }
  if (quoted) {
    throw BatchInputFormatException(_importMessage('unclosed-quote'));
  }
  if (row.isNotEmpty || field.isNotEmpty || source.endsWith(',')) finishRow();
  return rows;
}

final class BatchInputFormatException implements Exception {
  const BatchInputFormatException(this.structuredMessage);

  final StructuredMessage structuredMessage;

  @override
  String toString() => 'Batch input file is invalid.';
}

StructuredMessage _importMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'batch.import',
  code: code,
  category: StructuredMessageCategory.parsing,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);
