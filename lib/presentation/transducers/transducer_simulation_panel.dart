import 'package:flutter/material.dart';

import '../../core/models/simulation_highlight.dart';
import '../../core/services/highlight_channel.dart';
import '../../core/transducers/transducers.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../widgets/base_simulation_panel.dart';
import 'graphview_transducer_canvas_controller.dart';
import 'transducer_editor_state.dart';
import 'transducer_workspace_definition.dart';

final class TransducerSimulationPanel<
  TMachine extends DeterministicFiniteStateTransducer
>
    extends StatefulWidget {
  const TransducerSimulationPanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.controller,
    required this.definition,
    this.highlightChannel,
    this.scrollController,
    this.inputFocusNode,
    this.showTitle = true,
    this.onViewOnCanvas,
  });

  final TransducerEditorState<TMachine> state;
  final TransducerEditorNotifier<TMachine> notifier;
  final GraphViewTransducerCanvasController<TMachine> controller;
  final HighlightChannel? highlightChannel;
  final TransducerWorkspaceDefinition<TMachine> definition;
  final ScrollController? scrollController;
  final FocusNode? inputFocusNode;
  final bool showTitle;

  /// Starts the on-canvas playback for the given execution trace; when null,
  /// the panel offers no view-on-canvas affordance.
  final ValueChanged<List<TransducerExecutionStep>>? onViewOnCanvas;

  @override
  State<TransducerSimulationPanel<TMachine>> createState() =>
      _TransducerSimulationPanelState<TMachine>();
}

final class _TransducerSimulationPanelState<
  TMachine extends DeterministicFiniteStateTransducer
