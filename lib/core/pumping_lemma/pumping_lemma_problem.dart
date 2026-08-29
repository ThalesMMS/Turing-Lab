import 'package:collection/collection.dart';

import 'pumping_decomposition.dart';
import 'pumping_lemma_messages.dart';

enum PumpingLanguageRepresentationKind {
  curatedPredicate,
  regularExpression,
  finiteStateAutomaton,
  contextFreeGrammar,
  pushdownAutomaton,
  customBoundedPredicate,
}

enum PumpingChallengeOutcome {
  counterexampleExpected,
  noCounterexampleExpected,
  learnerDetermines,
}

final class PumpingMembershipExample {
  PumpingMembershipExample({
    required List<String> tokens,
    required this.expectedMembership,
  }) : tokens = List<String>.unmodifiable(tokens);

  factory PumpingMembershipExample.fromJson(Map<String, Object?> json) =>
      PumpingMembershipExample(
        tokens: (json['tokens']! as List<Object?>).cast<String>(),
        expectedMembership: json['expectedMembership']! as bool,
      );

  final List<String> tokens;
  final bool expectedMembership;

  Map<String, Object?> toJson() => {
    'tokens': tokens,
    'expectedMembership': expectedMembership,
  };

  @override
  bool operator ==(Object other) =>
      other is PumpingMembershipExample &&
      expectedMembership == other.expectedMembership &&
      const ListEquality<String>().equals(tokens, other.tokens);

  @override
  int get hashCode => Object.hash(
    const ListEquality<String>().hash(tokens),
    expectedMembership,
  );
}

final class PumpingLemmaProblem {
  PumpingLemmaProblem({
    required this.id,
    this.customTitle,
    this.contentVersion = 1,
    required this.theorem,
    required this.languageDescription,
    required this.representationKind,
    required this.representation,
    required this.sourceRevision,
    required this.suggestedPumpingLength,
    required List<String> suggestedWitness,
    this.expectedOutcome = PumpingChallengeOutcome.learnerDetermines,
    List<PumpingMembershipExample> validationExamples = const [],
  }) : suggestedWitness = List<String>.unmodifiable(suggestedWitness),
       validationExamples = List<PumpingMembershipExample>.unmodifiable(
         validationExamples,
       ) {
    if (contentVersion < 1) {
      throw PumpingLemmaArgumentError.value(
        contentVersion,
        'contentVersion',
        PumpingLemmaMessages.contentVersionPositive(),
      );
    }
    if (suggestedPumpingLength < 1) {
      throw PumpingLemmaArgumentError.value(
        suggestedPumpingLength,
        'suggestedPumpingLength',
        PumpingLemmaMessages.pumpingLengthPositive(),
      );
    }
    final requiredText = {
      'id': id,
      'languageDescription': languageDescription,
      'representation': representation,
      'sourceRevision': sourceRevision,
    };
    for (final entry in requiredText.entries) {
      if (entry.value.trim().isEmpty) {
        throw PumpingLemmaArgumentError.value(
          entry.value,
          entry.key,
          PumpingLemmaMessages.requiredTextNotEmpty(entry.key),
        );
      }
    }
    if (suggestedWitness.isEmpty) {
      throw PumpingLemmaArgumentError.value(
        suggestedWitness,
        'suggestedWitness',
        PumpingLemmaMessages.suggestedWitnessNotEmpty(),
      );
    }
    if (customTitle != null && customTitle!.trim().isEmpty) {
      throw PumpingLemmaArgumentError.value(
        customTitle,
        'customTitle',
        PumpingLemmaMessages.customTitleNotEmpty(),
      );
    }
  }

  factory PumpingLemmaProblem.fromJson(Map<String, Object?> json) =>
      PumpingLemmaProblem(
        id: json['id']! as String,
        customTitle: json['customTitle'] as String? ?? json['title'] as String?,
        contentVersion: json['contentVersion'] as int? ?? 1,
        theorem: PumpingLemmaTheorem.values.byName(json['theorem']! as String),
        languageDescription: json['languageDescription']! as String,
        representationKind: PumpingLanguageRepresentationKind.values.byName(
          json['representationKind']! as String,
        ),
        representation: json['representation']! as String,
        sourceRevision: json['sourceRevision']! as String,
        suggestedPumpingLength: json['suggestedPumpingLength']! as int,
        suggestedWitness: (json['suggestedWitness']! as List<Object?>)
            .cast<String>(),
        expectedOutcome: PumpingChallengeOutcome.values.byName(
          json['expectedOutcome'] as String? ??
              PumpingChallengeOutcome.learnerDetermines.name,
        ),
        validationExamples:
            (json['validationExamples'] as List<Object?>? ?? const <Object?>[])
                .map(
                  (value) => PumpingMembershipExample.fromJson(
                    (value! as Map).cast<String, Object?>(),
                  ),
                )
                .toList(growable: false),
      );

