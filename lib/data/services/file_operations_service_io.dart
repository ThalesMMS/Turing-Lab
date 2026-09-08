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
import '../../core/models/automaton.dart';
import '../../core/models/tm.dart';
import '../../core/models/transition.dart';
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
  }) {
    return _renderPng(
      automaton,
      _prepareDrawingData(automaton, emptyStringSymbol),
      includeAnnotations ? annotations : null,
    );
  }

  /// Rasterizes a PDA with the same off-screen painter used for FSAs; the
  /// transition labels are the canonical `input, pop → push` labels.
  @override
  Future<Result<Uint8List>> exportPdaToPngBytes(
    PDA pda, {
    String emptyStringSymbol = 'ε',
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) {
    return _renderPng(
      pda,
      _prepareGenericDrawingData(
        pda,
        pda.pdaTransitions,
        (transition) => transition.label,
        emptyStringSymbol,
      ),
      includeAnnotations ? annotations : null,
    );
  }

  /// Rasterizes a Turing machine; multi-tape transitions keep their stored
  /// per-tape label.
  @override
  Future<Result<Uint8List>> exportTuringMachineToPngBytes(
    TM machine, {
    String emptyStringSymbol = 'ε',
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) {
    return _renderPng(
      machine,
      _prepareGenericDrawingData(
        machine,
        machine.tmTransitions,
        (transition) => transition.label,
        emptyStringSymbol,
      ),
      includeAnnotations ? annotations : null,
    );
  }

  Future<Result<Uint8List>> _renderPng(
    Automaton automaton,
    _AutomatonDrawingData drawingData,
    DocumentAnnotationCollection? annotations,
  ) async {
    ui.Picture? picture;
    ui.Picture? contentPicture;
    ui.Image? image;
    try {
      const size = Size(_kCanvasWidth, _kCanvasHeight);
      final painter = _AutomatonPainter(drawingData);
      final contentRecorder = ui.PictureRecorder();
      final contentCanvas = Canvas(contentRecorder);
      painter.paint(contentCanvas, size);
      var bounds = painter.bounds;
      if (annotations != null) {
        final annotationBounds = _paintDocumentAnnotations(
          contentCanvas,
          annotations,
          automaton,
          Rect.fromLTWH(
            bounds?.left ?? 0,
            bounds?.top ?? 0,
            math.max(size.width, bounds?.width ?? 0),
            math.max(size.height, bounds?.height ?? 0),
          ),
        );
        if (annotationBounds != null) {
          bounds =
              bounds?.expandToInclude(annotationBounds) ?? annotationBounds;
        }
      }
      contentPicture = contentRecorder.endRecording();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _kBackgroundColor,
      );

      if (bounds != null) {
        // Fit world geometry, including labels and notes, inside a pixel margin.
        const margin = 20.0;
        final scale = math.min(
          1.0,
          math.min(
            (size.width - margin * 2) / bounds.width,
            (size.height - margin * 2) / bounds.height,
          ),
        );
        canvas.translate(
          (size.width - bounds.width * scale) / 2,
          (size.height - bounds.height * scale) / 2,
        );
        canvas.scale(scale);
        canvas.translate(-bounds.left, -bounds.top);
      }
      canvas.drawPicture(contentPicture);

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
      contentPicture?.dispose();
    }
  }

  Rect? _paintDocumentAnnotations(
    Canvas canvas,
    DocumentAnnotationCollection annotations,
    Automaton automaton,
    Rect sheet,
  ) {
    Rect? bounds;
    final statePositions = {
      for (final state in automaton.states)
        state.id: Offset(state.position.x, state.position.y),
    };
    final transitionPositions = {
      for (final transition in automaton.transitions)
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
      // Apply the SVG sheet policy in world coordinates so translating a
      // diagram preserves its notes, while distant offsets cannot dominate fit.
      final x = (rawX + (attachmentPosition == null ? 0 : attachment!.offsetX))
          .clamp(sheet.left, sheet.right - DocumentAnnotation.minimumWidth)
          .toDouble();
      final y = (rawY + (attachmentPosition == null ? 0 : attachment!.offsetY))
          .clamp(sheet.top, sheet.bottom - DocumentAnnotation.minimumHeight)
          .toDouble();
      final width = annotation.width.clamp(
        DocumentAnnotation.minimumWidth,
        math.max(DocumentAnnotation.minimumWidth, sheet.right - x),
      );
      final height =
          (annotation.collapsed
                  ? DocumentAnnotation.minimumHeight
                  : annotation.height)
              .clamp(
                DocumentAnnotation.minimumHeight,
                math.max(DocumentAnnotation.minimumHeight, sheet.bottom - y),
              );
      final annotationBounds = Rect.fromLTWH(
        x,
        y,
        width.toDouble(),
        height.toDouble(),
      ).inflate(1);
      bounds = bounds?.expandToInclude(annotationBounds) ?? annotationBounds;
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
    return bounds;
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
  ) => _prepareGenericDrawingData<FSATransition>(
    automaton,
    automaton.transitions.whereType<FSATransition>(),
    (transition) => transition.label,
    emptyStringSymbol,
  );

  /// Drawing data for any automaton whose transitions expose a display
  /// label (FSA, PDA and TM). Both ε and λ in a label are rendered as the
  /// configured empty-string symbol.
  _AutomatonDrawingData _prepareGenericDrawingData<T extends Transition>(
    Automaton automaton,
    Iterable<T> transitions,
    String Function(T transition) labelOf,
    String emptyStringSymbol,
  ) {
    final states = automaton.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final sortedTransitions = transitions.toList()
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

    // Parallel operations share one arrow, with one label row per operation.
    // Keep directions separate and preserve the stable transition-id order.
    final transitionGroups = <(String, String), List<T>>{};
    for (final transition in sortedTransitions) {
      transitionGroups
          .putIfAbsent((
            transition.fromState.id,
            transition.toState.id,
          ), () => [])
          .add(transition);
    }
    final drawableTransitions = transitionGroups.values
        .map(
          (group) => _DrawableTransition(
            from: Offset(
              group.first.fromState.position.x,
              group.first.fromState.position.y,
            ),
            to: Offset(
              group.first.toState.position.x,
              group.first.toState.position.y,
            ),
            label: group
                .map(labelOf)
                .where((label) => label.isNotEmpty)
                .join('\n')
                .replaceAll('ε', emptyStringSymbol)
                .replaceAll('λ', emptyStringSymbol),
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
  _AutomatonPainter(this.data)
    : _directions = {for (final edge in data.transitions) (edge.from, edge.to)};

  final _AutomatonDrawingData data;
  final Set<(Offset, Offset)> _directions;

  TextPainter _textPainter(String text, double fontSize) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: _kTextColor,
        fontSize: fontSize,
        fontFamily: 'Arial',
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();

  Rect? get bounds {
    Rect? result;
    void include(Rect rect) => result = result?.expandToInclude(rect) ?? rect;
    for (final state in data.states) {
      include(
        Rect.fromCircle(
          center: state.center,
          radius: _kStateRadius + state.strokeWidth,
        ),
      );
      final label = _textPainter(state.label, 14);
      include(
        Rect.fromCenter(
          center: state.center,
          width: label.width,
          height: label.height,
        ),
      );
      label.dispose();
    }
    for (final transition in data.transitions) {
      final geometry = _geometry(transition);
      include(geometry.path.getBounds().inflate(12));
      final label = _textPainter(transition.label, 12);
      include(
        Rect.fromCenter(
          center: geometry.labelCenter,
          width: label.width,
          height: label.height,
        ),
      );
      label.dispose();
    }
    return result;
  }

  ({Path path, Offset tip, Offset tangent, Offset labelCenter}) _geometry(
    _DrawableTransition transition,
  ) {
    final from = transition.from;
    final to = transition.to;
    if (from == to) {
      return (
        path: Path()
          ..moveTo(from.dx - 18, from.dy - 24)
          ..cubicTo(
            from.dx - 60,
            from.dy - 90,
            from.dx + 60,
            from.dy - 90,
            from.dx + 18,
            from.dy - 24,
          ),
        tip: from + const Offset(18, -24),
        tangent: const Offset(-42, 66) / const Offset(-42, 66).distance,
        labelCenter: from + const Offset(0, -86),
      );
    }
    final direction = (to - from) / (to - from).distance;
    final normal = Offset(-direction.dy, direction.dx);
    final opposing = _directions.contains((to, from));
    final midpoint = (from + to) / 2;
    if (opposing) {
      final label = _textPainter(transition.label, 12);
      // Clear even multi-row labels on vertical or diagonal opposing edges.
      final separation =
          20 +
          (normal.dx.abs() * label.width + normal.dy.abs() * label.height) / 2;
      label.dispose();
      final control = midpoint + normal * separation * 2;
      final startDirection = (control - from) / (control - from).distance;
      final tangent = (to - control) / (to - control).distance;
      final start = from + startDirection * _kStateRadius;
      final tip = to - tangent * _kStateRadius;
      return (
        path: Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy),
        tip: tip,
        tangent: tangent,
        labelCenter: (start + control * 2 + tip) / 4,
      );
    }
    return (
      path: Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy),
      tip: to - direction * _kStateRadius,
      tangent: direction,
      labelCenter: midpoint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final transitionPaint = Paint()
      ..color = _kStrokeColor
      ..strokeWidth = _kDefaultStrokeWidth
      ..style = PaintingStyle.stroke;

    for (final transition in data.transitions) {
      final geometry = _geometry(transition);
      canvas.drawPath(geometry.path, transitionPaint);
      final normal = Offset(-geometry.tangent.dy, geometry.tangent.dx);
      final left = geometry.tip - geometry.tangent * 10 + normal * 4;
      final right = geometry.tip - geometry.tangent * 10 - normal * 4;
      canvas.drawPath(
        Path()
          ..moveTo(left.dx, left.dy)
          ..lineTo(geometry.tip.dx, geometry.tip.dy)
          ..lineTo(right.dx, right.dy),
        transitionPaint,
      );
      final label = _textPainter(transition.label, 12);
      label.paint(
        canvas,
        geometry.labelCenter - Offset(label.width / 2, label.height / 2),
      );
      label.dispose();
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
