import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/cfg/cfg_toolkit.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser_messages.dart';
import 'package:turing_lab/core/algorithms/cfg_toolkit_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_earley.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_simple_recursive.dart';
import 'package:turing_lab/core/algorithms/lr1_parser.dart';
import 'package:turing_lab/core/algorithms/lr1_parser_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/lr1_models.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final timestamp = DateTime.utc(2026);

  Grammar simpleGrammar() => Grammar(
    id: 'lr1-structured-test',
    name: 'LR(1) structured test grammar',
    terminals: {'a'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: {
      const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    },
    type: GrammarType.contextFree,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
  );

  Grammar grammar({
    Set<String> terminals = const {'a'},
    Set<String> nonterminals = const {'S'},
    String startSymbol = 'S',
    Iterable<Production> productions = const <Production>[
      Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    ],
  }) => Grammar(
    id: 'structured-parser-test',
    name: 'Structured parser test grammar',
    terminals: terminals,
    nonterminals: nonterminals,
    startSymbol: startSymbol,
    productions: productions.toSet(),
    type: GrammarType.contextFree,
    created: timestamp,
    modified: timestamp,
  );

  void expectCode(StructuredMessage message, String code) {
    expect(message.stableCode, code);
    expect(StructuredMessage.fromJson(message.toJson()), message);
  }

  group('parser structured-message companions', () {
    test('expose stable namespaces and codes for CFG and CYK diagnostics', () {
      expectCode(
        CfgToolkitMessages.reduceFailed(),
        'grammar.cfg-toolkit.reduce-failed',
      );
      expectCode(
        CfgToolkitMessages.toCnfFailed(),
        'grammar.cfg-toolkit.to-cnf-failed',
      );
      expectCode(
        CfgToolkitMessages.toGnfFailed(),
        'grammar.cfg-toolkit.to-gnf-failed',
      );
      expectCode(CykParserMessages.timedOut(), 'grammar.cyk.timed-out');
      final rejected = CykParserMessages.inputRejected('a🙂');
      expectCode(rejected, 'grammar.cyk.input-rejected');
      expect(
        rejected.arguments['input']!.kind,
        StructuredMessageArgumentKind.literal,
      );
      expect(rejected.arguments['input']!.value, 'a🙂');
      expectCode(CykParserMessages.parseFailed(), 'grammar.cyk.parse-failed');
    });

    test('expose typed grammar-parser arguments', () {
      final timeout = GrammarParserMessages.ll1TimedOut(
        const Duration(milliseconds: 12),
      );
      expectCode(timeout, 'grammar.parser.ll1-timed-out');
      expect(
        timeout.arguments['timeout']!.kind,
        StructuredMessageArgumentKind.durationMilliseconds,
      );
      expect(timeout.arguments['timeout']!.value, 12);

      final mismatch = GrammarParserMessages.ll1TerminalMismatch(
        expected: 'id',
        found: '+',
        position: 4,
      );
      expectCode(mismatch, 'grammar.parser.ll1-terminal-mismatch');
      expect(
        mismatch.arguments['expected']!.kind,
        StructuredMessageArgumentKind.symbol,
      );
      expect(
        mismatch.arguments['found']!.kind,
        StructuredMessageArgumentKind.symbol,
      );
      expect(
        mismatch.arguments['position']!.kind,
        StructuredMessageArgumentKind.positionIndex,
      );

      final conflict = GrammarParserMessages.ll1ConflictCell(
        nonTerminal: 'E',
        lookahead: 'id',
        productions: 'T vs U',
      );
      expectCode(conflict, 'grammar.parser.ll1-conflict');
      expect(conflict.severity, StructuredMessageSeverity.warning);

      final codes = <String>{
        GrammarParserMessages.emptyGrammar().stableCode,
        GrammarParserMessages.missingStartSymbol().stableCode,
        GrammarParserMessages.startSymbolNotNonterminal().stableCode,
        GrammarParserMessages.inputRejected('a').stableCode,
        GrammarParserMessages.allStrategiesFailed('cyk').stableCode,
        GrammarParserMessages.generatedStringsFailed().stableCode,
        GrammarParserMessages.ll1StepLimitInvalid(0).stableCode,
        GrammarParserMessages.ll1Cancelled().stableCode,
        timeout.stableCode,
        GrammarParserMessages.ll1StepLimitReached(1).stableCode,
        GrammarParserMessages.ll1TrailingInput(
          lookahead: 'a',
          position: 1,
        ).stableCode,
        GrammarParserMessages.ll1UnexpectedEnd('a').stableCode,
        mismatch.stableCode,
        GrammarParserMessages.ll1EmptyTableCell(
          nonTerminal: 'S',
          lookahead: r'$',
          expected: 'a',
        ).stableCode,
        conflict.stableCode,
        GrammarParserMessages.ll1EmptyStack().stableCode,
        GrammarParserMessages.earleyMalformedProduction().stableCode,
        GrammarParserMessages.earleyMissingStartSymbol().stableCode,
        GrammarParserMessages.earleyTimedOut(Duration.zero).stableCode,
        GrammarParserMessages.recursiveDescentTimedOut().stableCode,
        GrammarParserMessages.recursiveDescentFailed().stableCode,
      };
      expect(codes, hasLength(21));
      expect(codes.every((code) => code.startsWith('grammar.parser.')), isTrue);
    });

    test('expose typed LR(1) construction and parser arguments', () {
      final duplicate = Lr1ParserMessages.duplicateProductionId('p1');
      expectCode(duplicate, 'grammar.lr1.duplicate-production-id');
      expect(
        duplicate.arguments['production']!.kind,
        StructuredMessageArgumentKind.identifier,
      );
      expect(duplicate.arguments['production']!.role, 'production-id');

      final undeclared = Lr1ParserMessages.undeclaredSymbol(
        productionId: 'p1',
        symbol: 'X',
      );
      expectCode(undeclared, 'grammar.lr1.undeclared-symbol');
      expect(
        undeclared.arguments['symbol']!.kind,
        StructuredMessageArgumentKind.symbol,
      );

      final conflict = Lr1ParserMessages.conflict(
        stateId: 'I2',
        lookahead: 'a',
      );
      expectCode(conflict, 'grammar.lr1.conflict');
      expect(
        conflict.arguments['state']!.kind,
        StructuredMessageArgumentKind.identifier,
      );
      expect(
        conflict.arguments['lookahead']!.kind,
        StructuredMessageArgumentKind.symbol,
      );

      final codes = <String>{
        Lr1ParserMessages.staleConstruction().stableCode,
        Lr1ParserMessages.invalidGrammar().stableCode,
        Lr1ParserMessages.missingStartSymbol().stableCode,
        Lr1ParserMessages.malformedProduction().stableCode,
        duplicate.stableCode,
        undeclared.stableCode,
        Lr1ParserMessages.constructionCancelled().stableCode,
        Lr1ParserMessages.constructionTimedOut(Duration.zero).stableCode,
        Lr1ParserMessages.constructionStateLimit().stableCode,
        Lr1ParserMessages.constructionItemLimit().stableCode,
        conflict.stableCode,
        Lr1ParserMessages.cancelled().stableCode,
        Lr1ParserMessages.timedOut(Duration.zero).stableCode,
        Lr1ParserMessages.stepLimitReached(1).stableCode,
        Lr1ParserMessages.emptyActionCell(
          stateId: 'I0',
          lookahead: 'a',
        ).stableCode,
        Lr1ParserMessages.actionConflict(
          stateId: 'I0',
          lookahead: 'a',
        ).stableCode,
        Lr1ParserMessages.invalidParserState().stableCode,
        Lr1ParserMessages.missingGoto(
          stateId: 'I0',
          nonTerminal: 'S',
        ).stableCode,
      };
      expect(codes, hasLength(18));
      expect(codes.every((code) => code.startsWith('grammar.lr1.')), isTrue);
    });
  });

  group('parser diagnostic propagation', () {
    test(
      'attaches validation, LL(1), CYK, Earley, and recursive diagnostics',
      () {
        final simple = grammar();
        final invalid = GrammarParser.parseLL1(
          grammar(productions: const <Production>[]),
          '',
        );
        expect(
          invalid.data!.structuredMessage!.stableCode,
          'grammar.parser.empty-grammar',
        );
        expect(
          invalid.data!.errorMessage,
          'Grammar must have at least one production',
        );

        final trailing = GrammarParser.parseLL1(simple, 'aa').data!;
        expect(
          trailing.structuredMessage!.stableCode,
          'grammar.parser.ll1-trailing-input',
        );
        expect(
          trailing.ll1Steps.last.structuredMessage!.stableCode,
          'grammar.parser.ll1-trailing-input',
        );

        final cyk = CYKParser.parse(simple, 'aa');
        expect(
          cyk.data!.structuredMessage!.stableCode,
          'grammar.cyk.input-rejected',
        );
        expect(cyk.data!.message, isNull);

        final earley = EarleyRecognizer(simple).recognizeWithReport('aa');
        expect(
          earley.structuredMessage!.stableCode,
          'grammar.parser.input-rejected',
        );
        final malformed = EarleyRecognizer(
          grammar(
            productions: const <Production>[
              Production(id: 'bad', leftSide: ['S', 'A'], rightSide: ['a']),
            ],
          ),
        ).recognizeWithReport('a');
        expect(
          malformed.structuredMessage!.stableCode,
          'grammar.parser.earley-malformed-production',
        );

        final recursive = SimpleRecursiveDescentParser(
          simple,
        ).parseWithReport('aa');
        expect(
          recursive.data!.structuredMessage!.stableCode,
          'grammar.parser.input-rejected',
        );
      },
    );

    test('attaches timeout diagnostics while retaining legacy prose', () {
      final simple = grammar();

      final cyk = CYKParser.parse(simple, 'a', timeout: Duration.zero);
      expect(cyk.data!.outcome, GrammarParseOutcome.timedOut);
      expect(cyk.data!.structuredMessage!.stableCode, 'grammar.cyk.timed-out');
      expect(cyk.data!.message, 'CYK parsing timed out');

      final cykSteps = CYKParser.parseWithSteps(
        simple,
        'a',
        timeout: Duration.zero,
      );
      expect(
        cykSteps.data!.structuredMessage!.stableCode,
        'grammar.cyk.timed-out',
      );

      final earley = EarleyRecognizer(
        simple,
      ).recognizeWithReport('a', timeout: Duration.zero);
      expect(earley.outcome, GrammarParseOutcome.timedOut);
      expect(
        earley.structuredMessage!.stableCode,
        'grammar.parser.earley-timed-out',
      );

      final recursive = SimpleRecursiveDescentParser(
        simple,
      ).parseWithReport('a', timeout: Duration.zero);
      expect(
        recursive.data!.structuredMessage!.stableCode,
        'grammar.parser.recursive-descent-timed-out',
      );
    });

    test('attaches CFG toolkit and LR(1) diagnostics', () {
      final malformed = grammar(
        productions: const <Production>[
          Production(id: 'bad', leftSide: [], rightSide: []),
        ],
      );
      final reduction = CFGToolkit.reduce(malformed);
      expect(
        reduction.structuredError!.stableCode,
        'grammar.cfg-toolkit.reduce-failed',
      );
      final cnf = CFGToolkit.toCNF(malformed);
      expect(
        cnf.structuredError!.stableCode,
        'grammar.cfg-toolkit.to-cnf-failed',
      );

      final invalid = LR1Parser.build(
        grammar(productions: const <Production>[]),
      );
      expect(
        invalid.structuredMessage!.stableCode,
        'grammar.lr1.invalid-grammar',
      );

      final bounded = LR1Parser.build(simpleGrammar(), maxStates: 1);
      expect(bounded.outcome, LR1ConstructionOutcome.stateLimit);
      expect(
        bounded.structuredMessage!.stableCode,
        'grammar.lr1.construction-state-limit',
      );

      final rejected = LR1Parser.parse(simpleGrammar(), 'aa');
      expect(rejected.outcome, LR1ParseOutcome.rejected);
      expect(
        rejected.structuredMessage!.stableCode,
        'grammar.lr1.empty-action-cell',
      );
      expect(
        rejected.steps.last.structuredMessage!.stableCode,
        'grammar.lr1.empty-action-cell',
      );
    });
  });
}
