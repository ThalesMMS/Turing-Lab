import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/regex_document.dart';
import 'codec_utils.dart';
import 'hardened_xml.dart';
import 'regex_json_document_codec.dart';
import 'regex_codec_messages.dart';

/// Loss-aware JFLAP 7.1 regular-expression XML codec.
final class RegexJflapDocumentCodec implements DocumentCodecCapability<Object> {
  const RegexJflapDocumentCodec();

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('regex.jflap.v1'),
    namespace: const CapabilityNamespaceId('codec.regex.jflap'),
    systemKey: DefaultFormalSystemIds.regex,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 100,
    compatibilityOwner: 'JFLAP 7.1 RETransducer',
    canonicalFixtures: ['test/fixtures/interoperability/regex_canonical.jff'],
    semanticCapabilities: {
      CodecSemanticCapabilityId.tokenVectors,
      CodecSemanticCapabilityId.extensions,
    },
    knownUnsupportedFields: {
      'JFLAP has no portable alphabet or tokenization metadata',
      'JFLAP has no escaping for its operators',
      'JFLAP empty-set conversion is not behaviorally consistent',
      'non-BMP symbols are split by the JFLAP Java char model',
    },
  );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecSniffResult.none;
    }
    final source = utf8.decode(payload.bytes, allowMalformed: true);
    if (!source.contains('<structure') ||
        !RegExp(
          r'<type>\s*re\s*</type>',
          caseSensitive: false,
        ).hasMatch(source)) {
      return CodecSniffResult.none;
    }
    return CodecSniffResult(
      confidence: 100,
      detectedSystem: DefaultFormalSystemIds.regex,
      detectedSchemaVersion: 1,
    );
  }

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    final parsed = parseHardenedXml(payload, descriptor.securityLimits);
    if (parsed is! CodecSuccess<XmlDocument>) return copyXmlFailure(parsed);
    try {
      final root = parsed.value.rootElement;
      if (root.name.local != 'structure' || _singleText(root, 'type') != 're') {
        return CodecUnsupported(
          reason: CodecUnsupportedReason.document,
          message: 'This XML is not a JFLAP regular-expression document.',
          structuredMessage: RegexJflapMessages.unsupportedDocument(),
        );
      }
      final expressions = root.findElements('expression').toList();
      if (expressions.length > 1) {
        throw _RegexJflapFormatException(
          'JFLAP Regex documents may contain at most one expression element.',
          RegexJflapMessages.multipleExpressions(),
        );
      }
      final jflapSource = expressions.firstOrNull?.innerText ?? '';
      final extensionElements = root.findElements('turingLabRegex').toList();
      if (extensionElements.length > 1) {
        throw _RegexJflapFormatException(
          'JFLAP Regex documents may contain at most one Turing Lab extension.',
          RegexJflapMessages.multipleExtensions(),
        );
      }
      final extensions = <String, Object?>{};
      final diagnostics = <CodecDiagnostic>[];
      preserveXmlAttributes(
        root,
        known: const {},
        key: 'rootAttributes',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      preserveXmlChildren(
        root,
        known: const {'type', 'expression', 'turingLabRegex'},
        key: 'rootChildren',
        extensions: extensions,
        diagnostics: diagnostics,
      );

      final extension = extensionElements.firstOrNull;
      if (extension != null && extension.innerText.trim().isNotEmpty) {
        Object? decoded;
        try {
          decoded = jsonDecode(extension.innerText);
        } on FormatException catch (error) {
          throw _RegexJflapFormatException(
            error.message,
            RegexJflapMessages.invalidExtension(),
          );
        }
        if (decoded is! Map) {
          throw _RegexJflapFormatException(
            'turingLabRegex must contain a JSON object.',
            RegexJflapMessages.invalidExtension(),
          );
        }
        late final RegexDocument document;
        try {
          document = RegexDocument.fromJson(Map<String, dynamic>.from(decoded));
        } on FormatException catch (error) {
          throw _RegexJflapFormatException(
            error.message,
            RegexJflapMessages.invalidDocument(),
          );
        }
        _requireValidDocument(document);
        final mapped = _toJflap(document.source);
        if (mapped != jflapSource) {
          throw _RegexJflapFormatException(
            'The Turing Lab Regex extension does not match the JFLAP expression.',
            RegexJflapMessages.extensionMismatch(),
          );
        }
        return CodecSuccess(
          value: InteroperableDocument<Object>(
            document: document,
            systemKey: DefaultFormalSystemIds.regex,
            schema: RegexJsonDocumentCodec.schema,
            sourceMetadata: const DocumentSourceMetadata(
              application: 'JFLAP',
              applicationVersion: '7.1',
              sourceFormatVersion: '7.1',
            ),
            extensions: DocumentExtensionBag(extensions),
          ),
          fidelity: DocumentFidelity.exact,
          diagnostics: diagnostics,
        );
      }

      final conversion = _fromJflap(jflapSource);
      if (conversion.source.isNotEmpty) {
        final validation = RegexToNFAConverter.validate(conversion.source);
        if (!validation.isValid) {
          throw _RegexJflapFormatException(
            validation.diagnostic!.displayMessage,
            RegexJflapMessages.invalidSource(),
          );
        }
      }
      final document = RegexDocument(
        id: deterministicContentId('regex', jflapSource),
        name: _nameFromFilename(payload.filename),
        source: conversion.source,
        alphabet: _literalAlphabet(conversion.source),
      );
      diagnostics.addAll(conversion.diagnostics);
      diagnostics.add(
        CodecDiagnostic(
          code: 'jflap.regex-dialect-normalized',
          message:
              'JFLAP union and epsilon syntax was normalized to the Turing Lab dialect.',
          path: r'$.structure.expression',
          structuredMessage: RegexJflapMessages.dialectNormalized(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      );
      return CodecSuccess(
        value: InteroperableDocument<Object>(
          document: document,
          systemKey: DefaultFormalSystemIds.regex,
          schema: RegexJsonDocumentCodec.schema,
          sourceMetadata: const DocumentSourceMetadata(
            application: 'JFLAP',
            applicationVersion: '7.1',
            sourceFormatVersion: '7.1',
          ),
          extensions: DocumentExtensionBag(extensions),
        ),
        fidelity: conversion.lossy
            ? DocumentFidelity.lossy
            : DocumentFidelity.normalized,
        diagnostics: diagnostics,
      );
    } on _RegexJflapUnsupported catch (error) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: error.message,
        roadmapIssue: 327,
        structuredMessage: error.structuredMessage,
      );
    } on _RegexJflapFormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        cause: error,
        structuredMessage: error.structuredMessage,
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        cause: error,
        structuredMessage: RegexJflapMessages.invalidSource(),
      );
    } catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Malformed JFLAP regular-expression document.',
        cause: error,
        structuredMessage: RegexJflapMessages.malformedDocument(),
      );
    }
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    final value = document.document;
    if (document.systemKey != DefaultFormalSystemIds.regex ||
        document.schema != RegexJsonDocumentCodec.schema ||
        value is! RegexDocument) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Expected a Regex document.',
        structuredMessage: RegexJflapMessages.expectedRegexDocument(),
      );
    }
    try {
      _requireValidDocument(value);
      final jflapSource = _toJflap(value.source);
      final builder = XmlBuilder();
      builder
        ..processing('xml', 'version="1.0" encoding="UTF-8"')
        ..element(
          'structure',
          nest: () {
            writeXmlAttributes(
              builder,
              document.extensions.values['rootAttributes'],
            );
            builder.element('type', nest: 're');
            builder.comment('The regular expression.');
            builder.element('expression', nest: jflapSource);
            builder.element(
              'turingLabRegex',
              nest: canonicalJson(value.toJson()),
            );
            writeXmlExtensions(
              builder,
              document.extensions.values['rootChildren'],
            );
          },
        );
      final xml = '${builder.buildDocument().toXmlString(pretty: true)}\n';
      return CodecSuccess(
        value: EncodedDocument(
          bytes: Uint8List.fromList(utf8.encode(xml)),
          mimeType: 'application/xml',
          filename: filenameWithExtension(
            filename,
            _safeFilename(value.name),
            'jff',
          ),
          schema: RegexJsonDocumentCodec.schema,
        ),
        fidelity: DocumentFidelity.lossy,
        diagnostics: [
          CodecDiagnostic(
            code: 'jflap.regex-turing-lab-extension-portability',
            message:
                'JFLAP preserves the expression language, but open/save drops Turing Lab identity, alphabet, tokenization, and unknown extensions.',
            path: r'$.structure.turingLabRegex',
            structuredMessage: RegexJflapMessages.portabilityLossy(),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        ],
      );
    } on _RegexJflapUnsupported catch (error) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: error.message,
        roadmapIssue: 327,
        structuredMessage: error.structuredMessage,
      );
    } on _RegexJflapFormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        cause: error,
        structuredMessage: error.structuredMessage,
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        cause: error,
        structuredMessage: RegexJflapMessages.invalidSource(),
      );
    } catch (error) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.encode,
        message: 'Failed to encode the JFLAP Regex document.',
        cause: error,
        structuredMessage: RegexJflapMessages.malformedDocument(),
      );
    }
  }
}