  final String id;
  final String? customTitle;
  final int contentVersion;
  final PumpingLemmaTheorem theorem;
  final String languageDescription;
  final PumpingLanguageRepresentationKind representationKind;
  final String representation;
  final String sourceRevision;
  final int suggestedPumpingLength;
  final List<String> suggestedWitness;
  final PumpingChallengeOutcome expectedOutcome;
  final List<PumpingMembershipExample> validationExamples;

  Map<String, Object?> toJson() => {
    'id': id,
    if (customTitle != null) 'customTitle': customTitle,
    'contentVersion': contentVersion,
    'theorem': theorem.name,
    'languageDescription': languageDescription,
    'representationKind': representationKind.name,
    'representation': representation,
    'sourceRevision': sourceRevision,
    'suggestedPumpingLength': suggestedPumpingLength,
    'suggestedWitness': suggestedWitness,
    'expectedOutcome': expectedOutcome.name,
    'validationExamples': validationExamples
        .map((example) => example.toJson())
        .toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      other is PumpingLemmaProblem &&
      id == other.id &&
      customTitle == other.customTitle &&
      contentVersion == other.contentVersion &&
      theorem == other.theorem &&
      languageDescription == other.languageDescription &&
      representationKind == other.representationKind &&
      representation == other.representation &&
      sourceRevision == other.sourceRevision &&
      suggestedPumpingLength == other.suggestedPumpingLength &&
      const ListEquality<String>().equals(
        suggestedWitness,
        other.suggestedWitness,
      ) &&
      expectedOutcome == other.expectedOutcome &&
      const ListEquality<PumpingMembershipExample>().equals(
        validationExamples,
        other.validationExamples,
      );

  @override
  int get hashCode => Object.hash(
    id,
    customTitle,
    contentVersion,
    theorem,
    languageDescription,
    representationKind,
    representation,
    sourceRevision,
    suggestedPumpingLength,
    const ListEquality<String>().hash(suggestedWitness),
    expectedOutcome,
    const ListEquality<PumpingMembershipExample>().hash(validationExamples),
  );
}

enum PumpingMembershipCertainty { concreteCheck, unavailable }

final class PumpingMembershipResult {
  const PumpingMembershipResult.checked(this.isInLanguage)
    : certainty = PumpingMembershipCertainty.concreteCheck;

  const PumpingMembershipResult.unavailable()
    : isInLanguage = null,
      certainty = PumpingMembershipCertainty.unavailable;

  final bool? isInLanguage;
  final PumpingMembershipCertainty certainty;

