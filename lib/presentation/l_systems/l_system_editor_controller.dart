import 'package:flutter/foundation.dart';

import '../../core/l_systems/l_systems.dart';
import '../../core/messages/structured_message.dart';

enum LSystemEditorStatus {
  idle,
  expanding,
  complete,
  bounded,
  cancelled,
  invalid,
}

final class LSystemEditorController extends ChangeNotifier {
  LSystemEditorController({
    required LSystemDocument document,
    LSystemExpander expander = const LSystemExpander(),
    LSystemTurtleInterpreter turtleInterpreter =
        const LSystemTurtleInterpreter(),
  }) : _document = document,
       _expander = expander,
       _turtleInterpreter = turtleInterpreter;

  final LSystemExpander _expander;
  final LSystemTurtleInterpreter _turtleInterpreter;
  final List<LSystemDocument> _undo = [];
  final List<LSystemDocument> _redo = [];

  LSystemDocument _document;
  LSystemEditorStatus _status = LSystemEditorStatus.idle;
  LSystemGeneration? _generation;
  LSystemGeometry? _geometry;
  List<StructuredMessage> _messages = const [];
  LSystemCancellationToken? _cancellationToken;
  int _requestRevision = 0;

  LSystemDocument get document => _document;
  LSystemEditorStatus get status => _status;
  LSystemGeneration? get generation => _generation;
  LSystemGeometry? get geometry => _geometry;
  List<StructuredMessage> get messages => List.unmodifiable(_messages);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get isExpanding => _status == LSystemEditorStatus.expanding;

  void replaceDocument(LSystemDocument next, {bool recordHistory = true}) {
    _cancelActive();
    if (recordHistory) {
      _undo.add(_document);
      _redo.clear();
    }
    _document = next;
    _generation = null;
    _geometry = null;
    _messages = const [];
    _status = LSystemEditorStatus.idle;
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    final previous = _undo.removeLast();
    _redo.add(_document);
    replaceDocument(previous, recordHistory: false);
  }

  void redo() {
    if (_redo.isEmpty) return;
    final next = _redo.removeLast();
    _undo.add(_document);
    replaceDocument(next, recordHistory: false);
  }

  void cancel() {
    if (_cancellationToken == null) return;
    _cancelActive();
    _status = LSystemEditorStatus.cancelled;
    _messages = [_executionMessage('expansion-cancelled')];
    notifyListeners();
  }

  Future<void> run({
    int? generation,
    LSystemExpansionLimits limits = const LSystemExpansionLimits(),
  }) async {
    _cancelActive();
    final request = ++_requestRevision;
    final token = LSystemCancellationToken();
    _cancellationToken = token;
    _status = LSystemEditorStatus.expanding;
    _messages = const [];
    notifyListeners();
    final effectiveLimits = LSystemExpansionLimits(
      maximumGenerations: limits.maximumGenerations,
      maximumSymbols: limits.maximumSymbols,
      maximumEstimatedBytes: limits.maximumEstimatedBytes,
      maximumElapsed: limits.maximumElapsed,
      retainGenerations: limits.retainGenerations,
      maximumRetainedGenerations: limits.maximumRetainedGenerations,
      cancellationToken: token,
      cancellationCheckpoint: limits.cancellationCheckpoint,
      elapsedProvider: limits.elapsedProvider,
    );
    final outcome = await _expander.expandAsync(
      _document,
      generations: generation,
      limits: effectiveLimits,
    );
    if (request != _requestRevision || token.isCancelled) return;
    _cancellationToken = null;
    _generation = outcome.finalGeneration;
    switch (outcome) {
      case LSystemExpansionCompleted():
        _status = _render(outcome.finalGeneration);
      case LSystemExpansionBounded():
        final renderStatus = _render(outcome.finalGeneration);
        if (renderStatus == LSystemEditorStatus.complete) {
          _status = LSystemEditorStatus.bounded;
          _messages = [
            _executionMessage(
              'expansion-bounded',
              severity: StructuredMessageSeverity.warning,
              arguments: {
                'kind': StructuredMessageArgument.outcome(
                  outcome.kind.name,
                  role: 'expansion-limit-kind',
                ),
                'maximum': StructuredMessageArgument.bound(outcome.maximum),
                'estimate': StructuredMessageArgument.integer(
                  outcome.estimate,
                  role: 'estimated-resource-use',
                ),
              },
            ),
          ];
        } else {
          _status = renderStatus;
        }
      case LSystemExpansionCancelled():
        _status = LSystemEditorStatus.cancelled;
        _messages = [_executionMessage('expansion-cancelled')];
      case LSystemExpansionInvalid():
        _status = LSystemEditorStatus.invalid;
        _messages = [
          for (final diagnostic in outcome.diagnostics)
            diagnostic.structuredMessage,
        ];
    }
    notifyListeners();
  }

  LSystemEditorStatus _render(LSystemGeneration generation) {
    final rendered = _turtleInterpreter.interpret(
      generation.word,
      settings: _document.turtle,
      mapping: _document.commandMapping,
    );
    switch (rendered) {
      case LSystemTurtleCompleted():
        _geometry = rendered.geometry;
        return LSystemEditorStatus.complete;
      case LSystemTurtleCancelled():
        _geometry = null;
        _messages = [_executionMessage('rendering-cancelled')];
        return LSystemEditorStatus.cancelled;
      case LSystemTurtleBounded():
        _geometry = null;
        _messages = [
          _executionMessage(
            'rendering-bounded',
            severity: StructuredMessageSeverity.warning,
            arguments: {
              'maximum': StructuredMessageArgument.bound(
                rendered.maximumSegments,
                role: 'segment-limit',
              ),
              'processed': StructuredMessageArgument.count(
                rendered.processedSymbols,
                role: 'processed-symbol-count',
              ),
            },
          ),
        ];
        return LSystemEditorStatus.bounded;
      case LSystemTurtleInvalid():
        _geometry = null;
        _messages = [
          for (final diagnostic in rendered.diagnostics)
            diagnostic.structuredMessage,
        ];
        return LSystemEditorStatus.invalid;
    }
  }

  void _cancelActive() {
    _cancellationToken?.cancel();
    _cancellationToken = null;
    _requestRevision++;
  }

  @override
  void dispose() {
    _cancelActive();
    super.dispose();
  }
}

StructuredMessage _executionMessage(
  String code, {
  StructuredMessageSeverity severity = StructuredMessageSeverity.information,
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'l-system.execution',
  code: code,
  category: StructuredMessageCategory.simulation,
  severity: severity,
  arguments: arguments,
);
