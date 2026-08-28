import 'dart:math' as math;
import 'dart:typed_data';

import '../messages/structured_message.dart';
import 'l_system_expander.dart';
import 'l_system_model.dart';

final class LSystemBounds {
  const LSystemBounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  double get width => maxX - minX;
  double get height => maxY - minY;
}

final class LSystemGeometry {
  factory LSystemGeometry({
    required Iterable<double> segmentCoordinates,
    required Iterable<int> sourceTokenIndices,
    required LSystemBounds bounds,
    required int maximumBranchDepth,
    Iterable<double>? segmentWidths,
    Iterable<int>? segmentColorsArgb,
    Iterable<LSystemPolygon> polygons = const [],
  }) {
    final coordinates = Float64List.fromList(
      segmentCoordinates.toList(growable: false),
    ).asUnmodifiableView();
    final sources = Int32List.fromList(
      sourceTokenIndices.toList(growable: false),
    ).asUnmodifiableView();
    if (coordinates.length % 4 != 0 ||
        sources.length != coordinates.length ~/ 4) {
      throw ArgumentError('Geometry segment arrays are inconsistent.');
    }
    final count = coordinates.length ~/ 4;
    final widths = Float64List.fromList(
      segmentWidths?.toList(growable: false) ?? List.filled(count, 1),
    ).asUnmodifiableView();
    final colors = Int64List.fromList(
      segmentColorsArgb?.toList(growable: false) ??
          List.filled(count, 0xff111827),
    ).asUnmodifiableView();
    if (widths.length != count || colors.length != count) {
      throw ArgumentError('Geometry style arrays are inconsistent.');
    }
    return LSystemGeometry._(
      segmentCoordinates: coordinates,
      sourceTokenIndices: sources,
      segmentWidths: widths,
      segmentColorsArgb: colors,
      polygons: List<LSystemPolygon>.unmodifiable(polygons),
      bounds: bounds,
      maximumBranchDepth: maximumBranchDepth,
    );
  }

  const LSystemGeometry._({
    required this.segmentCoordinates,
    required this.sourceTokenIndices,
    required this.segmentWidths,
    required this.segmentColorsArgb,
    required this.polygons,
    required this.bounds,
    required this.maximumBranchDepth,
  });

  final Float64List segmentCoordinates;
  final Int32List sourceTokenIndices;
  final Float64List segmentWidths;
  final Int64List segmentColorsArgb;
  final List<LSystemPolygon> polygons;
  final LSystemBounds bounds;
  final int maximumBranchDepth;

  int get segmentCount => segmentCoordinates.length ~/ 4;
}

final class LSystemPolygon {
  LSystemPolygon({
    required Iterable<double> coordinates,
    required this.sourceTokenIndex,
    required this.colorArgb,
  }) : coordinates = Float64List.fromList(
         coordinates.toList(growable: false),
       ).asUnmodifiableView() {
    if (this.coordinates.length < 6 || this.coordinates.length.isOdd) {
      throw ArgumentError('A polygon requires at least three 2D points.');
    }
  }

  final Float64List coordinates;
  final int sourceTokenIndex;
  final int colorArgb;
}

final class LSystemTurtleLimits {
  const LSystemTurtleLimits({
    this.maximumSegments = 1000000,
    this.maximumStackDepth = 10000,
    this.cancellationToken,
    this.cancellationCheckpoint,
  });

  final int maximumSegments;
  final int maximumStackDepth;
  final LSystemCancellationToken? cancellationToken;
  final bool Function(int processedSymbols)? cancellationCheckpoint;
}

enum LSystemTurtleDiagnosticCode {
  stackUnderflow,
  unclosedBranch,
  polygonUnderflow,
  unclosedPolygon,
  stackDepthLimit,
  nonFiniteGeometry,
  invalidCommandArgument,
  invalidColor,
  invalidLineWidth,
}

final class LSystemTurtleDiagnostic {
  const LSystemTurtleDiagnostic({
    required this.code,
    required this.symbolIndex,
    required this.structuredMessage,
  });

  final LSystemTurtleDiagnosticCode code;
  final int symbolIndex;
  final StructuredMessage structuredMessage;
}

