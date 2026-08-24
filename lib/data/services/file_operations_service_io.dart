//
//  file_operations_service_io.dart
//  Turing Lab
//
//  Centralizes reading and writing automata and grammars in JFLAP formats, and generates PNG and SVG exports by drawing the canvas with consistent visual settings.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/pda.dart';
import '../../core/parsers/grammar_xml_codec.dart';
import '../../core/parsers/jflap_xml_codec.dart';
import '../../core/result.dart';
import '../../core/services/file_operations_gateway.dart';
import '../../presentation/widgets/export/svg_exporter.dart';
import 'file_operations_payload_mixin.dart';

/// Service for file operations including JFLAP format support
class FileOperationsService
    with FileOperationsPayloadMixin
    implements FileOperationsGateway {
  static const _writeAccessRetryMessage =
      'Turing Lab could not write to the selected location. The file may be outside the app sandbox or no longer writable. Choose a destination again from the system save dialog and try again.';
  static const _readAccessRetryMessage =
      'Turing Lab could not read the selected file. The file may be outside the app sandbox or no longer readable. Pick the file again from the system dialog and try again.';
  static const _missingSaveLocationMessage =
      'The selected save location is no longer available. Choose a different destination and try again.';
  static const _missingReadLocationMessage =
      'The selected file is no longer available. Pick the file again and try again.';

  /// Renders the PNG payload without writing it to disk.
  @override
  Future<Result<Uint8List>> exportAutomatonToPngBytes(FSA automaton) async {
    ui.Picture? picture;
    ui.Image? image;
    try {
      const size = Size(_kCanvasWidth, _kCanvasHeight);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _kBackgroundColor,
      );

      final drawingData = _prepareDrawingData(automaton);
      final painter = _AutomatonPainter(drawingData);
      painter.paint(canvas, size);

      picture = recorder.endRecording();
      image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return const Failure('Failed to encode PNG data');
      }

      return Success(byteData.buffer.asUint8List());
    } catch (e) {
      return Failure('Failed to export automaton to PNG: $e');
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }

  static String describeFileAccessFailure(
    Object error, {
    required bool isWrite,
  }) {
    if (error is! FileSystemException) {
      return error.toString();
    }

    final errorCode = error.osError?.errorCode;
    final normalized = [
      error.message,
      error.osError?.message,
      error.path,
    ].whereType<String>().join(' ').toLowerCase();

    final isPermissionDenied = errorCode == 1 ||
        errorCode == 13 ||
        normalized.contains('operation not permitted') ||
        normalized.contains('permission denied') ||
        normalized.contains('access is denied') ||
        normalized.contains('not permitted');
    if (isPermissionDenied) {
      return isWrite ? _writeAccessRetryMessage : _readAccessRetryMessage;
    }

    final isMissingPath = errorCode == 2 ||
        normalized.contains('no such file') ||
        normalized.contains('cannot find the path') ||
        normalized.contains('does not exist');
    if (isMissingPath) {
      return isWrite
          ? _missingSaveLocationMessage
          : _missingReadLocationMessage;
    }

    final osMessage = error.osError?.message.trim();
    if (osMessage != null && osMessage.isNotEmpty) {
      return osMessage;
    }

    return error.message;
  }

  /// Saves automaton to JFLAP XML format (.jff)
  @override
  Future<StringResult> saveAutomatonToJFLAP(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(serializeAutomatonToJFLAPString(automaton));
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to save automaton to JFLAP format: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to save automaton to JFLAP format: $e');
    }
  }

  /// Loads automaton from JFLAP XML format (.jff)
  @override
  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = await file.readAsString();
      return const JflapXmlCodec().decodeFsaXml(xmlString);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to load automaton from JFLAP format: ${describeFileAccessFailure(e, isWrite: false)}',
      );
    } catch (e) {
      return Failure('Failed to load automaton from JFLAP format: $e');
    }
  }

  /// Saves automaton to JSON format.
  @override
  Future<StringResult> saveAutomatonToJson(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(serializeAutomatonToJsonString(automaton));
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to save automaton to JSON format: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to save automaton to JSON format: $e');
    }
  }

  /// Loads automaton from JSON format.
  @override
  Future<Result<FSA>> loadAutomatonFromJson(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const Failure('Invalid automaton JSON format');
      }
      return Success(FSA.fromJson(decoded));
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to load automaton from JSON format: ${describeFileAccessFailure(e, isWrite: false)}',
      );
    } catch (e) {
      return Failure('Failed to load automaton from JSON format: $e');
    }
  }

  /// Saves grammar to JFLAP XML format (.cfg)
  @override
  Future<StringResult> saveGrammarToJFLAP(
    Grammar grammar,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(serializeGrammarToJFLAPString(grammar));
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to save grammar to JFLAP format: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to save grammar to JFLAP format: $e');
    }
  }

  /// Loads grammar from JFLAP XML format (.cfg)
  @override
  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = await file.readAsString();
      final result = const GrammarXmlCodec().decodeGrammarXml(xmlString);
      if (result.isFailure) {
        return Failure(
          'Failed to load grammar from JFLAP format: ${result.error}',
        );
      }
      return result;
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to load grammar from JFLAP format: ${describeFileAccessFailure(e, isWrite: false)}',
      );
    } catch (e) {
      return Failure('Failed to load grammar from JFLAP format: $e');
    }
  }

  /// Exports automaton to PNG image
  Future<StringResult> exportAutomatonToPNG(
    FSA automaton,
    String filePath,
  ) async {
    try {
      final pngBytesResult = await exportAutomatonToPngBytes(automaton);
      if (pngBytesResult.isFailure) {
        return Failure(pngBytesResult.error!);
      }
      return writePngBytesToPath(pngBytesResult.data!, filePath);
    } catch (e) {
      return Failure('Failed to export automaton to PNG: $e');
    }
  }

  /// Writes previously rendered PNG bytes to disk.
  @override
  Future<StringResult> writePngBytesToPath(
    Uint8List bytes,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export automaton to PNG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export automaton to PNG: $e');
    }
  }

  /// Exports the current FSA model to SVG format.
  @override
  Future<StringResult> exportFsaToSVG(
    FSA automaton,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportFsaToSvgString(automaton, options: options),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export automaton to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export automaton to SVG: $e');
    }
  }

  /// Exports grammar to SVG format (as state diagram)
  Future<StringResult> exportGrammarToSVG(
    GrammarEntity grammar,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportGrammarToSvgString(grammar, options: options),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export grammar to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export grammar to SVG: $e');
    }
  }

  /// Exports the current grammar model to SVG format.
  @override
  Future<StringResult> exportGrammarModelToSVG(
    Grammar grammar,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportGrammarModelToSvgString(grammar, options: options),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export grammar to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export grammar to SVG: $e');
    }
  }

  /// Exports the current PDA model to SVG format.
  @override
  Future<StringResult> exportPdaToSVG(
    PDA pda,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportPdaToSvgString(pda, options: options),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export PDA to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export PDA to SVG: $e');
    }
  }

  /// Exports Turing machine to SVG format
  @override
  Future<StringResult> exportTuringMachineToSVG(
    TuringMachineEntity tm,
    String filePath, {
    SvgExportOptions? options,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportTuringMachineToSvgString(tm, options: options),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return Failure(
        'Failed to export Turing machine to SVG: ${describeFileAccessFailure(e, isWrite: true)}',
      );
    } catch (e) {
      return Failure('Failed to export Turing machine to SVG: $e');
    }
  }

  /// Gets the default documents directory
  Future<StringResult> getDocumentsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return Success(directory.path);
    } catch (e) {
      return Failure('Failed to get documents directory: $e');
    }
  }

  /// Creates a new file with unique name
  Future<StringResult> createUniqueFile(
    String baseName,
    String extension,
  ) async {
    try {
      final dirResult = await getDocumentsDirectory();
      if (!dirResult.isSuccess) return Failure(dirResult.error!);

      final directory = Directory(dirResult.data!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${baseName}_$timestamp.$extension';
      final filePath = '${directory.path}/$fileName';

      return Success(filePath);
    } catch (e) {
      return Failure('Failed to create unique file: $e');
    }
  }

  /// Lists all files with specific extension in documents directory
  Future<ListResult<String>> listFiles(String extension) async {
    try {
      final dirResult = await getDocumentsDirectory();
      if (!dirResult.isSuccess) return Failure(dirResult.error!);

      final directory = Directory(dirResult.data!);
      final files = <String>[];
      await for (final entity in directory.list()) {
        if (entity.path.endsWith('.$extension')) {
          files.add(entity.path);
        }
      }

      return Success(files);
    } catch (e) {
      return Failure('Failed to list files: $e');
    }
  }

  /// Deletes a file
  Future<BoolResult> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return const Success(true);
      }
      return const Failure('File does not exist');
    } catch (e) {
      return Failure('Failed to delete file: $e');
    }
  }

  _AutomatonDrawingData _prepareDrawingData(FSA automaton) {
    final states = automaton.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final transitions = automaton.transitions
        .whereType<FSATransition>()
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final drawableStates = states
        .map(
          (state) => _DrawableState(
            center: Offset(state.position.x, state.position.y),
            label: state.label,
            fillColor:
                state.isAccepting ? _kAcceptingFillColor : _kDefaultFillColor,
            strokeColor: state.isInitial ? _kInitialStrokeColor : _kStrokeColor,
            strokeWidth:
                state.isInitial ? _kInitialStrokeWidth : _kDefaultStrokeWidth,
          ),
        )
        .toList();

    final drawableTransitions = transitions
        .map(
          (transition) => _DrawableTransition(
            from: Offset(
              transition.fromState.position.x,
              transition.fromState.position.y,
            ),
            to: Offset(
              transition.toState.position.x,
              transition.toState.position.y,
            ),
            label: transition.symbol,
          ),
        )
        .toList();

    return _AutomatonDrawingData(
      states: drawableStates,
      transitions: drawableTransitions,
    );
  }
}

