import '../formal_systems/formal_systems.dart';
import '../messages/structured_message.dart';
import 'codec_descriptor.dart';
import 'codec_outcome.dart';
import 'codec_payload_prescan.dart';
import 'codec_source.dart';

final class DetectedDocument {
  const DetectedDocument({required this.codec, required this.sniff});

  final DocumentCodecCapability<Object> codec;
  final CodecSniffResult sniff;

  CodecDescriptor get descriptor => codec.descriptor;
}

final class DocumentInteroperabilityRegistry {
  factory DocumentInteroperabilityRegistry.fromFormalSystems(
    FormalSystemRegistry formalSystems,
  ) {
    final registrations = <_CodecRegistration>[];
    for (final module in formalSystems.modules) {
      for (final codec in module.codecs) {
        registrations.add(_CodecRegistration(module.descriptor, codec));
      }
    }
    final issues = _validate(formalSystems, registrations);
    if (issues.isNotEmpty) {
      throw ArgumentError.value(
        issues.map((issue) => issue.toJson()).toList(growable: false),
        'formalSystems',
        'interop.registry.invalid-registrations',
      );
    }
    return DocumentInteroperabilityRegistry._(
      formalSystems,
      List<_CodecRegistration>.unmodifiable(registrations),
    );
  }

  const DocumentInteroperabilityRegistry._(
    this.formalSystems,
    this._registrations,
  );

  final FormalSystemRegistry formalSystems;
  final List<_CodecRegistration> _registrations;

  List<CodecDescriptor> get descriptors => List<CodecDescriptor>.unmodifiable(
    _registrations.map((registration) => registration.codec.descriptor),
  );

