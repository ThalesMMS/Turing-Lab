import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda_models.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  Grammar buildGrammar({
    String startSymbol = 'S',
    Set<String> terminals = const {'a', 'b'},
    Set<String> nonterminals = const {'S'},
    Set<Production>? productions,
  }) => Grammar(
    id: 'cfg',
    name: 'CFG',
    terminals: terminals,
    nonterminals: nonterminals,
    startSymbol: startSymbol,
    productions:
        productions ??
        {
          const Production(id: 'p0', leftSide: ['S'], rightSide: ['a']),
        },
    type: GrammarType.contextFree,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
  );

  test('validation diagnostics carry typed messages and legacy fields', () {
    final report = CfgToPdaConverter.buildLl(
      buildGrammar(
        productions: {
          const Production(id: 'duplicate', leftSide: ['S'], rightSide: ['a']),
          const Production(id: 'duplicate', leftSide: ['S'], rightSide: ['b']),
          const Production(
            id: 'malformed',
            leftSide: ['S', 'A'],
            rightSide: ['a'],
          ),
          const Production(
            id: 'undeclared',
            leftSide: ['S'],
            rightSide: ['missing'],
          ),
        },
      ),
      sourceRevision: 4,
    );

    expect(report.isCompleted, isFalse);
    final diagnostics = report.diagnostics;
    expect(
      diagnostics.map((diagnostic) => diagnostic.structuredMessage?.stableCode),
      containsAll(<String>[
        'cfg.to-pda.duplicate-production-id',
        'cfg.to-pda.malformed-production',
        'cfg.to-pda.undeclared-symbol',
      ]),
    );
    final undeclared = diagnostics.firstWhere(
      (diagnostic) =>
          diagnostic.code == CfgToPdaDiagnosticCode.undeclaredSymbol,
    );
    expect(undeclared.productionId, 'undeclared');
    expect(undeclared.symbol, 'missing');
    expect(
      undeclared.structuredMessage!.arguments['production']!.kind,
      StructuredMessageArgumentKind.identifier,
    );
    expect(
      undeclared.structuredMessage!.arguments['symbol']!.kind,
      StructuredMessageArgumentKind.symbol,
    );
  });

  test('start-symbol diagnostics preserve symbols as typed arguments', () {
    final report = CfgToPdaConverter.buildLl(
      buildGrammar(startSymbol: 'X'),
      sourceRevision: 1,
    );
    final diagnostic = report.diagnostics.single;

    expect(diagnostic.code, CfgToPdaDiagnosticCode.undeclaredStartSymbol);
    expect(diagnostic.symbol, 'X');
    expect(
      diagnostic.structuredMessage,
      CfgToPdaMessages.undeclaredStartSymbol('X'),
    );
  });

  test('LL conflicts carry locale-neutral conflict context', () {
    final report = CfgToPdaConverter.buildLl(
      buildGrammar(
        terminals: {'a'},
        productions: {
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
          const Production(id: 'p2', leftSide: ['S'], rightSide: ['a']),
        },
      ),
      sourceRevision: 2,
    );
    final conflict = report.diagnostics.firstWhere(
      (diagnostic) => diagnostic.code == CfgToPdaDiagnosticCode.llConflict,
    );

    expect(conflict.structuredMessage?.stableCode, 'cfg.to-pda.ll-conflict');
    expect(conflict.structuredMessage!.arguments['nonterminal']!.value, 'S');
    expect(conflict.structuredMessage!.arguments['lookahead']!.value, 'a');
    expect(
      conflict.structuredMessage!.arguments['productions']!.value,
      'p1, p2',
    );
  });

  test('structured messages round-trip without losing typed arguments', () {
    final message = CfgToPdaMessages.undeclaredSymbol(
      productionId: 'p7',
      symbol: 'X',
    );
    final restored = StructuredMessage.fromJson(message.toJson());

    expect(restored, message);
    expect(restored.arguments['production']!.role, 'production-id');
    expect(restored.arguments['symbol']!.role, 'grammar-symbol');
  });
}
