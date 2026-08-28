import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/parsers/grammar_xml_codec.dart';

void main() {
  group('user-controlled derivation session', () {
    test(
      'requires the exact occurrence and enforces leftmost/rightmost modes',
      () {
        final grammar = _cfg(
          productions: [
            _cfgProduction('split', 'S', [_n('A'), _n('A')], 0),
            _cfgProduction('left', 'A', [_t('a')], 1),
            _cfgProduction('right', 'A', [_t('b')], 2),
          ],
          terminals: {_t('a'), _t('b')},
          nonterminals: {_n('S'), _n('A')},
        );
        var leftmost = UserDerivationSession.start(
          grammar: grammar,
          target: _sequence([_t('a'), _t('b')]),
          mode: UserDerivationMode.leftmost,
        ).session!;
        leftmost = leftmost
            .apply(grammar: grammar, productionId: 'split', startIndex: 0)
            .session;

        expect(
          leftmost
              .availableApplications(grammar)
              .map((application) => application.occurrence.startIndex),
          everyElement(0),
        );
        final restricted = leftmost.preview(
          grammar: grammar,
          productionId: 'right',
          startIndex: 1,
        );
        expect(restricted.isSuccess, isFalse);
        expect(
          restricted.diagnostics.single.code,
          UserDerivationDiagnosticCode.occurrenceRestricted,
        );

        var rightmost = UserDerivationSession.start(
          grammar: grammar,
          target: _sequence([_t('a'), _t('b')]),
          mode: UserDerivationMode.rightmost,
        ).session!;
        rightmost = rightmost
            .apply(grammar: grammar, productionId: 'split', startIndex: 0)
            .session;
        expect(
          rightmost
              .availableApplications(grammar)
              .map((application) => application.occurrence.startIndex),
          everyElement(1),
        );
      },
    );

    test(
      'applies Unicode tokens, previews moves, and builds an epsilon CFG tree',
      () {
        final grammar = _cfg(
          productions: [
            _cfgProduction('to-a', 'S', [_n('Á')], 0),
            _cfgProduction('empty', 'Á', const [], 1),
          ],
          terminals: const {},
          nonterminals: {_n('S'), _n('Á')},
        );
        var session = UserDerivationSession.start(
          grammar: grammar,
          target: const GrammarSymbolSequence.empty(),
          mode: UserDerivationMode.unrestrictedOccurrence,
        ).session!;
        final preview = session.preview(
          grammar: grammar,
          productionId: 'to-a',
          startIndex: 0,
        );
        expect(preview.isSuccess, isTrue);
        expect(preview.preview!.after.toString(), 'Á');
        session = session
            .apply(grammar: grammar, productionId: 'to-a', startIndex: 0)
            .session;
        session = session
            .apply(grammar: grammar, productionId: 'empty', startIndex: 0)
            .session;

        expect(session.status, UserDerivationStatus.success);
        expect(session.currentForm, const GrammarSymbolSequence.empty());
        expect(session.buildCfgTree(grammar)!.prettyPrint(), contains('ε'));
      },
    );

    test('undo, redo, branching, and restart use explicit linear history', () {
      final grammar = _simpleCfg();
      var session = UserDerivationSession.start(
        grammar: grammar,
        target: _sequence([_t('a')]),
        mode: UserDerivationMode.leftmost,
      ).session!;
      session = session
          .apply(grammar: grammar, productionId: 'to-a', startIndex: 0)
          .session;
      expect(session.status, UserDerivationStatus.success);

      session = session.undo(grammar).session;
      expect(session.canRedo, isTrue);
      session = session.redo(grammar).session;
      expect(session.status, UserDerivationStatus.success);
      session = session.branchFromStep(grammar, 0).session;
      session = session
          .apply(grammar: grammar, productionId: 'to-b', startIndex: 0)
          .session;
      expect(session.steps, hasLength(1));
      expect(session.steps.single.productionId, 'to-b');
      expect(session.canRedo, isFalse);
      expect(session.status, UserDerivationStatus.localDeadEnd);
      expect(
        session.diagnostics.single.code,
        UserDerivationDiagnosticCode.terminalMismatch,
      );

      session = session.restart(grammar).session;
      expect(session.steps, isEmpty);
      expect(session.cursor, 0);
      expect(session.canRedo, isFalse);
      expect(session.status, UserDerivationStatus.active);
    });

    test('unrestricted mode applies a multi-symbol LHS without a CFG tree', () {
      final grammar = UnrestrictedGrammar(
        id: 'u',
        name: 'Unrestricted',
        revision: 3,
        terminals: {_t('a'), _t('b')},
        nonterminals: {_n('S'), _n('A')},
        startSymbol: _n('S'),
        productions: [
          _phraseProduction('seed', [_n('S')], [_n('A'), _t('a')], 0),
          _phraseProduction('pair', [_n('A'), _t('a')], [_t('b')], 1),
        ],
      );
      var session = UserDerivationSession.start(
        grammar: grammar,
        target: _sequence([_t('b')]),
        mode: UserDerivationMode.unrestrictedOccurrence,
      ).session!;
      session = session
          .apply(grammar: grammar, productionId: 'seed', startIndex: 0)
          .session;
      final pair = session.availableApplications(grammar).single;
      expect(pair.production.left.length, 2);
      expect(pair.occurrence.startIndex, 0);
      session = session
          .apply(grammar: grammar, productionId: 'pair', startIndex: 0)
          .session;

      expect(session.status, UserDerivationStatus.success);
      expect(session.buildCfgTree(grammar), isNull);
    });

    test('challenge mode restricts productions and step count', () {
      final grammar = _simpleCfg();
      expect(
        () => UserDerivationChallenge(
          id: 'invalid',
          enforcedMode: UserDerivationMode.challengeEnforced,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'A challenge must enforce a concrete occurrence mode.',
          ),
        ),
      );
      final challenge = UserDerivationChallenge(
        id: 'only-a',
        enforcedMode: UserDerivationMode.leftmost,
        maxSteps: 1,
        allowedProductionIds: const {'to-a'},
      );
      final session = UserDerivationSession.start(
        grammar: grammar,
        target: _sequence([_t('a')]),
        mode: UserDerivationMode.challengeEnforced,
        challenge: challenge,
      ).session!;

      expect(
        session
            .availableApplications(grammar)
            .map((application) => application.production.id),
        ['to-a'],
      );
      expect(
        session
            .preview(grammar: grammar, productionId: 'to-b', startIndex: 0)
            .diagnostics
            .single
            .code,
        UserDerivationDiagnosticCode.challengeProductionRestricted,
      );
    });

    test('round-trips losslessly and invalidates changed source revisions', () {
      final grammar = _simpleCfg();
      var session = UserDerivationSession.start(
        grammar: grammar,
        target: _sequence([_t('a')]),
        mode: UserDerivationMode.leftmost,
      ).session!;
      session = session
          .apply(grammar: grammar, productionId: 'to-a', startIndex: 0)
          .session;

      final restored = UserDerivationSession.restore(
        session.toJson(),
        grammar: grammar,
      );
      expect(restored.isSuccess, isTrue);
      expect(restored.session!.toJson(), session.toJson());

      final changed = ContextFreeGrammar(
        id: grammar.id,
        name: grammar.name,
        revision: grammar.revision + 1,
        terminals: grammar.terminals,
        nonterminals: grammar.nonterminals,
        startSymbol: grammar.startSymbol,
        productions: grammar.productions,
      );
      final invalidated = UserDerivationSession.restore(
        session.toJson(),
        grammar: changed,
      );
      expect(invalidated.session!.status, UserDerivationStatus.invalidated);
      expect(
        invalidated.diagnostics.single.code,
        UserDerivationDiagnosticCode.sourceChanged,
      );

      final future = Map<String, Object?>.from(session.toJson());
      future['schema'] = {
        'id': UserDerivationSession.schemaId,
        'version': UserDerivationSession.schemaVersion + 1,
      };
      expect(
        UserDerivationSession.restore(
          future,
          grammar: grammar,
        ).diagnostics.single.code,
        UserDerivationDiagnosticCode.unsupportedSchema,
      );
    });

    test(
      'target changes fork explicitly and local dead ends make no proof',
      () {
        final grammar = _simpleCfg();
        var session = UserDerivationSession.start(
          grammar: grammar,
          target: _sequence([_t('a')]),
          mode: UserDerivationMode.leftmost,
        ).session!;
        session = session
            .apply(grammar: grammar, productionId: 'to-b', startIndex: 0)
            .session;
        expect(session.status, UserDerivationStatus.localDeadEnd);
        expect(
          session.diagnostics.single.code,
          UserDerivationDiagnosticCode.terminalMismatch,
        );

        final fork = session.forkForTarget(
          grammar: grammar,
          target: _sequence([_t('b')]),
        );
        expect(fork.isSuccess, isTrue);
        expect(fork.session!.steps, isEmpty);
        expect(fork.session!.status, UserDerivationStatus.active);
      },
    );
  });

  group('user-controlled derivation hints', () {
    test(
      'suggests a reproducible bounded first move without applying it',
      () async {
        final grammar = _cfg(
          terminals: {_t('a')},
          nonterminals: {_n('S'), _n('A')},
          productions: [
            _cfgProduction('to-a', 'S', [_n('A')], 0),
            _cfgProduction('leaf', 'A', [_t('a')], 1),
          ],
        );
        final session = UserDerivationSession.start(
          grammar: grammar,
          target: _sequence([_t('a')]),
          mode: UserDerivationMode.leftmost,
        ).session!;

        final hint = await UserDerivationHintSearch.run(
          session: session,
          grammar: grammar,
        );

        expect(hint.outcome, UserDerivationHintOutcome.suggested);
        expect(hint.suggestion!.production.id, 'to-a');
        expect(hint.suggestion!.occurrence.startIndex, 0);
        expect(hint.witness.map((step) => step.productionId), ['to-a', 'leaf']);
        expect(session.steps, isEmpty);
      },
    );

    test(
      'reports limit exhaustion as boundedUnknown, not noSuggestion',
      () async {
        final grammar = _cfg(
          terminals: {_t('a')},
          nonterminals: {_n('S'), _n('A')},
          productions: [
            _cfgProduction('to-a', 'S', [_n('A')], 0),
            _cfgProduction('leaf', 'A', [_t('a')], 1),
          ],
        );
        final session = UserDerivationSession.start(
          grammar: grammar,
          target: _sequence([_t('a')]),
          mode: UserDerivationMode.leftmost,
        ).session!;

        final hint = await UserDerivationHintSearch.run(
          session: session,
          grammar: grammar,
          limits: const UserDerivationHintLimits(maxDepth: 0),
        );

        expect(hint.outcome, UserDerivationHintOutcome.boundedUnknown);
        expect(hint.limit, UserDerivationHintLimit.depth);
        expect(hint.suggestion, isNull);
      },
    );

    test('cancels cooperatively after yielding progress', () async {
      final grammar = _cfg(
        terminals: {_t('a')},
        nonterminals: {_n('S')},
        productions: [
          _cfgProduction('grow', 'S', [_n('S'), _n('S')], 0),
        ],
      );
      final session = UserDerivationSession.start(
        grammar: grammar,
        target: _sequence([_t('a')]),
        mode: UserDerivationMode.unrestrictedOccurrence,
      ).session!;
      final token = UserDerivationHintCancellationToken();
      var progressCalls = 0;

      final hint = await UserDerivationHintSearch.run(
        session: session,
        grammar: grammar,
        cancellationToken: token,
        limits: const UserDerivationHintLimits(
          yieldEvery: 1,
          maxSymbolCount: 64,
        ),
        onProgress: (_) {
          progressCalls++;
          token.cancel();
        },
      );

      expect(progressCalls, greaterThan(0));
      expect(hint.outcome, UserDerivationHintOutcome.cancelled);
    });

    test(
      'labels an exhausted dead end as noSuggestion without a proof claim',
      () async {
        final grammar = _simpleCfg();
        var session = UserDerivationSession.start(
          grammar: grammar,
          target: _sequence([_t('a')]),
          mode: UserDerivationMode.leftmost,
        ).session!;
        session = session
            .apply(grammar: grammar, productionId: 'to-b', startIndex: 0)
            .session;

        final hint = await UserDerivationHintSearch.run(
          session: session,
          grammar: grammar,
        );

        expect(hint.outcome, UserDerivationHintOutcome.noSuggestion);
        expect(hint.limit, isNull);
      },
    );

    test(
      'finds a deterministic suggestion in an ambiguous recursive grammar',
      () async {
        final grammar = _cfg(
          terminals: {_t('a')},
          nonterminals: {_n('S')},
          productions: [
            _cfgProduction('split', 'S', [_n('S'), _n('S')], 0),
            _cfgProduction('leaf', 'S', [_t('a')], 1),
          ],
        );
        final session = UserDerivationSession.start(
          grammar: grammar,
          target: _sequence([_t('a'), _t('a'), _t('a')]),
          mode: UserDerivationMode.leftmost,
        ).session!;

        final hint = await UserDerivationHintSearch.run(
          session: session,
          grammar: grammar,
        );

        expect(hint.outcome, UserDerivationHintOutcome.suggested);
        expect(hint.suggestion!.production.id, 'split');
        expect(hint.witness, isNotEmpty);
      },
    );
  });

  test(
    'legacy CFG adapter preserves multi-character target token boundaries',
    () {
      final now = DateTime(2026);
      final legacy = Grammar(
        id: 'legacy-cfg',
        name: 'Legacy CFG',
        terminals: const {'token🙂'},
        nonterminals: const {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['token🙂', 'token🙂'],
          ),
        },
        type: GrammarType.contextFree,
        created: now,
        modified: now,
      );

      final adapted = LegacyContextFreeGrammarAdapter.adapt(
        legacy,
        revision: 9,
      );
      final target = LegacyContextFreeGrammarAdapter.tokenizeTarget(
        legacy,
        'token🙂token🙂',
      );

      expect(target.isSuccess, isTrue);
      expect(target.data!.length, 2);
      expect(
        target.data!.symbols.every((symbol) => symbol.value == 'token🙂'),
        isTrue,
      );
      final session = UserDerivationSession.start(
        grammar: adapted,
        target: target.data!,
        mode: UserDerivationMode.leftmost,
      ).session!;
      expect(
        session
            .apply(grammar: adapted, productionId: 'p1', startIndex: 0)
            .session
            .status,
        UserDerivationStatus.success,
      );
    },
  );

  test('legacy CFG adapter computes deterministic content revisions', () {
    final now = DateTime(2026);
    Grammar grammar(Set<Production> productions) => Grammar(
      id: 'revision-cfg',
      name: 'Revision CFG',
      terminals: const {'token🙂'},
      nonterminals: const {'S'},
      startSymbol: 'S',
      productions: productions,
      type: GrammarType.contextFree,
      created: now,
      modified: now,
    );
    final original = grammar({
      const Production(id: 'p1', leftSide: ['S'], rightSide: ['token🙂']),
    });
    final sameContent = original.copyWith(
      terminals: {'token🙂'},
      nonterminals: {'S'},
    );
    final changed = grammar({
      const Production(
        id: 'p1',
        leftSide: ['S'],
        rightSide: [],
        isLambda: true,
      ),
    });

    expect(
      LegacyContextFreeGrammarAdapter.sourceRevision(original),
      LegacyContextFreeGrammarAdapter.sourceRevision(sameContent),
    );
    expect(
      LegacyContextFreeGrammarAdapter.sourceRevision(original),
      isNot(LegacyContextFreeGrammarAdapter.sourceRevision(changed)),
    );
  });

  test(
    'runs the JFLAP occurrence fixture with stable imported production IDs',
    () {
      final xml = File(
        'test/fixtures/interoperability/grammar_user_derivation_occurrences.jff',
      ).readAsStringSync();
      final decoded = const GrammarXmlCodec().decodeGrammarXml(xml);
      expect(decoded.isSuccess, isTrue);
      final adapted = LegacyContextFreeGrammarAdapter.adapt(
        decoded.data!,
        revision: 1,
      );
      var session = UserDerivationSession.start(
        grammar: adapted,
        target: LegacyContextFreeGrammarAdapter.tokenizeTarget(
          decoded.data!,
          'token🙂token🙂',
        ).data!,
        mode: UserDerivationMode.leftmost,
      ).session!;
      session = session
          .apply(grammar: adapted, productionId: 'p0', startIndex: 0)
          .session;

      expect(
        PhraseProductionApplicator.allApplications(
          session.currentForm,
          adapted.phraseProductions,
        ).where((application) => application.production.id == 'p1'),
        hasLength(2),
      );
      expect(
        session
            .availableApplications(adapted)
            .map((application) => application.occurrence.startIndex),
        everyElement(0),
      );
    },
  );
}