LSystemTurtleDiagnostic _turtleDiagnostic({
  required LSystemTurtleDiagnosticCode code,
  required int symbolIndex,
  required String messageCode,
  Map<String, StructuredMessageArgument> arguments = const {},
}) => LSystemTurtleDiagnostic(
  code: code,
  symbolIndex: symbolIndex,
  structuredMessage: StructuredMessage(
    namespace: 'l-system.turtle',
    code: messageCode,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
    source: StructuredMessageSource(kind: 'l-system-token', index: symbolIndex),
  ),
);

sealed class LSystemTurtleOutcome {
  const LSystemTurtleOutcome();
}

final class LSystemTurtleCompleted extends LSystemTurtleOutcome {
  const LSystemTurtleCompleted(this.geometry);

  final LSystemGeometry geometry;
}

final class LSystemTurtleCancelled extends LSystemTurtleOutcome {
  const LSystemTurtleCancelled({required this.processedSymbols});

  final int processedSymbols;
}

final class LSystemTurtleBounded extends LSystemTurtleOutcome {
  const LSystemTurtleBounded({
    required this.maximumSegments,
    required this.processedSymbols,
  });

  final int maximumSegments;
  final int processedSymbols;
}

final class LSystemTurtleInvalid extends LSystemTurtleOutcome {
  LSystemTurtleInvalid(Iterable<LSystemTurtleDiagnostic> diagnostics)
    : diagnostics = List<LSystemTurtleDiagnostic>.unmodifiable(diagnostics);

  final List<LSystemTurtleDiagnostic> diagnostics;
}

final class LSystemFitTransform {
  const LSystemFitTransform({
    required this.scale,
    required this.translateX,
    required this.translateY,
  });

  final double scale;
  final double translateX;
  final double translateY;

  static LSystemFitTransform contain(
    LSystemBounds bounds, {
    required double viewportWidth,
    required double viewportHeight,
    double padding = 16,
  }) {
    if (viewportWidth <= 0 || viewportHeight <= 0 || padding < 0) {
      throw ArgumentError('Viewport dimensions must be positive.');
    }
    final availableWidth = math.max(1.0, viewportWidth - padding * 2);
    final availableHeight = math.max(1.0, viewportHeight - padding * 2);
    final width = math.max(bounds.width, 1e-9);
    final height = math.max(bounds.height, 1e-9);
    final scale = math.min(availableWidth / width, availableHeight / height);
    final contentWidth = bounds.width * scale;
    final contentHeight = bounds.height * scale;
    return LSystemFitTransform(
      scale: scale,
      translateX: (viewportWidth - contentWidth) / 2 - bounds.minX * scale,
      translateY: (viewportHeight - contentHeight) / 2 - bounds.minY * scale,
    );
  }
}

final class LSystemTurtleInterpreter {
  const LSystemTurtleInterpreter();

