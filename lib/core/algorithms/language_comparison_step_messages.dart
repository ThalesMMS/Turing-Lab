import '../messages/structured_message.dart';

/// Locale-neutral descriptions emitted for language-comparison trace steps.
///
/// The comparison algorithm keeps its historical map payloads and English
/// descriptions for compatibility. These messages carry only the formal
/// values needed to localize each description at the presentation boundary.
abstract final class LanguageComparisonStepMessages {
  static const namespace = 'language.comparison.trace';

  static StructuredMessage validation() => _step('validation');

  static StructuredMessage initialization() => _step('initialization');

  static StructuredMessage alphabetNormalization() =>
      _step('alphabet-normalization');

  static StructuredMessage nfaToDfa(String automaton) =>
      _step('nfa-to-dfa', arguments: {'automaton': _automatonSide(automaton)});

  static StructuredMessage dfaCompletion(String automaton) => _step(
    'dfa-completion',
    arguments: {'automaton': _automatonSide(automaton)},
  );

  static StructuredMessage productConstructionStart() =>
      _step('product-construction-start');

  static StructuredMessage productStateCreated(String productState) => _step(
    'product-state-created',
    arguments: {'state': _stateLabel(productState)},
  );

  static StructuredMessage productTransitionCreated(String symbol) => _step(
    'product-transition-created',
    arguments: {'symbol': _inputSymbol(symbol)},
  );

  static StructuredMessage productConstructionComplete() =>
      _step('product-construction-complete');

  static StructuredMessage bfsSearchStart() => _step('bfs-search-start');

  static StructuredMessage bfsInitialCheck({
    required bool acceptsA,
    required bool acceptsB,
  }) => _step(
    'bfs-initial-check',
    arguments: {
      'different': StructuredMessageArgument.boolean(
        acceptsA != acceptsB,
        role: 'acceptance-difference',
      ),
    },
  );

  static StructuredMessage bfsExplorePair({
    required String stateA,
    required String stateB,
  }) => _step(
    'bfs-explore-pair',
    arguments: {'state-a': _stateLabel(stateA), 'state-b': _stateLabel(stateB)},
  );

  static StructuredMessage bfsDistinguishingFound(
    String distinguishingString,
  ) => _step(
    'bfs-distinguishing-found',
    arguments: {
      'value': _literal(distinguishingString, 'distinguishing-string'),
    },
  );

  static StructuredMessage bfsComplete() => _step('bfs-complete');

  static StructuredMessage result({required bool isEquivalent}) => _step(
    'result',
    arguments: {
      'equivalent': StructuredMessageArgument.boolean(
        isEquivalent,
        role: 'comparison-equivalence',
      ),
    },
  );

  static StructuredMessage error() => _step('error');

  static StructuredMessage unknown(String rawType) =>
      _step('unknown', arguments: {'type': _literal(rawType, 'trace-type')});

  /// Converts one legacy trace map without changing that map's shape.
  ///
  /// Unknown or incomplete payloads receive a stable fallback message so
  /// adding a future legacy step cannot make a successful comparison fail
  /// while its structured companion is being integrated.
  static StructuredMessage fromLegacyStep(Map<String, dynamic> step) {
    final type = step['type']?.toString() ?? '';
    final data = _data(step['data']);

    return switch (type) {
      'validation' => validation(),
      'initialization' => initialization(),
      'alphabet_normalization' => alphabetNormalization(),
      'nfa_to_dfa' =>
        _hasStrings(data, const ['automaton'])
            ? nfaToDfa(_string(data, 'automaton'))
            : unknown(type),
      'dfa_completion' =>
        _hasStrings(data, const ['automaton'])
            ? dfaCompletion(_string(data, 'automaton'))
            : unknown(type),
      'product_construction_start' => productConstructionStart(),
      'product_state_created' =>
        _hasStrings(data, const ['productState'])
            ? productStateCreated(_string(data, 'productState'))
            : unknown(type),
      'product_transition_created' =>
        _hasStrings(data, const ['symbol'])
            ? productTransitionCreated(_string(data, 'symbol'))
            : unknown(type),
      'product_construction_complete' => productConstructionComplete(),
      'bfs_search_start' => bfsSearchStart(),
      'bfs_initial_check' =>
        _hasBools(data, const ['acceptsA', 'acceptsB'])
            ? bfsInitialCheck(
                acceptsA: _bool(data, 'acceptsA'),
                acceptsB: _bool(data, 'acceptsB'),
              )
            : unknown(type),
      'bfs_explore_pair' =>
        _hasStrings(data, const ['stateA', 'stateB'])
            ? bfsExplorePair(
                stateA: _string(data, 'stateA'),
                stateB: _string(data, 'stateB'),
              )
            : unknown(type),
      'bfs_distinguishing_found' =>
        _hasStrings(data, const ['distinguishingString'])
            ? bfsDistinguishingFound(_string(data, 'distinguishingString'))
            : unknown(type),
      'bfs_complete' => bfsComplete(),
      'result' =>
        _hasBools(data, const ['isEquivalent'])
            ? result(isEquivalent: _bool(data, 'isEquivalent'))
            : unknown(type),
      'error' || 'comparison_error' => error(),
      _ => unknown(type),
    };
  }

  static StructuredMessage _step(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessageArgument _automatonSide(String value) =>
      StructuredMessageArgument.identifier(value, role: 'automaton-side');

  static StructuredMessageArgument _stateLabel(String value) =>
      _literal(value, 'state-label');

  static StructuredMessageArgument _inputSymbol(String value) =>
      StructuredMessageArgument.symbol(value, role: 'input-symbol');

  static StructuredMessageArgument _literal(String value, String role) =>
      StructuredMessageArgument.literal(value, role: role);

  static Map<String, dynamic> _data(Object? raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static String _string(Map<String, dynamic> data, String key) =>
      data[key]?.toString() ?? '';

  static bool _bool(Map<String, dynamic> data, String key) => data[key] == true;

  static bool _hasStrings(Map<String, dynamic> data, List<String> keys) =>
      keys.every((key) => data[key] is String);

  static bool _hasBools(Map<String, dynamic> data, List<String> keys) =>
      keys.every((key) => data[key] is bool);
}
