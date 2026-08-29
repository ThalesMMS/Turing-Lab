import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  Grammar buildGrammar({
    required String id,
    Set<String> terminals = const {'a'},
    Set<Production>? productions,
  }) {
    final timestamp = DateTime.utc(2026);
    return Grammar(
      id: id,
      name: id,
      terminals: terminals,
      nonterminals: const {'S', 'A'},
      startSymbol: 'S',
      productions:
          productions ??
          {
            const Production(id: 'p-1', leftSide: ['S'], rightSide: ['a']),
          },
      type: GrammarType.contextFree,
      created: timestamp,
      modified: timestamp,
    );
  }

  group('grammar-to-PDA structured messages', () {
    test('message factories expose stable identity and typed arguments', () {
      final duplicate = GrammarToPdaMessages.duplicateProductionId('p-2');
      final timeout = GrammarToPdaMessages.conversionTimedOut(
        const Duration(milliseconds: 250),
      );

      expect(duplicate.stableCode, 'grammar.to-pda.duplicate-production-id');
      expect(
        duplicate.arguments['production'],
        StructuredMessageArgument.identifier('p-2', role: 'production-id'),
      );
      expect(timeout.stableCode, 'grammar.to-pda.timed-out');
      expect(
        timeout.arguments['timeout'],
        StructuredMessageArgument.duration(
          const Duration(milliseconds: 250),
          role: 'timeout',
        ),
      );
      expect(timeout.category, StructuredMessageCategory.conversion);
      expect(timeout.severity, StructuredMessageSeverity.error);
    });

    test('validation failures retain legacy text and structured payloads', () {
      final grammar = buildGrammar(
        id: 'duplicate-id',
        productions: {
          const Production(id: 'p-1', leftSide: ['S'], rightSide: ['a']),
          const Production(id: 'p-1', leftSide: ['S'], rightSide: ['b']),
        },
        terminals: {'a', 'b'},
      );

      final result = GrammarToPDAConverter.convert(grammar);

      expect(result.isFailure, isTrue);
      expect(result.error, 'Duplicate production ID: p-1');
      expect(
        result.structuredError,
        GrammarToPdaMessages.duplicateProductionId('p-1'),
      );
    });

    test(
      'conversion timeout is represented without embedding locale prose',
      () {
        final result = GrammarToPDAConverter.convert(
          buildGrammar(
            id: 'timeout',
            productions: {
              const Production(id: 'p-1', leftSide: ['S'], rightSide: ['a']),
            },
          ),
          timeout: Duration.zero,
        );

        expect(result.isFailure, isTrue);
        expect(result.error, 'Conversion timed out');
        expect(result.structuredError?.stableCode, 'grammar.to-pda.timed-out');
      },
    );

    test(
      'analysis exposes structured counterparts for its legacy step list',
      () {
        final result = GrammarToPDAConverter.analyzeGrammarToPDAConversion(
          buildGrammar(id: 'analysis'),
        );

        expect(result.isSuccess, isTrue);
        final payload = result.data!;
        expect(payload['steps'], [
          'Validate grammar',
          'Create initial state',
          'Create processing state',
          'Create accepting state',
          'Add transitions',
        ]);

        final structuredSteps = (payload['structuredSteps']! as List)
            .map(
              (entry) => StructuredMessage.fromJson(
                Map<String, Object?>.from(entry as Map),
              ),
            )
            .toList();
        expect(structuredSteps.map((message) => message.stableCode), [
          'grammar.to-pda.validate-grammar',
          'grammar.to-pda.create-initial-state',
          'grammar.to-pda.create-processing-state',
          'grammar.to-pda.create-accepting-state',
          'grammar.to-pda.add-transitions',
        ]);
      },
    );

    test('non-context-free check carries a validation payload', () {
      final result = GrammarToPDAConverter.canConvertGrammarToPDA(
        buildGrammar(
          id: 'unrestricted',
          productions: {
            const Production(id: 'p-1', leftSide: ['S', 'A'], rightSide: ['a']),
          },
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, 'Grammar is not context-free');
      expect(result.structuredError, GrammarToPdaMessages.notContextFree());
    });

    test('GNF conversion failure carries a stable conversion payload', () {
      final result = GrammarToPDAConverter.convertGrammarToPDAGreibach(
        buildGrammar(
          id: 'malformed-gnf',
          productions: {
            const Production(
              id: 'malformed',
              leftSide: [],
              rightSide: [],
              isLambda: true,
            ),
          },
        ),
      );

      expect(result.isFailure, isTrue);
      expect(
        result.structuredError,
        GrammarToPdaMessages.gnfConversionFailed(),
      );
    });
  });
}