ContextFreeGrammar _simpleCfg() => _cfg(
  terminals: {_t('a'), _t('b')},
  nonterminals: {_n('S')},
  productions: [
    _cfgProduction('to-a', 'S', [_t('a')], 0),
    _cfgProduction('to-b', 'S', [_t('b')], 1),
  ],
);

ContextFreeGrammar _cfg({
  required Set<TerminalGrammarSymbol> terminals,
  required Set<NonterminalGrammarSymbol> nonterminals,
  required List<ContextFreeProduction> productions,
}) => ContextFreeGrammar(
  id: 'cfg',
  name: 'CFG',
  revision: 7,
  terminals: terminals,
  nonterminals: nonterminals,
  startSymbol: _n('S'),
  productions: productions,
);

ContextFreeProduction _cfgProduction(
  String id,
  String left,
  List<PhraseGrammarSymbol> right,
  int order,
) => ContextFreeProduction(
  id: id,
  left: _n(left),
  right: _sequence(right),
  order: order,
);

PhraseStructureProduction _phraseProduction(
  String id,
  List<PhraseGrammarSymbol> left,
  List<PhraseGrammarSymbol> right,
  int order,
) => PhraseStructureProduction(
  id: id,
  left: _sequence(left),
  right: _sequence(right),
  order: order,
);

GrammarSymbolSequence _sequence(List<PhraseGrammarSymbol> symbols) =>
    GrammarSymbolSequence(symbols);

TerminalGrammarSymbol _t(String value) => TerminalGrammarSymbol(value);
NonterminalGrammarSymbol _n(String value) => NonterminalGrammarSymbol(value);