  LSystemTurtleOutcome interpret(
    LSystemWord word, {
    required LSystemTurtleSettings settings,
    required LSystemCommandMapping mapping,
    LSystemTurtleLimits limits = const LSystemTurtleLimits(),
  }) {
    if (limits.maximumSegments < 0 || limits.maximumStackDepth < 0) {
      throw ArgumentError('Turtle limits must be non-negative.');
    }
    final coordinates = <double>[];
    final sourceIndices = <int>[];
    final widths = <double>[];
    final colors = <int>[];
    final polygons = <LSystemPolygon>[];
    var drawnSegments = 0;
    List<double>? activePolygon;
    var polygonStartIndex = -1;
    final stack = <_TurtleState>[];
    var state = _TurtleState.initial(settings);
    var minX = state.position.x;
    var maxX = state.position.x;
    var minY = state.position.y;
    var maxY = state.position.y;
    var maximumDepth = 0;
    for (var index = 0; index < word.symbols.length; index++) {
      if ((limits.cancellationToken?.isCancelled ?? false) ||
          (limits.cancellationCheckpoint?.call(index) ?? false)) {
        return LSystemTurtleCancelled(processedSymbols: index);
      }
      final parsed = _parseCommandToken(word.symbols[index]);
      final command =
          mapping.commands[word.symbols[index]] ??
          mapping.commands[parsed.name] ??
          LSystemTurtleCommand.ignore;
      final argument = parsed.argument;
      final numericArgument = _numericArgument(argument);
      if (_numericCommands.contains(command) &&
          ((argument != null &&
                  (numericArgument == null || !numericArgument.isFinite)) ||
              (_numericAssignmentCommands.contains(command) &&
                  numericArgument == null))) {
        return LSystemTurtleInvalid([
          _turtleDiagnostic(
            code: LSystemTurtleDiagnosticCode.invalidCommandArgument,
            symbolIndex: index,
            messageCode: 'finite-command-argument-required',
            arguments: {
              'command': StructuredMessageArgument.literal(
                parsed.name,
                role: 'turtle-command',
              ),
            },
          ),
        ]);
      }
      switch (command) {
        case LSystemTurtleCommand.drawForward:
        case LSystemTurtleCommand.moveForward:
          final distance = _numericArgument(argument) ?? state.stepLength;
          if (!distance.isFinite) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.nonFiniteGeometry,
                symbolIndex: index,
                messageCode: 'non-finite-geometry',
              ),
            ]);
          }
          final next = state.position + state.forward.scale(distance);
          if (!next.isFinite) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.nonFiniteGeometry,
                symbolIndex: index,
                messageCode: 'non-finite-geometry',
              ),
            ]);
          }
          final nextX = next.x;
          final nextY = next.y;
          if (command == LSystemTurtleCommand.drawForward) {
            if (drawnSegments >= limits.maximumSegments) {
              return LSystemTurtleBounded(
                maximumSegments: limits.maximumSegments,
                processedSymbols: index,
              );
            }
            drawnSegments++;
            if (activePolygon != null) {
              activePolygon.addAll([nextX, nextY]);
            } else {
              coordinates.addAll([
                state.position.x,
                state.position.y,
                nextX,
                nextY,
              ]);
              sourceIndices.add(index);
              widths.add(state.lineWidth);
              colors.add(state.colorArgb);
            }
          }
          state = state.copyWith(position: next);
          minX = math.min(minX, nextX);
          maxX = math.max(maxX, nextX);
          minY = math.min(minY, nextY);
          maxY = math.max(maxY, nextY);
          continue;
        case LSystemTurtleCommand.turnLeft:
          state = state.rotate(
            axis: state.up,
            degrees: -(_numericArgument(argument) ?? state.angleDegrees),
          );
          continue;
        case LSystemTurtleCommand.turnRight:
          state = state.rotate(
            axis: state.up,
            degrees: _numericArgument(argument) ?? state.angleDegrees,
          );
          continue;
        case LSystemTurtleCommand.pitchDown:
          state = state.rotate(
            axis: state.right,
            degrees: _numericArgument(argument) ?? state.angleDegrees,
          );
          continue;
        case LSystemTurtleCommand.pitchUp:
          state = state.rotate(
            axis: state.right,
            degrees: -(_numericArgument(argument) ?? state.angleDegrees),
          );
          continue;
        case LSystemTurtleCommand.rollRight:
          state = state.rotate(
            axis: state.forward,
            degrees: _numericArgument(argument) ?? state.angleDegrees,
          );
          continue;
        case LSystemTurtleCommand.rollLeft:
          state = state.rotate(
            axis: state.forward,
            degrees: -(_numericArgument(argument) ?? state.angleDegrees),
          );
          continue;
        case LSystemTurtleCommand.push:
          if (stack.length >= limits.maximumStackDepth) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.stackDepthLimit,
                symbolIndex: index,
                messageCode: 'branch-stack-limit',
              ),
            ]);
          }
          stack.add(state);
          maximumDepth = math.max(maximumDepth, stack.length);
          continue;
        case LSystemTurtleCommand.pop:
          if (stack.isEmpty) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.stackUnderflow,
                symbolIndex: index,
                messageCode: 'branch-pop-without-push',
              ),
            ]);
          }
          state = stack.removeLast();
          continue;
        case LSystemTurtleCommand.reverseHeading:
          state = state.rotate(axis: state.up, degrees: 180);
          continue;
        case LSystemTurtleCommand.increaseLineWidth:
        case LSystemTurtleCommand.decreaseLineWidth:
          final delta = _numericArgument(argument) ?? state.lineWidthIncrement;
          final nextWidth = command == LSystemTurtleCommand.increaseLineWidth
              ? state.lineWidth + delta
              : state.lineWidth - delta;
          if (!nextWidth.isFinite || nextWidth <= 0) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.invalidLineWidth,
                symbolIndex: index,
                messageCode: 'line-width-invalid',
              ),
            ]);
          }
          state = state.copyWith(lineWidth: nextWidth);
          continue;
        case LSystemTurtleCommand.beginPolygon:
          if (activePolygon != null) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.unclosedPolygon,
                symbolIndex: index,
                messageCode: 'nested-polygon-unsupported',
              ),
            ]);
          }
          activePolygon = [state.position.x, state.position.y];
          polygonStartIndex = index;
          continue;
        case LSystemTurtleCommand.endPolygon:
          if (activePolygon == null) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.polygonUnderflow,
                symbolIndex: index,
                messageCode: 'polygon-close-without-begin',
              ),
            ]);
          }
          if (activePolygon.length < 6) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.unclosedPolygon,
                symbolIndex: index,
                messageCode: 'polygon-minimum-points',
              ),
            ]);
          }
          polygons.add(
            LSystemPolygon(
              coordinates: activePolygon,
              sourceTokenIndex: polygonStartIndex,
              colorArgb: state.polygonColorArgb,
            ),
          );
          activePolygon = null;
          polygonStartIndex = -1;
          continue;
        case LSystemTurtleCommand.increaseHue:
        case LSystemTurtleCommand.decreaseHue:
        case LSystemTurtleCommand.increasePolygonHue:
        case LSystemTurtleCommand.decreasePolygonHue:
          final change =
              _numericArgument(argument) ?? state.hueIncrementDegrees;
          final increasing =
              command == LSystemTurtleCommand.increaseHue ||
              command == LSystemTurtleCommand.increasePolygonHue;
          final polygon =
              command == LSystemTurtleCommand.increasePolygonHue ||
              command == LSystemTurtleCommand.decreasePolygonHue;
          final shifted = _shiftHue(
            polygon ? state.polygonColorArgb : state.colorArgb,
            increasing ? change : -change,
          );
          state = polygon
              ? state.copyWith(polygonColorArgb: shifted)
              : state.copyWith(colorArgb: shifted);
          continue;
        case LSystemTurtleCommand.setDrawColor:
        case LSystemTurtleCommand.setPolygonColor:
          final color = parseJflapTurtleColor(argument);
          if (color == null) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.invalidColor,
                symbolIndex: index,
                messageCode: 'color-unsupported',
              ),
            ]);
          }
          state = command == LSystemTurtleCommand.setDrawColor
              ? state.copyWith(colorArgb: color)
              : state.copyWith(polygonColorArgb: color);
          continue;
        case LSystemTurtleCommand.setAngleIncrement:
          state = state.copyWith(
            angleDegrees: _normalizeDegrees(numericArgument!),
          );
          continue;
        case LSystemTurtleCommand.setLineWidth:
          if (numericArgument! <= 0) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.invalidLineWidth,
                symbolIndex: index,
                messageCode: 'line-width-invalid',
              ),
            ]);
          }
          state = state.copyWith(lineWidth: numericArgument);
          continue;
        case LSystemTurtleCommand.setLineWidthIncrement:
          if (numericArgument! <= 0) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.invalidLineWidth,
                symbolIndex: index,
                messageCode: 'line-width-increment-invalid',
              ),
            ]);
          }
          state = state.copyWith(lineWidthIncrement: numericArgument);
          continue;
        case LSystemTurtleCommand.setStepLength:
          if (numericArgument! <= 0) {
            return LSystemTurtleInvalid([
              _turtleDiagnostic(
                code: LSystemTurtleDiagnosticCode.invalidCommandArgument,
                symbolIndex: index,
                messageCode: 'distance-invalid',
              ),
            ]);
          }
          state = state.copyWith(stepLength: numericArgument * settings.scale);
          continue;
        case LSystemTurtleCommand.setHueIncrement:
          state = state.copyWith(
            hueIncrementDegrees: _normalizeDegrees(numericArgument!),
          );
          continue;
        case LSystemTurtleCommand.ignore:
          break;
      }
    }
    if (activePolygon != null) {
      return LSystemTurtleInvalid([
        _turtleDiagnostic(
          code: LSystemTurtleDiagnosticCode.unclosedPolygon,
          symbolIndex: word.length,
          messageCode: 'polygon-unclosed',
        ),
      ]);
    }
    if (stack.isNotEmpty) {
      return LSystemTurtleInvalid([
        _turtleDiagnostic(
          code: LSystemTurtleDiagnosticCode.unclosedBranch,
          symbolIndex: word.length,
          messageCode: 'branch-state-unrestored',
          arguments: {
            'count': StructuredMessageArgument.count(
              stack.length,
              role: 'branch-count',
            ),
          },
        ),
      ]);
    }
    return LSystemTurtleCompleted(
      LSystemGeometry(
        segmentCoordinates: coordinates,
        sourceTokenIndices: sourceIndices,
        segmentWidths: widths,
        segmentColorsArgb: colors,
        polygons: polygons,
        bounds: LSystemBounds(minX: minX, minY: minY, maxX: maxX, maxY: maxY),
        maximumBranchDepth: maximumDepth,
      ),
    );
  }
}

