import 'package:test/test.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

Grammar _grammar({
  String startSymbol = 'S',
  Set<String> nonTerminals = const {'S'},
  Set<String> terminals = const {},
  Set<Production> productions = const {},
}) {
  return Grammar(
    id: 'characterization',
    name: 'Characterization grammar',
    terminals: terminals,
    nonterminals: nonTerminals,
    startSymbol: startSymbol,
    productions: productions,
    type: GrammarType.contextFree,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
  );
}

Production _production(
  String id,
  String left,
  List<String> right, {
  int order = 0,
}) {
  return Production(
    id: id,
    leftSide: [left],
    rightSide: right,
    isLambda: right.isEmpty,
    order: order,
  );
}

List<String> _productionShapes(Grammar grammar) {
  return grammar.productions
      .map(
        (production) =>
            '${production.leftSide.join(' ')}->${production.rightSide.join(' ')}',
      )
      .toList()
    ..sort();
}

void main() {
  test('GrammarAnalyzer preserves its public default constructor', () {
    expect(const GrammarAnalyzer(), isA<GrammarAnalyzer>());
  });

  test('ListEquality preserves its public const API and shallow equality', () {
    const equality = ListEquality();

    expect(identical(equality, const ListEquality()), isTrue);
    expect(equality.hashCode, const ListEquality().hashCode);
    expect(equality.equals(const [1, 'a', null], const [1, 'a', null]), isTrue);
    expect(equality.equals(const [1, 'a'], const [1, 'b']), isFalse);
    expect(equality.equals(const [1], const [1, 2]), isFalse);
  });

  group('GrammarAnalysisContext', () {
    test('takes immutable sorted snapshots of symbols and productions', () {
      final terminals = <String>{'z', 'a'};
      final nonTerminals = <String>{'Tail', 'S'};
      final right = <String>['z'];
      final productions = <Production>{
        Production(
          id: 'p2',
          leftSide: const ['Tail'],
          rightSide: right,
          order: 2,
        ),
        _production('p1', 'S', const ['a'], order: 1),
      };
      final context = GrammarAnalysisContext(
        _grammar(
          nonTerminals: nonTerminals,
          terminals: terminals,
          productions: productions,
        ),
      );

      terminals.add('later');
      nonTerminals.add('Later');
      right.add('later');

      expect(context.terminals.toList(), ['a', 'z']);
      expect(context.nonTerminals.toList(), ['S', 'Tail']);
      expect(context.productions.map((production) => production.id), [
        'p1',
        'p2',
      ]);
      expect(context.productions.last.rightSide, ['z']);
      expect(() => context.terminals.add('x'), throwsUnsupportedError);
      expect(
        () => context.productionsByNonTerminal['S']!.add(const ['x']),
        throwsUnsupportedError,
      );
    });

    test('transformations use a detached immutable grammar snapshot', () {
      final terminals = <String>{'a'};
      final nonTerminals = <String>{'S'};
      final right = <String>['a'];
      final productions = <Production>{_production('p1', 'S', right)};
      final source = _grammar(
        terminals: terminals,
        nonTerminals: nonTerminals,
        productions: productions,
      );
      final context = GrammarAnalysisContext(source);

      terminals
        ..clear()
        ..add('changed');
      nonTerminals
        ..clear()
        ..add('Changed');
      right[0] = 'changed';
      productions.clear();

      final result = GrammarLeftRecursionTransformer(
        context,
      ).removeLeftRecursion();
      final transformed = result.data!.value;

      expect(result.isSuccess, isTrue);
      expect(transformed, isNot(same(source)));
      expect(transformed.terminals, {'a'});
      expect(transformed.nonterminals, {'S'});
      expect(_productionShapes(transformed), ['S->a']);
      expect(() => transformed.terminals.add('x'), throwsUnsupportedError);
      expect(
        () => transformed.productions.single.rightSide.add('x'),
        throwsUnsupportedError,
      );
    });
  });

  group('GrammarStructuralAnalyzer', () {
    test('characterizes empty and invalid start-symbol diagnostics', () {
      final empty = GrammarStructuralAnalyzer(
        GrammarAnalysisContext(
          _grammar(startSymbol: '', nonTerminals: const {}),
        ),
      ).validateMalformedProductions();
      expect(empty.data!.diagnostics.map((diagnostic) => diagnostic.code), [
        'grammar.start_symbol_missing',
        'grammar.no_productions',
      ]);

      final invalid = GrammarStructuralAnalyzer(
        GrammarAnalysisContext(
          _grammar(startSymbol: '開始', nonTerminals: const {'S'}),
        ),
      ).validateMalformedProductions();
      expect(
        invalid.data!.diagnostics.map((diagnostic) => diagnostic.code),
        contains('grammar.start_symbol_not_nonterminal'),
      );
    });

    test('reports unreachable and nonproductive cycles deterministically', () {
      final analyzer = GrammarStructuralAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            nonTerminals: const {'S', 'A', 'B'},
            terminals: const {'a'},
            productions: {
              _production('p1', 'S', const ['a'], order: 1),
              _production('p2', 'A', const ['B'], order: 2),
              _production('p3', 'B', const ['A'], order: 3),
            },
          ),
        ),
      );

      expect(
        analyzer.detectUnreachableNonTerminals().data!.diagnostics.last.symbols,
        ['A', 'B'],
      );
      expect(
        analyzer
            .detectUnproductiveNonTerminals()
            .data!
            .diagnostics
            .first
            .symbols,
        ['A', 'B'],
      );
    });

    test('preserves duplicate production ids as distinct model entries', () {
      final context = GrammarAnalysisContext(
        _grammar(
          terminals: const {'a'},
          productions: {
            _production('p1', 'S', const ['a'], order: 1),
            _production('p2', 'S', const ['a'], order: 2),
          },
        ),
      );

      expect(context.productionsByNonTerminal['S'], hasLength(2));
      expect(
        GrammarStructuralAnalyzer(
          context,
        ).validateMalformedProductions().data!.diagnostics,
        isEmpty,
      );
    });
  });

  group('GrammarNullableFirstFollowAnalyzer', () {
    const epsilonAliases = [
      'ε',
      'lambda',
      'λ',
      'epsilon',
      'varepsilon',
      'eps',
      'empty',
      'vazio',
      '∅',
      'ø',
    ];

    test('computes nullable, FIRST, and FOLLOW through an epsilon chain', () {
      final analyzer = GrammarNullableFirstFollowAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            nonTerminals: const {'S', 'A', 'B'},
            productions: {
              _production('p1', 'S', const ['A'], order: 1),
              _production('p2', 'A', const ['B'], order: 2),
              _production('p3', 'B', const [], order: 3),
            },
          ),
        ),
      );

      expect(analyzer.computeNullableNonTerminals(), {'S', 'A', 'B'});
      final first = analyzer.computeFirstSets().data!.value;
      expect(first, {
        'S': {'ε'},
        'A': {'ε'},
        'B': {'ε'},
      });
      final follow = analyzer.computeFollowSets().data!.value;
      expect(follow, {
        'S': {'\$'},
        'A': {'\$'},
        'B': {'\$'},
      });
    });

    test('keeps multi-character and Unicode symbols intact', () {
      final result = GrammarNullableFirstFollowAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            startSymbol: 'Expr',
            nonTerminals: const {'Expr', 'Tail'},
            terminals: const {'identificador', '🙂'},
            productions: {
              _production('p1', 'Expr', const ['identificador', 'Tail']),
              _production('p2', 'Tail', const ['🙂']),
            },
          ),
        ),
      ).computeFirstSets();

      expect(result.data!.value['Expr'], {'identificador'});
      expect(result.data!.value['Tail'], {'🙂'});
    });

    for (final alias in epsilonAliases) {
      test('treats declared terminal "$alias" as a terminal', () {
        final context = GrammarAnalysisContext(
          _grammar(
            terminals: {alias},
            productions: {
              _production('p1', 'S', [alias]),
            },
          ),
        );
        final analyzer = GrammarNullableFirstFollowAnalyzer(context);

        expect(analyzer.computeNullableNonTerminals(), isEmpty);
        expect(analyzer.computeFirstSets().data!.value['S'], {alias});
        final row = GrammarPredictiveAnalyzer(
          context,
        ).buildLL1ParseTable().data!.value.table['S']!;
        expect(row.keys, contains(alias));
        expect(row.keys, isNot(contains('\$')));
      });
    }

    for (final alias in epsilonAliases) {
      test('keeps undeclared alias "$alias" as the nullable sentinel', () {
        final context = GrammarAnalysisContext(
          _grammar(
            productions: {
              _production('p1', 'S', [alias]),
            },
          ),
        );
        final analyzer = GrammarNullableFirstFollowAnalyzer(context);

        expect(analyzer.computeNullableNonTerminals(), {'S'});
        expect(analyzer.computeFirstSets().data!.value['S'], {'ε'});
        expect(
          GrammarPredictiveAnalyzer(
            context,
          ).buildLL1ParseTable().data!.value.table['S']!.keys,
          {'\$'},
        );
      });
    }

    test('treats a declared epsilon alias as a non-terminal', () {
      final analyzer = GrammarNullableFirstFollowAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            nonTerminals: const {'S', 'epsilon'},
            terminals: const {'a'},
            productions: {
              _production('p1', 'S', const ['epsilon']),
              _production('p2', 'epsilon', const ['a']),
            },
          ),
        ),
      );

      expect(analyzer.computeNullableNonTerminals(), isEmpty);
      expect(analyzer.computeFirstSets().data!.value, {
        'S': {'a'},
        'epsilon': {'a'},
      });
    });
  });

  group('GrammarLeftRecursionAnalyzer', () {
    test('removes direct and indirect cycles without mutating the source', () {
      final source = _grammar(
        nonTerminals: const {'S', 'A'},
        terminals: const {'a', 'b'},
        productions: {
          _production('p1', 'S', const ['A', 'a'], order: 1),
          _production('p2', 'S', const ['b'], order: 2),
          _production('p3', 'A', const ['S'], order: 3),
          _production('p4', 'A', const ['a'], order: 4),
        },
      );
      final before = _productionShapes(source);
      final result = GrammarLeftRecursionTransformer(
        GrammarAnalysisContext(source),
      ).removeLeftRecursion();

      expect(result.isSuccess, isTrue);
      expect(_productionShapes(source), before);
      expect(
        GrammarLeftRecursionAnalyzer(
          GrammarAnalysisContext(result.data!.value),
        ).hasLeftCornerCycle(),
        isFalse,
      );
      expect(result.data!.steps, isNotEmpty);
    });

    test('detects recursion behind a nullable left prefix', () {
      final grammar = _grammar(
        startSymbol: 'A',
        nonTerminals: const {'A', 'B'},
        terminals: const {'a'},
        productions: {
          _production('p1', 'A', const ['B', 'A', 'a'], order: 1),
          _production('p2', 'B', const [], order: 2),
        },
      );

      expect(
        GrammarLeftRecursionAnalyzer(
          GrammarAnalysisContext(grammar),
        ).hasLeftCornerCycle(),
        isTrue,
      );
      final transformation = GrammarAnalyzer.removeLeftRecursion(grammar);
      expect(transformation.isFailure, isTrue);
      expect(transformation.error, contains('left-corner relation'));
    });
  });

  group('GrammarPredictiveAnalyzer', () {
    test('factors nested common prefixes', () {
      final result = GrammarPredictiveAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            terminals: const {'a', 'b', 'c', 'd', 'e'},
            productions: {
              _production('p1', 'S', const ['a', 'b', 'c'], order: 1),
              _production('p2', 'S', const ['a', 'b', 'd'], order: 2),
              _production('p3', 'S', const ['a', 'e'], order: 3),
            },
          ),
        ),
      ).leftFactor();

      expect(result.isSuccess, isTrue);
      expect(result.data!.value.nonterminals, containsAll({'S_1', 'S_2'}));
      expect(result.data!.notes, hasLength(2));
    });

    test('distinguishes LL(1), FIRST/FIRST, and FIRST/FOLLOW conflicts', () {
      final ll1 = GrammarPredictiveAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            nonTerminals: const {'S', 'A'},
            terminals: const {'a', 'b', 'c'},
            productions: {
              _production('p1', 'S', const ['a', 'A']),
              _production('p2', 'S', const ['b']),
              _production('p3', 'A', const ['c']),
              _production('p4', 'A', const []),
            },
          ),
        ),
      ).buildLL1ParseTable();
      expect(ll1.data!.conflicts, isEmpty);

      final firstFirst = GrammarPredictiveAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            nonTerminals: const {'S', 'A', 'B'},
            terminals: const {'a', 'x', 'y'},
            productions: {
              _production('p1', 'S', const ['a', 'A']),
              _production('p2', 'S', const ['a', 'B']),
              _production('p3', 'A', const ['x']),
              _production('p4', 'B', const ['y']),
            },
          ),
        ),
      ).buildLL1ParseTable();
      expect(firstFirst.data!.conflicts.single, contains('[S, a]'));
      final firstFirstConflict = firstFirst.data!.value.typedConflicts.single;
      final firstFirstMessage = firstFirstConflict.descriptionMessage;
      expect(
        firstFirstConflict.formalDescription,
        startsWith('FIRST/FIRST [S, a]:'),
      );
      expect(firstFirstConflict.formalDescription, contains('p1 S → a A'));
      expect(firstFirstMessage.stableCode, 'grammar.ll1-conflict.detected');
      expect(firstFirstMessage.arguments['kind']?.value, 'first-first');
      expect(
        firstFirstMessage.arguments['non-terminal'],
        StructuredMessageArgument.symbol('S', role: 'grammar-nonterminal'),
      );
      expect(
        firstFirstMessage.arguments['lookahead'],
        StructuredMessageArgument.symbol('a', role: 'grammar-lookahead'),
      );
      expect(
        firstFirstMessage.arguments['alternatives']?.role,
        'grammar-productions',
      );
      expect(
        StructuredMessage.fromJson(firstFirstMessage.toJson()),
        firstFirstMessage,
      );

      final firstFollow = GrammarPredictiveAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            nonTerminals: const {'S', 'A'},
            terminals: const {'a'},
            productions: {
              _production('p1', 'S', const ['A', 'a']),
              _production('p2', 'A', const ['a']),
              _production('p3', 'A', const []),
            },
          ),
        ),
      ).buildLL1ParseTable();
      expect(firstFollow.data!.conflicts.single, contains('[A, a]'));
      expect(
        firstFollow
            .data!
            .value
            .typedConflicts
            .single
            .descriptionMessage
            .arguments['kind']
            ?.value,
        'first-follow',
      );
      expect(
        firstFollow.data!.value.typedConflicts.single.formalDescription,
        startsWith('FIRST/FOLLOW [A, a]:'),
      );
    });
  });

  group('GrammarAmbiguityAnalyzer', () {
    test('labels the LL(1) signal as incomplete heuristic evidence', () {
      final report = GrammarAmbiguityAnalyzer(
        GrammarAnalysisContext(
          _grammar(
            terminals: const {'a'},
            productions: {
              _production('p1', 'S', const ['a'], order: 1),
              _production('p2', 'S', const ['a', 'a'], order: 2),
            },
          ),
        ),
      ).assess().data!;

      expect(report.value.appearsLl1, isFalse);
      expect(report.value.isComplete, isFalse);
      expect(
        report.value.evidence,
        GrammarAmbiguityEvidence.ll1ConflictHeuristic,
      );
      expect(
        report.value.limitation,
        GrammarAmbiguityLimitation.ll1ConflictsDoNotDecideAmbiguity,
      );
      expect(report.structuredNotes.map((message) => message.stableCode), [
        'grammar.ambiguity.ll1-conflicts-detected',
        'grammar.ambiguity.non-ll1-does-not-imply-ambiguity',
      ]);
    });
  });

  test('reports and facade outputs are stable across set insertion orders', () {
    final p1 = _production('p1', 'S', const ['A', 'b'], order: 1);
    final p2 = _production('p2', 'A', const ['a'], order: 2);
    final p3 = _production('p3', 'A', const [], order: 3);
    final firstGrammar = _grammar(
      nonTerminals: <String>{'S', 'A'},
      terminals: <String>{'a', 'b'},
      productions: <Production>{p1, p2, p3},
    );
    final secondGrammar = _grammar(
      nonTerminals: <String>{'A', 'S'},
      terminals: <String>{'b', 'a'},
      productions: <Production>{p3, p2, p1},
    );

    final first = GrammarAnalyzer.buildLL1ParseTable(firstGrammar).data!;
    final second = GrammarAnalyzer.buildLL1ParseTable(secondGrammar).data!;
    expect(first.value.table, second.value.table);
    expect(first.value.terminals.toList(), second.value.terminals.toList());
    expect(first.notes, second.notes);
    expect(first.derivations, second.derivations);
    expect(first.conflicts, second.conflicts);
  });

  test('GrammarReportComposer preserves aggregate report fields', () {
    final notes = <String>['initial'];
    final report = GrammarReportComposer.compose(value: true, notes: notes);
    expect(report.value, isTrue);
    expect(report.notes, ['initial']);
    expect(report.notes, same(notes));
  });
}
