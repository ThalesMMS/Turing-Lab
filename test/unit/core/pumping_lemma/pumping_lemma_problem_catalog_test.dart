import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';

void main() {
  final catalogs = <PumpingLemmaTheorem, List<PumpingLemmaProblem>>{
    PumpingLemmaTheorem.regular: PumpingLemmaProblemCatalog.regular,
    PumpingLemmaTheorem.contextFree: PumpingLemmaProblemCatalog.contextFree,
  };

  group('curated pumping challenge catalog', () {
    test('provides 13 stable challenges for each theorem', () {
      expect(PumpingLemmaProblemCatalog.regular, hasLength(13));
      expect(PumpingLemmaProblemCatalog.contextFree, hasLength(13));

      final all = catalogs.values.expand((catalog) => catalog).toList();
      expect(all.map((problem) => problem.id).toSet(), hasLength(26));
      for (final problem in all) {
        expect(
          problem.id,
          matches(RegExp(r'^(regular|cfl)\.[a-z0-9]+(?:-[a-z0-9]+)*$')),
        );
        expect(
          problem.expectedOutcome,
          isNot(PumpingChallengeOutcome.learnerDetermines),
        );
      }
    });

    test('covers varied lengths and successful and failed proof paths', () {
      for (final catalog in catalogs.values) {
        expect(
          catalog.map((problem) => problem.suggestedPumpingLength).toSet(),
          hasLength(greaterThanOrEqualTo(3)),
        );
        expect(
          catalog.map((problem) => problem.expectedOutcome).toSet(),
          containsAll(const {
            PumpingChallengeOutcome.counterexampleExpected,
            PumpingChallengeOutcome.noCounterexampleExpected,
          }),
        );
      }
    });

    test('validates every expected membership outcome deterministically', () {
      for (final entry in catalogs.entries) {
        expect(
          PumpingLemmaProblemCatalog.validateCatalog(
            theorem: entry.key,
            problems: entry.value,
          ),
          entry.value,
        );
        for (final problem in entry.value) {
          expect(
            problem.validationExamples.map(
              (example) => example.expectedMembership,
            ),
            containsAll(const [true, false]),
          );
          for (final example in problem.validationExamples) {
            final first = PumpingLemmaProblemCatalog.evaluateCurated(
              problem,
              example.tokens,
            );
            final second = PumpingLemmaProblemCatalog.evaluateCurated(
              problem,
              example.tokens,
            );
            expect(first.isInLanguage, example.expectedMembership);
            expect(second.isInLanguage, first.isInLanguage);
          }
        }
      }
    });

    test(
      'curated oracles reject tokens outside their documented alphabets',
      () {
        final failures = <String>[];
        for (final problem in catalogs.values.expand((catalog) => catalog)) {
          if (PumpingLemmaProblemCatalog.evaluateCurated(problem, const [
                '?',
                '?',
              ]).isInLanguage !=
              false) {
            failures.add(problem.id);
          }
        }
        expect(failures, isEmpty);
      },
    );

    test('suggested rounds agree with their declared learning outcomes', () {
      const sampledExponents = [0, 1, 2, 3, 4, 5];
      final failures = <String>[];
      for (final problem in catalogs.values.expand((catalog) => catalog)) {
        final decompositions = problem.theorem == PumpingLemmaTheorem.regular
            ? PumpingDecompositionEnumerator.regular(
                witness: problem.suggestedWitness,
                pumpingLength: problem.suggestedPumpingLength,
              )
            : PumpingDecompositionEnumerator.contextFree(
                witness: problem.suggestedWitness,
                pumpingLength: problem.suggestedPumpingLength,
              );
        bool remainsInLanguage(PumpingDecomposition decomposition, int value) =>
            PumpingLemmaProblemCatalog.evaluateCurated(
              problem,
              decomposition.pump(value),
            ).isInLanguage!;
        final everySplitHasCounterexample = decompositions.every(
          (decomposition) => sampledExponents.any(
            (value) => !remainsInLanguage(decomposition, value),
          ),
        );
        final someSplitSurvivesAllSamples = decompositions.any(
          (decomposition) => sampledExponents.every(
            (value) => remainsInLanguage(decomposition, value),
          ),
        );

        switch (problem.expectedOutcome) {
          case PumpingChallengeOutcome.counterexampleExpected:
            if (!everySplitHasCounterexample) failures.add(problem.id);
          case PumpingChallengeOutcome.noCounterexampleExpected:
            if (!someSplitSurvivesAllSamples) failures.add(problem.id);
          case PumpingChallengeOutcome.learnerDetermines:
            fail('Curated challenge ${problem.id} has no declared outcome.');
        }
      }
      expect(failures, isEmpty);
    });

    test('round-trips challenge metadata without changing validation', () {
      for (final problem in catalogs.values.expand((catalog) => catalog)) {
        final restored = PumpingLemmaProblem.fromJson(problem.toJson());
        expect(restored, problem);
        expect(restored.contentVersion, 1);
        for (final example in restored.validationExamples) {
          expect(
            PumpingLemmaProblemCatalog.evaluateCurated(
              restored,
              example.tokens,
            ).isInLanguage,
            example.expectedMembership,
          );
        }
      }
    });

    test('legacy problem payload defaults to content version one', () {
      final encoded = Map<String, Object?>.from(
        PumpingLemmaProblemCatalog.regular.first.toJson(),
      )..remove('contentVersion');

      expect(PumpingLemmaProblem.fromJson(encoded).contentVersion, 1);
    });

    test('rejects duplicate IDs', () {
      final problem = PumpingLemmaProblemCatalog.regular.first;

      expect(
        () => PumpingLemmaProblemCatalog.validateCatalog(
          theorem: PumpingLemmaTheorem.regular,
          problems: [problem, problem],
        ),
        throwsStateError,
      );
    });

    test('rejects malformed challenge metadata and validation cases', () {
      expect(
        () => PumpingLemmaProblem(
          id: ' ',
          theorem: PumpingLemmaTheorem.regular,
          languageDescription: 'L = {a^(2n) | n >= 0}',
          representationKind:
              PumpingLanguageRepresentationKind.curatedPredicate,
          representation: 'even-a-length',
          sourceRevision: 'test',
          suggestedPumpingLength: 2,
          suggestedWitness: const ['a', 'a'],
          expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
        ),
        throwsArgumentError,
      );

      final missingValidation = PumpingLemmaProblem(
        id: 'regular.missing-validation',
        customTitle: 'Missing validation examples',
        theorem: PumpingLemmaTheorem.regular,
        languageDescription: 'L = {a^(2n) | n >= 0}',
        representationKind: PumpingLanguageRepresentationKind.curatedPredicate,
        representation: 'even-a-length',
        sourceRevision: 'test',
        suggestedPumpingLength: 2,
        suggestedWitness: const ['a', 'a'],
        expectedOutcome: PumpingChallengeOutcome.noCounterexampleExpected,
      );
      expect(
        () => PumpingLemmaProblemCatalog.validateCatalog(
          theorem: PumpingLemmaTheorem.regular,
          problems: [missingValidation],
        ),
        throwsStateError,
      );

      final shortWitnessJson = {
        ...PumpingLemmaProblemCatalog.regular.first.toJson(),
        'id': 'regular.short-witness',
        'suggestedPumpingLength': 5,
        'suggestedWitness': const ['a', 'a', 'b', 'b'],
      };
      final shortWitness = PumpingLemmaProblem.fromJson(shortWitnessJson);
      expect(
        () => PumpingLemmaProblemCatalog.validateCatalog(
          theorem: PumpingLemmaTheorem.regular,
          problems: [shortWitness],
        ),
        throwsStateError,
      );
    });
  });
}
