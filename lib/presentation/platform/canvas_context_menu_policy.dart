import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'canvas_context_menu_driver_stub.dart'
    if (dart.library.js_interop) 'canvas_context_menu_driver_web.dart'
    as platform;

typedef CanvasContextMenuSetter = Future<void> Function(bool enabled);

final NavigatorObserver canvasContextMenuNavigatorObserver =
    _CanvasContextMenuNavigatorObserver();

/// Owns the browser context menu while editable canvases need secondary click.
class CanvasContextMenuPolicy {
  CanvasContextMenuPolicy({CanvasContextMenuSetter? setEnabled})
    : _setEnabled = setEnabled ?? platform.setCanvasContextMenuEnabled;

  static final CanvasContextMenuPolicy instance = CanvasContextMenuPolicy();

  final CanvasContextMenuSetter _setEnabled;
  final Set<Object> _owners = <Object>{};
  Future<void> _pending = Future<void>.value();
  bool _lastAppliedEnabled = true;

  @visibleForTesting
  int get ownerCount => _owners.length;

  Future<void> acquire(Object owner) {
    if (_owners.add(owner)) {
      _scheduleSynchronization();
    }
    return _pending;
  }

  Future<void> release(Object owner) {
    if (_owners.remove(owner)) {
      _scheduleSynchronization();
    }
    return _pending;
  }

  Future<void> releaseAll() {
    if (_owners.isNotEmpty) {
      _owners.clear();
      _scheduleSynchronization();
    }
    return _pending;
  }

  @visibleForTesting
  Future<void> get settled => _pending;

  void _scheduleSynchronization() {
    _pending = _pending.then((_) async {
      final enabled = _owners.isEmpty;
      if (enabled == _lastAppliedEnabled) {
        return;
      }
      try {
        await _setEnabled(enabled);
        _lastAppliedEnabled = enabled;
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[CanvasContextMenuPolicy] Failed to set enabled=$enabled: '
            '$error\n$stackTrace',
          );
        }
      }
    });
  }
}

class _CanvasContextMenuNavigatorObserver extends NavigatorObserver {
  void _releaseCanvasOwners() {
    unawaited(CanvasContextMenuPolicy.instance.releaseAll());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _releaseCanvasOwners();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _releaseCanvasOwners();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _releaseCanvasOwners();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _releaseCanvasOwners();
  }
}
