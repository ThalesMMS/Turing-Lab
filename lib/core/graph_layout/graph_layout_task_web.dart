import 'dart:async';

import 'graph_layout_engine.dart';
import 'graph_layout_models.dart';

final class GraphLayoutCancelledException implements Exception {
  const GraphLayoutCancelledException();

  @override
  String toString() => 'Graph layout computation was cancelled.';
}

/// Cooperative browser fallback for platforms without spawned isolates.
final class GraphLayoutTask {
  GraphLayoutTask._(
    this._resultCompleter,
    this._progressController,
  );

  final Completer<GraphLayoutResult> _resultCompleter;
  final StreamController<GraphLayoutProgress> _progressController;
  bool _closed = false;

  Future<GraphLayoutResult> get result => _resultCompleter.future;
  Stream<GraphLayoutProgress> get progress => _progressController.stream;

  static Future<GraphLayoutTask> start(GraphLayoutRequest request) async {
    final resultCompleter = Completer<GraphLayoutResult>();
    // Ownership transfers to GraphLayoutTask, which closes the controller.
    // ignore: close_sinks
    final progressController =
        StreamController<GraphLayoutProgress>.broadcast();
    final task = GraphLayoutTask._(resultCompleter, progressController);
    unawaited(task._run(request));
    return task;
  }

  Future<void> _run(GraphLayoutRequest request) async {
    await Future<void>.delayed(Duration.zero);
    if (_closed) return;
    try {
      final result = GraphLayoutEngine.compute(
        request,
        onProgress: (progress) {
          if (!_closed) _progressController.add(progress);
        },
      );
      if (!_closed) _resultCompleter.complete(result);
    } catch (error, stackTrace) {
      if (!_closed) _resultCompleter.completeError(error, stackTrace);
    } finally {
      _close();
    }
  }

  void cancel() {
    if (_closed) return;
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.completeError(const GraphLayoutCancelledException());
    }
    _close();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    unawaited(_progressController.close());
  }
}
