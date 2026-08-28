import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'domains.dart';
import 'models.dart';

abstract interface class DomainShrinker<T> {
  Iterable<T> candidates(T value);
}

final class ShrinkResult<T> {
  const ShrinkResult({
    required this.source,
    required this.minimalValue,
    required this.attempts,
    required this.acceptedCandidates,
  });

  final GeneratedCase<T> source;
  final T minimalValue;
  final int attempts;
  final int acceptedCandidates;

  String get fixtureFilename => 'hard-edge-${source.id}-minimized.json';

  String get reproductionCommand =>
      'dart run tool/hard_edge_cases.dart replay --fixture $fixtureFilename';

  Map<String, Object?> toFixtureJson() => {
        'caseIndex': source.caseIndex,
        'family': source.family,
        'fixtureId': '${source.id}-minimized',
        'mode': source.mode.name,
        'reproductionCommand': reproductionCommand,
        'schema': {'id': 'turing-lab.hard-edge-fixture', 'version': 1},
        'seed': source.seed,
        'value': source.encodeValue(minimalValue),
      };

  String toCanonicalFixture() => canonicalJsonEncode(toFixtureJson());

  /// Wraps the minimized value in the standalone failure-artifact schema used
  /// by `hard_edge_cases.dart replay`. [catalogCase] must be the strict catalog
  /// metadata for the generated property and is validated by the replay tool.
  Map<String, Object?> toFailureArtifactJson({
    required Map<String, Object?> catalogCase,
  }) {
    final fixture = source.encodeValue(minimalValue);
    final fixtureSha256 = sha256.convert(
      utf8.encode(canonicalJsonEncode(fixture)),
    );
    return {
      'case': <String, Object?>{
        ...catalogCase,
        'sha256': fixtureSha256.toString(),
      },
      'fixture': fixture,
      'minimized': true,
      'minimalFixture': null,
      'schemaVersion': 1,
    };
  }

  String toCanonicalFailureArtifact({
    required Map<String, Object?> catalogCase,
  }) =>
      canonicalJsonEncode(toFailureArtifactJson(catalogCase: catalogCase));
}

ShrinkResult<T> shrinkFailure<T>({
  required GeneratedCase<T> source,
  required DomainShrinker<T> shrinker,
  required bool Function(T candidate) stillFails,
  bool Function(T candidate)? isValid,
  bool Function(T candidate)? isApplicable,
  int maxAttempts = 10000,
}) {
  if (maxAttempts <= 0) {
    throw ArgumentError.value(maxAttempts, 'maxAttempts', 'must be positive');
  }
  if (!stillFails(source.value)) {
    throw ArgumentError('The source case does not reproduce the failure.');
  }

  var current = source.value;
  var attempts = 0;
  var accepted = 0;
  final seen = <String>{canonicalJsonEncode(source.encodeValue(current))};
  outer:
  while (attempts < maxAttempts) {
    var reduced = false;
    for (final candidate in shrinker.candidates(current)) {
      if (attempts >= maxAttempts) break outer;
      attempts++;
      final fingerprint = canonicalJsonEncode(source.encodeValue(candidate));
      if (!seen.add(fingerprint)) continue;
      if ((isValid?.call(candidate) ?? true) &&
          (isApplicable?.call(candidate) ?? true) &&
          stillFails(candidate)) {
        current = candidate;
        accepted++;
        reduced = true;
        break;
      }
      if (attempts >= maxAttempts) break outer;
    }
    if (!reduced) break;
  }
  return ShrinkResult(
    source: source,
    minimalValue: current,
    attempts: attempts,
    acceptedCandidates: accepted,
  );
}

