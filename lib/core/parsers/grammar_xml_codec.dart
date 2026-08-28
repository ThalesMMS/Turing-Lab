import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import '../models/grammar.dart';
import '../messages/structured_message.dart';
import '../models/production.dart';
import '../result.dart';

/// Shared JFLAP XML codec for grammars.
class GrammarXmlCodec {
  const GrammarXmlCodec();

  /// Encodes a [Grammar] into the JFLAP grammar XML shape used by exports.
  String encodeGrammar(Grammar grammar) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        builder.attribute('type', 'grammar');
        builder.element(
          'grammar',
          nest: () {
            builder.attribute('type', grammar.type.name);
            builder.element('start', nest: grammar.startSymbol);

            for (final production in grammar.productions) {
              builder.element(
                'production',
                nest: () {
                  builder.element('left', nest: production.leftSide.join(' '));
                  builder.element(
                    'right',
                    nest: production.rightSide.join(' '),
                  );
                },
              );
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Decodes JFLAP grammar XML into a [Grammar].
  Result<Grammar> decodeGrammarXml(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      return decodeGrammarDocument(document);
    } catch (_) {
      return _failure('malformed-document');
    }
  }

  /// Decodes a parsed JFLAP grammar document into a [Grammar].
  Result<Grammar> decodeGrammarDocument(XmlDocument document) {
    try {
      final grammarElement = document.findAllElements('grammar').firstOrNull;
      if (grammarElement == null) {
        return _failure('missing-grammar-element');
      }

      final startElement = grammarElement.findElements('start').firstOrNull;
      if (startElement == null) {
        return _failure('missing-start-element');
      }
      final startSymbols = _splitGrammarSymbols(startElement.innerText);
      if (startSymbols.isEmpty) {
        return _failure('empty-start-element');
      }
      if (startSymbols.length != 1) {
        return _failure(
          'invalid-start-count',
          arguments: {
            'count': StructuredMessageArgument.count(startSymbols.length),
          },
        );
      }

      final grammarType = _parseGrammarType(
        grammarElement.getAttribute('type'),
      );
      final productions = <Production>{};
      var productionIndex = 0;
      for (final productionElement in grammarElement.findAllElements(
        'production',
      )) {
        final leftElement = productionElement.findElements('left').firstOrNull;
        final rightElement = productionElement
            .findElements('right')
            .firstOrNull;
        if (leftElement == null || rightElement == null) {
          return _failure(
            'incomplete-production',
            arguments: {
              'index': StructuredMessageArgument.index(
                productionIndex,
                role: 'production-index',
              ),
            },
          );
        }

        final leftSide = _splitGrammarSymbols(leftElement.innerText);
        final rightSide = _splitGrammarSymbols(rightElement.innerText);

        productions.add(
          Production(
            id: 'p${productions.length}',
            leftSide: leftSide,
            rightSide: rightSide,
            isLambda: rightSide.isEmpty,
            order: productions.length,
          ),
        );
        productionIndex++;
      }

      final nonterminals = <String>{
        startSymbols.single,
        ...productions.expand((p) => p.leftSide).where((s) => s.isNotEmpty),
      };
      final terminals = productions
          .expand((p) => p.rightSide)
          .where((s) => s.isNotEmpty && !nonterminals.contains(s))
          .toSet();

      final now = DateTime.now();
      final importedId = 'imported_grammar_${now.millisecondsSinceEpoch}';
      return Success(
        Grammar(
          id: importedId,
          name: importedId,
          terminals: terminals,
          nonterminals: nonterminals,
          startSymbol: startSymbols.single,
          productions: productions,
          type: grammarType,
          created: now,
          modified: now,
        ),
      );
    } catch (_) {
      return _failure('malformed-document');
    }
  }

  Failure<T> _failure<T>(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) {
    final message = StructuredMessage(
      namespace: 'parser.grammar-xml',
      code: code,
      category: StructuredMessageCategory.interoperability,
      severity: StructuredMessageSeverity.error,
      arguments: arguments,
    );
    return Failure(message.stableCode, structuredMessage: message);
  }

  List<String> _splitGrammarSymbols(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }
    return trimmed.split(RegExp(r'\s+'));
  }

  GrammarType _parseGrammarType(String? rawType) {
    final normalized = rawType?.trim();
    if (normalized == null || normalized.isEmpty) {
      return GrammarType.contextFree;
    }
    return GrammarType.values.firstWhere(
      (type) => type.name == normalized,
      orElse: () => GrammarType.contextFree,
    );
  }
}
