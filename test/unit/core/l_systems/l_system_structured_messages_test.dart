import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/messages/structured_message.dart';

void main() {
  test('expansion diagnostics preserve codes, typed arguments, and JSON', () {
    final outcome =
        const LSystemExpander().expand(
              LSystemDocument(
                id: 'fixture',
                name: 'fixture',
                revision: 0,
                axiom: LSystemWord(const ['A']),
                productions: [
                  LSystemProduction(
                    id: 'same',
                    predecessor: 'A',
                    successor: LSystemWord(const ['A']),
                  ),
                  LSystemProduction(
                    id: 'same',
                    predecessor: 'B',
                    successor: LSystemWord(const ['B']),
                  ),
                ],
                iterations: 1,
                turtle: LSystemTurtleSettings(),
                commandMapping: LSystemCommandMapping.standard,
                unsupportedVariants: const [
                  LSystemUnsupportedVariant.parametric,
                ],
              ),
            )
            as LSystemExpansionInvalid;

    expect(
      outcome.diagnostics.map((value) => value.structuredMessage.stableCode),
      [
        'l-system.expansion.duplicate-production-id',
        'l-system.expansion.unsupported-variant',
      ],
    );
    final duplicate = outcome.diagnostics.first.structuredMessage;
    expect(
      duplicate.arguments['production'],
      StructuredMessageArgument.identifier('same', role: 'production-id'),
    );
    final unsupported = outcome.diagnostics.last.structuredMessage;
    expect(
      unsupported.arguments['variant'],
      StructuredMessageArgument.outcome('parametric', role: 'l-system-variant'),
    );
    expect(StructuredMessage.fromJson(unsupported.toJson()), unsupported);
  });

  test('turtle diagnostics preserve counts and survive persistence', () {
    final outcome =
        const LSystemTurtleInterpreter().interpret(
              LSystemWord(const ['[', 'F']),
              settings: LSystemTurtleSettings(),
              mapping: LSystemCommandMapping.standard,
            )
            as LSystemTurtleInvalid;

    final message = outcome.diagnostics.single.structuredMessage;
    expect(message.stableCode, 'l-system.turtle.branch-state-unrestored');
    expect(
      message.arguments['count'],
      StructuredMessageArgument.count(1, role: 'branch-count'),
    );
    expect(StructuredMessage.fromJson(message.toJson()), message);
  });
}
