import 'batch_execution_models.dart';

final class BatchInputGenerator {
  const BatchInputGenerator._();

  static List<BatchInputCase> boundedWords({
    required Iterable<String> alphabet,
    required int maxLength,
    required int maxCount,
  }) {
    if (maxLength < 0) {
      throw ArgumentError.value(maxLength, 'maxLength', 'must be non-negative');
    }
    if (maxCount <= 0) {
      throw ArgumentError.value(maxCount, 'maxCount', 'must be positive');
    }
    final symbols = alphabet.toSet().toList()..sort();
    if (symbols.any((symbol) => symbol.isEmpty)) {
      throw ArgumentError('Alphabet symbols must be non-empty.');
    }
    final cases = <BatchInputCase>[];
    var serial = 0;
    void add(List<String> tokens) {
      serial++;
      cases.add(
        BatchInputCase(
          id: 'generated-${serial.toString().padLeft(6, '0')}',
          input: tokens.join(),
          tokens: tokens,
        ),
      );
    }

    add(const []);
    var frontier = <List<String>>[const []];
    for (var length = 1;
        length <= maxLength && cases.length < maxCount;
        length++) {
      final next = <List<String>>[];
      for (final prefix in frontier) {
        for (final symbol in symbols) {
          final word = [...prefix, symbol];
          add(word);
          next.add(word);
          if (cases.length >= maxCount) break;
        }
        if (cases.length >= maxCount) break;
      }
      frontier = next;
      if (frontier.isEmpty) break;
    }
    return List<BatchInputCase>.unmodifiable(cases);
  }

  static List<BatchInputCase> multiline(
    String source, {
    String emptyWordMarker = 'ε',
  }) {
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.length > 1 && lines.last.isEmpty) lines.removeLast();
    return List<BatchInputCase>.unmodifiable([
      for (var index = 0; index < lines.length; index++)
        BatchInputCase(
          id: 'line-${(index + 1).toString().padLeft(6, '0')}',
          input: lines[index] == emptyWordMarker ? '' : lines[index],
        ),
    ]);
  }
}
