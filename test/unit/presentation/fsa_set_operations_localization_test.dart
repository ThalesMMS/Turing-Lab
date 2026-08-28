import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa_concatenation_messages.dart';
import 'package:turing_lab/core/algorithms/fsa_reverser_messages.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('resolves reversal diagnostics and steps in both locales', () {
    expect(
      en.resolveStructuredMessage(FsaReversalMessages.emptyOperand()),
      en.fsaReversalEmptyOperand,
    );
    expect(
      pt.resolveStructuredMessage(FsaReversalMessages.emptyOperand()),
      pt.fsaReversalEmptyOperand,
    );
    expect(
      en.resolveStructuredMessage(FsaReversalMessages.invalidTransition('t7')),
      'The reversal operand contains an invalid transition: t7.',
    );
    expect(
      pt.resolveStructuredMessage(FsaReversalMessages.invalidTransition('t7')),
      'O operando da inversão contém uma transição inválida: t7.',
    );
    expect(
      pt.resolveStructuredMessage(FsaReversalMessages.stepTitle('reverse')),
      pt.fsaReversalReverseTitle,
    );
    expect(
      pt.resolveStructuredMessage(
        FsaReversalMessages.entryExplanation(hasAcceptingStates: false),
      ),
      pt.fsaReversalEntryEmptyExplanation,
    );
  });

  test('resolves concatenation operand and transition arguments', () {
    expect(
      en.resolveStructuredMessage(
        FsaConcatenationMessages.emptyOperand('left'),
      ),
      'The left operand must contain at least one state.',
    );
    expect(
      pt.resolveStructuredMessage(
        FsaConcatenationMessages.emptyOperand('right'),
      ),
      'O operando direito deve conter pelo menos um estado.',
    );
    expect(
      en.resolveStructuredMessage(
        FsaConcatenationMessages.invalidTransition('right', 't8'),
      ),
      'The right operand contains an invalid transition: t8.',
    );
    expect(
      pt.resolveStructuredMessage(FsaConcatenationMessages.cloneTitle('left')),
      'Clonar o operando esquerdo',
    );
    expect(
      pt.resolveStructuredMessage(
        FsaConcatenationMessages.connectEmptyExplanation(),
      ),
      'A linguagem do operando esquerdo é vazia, portanto nenhuma ponte epsilon é necessária.',
    );
  });

  test('malformed operation arguments use the stable fallback', () {
    expect(
      en.resolveStructuredMessage(FsaReversalMessages.invalidTransition('')),
      contains('automaton.fsa-reversal.invalid-transition'),
    );
    expect(
      pt.resolveStructuredMessage(
        FsaConcatenationMessages.invalidTransition('middle', 't8'),
      ),
      contains('automaton.fsa-concatenation.invalid-transition'),
    );
  });
}