  CodecOutcome<DetectedDocument> detect(
    DocumentPayload payload, {
    FormalSystemKey? expectedSystem,
    DocumentFormatId? expectedFormat,
  }) {
    final candidates = <DetectedDocument>[];
    CodecResourceLimit<DetectedDocument>? resourceLimit;
    CodecInternalFailure<DetectedDocument>? sniffFailure;
    final preScanByPolicy = <String, CodecPayloadPreScanLimit?>{};
    final eligible = _registrations
        .where((registration) {
          final descriptor = registration.codec.descriptor;
          return (expectedSystem == null ||
                  descriptor.systemKey == expectedSystem) &&
              (expectedFormat == null ||
                  descriptor.formatId == expectedFormat) &&
              descriptor.directions.contains(
                DocumentFormatDirection.importDocument,
              );
        })
        .toList(growable: false);
    for (final registration in eligible) {
      final descriptor = registration.codec.descriptor;
      if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
        resourceLimit ??= CodecResourceLimit<DetectedDocument>(
          limit: CodecResourceLimitKind.bytes,
          maximum: descriptor.securityLimits.maximumBytes,
          actual: payload.bytes.length,
        );
        continue;
      }
      final limits = descriptor.securityLimits;
      final preScanKey =
          '${descriptor.formatId.value}|'
          '${limits.maximumDepth}|${limits.maximumElements}|'
          '${limits.maximumCollectionEntries}';
      final preScan = preScanByPolicy.containsKey(preScanKey)
          ? preScanByPolicy[preScanKey]
          : preScanByPolicy[preScanKey] = preScanCodecPayload(
              payload,
              descriptor,
            );
      if (preScan != null) {
        resourceLimit ??= CodecResourceLimit<DetectedDocument>(
          limit: preScan.kind,
          maximum: preScan.maximum,
          actual: preScan.actual,
        );
        continue;
      }
      try {
        final sniff = registration.codec.sniff(payload);
        if ((sniff.detectedSystem != null &&
                sniff.detectedSystem != descriptor.systemKey) ||
            (sniff.detectedSchemaVersion != null &&
                !descriptor.schemas.contains(sniff.detectedSchemaVersion!))) {
          sniffFailure ??= _internalFailure(
            stage: CodecInternalFailureStage.sniff,
            code: 'sniff-identity-mismatch',
            arguments: {
              'codec': StructuredMessageArgument.identifier(
                descriptor.codecId.value,
                role: 'codec',
              ),
            },
          );
          continue;
        }
        if (sniff.confidence > 0) {
          candidates.add(
            DetectedDocument(codec: registration.codec, sniff: sniff),
          );
        }
      } catch (error) {
        sniffFailure ??= _internalFailure(
          stage: CodecInternalFailureStage.sniff,
          code: 'sniff-failed',
          arguments: {
            'codec': StructuredMessageArgument.identifier(
              descriptor.codecId.value,
              role: 'codec',
            ),
          },
          cause: error,
        );
      }
    }
    if (candidates.isEmpty) {
      if (sniffFailure == null &&
          resourceLimit == null &&
          expectedSystem != null &&
          expectedFormat != null &&
          eligible.length == 1) {
        return CodecSuccess(
          value: DetectedDocument(
            codec: eligible.single.codec,
            sniff: CodecSniffResult.none,
          ),
          fidelity: DocumentFidelity.exact,
        );
      }
      return sniffFailure ??
          resourceLimit ??
          _unsupported(
            reason: CodecUnsupportedReason.document,
            code: 'document-unrecognized',
          );
    }
    candidates.sort((left, right) {
      final confidence = right.sniff.confidence.compareTo(
        left.sniff.confidence,
      );
      if (confidence != 0) return confidence;
      return right.descriptor.priority.compareTo(left.descriptor.priority);
    });
    final best = candidates.first;
    final ambiguous = candidates.where(
      (candidate) =>
          candidate.sniff.confidence == best.sniff.confidence &&
          candidate.descriptor.priority == best.descriptor.priority,
    );
    if (ambiguous.length > 1) {
      return CodecAmbiguous(
        codecIds: ambiguous.map((candidate) => candidate.descriptor.codecId),
      );
    }
    return CodecSuccess(value: best, fidelity: DocumentFidelity.exact);
  }

  CodecOutcome<InteroperableDocument<Object>> decode(
    DocumentPayload payload, {
    FormalSystemKey? expectedSystem,
    DocumentFormatId? expectedFormat,
  }) {
    final detected = detect(
      payload,
      expectedSystem: expectedSystem,
      expectedFormat: expectedFormat,
    );
    if (detected is! CodecSuccess<DetectedDocument>) {
      return _copyFailure(detected);
    }
    try {
      final result = detected.value.codec.decode(payload);
      if (result is CodecSuccess<InteroperableDocument<Object>>) {
        final descriptor = detected.value.descriptor;
        if (result.value.systemKey != descriptor.systemKey ||
            !descriptor.schemas.contains(result.value.schema.version.value) ||
            result.value.schema.id !=
                detected.value.codec.descriptor.systemKeySchema(
                  formalSystems,
                )) {
          return _internalFailure(
            stage: CodecInternalFailureStage.decode,
            code: 'decoded-identity-mismatch',
            arguments: {
              'codec': StructuredMessageArgument.identifier(
                descriptor.codecId.value,
                role: 'codec',
              ),
            },
          );
        }
      }
      return result;
    } catch (error) {
      return _internalFailure(
        stage: CodecInternalFailureStage.decode,
        code: 'decode-failed',
        arguments: {
          'codec': StructuredMessageArgument.identifier(
            detected.value.descriptor.codecId.value,
            role: 'codec',
          ),
        },
        cause: error,
      );
    }
  }

  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    required DocumentFormatId format,
    String? filename,
  }) {
    final registeredSchema = formalSystems
        .descriptorFor(document.systemKey)
        ?.schema;
    if (registeredSchema == null || document.schema.id != registeredSchema.id) {
      return _unsupported(
        reason: CodecUnsupportedReason.schema,
        code: 'schema-identity-unregistered',
        arguments: {
          'system': StructuredMessageArgument.identifier(
            document.systemKey.value,
            role: 'formal-system',
          ),
          'schema': StructuredMessageArgument.identifier(
            document.schema.id.value,
            role: 'schema',
          ),
        },
      );
    }
    final routes = _registrations.where((registration) {
      final descriptor = registration.codec.descriptor;
      return descriptor.systemKey == document.systemKey &&
          descriptor.formatId == format &&
          descriptor.directions.contains(
            DocumentFormatDirection.exportDocument,
          );
    }).toList();
    if (routes.isEmpty) {
      return _unsupported(
        reason: CodecUnsupportedReason.format,
        code: 'export-route-unavailable',
        arguments: {
          'system': StructuredMessageArgument.identifier(
            document.systemKey.value,
            role: 'formal-system',
          ),
          'format': StructuredMessageArgument.identifier(
            format.value,
            role: 'document-format',
          ),
          'schema-version': StructuredMessageArgument.integer(
            document.schema.version.value,
            role: 'schema-version',
          ),
        },
      );
    }
    final matches = routes
        .where(
          (registration) => registration.codec.descriptor.schemas.contains(
            document.schema.version.value,
          ),
        )
        .toList();
    if (matches.isEmpty) {
      return _unsupported(
        reason: CodecUnsupportedReason.schema,
        code: 'export-schema-unavailable',
        arguments: {
          'schema-version': StructuredMessageArgument.integer(
            document.schema.version.value,
            role: 'schema-version',
          ),
        },
      );
    }
    matches.sort(
      (left, right) => right.codec.descriptor.priority.compareTo(
        left.codec.descriptor.priority,
      ),
    );
    if (matches.length > 1 &&
        matches[0].codec.descriptor.priority ==
            matches[1].codec.descriptor.priority) {
      return CodecAmbiguous(
        codecIds: matches
            .where(
              (match) =>
                  match.codec.descriptor.priority ==
                  matches.first.codec.descriptor.priority,
            )
            .map((match) => match.codec.descriptor.codecId),
      );
    }
    try {
      final registration = matches.first;
      final result = registration.codec.encode(document, filename: filename);
      if (result is CodecSuccess<EncodedDocument>) {
        final format = formalSystems.formatFor(
          registration.codec.descriptor.formatId,
        )!;
        final extension = result.value.filename.contains('.')
            ? normalizeDocumentExtension(result.value.filename.split('.').last)
            : '';
        final mimeMismatch =
            format.mediaType != null &&
            result.value.mimeType.toLowerCase() !=
                format.mediaType!.toLowerCase();
        final schemaMismatch =
            result.value.schema.id != registeredSchema.id ||
            !registration.codec.descriptor.schemas.contains(
              result.value.schema.version.value,
            );
        if (mimeMismatch ||
            schemaMismatch ||
            !format.normalizedExtensions.contains(extension)) {
          return _internalFailure(
            stage: CodecInternalFailureStage.encode,
            code: 'encoded-metadata-mismatch',
            arguments: {
              'codec': StructuredMessageArgument.identifier(
                registration.codec.descriptor.codecId.value,
                role: 'codec',
              ),
            },
          );
        }
      }
      return result;
    } catch (error) {
      return _internalFailure(
        stage: CodecInternalFailureStage.encode,
        code: 'encode-failed',
        arguments: {
          'codec': StructuredMessageArgument.identifier(
            matches.first.codec.descriptor.codecId.value,
            role: 'codec',
          ),
        },
        cause: error,
      );
    }
  }
}