void _requireValidDocument(RegexDocument document) {
  final errors = document.validate();
  if (errors.isNotEmpty) {
    throw _RegexJflapFormatException(
      errors.first,
      RegexJflapMessages.invalidDocument(),
    );
  }
  if (document.dialect != RegexDialect.turingLabV1 ||
      document.tokenization != RegexTokenization.unicodeScalar ||
      document.epsilonSymbol != 'ε' ||
      document.emptyLanguageSymbol != '∅') {
    throw _RegexJflapUnsupported(
      'JFLAP export supports only the Turing Lab v1 Unicode-scalar Regex dialect.',
      RegexJflapMessages.unsupportedDialect(),
    );
  }
  if (document.source.isNotEmpty) {
    final validation = RegexToNFAConverter.validate(document.source);
    if (!validation.isValid) {
      throw _RegexJflapFormatException(
        validation.diagnostic!.displayMessage,
        RegexJflapMessages.invalidSource(),
      );
    }
  }
}

String _toJflap(String source) {
  final output = StringBuffer();
  final characters = source.runes.map(String.fromCharCode).toList();
  for (var index = 0; index < characters.length; index++) {
    final char = characters[index];
    if (char.length > 1) {
      throw _RegexJflapUnsupported(
        'JFLAP regular expressions cannot safely preserve non-BMP symbols.',
        RegexJflapMessages.nonBmpSymbol(),
      );
    }
    if (char == '\\') {
      if (++index >= characters.length) {
        throw _RegexJflapFormatException(
          'Regex escape must be followed by a symbol.',
          RegexJflapMessages.escapeMissingSymbol(),
        );
      }
      final literal = characters[index];
      if (literal.length > 1 ||
          const {'+', '*', '(', ')', '!', 'ø', 'ε', 'λ'}.contains(literal)) {
        throw _RegexJflapUnsupported(
          'JFLAP has no escape syntax for the literal "$literal".',
          RegexJflapMessages.escapeUnsupported(literal),
        );
      }
      output.write(literal);
      continue;
    }
    switch (char) {
      case '|':
        output.write('+');
      case 'ε':
        output.write('!');
      case '∅':
        throw _RegexJflapUnsupported(
          'JFLAP 7.1 does not reopen the empty-language symbol with equivalent semantics.',
          RegexJflapMessages.emptyLanguageUnsupported(),
        );
      case '!':
      case 'ø':
      case 'λ':
        throw _RegexJflapUnsupported(
          'The literal "$char" has reserved or profile-dependent meaning in JFLAP.',
          RegexJflapMessages.reservedLiteral(char),
        );
      case '+':
      case '?':
      case '.':
      case '[':
      case ']':
        throw _RegexJflapUnsupported(
          'The JFLAP Regex dialect does not support the "$char" construct.',
          RegexJflapMessages.unsupportedConstruct(char),
        );
      default:
        output.write(char);
    }
  }
  final result = output.toString();
  _validateJflap(result);
  return result;
}

