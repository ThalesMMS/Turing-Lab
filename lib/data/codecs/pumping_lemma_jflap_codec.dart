import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/pumping_lemma/pumping_lemma.dart';
import 'hardened_xml.dart';

final class PumpingLemmaJflapCodec implements DocumentCodecCapability<Object> {
  const PumpingLemmaJflapCodec._({
    required this.theorem,
    required this.systemKey,
    required this.schema,
    required this.typeName,
    required this.codecId,
    required this.namespace,
    required this.fixture,
  });

  const PumpingLemmaJflapCodec.regular()
    : this._(
        theorem: PumpingLemmaTheorem.regular,
        systemKey: DefaultFormalSystemIds.regularPumping,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.pumping-lemma.regular'),
          version: DocumentSchemaVersion(1),
        ),
        typeName: 'regular pumping lemma',
        codecId: const DocumentCodecId('pumping-lemma.regular.jflap.v1'),
        namespace: const CapabilityNamespaceId(
          'codec.pumping-lemma.regular.jflap',
        ),
        fixture:
            'test/fixtures/interoperability/pumping_lemma_regular_canonical.jff',
      );

  const PumpingLemmaJflapCodec.contextFree()
    : this._(
        theorem: PumpingLemmaTheorem.contextFree,
        systemKey: DefaultFormalSystemIds.contextFreePumping,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.pumping-lemma.context-free'),
          version: DocumentSchemaVersion(1),
        ),
        typeName: 'context-free pumping lemma',
        codecId: const DocumentCodecId('pumping-lemma.context-free.jflap.v1'),
        namespace: const CapabilityNamespaceId(
          'codec.pumping-lemma.context-free.jflap',
        ),
        fixture:
            'test/fixtures/interoperability/pumping_lemma_context_free_canonical.jff',
      );

  final PumpingLemmaTheorem theorem;
  final FormalSystemKey systemKey;
  final DocumentSchemaDescriptor schema;
  final String typeName;
  final DocumentCodecId codecId;
  final CapabilityNamespaceId namespace;
  final String fixture;

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: codecId,
    namespace: namespace,
    systemKey: systemKey,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 100,
    compatibilityOwner: 'JFLAP 7.1 pumping lemma XML',
    canonicalFixtures: [fixture],
    semanticCapabilities: {
      CodecSemanticCapabilityId.tokenVectors,
      CodecSemanticCapabilityId.extensions,
    },
    knownUnsupportedFields: const {
      'portable token boundaries after JFLAP open/save',
      'free-form language predicates',
      'full local progress history',
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
          '<type>\\s*${RegExp.escape(typeName)}\\s*</type>',
          caseSensitive: false,
        ).hasMatch(source)) {
      return CodecSniffResult.none;
    }
    return CodecSniffResult(
      confidence: 100,
      detectedSystem: systemKey,
      detectedSchemaVersion: 1,
    );
  }

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    final parsed = parseHardenedXml(payload, descriptor.securityLimits);
    if (parsed is! CodecSuccess<XmlDocument>) return _forward(parsed);
    try {
      final root = parsed.value.rootElement;
      final type = _text(root, 'type');
      if (root.name.local != 'structure' || type != typeName) {
        return const CodecUnsupported(
          reason: CodecUnsupportedReason.document,
          message: 'This XML is not the expected JFLAP pumping lemma type.',
        );
      }
      final extension = root.findElements('turingLabDocument').firstOrNull;
      if (extension != null && extension.innerText.trim().isNotEmpty) {
        final decoded = jsonDecode(extension.innerText);
        if (decoded is! Map) {
          throw const FormatException(
            'turingLabDocument must contain a JSON object.',
          );
        }
        final document = PumpingLemmaDocument.fromJson(
          Map<String, Object?>.from(decoded),
        );
        if (document.theorem != theorem) {
          throw const FormatException('Embedded theorem type mismatch.');
        }
        return CodecSuccess(
          value: InteroperableDocument<Object>(
            document: document,
            systemKey: systemKey,
            schema: schema,
            sourceMetadata: const DocumentSourceMetadata(
              application: 'JFLAP',
              applicationVersion: '7.1',
              sourceFormatVersion: '7.1',
            ),
          ),
          fidelity: DocumentFidelity.exact,
        );
      }
      final decoded = _decodeJflap(root);
      return CodecSuccess(
        value: InteroperableDocument<Object>(
          document: decoded.document,
          systemKey: systemKey,
          schema: schema,
          sourceMetadata: const DocumentSourceMetadata(
            application: 'JFLAP',
            applicationVersion: '7.1',
            sourceFormatVersion: '7.1',
          ),
          extensions: DocumentExtensionBag({
            if (decoded.attempts.isNotEmpty) 'jflap.attempts': decoded.attempts,
          }),
        ),
        fidelity: DocumentFidelity.normalized,
        diagnostics: const [
          CodecDiagnostic(
            code: 'jflap.pumping-lemma.character-tokenization',
            message:
                'JFLAP string offsets were normalized to explicit token indices.',
            path: r'$.structure.w',
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        ],
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        cause: error,
      );
    } catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Malformed JFLAP pumping lemma XML.',
        cause: error,
      );
    }
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != systemKey ||
        document.schema != schema ||
        document.document is! PumpingLemmaDocument) {
      return const CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Expected a pumping lemma document for this workspace.',
      );
    }
    final pumping = document.document as PumpingLemmaDocument;
    if (pumping.theorem != theorem) {
      return const CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'The pumping lemma theorem does not match this workspace.',
      );
    }
    try {
      final session = pumping.erasedSession;
      final builder = XmlBuilder();
      builder
        ..processing('xml', 'version="1.0" encoding="UTF-8"')
        ..element(
          'structure',
          nest: () {
            builder.element('type', nest: typeName);
            builder.element(
              'name',
              nest: pumping.problem.customTitle ?? pumping.problem.id,
            );
            builder.element(
              'first_player',
              nest: session.role == PumpingLemmaRole.learner
                  ? 'Human'
                  : 'Computer',
            );
            builder.element('m', nest: '${session.pumpingLength ?? -1}');
            builder.element('w', nest: session.witness.join());
            builder.element('i', nest: '${session.pumpExponent ?? -1}');
            final lengths = _segmentLengths(session.decomposition, theorem);
            for (final entry in lengths.entries) {
              builder.element(entry.key, nest: '${entry.value}');
            }
            builder.element(
              'turingLabDocument',
              nest: jsonEncode(pumping.toJson()),
            );
          },
        );
      return CodecSuccess(
        value: EncodedDocument(
          bytes: Uint8List.fromList(
            utf8.encode(builder.buildDocument().toXmlString(pretty: true)),
          ),
          mimeType: 'application/xml',
          filename:
              filename ??
              (theorem == PumpingLemmaTheorem.regular
                  ? 'regular-pumping-lemma.jff'
                  : 'context-free-pumping-lemma.jff'),
          schema: schema,
        ),
        fidelity: DocumentFidelity.normalized,
        diagnostics: const [
          CodecDiagnostic(
            code: 'jflap.pumping-lemma.local-extension',
            message:
                'Local token, problem, progress, and history data require a Turing Lab XML extension.',
            path: r'$.structure.turingLabDocument',
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        ],
      );
    } catch (error) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.encode,
        message: 'Could not encode JFLAP pumping lemma XML.',
        cause: error,
      );
    }
  }

  ({PumpingLemmaDocument document, List<String> attempts}) _decodeJflap(
    XmlElement root,
  ) {
    final title = _requiredText(root, 'name');
    final rawP = _integer(_requiredText(root, 'm'));
    final rawExponent = _integer(_requiredText(root, 'i'));
    final witness = _jflapTokens(_text(root, 'w') ?? '');
    final pumpingLength = rawP > 0 ? rawP : null;
    if (pumpingLength != null && witness.length < pumpingLength) {
      throw const FormatException(
        'The JFLAP witness is shorter than the pumping length.',
      );
    }
    final role = (_text(root, 'first_player') ?? '').toLowerCase() == 'computer'
        ? PumpingLemmaRole.adversary
        : PumpingLemmaRole.learner;
    final problem = PumpingLemmaProblem(
      id: 'jflap-${theorem.name}-${_stableId(title)}',
      customTitle: title,
      theorem: theorem,
      languageDescription: title,
      representationKind:
          PumpingLanguageRepresentationKind.customBoundedPredicate,
      representation: title,
      sourceRevision: 'jflap-7.1',
      suggestedPumpingLength: pumpingLength ?? 1,
      suggestedWitness: witness.isEmpty ? const ['a'] : witness,
    );
    if (theorem == PumpingLemmaTheorem.regular) {
      final decomposition = pumpingLength == null || witness.isEmpty
          ? null
          : _regularDecomposition(root, witness, pumpingLength);
      final session = PumpingLemmaSession<RegularPumpingDecomposition>(
        sessionId: 'jflap-regular-session',
        challengeId: problem.id,
        sourceRevision: problem.sourceRevision,
        theorem: theorem,
        mode: PumpingLemmaMode.freeForm,
        role: role,
        targetLanguage: problem.languageDescription,
        pumpingLength: pumpingLength,
        witness: pumpingLength == null ? const [] : witness,
        decomposition: decomposition,
        pumpExponent: decomposition != null && rawExponent >= 0
            ? rawExponent
            : null,
      );
      return (
        document: RegularPumpingLemmaDocument(
          problem: problem,
          session: session,
          progress: PumpingLemmaEnvironmentProgress(),
        ),
        attempts: root
            .findElements('attempt')
            .map((element) => element.innerText)
            .toList(growable: false),
      );
    }
    final decomposition = pumpingLength == null || witness.isEmpty
        ? null
        : _contextFreeDecomposition(root, witness, pumpingLength);
    final session = PumpingLemmaSession<ContextFreePumpingDecomposition>(
      sessionId: 'jflap-context-free-session',
      challengeId: problem.id,
      sourceRevision: problem.sourceRevision,
      theorem: theorem,
      mode: PumpingLemmaMode.freeForm,
      role: role,
      targetLanguage: problem.languageDescription,
      pumpingLength: pumpingLength,
      witness: pumpingLength == null ? const [] : witness,
      decomposition: decomposition,
      pumpExponent: decomposition != null && rawExponent >= 0
          ? rawExponent
          : null,
    );
    return (
      document: ContextFreePumpingLemmaDocument(
        problem: problem,
        session: session,
        progress: PumpingLemmaEnvironmentProgress(),
      ),
      attempts: root
          .findElements('attempt')
          .map((element) => element.innerText)
          .toList(growable: false),
    );
  }
}