extension on CodecDescriptor {
  DocumentSchemaId systemKeySchema(FormalSystemRegistry registry) =>
      registry.descriptorFor(systemKey)!.schema.id;
}

final class _CodecRegistration {
  const _CodecRegistration(this.owner, this.codec);

  final FormalSystemDescriptor owner;
  final DocumentCodecCapability<Object> codec;
}

List<StructuredMessage> _validate(
  FormalSystemRegistry formalSystems,
  List<_CodecRegistration> registrations,
) {
  final issues = <StructuredMessage>[];
  final ids = <DocumentCodecId, String>{};
  final namespaces = <CapabilityNamespaceId, String>{};
  final signatures = <String, String>{};
  for (final registration in registrations) {
    final owner = registration.owner;
    final descriptor = registration.codec.descriptor;
    final codecName = descriptor.codecId.value;
    if (descriptor.systemKey != owner.key) {
      issues.add(
        _validationMessage('system-owner-mismatch', {
          'codec': StructuredMessageArgument.identifier(
            codecName,
            role: 'codec',
          ),
          'declared-system': StructuredMessageArgument.identifier(
            descriptor.systemKey.value,
            role: 'formal-system',
          ),
          'owner-system': StructuredMessageArgument.identifier(
            owner.key.value,
            role: 'formal-system',
          ),
        }),
      );
    }
    if (formalSystems.formatFor(descriptor.formatId) == null) {
      issues.add(
        _validationMessage('unknown-format', {
          'codec': StructuredMessageArgument.identifier(
            codecName,
            role: 'codec',
          ),
          'format': StructuredMessageArgument.identifier(
            descriptor.formatId.value,
            role: 'document-format',
          ),
        }),
      );
    }
    final support = owner.formatSupport(descriptor.formatId);
    for (final direction in descriptor.directions) {
      if (support?.supports(direction) != true) {
        issues.add(
          _validationMessage('unsupported-direction', {
            'codec': StructuredMessageArgument.identifier(
              codecName,
              role: 'codec',
            ),
            'direction': StructuredMessageArgument.outcome(
              direction.name,
              role: 'document-direction',
            ),
            'system': StructuredMessageArgument.identifier(
              owner.key.value,
              role: 'formal-system',
            ),
          }),
        );
      }
    }
    if (descriptor.schemas.minimum <= 0 ||
        descriptor.schemas.maximum < descriptor.schemas.minimum) {
      issues.add(
        _validationMessage('invalid-schema-range', {
          'codec': StructuredMessageArgument.identifier(
            codecName,
            role: 'codec',
          ),
          'minimum': StructuredMessageArgument.integer(
            descriptor.schemas.minimum,
            role: 'schema-version',
          ),
          'maximum': StructuredMessageArgument.integer(
            descriptor.schemas.maximum,
            role: 'schema-version',
          ),
        }),
      );
    }
    if (descriptor.compatibilityOwner.trim().isEmpty) {
      issues.add(
        _validationMessage('empty-compatibility-owner', {
          'codec': StructuredMessageArgument.identifier(
            codecName,
            role: 'codec',
          ),
        }),
      );
    }
    if (descriptor.canonicalFixtures.isEmpty) {
      issues.add(
        _validationMessage('missing-canonical-fixtures', {
          'codec': StructuredMessageArgument.identifier(
            codecName,
            role: 'codec',
          ),
        }),
      );
    }
    final priorId = ids[descriptor.codecId];
    if (priorId != null) {
      issues.add(
        _validationMessage('duplicate-codec-id', {
          'codec': StructuredMessageArgument.identifier(
            codecName,
            role: 'codec',
          ),
          'prior-owner': StructuredMessageArgument.identifier(
            priorId,
            role: 'formal-system',
          ),
        }),
      );
    }
    ids[descriptor.codecId] = owner.key.value;
    final priorNamespace = namespaces[descriptor.namespace];
    if (priorNamespace != null) {
      issues.add(
        _validationMessage('duplicate-codec-namespace', {
          'namespace': StructuredMessageArgument.identifier(
            descriptor.namespace.value,
            role: 'codec-namespace',
          ),
          'prior-owner': StructuredMessageArgument.identifier(
            priorNamespace,
            role: 'formal-system',
          ),
        }),
      );
    }
    namespaces[descriptor.namespace] = owner.key.value;
    final directions = descriptor.directions.map((value) => value.name).toList()
      ..sort();
    final signature =
        '${owner.key.value}|${descriptor.formatId.value}|'
        '${descriptor.schemas.minimum}-${descriptor.schemas.maximum}|'
        '${directions.join(',')}|${descriptor.priority}';
    final priorSignature = signatures[signature];
    if (priorSignature != null) {
      issues.add(
        _validationMessage('duplicate-routing-signature', {
          'signature': StructuredMessageArgument.identifier(
            signature,
            role: 'routing-signature',
          ),
          'prior-codec': StructuredMessageArgument.identifier(
            priorSignature,
            role: 'codec',
          ),
        }),
      );
    }
    signatures[signature] = codecName;
  }
  return issues..sort((left, right) {
    final byCode = left.stableCode.compareTo(right.stableCode);
    if (byCode != 0) return byCode;
    return left.toJson().toString().compareTo(right.toJson().toString());
  });
}

