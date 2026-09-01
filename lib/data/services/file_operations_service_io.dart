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
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/annotations/annotations.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/messages/structured_message.dart';
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
  @override
  Future<Result<Uint8List>> readBytes(String filePath) async {
    try {
      return Success(await File(filePath).readAsBytes());
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: false);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'read');
    }
  }

  @override
  Future<StringResult> writeBytes(
    Uint8List bytes,
    String filePath, {
    String mimeType = 'application/octet-stream',
  }) async {
    try {
      await File(filePath).writeAsBytes(bytes, flush: true);
      return Success(filePath);
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: true);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'write');
    }
  }

  /// Renders the PNG payload without writing it to disk.
  @override
  Future<Result<Uint8List>> exportAutomatonToPngBytes(
    FSA automaton, {
    String emptyStringSymbol = 'ε',
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
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

      final drawingData = _prepareDrawingData(automaton, emptyStringSymbol);
      final painter = _AutomatonPainter(drawingData);
      painter.paint(canvas, size);
      if (includeAnnotations && annotations != null) {
        _paintDocumentAnnotations(canvas, annotations, automaton, size);
      }

      picture = recorder.endRecording();
      image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return fileOperationFailure('operation-failed', operation: 'encodePng');
      }

      return Success(byteData.buffer.asUint8List());
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'exportPng');
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }

  void _paintDocumentAnnotations(
    Canvas canvas,
    DocumentAnnotationCollection annotations,
    FSA automaton,
    Size size,
  ) {
    final statePositions = {
      for (final state in automaton.states)
        state.id: Offset(state.position.x, state.position.y),
    };
    final transitionPositions = {
      for (final transition in automaton.transitions.whereType<FSATransition>())
        transition.id: Offset(
          (transition.fromState.position.x + transition.toState.position.x) / 2,
          (transition.fromState.position.y + transition.toState.position.y) / 2,
        ),
    };
    for (final annotation in annotations.annotations) {
      final attachment = annotation.attachment;
      final attachmentPosition = switch (attachment?.type) {
        AnnotationTargetType.state => statePositions[attachment!.targetId],
        AnnotationTargetType.transition =>
          transitionPositions[attachment!.targetId],
        _ => null,
      };
      final rawX = attachmentPosition?.dx ?? annotation.x;
      final rawY = attachmentPosition?.dy ?? annotation.y;
      final x = (rawX + (attachmentPosition == null ? 0 : attachment!.offsetX))
          .clamp(0, size.width - 1)
          .toDouble();
      final y = (rawY + (attachmentPosition == null ? 0 : attachment!.offsetY))
          .clamp(0, size.height - 1)
          .toDouble();
      final width = annotation.width.clamp(
        DocumentAnnotation.minimumWidth,
        math.max(DocumentAnnotation.minimumWidth, size.width - x),
      );
      final height =
          (annotation.collapsed
                  ? DocumentAnnotation.minimumHeight
                  : annotation.height)
              .clamp(
                DocumentAnnotation.minimumHeight,
                math.max(DocumentAnnotation.minimumHeight, size.height - y),
              );
      final fill = switch (annotation.styleRole) {
        AnnotationStyleRole.note => const Color(0xFFFFF3B0),
        AnnotationStyleRole.information => const Color(0xFFDBEAFE),
        AnnotationStyleRole.warning => const Color(0xFFFEE2E2),
        AnnotationStyleRole.question => const Color(0xFFEDE9FE),
        AnnotationStyleRole.todo => const Color(0xFFE5E7EB),
      };
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width.toDouble(), height.toDouble()),
        const Radius.circular(8),
      );
      canvas
        ..drawRRect(rect, Paint()..color = fill)
        ..drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFF424242)
            ..style = PaintingStyle.stroke,
        );
      if (!annotation.collapsed) {
        final painter = TextPainter(
          text: TextSpan(
            text: annotation.text,
            style: const TextStyle(color: Color(0xFF212121), fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 8,
          ellipsis: '…',
        )..layout(maxWidth: math.max(1, width.toDouble() - 20));
        painter.paint(canvas, Offset(x + 10, y + 10));
      }
    }
  }

  static StructuredMessage describeFileAccessFailure(
    Object error, {
    required bool isWrite,
  }) => StructuredMessage(
    namespace: 'service.file-operations',
    code: error is FileSystemException
        ? _fileAccessFailureCode(error)
        : 'access-failed',
    category: StructuredMessageCategory.interoperability,
    severity: StructuredMessageSeverity.error,
    arguments: {
      'operation': StructuredMessageArgument.outcome(
        isWrite ? 'write' : 'read',
        role: 'file-operation',
      ),
    },
  );

  Failure<T> _accessFailure<T>(
    FileSystemException error, {
    required bool isWrite,
  }) {
    final structuredMessage = describeFileAccessFailure(
      error,
      isWrite: isWrite,
    );
    return Failure<T>(
      structuredMessage.stableCode,
      structuredMessage: structuredMessage,
    );
  }

  static String _fileAccessFailureCode(FileSystemException error) {
    final errorCode = error.osError?.errorCode;
    final normalized = [
      error.message,
      error.osError?.message,
    ].whereType<String>().join(' ').toLowerCase();
    if ((!Platform.isWindows && (errorCode == 1 || errorCode == 13)) ||
        (Platform.isWindows && errorCode == 5) ||
        normalized.contains('operation not permitted') ||
        normalized.contains('permission denied') ||
        normalized.contains('access is denied') ||
        normalized.contains('not permitted')) {
      return 'access-denied';
    }
    if ((!Platform.isWindows && errorCode == 2) ||
        (Platform.isWindows && (errorCode == 2 || errorCode == 3)) ||
        normalized.contains('no such file') ||
        normalized.contains('cannot find the path') ||
        normalized.contains('does not exist')) {
      return 'location-missing';
    }
    return 'access-failed';
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
      return _accessFailure(e, isWrite: true);
    } on CodecOperationException catch (e) {
      return Failure(
        e.compatibilityCode,
        structuredMessage: e.structuredMessage,
      );
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'write');
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
      return _accessFailure(e, isWrite: false);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'read');
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
      return _accessFailure(e, isWrite: true);
    } on CodecOperationException catch (e) {
      return Failure(
        e.compatibilityCode,
        structuredMessage: e.structuredMessage,
      );
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'write');
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
        return fileOperationFailure(
          'codec-malformed',
          arguments: {
            'reason': StructuredMessageArgument.outcome(
              'invalidValue',
              role: 'codec-malformed-reason',
            ),
          },
        );
      }
      return Success(FSA.fromJson(decoded));
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: false);
    } on FormatException {
      return fileOperationFailure(
        'codec-malformed',
        arguments: {
          'reason': StructuredMessageArgument.outcome(
            'invalidValue',
            role: 'codec-malformed-reason',
          ),
        },
      );
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'read');
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
      return _accessFailure(e, isWrite: true);
    } on CodecOperationException catch (e) {
      return Failure(
        e.compatibilityCode,
        structuredMessage: e.structuredMessage,
      );
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'write');
    }
  }

  /// Loads grammar from JFLAP XML format (.cfg)
  @override
  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = await file.readAsString();
      return const GrammarXmlCodec().decodeGrammarXml(xmlString);
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: false);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'read');
    }
  }

  /// Exports automaton to PNG image
  Future<StringResult> exportAutomatonToPNG(
    FSA automaton,
    String filePath, {
    String emptyStringSymbol = 'ε',
  }) async {
    try {
      final pngBytesResult = await exportAutomatonToPngBytes(
        automaton,
        emptyStringSymbol: emptyStringSymbol,
      );
      if (pngBytesResult.isFailure) {
        return Failure(
          pngBytesResult.error!,
          structuredMessage: pngBytesResult.structuredError,
        );
      }
      return await writePngBytesToPath(pngBytesResult.data!, filePath);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'exportPng');
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
      return _accessFailure(e, isWrite: true);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'exportPng');
    }
  }

  /// Exports the current FSA model to SVG format.
  @override
  Future<StringResult> exportFsaToSVG(
    FSA automaton,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportFsaToSvgString(
          automaton,
          options: options,
          emptyAutomatonLabel: emptyAutomatonLabel,
          tmLegendLabel: tmLegendLabel,
          emptyStringSymbol: emptyStringSymbol,
          includeAnnotations: includeAnnotations,
          annotations: annotations,
        ),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: true);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'exportSvg');
    }
  }

  /// Exports grammar to SVG format (as state diagram)
  Future<StringResult> exportGrammarToSVG(
    GrammarEntity grammar,
    String filePath, {
    SvgExportOptions? options,
    String? emptyStringSymbol,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportGrammarToSvgString(
          grammar,
          options: options,
          emptyStringSymbol: emptyStringSymbol,
        ),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: true);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'exportSvg');
    }
  }

  /// Exports the current grammar model to SVG format.
  @override
  Future<StringResult> exportGrammarModelToSVG(
    Grammar grammar,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportGrammarModelToSvgString(
          grammar,
          options: options,
          emptyAutomatonLabel: emptyAutomatonLabel,
          tmLegendLabel: tmLegendLabel,
          emptyStringSymbol: emptyStringSymbol,
          includeAnnotations: includeAnnotations,
          annotations: annotations,
        ),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: true);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'exportSvg');
    }
  }

  /// Exports the current PDA model to SVG format.
  @override
  Future<StringResult> exportPdaToSVG(
    PDA pda,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportPdaToSvgString(
          pda,
          options: options,
          emptyAutomatonLabel: emptyAutomatonLabel,
          tmLegendLabel: tmLegendLabel,
          emptyStringSymbol: emptyStringSymbol,
          includeAnnotations: includeAnnotations,
          annotations: annotations,
        ),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: true);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'exportSvg');
    }
  }

  /// Exports Turing machine to SVG format
  @override
  Future<StringResult> exportTuringMachineToSVG(
    TuringMachineEntity tm,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    try {
      final file = File(filePath);
      await file.writeAsString(
        exportTuringMachineToSvgString(
          tm,
          options: options,
          emptyAutomatonLabel: emptyAutomatonLabel,
          tmLegendLabel: tmLegendLabel,
          emptyStringSymbol: emptyStringSymbol,
          includeAnnotations: includeAnnotations,
          annotations: annotations,
        ),
      );
      return Success(filePath);
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: true);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'exportSvg');
    }
  }

  /// Gets the default documents directory
  Future<StringResult> getDocumentsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return Success(directory.path);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'directory');
    }
  }

  /// Creates a new file with unique name
  Future<StringResult> createUniqueFile(
    String baseName,
    String extension,
  ) async {
    try {
      final dirResult = await getDocumentsDirectory();
      if (!dirResult.isSuccess) {
        return Failure(
          dirResult.error!,
          structuredMessage: dirResult.structuredError,
        );
      }

      final directory = Directory(dirResult.data!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${baseName}_$timestamp.$extension';
      final filePath = '${directory.path}/$fileName';

      return Success(filePath);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'create');
    }
  }

  /// Lists all files with specific extension in documents directory
  Future<ListResult<String>> listFiles(String extension) async {
    try {
      final dirResult = await getDocumentsDirectory();
      if (!dirResult.isSuccess) {
        return Failure(
          dirResult.error!,
          structuredMessage: dirResult.structuredError,
        );
      }

      final directory = Directory(dirResult.data!);
      final files = <String>[];
      await for (final entity in directory.list()) {
        if (entity.path.endsWith('.$extension')) {
          files.add(entity.path);
        }
      }

      return Success(files);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'list');
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
      return fileOperationFailure('location-missing', operation: 'delete');
    } on FileSystemException catch (e) {
      return _accessFailure(e, isWrite: true);
    } catch (_) {
      return fileOperationFailure('operation-failed', operation: 'delete');
    }
  }

  _AutomatonDrawingData _prepareDrawingData(
    FSA automaton,
    String emptyStringSymbol,
  ) {
    final states = automaton.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final transitions =
        automaton.transitions.whereType<FSATransition>().toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    final drawableStates = states
        .map(
          (state) => _DrawableState(
            center: Offset(state.position.x, state.position.y),
            label: state.label,
            fillColor: state.isAccepting
                ? _kAcceptingFillColor
                : _kDefaultFillColor,
            strokeColor: state.isInitial ? _kInitialStrokeColor : _kStrokeColor,
            strokeWidth: state.isInitial
                ? _kInitialStrokeWidth
                : _kDefaultStrokeWidth,
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
            label: transition.symbol.replaceAll('ε', emptyStringSymbol),
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
