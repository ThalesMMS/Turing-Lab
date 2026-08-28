import 'dart:async';
import 'dart:isolate';

import 'graph_layout_engine.dart';
import 'graph_layout_models.dart';

final class GraphLayoutCancelledException implements Exception {
  const GraphLayoutCancelledException();

  @override
  String toString() => 'Graph layout computation was cancelled.';
}

final class GraphLayoutTask {
  GraphLayoutTask._(
    this._isolate,
    this._receivePort,
    this._subscription,
    this._resultCompleter,
    this._progressController,
  );

  final Isolate _isolate;
  final ReceivePort _receivePort;
  final StreamSubscription<Object?> _subscription;
  final Completer<GraphLayoutResult> _resultCompleter;
  final StreamController<GraphLayoutProgress> _progressController;
  bool _closed = false;

  Future<GraphLayoutResult> get result => _resultCompleter.future;
  Stream<GraphLayoutProgress> get progress => _progressController.stream;

  static Future<GraphLayoutTask> start(GraphLayoutRequest request) async {
    final receivePort = ReceivePort();
    final resultCompleter = Completer<GraphLayoutResult>();
    // Ownership transfers to GraphLayoutTask, which closes the controller.
    // ignore: close_sinks
    final progressController =
        StreamController<GraphLayoutProgress>.broadcast();
    late final GraphLayoutTask task;
    // Ownership transfers to GraphLayoutTask, which cancels the subscription.
    // ignore: cancel_subscriptions
    final subscription = receivePort.listen((message) {
      if (message is! Map) return;
      switch (message['kind']) {
        case 'progress':
          progressController.add(
            GraphLayoutProgress(
              fraction: message['fraction'] as double,
              stage: GraphLayoutProgressStage.values.byName(
                message['stage'] as String,
              ),
              current: message['current'] as int?,
              total: message['total'] as int?,
            ),
          );
        case 'result':
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(message['value'] as GraphLayoutResult);
          }
          task._close(kill: false);
        case 'error':
          if (!resultCompleter.isCompleted) {
            resultCompleter.completeError(
              StateError(message['message'] as String),
            );
          }
          task._close(kill: false);
      }
    });
    subscription.pause();
    final isolate = await Isolate.spawn<(SendPort, GraphLayoutRequest)>(
      _runGraphLayout,
      (receivePort.sendPort, request),
      debugName: 'turing-lab-graph-layout',
    );
    task = GraphLayoutTask._(
      isolate,
      receivePort,
      subscription,
      resultCompleter,
      progressController,
    );
    subscription.resume();
    return task;
  }

  void cancel() {
    if (_closed) return;
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.completeError(const GraphLayoutCancelledException());
    }
    _close(kill: true);
  }

  void _close({required bool kill}) {
    if (_closed) return;
    _closed = true;
    if (kill) _isolate.kill(priority: Isolate.immediate);
    unawaited(_subscription.cancel());
    unawaited(_progressController.close());
    _receivePort.close();
  }
}

void _runGraphLayout((SendPort, GraphLayoutRequest) message) {
  final (sendPort, request) = message;
  try {
    final result = GraphLayoutEngine.compute(
      request,
      onProgress: (progress) => sendPort.send({
        'kind': 'progress',
        'fraction': progress.fraction,
        'stage': progress.stage.name,
        'current': progress.current,
        'total': progress.total,
      }),
    );
    sendPort.send({'kind': 'result', 'value': result});
  } catch (error, stackTrace) {
    sendPort.send({'kind': 'error', 'message': '$error\n$stackTrace'});
  }
}