({String source, bool lossy, List<CodecDiagnostic> diagnostics}) _fromJflap(
  String source,
) {
  _validateJflap(source);
  final output = StringBuffer();
  var lossy = false;
  final diagnostics = <CodecDiagnostic>[];
  for (final char in source.runes.map(String.fromCharCode)) {
    if (char.length > 1) {
      throw _RegexJflapUnsupported(
        'JFLAP non-BMP Regex symbols do not have portable Java-char semantics.',
        RegexJflapMessages.nonBmpSymbol(),
      );
    }
    switch (char) {
      case '+':
        output.write('|');
      case '!':
        output.write('ε');
      case 'ø':
        output.write('∅');
        lossy = true;
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.regex-empty-set-interoperability',
            message:
                'JFLAP-generated ø was interpreted as the empty language; JFLAP 7.1 conversion treats that symbol inconsistently.',
            path: r'$.structure.expression',
            sourceValue: 'ø',
            structuredMessage: RegexJflapMessages.emptySetInteroperability(),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      case 'ε':
      case 'λ':
        throw _RegexJflapUnsupported(
          'The JFLAP symbol "$char" depends on a global profile; use ! for portable epsilon.',
          RegexJflapMessages.profileDependentSymbol(char),
        );
      case '|':
      case '?':
      case '.':
      case '[':
      case ']':
      case '\\':
      case '∅':
        output
          ..write('\\')
          ..write(char);
      default:
        output.write(char);
    }
  }
  return (source: output.toString(), lossy: lossy, diagnostics: diagnostics);
}

