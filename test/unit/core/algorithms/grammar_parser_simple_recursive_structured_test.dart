import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/algorithms/grammar_parser_simple_recursive.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_simple_recursive_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final grammar = Grammar(
    id: 'simple-recursive-structured-test',
    name: 'Simple recursive structured test grammar',
    terminals: {'a', 'b'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: {
      const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    },
    type: GrammarType.contextFree,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
  );

  test('exposes simple recursive factories with established parser codes', () {
    final rejected = SimpleRecursiveDescentMessages.inputRejected('a🙂');
    final timedOut = SimpleRecursiveDescentMessages.timedOut();
    final failed = SimpleRecursiveDescentMessages.failed();

    expect(rejected.stableCode, 'grammar.parser.input-rejected');
    expect(timedOut.stableCode, 'grammar.parser.recursive-descent-timed-out');
    expect(failed.stableCode, 'grammar.parser.recursive-descent-failed');
    expect(
      rejected.arguments['input']!.kind,
      StructuredMessageArgumentKind.literal,
    );
    expect(rejected.arguments['input']!.role, 'input-string');
    expect(rejected.arguments['input']!.value, 'a🙂');
    expect(timedOut.category, StructuredMessageCategory.parsing);
    expect(timedOut.severity, StructuredMessageSeverity.warning);
    expect(failed.category, StructuredMessageCategory.analysis);
    expect(failed.severity, StructuredMessageSeverity.error);

    for (final message in [rejected, timedOut, failed]) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
    expect(SimpleRecursiveDescentMessages.recursiveDescentTimedOut(), timedOut);
    expect(SimpleRecursiveDescentMessages.recursiveDescentFailed(), failed);
  });

  test('parser attaches the dedicated rejection diagnostic to reports', () {
    final result = SimpleRecursiveDescentParser(grammar).parseWithReport('b');

    expect(result.isSuccess, isTrue);
    final report = result.data!;
    expect(report.accepted, isFalse);
    expect(report.outcome, GrammarParseOutcome.rejected);
    expect(report.message, 'String "b" cannot be derived from grammar');
    expect(
      report.structuredMessage,
      SimpleRecursiveDescentMessages.inputRejected('b'),
    );
  });

  test('parser attaches timeout diagnostics while retaining legacy prose', () {
    final reportResult = SimpleRecursiveDescentParser(
      grammar,
    ).parseWithReport('a', timeout: Duration.zero);
    expect(reportResult.isSuccess, isTrue);
    final report = reportResult.data!;
    expect(report.outcome, GrammarParseOutcome.timedOut);
    expect(report.message, 'Recursive-descent parsing timed out.');
    expect(report.structuredMessage, SimpleRecursiveDescentMessages.timedOut());

    final parseResult = SimpleRecursiveDescentParser(
      grammar,
    ).parse('a', timeout: Duration.zero);
    expect(parseResult.isSuccess, isTrue);
    expect(parseResult.data!.accepted, isFalse);
    expect(parseResult.data!.outcome, GrammarParseOutcome.timedOut);
    expect(
      parseResult.data!.errorMessage,
      'Recursive-descent parsing timed out.',
    );
    expect(
      parseResult.data!.structuredMessage,
      SimpleRecursiveDescentMessages.timedOut(),
    );
  });

  test('successful parses keep the existing result shape', () {
    final result = SimpleRecursiveDescentParser(grammar).parse('a');

    expect(result.isSuccess, isTrue);
    expect(result.data!.accepted, isTrue);
    expect(result.data!.inputString, 'a');
    expect(result.data!.derivations, hasLength(1));
    expect(result.data!.structuredMessage, isNull);
  });
}