  bool get isComputationalEvidenceOnly => true;
  bool get provesUniversalClaim => false;
}

typedef PumpingMembershipOracle =
    PumpingMembershipResult Function(List<String> tokens);

abstract final class PumpingLemmaProblemCatalog {
  static final regular = validateCatalog(
    theorem: PumpingLemmaTheorem.regular,
    problems: [
      _problem(
        id: 'regular.equal-blocks',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {a^n b^n | n >= 0}',
        representation: 'equal-a-b-blocks',
        pumpingLength: 2,
        witness: const ['a', 'a', 'b', 'b'],
        rejectedExample: const ['a', 'b', 'b'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'regular.equal-counts',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {w in {a,b}* | #a(w) = #b(w)}',
        representation: 'equal-a-b-counts',
        pumpingLength: 3,
        witness: const ['a', 'a', 'a', 'b', 'b', 'b'],
        rejectedExample: const ['a', 'a', 'b'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'regular.unary-squares',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {a^(n^2) | n >= 0}',
        representation: 'unary-square-length',
        pumpingLength: 4,
        witness: const ['a', 'a', 'a', 'a'],
        rejectedExample: const ['a', 'a', 'a'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'regular.even-a',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {a^(2n) | n >= 0}',
        representation: 'even-a-length',
        pumpingLength: 2,
        witness: const ['a', 'a'],
        rejectedExample: const ['a'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'regular.unary-primes',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {a^p | p is prime}',
        representation: 'unary-prime-length',
        pumpingLength: 3,
        witness: const ['a', 'a', 'a'],
        rejectedExample: const ['a', 'a', 'a', 'a'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'regular.binary-palindromes',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {w in {a,b}* | w = reverse(w)}',
        representation: 'binary-palindrome',
        pumpingLength: 3,
        witness: const ['a', 'a', 'a', 'b', 'a', 'a', 'a'],
        rejectedExample: const ['a', 'b', 'b'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'regular.duplicated-word',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {ww | w in {a,b}*}',
        representation: 'copy-language',
        pumpingLength: 4,
        witness: const [
          'a',
          'a',
          'a',
          'a',
          'b',
          'b',
          'b',
          'b',
          'a',
          'a',
          'a',
          'a',
          'b',
          'b',
          'b',
          'b',
        ],
        rejectedExample: const ['a', 'b', 'b', 'a'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'regular.double-second-block',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {a^n b^(2n) | n >= 0}',
        representation: 'double-b-block',
        pumpingLength: 3,
        witness: const ['a', 'a', 'b', 'b', 'b', 'b'],
        rejectedExample: const ['a', 'a', 'b', 'b', 'b'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'regular.more-a-than-b',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {w in {a,b}* | #a(w) > #b(w)}',
        representation: 'more-a-than-b',
        pumpingLength: 3,
        witness: const ['a', 'a', 'a', 'b', 'b'],
        rejectedExample: const ['a', 'b', 'b'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'regular.contains-ab',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {w in {a,b}* | w contains ab}',
        representation: 'contains-ab',
        pumpingLength: 3,
        witness: const ['a', 'a', 'b'],
        rejectedExample: const ['a', 'a'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'regular.ends-with-a',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {w in {a,b}* | w ends with a}',
        representation: 'ends-with-a',
        pumpingLength: 2,
        witness: const ['b', 'a'],
        rejectedExample: const ['a', 'b'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'regular.alternating-ab',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {(ab)^n | n >= 0}',
        representation: 'alternating-ab',
        pumpingLength: 4,
        witness: const ['a', 'b', 'a', 'b'],
        rejectedExample: const ['a', 'b', 'a', 'a'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'regular.at-most-two-a',
        theorem: PumpingLemmaTheorem.regular,
        language: 'L = {w in {a,b}* | #a(w) <= 2}',
        representation: 'at-most-two-a',
        pumpingLength: 3,
        witness: const ['a', 'a', 'b'],
        rejectedExample: const ['a', 'a', 'a'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
    ],
  );

  static final contextFree = validateCatalog(
    theorem: PumpingLemmaTheorem.contextFree,
    problems: [
      _problem(
        id: 'cfl.equal-three-blocks',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^n b^n c^n | n >= 0}',
        representation: 'equal-a-b-c-blocks',
        pumpingLength: 3,
        witness: const ['a', 'a', 'a', 'b', 'b', 'b', 'c', 'c', 'c'],
        rejectedExample: const ['a', 'a', 'a', 'b', 'b', 'b', 'c', 'c'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'cfl.copy-language',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {ww | w in {a,b}*}',
        representation: 'copy-language',
        pumpingLength: 4,
        witness: const [
          'a',
          'a',
          'a',
          'a',
          'b',
          'b',
          'b',
          'b',
          'a',
          'a',
          'a',
          'a',
          'b',
          'b',
          'b',
          'b',
        ],
        rejectedExample: const ['a', 'b', 'b', 'a'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'cfl.equal-multiple-blocks',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^n b^n c^n d^n | n >= 0}',
        representation: 'equal-a-b-c-d-blocks',
        pumpingLength: 5,
        witness: const ['a', 'a', 'b', 'b', 'c', 'c', 'd', 'd'],
        rejectedExample: const ['a', 'a', 'b', 'b', 'c', 'd', 'd', 'd'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'cfl.equal-two-blocks',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^n b^n | n >= 0}',
        representation: 'equal-a-b-blocks',
        pumpingLength: 2,
        witness: const ['a', 'a', 'a', 'b', 'b', 'b'],
        rejectedExample: const ['a', 'a', 'a', 'b', 'b'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'cfl.marked-mirror',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {w#reverse(w) | w in {a,b}*}',
        representation: 'marked-mirror',
        pumpingLength: 3,
        witness: const ['a', 'b', '#', 'b', 'a'],
        rejectedExample: const ['a', 'b', '#', 'a', 'b'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'cfl.balanced-parentheses',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {well-balanced strings over ( and )}',
        representation: 'balanced-parentheses',
        pumpingLength: 4,
        witness: const ['(', '(', ')', ')'],
        rejectedExample: const ['(', ')', ')'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'cfl.equal-ab-with-tail',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^n b^n c^m | n,m >= 0}',
        representation: 'equal-ab-with-c-tail',
        pumpingLength: 3,
        witness: const ['a', 'a', 'b', 'b', 'c', 'c'],
        rejectedExample: const ['a', 'a', 'b', 'c', 'c'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'cfl.head-with-equal-bc',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^m b^n c^n | m,n >= 0}',
        representation: 'a-head-with-equal-bc',
        pumpingLength: 3,
        witness: const ['a', 'a', 'b', 'b', 'c', 'c'],
        rejectedExample: const ['a', 'a', 'b', 'b', 'c'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
      _problem(
        id: 'cfl.crossed-dependencies',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^i b^j c^i d^j | i,j >= 0}',
        representation: 'crossed-dependencies',
        pumpingLength: 4,
        witness: const [
          'a',
          'a',
          'a',
          'a',
          'b',
          'b',
          'b',
          'b',
          'c',
          'c',
          'c',
          'c',
          'd',
          'd',
          'd',
          'd',
        ],
        rejectedExample: const ['a', 'a', 'b', 'b', 'c', 'd', 'd', 'd'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'cfl.marked-copy',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {w#w | w in {a,b}*}',
        representation: 'marked-copy',
        pumpingLength: 3,
        witness: const ['a', 'b', '#', 'a', 'b'],
        rejectedExample: const ['a', 'b', '#', 'b', 'a'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'cfl.unary-squares',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^(n^2) | n >= 0}',
        representation: 'unary-square-length',
        pumpingLength: 4,
        witness: const ['a', 'a', 'a', 'a'],
        rejectedExample: const ['a', 'a', 'a'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'cfl.unary-powers-of-two',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^(2^n) | n >= 0}',
        representation: 'unary-power-of-two',
        pumpingLength: 4,
        witness: const ['a', 'a', 'a', 'a'],
        rejectedExample: const ['a', 'a', 'a'],
        expectedOutcome: PumpingChallengeOutcome.counterexampleExpected,
      ),
      _problem(
        id: 'cfl.equal-ab-or-bc',
        theorem: PumpingLemmaTheorem.contextFree,
        language: 'L = {a^i b^j c^k | i = j or j = k}',
        representation: 'equal-ab-or-bc',
        pumpingLength: 3,
        witness: const ['a', 'a', 'b', 'b', 'c'],
        rejectedExample: const ['a', 'a', 'b', 'b', 'b', 'c'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      ),
    ],
  );

  static PumpingMembershipResult evaluateCurated(
    PumpingLemmaProblem problem,
    List<String> tokens,
  ) {
    if (problem.representationKind !=
        PumpingLanguageRepresentationKind.curatedPredicate) {
      return const PumpingMembershipResult.unavailable();
    }
    final result = switch (problem.representation) {
      'equal-a-b-blocks' => _equalBlocks(tokens, const ['a', 'b']),
      'equal-a-b-c-blocks' => _equalBlocks(tokens, const ['a', 'b', 'c']),
      'equal-a-b-c-d-blocks' => _equalBlocks(tokens, const [
        'a',
        'b',
        'c',
        'd',
      ]),
      'equal-a-b-counts' =>
        tokens.where((token) => token == 'a').length ==
                tokens.where((token) => token == 'b').length &&
            tokens.every((token) => token == 'a' || token == 'b'),
      'unary-square-length' =>
        tokens.every((token) => token == 'a') && _isSquare(tokens.length),
      'even-a-length' =>
        tokens.every((token) => token == 'a') && tokens.length.isEven,
      'unary-prime-length' => _isUnary(tokens) && _isPrime(tokens.length),
      'binary-palindrome' =>
        _hasOnly(tokens, const {'a', 'b'}) && _isPalindrome(tokens),
      'copy-language' => _hasOnly(tokens, const {'a', 'b'}) && _isCopy(tokens),
      'double-b-block' => _hasOrderedCounts(tokens, const [
        'a',
        'b',
      ], (counts) => counts[1] == 2 * counts[0]),
      'more-a-than-b' =>
        _hasOnly(tokens, const {'a', 'b'}) &&
            _count(tokens, 'a') > _count(tokens, 'b'),
      'contains-ab' => _containsAdjacent(tokens, 'a', 'b'),
      'ends-with-a' =>
        _hasOnly(tokens, const {'a', 'b'}) && tokens.lastOrNull == 'a',
      'alternating-ab' => _isAlternatingAb(tokens),
      'at-most-two-a' =>
        _hasOnly(tokens, const {'a', 'b'}) && _count(tokens, 'a') <= 2,
      'marked-mirror' => _isMarkedPair(tokens, reverseRight: true),
      'balanced-parentheses' => _isBalancedParentheses(tokens),
      'equal-ab-with-c-tail' => _hasOrderedCounts(tokens, const [
        'a',
        'b',
        'c',
      ], (counts) => counts[0] == counts[1]),
      'a-head-with-equal-bc' => _hasOrderedCounts(tokens, const [
        'a',
        'b',
        'c',
      ], (counts) => counts[1] == counts[2]),
      'crossed-dependencies' => _hasOrderedCounts(tokens, const [
        'a',
        'b',
        'c',
        'd',
      ], (counts) => counts[0] == counts[2] && counts[1] == counts[3]),
      'marked-copy' => _isMarkedPair(tokens, reverseRight: false),
      'unary-power-of-two' => _isUnary(tokens) && _isPowerOfTwo(tokens.length),
      'equal-ab-or-bc' => _hasOrderedCounts(tokens, const [
        'a',
        'b',
        'c',
      ], (counts) => counts[0] == counts[1] || counts[1] == counts[2]),
      _ => null,
    };
    return result == null
        ? const PumpingMembershipResult.unavailable()
        : PumpingMembershipResult.checked(result);
  }

  static List<PumpingLemmaProblem> validateCatalog({
    required PumpingLemmaTheorem theorem,
    required Iterable<PumpingLemmaProblem> problems,
  }) {
    final catalog = problems.toList(growable: false);
    final ids = <String>{};
    final prefix = theorem == PumpingLemmaTheorem.regular ? 'regular.' : 'cfl.';
    for (final problem in catalog) {
      if (problem.theorem != theorem) {
        throw StateError(
          'Challenge ${problem.id} belongs to ${problem.theorem.name}, not ${theorem.name}.',
        );
      }
      if (!problem.id.startsWith(prefix)) {
        throw StateError('Challenge ${problem.id} must start with $prefix.');
      }
      if (!ids.add(problem.id)) {
        throw StateError('Duplicate pumping challenge ID ${problem.id}.');
      }
      if (problem.expectedOutcome ==
          PumpingChallengeOutcome.learnerDetermines) {
        throw StateError(
          'Curated challenge ${problem.id} needs an expected learning outcome.',
        );
      }
      if (problem.suggestedWitness.length < problem.suggestedPumpingLength) {
        throw StateError(
          'Suggested witness for ${problem.id} must contain at least p tokens.',
        );
      }
      final suggested = evaluateCurated(problem, problem.suggestedWitness);
      if (suggested.isInLanguage != true) {
        throw StateError(
          'Suggested witness for ${problem.id} is not accepted by its oracle.',
        );
      }
      final outcomes = <bool>{};
      for (final example in problem.validationExamples) {
        final evaluated = evaluateCurated(problem, example.tokens);
        if (evaluated.isInLanguage != example.expectedMembership) {
          throw StateError(
            'Validation example for ${problem.id} disagrees with its oracle.',
          );
        }
        outcomes.add(example.expectedMembership);
      }
      if (!outcomes.containsAll(const {true, false})) {
        throw StateError(
          'Curated challenge ${problem.id} needs accepted and rejected validation examples.',
        );
      }
    }
    return List<PumpingLemmaProblem>.unmodifiable(catalog);
  }
}

PumpingLemmaProblem _problem({
  required String id,
  required PumpingLemmaTheorem theorem,
  required String language,
  required String representation,
  required int pumpingLength,
  required List<String> witness,
  required List<String> rejectedExample,
  required PumpingChallengeOutcome expectedOutcome,
}) => PumpingLemmaProblem(
  id: id,
  theorem: theorem,
  languageDescription: language,
  representationKind: PumpingLanguageRepresentationKind.curatedPredicate,
  representation: representation,
  contentVersion: 1,
  sourceRevision: '2026-08-25',
  suggestedPumpingLength: pumpingLength,
  suggestedWitness: witness,
  expectedOutcome: expectedOutcome,
  validationExamples: [
    PumpingMembershipExample(tokens: witness, expectedMembership: true),
    PumpingMembershipExample(
      tokens: rejectedExample,
      expectedMembership: false,
    ),
  ],
);

bool _equalBlocks(List<String> tokens, List<String> symbols) {
  if (tokens.isEmpty) return true;
  var cursor = 0;
  int? expected;
  for (final symbol in symbols) {
    var count = 0;
    while (cursor < tokens.length && tokens[cursor] == symbol) {
      count++;
      cursor++;
    }
    expected ??= count;
    if (count != expected) return false;
  }
  return cursor == tokens.length;
}

bool _isSquare(int value) {
  for (var root = 0; root * root <= value; root++) {
    if (root * root == value) return true;
  }
  return false;
}

bool _isCopy(List<String> tokens) {
  if (tokens.length.isOdd) return false;
  final middle = tokens.length ~/ 2;
  for (var index = 0; index < middle; index++) {
    if (tokens[index] != tokens[middle + index]) return false;
  }
  return true;
}

bool _hasOnly(List<String> tokens, Set<String> alphabet) =>
    tokens.every(alphabet.contains);

bool _isUnary(List<String> tokens) =>
    tokens.isNotEmpty && tokens.every((token) => token == 'a');

int _count(List<String> tokens, String symbol) =>
    tokens.where((token) => token == symbol).length;

bool _isPrime(int value) {
  if (value < 2) return false;
  for (var divisor = 2; divisor * divisor <= value; divisor++) {
    if (value % divisor == 0) return false;
  }
  return true;
}

bool _isPowerOfTwo(int value) => value > 0 && (value & (value - 1)) == 0;

bool _isPalindrome(List<String> tokens) {
  for (var index = 0; index < tokens.length ~/ 2; index++) {
    if (tokens[index] != tokens[tokens.length - index - 1]) return false;
  }
  return true;
}

bool _containsAdjacent(List<String> tokens, String left, String right) {
  if (!_hasOnly(tokens, const {'a', 'b'})) return false;
  for (var index = 0; index + 1 < tokens.length; index++) {
    if (tokens[index] == left && tokens[index + 1] == right) return true;
  }
  return false;
}

bool _isAlternatingAb(List<String> tokens) {
  if (tokens.length.isOdd) return false;
  for (var index = 0; index < tokens.length; index++) {
    if (tokens[index] != (index.isEven ? 'a' : 'b')) return false;
  }
  return true;
}

bool _hasOrderedCounts(
  List<String> tokens,
  List<String> symbols,
  bool Function(List<int> counts) predicate,
) {
  var cursor = 0;
  final counts = <int>[];
  for (final symbol in symbols) {
    var count = 0;
    while (cursor < tokens.length && tokens[cursor] == symbol) {
      cursor++;
      count++;
    }
    counts.add(count);
  }
  return cursor == tokens.length && predicate(counts);
}

bool _isMarkedPair(List<String> tokens, {required bool reverseRight}) {
  final marker = tokens.indexOf('#');
  if (marker < 0 || marker != tokens.lastIndexOf('#')) return false;
  final left = tokens.take(marker).toList(growable: false);
  final right = tokens.skip(marker + 1).toList(growable: false);
  if (!_hasOnly([...left, ...right], const {'a', 'b'})) return false;
  final expected = reverseRight ? left.reversed : left;
  return const ListEquality<String>().equals(
    expected.toList(growable: false),
    right,
  );
}

bool _isBalancedParentheses(List<String> tokens) {
  var depth = 0;
  for (final token in tokens) {
    if (token == '(') {
      depth++;
    } else if (token == ')') {
      depth--;
      if (depth < 0) return false;
    } else {
      return false;
    }
  }
  return depth == 0;
}
