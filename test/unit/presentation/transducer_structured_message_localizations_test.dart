import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/data/transducers/mealy_example_catalog.dart';
import 'package:turing_lab/data/transducers/moore_example_catalog.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('multi-count summaries and budgets distinguish one from other counts', () {
    for (final count in [0, 1, 2]) {
      expect(
        en.transducerConversionSummary(count, count, count, count),
        '$count ${count == 1 ? 'state' : 'states'} and $count ${count == 1 ? 'transition' : 'transitions'} became $count ${count == 1 ? 'state' : 'states'} and $count ${count == 1 ? 'transition' : 'transitions'}.',
      );
      expect(
        pt.transducerConversionSummary(count, count, count, count),
        '$count ${count == 1 ? 'estado' : 'estados'} e $count ${count == 1 ? 'transição' : 'transições'} viraram $count ${count == 1 ? 'estado' : 'estados'} e $count ${count == 1 ? 'transição' : 'transições'}.',
      );
      expect(
        en.tmMultiTapeReductionStateBudget(count, 0),
        contains('$count ${count == 1 ? 'state,' : 'states,'}'),
      );
      expect(
        pt.tmMultiTapeReductionStateBudget(count, 0),
        contains('$count ${count == 1 ? 'estado,' : 'estados,'}'),
      );
      expect(
        en.tmMultiTapeReductionTransitionBudget(count, 0),
        contains('$count ${count == 1 ? 'transition,' : 'transitions,'}'),
      );
      expect(
        pt.tmMultiTapeReductionTapeSymbolBudget(count, 0),
        contains(
          '$count ${count == 1 ? 'símbolo composto' : 'símbolos compostos'}',
        ),
      );
      expect(
        en.bruteForceWitnessLabel('1', count, '$count'),
        'Witness 1 • $count ${count == 1 ? 'step' : 'steps'}',
      );
      expect(
        pt.bruteForceWitnessLabel('1', count, '$count'),
        'Derivação 1 • $count ${count == 1 ? 'passo' : 'passos'}',
      );
    }
    expect(en.transducerConversionEvidence(0, 2), contains('not verified'));
    expect(
      pt.transducerConversionEvidence(1, 2),
      startsWith('Verificada 1 palavra de entrada'),
    );
    expect(
      en.bruteForceDerivationStepLabel('1', '2', 'p0'),
      'Step 1 of 2 • production p0',
    );
    expect(
      pt.bruteForceDerivationStepLabel('1', '2', 'p0'),
      'Passo 1 de 2 • produção p0',
    );
  });

  test('zero conversion evidence does not claim output agreement', () {
    expect(
      en.transducerConversionEvidenceTruncated(0),
      'No input words were checked; output agreement has not been verified.',
    );
    expect(
      pt.transducerConversionEvidenceTruncated(0),
      'Nenhuma palavra de entrada foi verificada; '
      'a correspondência das saídas não foi confirmada.',
    );
  });

  test('truncated conversion evidence uses singular only for one word', () {
    expect(
      en.transducerConversionEvidenceTruncated(1),
      'Stopped after 1 input word: outputs agree for the tested word. '
      'Additional words were not checked.',
    );
    expect(
      pt.transducerConversionEvidenceTruncated(1),
      'Verificação interrompida após 1 palavra de entrada: '
      'as saídas coincidem na palavra testada. '
      'Outras palavras não foram verificadas.',
    );
    for (final count in [2, 2000]) {
      expect(
        en.transducerConversionEvidenceTruncated(count),
        'Stopped after $count input words: outputs agree for the tested words. '
        'Additional words were not checked.',
      );
      expect(
        pt.transducerConversionEvidenceTruncated(count),
        'Verificação interrompida após $count palavras de entrada: '
        'as saídas coincidem nas palavras testadas. '
        'Outras palavras não foram verificadas.',
      );
    }
  });

  test('every transducer execution code resolves in both locales', () {
    final messages = [
      _message(
        'invalid-machine',
        arguments: {'diagnostic-count': StructuredMessageArgument.count(2)},
      ),
      _message(
        'invalid-input-symbol',
        arguments: {
          'symbol': StructuredMessageArgument.symbol('β', role: 'input-symbol'),
        },
      ),
      _message(
        'tokenization-failure',
        arguments: {
          'offset': StructuredMessageArgument.index(3, role: 'input-offset'),
        },
      ),
      _message('invalid-input'),
      _message(
        'undefined-transition',
        arguments: {
          'state': StructuredMessageArgument.identifier('q0', role: 'state'),
          'symbol': StructuredMessageArgument.symbol('a', role: 'input-symbol'),
        },
      ),
      _message(
        'cancelled',
        arguments: {'processed': StructuredMessageArgument.count(0)},
      ),
      _message(
        'bounded',
        arguments: {
          'limit': StructuredMessageArgument.bound(5),
          'processed': StructuredMessageArgument.count(2),
        },
      ),
      _message(
        'success',
        arguments: {
          'processed': StructuredMessageArgument.count(2),
          'output-count': StructuredMessageArgument.count(1),
        },
      ),
    ];

    for (final message in messages) {
      final english = en.resolveStructuredMessage(message);
      final portuguese = pt.resolveStructuredMessage(message);
      expect(english, isNotEmpty, reason: message.stableCode);
      expect(portuguese, isNotEmpty, reason: message.stableCode);
      expect(portuguese, isNot(english), reason: message.stableCode);
      expect(english, isNot(contains(message.stableCode)));
      expect(portuguese, isNot(contains(message.stableCode)));
    }
  });

  test('malformed and future messages use the localized safe fallback', () {
    final missing = _message('bounded');
    final wrongType = _message(
      'bounded',
      arguments: {
        'limit': StructuredMessageArgument.count(5),
        'processed': StructuredMessageArgument.count(2),
      },
    );
    final extra = _message(
      'bounded',
      arguments: {
        'limit': StructuredMessageArgument.bound(5),
        'processed': StructuredMessageArgument.count(2),
        'extra': StructuredMessageArgument.count(1),
      },
    );
    final future = _message('future-outcome');

    for (final message in [missing, wrongType, extra, future]) {
      expect(
        en.resolveStructuredMessage(message),
        'Message unavailable (${message.stableCode}).',
      );
      expect(
        pt.resolveStructuredMessage(message),
        'Mensagem indisponível (${message.stableCode}).',
      );
    }
  });

  test('analysis payloads resolve typed symbols and ICU counts', () {
    final messages = _analysisMessages();

    for (final message in messages) {
      final english = en.resolveStructuredMessage(message);
      final portuguese = pt.resolveStructuredMessage(message);
      expect(english, isNotEmpty, reason: message.stableCode);
      expect(portuguese, isNotEmpty, reason: message.stableCode);
      expect(english, isNot(portuguese), reason: message.stableCode);
      expect(english, isNot(contains(message.stableCode)));
      expect(portuguese, isNot(contains(message.stableCode)));
    }

    final multiple = messages[1];
    final outside = messages[6];

    expect(en.resolveStructuredMessage(multiple), contains('2 initial states'));
    expect(
      pt.resolveStructuredMessage(multiple),
      contains('2 estados iniciais'),
    );
    expect(en.resolveStructuredMessage(outside), contains('β'));
    expect(pt.resolveStructuredMessage(outside), contains('β'));

    final malformed = _analysisMessage('duplicate-transition-id');
    expect(
      en.resolveStructuredMessage(malformed),
      'Message unavailable (${malformed.stableCode}).',
    );
    expect(
      pt.resolveStructuredMessage(malformed),
      'Mensagem indisponível (${malformed.stableCode}).',
    );
  });

  test(
    'catalog copy follows a runtime locale switch without reloading',
    () async {
      final examples = [
        ...(await MealyExampleCatalog().loadExamples()),
        ...(await MooreExampleCatalog().loadExamples()),
      ];

      for (final example in examples) {
        final nameMessage = example.nameMessage!;
        final descriptionMessage = example.descriptionMessage!;
        final englishName = en.resolveStructuredMessage(nameMessage);
        final portugueseName = pt.resolveStructuredMessage(nameMessage);
        expect(englishName, isNot(portugueseName), reason: example.id);
        expect(
          en.resolveStructuredMessage(descriptionMessage),
          isNot(pt.resolveStructuredMessage(descriptionMessage)),
          reason: example.id,
        );
      }
    },
  );
}

