//
//  simulation_input_request_provider.dart
//  Turing Lab
//
//  Carries a suggested simulation input from an example surface to the
//  simulation field of the same workspace. The request is keyed by the
//  workspace's stable FormalSystemKey so no other workspace applies it, and
//  it stays pending until a matching simulation panel consumes it.
//

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';

@immutable
class SimulationInputRequest {
  const SimulationInputRequest({
    required this.id,
    required this.workspace,
    required this.exampleId,
    required this.input,
  });

  /// Monotonic identifier so consumers can acknowledge exactly one request.
  final int id;
  final FormalSystemKey workspace;
  final String exampleId;

  /// Input exactly as suggested by the example catalog.
  final String input;

  @override
  bool operator ==(Object other) =>
      other is SimulationInputRequest &&
      other.id == id &&
      other.workspace == workspace &&
      other.exampleId == exampleId &&
      other.input == input;

  @override
  int get hashCode => Object.hash(id, workspace, exampleId, input);
}

class SimulationInputRequestNotifier
    extends StateNotifier<SimulationInputRequest?> {
  SimulationInputRequestNotifier() : super(null);

  int _nextId = 0;

  /// Publishes a new request, replacing any pending one.
  SimulationInputRequest publish({
    required FormalSystemKey workspace,
    required String exampleId,
    required String input,
  }) {
    final request = SimulationInputRequest(
      id: ++_nextId,
      workspace: workspace,
      exampleId: exampleId,
      input: input,
    );
    state = request;
    return request;
  }

  /// Clears the pending request when it still carries [id].
  void consume(int id) {
    if (state?.id == id) {
      state = null;
    }
  }
}

final simulationInputRequestProvider =
    StateNotifierProvider<
      SimulationInputRequestNotifier,
      SimulationInputRequest?
    >((ref) => SimulationInputRequestNotifier());
