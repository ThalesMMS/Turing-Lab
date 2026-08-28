import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_gnf_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_gnf_transformer.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('GrammarGnfTransformer structured messages', () {
    test('exposes a locale-neutral payload for the conversion step', () {
      final grammar = _simpleGrammar();

      final report = GrammarGnfTransformer.toGnf(grammar);

      expect(report.steps, hasLength(1));
      expect(report.structuredSteps, hasLength(report.steps.length));
      expect(
        report.structuredSteps.single.operationMessage,
        GrammarGnfMessages.convertTitle(),
      );
      expect(
        report.structuredSteps.single.rationaleMessage,
        GrammarGnfMessages.convertRationale(),
      );
      expect(
        report.structuredSteps.single.operationMessage.stableCode,
        'grammar.gnf.convert-title',
      );
      expect(
        report.structuredSteps.single.rationaleMessage.stableCode,
        'grammar.gnf.convert-rationale',
      );
      expect(report.structuredSteps.single.legacyStep, report.steps.single);
    });

    test(
      'preserves a structured warning when the result is not strict GNF',
      () {
        final grammar = Grammar(
          id: 'gnf-warning',
          name: 'GNF warning',
          nonterminals: {'S'},
          terminals: const {},
          startSymbol: 'S',
          productions: {
            const Production(id: 'p1', leftSide: ['S'], rightSide: ['S']),
          },
          type: GrammarType.contextFree,
          created: DateTime(2025),
          modified: DateTime(2025),
        );

        final report = GrammarGnfTransformer.toGnf(grammar);
        final warnings = report.diagnostics
            .where((diagnostic) => diagnostic.code == 'gnf_transform_not_gnf')
            .toList();
        expect(warnings, hasLength(1));
        final warning = warnings.single;
        expect(warning.structuredMessage, GrammarGnfMessages.notGnf());
        expect(warning.message, 'grammar.gnf.not-gnf');
        expect(warning.severity.name, 'warning');
      },
    );

    test(
      'message factories preserve stable category and severity metadata',
      () {
        final failed = GrammarGnfMessages.transformFailed();
        final notGnf = GrammarGnfMessages.notGnf();

        expect(failed.stableCode, 'grammar.gnf.transform-failed');
        expect(failed.category, StructuredMessageCategory.transformation);
        expect(failed.severity, StructuredMessageSeverity.error);
        expect(notGnf.stableCode, 'grammar.gnf.not-gnf');
        expect(notGnf.category, StructuredMessageCategory.validation);
        expect(notGnf.severity, StructuredMessageSeverity.warning);
      },
    );
  });
}

Grammar _simpleGrammar() => Grammar(
  id: 'gnf-structured',
  name: 'GNF structured messages',
  nonterminals: {'S', 'A', 'B'},
  terminals: {'a', 'b'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p1', leftSide: ['S'], rightSide: ['A', 'B']),
    const Production(id: 'p2', leftSide: ['A'], rightSide: ['a']),
    const Production(id: 'p3', leftSide: ['B'], rightSide: ['b']),
  },
  type: GrammarType.contextFree,
  created: DateTime(2025),
  modified: DateTime(2025),
);