>
    extends State<TransducerSimulationPanel<TMachine>> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _maxStepsController = TextEditingController(
    text: '100000',
  );
  final FocusNode _maxStepsFocus = FocusNode();
  TransducerCancellationToken? _cancellationToken;
  bool _isRunning = false;
  String? _maxStepsError;
  int _runGeneration = 0;

  @override
  void didUpdateWidget(
    covariant TransducerSimulationPanel<TMachine> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.document.id != widget.state.document.id ||
        oldWidget.state.document.revision != widget.state.document.revision) {
      _cancellationToken?.cancel();
      _runGeneration++;
      _cancellationToken = null;
      _isRunning = false;
      _highlights.clear();
    }
  }

  @override
  void dispose() {
    _cancellationToken?.cancel();
    _inputController.dispose();
    _maxStepsController.dispose();
    _maxStepsFocus.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final tokens = _inputController.text
        .split('\n')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    final maxSteps = int.tryParse(_maxStepsController.text);
    if (maxSteps == null || maxSteps < 0) {
      setState(
        () => _maxStepsError = appLocalizationsOf(
          context,
        ).transducerMaximumStepsInvalid,
      );
      _maxStepsFocus.requestFocus();
      return;
    }
    setState(() => _maxStepsError = null);
    final token = TransducerCancellationToken();
    final generation = ++_runGeneration;
    setState(() {
      _cancellationToken = token;
      _isRunning = true;
    });
    final outcome = await widget.definition
        .simulator(widget.state.document)
        .runAsync(
          TransducerInputWord.fromValues(tokens),
          options: TransducerSimulationOptions(
            maxSteps: maxSteps,
            cancellationToken: token,
          ),
        );
    if (!mounted ||
        generation != _runGeneration ||
        !identical(_cancellationToken, token)) {
      return;
    }
    setState(() {
      _isRunning = false;
      _cancellationToken = null;
    });
    widget.notifier.setExecution(outcome);
    _highlight(outcome.trace.isEmpty ? null : outcome.trace.first);
  }

  void _selectStep(int index) {
    widget.notifier.setTraceIndex(index);
    _highlight(widget.state.lastExecution!.trace[index]);
  }

  void _highlight(TransducerExecutionStep? step) {
    if (step == null) {
      _highlights.clear();
      return;
    }
    _highlights.send(
      SimulationHighlight(
        stateIds: {step.targetStateId.value},
        transitionIds: {step.transitionId.value},
      ),
    );
  }

  HighlightChannel get _highlights =>
      widget.highlightChannel ??
      GraphViewSimulationHighlightChannel(widget.controller);

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final outcome = widget.state.lastExecution;
    final header = <Widget>[
      if (widget.showTitle) ...[
        Text(
          l10n.transducerSimulationTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        key: const Key('transducer-simulation-input'),
        controller: _inputController,
        focusNode: widget.inputFocusNode,
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(
          labelText: l10n.transducerInputTokens,
          helperText: l10n.transducerInputTokensHint,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('transducer-simulation-max-steps'),
        controller: _maxStepsController,
        focusNode: _maxStepsFocus,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.transducerMaximumSteps,
          errorText: _maxStepsError,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Wrap(
          spacing: 8,
          children: [
            if (_isRunning)
              OutlinedButton.icon(
                key: const Key('transducer-cancel-run'),
                onPressed: _cancellationToken?.cancel,
                icon: const Icon(Icons.stop),
                label: Text(l10n.transducerCancel),
              ),
            FilledButton.icon(
              key: const Key('transducer-run'),
              onPressed: _isRunning ? null : _run,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.transducerRun),
            ),
          ],
        ),
      ),
      if (outcome != null) ...[
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          container: true,
          excludeSemantics: true,
          label: _outcomeMessage(l10n, outcome),
          child: Text(_outcomeMessage(l10n, outcome)),
        ),
        const SizedBox(height: 8),
        SelectableText(
          '${l10n.transducerOutput}: ${_outputText(l10n, outcome.output)}',
          key: const Key('transducer-simulation-output'),
        ),
        if (widget.onViewOnCanvas != null && outcome.trace.isNotEmpty) ...[
          const SizedBox(height: 8),
          SimulationViewOnCanvasButton(
            onPressed: () => widget.onViewOnCanvas!(
              List<TransducerExecutionStep>.unmodifiable(outcome.trace),
            ),
          ),
        ],
        const Divider(height: 24),
        if (outcome.trace.isEmpty) Text(l10n.transducerNoTrace),
      ],
    ];
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: header),
        ),
        if (outcome != null && outcome.trace.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList.builder(
              itemCount: outcome.trace.length,
              itemBuilder: (context, index) => _TraceStepTile(
                step: outcome.trace[index],
                selected: widget.state.activeTraceIndex == index,
                onSelected: () => _selectStep(index),
              ),
            ),
          ),
      ],
    );
  }
}

String _outcomeMessage(
  AppLocalizations l10n,
  TransducerExecutionOutcome outcome,
) => l10n.resolveStructuredMessage(outcome.structuredMessage);

String _outputText(AppLocalizations l10n, TransducerOutputWord output) =>
    output.values.isEmpty
    ? l10n.transducerEmptyOutput
    : output.values.join(' · ');

final class _TraceStepTile extends StatelessWidget {
  const _TraceStepTile({
    required this.step,
    required this.selected,
    required this.onSelected,
  });

  final TransducerExecutionStep step;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final label = l10n.transducerTraceStep(
      step.index + 1,
      step.sourceStateId.value,
      step.targetStateId.value,
      step.transitionId.value,
    );
    final details = l10n.transducerTraceDetails(
      step.consumedInput.value,
      _inputText(l10n, step.remainingInput),
      _outputText(l10n, step.emittedOutput),
      _outputText(l10n, step.cumulativeOutput),
    );
    return Semantics(
      selected: selected,
      button: true,
      excludeSemantics: true,
      label: '$label. $details',
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          selected: selected,
          minTileHeight: 48,
          onTap: onSelected,
          leading: CircleAvatar(child: Text('${step.index + 1}')),
          title: Text(label),
          subtitle: Text(details),
        ),
      ),
    );
  }
}

String _inputText(AppLocalizations l10n, TransducerInputSuffix input) =>
    input.isEmpty
    ? l10n.transducerEmptyInput
    : l10n.transducerRemainingInputPreview(
        input.previewValues(8).join(' · '),
        input.length,
      );
