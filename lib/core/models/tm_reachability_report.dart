import 'dart:collection';

import '../messages/structured_message.dart';
import 'tm_execution_analysis.dart';

enum TMReachabilityStatus {
  complete,
  boundedIncomplete,
  cancelled,
  invalidMachine,
}

/// Shortest known concrete execution witness for reaching one control state.
class TMReachabilityWitness {
  TMReachabilityWitness({
    required this.stateId,
    required this.input,
    required this.step,
    required this.headPosition,
    required this.readSymbol,
    required this.incomingTransitionId,
    required List<String> stateIds,
    required List<String> transitionIds,
  }) : stateIds = List<String>.unmodifiable(stateIds),
       transitionIds = List<String>.unmodifiable(transitionIds);

  final String stateId;
  final String input;
  final int step;
  final int headPosition;
  final String readSymbol;
  final String? incomingTransitionId;
  final List<String> stateIds;
  final List<String> transitionIds;
}

/// Exact structural reachability plus bounded semantic evidence.
class TMReachabilityReport {
  TMReachabilityReport({
    required List<String> inputs,
    required this.status,
    required this.message,
    required Set<String> structurallyReachableStateIds,
    required Set<String> structurallyUnreachableStateIds,
    required Map<String, TMReachabilityWitness> witnessesByStateId,
    required this.configurationsExplored,
    required this.transitionsExplored,
    required this.maxSteps,
    required this.maxConfigurations,
    required this.timeout,
    required this.executionTime,
    this.limit,
    this.structuredMessage,
  }) : inputs = List<String>.unmodifiable(inputs),
       structurallyReachableStateIds = Set<String>.unmodifiable(
         structurallyReachableStateIds,
       ),
       structurallyUnreachableStateIds = Set<String>.unmodifiable(
         structurallyUnreachableStateIds,
       ),
       witnessesByStateId = UnmodifiableMapView(
         Map<String, TMReachabilityWitness>.from(witnessesByStateId),
       );

  final List<String> inputs;
  final TMReachabilityStatus status;
  final String message;
  final Set<String> structurallyReachableStateIds;
  final Set<String> structurallyUnreachableStateIds;
  final Map<String, TMReachabilityWitness> witnessesByStateId;
  final int configurationsExplored;
  final int transitionsExplored;
  final int maxSteps;
  final int maxConfigurations;
  final Duration timeout;
  final Duration executionTime;
  final TMExecutionLimit? limit;

  /// Locale-neutral semantic payload for [message], when available.
  final StructuredMessage? structuredMessage;

  Set<String> get reachedWithinBoundsStateIds =>
      Set<String>.unmodifiable(witnessesByStateId.keys);

  Set<String> get notObservedWithinBoundsStateIds => Set<String>.unmodifiable(
    structurallyReachableStateIds.difference(reachedWithinBoundsStateIds),
  );

  bool get isComplete => status == TMReachabilityStatus.complete;
}