void _validateJflap(String source) {
  if (source.isEmpty) return;
  var depth = 0;
  for (var index = 0; index < source.length; index++) {
    final char = source[index];
    if (char == '(') depth++;
    if (char == ')' && --depth < 0) {
      throw _RegexJflapFormatException(
        'JFLAP Regex parentheses are unbalanced.',
        RegexJflapMessages.unbalancedParentheses(),
      );
    }
    if (index == 0 && const {')', '+', '*'}.contains(char)) {
      throw _RegexJflapFormatException(
        'JFLAP Regex operators are poorly formatted.',
        RegexJflapMessages.malformedOperators(),
      );
    }
    if (char == '+' && index == source.length - 1) {
      throw _RegexJflapFormatException(
        'JFLAP Regex union lacks a right operand.',
        RegexJflapMessages.unionMissingOperand(),
      );
    }
    if (index > 0 && const {'+', ')', '*'}.contains(char)) {
      final previous = source[index - 1];
      if (previous == '(' || previous == '+') {
        throw _RegexJflapFormatException(
          'JFLAP Regex operators are poorly formatted.',
          RegexJflapMessages.malformedOperators(),
        );
      }
    }
    if (char == '!') {
      final previous = index == 0 ? null : source[index - 1];
      final next = index + 1 == source.length ? null : source[index + 1];
      if (previous != null && previous != '(' && previous != '+') {
        throw _RegexJflapFormatException(
          'JFLAP epsilon cannot be concatenated on its left.',
          RegexJflapMessages.epsilonLeftConcatenation(),
        );
      }
      if (next != null && next != ')' && next != '+' && next != '*') {
        throw _RegexJflapFormatException(
          'JFLAP epsilon cannot be concatenated on its right.',
          RegexJflapMessages.epsilonRightConcatenation(),
        );
      }
    }
  }
  if (depth != 0) {
    throw _RegexJflapFormatException(
      'JFLAP Regex parentheses are unbalanced.',
      RegexJflapMessages.unbalancedParentheses(),
    );
  }
}

Set<String> _literalAlphabet(String source) {
  final node = RegexToNFAConverter.parse(source);
  if (node == null) return const {};
  final symbols = <String>{};
  void collect(RegexNode current) {
    switch (current) {
      case SymbolNode(:final symbol):
        symbols.add(symbol);
      case SetNode(symbols: final classSymbols):
        symbols.addAll(classSymbols);
      case UnionNode(:final left, :final right):
      case ConcatenationNode(:final left, :final right):
        collect(left);
        collect(right);
      case KleeneStarNode(:final child):
      case PlusNode(:final child):
      case QuestionNode(:final child):
        collect(child);
      case DotNode():
      case ShortcutNode():
      case EpsilonNode():
      case EmptyLanguageNode():
        break;
      case _:
        break;
    }
  }

  collect(node);
  return symbols;
}

String _singleText(XmlElement root, String name) {
  final values = root.findElements(name).toList();
  if (values.length != 1) {
    throw _RegexJflapFormatException(
      'JFLAP Regex requires exactly one $name element.',
      RegexJflapMessages.expectedRegexDocument(),
    );
  }
  return values.single.innerText.trim();
}

String _nameFromFilename(String? filename) {
  final value = filename?.trim();
  if (value == null || value.isEmpty) return 'Imported regular expression';
  final dot = value.lastIndexOf('.');
  final base = dot > 0 ? value.substring(0, dot) : value;
  return base.trim().isEmpty ? 'Imported regular expression' : base;
}

String _safeFilename(String name) {
  final safe = name
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return safe.isEmpty ? 'regular-expression' : safe;
}

final class _RegexJflapUnsupported implements Exception {
  const _RegexJflapUnsupported(this.message, this.structuredMessage);

  final String message;
  final StructuredMessage structuredMessage;
}

final class _RegexJflapFormatException implements Exception {
  const _RegexJflapFormatException(this.message, this.structuredMessage);

  final String message;
  final StructuredMessage structuredMessage;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