RegularPumpingDecomposition? _regularDecomposition(
  XmlElement root,
  List<String> witness,
  int pumpingLength,
) {
  final xLength = _integer(_requiredText(root, 'xLength'));
  final yLength = _integer(_requiredText(root, 'yLength'));
  if (xLength < 0 || yLength <= 0 || xLength + yLength > witness.length) {
    return null;
  }
  final decomposition = RegularPumpingDecomposition(
    x: witness.sublist(0, xLength),
    y: witness.sublist(xLength, xLength + yLength),
    z: witness.sublist(xLength + yLength),
  );
  return decomposition.validate(pumpingLength: pumpingLength).isEmpty
      ? decomposition
      : null;
}

ContextFreePumpingDecomposition? _contextFreeDecomposition(
  XmlElement root,
  List<String> witness,
  int pumpingLength,
) {
  final lengths = [
    _integer(_requiredText(root, 'uLength')),
    _integer(_requiredText(root, 'vLength')),
    _integer(_requiredText(root, 'xLength')),
    _integer(_requiredText(root, 'yLength')),
  ];
  if (lengths.any((value) => value < 0) ||
      lengths.fold<int>(0, (sum, value) => sum + value) > witness.length) {
    return null;
  }
  final uEnd = lengths[0];
  final vEnd = uEnd + lengths[1];
  final xEnd = vEnd + lengths[2];
  final yEnd = xEnd + lengths[3];
  final decomposition = ContextFreePumpingDecomposition(
    u: witness.sublist(0, uEnd),
    v: witness.sublist(uEnd, vEnd),
    x: witness.sublist(vEnd, xEnd),
    y: witness.sublist(xEnd, yEnd),
    z: witness.sublist(yEnd),
  );
  return decomposition.validate(pumpingLength: pumpingLength).isEmpty
      ? decomposition
      : null;
}

