import 'dart:convert';
import 'dart:typed_data';

import '../../core/entities/grammar_entity.dart';
import '../../core/annotations/document_annotation_collection.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/messages/structured_message.dart';
import '../../core/result.dart';
import '../codecs/default_document_interoperability_registry.dart';
import '../../presentation/widgets/export/svg_exporter.dart';

/// Shared platform-independent payload helpers for file operations.
mixin FileOperationsPayloadMixin {
  static final _documentCodecs =
      DefaultDocumentInteroperabilityRegistry.create();

  SvgExportOptions _svgOptionsWithLabels({
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) {
    final base = options ?? const SvgExportOptions();
    return SvgExportOptions(
      includeTitle: base.includeTitle,
      includeLegend: base.includeLegend,
      scale: base.scale,
      colorScheme: base.colorScheme,
      emptyAutomatonLabel: emptyAutomatonLabel ?? base.emptyAutomatonLabel,
      tmLegendLabel: tmLegendLabel ?? base.tmLegendLabel,
      includeAnnotations: includeAnnotations || base.includeAnnotations,
      annotations: annotations ?? base.annotations,
    );
  }

  /// Creates the JFLAP XML payload without writing it to disk.
  String serializeAutomatonToJFLAPString(FSA automaton) {
    return _encodeDocument(
      _interoperable(automaton, DefaultFormalSystemIds.fsa),
      DefaultFormalSystemIds.jflapXmlFormat,
    );
  }

  /// Creates the JSON payload without writing it to disk.
  String serializeAutomatonToJsonString(FSA automaton) {
    return _encodeDocument(
      _interoperable(automaton, DefaultFormalSystemIds.fsa),
      DefaultFormalSystemIds.turingLabJsonFormat,
    );
  }

  /// Creates the grammar JFLAP payload without writing it to disk.
  String serializeGrammarToJFLAPString(Grammar grammar) {
    return _encodeDocument(
      _interoperable(grammar, DefaultFormalSystemIds.grammar),
      DefaultFormalSystemIds.jflapXmlFormat,
    );
  }

  /// Creates an FSA SVG payload from the current model.
  String exportFsaToSvgString(
    FSA automaton, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) {
    return SvgExporter.exportFsaToSvg(
      automaton,
      options: _svgOptionsWithLabels(
        options: options,
        emptyAutomatonLabel: emptyAutomatonLabel,
        tmLegendLabel: tmLegendLabel,
        includeAnnotations: includeAnnotations,
        annotations: annotations,
      ),
    );
  }

  /// Creates the grammar SVG payload without writing it to disk.
  String exportGrammarToSvgString(
    GrammarEntity grammar, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) {
    return SvgExporter.exportGrammarToSvg(
      grammar,
      options: _svgOptionsWithLabels(
        options: options,
        emptyAutomatonLabel: emptyAutomatonLabel,
        tmLegendLabel: tmLegendLabel,
        includeAnnotations: includeAnnotations,
        annotations: annotations,
      ),
    );
  }

  /// Creates a grammar SVG payload from the current model.
  String exportGrammarModelToSvgString(
    Grammar grammar, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) {
    return exportGrammarToSvgString(
      _grammarToGrammarEntity(grammar),
      options: options,
      emptyAutomatonLabel: emptyAutomatonLabel,
      tmLegendLabel: tmLegendLabel,
      includeAnnotations: includeAnnotations,
      annotations: annotations,
    );
  }

  /// Creates a PDA SVG payload from the current model.
  String exportPdaToSvgString(
    PDA pda, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) {
    return SvgExporter.exportPdaToSvg(
      pda,
      options: _svgOptionsWithLabels(
        options: options,
        emptyAutomatonLabel: emptyAutomatonLabel,
        tmLegendLabel: tmLegendLabel,
        includeAnnotations: includeAnnotations,
        annotations: annotations,
      ),
    );
  }

  /// Creates the Turing machine SVG payload without writing it to disk.
  String exportTuringMachineToSvgString(
    TuringMachineEntity tm, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) {
    return SvgExporter.exportTuringMachineToSvg(
      tm,
      options: _svgOptionsWithLabels(
        options: options,
        emptyAutomatonLabel: emptyAutomatonLabel,
        tmLegendLabel: tmLegendLabel,
        includeAnnotations: includeAnnotations,
        annotations: annotations,
      ),
    );
  }

  /// Loads automaton from in-memory bytes (JFLAP XML format).
  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes) async {
    return _decodeModel<FSA>(
      bytes,
      DefaultFormalSystemIds.fsa,
      DefaultFormalSystemIds.jflapXmlFormat,
    );
  }

  /// Loads automaton from in-memory bytes (JSON format).
  Future<Result<FSA>> loadAutomatonFromJsonBytes(Uint8List bytes) async {
    return _decodeModel<FSA>(
      bytes,
      DefaultFormalSystemIds.fsa,
      DefaultFormalSystemIds.turingLabJsonFormat,
    );
  }

  /// Loads grammar from in-memory bytes (JFLAP XML format).
  Future<Result<Grammar>> loadGrammarFromBytes(Uint8List bytes) async {
    return _decodeModel<Grammar>(
      bytes,
      DefaultFormalSystemIds.grammar,
      DefaultFormalSystemIds.jflapXmlFormat,
    );
  }

  InteroperableDocument<Object> _interoperable(
    Object document,
    FormalSystemKey key,
  ) {
    final descriptor = _documentCodecs.formalSystems.descriptorFor(key)!;
    return InteroperableDocument<Object>(
      document: document,
      systemKey: key,
      schema: descriptor.schema,
    );
  }

  String _encodeDocument(
    InteroperableDocument<Object> document,
    DocumentFormatId format,
  ) {
    final outcome = _documentCodecs.encode(document, format: format);
    if (outcome is! CodecSuccess<EncodedDocument>) {
      throw CodecOperationException(
        compatibilityCode: _outcomeCode(outcome),
        structuredMessage: _outcomeMessage(outcome),
      );
    }
    if (outcome.fidelity == DocumentFidelity.lossy) {
      throw CodecOperationException(
        compatibilityCode: 'codec.lossy-export-requires-confirmation',
        structuredMessage: fileOperationMessage(
          'lossy-export-requires-confirmation',
        ),
      );
    }
    return utf8.decode(outcome.value.bytes);
  }

  Future<Result<T>> _decodeModel<T extends Object>(
    Uint8List bytes,
    FormalSystemKey system,
    DocumentFormatId format,
  ) async {
    final outcome = _documentCodecs.decode(
      DocumentPayload(bytes: bytes),
      expectedSystem: system,
      expectedFormat: format,
    );
    if (outcome is! CodecSuccess<InteroperableDocument<Object>>) {
      return Failure(
        _outcomeCode(outcome),
        structuredMessage: _decodeOutcomeMessage(outcome),
      );
    }
    if (outcome.fidelity == DocumentFidelity.lossy ||
        !outcome.value.extensions.isEmpty) {
      return Failure(
        'codec.requires-interoperability-review',
        structuredMessage: fileOperationMessage(
          'interoperability-review-required',
        ),
      );
    }
    final model = outcome.value.document;
    if (model is! T) {
      return Failure(
        'codec.invalid-model-type',
        structuredMessage: fileOperationMessage('invalid-model-type'),
      );
    }
    return Success(model);
  }

  String _outcomeCode(CodecOutcome<Object?> outcome) => switch (outcome) {
    CodecUnsupported(:final reason) => 'codec.unsupported.${reason.name}',
    CodecAmbiguous() => 'codec.ambiguous',
    CodecMalformed(:final reason) => 'codec.malformed.${reason.name}',
    CodecResourceLimit(:final limit) => 'codec.resource-limit.${limit.name}',
    CodecInternalFailure(:final stage) => 'codec.internal.${stage.name}',
    CodecSuccess() => 'codec.success',
  };

  StructuredMessage _outcomeMessage(CodecOutcome<Object?> outcome) =>
      switch (outcome) {
        // File operations expose their stable service-level contract even
        // when a codec also supplies a more specific diagnostic. The codec
        // payload remains available on the codec outcome itself.
        CodecUnsupported(:final reason) => fileOperationMessage(
          'codec-unsupported',
          arguments: {
            'reason': StructuredMessageArgument.outcome(
              reason.name,
              role: 'codec-unsupported-reason',
            ),
          },
        ),
        CodecAmbiguous(:final codecIds) => fileOperationMessage(
          'codec-ambiguous',
          arguments: {
            'count': StructuredMessageArgument.count(
              codecIds.length,
              role: 'codec-count',
            ),
          },
        ),
        CodecMalformed(:final reason) => fileOperationMessage(
          'codec-malformed',
          arguments: {
            'reason': StructuredMessageArgument.outcome(
              reason.name,
              role: 'codec-malformed-reason',
            ),
          },
        ),
        CodecResourceLimit(:final limit, :final maximum, :final actual) =>
          fileOperationMessage(
            'codec-resource-limit',
            arguments: {
              'limit': StructuredMessageArgument.outcome(
                limit.name,
                role: 'codec-resource-limit',
              ),
              'maximum': StructuredMessageArgument.bound(maximum),
              'actual': StructuredMessageArgument.count(actual),
            },
          ),
        CodecInternalFailure(:final stage) => fileOperationMessage(
          'codec-internal-failure',
          arguments: {
            'stage': StructuredMessageArgument.outcome(
              stage.name,
              role: 'codec-stage',
            ),
          },
        ),
        CodecSuccess() => throw StateError('codec.success'),
      };

  StructuredMessage _decodeOutcomeMessage(CodecOutcome<Object?> outcome) {
    final codecMessage = switch (outcome) {
      CodecUnsupported(:final structuredMessage) => structuredMessage,
      CodecMalformed(:final structuredMessage) => structuredMessage,
      CodecInternalFailure(:final structuredMessage) => structuredMessage,
      _ => null,
    };
    return codecMessage ?? _outcomeMessage(outcome);
  }

  StructuredMessage fileOperationMessage(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'service.file-operations',
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  Failure<T> fileOperationFailure<T>(
    String code, {
    String? operation,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) {
    final messageArguments = <String, StructuredMessageArgument>{
      if (operation != null)
        'operation': StructuredMessageArgument.outcome(
          operation,
          role: 'file-operation',
        ),
      ...arguments,
    };
    final structuredMessage = fileOperationMessage(
      code,
      arguments: messageArguments,
    );
    return Failure<T>(
      structuredMessage.stableCode,
      structuredMessage: structuredMessage,
    );
  }

  GrammarEntity _grammarToGrammarEntity(Grammar grammar) {
    return GrammarEntity(
      id: grammar.id,
      name: grammar.name,
      terminals: grammar.terminals,
      nonTerminals: grammar.nonterminals,
      startSymbol: grammar.startSymbol,
      productions: grammar.productions
          .map(
            (production) => ProductionEntity(
              id: production.id,
              leftSide: List<String>.from(production.leftSide),
              rightSide: List<String>.from(production.rightSide),
            ),
          )
          .toList(),
    );
  }
}