StructuredMessage _message(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'transducer.execution',
  code: code,
  category: StructuredMessageCategory.simulation,
  severity: StructuredMessageSeverity.information,
  arguments: arguments,
);

StructuredMessage _analysisMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'transducer.analysis',
  code: code,
  category: StructuredMessageCategory.analysis,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);

List<StructuredMessage> _analysisMessages() => [
  _analysisMessage('missing-initial-state'),
  _analysisMessage(
    'multiple-initial-states',
    arguments: {'count': StructuredMessageArgument.count(2)},
  ),
  _analysisMessage(
    'duplicate-state-id',
    arguments: {
      'state': StructuredMessageArgument.identifier('q0', role: 'state'),
    },
  ),
  for (final code in [
    'duplicate-transition-id',
    'dangling-source-state',
    'dangling-target-state',
  ])
    _analysisMessage(
      code,
      arguments: {
        'transition': StructuredMessageArgument.identifier(
          't0',
          role: 'transition',
        ),
      },
    ),
  _analysisMessage(
    'input-symbol-outside-alphabet',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        't0',
        role: 'transition',
      ),
      'symbol': StructuredMessageArgument.symbol('β', role: 'input-symbol'),
    },
  ),
  _analysisMessage(
    'output-symbol-outside-alphabet',
    arguments: {
      'subject': StructuredMessageArgument.identifier(
        'q0',
        role: 'output-owner',
      ),
      'symbol': StructuredMessageArgument.symbol('γ', role: 'output-symbol'),
    },
  ),
  for (final code in [
    'nondeterministic-transition',
    'incomplete-transition-function',
  ])
    _analysisMessage(
      code,
      arguments: {
        'state': StructuredMessageArgument.identifier('q0', role: 'state'),
        'symbol': StructuredMessageArgument.symbol('a', role: 'input-symbol'),
      },
    ),
  _analysisMessage(
    'empty-identifier',
    arguments: {
      'entity': StructuredMessageArgument.outcome('state', role: 'entity-kind'),
    },
  ),
  for (final code in ['empty-input-symbol', 'empty-output-symbol'])
    _analysisMessage(
      code,
      arguments: {
        'subject': StructuredMessageArgument.literal(
          'alphabet',
          role: 'diagnostic-subject',
        ),
      },
    ),
  _analysisMessage(
    'negative-revision',
    arguments: {'revision': StructuredMessageArgument.integer(-1)},
  ),
];
