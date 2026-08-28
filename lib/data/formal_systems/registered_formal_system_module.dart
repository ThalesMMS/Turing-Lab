import 'dart:async';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/asset_example.dart';

/// Adapts a typed module to the application-wide heterogeneous registry.
final class RegisteredFormalSystemModule<TDocument extends Object>
    implements FormalSystemModule<Object> {
  RegisteredFormalSystemModule({
    required FormalSystemModule<TDocument> base,
    Iterable<DocumentCodecCapability<Object>>? codecs,
    ExampleCatalogCapability<TDocument>? examples,
  })  : descriptor = base.descriptor,
        codecs = List<DocumentCodecCapability<Object>>.unmodifiable(
          codecs ??
              base.codecs.map(
                (codec) => _ErasedDocumentCodecCapability<TDocument>(codec),
              ),
        ),
        conversions = List<ConversionCapability<Object, Object>>.unmodifiable(
          base.conversions.map(
            (conversion) =>
                _ErasedConversionCapability<TDocument, Object>(conversion),
          ),
        ),
        examples = switch (examples ?? base.examples) {
          final capability? => _ErasedExamples<TDocument>(capability),
          null => null,
        },
        session = base.session == null
            ? null
            : _ErasedSessionCapability<TDocument>(base.session!);

  @override
  final FormalSystemDescriptor descriptor;
  @override
  final List<DocumentCodecCapability<Object>> codecs;
  @override
  final List<ConversionCapability<Object, Object>> conversions;
  @override
  final ExampleCatalogCapability<Object>? examples;
  @override
  final SessionCapability<Object>? session;
}

final class _ErasedDocumentCodecCapability<TDocument extends Object>
    implements DocumentCodecCapability<Object> {
  const _ErasedDocumentCodecCapability(this._delegate);

  final DocumentCodecCapability<TDocument> _delegate;

  @override
  CodecDescriptor get descriptor => _delegate.descriptor;

  @override
  CodecSniffResult sniff(DocumentPayload payload) => _delegate.sniff(payload);

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) =>
      _mapCodecOutcome(
        _delegate.decode(payload),
        (value) => InteroperableDocument<Object>(
          document: value.document,
          systemKey: value.systemKey,
          schema: value.schema,
          sourceMetadata: value.sourceMetadata,
          extensions: value.extensions,
        ),
      );

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    final value = document.document;
    if (value is! TDocument) {
      return CodecUnsupported<EncodedDocument>(
        reason: CodecUnsupportedReason.document,
        message:
            '${descriptor.codecId.value} cannot encode ${value.runtimeType}.',
      );
    }
    return _delegate.encode(
      InteroperableDocument<TDocument>(
        document: value,
        systemKey: document.systemKey,
        schema: document.schema,
        sourceMetadata: document.sourceMetadata,
        extensions: document.extensions,
      ),
      filename: filename,
    );
  }
}

final class _ErasedConversionCapability<TSource extends Object,
    TTarget extends Object> implements ConversionCapability<Object, Object> {
  const _ErasedConversionCapability(this._delegate);

  final ConversionCapability<TSource, TTarget> _delegate;

  @override
  ConversionEdge get edge => _delegate.edge;

  @override
  FutureOr<Object> convert(Object source) {
    if (source is! TSource) {
      throw ArgumentError.value(
        source,
        'source',
        '${edge.id.value} expects $TSource.',
      );
    }
    return _delegate.convert(source);
  }
}

final class _ErasedSessionCapability<TDocument extends Object>
    implements SessionCapability<Object> {
  const _ErasedSessionCapability(this._delegate);

  final SessionCapability<TDocument> _delegate;

  @override
  CapabilityNamespaceId get namespace => _delegate.namespace;

  @override
  Object decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) =>
      _delegate.decodeSession(encoded, schema: schema);

  @override
  Map<String, Object?> encodeSession(Object document) {
    if (document is! TDocument) {
      throw FormatException(
        '${namespace.value} cannot encode ${document.runtimeType}.',
      );
    }
    return _delegate.encodeSession(document);
  }
}

final class _ErasedExamples<TDocument extends Object>
    implements ExampleCatalogCapability<Object> {
  const _ErasedExamples(this._delegate);

  final ExampleCatalogCapability<TDocument> _delegate;

  @override
  CapabilityNamespaceId get namespace => _delegate.namespace;

  @override
  Future<List<AssetExample<Object>>> loadExamples() async =>
      (await _delegate.loadExamples()).cast<AssetExample<Object>>();
}

CodecOutcome<TMapped> _mapCodecOutcome<TValue, TMapped>(
  CodecOutcome<TValue> outcome,
  TMapped Function(TValue) map,
) =>
    switch (outcome) {
      CodecSuccess<TValue>() => CodecSuccess<TMapped>(
          value: map(outcome.value),
          fidelity: outcome.fidelity,
          diagnostics: outcome.diagnostics,
        ),
      CodecUnsupported<TValue>() => CodecUnsupported<TMapped>(
          reason: outcome.reason,
          message: outcome.message,
          roadmapIssue: outcome.roadmapIssue,
        ),
      CodecAmbiguous<TValue>() => CodecAmbiguous<TMapped>(
          codecIds: outcome.codecIds,
        ),
      CodecMalformed<TValue>() => CodecMalformed<TMapped>(
          reason: outcome.reason,
          message: outcome.message,
          location: outcome.location,
          cause: outcome.cause,
        ),
      CodecResourceLimit<TValue>() => CodecResourceLimit<TMapped>(
          limit: outcome.limit,
          maximum: outcome.maximum,
          actual: outcome.actual,
        ),
      CodecInternalFailure<TValue>() => CodecInternalFailure<TMapped>(
          stage: outcome.stage,
          message: outcome.message,
          cause: outcome.cause,
        ),
    };
