//
//  file_operations_service_web.dart
//  Turing Lab
//
//  Web-friendly implementation of the FileOperationsService that relies on
//  in-memory representations instead of direct filesystem access. Only
//  operations that can be executed without `dart:io` are supported; attempts to
//  interact with the local filesystem return explicit failures so the UI can
//  surface clear feedback to the user.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import '../../core/entities/grammar_entity.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/result.dart';
import '../../core/services/file_operations_gateway.dart';
import '../../presentation/widgets/export/svg_exporter.dart';
import 'file_operations_payload_mixin.dart';

/// Service for file operations tailored for web environments.
class FileOperationsService
    with FileOperationsPayloadMixin
    implements FileOperationsGateway {
  /// PNG rendering is not available in the web service implementation.
  @override
  Future<Result<Uint8List>> exportAutomatonToPngBytes(FSA automaton) async {
    return const Failure<Uint8List>('PNG export is not supported on web.');
  }

  /// Starts a PNG download from previously rendered bytes.
  @override
  Future<StringResult> writePngBytesToPath(
    Uint8List bytes,
    String filePath,
  ) {
    return _downloadBytes(filePath, 'image/png', bytes);
  }

  @override
  Future<StringResult> saveAutomatonToJFLAP(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final xml = serializeAutomatonToJFLAPString(automaton);
      return _downloadText(filePath, 'application/xml', xml);
    } catch (e) {
      return Failure('Failed to prepare automaton download: $e');
    }
  }

  @override
  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath) async {
    return const Failure(
      'Loading JFLAP files from a path is not supported on web.',
    );
  }

  @override
  Future<StringResult> saveAutomatonToJson(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final jsonString = serializeAutomatonToJsonString(automaton);
      return _downloadText(filePath, 'application/json', jsonString);
    } catch (e) {
      return Failure('Failed to prepare automaton JSON download: $e');
    }
  }

  @override
  Future<Result<FSA>> loadAutomatonFromJson(String filePath) async {
    return const Failure(
      'Loading automaton JSON files from a path is not supported on web.',
    );
  }

  @override
  Future<StringResult> saveGrammarToJFLAP(
    Grammar grammar,
    String filePath,
  ) async {
    try {
      final xml = serializeGrammarToJFLAPString(grammar);
      return _downloadText(filePath, 'application/xml', xml);
    } catch (e) {
      return Failure('Failed to prepare grammar download: $e');
    }
  }

  @override
  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath) async {
    return const Failure(
      'Loading grammars from a path is not supported on web.',
    );
  }

  Future<StringResult> exportAutomatonToPNG(
    FSA automaton,
    String filePath,
  ) async {
    return const Failure('PNG export is not supported on web.');
  }

  @override
  Future<StringResult> exportFsaToSVG(
    FSA automaton,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
  }) async {
    try {
      final svg = exportFsaToSvgString(
        automaton,
        options: options,
        emptyAutomatonLabel: emptyAutomatonLabel,
        tmLegendLabel: tmLegendLabel,
      );
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export automaton: $e');
    }
  }

  Future<StringResult> exportGrammarToSVG(
    GrammarEntity grammar,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final svg = exportGrammarToSvgString(grammar, options: options);
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export grammar: $e');
    }
  }

  @override
  Future<StringResult> exportGrammarModelToSVG(
    Grammar grammar,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
  }) async {
    try {
      final svg = exportGrammarModelToSvgString(
        grammar,
        options: options,
        emptyAutomatonLabel: emptyAutomatonLabel,
        tmLegendLabel: tmLegendLabel,
      );
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export grammar: $e');
    }
  }

  @override
  Future<StringResult> exportPdaToSVG(
    PDA pda,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
  }) async {
    try {
      final svg = exportPdaToSvgString(
        pda,
        options: options,
        emptyAutomatonLabel: emptyAutomatonLabel,
        tmLegendLabel: tmLegendLabel,
      );
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export PDA: $e');
    }
  }

  @override
  Future<StringResult> exportTuringMachineToSVG(
    TuringMachineEntity machine,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
  }) async {
    try {
      final svg = exportTuringMachineToSvgString(
        machine,
        options: options,
        emptyAutomatonLabel: emptyAutomatonLabel,
        tmLegendLabel: tmLegendLabel,
      );
      return _downloadText(filePath, 'image/svg+xml', svg);
    } catch (e) {
      return Failure('Failed to export Turing machine: $e');
    }
  }

  Future<StringResult> getDocumentsDirectory() async {
    return const Failure('Documents directory is not available on web.');
  }

  Future<StringResult> createUniqueFile(
    String baseName,
    String extension,
  ) async {
    return const Failure('File creation is not supported on web.');
  }

  Future<ListResult<String>> listFiles(String extension) async {
    return const Failure('Listing files is not supported on web.');
  }

  Future<BoolResult> deleteFile(String filePath) async {
    return const Failure('Deleting files is not supported on web.');
  }

  Future<StringResult> _downloadText(
    String fileName,
    String mimeType,
    String contents,
  ) async {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    return _downloadBytes(fileName, mimeType, bytes);
  }

  Future<StringResult> _downloadBytes(
    String fileName,
    String mimeType,
    Uint8List bytes,
  ) async {
    try {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      return Success(fileName);
    } catch (e) {
      return Failure('Failed to start download: $e');
    }
  }
}
