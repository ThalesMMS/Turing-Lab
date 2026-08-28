import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('phrase-structure classification', () {
    test('keeps CFG and unrestricted model types separate', () {
      final cfg = ContextFreeGrammar(
        id: 'cfg',
        name: 'CFG',
        revision: 0,
        terminals: const [TerminalGrammarSymbol('a')],
        nonterminals: const [NonterminalGrammarSymbol('S')],
        startSymbol: const NonterminalGrammarSymbol('S'),
        productions: [
          ContextFreeProduction(
            id: 'p0',
            left: const NonterminalGrammarSymbol('S'),
            right: _sequence(const [TerminalGrammarSymbol('a')]),
            order: 0,
          ),
        ],
      );
      final unrestricted = cfg.toUnrestricted();

      expect(cfg, isA<ContextFreeGrammar>());
      expect(unrestricted, isA<UnrestrictedGrammar>());
      expect(unrestricted, isNot(isA<ContextFreeGrammar>()));
      expect(
        PhraseGrammarClassifier.classify(unrestricted).classification,
        PhraseGrammarClassification.regular,
      );
    });

    test('distinguishes context-sensitive and unrestricted restrictions', () {
      final contextSensitive = _grammar([
        _production(
          'expand',
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('S'),
          ],
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('S'),
            TerminalGrammarSymbol('b'),
          ],
        ),
      ]);
      final contracting = _grammar([
        _production(
          'contract',
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('S'),
          ],
          const [TerminalGrammarSymbol('a')],
        ),
      ]);

      expect(
        PhraseGrammarClassifier.classify(contextSensitive).classification,
        PhraseGrammarClassification.contextSensitive,
      );
      final report = PhraseGrammarClassifier.classify(contracting);
      expect(report.classification, PhraseGrammarClassification.unrestricted);
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        contains(PhraseGrammarDiagnosticCode.contextSensitiveContracting),
      );
    });

    test('handles the start-epsilon exception exactly', () {
      final allowed = _grammar([
        _production(
          'epsilon',
          const [NonterminalGrammarSymbol('S')],
          const [],
        ),
      ]);
      final startOnRight = _grammar([
        _production(
          'epsilon',
          const [NonterminalGrammarSymbol('S')],
          const [],
        ),
        _production(
          'returns-start',
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('S'),
          ],
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('S'),
          ],
          order: 1,
        ),
      ]);

      expect(
        PhraseGrammarClassifier.classify(allowed).diagnostics.map(
              (diagnostic) => diagnostic.code,
            ),
        isNot(contains(
          PhraseGrammarDiagnosticCode.contextSensitiveEpsilonRestriction,
        )),
      );
      expect(
        PhraseGrammarClassifier.classify(startOnRight).diagnostics.map(
              (diagnostic) => diagnostic.code,
            ),
        contains(PhraseGrammarDiagnosticCode.contextSensitiveStartOnRight),
      );
    });

    test('reports structural invalidity and duplicate identities', () {
      final grammar = _grammar([
        _production('same', const [], const []),
        _production('same', const [], const [], order: 1),
      ]);
      final report = PhraseGrammarClassifier.classify(grammar);

      expect(report.classification, PhraseGrammarClassification.invalid);
      expect(
        report.errors.map((diagnostic) => diagnostic.code),
        containsAll([
          PhraseGrammarDiagnosticCode.duplicateProductionId,
          PhraseGrammarDiagnosticCode.duplicateProduction,
          PhraseGrammarDiagnosticCode.emptyLeftSide,
        ]),
      );
    });

    test('reports regular orientation and rejects mixed linear rules', () {
      final right = _grammar([
        _production(
          'right',
          const [NonterminalGrammarSymbol('S')],
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('A'),
          ],
        ),
      ]);
      final left = _grammar([
        _production(
          'left',
          const [NonterminalGrammarSymbol('S')],
          const [
            NonterminalGrammarSymbol('A'),
            TerminalGrammarSymbol('a'),
          ],
        ),
      ]);
      final mixed = _grammar([
        ...right.productions,
        _production(
          'left',
          const [NonterminalGrammarSymbol('A')],
          const [
            NonterminalGrammarSymbol('S'),
            TerminalGrammarSymbol('b'),
          ],
          order: 1,
        ),
      ]);

      expect(
        PhraseGrammarClassifier.classify(right).regularOrientation,
        PhraseGrammarRegularOrientation.rightLinear,
      );
      expect(
        PhraseGrammarClassifier.classify(left).regularOrientation,
        PhraseGrammarRegularOrientation.leftLinear,
      );
      final mixedReport = PhraseGrammarClassifier.classify(mixed);
      expect(
        mixedReport.classification,
        PhraseGrammarClassification.contextFree,
      );
      expect(
        mixedReport.regularOrientation,
        PhraseGrammarRegularOrientation.mixed,
      );
      expect(
        mixedReport.diagnostics.map((item) => item.code),
        contains(PhraseGrammarDiagnosticCode.regularMixedOrientation),
      );
    });

    test('reports strict/weak CNF and GNF through canonical predicates', () {
      final strictCnf = _grammar([
        _production(
          'binary',
          const [NonterminalGrammarSymbol('S')],
          const [
            NonterminalGrammarSymbol('A'),
            NonterminalGrammarSymbol('A'),
          ],
        ),
        _production(
          'terminal',
          const [NonterminalGrammarSymbol('A')],
          const [TerminalGrammarSymbol('a')],
          order: 1,
        ),
      ]);
      final weakCnf = _grammar([
        _production(
          'epsilon',
          const [NonterminalGrammarSymbol('S')],
          const [],
        ),
      ]);
      final gnf = _grammar([
        _production(
          'gnf',
          const [NonterminalGrammarSymbol('S')],
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('A'),
          ],
        ),
      ]);

      expect(
        PhraseGrammarClassifier.classify(strictCnf).normalForms,
        containsAll([
          PhraseGrammarNormalForm.strictChomsky,
          PhraseGrammarNormalForm.weakChomsky,
        ]),
      );
      expect(
        PhraseGrammarClassifier.classify(weakCnf).normalForms,
        contains(PhraseGrammarNormalForm.weakChomsky),
      );
      expect(
        PhraseGrammarClassifier.classify(weakCnf).normalForms,
        isNot(contains(PhraseGrammarNormalForm.strictChomsky)),
      );
      expect(
        PhraseGrammarClassifier.classify(gnf).normalForms,
        contains(PhraseGrammarNormalForm.greibach),
      );
    });

    test('evidence and diagnostic ordering is stable by production identity',
        () {
      final first = _production(
        'z-last',
        const [NonterminalGrammarSymbol('S')],
        const [
          NonterminalGrammarSymbol('A'),
          TerminalGrammarSymbol('a'),
        ],
        order: 1,
      );
      final second = _production(
        'a-first',
        const [NonterminalGrammarSymbol('A')],
        const [
          TerminalGrammarSymbol('b'),
          NonterminalGrammarSymbol('S'),
        ],
      );

      final forward = PhraseGrammarClassifier.classify(
        _grammar([first, second]),
      );
      final reverse = PhraseGrammarClassifier.classify(
        _grammar([second, first]),
      );

      expect(
        forward.productionEvidence.map((item) => item.productionId),
        reverse.productionEvidence.map((item) => item.productionId),
      );
      expect(
        forward.productionEvidence.first.violated,
        contains(PhraseGrammarPredicateCode.leftLinearRule),
      );
      expect(
        forward.toStructuredJson(),
        reverse.toStructuredJson(),
      );
    });

    test('legacy adapter reports declared type mismatch without rewriting it',
        () {
      final grammar = Grammar(
        id: 'legacy',
        name: 'Legacy',
        terminals: const {'a'},
        nonterminals: const {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p0',
            leftSide: ['S'],
            rightSide: ['a'],
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime(2026),
        modified: DateTime(2026),
      );

      final report = PhraseGrammarClassifier.classifyLegacy(grammar);

      expect(report.classification, PhraseGrammarClassification.regular);
      expect(
        report.declaredClassification,
        PhraseGrammarClassification.contextFree,
      );
      expect(report.declaredTypeMatches, isFalse);
      expect(grammar.type, GrammarType.contextFree);
      expect(
        report.diagnostics.map((item) => item.code),
        contains(PhraseGrammarDiagnosticCode.declaredTypeMismatch),
      );
    });

    test('defines empty, malformed epsilon, and token-length outcomes', () {
      final empty = _grammar(const []);
      final malformedEpsilon = _grammar([
        _production(
          'bad-epsilon',
          const [NonterminalGrammarSymbol('A')],
          const [],
        ),
      ]);
      final tokenCounted = UnrestrictedGrammar(
        id: 'tokens',
        name: 'Tokens',
        revision: 0,
        terminals: const [
          TerminalGrammarSymbol('multi-character'),
          TerminalGrammarSymbol('🙂'),
        ],
        nonterminals: const [NonterminalGrammarSymbol('Start')],
        startSymbol: const NonterminalGrammarSymbol('Start'),
        productions: [
          _production(
            'unicode',
            const [NonterminalGrammarSymbol('Start')],
            const [
              TerminalGrammarSymbol('multi-character'),
              TerminalGrammarSymbol('🙂'),
            ],
          ),
        ],
      );

      expect(
        PhraseGrammarClassifier.classify(empty).diagnostics.map(
              (item) => item.code,
            ),
        contains(PhraseGrammarDiagnosticCode.emptyGrammar),
      );
      final malformedReport =
          PhraseGrammarClassifier.classify(malformedEpsilon);
      expect(
        malformedReport.classification,
        PhraseGrammarClassification.contextFree,
      );
      expect(
        malformedReport.productionEvidence.single.violated,
        containsAll([
          PhraseGrammarPredicateCode.epsilonRestriction,
          PhraseGrammarPredicateCode.rightLinearRule,
          PhraseGrammarPredicateCode.leftLinearRule,
        ]),
      );
      expect(
        PhraseGrammarClassifier.classify(tokenCounted).classification,
        PhraseGrammarClassification.regular,
      );
    });
  });

  group('phrase replacement', () {
    test('returns every overlapping occurrence with stable token indices', () {
      final production = _production(
        'overlap',
        const [
          NonterminalGrammarSymbol('A'),
          NonterminalGrammarSymbol('A'),
        ],
        const [TerminalGrammarSymbol('b')],
      );
      final form = _sequence(const [
        NonterminalGrammarSymbol('A'),
        NonterminalGrammarSymbol('A'),
        NonterminalGrammarSymbol('A'),
      ]);

      final applications = PhraseProductionApplicator.allApplications(
        form,
        [production],
      );

      expect(applications.map((item) => item.occurrence.startIndex), [0, 1]);
      expect(
          applications.map((item) => item.occurrence.occurrenceIndex), [0, 1]);
      expect(
        applications.first.after.symbols,
        const [TerminalGrammarSymbol('b'), NonterminalGrammarSymbol('A')],
      );
      expect(
        applications.last.after.symbols,
        const [NonterminalGrammarSymbol('A'), TerminalGrammarSymbol('b')],
      );
    });

    test('canonical production order ignores insertion order', () {
      final first = _production(
        'p1',
        const [NonterminalGrammarSymbol('S')],
        const [TerminalGrammarSymbol('a')],
        order: 1,
      );
      final zero = _production(
        'p0',
        const [NonterminalGrammarSymbol('S')],
        const [TerminalGrammarSymbol('b')],
      );
      final form = _sequence(const [NonterminalGrammarSymbol('S')]);

      final forward = PhraseProductionApplicator.allApplications(
        form,
        [first, zero],
      );
      final reverse = PhraseProductionApplicator.allApplications(
        form,
        [zero, first],
      );

      expect(forward.map((item) => item.production.id), ['p0', 'p1']);
      expect(reverse.map((item) => item.production.id), ['p0', 'p1']);
    });
  });

  group('bounded derivation', () {
    test('accepts with exact production and occurrence witness', () async {
      final grammar = _grammar([
        _production(
          'grow',
          const [NonterminalGrammarSymbol('S')],
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('S'),
          ],
        ),
        _production(
          'finish',
          const [NonterminalGrammarSymbol('S')],
          const [TerminalGrammarSymbol('b')],
          order: 1,
        ),
      ]);

      final outcome = await BoundedDerivationSearch.run(
        grammar: grammar,
        input: _sequence(const [
          TerminalGrammarSymbol('a'),
          TerminalGrammarSymbol('a'),
          TerminalGrammarSymbol('b'),
        ]),
      );

      expect(outcome, isA<DerivationAccepted>());
      final witness = (outcome as DerivationAccepted).witness;
      expect(witness.map((step) => step.production.id), [
        'grow',
        'grow',
        'finish',
      ]);
      expect(witness.map((step) => step.occurrence.startIndex), [0, 1, 2]);
    });

    test('never turns a truncated infinite growth into rejection', () async {
      final grammar = _grammar([
        _production(
          'grow',
          const [NonterminalGrammarSymbol('S')],
          const [
            NonterminalGrammarSymbol('S'),
            NonterminalGrammarSymbol('S'),
          ],
        ),
      ]);

      final outcome = await BoundedDerivationSearch.run(
        grammar: grammar,
        input: _sequence(const [TerminalGrammarSymbol('a')]),
        limits: const DerivationSearchLimits(
          maxExpandedForms: 4,
          maxVisitedForms: 8,
          maxFrontierSize: 4,
          maxSymbolCount: 8,
          yieldEvery: 1,
        ),
      );

      expect(outcome, isA<DerivationBoundedUnknown>());
      expect(outcome, isNot(isA<DerivationExhausted>()));
    });

    test('symbol, frontier, and time pruning all stay bounded unknown',
        () async {
      final grammar = _grammar([
        _production(
          'branch-a',
          const [NonterminalGrammarSymbol('S')],
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('S'),
          ],
        ),
        _production(
          'branch-b',
          const [NonterminalGrammarSymbol('S')],
          const [
            TerminalGrammarSymbol('b'),
            NonterminalGrammarSymbol('S'),
          ],
          order: 1,
        ),
      ]);
      final target = _sequence(const [TerminalGrammarSymbol('a')]);

      final symbolLimited = await BoundedDerivationSearch.run(
        grammar: grammar,
        input: target,
        limits: const DerivationSearchLimits(maxSymbolCount: 1),
      );
      final frontierLimited = await BoundedDerivationSearch.run(
        grammar: grammar,
        input: target,
        limits: const DerivationSearchLimits(maxFrontierSize: 1),
      );
      final timeLimited = await BoundedDerivationSearch.run(
        grammar: grammar,
        input: target,
        limits: const DerivationSearchLimits(timeLimit: Duration.zero),
      );

      expect(symbolLimited, isA<DerivationBoundedUnknown>());
      expect(frontierLimited, isA<DerivationBoundedUnknown>());
      expect(timeLimited, isA<DerivationBoundedUnknown>());
    });

    test('reports exhausted only for a fully explored finite space', () async {
      final grammar = _grammar([
        _production(
          'finish',
          const [NonterminalGrammarSymbol('S')],
          const [TerminalGrammarSymbol('b')],
        ),
      ]);

      final outcome = await BoundedDerivationSearch.run(
        grammar: grammar,
        input: _sequence(const [TerminalGrammarSymbol('a')]),
      );

      expect(outcome, isA<DerivationExhausted>());
    });

    test('cancels cooperatively and rejects undeclared input as invalid',
        () async {
      final grammar = _grammar([
        _production(
          'loop',
          const [NonterminalGrammarSymbol('S')],
          const [
            TerminalGrammarSymbol('a'),
            NonterminalGrammarSymbol('S'),
          ],
        ),
      ]);
      final token = DerivationCancellationToken()..cancel();

      expect(
        await BoundedDerivationSearch.run(
          grammar: grammar,
          input: _sequence(const [TerminalGrammarSymbol('a')]),
          cancellationToken: token,
        ),
        isA<DerivationCancelled>(),
      );
      expect(
        await BoundedDerivationSearch.run(
          grammar: grammar,
          input: _sequence(const [TerminalGrammarSymbol('unknown')]),
        ),
        isA<DerivationInvalid>(),
      );
    });
  });
}

UnrestrictedGrammar _grammar(List<PhraseStructureProduction> productions) =>
    UnrestrictedGrammar(
      id: 'grammar',
      name: 'Grammar',
      revision: 0,
      terminals: const [
        TerminalGrammarSymbol('a'),
        TerminalGrammarSymbol('b'),
      ],
      nonterminals: const [
        NonterminalGrammarSymbol('S'),
        NonterminalGrammarSymbol('A'),
      ],
      startSymbol: const NonterminalGrammarSymbol('S'),
      productions: productions,
    );

PhraseStructureProduction _production(
  String id,
  List<PhraseGrammarSymbol> left,
  List<PhraseGrammarSymbol> right, {
  int order = 0,
}) =>
    PhraseStructureProduction(
      id: id,
      left: _sequence(left),
      right: _sequence(right),
      order: order,
    );

GrammarSymbolSequence _sequence(List<PhraseGrammarSymbol> symbols) =>
    GrammarSymbolSequence(symbols);