final class _TurtleState {
  const _TurtleState({
    required this.position,
    required this.forward,
    required this.right,
    required this.up,
    required this.stepLength,
    required this.angleDegrees,
    required this.lineWidth,
    required this.lineWidthIncrement,
    required this.hueIncrementDegrees,
    required this.colorArgb,
    required this.polygonColorArgb,
  });

  factory _TurtleState.initial(LSystemTurtleSettings settings) {
    final radians = settings.initialHeadingDegrees * math.pi / 180;
    return _TurtleState(
      position: _Vector3(settings.initialX, settings.initialY, 0),
      forward: _Vector3(math.sin(radians), -math.cos(radians), 0),
      right: _Vector3(math.cos(radians), math.sin(radians), 0),
      up: const _Vector3(0, 0, 1),
      stepLength: settings.stepLength * settings.scale,
      angleDegrees: _normalizeDegrees(settings.angleDegrees),
      lineWidth: settings.lineWidth,
      lineWidthIncrement: settings.lineWidthIncrement,
      hueIncrementDegrees: _normalizeDegrees(settings.hueIncrementDegrees),
      colorArgb: settings.initialColorArgb,
      polygonColorArgb: settings.initialPolygonColorArgb,
    );
  }

  final _Vector3 position;
  final _Vector3 forward;
  final _Vector3 right;
  final _Vector3 up;
  final double stepLength;
  final double angleDegrees;
  final double lineWidth;
  final double lineWidthIncrement;
  final double hueIncrementDegrees;
  final int colorArgb;
  final int polygonColorArgb;

