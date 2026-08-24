//
//  graphview_state_notifier_adapter.dart
//  Turing Lab
//
//  Adapts the CRUD surfaces of the FSA, PDA, and TM notifiers for the
//  shared GraphView canvas controller.
//
//  Thales Matheus Mendonça Santos - July 2026
//
import 'package:flutter/material.dart';

/// Adapts a domain notifier's state CRUD surface for shared canvas logic.
class GraphViewStateNotifierAdapter<TSnapshot> {
  const GraphViewStateNotifierAdapter({
    required this.currentData,
    required this.stateIdsOf,
    required this.stateLabelsOf,
    required this.transitionIdsOf,
    required this.addState,
    required this.moveState,
    required this.updateStateLabel,
    required this.updateStateFlags,
    required this.removeState,
    required this.logMutation,
  });

  final TSnapshot? Function() currentData;
  final Iterable<String> Function(TSnapshot data) stateIdsOf;
  final Iterable<String> Function(TSnapshot data) stateLabelsOf;
  final Iterable<String> Function(TSnapshot data) transitionIdsOf;
  final void Function({
    required String id,
    required String label,
    required Offset position,
  }) addState;
  final void Function({required String id, required Offset position}) moveState;
  final void Function({required String id, required String label})
      updateStateLabel;
  final void Function({
    required String id,
    bool? isInitial,
    bool? isAccepting,
  }) updateStateFlags;
  final void Function(String id) removeState;
  final void Function(String message) logMutation;
}