Future<ShrinkResult<T>> shrinkFailureAsync<T>({
  required GeneratedCase<T> source,
  required DomainShrinker<T> shrinker,
  required Future<bool> Function(T candidate) stillFails,
  Future<bool> Function(T candidate)? isValid,
  Future<bool> Function(T candidate)? isApplicable,
  int maxAttempts = 10000,
}) async {
  if (maxAttempts <= 0) {
    throw ArgumentError.value(maxAttempts, 'maxAttempts', 'must be positive');
  }
  if (!await stillFails(source.value)) {
    throw ArgumentError('The source case does not reproduce the failure.');
  }

  var current = source.value;
  var attempts = 0;
  var accepted = 0;
  final seen = <String>{canonicalJsonEncode(source.encodeValue(current))};
  outer:
  while (attempts < maxAttempts) {
    var reduced = false;
    for (final candidate in shrinker.candidates(current)) {
      if (attempts >= maxAttempts) break outer;
      attempts++;
      final fingerprint = canonicalJsonEncode(source.encodeValue(candidate));
      if (!seen.add(fingerprint)) continue;
      if ((await isValid?.call(candidate) ?? true) &&
          (await isApplicable?.call(candidate) ?? true) &&
          await stillFails(candidate)) {
        current = candidate;
        accepted++;
        reduced = true;
        break;
      }
    }
    if (!reduced) break;
  }
  return ShrinkResult(
    source: source,
    minimalValue: current,
    attempts: attempts,
    acceptedCandidates: accepted,
  );
}

/// Deterministic fallback for standalone JSON artifacts. Typed algorithm
/// adapters can provide narrower shrinkers, while this one removes domain
/// collections and shortens their members in a stable order.
final class JsonValueShrinker implements DomainShrinker<Object?> {
  const JsonValueShrinker({this.preferredCandidate});

  final Object? preferredCandidate;

  @override
  Iterable<Object?> candidates(Object? value) sync* {
    if (preferredCandidate != null) yield preferredCandidate;
    yield* _jsonCandidates(value);
  }
}

const _domainFieldOrder = <String>[
  'transitions',
  'productions',
  'states',
  'alphabet',
  'inputAlphabet',
  'outputAlphabet',
  'tokens',
  'word',
  'tape',
  'stack',
  'children',
];

