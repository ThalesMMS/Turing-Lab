import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/algorithms/grammar_structural_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('structural grammar diagnostics resolve in English and Portuguese', () {
    final messages = <StructuredMessage>[
      GrammarStructuralMessages.startSymbolMissing(),
      GrammarStructuralMessages.startSymbolMissingForReachability(),
      GrammarStructuralMessages.startSymbolNotNonterminal('Início'),
      GrammarStructuralMessages.startSymbolNotNonterminalForReachability('S'),
      GrammarStructuralMessages.noProductions(),
      GrammarStructuralMessages.noProductionsForProductivity(),
      GrammarStructuralMessages.productionLeftSideEmpty('p-empty'),
      GrammarStructuralMessages.productionLeftSideNotSingleNonterminal(
        'p-many',
        'A B',
      ),
      GrammarStructuralMessages.productionLeftSideEmptySymbol('p-empty-symbol'),
      GrammarStructuralMessages.productionLeftSideNotNonterminal(
        'p-bad-left',
        'X',
      ),
      GrammarStructuralMessages.productionReferencesUnknownSymbol(
        'p-unknown',
        '🙂',
      ),
      GrammarStructuralMessages.unknownSymbolForReachability('Y'),
      GrammarStructuralMessages.unknownSymbolForProductivity('Z'),
      GrammarStructuralMessages.lambdaProductionRhsNotEmpty('p-lambda'),
      GrammarStructuralMessages.productionRhsEmpty('p-empty-right'),
      GrammarStructuralMessages.unreachableNonterminals(2, 'A, B'),
      GrammarStructuralMessages.unproductiveNonterminals(1, 'C'),
      GrammarStructuralMessages.unproductiveProductions('C'),
    ];

    for (final message in messages) {
      final restored = StructuredMessage.fromJson(message.toJson());
      final english = en.resolveStructuredMessage(restored);
      final portuguese = pt.resolveStructuredMessage(restored);

      expect(restored, message);
      expect(english, isNot(contains(message.stableCode)));
      expect(portuguese, isNot(contains(message.stableCode)));
      expect(english, isNot(portuguese));
    }

    expect(
      en.resolveStructuredMessage(messages[7]),
      'Production p-many left-hand side must be exactly one non-terminal for CFG tooling; got A B.',
    );
    expect(
      pt.resolveStructuredMessage(messages[7]),
      'O lado esquerdo da produção p-many deve conter exatamente um não terminal para as ferramentas CFG; foi recebido A B.',
    );
    expect(
      en.resolveStructuredMessage(messages[15]),
      'Found 2 unreachable non-terminals: A, B.',
    );
    expect(
      pt.resolveStructuredMessage(messages[15]),
      'Foram encontrados 2 não terminais inalcançáveis: A, B.',
    );
  });

  test(
    'structural analyzer attaches locale-neutral payloads to productions',
    () {
      final grammar = Grammar(
        id: 'structural-localization',
        name: 'Structural localization',
        startSymbol: 'S',
        nonterminals: const {'S'},
        terminals: const {'a'},
        productions: {
          const Production(id: 'p-empty', leftSide: [], rightSide: []),
          const Production(
            id: 'p-many',
            leftSide: ['S', 'A'],
            rightSide: ['a'],
          ),
          const Production(id: 'p-unknown', leftSide: ['S'], rightSide: ['?']),
          const Production(
            id: 'p-lambda',
            leftSide: ['S'],
            rightSide: ['a'],
            isLambda: true,
          ),
          const Production(id: 'p-empty-right', leftSide: ['S'], rightSide: []),
        },
        type: GrammarType.contextFree,
        created: DateTime.utc(2026),
        modified: DateTime.utc(2026),
      );

      final result = GrammarAnalyzer.validateMalformedProductions(grammar);
      expect(result.isSuccess, isTrue);

      final diagnostics = result.data!.diagnostics;
      expect(diagnostics, isNotEmpty);
      expect(
        diagnostics.every((diagnostic) => diagnostic.structuredMessage != null),
        isTrue,
      );
      expect(
        diagnostics.map(
          (diagnostic) => diagnostic.structuredMessage!.stableCode,
        ),
        containsAll(<String>[
          'grammar.structural.production-left-side-empty',
          'grammar.structural.production-left-side-not-single-nonterminal',
          'grammar.structural.production-unknown-symbol',
          'grammar.structural.lambda-production-rhs-not-empty',
          'grammar.structural.production-rhs-empty',
        ]),
      );

      final unknown = diagnostics.firstWhere(
        (diagnostic) => diagnostic.code == 'grammar.unknown_symbol',
      );
      expect(
        pt.resolveStructuredMessage(unknown.structuredMessage!),
        'A produção p-unknown faz referência ao símbolo desconhecido ?.',
      );
    },
  );
}