  _TurtleState rotate({required _Vector3 axis, required double degrees}) {
    if (!degrees.isFinite) return this;
    final normalizedDegrees = _normalizeDegrees(degrees);
    return copyWith(
      forward: forward.rotate(axis, normalizedDegrees).normalized.snapped,
      right: right.rotate(axis, normalizedDegrees).normalized.snapped,
      up: up.rotate(axis, normalizedDegrees).normalized.snapped,
    );
  }

  _TurtleState copyWith({
    _Vector3? position,
    _Vector3? forward,
    _Vector3? right,
    _Vector3? up,
    double? stepLength,
    double? angleDegrees,
    double? lineWidth,
    double? lineWidthIncrement,
    double? hueIncrementDegrees,
    int? colorArgb,
    int? polygonColorArgb,
  }) => _TurtleState(
    position: position ?? this.position,
    forward: forward ?? this.forward,
    right: right ?? this.right,
    up: up ?? this.up,
    stepLength: stepLength ?? this.stepLength,
    angleDegrees: angleDegrees ?? this.angleDegrees,
    lineWidth: lineWidth ?? this.lineWidth,
    lineWidthIncrement: lineWidthIncrement ?? this.lineWidthIncrement,
    hueIncrementDegrees: hueIncrementDegrees ?? this.hueIncrementDegrees,
    colorArgb: colorArgb ?? this.colorArgb,
    polygonColorArgb: polygonColorArgb ?? this.polygonColorArgb,
  );
}

