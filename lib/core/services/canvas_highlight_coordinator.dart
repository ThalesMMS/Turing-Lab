// lib/core must stay Flutter-free (see core_layer_boundaries_test), so the
// immutability annotation comes from meta rather than flutter/foundation.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../models/simulation_highlight.dart';
import 'highlight_channel.dart';

/// Automaton family rendered by a concrete canvas surface.
enum AutomatonSurfaceKind { fsa, pda, tm }

/// Independent highlight producers ordered by visual priority.
enum CanvasHighlightSource { validation, analysis, simulation }

/// Immutable identity for one revision of a concrete automaton canvas.
@immutable
class CanvasHighlightTarget {
  const CanvasHighlightTarget({
    required this.kind,
    required this.surface,
    required this.documentId,
    required this.revision,
  });

  final AutomatonSurfaceKind kind;
  final Object surface;
  final String? documentId;
  final int revision;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CanvasHighlightTarget &&
            other.kind == kind &&
            identical(other.surface, surface) &&
            other.documentId == documentId &&
            other.revision == revision;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        identityHashCode(surface),
        documentId,
        revision,
      );
}

/// Arbitrates highlight sources for exactly one concrete canvas.
class CanvasHighlightCoordinator {
  CanvasHighlightCoordinator({
    required CanvasHighlightTarget target,
    required HighlightChannel output,
  })  : _target = target,
        _output = output;

  static const List<CanvasHighlightSource> _priority = [
    CanvasHighlightSource.simulation,
    CanvasHighlightSource.analysis,
    CanvasHighlightSource.validation,
  ];

  final HighlightChannel _output;
  final Map<CanvasHighlightSource, _HighlightSlot> _slots = {};
  CanvasHighlightTarget _target;
  SimulationHighlight _effective = SimulationHighlight.empty;
  bool _disposed = false;

  CanvasHighlightTarget get target => _target;

  /// Claims a separately owned slot for [source].
  CanvasHighlightSourceHandle source(CanvasHighlightSource source) {
    return CanvasHighlightSourceHandle._(this, source);
  }

  /// Replaces the surface revision and invalidates all previous payloads.
  void retarget(CanvasHighlightTarget target) {
    if (_disposed || target == _target) {
      return;
    }

    _target = target;
    _slots.clear();
    _reconcile();
  }

  void _send(
    CanvasHighlightSourceHandle owner,
    CanvasHighlightTarget target,
    SimulationHighlight highlight,
  ) {
    if (_disposed || owner._disposed || target != _target) {
      return;
    }
    if (highlight.isEmpty) {
      _clear(owner, target);
      return;
    }

    _slots[owner.source] = _HighlightSlot(owner, highlight);
    _reconcile();
  }

  void _clear(
    CanvasHighlightSourceHandle owner,
    CanvasHighlightTarget target,
  ) {
    if (_disposed || owner._disposed || target != _target) {
      return;
    }

    final slot = _slots[owner.source];
    if (slot == null || !identical(slot.owner, owner)) {
      return;
    }
    _slots.remove(owner.source);
    _reconcile();
  }

  void _disposeHandle(CanvasHighlightSourceHandle owner) {
    if (_disposed) {
      return;
    }
    final slot = _slots[owner.source];
    if (slot == null || !identical(slot.owner, owner)) {
      return;
    }
    _slots.remove(owner.source);
    _reconcile();
  }

  void _reconcile() {
    var next = SimulationHighlight.empty;
    for (final source in _priority) {
      final slot = _slots[source];
      if (slot != null) {
        next = slot.highlight;
        break;
      }
    }

    if (next == _effective) {
      return;
    }
    _effective = next;
    if (next.isEmpty) {
      _output.clear();
    } else {
      _output.send(next);
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _slots.clear();
    if (!_effective.isEmpty) {
      _effective = SimulationHighlight.empty;
      _output.clear();
    }
    _disposed = true;
  }
}

/// Owned channel for one coordinator source.
class CanvasHighlightSourceHandle implements HighlightChannel {
  CanvasHighlightSourceHandle._(this._coordinator, this.source);

  final CanvasHighlightCoordinator _coordinator;
  final CanvasHighlightSource source;
  bool _disposed = false;

  CanvasHighlightTarget get target => _coordinator.target;

  @override
  void send(SimulationHighlight highlight) {
    sendFor(target, highlight);
  }

  /// Publishes only when [target] is still the coordinator's current target.
  void sendFor(
    CanvasHighlightTarget target,
    SimulationHighlight highlight,
  ) {
    _coordinator._send(this, target, highlight);
  }

  @override
  void clear() {
    clearFor(target);
  }

  /// Clears only this handle's current slot on [target].
  void clearFor(CanvasHighlightTarget target) {
    _coordinator._clear(this, target);
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _coordinator._disposeHandle(this);
    _disposed = true;
  }
}

class _HighlightSlot {
  const _HighlightSlot(this.owner, this.highlight);

  final CanvasHighlightSourceHandle owner;
  final SimulationHighlight highlight;
}

/// Scoped coordinator made available by a concrete canvas page. The null
/// default disables coordinated highlights; consumers must handle null unless
/// a page overrides the provider.
final canvasHighlightCoordinatorProvider =
    Provider<CanvasHighlightCoordinator?>((ref) => null);
