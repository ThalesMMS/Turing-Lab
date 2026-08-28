import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../../core/models/automaton.dart';

typedef CanvasSyncCallback = void Function(Object? automaton);
typedef CanvasPostFrameScheduler = void Function(FrameCallback callback);

/// Coalesces domain-to-canvas updates and rejects callbacks from stale
/// controller generations.
class AutomatonGraphViewDomainSyncCoordinator {
  AutomatonGraphViewDomainSyncCoordinator({
    required CanvasSyncCallback synchronize,
    required bool Function() isMounted,
    CanvasPostFrameScheduler? schedulePostFrame,
    void Function(Object error, StackTrace stackTrace)? onError,
  })  : _synchronize = synchronize,
        _isMounted = isMounted,
        _schedulePostFrame =
            schedulePostFrame ?? SchedulerBinding.instance.addPostFrameCallback,
        _onError = onError;

  CanvasSyncCallback _synchronize;
  final bool Function() _isMounted;
  final CanvasPostFrameScheduler _schedulePostFrame;
  final void Function(Object error, StackTrace stackTrace)? _onError;

  Object? _pendingAutomaton;
  int _generation = 0;
  bool _scheduled = false;
  bool _disposed = false;

  int get generation => _generation;

  void schedule(Object? automaton) {
    if (_disposed) {
      return;
    }
    _pendingAutomaton = automaton;
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    final scheduledGeneration = _generation;
    _schedulePostFrame((_) => _flush(scheduledGeneration));
  }

  void replaceTarget(CanvasSyncCallback synchronize) {
    if (_disposed) {
      return;
    }
    _generation++;
    _scheduled = false;
    _pendingAutomaton = null;
    _synchronize = synchronize;
  }

  bool contentChanged(Object? previous, Object? next) {
    if (identical(previous, next)) {
      return false;
    }
    return !_contentEquality.equals(
      _contentSignature(previous),
      _contentSignature(next),
    );
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _scheduled = false;
    _pendingAutomaton = null;
  }

  void _flush(int scheduledGeneration) {
    if (_disposed || scheduledGeneration != _generation) {
      return;
    }
    _scheduled = false;
    if (!_isMounted()) {
      _pendingAutomaton = null;
      return;
    }
    final target = _pendingAutomaton;
    _pendingAutomaton = null;
    try {
      _synchronize(target);
    } catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    }
  }
}

const DeepCollectionEquality _contentEquality = DeepCollectionEquality();

const Set<String> _unorderedCollectionPaths = {
  'acceptingStates',
  'alphabet',
  'stackAlphabet',
  'states',
  'tapeAlphabet',
  'transitions',
  'transitions.*.inputSymbols',
};

Object? _contentSignature(Object? data) {
  if (data is! Automaton) {
    return data;
  }
  final json = Map<String, dynamic>.from(data.toJson())
    ..remove('created')
    ..remove('modified');
  return _canonicalValue(json);
}

Object? _canonicalValue(
  Object? value, {
  List<String> path = const <String>[],
}) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return {
      for (final entry in entries)
        entry.key.toString(): _canonicalValue(
          entry.value,
          path: [...path, entry.key.toString()],
        ),
    };
  }
  if (value is Iterable && value is! String) {
    final items = value
        .map((item) => _canonicalValue(item, path: [...path, '*']))
        .toList();
    if (_unorderedCollectionPaths.contains(path.join('.'))) {
      items.sort((left, right) => _sortKey(left).compareTo(_sortKey(right)));
    }
    return items;
  }
  if (value is math.Rectangle) {
    return {
      'left': value.left,
      'top': value.top,
      'width': value.width,
      'height': value.height,
    };
  }
  if (value is vmath.Vector2) {
    return {'x': value.x, 'y': value.y};
  }
  return value;
}

String _sortKey(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return entries
        .map((entry) => '${entry.key}:${_sortKey(entry.value)}')
        .join('|');
  }
  if (value is Iterable && value is! String) {
    return value.map(_sortKey).join(',');
  }
  return value?.toString() ?? 'null';
}