final class _Vector3 {
  const _Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  bool get isFinite => x.isFinite && y.isFinite && z.isFinite;

  _Vector3 operator +(_Vector3 other) =>
      _Vector3(x + other.x, y + other.y, z + other.z);

  _Vector3 scale(double value) => _Vector3(x * value, y * value, z * value);

  double dot(_Vector3 other) => x * other.x + y * other.y + z * other.z;

  _Vector3 cross(_Vector3 other) => _Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  double get length => math.sqrt(dot(this));

  _Vector3 get normalized {
    final magnitude = length;
    return magnitude == 0 ? this : scale(1 / magnitude);
  }

  _Vector3 get snapped =>
      _Vector3(_snapComponent(x), _snapComponent(y), _snapComponent(z));

  _Vector3 rotate(_Vector3 rawAxis, double degrees) {
    final axis = rawAxis.normalized;
    final radians = degrees * math.pi / 180;
    final cosine = math.cos(radians);
    final sine = math.sin(radians);
    return scale(cosine) +
        axis.cross(this).scale(sine) +
        axis.scale(axis.dot(this) * (1 - cosine));
  }
}

const _numericCommands = {
  LSystemTurtleCommand.drawForward,
  LSystemTurtleCommand.moveForward,
  LSystemTurtleCommand.turnLeft,
  LSystemTurtleCommand.turnRight,
  LSystemTurtleCommand.pitchDown,
  LSystemTurtleCommand.pitchUp,
  LSystemTurtleCommand.rollRight,
  LSystemTurtleCommand.rollLeft,
  LSystemTurtleCommand.increaseLineWidth,
  LSystemTurtleCommand.decreaseLineWidth,
  LSystemTurtleCommand.increaseHue,
  LSystemTurtleCommand.decreaseHue,
  LSystemTurtleCommand.increasePolygonHue,
  LSystemTurtleCommand.decreasePolygonHue,
  LSystemTurtleCommand.setAngleIncrement,
  LSystemTurtleCommand.setLineWidth,
  LSystemTurtleCommand.setLineWidthIncrement,
  LSystemTurtleCommand.setStepLength,
  LSystemTurtleCommand.setHueIncrement,
};

const _numericAssignmentCommands = {
  LSystemTurtleCommand.setAngleIncrement,
  LSystemTurtleCommand.setLineWidth,
  LSystemTurtleCommand.setLineWidthIncrement,
  LSystemTurtleCommand.setStepLength,
  LSystemTurtleCommand.setHueIncrement,
};

({String name, String? argument}) _parseCommandToken(String token) {
  final opening = token.indexOf('(');
  if (opening > 0 && token.endsWith(')')) {
    return (
      name: token.substring(0, opening),
      argument: token.substring(opening + 1, token.length - 1).trim(),
    );
  }
  final assignment = token.indexOf('=');
  if (assignment > 0) {
    return (
      name: token.substring(0, assignment).trim(),
      argument: token.substring(assignment + 1).trim(),
    );
  }
  return (name: token, argument: null);
}

double? _numericArgument(String? value) {
  if (value == null || value.isEmpty) return null;
  return double.tryParse(value);
}