Map<String, int> _segmentLengths(
  PumpingDecomposition? decomposition,
  PumpingLemmaTheorem theorem,
) {
  if (decomposition is RegularPumpingDecomposition) {
    return {
      'xLength': decomposition.x.length,
      'yLength': decomposition.y.length,
    };
  }
  if (decomposition is ContextFreePumpingDecomposition) {
    return {
      'uLength': decomposition.u.length,
      'vLength': decomposition.v.length,
      'xLength': decomposition.x.length,
      'yLength': decomposition.y.length,
    };
  }
  return theorem == PumpingLemmaTheorem.contextFree
      ? {'uLength': 0, 'vLength': 0, 'xLength': 0, 'yLength': 0}
      : {'xLength': 0, 'yLength': 0};
}

String? _text(XmlElement root, String name) =>
    root.findElements(name).firstOrNull?.innerText.trim();

String _requiredText(XmlElement root, String name) {
  final value = _text(root, name);
  if (value == null) throw FormatException('Missing JFLAP element <$name>.');
  return value;
}

int _integer(String value) {
  final parsed = int.tryParse(value);
  if (parsed == null) throw FormatException('Invalid JFLAP integer: $value.');
  return parsed;
}

List<String> _jflapTokens(String value) =>
    value.runes.map(String.fromCharCode).toList(growable: false);

String _stableId(String value) =>
    base64Url.encode(utf8.encode(value)).replaceAll('=', '').toLowerCase();

CodecOutcome<T> _forward<T>(CodecOutcome<XmlDocument> outcome) =>
    switch (outcome) {
      CodecMalformed<XmlDocument>() => CodecMalformed(
        reason: outcome.reason,
        message: outcome.message,
        location: outcome.location,
        cause: outcome.cause,
      ),
      CodecResourceLimit<XmlDocument>() => CodecResourceLimit(
        limit: outcome.limit,
        maximum: outcome.maximum,
        actual: outcome.actual,
      ),
      CodecUnsupported<XmlDocument>() => CodecUnsupported(
        reason: outcome.reason,
        message: outcome.message,
        roadmapIssue: outcome.roadmapIssue,
      ),
      CodecAmbiguous<XmlDocument>() => CodecAmbiguous(
        codecIds: outcome.codecIds,
      ),
      CodecInternalFailure<XmlDocument>() => CodecInternalFailure(
        stage: outcome.stage,
        message: outcome.message,
        cause: outcome.cause,
      ),
      CodecSuccess<XmlDocument>() => throw StateError('Unexpected success.'),
    };