CodecOutcome<T> _copyFailure<T>(CodecOutcome<Object?> outcome) {
  return switch (outcome) {
    CodecUnsupported(
      :final reason,
      :final message,
      :final roadmapIssue,
      :final structuredMessage,
    ) =>
      CodecUnsupported(
        reason: reason,
        message: message,
        roadmapIssue: roadmapIssue,
        structuredMessage: structuredMessage,
      ),
    CodecAmbiguous(:final codecIds) => CodecAmbiguous(codecIds: codecIds),
    CodecMalformed(
      :final reason,
      :final message,
      :final location,
      :final cause,
      :final structuredMessage,
    ) =>
      CodecMalformed(
        reason: reason,
        message: message,
        location: location,
        cause: cause,
        structuredMessage: structuredMessage,
      ),
    CodecResourceLimit(:final limit, :final maximum, :final actual) =>
      CodecResourceLimit(limit: limit, maximum: maximum, actual: actual),
    CodecInternalFailure(
      :final stage,
      :final message,
      :final cause,
      :final structuredMessage,
    ) =>
      CodecInternalFailure(
        stage: stage,
        message: message,
        cause: cause,
        structuredMessage: structuredMessage,
      ),
    CodecSuccess() => throw StateError('Cannot copy a successful outcome'),
  };
}

CodecUnsupported<T> _unsupported<T>({
  required CodecUnsupportedReason reason,
  required String code,
  Map<String, StructuredMessageArgument> arguments = const {},
}) {
  final structuredMessage = _interopMessage(code, arguments);
  return CodecUnsupported(
    reason: reason,
    message: structuredMessage.stableCode,
    structuredMessage: structuredMessage,
  );
}

CodecInternalFailure<T> _internalFailure<T>({
  required CodecInternalFailureStage stage,
  required String code,
  Map<String, StructuredMessageArgument> arguments = const {},
  Object? cause,
}) {
  final structuredMessage = _interopMessage(code, arguments);
  return CodecInternalFailure(
    stage: stage,
    message: structuredMessage.stableCode,
    cause: cause,
    structuredMessage: structuredMessage,
  );
}

StructuredMessage _validationMessage(
  String code,
  Map<String, StructuredMessageArgument> arguments,
) => _interopMessage(code, arguments, namespace: 'interop.registry-validation');

StructuredMessage _interopMessage(
  String code,
  Map<String, StructuredMessageArgument> arguments, {
  String namespace = 'interop.registry',
}) => StructuredMessage(
  namespace: namespace,
  code: code,
  category: StructuredMessageCategory.interoperability,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);
