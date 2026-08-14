//
//  algorithm_step_highlight_service.dart
//  Turing Lab
//
//  Orquestra a emissão de destaques de passos de algoritmos com suporte a canais
//  plugáveis e dispatchers legados, oferecendo provedores Riverpod para integração
//  com o canvas. Extrai conjuntos de estados e transições relevantes por passo,
//  registra eventos em modo debug e disponibiliza utilidades para reemitir ou
//  limpar seleções durante visualização passo a passo de algoritmos.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/simulation_highlight.dart';
import 'algorithm_step_highlight_extractor.dart';
import 'highlight_channel.dart';

/// Provides access to the algorithm step highlight service associated with the
/// active canvas.
final canvasAlgorithmStepHighlightServiceProvider =
    Provider<AlgorithmStepHighlightService>((ref) {
  return AlgorithmStepHighlightService();
});

class AlgorithmStepHighlightService {
  AlgorithmStepHighlightService({
    HighlightChannel? channel,
    HighlightDispatcher? dispatcher,
  }) : _highlightDispatch = HighlightDispatchController<HighlightChannel>(
          debugLabel: 'AlgorithmStepHighlightService',
          channel: channel,
          dispatcher: dispatcher,
          channelFromDispatcher: FunctionHighlightChannel.new,
        );

  final HighlightDispatchController<HighlightChannel> _highlightDispatch;

  HighlightChannel? get channel => _highlightDispatch.channel;

  set channel(HighlightChannel? value) {
    _highlightDispatch.channel = value;
  }

  /// Number of highlight payloads dispatched since the service was created.
  int get dispatchCount => _highlightDispatch.dispatchCount;

  /// Last highlight payload emitted by the service, if any.
  SimulationHighlight? get lastHighlight => _highlightDispatch.lastHighlight;

  /// Computes a highlight payload from step metadata.
  SimulationHighlight computeFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) {
      _highlightDispatch.log(
        'Skipping highlight computation: no step metadata',
      );
      return SimulationHighlight.empty;
    }

    return _extractHighlightFromMetadata(metadata);
  }

  /// Computes a highlight payload from a list of metadata maps.
  SimulationHighlight computeFromMetadataList(
    List<Map<String, dynamic>> metadataList,
    int stepIndex,
  ) {
    if (metadataList.isEmpty ||
        stepIndex < 0 ||
        stepIndex >= metadataList.length) {
      _highlightDispatch.log(
        'Ignoring highlight request for step $stepIndex (available: ${metadataList.length})',
      );
      return SimulationHighlight.empty;
    }

    return computeFromMetadata(metadataList[stepIndex]);
  }

  /// Emits a highlight event derived from [metadata].
  SimulationHighlight emitFromMetadata(Map<String, dynamic>? metadata) {
    final highlight = computeFromMetadata(metadata);
    _highlightDispatch.log(
      'Computed highlight from metadata (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    dispatch(highlight);
    return highlight;
  }

  /// Emits a highlight event derived from [metadataList] and [stepIndex].
  SimulationHighlight emitFromMetadataList(
    List<Map<String, dynamic>> metadataList,
    int stepIndex,
  ) {
    final highlight = computeFromMetadataList(metadataList, stepIndex);
    _highlightDispatch.log(
      'Computed highlight from metadata list at index $stepIndex (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    dispatch(highlight);
    return highlight;
  }

  /// Dispatches [highlight] to the active canvas highlight channel.
  void dispatch(SimulationHighlight highlight) {
    _highlightDispatch.dispatch(highlight);
  }

  /// Sends a clear highlight event.
  void clear() {
    _highlightDispatch.clear();
  }

  /// Extracts state and transition IDs from step metadata
  SimulationHighlight _extractHighlightFromMetadata(
    Map<String, dynamic> metadata,
  ) {
    return extractAlgorithmStepHighlight(metadata);
  }
}