const double _kCanvasWidth = 800;
const double _kCanvasHeight = 600;
const double _kStateRadius = 30;
const double _kDefaultStrokeWidth = 2;
const double _kInitialStrokeWidth = 3;

const Color _kBackgroundColor = Color(0xFFFFFFFF);
const Color _kDefaultFillColor = Color(0xFFFFFFFF);
const Color _kAcceptingFillColor = Color(0xFFADD8E6);
const Color _kStrokeColor = Color(0xFF000000);
const Color _kInitialStrokeColor = Color(0xFFFF0000);
const Color _kTextColor = Color(0xFF000000);

class _AutomatonDrawingData {
  const _AutomatonDrawingData({
    required this.states,
    required this.transitions,
  });

  final List<_DrawableState> states;
  final List<_DrawableTransition> transitions;
}

class _DrawableState {
  const _DrawableState({
    required this.center,
    required this.label,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final Offset center;
  final String label;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
}

class _DrawableTransition {
  const _DrawableTransition({
    required this.from,
    required this.to,
    required this.label,
  });

  final Offset from;
  final Offset to;
  final String label;
}

class _AutomatonPainter extends CustomPainter {
  _AutomatonPainter(this.data);

  final _AutomatonDrawingData data;

  @override
  void paint(Canvas canvas, Size size) {
    final transitionPaint = Paint()
      ..color = _kStrokeColor
      ..strokeWidth = _kDefaultStrokeWidth
      ..style = PaintingStyle.stroke;

    for (final transition in data.transitions) {
      canvas.drawLine(transition.from, transition.to, transitionPaint);

      if (transition.label.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: transition.label,
            style: const TextStyle(
              color: _kTextColor,
              fontSize: 12,
              fontFamily: 'Arial',
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        final midPoint = Offset(
          (transition.from.dx + transition.to.dx) / 2,
          (transition.from.dy + transition.to.dy) / 2,
        );

        final textOffset = Offset(
          midPoint.dx - (textPainter.width / 2),
          midPoint.dy - (textPainter.height / 2),
        );

        textPainter.paint(canvas, textOffset);
      }
    }

    for (final state in data.states) {
      final fillPaint = Paint()
        ..color = state.fillColor
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = state.strokeColor
        ..strokeWidth = state.strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(state.center, _kStateRadius, fillPaint);
      canvas.drawCircle(state.center, _kStateRadius, strokePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: state.label,
          style: const TextStyle(
            color: _kTextColor,
            fontSize: 14,
            fontFamily: 'Arial',
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        state.center.dx - (textPainter.width / 2),
        state.center.dy - (textPainter.height / 2),
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _AutomatonPainter oldDelegate) => false;
}
