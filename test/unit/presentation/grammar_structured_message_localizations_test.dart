import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/algorithms/grammar_analysis_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_input_messages.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('grammar dependency messages resolve and survive persistence', () {
    final messages = <StructuredMessage>[
      _message(
        'summary-counts',
        arguments: {
          'variable-count': StructuredMessageArgument.count(
            2,
            role: 'variable-count',
          ),
          'edge-count': StructuredMessageArgument.count(1, role: 'edge-count'),
        },
      ),
      _message('no-recursion-cycle'),
      _message(
        'recursion-cycle-count',
        arguments: {
          'cycle-count': StructuredMessageArgument.count(
            2,
            role: 'cycle-count',
          ),
        },
      ),
      for (final code in ['unreachable-variable', 'nonproductive-variable'])
        _message(
          code,
          arguments: {
            'variable': StructuredMessageArgument.symbol(
              'Expr🙂',
              role: 'grammar-variable',
            ),
          },
        ),
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
      en.resolveStructuredMessage(messages.first),
      '2 variables and 1 dependency edge.',
    );
    expect(
      pt.resolveStructuredMessage(messages.first),
      '2 variáveis e 1 aresta de dependência.',
    );
    expect(en.resolveStructuredMessage(messages.last), contains('Expr🙂'));
    expect(pt.resolveStructuredMessage(messages.last), contains('Expr🙂'));
  });

  test(
    'invalid grammar argument contract uses the localized safe fallback',
    () {
      final message = _message(
        'unreachable-variable',
        arguments: {
          'variable': StructuredMessageArgument.literal(
            'S',
            role: 'grammar-variable',
          ),
        },
      );

      expect(
        en.resolveStructuredMessage(message),
        'Message unavailable (${message.stableCode}).',
      );
      expect(
        pt.resolveStructuredMessage(message),
        'Mensagem indisponível (${message.stableCode}).',
      );
    },
  );

  test('LL(1) conflict messages resolve in English and Portuguese', () {
    final messages = [
      _ll1ConflictMessage('first-first'),
      _ll1ConflictMessage('first-follow'),
    ];

    expect(
      en.resolveStructuredMessage(messages.first),
      'FIRST/FIRST conflict in [S, a]: p1 S → a | p2 S → a A.',
    );
    expect(
      pt.resolveStructuredMessage(messages.first),
      'Conflito FIRST/FIRST em [S, a]: p1 S → a | p2 S → a A.',
    );
    expect(
      en.resolveStructuredMessage(messages.last),
      contains('FIRST/FOLLOW conflict'),
    );
    expect(
      pt.resolveStructuredMessage(messages.last),
      contains('Conflito FIRST/FOLLOW'),
    );
    for (final message in messages) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
  });

  test('grammar tokenizer diagnostics resolve with a one-based position', () {
    final message = GrammarInputMessages.invalidSymbol(
      symbol: '?',
      position: 2,
    );

    expect(
      en.resolveStructuredMessage(message),
      'Input string contains invalid symbol ? at position 3.',
    );
    expect(
      pt.resolveStructuredMessage(message),
      'A cadeia de entrada contém o símbolo inválido ? na posição 3.',
    );
    expect(StructuredMessage.fromJson(message.toJson()), message);
  });

  test('grammar ambiguity notes resolve in English and Portuguese', () {
    final messages = [
      GrammarAmbiguityMessages.noLl1Conflicts(),
      GrammarAmbiguityMessages.ll1ConflictsDetected(),
      GrammarAmbiguityMessages.nonLl1DoesNotImplyAmbiguity(),
    ];

    expect(
      en.resolveStructuredMessage(messages[0]),
      'No LL(1) conflicts detected (grammar appears LL(1) for this analysis).',
    );
    expect(
      pt.resolveStructuredMessage(messages[0]),
      'Nenhum conflito LL(1) detectado (a gramática parece ser LL(1) para esta análise).',
    );
    expect(
      en.resolveStructuredMessage(messages[1]),
      'LL(1) conflicts detected (grammar is not LL(1)).',
    );
    expect(
      pt.resolveStructuredMessage(messages[1]),
      'Conflitos LL(1) detectados (a gramática não é LL(1)).',
    );
    expect(
      en.resolveStructuredMessage(messages[2]),
      contains('does not necessarily mean the grammar is ambiguous'),
    );
    expect(
      pt.resolveStructuredMessage(messages[2]),
      contains('não significa necessariamente que a gramática seja ambígua'),
    );
    for (final message in messages) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
  });

  test('grammar analysis messages resolve in English and Portuguese', () {
    final messages = [
      GrammarAnalysisMessages.emptyProductions(),
      GrammarAnalysisMessages.noLeftRecursion(),
    ];

    expect(
      en.resolveStructuredMessage(messages[0]),
      'The grammar has no productions.',
    );
    expect(
      pt.resolveStructuredMessage(messages[0]),
      'A gramática não possui produções.',
    );
    expect(
      en.resolveStructuredMessage(messages[1]),
      'No direct or indirect left recursion detected.',
    );
    expect(
      pt.resolveStructuredMessage(messages[1]),
      'Nenhuma recursão à esquerda direta ou indireta foi detectada.',
    );
    for (final message in messages) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
  });

  test('malformed and future LL(1) conflicts use the safe fallback', () {
    final messages = [
      _ll1ConflictMessage('future-kind'),
      _ll1ConflictMessage('first-first', includeLookahead: false),
      _ll1ConflictMessage('first-first', wrongAlternativesKind: true),
      _ll1ConflictMessage('first-first', includeExtra: true),
    ];

    for (final message in messages) {
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

  test('unrestricted grammar workflow failures resolve in Portuguese', () {
    const translations = {
      'Imported document is not an unrestricted grammar.':
          'O documento importado não é uma gramática irrestrita.',
      'Expected an unrestricted grammar.':
          'Era esperada uma gramática irrestrita.',
      'Unsupported unrestricted grammar session.':
          'A sessão da gramática irrestrita não é compatível.',
    };

    for (final entry in translations.entries) {
      expect(en.localizeWorkflowText(entry.key), entry.key);
      expect(pt.localizeWorkflowText(entry.key), entry.value);
    }
  });
}

StructuredMessage _message(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'grammar.dependency-graph',
  code: code,
  category: StructuredMessageCategory.analysis,
  severity: StructuredMessageSeverity.information,
  arguments: arguments,
);

StructuredMessage _ll1ConflictMessage(
  String kind, {
  bool includeLookahead = true,
  bool wrongAlternativesKind = false,
  bool includeExtra = false,
}) => StructuredMessage(
  namespace: 'grammar.ll1-conflict',
  code: 'detected',
  category: StructuredMessageCategory.analysis,
  severity: StructuredMessageSeverity.warning,
  arguments: {
    'kind': StructuredMessageArgument.outcome(kind, role: 'll1-conflict-kind'),
    'non-terminal': StructuredMessageArgument.symbol(
      'S',
      role: 'grammar-nonterminal',
    ),
    if (includeLookahead)
      'lookahead': StructuredMessageArgument.symbol(
        'a',
        role: 'grammar-lookahead',
      ),
    'alternatives': wrongAlternativesKind
        ? StructuredMessageArgument.outcome(
            'p1 S → a | p2 S → a A',
            role: 'grammar-productions',
          )
        : StructuredMessageArgument.literal(
            'p1 S → a | p2 S → a A',
            role: 'grammar-productions',
          ),
    if (includeExtra) 'extra': StructuredMessageArgument.count(1),
  },
);