Iterable<Object?> _jsonCandidates(Object? value) sync* {
  if (value is List) {
    yield* _listReductions<Object?>(value);
    for (var index = 0; index < value.length; index++) {
      for (final reduced in _jsonCandidates(value[index])) {
        yield <Object?>[...value]..[index] = reduced;
      }
    }
    return;
  }
  if (value is Map) {
    final map = <String, Object?>{
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    final keys = map.keys.toList()
      ..sort((left, right) {
        final leftRank = _domainFieldOrder.indexOf(left);
        final rightRank = _domainFieldOrder.indexOf(right);
        if (leftRank >= 0 || rightRank >= 0) {
          if (leftRank < 0) return 1;
          if (rightRank < 0) return -1;
          if (leftRank != rightRank) return leftRank.compareTo(rightRank);
        }
        return left.compareTo(right);
      });
    for (final key in keys) {
      for (final reduced in _jsonCandidates(map[key])) {
        yield <String, Object?>{...map, key: reduced};
      }
      if (key != 'outcome') {
        yield <String, Object?>{...map}..remove(key);
      }
    }
    return;
  }
  if (value is String) {
    yield* _symbolReductions(value);
    return;
  }
  if (value is int && value != 0) {
    yield 0;
    if (value.abs() > 1) yield value ~/ 2;
  }
}

final class TokenListShrinker implements DomainShrinker<List<String>> {
  const TokenListShrinker();

  @override
  Iterable<List<String>> candidates(List<String> value) sync* {
    yield* _listReductions(value);
    for (var index = 0; index < value.length; index++) {
      for (final symbol in _symbolReductions(value[index])) {
        yield List.unmodifiable([...value]..[index] = symbol);
      }
    }
  }
}

final class RegexAstShrinker implements DomainShrinker<GeneratedRegexAst> {
  const RegexAstShrinker();

  @override
  Iterable<GeneratedRegexAst> candidates(GeneratedRegexAst value) sync* {
    yield GeneratedRegexAst(kind: GeneratedRegexKind.empty);
    yield GeneratedRegexAst(kind: GeneratedRegexKind.epsilon);
    yield* value.children;
    for (var index = 0; index < value.children.length; index++) {
      for (final child in candidates(value.children[index])) {
        final children = [...value.children]..[index] = child;
        yield GeneratedRegexAst(
          kind: value.kind,
          symbol: value.symbol,
          children: children,
        );
      }
    }
    final symbol = value.symbol;
    if (symbol != null) {
      for (final reduced in _symbolReductions(symbol)) {
        yield GeneratedRegexAst(kind: value.kind, symbol: reduced);
      }
    }
  }
}

final class AutomatonShrinker implements DomainShrinker<GeneratedAutomaton> {
  const AutomatonShrinker();

  @override
  Iterable<GeneratedAutomaton> candidates(GeneratedAutomaton value) sync* {
    for (final states in _listReductions(value.states)) {
      final retained = states.map((state) => state.id).toSet();
      yield value.copyWith(
        states: states,
        transitions: value.transitions.where(
          (transition) =>
              retained.contains(transition.fromId) &&
              retained.contains(transition.toId),
        ),
      );
    }
    for (final transitions in _listReductions(value.transitions)) {
      yield value.copyWith(transitions: transitions);
    }
    for (final alphabet in _listReductions(value.alphabet)) {
      yield value.copyWith(alphabet: alphabet);
    }
  }
}

final class GrammarShrinker implements DomainShrinker<GeneratedGrammar> {
  const GrammarShrinker();

  @override
  Iterable<GeneratedGrammar> candidates(GeneratedGrammar value) sync* {
    for (final productions in _listReductions(value.productions)) {
      yield value.copyWith(productions: productions);
    }
    for (final terminals in _listReductions(value.terminals)) {
      yield value.copyWith(terminals: terminals);
    }
    for (final nonterminals in _listReductions(value.nonterminals)) {
      if (nonterminals.contains(value.startSymbol) || nonterminals.isEmpty) {
        yield value.copyWith(nonterminals: nonterminals);
      }
    }
    for (var index = 0; index < value.productions.length; index++) {
      final production = value.productions[index];
      for (final right
          in const TokenListShrinker().candidates(production.rightTokens)) {
        final productions = [...value.productions]..[index] =
              GeneratedProduction(
            id: production.id,
            leftTokens: production.leftTokens,
            rightTokens: right,
          );
        yield value.copyWith(productions: productions);
      }
    }
  }
}

final class TransducerShrinker implements DomainShrinker<GeneratedTransducer> {
  const TransducerShrinker();

  @override
  Iterable<GeneratedTransducer> candidates(GeneratedTransducer value) sync* {
    for (final states in _listReductions(value.states)) {
      final retained = states.map((state) => state.id).toSet();
      yield value.copyWith(
        states: states,
        transitions: value.transitions.where(
          (transition) =>
              retained.contains(transition.fromId) &&
              retained.contains(transition.toId),
        ),
      );
    }
    for (final transitions in _listReductions(value.transitions)) {
      yield value.copyWith(transitions: transitions);
    }
    for (final symbols in _listReductions(value.inputAlphabet)) {
      yield value.copyWith(inputAlphabet: symbols);
    }
    for (final symbols in _listReductions(value.outputAlphabet)) {
      yield value.copyWith(outputAlphabet: symbols);
    }
  }
}

final class LSystemShrinker implements DomainShrinker<GeneratedLSystem> {
  const LSystemShrinker();

  @override
  Iterable<GeneratedLSystem> candidates(GeneratedLSystem value) sync* {
    for (final productions in _listReductions(value.productions)) {
      yield value.copyWith(productions: productions);
    }
    for (final alphabet in _listReductions(value.alphabet)) {
      yield value.copyWith(alphabet: alphabet);
    }
    for (final axiom in const TokenListShrinker().candidates(
      value.axiomTokens,
    )) {
      yield value.copyWith(axiomTokens: axiom);
    }
    if (value.iterations > 0) {
      yield value.copyWith(iterations: 0);
      yield value.copyWith(iterations: value.iterations ~/ 2);
    }
  }
}

Iterable<List<T>> _listReductions<T>(List<T> values) sync* {
  if (values.isEmpty) return;
  yield List<T>.unmodifiable(const []);
  if (values.length > 1) {
    yield List<T>.unmodifiable(values.take(values.length ~/ 2));
  }
  for (var index = values.length - 1; index >= 0; index--) {
    yield List<T>.unmodifiable([...values]..removeAt(index));
  }
}

Iterable<String> _symbolReductions(String symbol) sync* {
  if (symbol.isEmpty) return;
  yield '';
  final scalars = symbol.runes.toList();
  if (scalars.length > 1) {
    yield String.fromCharCode(scalars.first);
    yield String.fromCharCodes(scalars.take(scalars.length ~/ 2));
  }
}
