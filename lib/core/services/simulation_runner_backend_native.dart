import 'dart:async';
import 'dart:isolate';

import '../algorithms/pda_simulator.dart';
import '../algorithms/tm_simulator.dart';
import '../models/pda.dart';
import '../models/tm.dart';
import '../result.dart';
import 'simulation_runner_models.dart';
import 'simulation_runner_messages.dart';

SimulationRunnerBackend createSimulationRunnerBackend() =>
    _NativeSimulationRunnerBackend();

class _NativeSimulationRunnerBackend implements SimulationRunnerBackend {
  @override
  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    return _NativeSimulationTask.spawn<
      PDASimulationResult,
      (PDA, String, bool, Duration)
    >(_pdaWorker, (pda, inputString, stepByStep, timeout), classifyPdaResult);
  }

  @override
  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    return _NativeSimulationTask.spawn<
      TMSimulationResult,
      (TM, String, bool, Duration)
    >(_tmWorker, (tm, inputString, stepByStep, timeout), classifyTmResult);
  }
}

class _NativeSimulationTask<T> implements SimulationTask<T> {
  _NativeSimulationTask._(this._classify);

  static _NativeSimulationTask<T> spawn<T, P>(
    void Function((SendPort, P)) entryPoint,
    P payload,
    SimulationOutcome<T> Function(T) classify,
  ) {
    final task = _NativeSimulationTask<T>._(classify);
    task._start(entryPoint, payload);
    return task;
  }

  final SimulationOutcome<T> Function(T) _classify;
  final Completer<SimulationOutcome<T>> _completer = Completer();
  final ReceivePort _receivePort = ReceivePort();
  Isolate? _isolate;
  bool _cancelled = false;

  @override
  Future<SimulationOutcome<T>> get outcome => _completer.future;

  Future<void> _start<P>(
    void Function((SendPort, P)) entryPoint,
    P payload,
  ) async {
    _receivePort.listen(_handleMessage);
    try {
      final isolate = await Isolate.spawn(
        entryPoint,
        (_receivePort.sendPort, payload),
        onError: _receivePort.sendPort,
        onExit: _receivePort.sendPort,
        errorsAreFatal: true,
      );
      if (_cancelled) {
        isolate.kill(priority: Isolate.immediate);
      } else {
        _isolate = isolate;
      }
    } catch (error) {
      _complete(
        SimulationOutcome(
          kind: SimulationOutcomeKind.failed,
          message: error.toString(),
          structuredMessage: SimulationRunnerMessages.startFailed(),
        ),
      );
    }
  }

  void _handleMessage(Object? message) {
    if (_cancelled) return;
    if (message is Result<T>) {
      if (message.isSuccess && message.data != null) {
        _complete(_classify(message.data as T));
      } else {
        _complete(
          SimulationOutcome(
            kind: SimulationOutcomeKind.failed,
            message: message.error,
            structuredMessage:
                message.structuredError ??
                SimulationRunnerMessages.executionFailed(),
          ),
        );
      }
    } else if (message is List<Object?> && message.length == 2) {
      _complete(
        SimulationOutcome(
          kind: SimulationOutcomeKind.failed,
          message: message.first?.toString(),
          structuredMessage: SimulationRunnerMessages.workerFailed(),
        ),
      );
    } else if (message == null) {
      _complete(
        SimulationOutcome(
          kind: SimulationOutcomeKind.failed,
          structuredMessage:
              SimulationRunnerMessages.workerExitedUnexpectedly(),
        ),
      );
    } else {
      _complete(
        SimulationOutcome(
          kind: SimulationOutcomeKind.failed,
          structuredMessage: SimulationRunnerMessages.invalidWorkerResponse(),
        ),
      );
    }
  }

  @override
  void cancel() {
    if (_completer.isCompleted) return;
    _cancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
    _complete(const SimulationOutcome(kind: SimulationOutcomeKind.cancelled));
  }

  void _complete(SimulationOutcome<T> outcome) {
    if (_completer.isCompleted) return;
    _completer.complete(outcome);
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
  }
}

void _pdaWorker((SendPort, (PDA, String, bool, Duration)) message) {
  final (port, payload) = message;
  final (pda, input, stepByStep, timeout) = payload;
  port.send(
    PDASimulator.simulateNPDA(
      pda,
      input,
      stepByStep: stepByStep,
      timeout: timeout,
      mode: pda.acceptanceMode,
    ),
  );
}

void _tmWorker((SendPort, (TM, String, bool, Duration)) message) {
  final (port, payload) = message;
  final (tm, input, stepByStep, timeout) = payload;
  port.send(
    TMSimulator.simulate(tm, input, stepByStep: stepByStep, timeout: timeout),
  );
}
