part of 'pda_simulator.dart';

/// Recursively generates strings and adds them to [results] based on [predicate].
///
/// [predicate] receives the acceptance result (`true` = accepted) and returns
/// whether the string should be included.
void _generateStringsByPredicate(
  PDA pda,
  List<String> alphabet,
  String currentString,
  int remainingLength,
  Set<String> results,
  int maxResults,
  bool Function(bool) predicate,
) {
  if (results.length >= maxResults) return;

  if (remainingLength == 0) {
    final acceptsResult = PDASimulator.accepts(pda, currentString);
    if (!acceptsResult.isSuccess || acceptsResult.data == null) {
      throw StateError(
        'PDA acceptance failed for "$currentString": '
        '${acceptsResult.error ?? 'no acceptance result'}',
      );
    }
    if (predicate(acceptsResult.data!)) {
      results.add(currentString);
    }
    return;
  }

  for (final symbol in alphabet) {
    _generateStringsByPredicate(
      pda,
      alphabet,
      currentString + symbol,
      remainingLength - 1,
      results,
      maxResults,
      predicate,
    );
  }
}

/// Recursively generates strings accepted by the PDA.
void _generateStrings(
  PDA pda,
  List<String> alphabet,
  String currentString,
  int remainingLength,
  Set<String> acceptedStrings,
  int maxResults,
) => _generateStringsByPredicate(
  pda,
  alphabet,
  currentString,
  remainingLength,
  acceptedStrings,
  maxResults,
  (accepted) => accepted,
);

/// Recursively generates strings rejected by the PDA.
void _generateRejectedStrings(
  PDA pda,
  List<String> alphabet,
  String currentString,
  int remainingLength,
  Set<String> rejectedStrings,
  int maxResults,
) => _generateStringsByPredicate(
  pda,
  alphabet,
  currentString,
  remainingLength,
  rejectedStrings,
  maxResults,
  (accepted) => !accepted,
);