int? parseJflapTurtleColor(String? value) {
  if (value == null || value.isEmpty) return null;
  final normalized = value.trim().toLowerCase();
  const named = {
    'black': 0xff000000,
    'blue': 0xff0000ff,
    'cyan': 0xff00ffff,
    'darkgray': 0xff404040,
    'darkgrey': 0xff404040,
    'gray': 0xff808080,
    'grey': 0xff808080,
    'green': 0xff00ff00,
    'lightgray': 0xffc0c0c0,
    'lightgrey': 0xffc0c0c0,
    'magenta': 0xffff00ff,
    'orange': 0xffffc800,
    'pink': 0xffffafaf,
    'red': 0xffff0000,
    'white': 0xffffffff,
    'yellow': 0xffffff00,
    'dukeblue': 0xff00009c,
    'brown': 0xff810000,
    'olivedrab': 0xff725d00,
    'darkolivegreen': 0xff6d6f00,
    'orangered': 0xfffc7600,
    'maroon': 0xffbe0000,
    'forestgreen': 0xff007f00,
    'purple': 0xffd100ff,
    'springgreen': 0xffc1ff9d,
    'violetred': 0xffd200cd,
    'goldenrod': 0xffffd600,
    'darkolivegreen2': 0xff0a7f00,
  };
  if (named.containsKey(normalized)) return named[normalized];
  if (normalized.startsWith('#')) {
    final hex = normalized.substring(1);
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;
    return switch (hex.length) {
      6 => 0xff000000 | parsed,
      8 => parsed,
      _ => null,
    };
  }
  final components = normalized.split(',');
  if (components.length != 3) return null;
  final values = components
      .map((value) => double.tryParse(value.trim()))
      .toList();
  if (values.any((value) => value == null || !value.isFinite)) return null;
  final redOrHue = values[0]!;
  final greenOrSaturation = values[1]!;
  final blueOrBrightness = values[2]!;
  if (redOrHue < 0 || greenOrSaturation < 0 || blueOrBrightness < 0) {
    return null;
  }
  if (redOrHue <= 1 && greenOrSaturation <= 1 && blueOrBrightness <= 1) {
    return _hsbColor(redOrHue, greenOrSaturation, blueOrBrightness);
  }
  if (redOrHue > 255 || greenOrSaturation > 255 || blueOrBrightness > 255) {
    return null;
  }
  return 0xff000000 |
      (redOrHue.toInt() << 16) |
      (greenOrSaturation.toInt() << 8) |
      blueOrBrightness.toInt();
}

double _normalizeDegrees(double degrees) {
  final normalized = degrees % 360;
  return normalized == -0.0 ? 0 : normalized;
}

double _snapComponent(double value) {
  final nearest = value.roundToDouble();
  return (value - nearest).abs() < 1e-12 ? nearest : value;
}

int _hsbColor(double hue, double saturation, double brightness) {
  final normalizedHue = (hue % 1 + 1) % 1;
  final sector = normalizedHue * 6;
  final chroma = brightness * saturation;
  final component = chroma * (1 - (sector % 2 - 1).abs());
  final match = brightness - chroma;
  final (red, green, blue) = switch (sector) {
    < 1 => (chroma, component, 0.0),
    < 2 => (component, chroma, 0.0),
    < 3 => (0.0, chroma, component),
    < 4 => (0.0, component, chroma),
    < 5 => (component, 0.0, chroma),
    _ => (chroma, 0.0, component),
  };
  return 0xff000000 |
      (((red + match) * 255).round() << 16) |
      (((green + match) * 255).round() << 8) |
      ((blue + match) * 255).round();
}

int _shiftHue(int argb, double degrees) {
  final alpha = (argb >> 24) & 0xff;
  final red = ((argb >> 16) & 0xff) / 255;
  final green = ((argb >> 8) & 0xff) / 255;
  final blue = (argb & 0xff) / 255;
  final maximum = math.max(red, math.max(green, blue));
  final minimum = math.min(red, math.min(green, blue));
  final delta = maximum - minimum;
  var hue = 0.0;
  if (delta != 0) {
    if (maximum == red) {
      hue = 60 * (((green - blue) / delta) % 6);
    } else if (maximum == green) {
      hue = 60 * ((blue - red) / delta + 2);
    } else {
      hue = 60 * ((red - green) / delta + 4);
    }
  }
  hue = (hue + degrees) % 360;
  if (hue < 0) hue += 360;
  final saturation = maximum == 0 ? 0 : delta / maximum;
  final chroma = maximum * saturation;
  final component = chroma * (1 - ((hue / 60) % 2 - 1).abs());
  final match = maximum - chroma;
  final (r, g, b) = switch (hue) {
    < 60 => (chroma, component, 0.0),
    < 120 => (component, chroma, 0.0),
    < 180 => (0.0, chroma, component),
    < 240 => (0.0, component, chroma),
    < 300 => (component, 0.0, chroma),
    _ => (chroma, 0.0, component),
  };
  return (alpha << 24) |
      (((r + match) * 255).round() << 16) |
      (((g + match) * 255).round() << 8) |
      ((b + match) * 255).round();
}
