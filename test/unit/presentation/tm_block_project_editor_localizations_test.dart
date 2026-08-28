import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt', 'BR'));

  test('resolves every TM block editor failure in English and Portuguese', () {
    final cases = <({StructuredMessage message, String en, String pt})>[
      (
        message: _message(
          'duplicate-block-id',
          arguments: {'block': _id('block_α', 'block-id')},
        ),
        en: 'A machine already uses block ID block_α.',
        pt: 'Uma máquina já usa o ID de bloco block_α.',
      ),
      (
        message: _message(
          'duplicate-block-name',
          arguments: {
            'name': StructuredMessageArgument.literal(
              'Scanner Ω',
              role: 'block-name',
            ),
          },
        ),
        en: 'A block already uses the name Scanner Ω.',
        pt: 'Um bloco já usa o nome Scanner Ω.',
      ),
      (
        message: _message('invalid-block-name'),
        en: 'Block names must be non-empty and unique.',
        pt: 'Os nomes dos blocos devem ser não vazios e únicos.',
      ),
      (
        message: _message(
          'referenced-block',
          arguments: {'block': _id('block_α', 'block-id')},
        ),
        en: 'Block block_α is still referenced. Choose an explicit resolution.',
        pt: 'O bloco block_α ainda está referenciado. Escolha uma resolução explícita.',
      ),
      (
        message: _message(
          'missing-owner-machine',
          arguments: {'machine': _id('root_β', 'machine-id')},
        ),
        en: 'Machine root_β does not exist.',
        pt: 'A máquina root_β não existe.',
      ),
      (
        message: _message(
          'missing-anchor-state',
          arguments: {
            'state': _id('q_α', 'state-id'),
            'machine': _id('root_β', 'machine-id'),
          },
        ),
        en: 'State q_α does not exist in root_β.',
        pt: 'O estado q_α não existe em root_β.',
      ),
      (
        message: _message(
          'state-already-invokes-block',
          arguments: {'state': _id('q_α', 'state-id')},
        ),
        en: 'State q_α already invokes a block.',
        pt: 'O estado q_α já invoca um bloco.',
      ),
      (
        message: _message(
          'duplicate-root-state',
          arguments: {'state': _id('q_α', 'state-id')},
        ),
        en: 'State q_α already exists in the root machine.',
        pt: 'O estado q_α já existe na máquina raiz.',
      ),
      (
        message: _message(
          'missing-invocation',
          arguments: {'invocation': _id('invoke_γ', 'invocation-id')},
        ),
        en: 'Invocation invoke_γ does not exist.',
        pt: 'A invocação invoke_γ não existe.',
      ),
      (
        message: _message('nothing-to-undo'),
        en: 'There is no building-block edit to undo.',
        pt: 'Não há nenhuma edição de bloco de construção para desfazer.',
      ),
      (
        message: _message('nothing-to-redo'),
        en: 'There is no building-block edit to redo.',
        pt: 'Não há nenhuma edição de bloco de construção para refazer.',
      ),
      (
        message: _message(
          'missing-block',
          arguments: {'block': _id('block_α', 'block-id')},
        ),
        en: 'Block block_α does not exist.',
        pt: 'O bloco block_α não existe.',
      ),
      (
        message: _message(
          'invalid-project',
          arguments: {
            'diagnostic': StructuredMessageArgument.outcome(
              'recursiveDependency',
              role: 'tm-block-diagnostic',
            ),
          },
        ),
        en: 'The block dependency graph is recursive.',
        pt: 'O grafo de dependências dos blocos é recursivo.',
      ),
    ];

    for (final testCase in cases) {
      expect(en.resolveStructuredMessage(testCase.message), testCase.en);
      expect(pt.resolveStructuredMessage(testCase.message), testCase.pt);
    }
  });

  test('malformed contracts use the localized fallback with stable code', () {
    final malformed = _message('missing-block');

    expect(
      en.resolveStructuredMessage(malformed),
      'Message unavailable (service.tm-block-editor.missing-block).',
    );
    expect(
      pt.resolveStructuredMessage(malformed),
      'Mensagem indisponível (service.tm-block-editor.missing-block).',
    );
  });
}

StructuredMessage _message(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'service',
  code: 'tm-block-editor.$code',
  category: StructuredMessageCategory.validation,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);

StructuredMessageArgument _id(String value, String role) =>
    StructuredMessageArgument.identifier(value, role: role);
