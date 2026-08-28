import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/transducers/transducers.dart';
import 'transducer_batch_comparison_strings.dart';

typedef TransducerSimulatorFactory<T extends DeterministicFiniteStateTransducer>
    = DeterministicTransducerSimulator Function(T machine);

typedef TransducerComparisonMachineSelector<
        T extends DeterministicFiniteStateTransducer>
    = Future<T?> Function();

enum TransducerComparisonMode { exact, bounded }

final class TransducerBatchComparisonPanel<
    T extends DeterministicFiniteStateTransducer> extends StatefulWidget {
  const TransducerBatchComparisonPanel({
    super.key,
    required this.machine,
    required this.simulatorFor,
    required this.strings,
    this.comparisonMachine,
    this.selectComparisonMachine,
    this.onComparisonMachineChanged,
    this.batchMaxSteps = 100000,
    this.initialBound = 4,
  })  : assert(batchMaxSteps >= 0),
        assert(initialBound >= 0);

  final T machine;
  final TransducerSimulatorFactory<T> simulatorFor;
  final TransducerBatchComparisonStrings strings;
  final T? comparisonMachine;
  final TransducerComparisonMachineSelector<T>? selectComparisonMachine;
  final ValueChanged<T?>? onComparisonMachineChanged;
  final int batchMaxSteps;
  final int initialBound;

  @override
  State<TransducerBatchComparisonPanel<T>> createState() =>
      _TransducerBatchComparisonPanelState<T>();
}

final class _TransducerBatchComparisonPanelState<
        T extends DeterministicFiniteStateTransducer>
    extends State<TransducerBatchComparisonPanel<T>> {
  late final TextEditingController _batchController;
  late final TextEditingController _boundController;
  T? _comparisonMachine;
  TransducerComparisonMode _mode = TransducerComparisonMode.exact;
  TransducerBatchReport? _batchReport;
  TransducerComparisonResult? _comparisonResult;
  String? _batchError;
  String? _boundError;
  String? _selectionError;
  bool _selectingMachine = false;

  @override
  void initState() {
    super.initState();
    _batchController = TextEditingController();
    _boundController = TextEditingController(
      text: widget.initialBound.toString(),
    );
    _comparisonMachine = widget.comparisonMachine;
  }

  @override
  void didUpdateWidget(
    covariant TransducerBatchComparisonPanel<T> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.machine, widget.machine)) {
      _batchReport = null;
      _comparisonResult = null;
    }
    if (!identical(oldWidget.comparisonMachine, widget.comparisonMachine)) {
      _comparisonMachine = widget.comparisonMachine;
      _comparisonResult = null;
      _selectionError = null;
    }
  }

  @override
  void dispose() {
    _batchController.dispose();
    _boundController.dispose();
    super.dispose();
  }

  void _runBatch() {
    final parsed = _parseBatchInput(_batchController.text);
    switch (parsed) {
      case _BatchInputFailure(:final line):
        setState(() {
          _batchError = widget.strings.invalidBatchLine(line);
          _batchReport = null;
        });
      case _BatchInputSuccess(:final inputs):
        setState(() {
          _batchError = null;
          _batchReport = TransducerBatchRunner(
            widget.simulatorFor(widget.machine),
          ).run(inputs, maxSteps: widget.batchMaxSteps);
        });
    }
  }

  Future<void> _selectMachine() async {
    final selector = widget.selectComparisonMachine;
    if (selector == null || _selectingMachine) return;
    setState(() {
      _selectingMachine = true;
      _selectionError = null;
    });
    T? selected;
    try {
      selected = await selector();
    } catch (_) {
      if (mounted) {
        setState(() => _selectionError = widget.strings.machineSelectionFailed);
      }
      return;
    } finally {
      if (mounted) setState(() => _selectingMachine = false);
    }
    if (!mounted || selected == null) return;
    setState(() {
      _comparisonMachine = selected;
      _comparisonResult = null;
      _selectionError = null;
    });
    widget.onComparisonMachineChanged?.call(selected);
  }

  void _compare() {
    final comparisonMachine = _comparisonMachine;
    if (comparisonMachine == null) return;
    late final TransducerComparisonSemantics semantics;
    if (_mode == TransducerComparisonMode.exact) {
      _boundError = null;
      semantics = const ExactTransducerComparison();
    } else {
      final bound = int.tryParse(_boundController.text.trim());
      if (bound == null || bound < 0) {
        setState(() => _boundError = widget.strings.comparisonInvalid);
        return;
      }
      _boundError = null;
      semantics = BoundedTransducerComparison(maxInputLength: bound);
    }
    setState(() {
      _comparisonResult = TransducerEquivalenceComparator.compare(
        widget.simulatorFor(widget.machine),
        widget.simulatorFor(comparisonMachine),
        semantics: semantics,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final batch = FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: _BatchSection(
        strings: widget.strings,
        controller: _batchController,
        errorText: _batchError,
        report: _batchReport,
        onRun: _runBatch,
      ),
    );
    final comparison = FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: _ComparisonSection<T>(
        strings: widget.strings,
        mode: _mode,
        onModeChanged: (mode) => setState(() {
          _mode = mode;
          _comparisonResult = null;
          _boundError = null;
        }),
        boundController: _boundController,
        boundError: _boundError,
        comparisonMachine: _comparisonMachine,
        canSelectMachine: widget.selectComparisonMachine != null,
        selectingMachine: _selectingMachine,
        selectionError: _selectionError,
        onSelectMachine: _selectMachine,
        onCompare: _comparisonMachine == null ? null : _compare,
        result: _comparisonResult,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: batch),
              const SizedBox(width: 24),
              Expanded(child: comparison),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              batch,
              const SizedBox(height: 24),
              comparison,
            ],
          ),
        );
      },
    );
  }
}

final class _BatchSection extends StatelessWidget {
  const _BatchSection({
    required this.strings,
    required this.controller,
    required this.errorText,
    required this.report,
    required this.onRun,
  });

  final TransducerBatchComparisonStrings strings;
  final TextEditingController controller;
  final String? errorText;
  final TransducerBatchReport? report;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) => _PanelCard(
        title: strings.batchTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('transducer_batch_input'),
              controller: controller,
              minLines: 4,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: strings.batchInputLabel,
                helperText: strings.batchInputHelper,
                errorText: errorText,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('run_transducer_batch'),
              onPressed: onRun,
              icon: const Icon(Icons.play_arrow),
              label: Text(strings.runBatch),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (report != null) ...[
              const SizedBox(height: 16),
              TransducerBatchResultsView(
                report: report!,
                strings: strings,
              ),
            ],
          ],
        ),
      );
}

final class _ComparisonSection<T extends DeterministicFiniteStateTransducer>
    extends StatelessWidget {
  const _ComparisonSection({
    required this.strings,
    required this.mode,
    required this.onModeChanged,
    required this.boundController,
    required this.boundError,
    required this.comparisonMachine,
    required this.canSelectMachine,
    required this.selectingMachine,
    required this.selectionError,
    required this.onSelectMachine,
    required this.onCompare,
    required this.result,
  });

  final TransducerBatchComparisonStrings strings;
  final TransducerComparisonMode mode;
  final ValueChanged<TransducerComparisonMode> onModeChanged;
  final TextEditingController boundController;
  final String? boundError;
  final T? comparisonMachine;
  final bool canSelectMachine;
  final bool selectingMachine;
  final String? selectionError;
  final VoidCallback onSelectMachine;
  final VoidCallback? onCompare;
  final TransducerComparisonResult? result;

  @override
  Widget build(BuildContext context) => _PanelCard(
        title: strings.comparisonTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<TransducerComparisonMode>(
              key: const ValueKey('transducer_comparison_mode'),
              initialValue: mode,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.comparisonModeLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: TransducerComparisonMode.exact,
                  child: Text(strings.exactMode),
                ),
                DropdownMenuItem(
                  value: TransducerComparisonMode.bounded,
                  child: Text(strings.boundedMode),
                ),
              ],
              onChanged: (value) {
                if (value != null) onModeChanged(value);
              },
            ),
            if (mode == TransducerComparisonMode.bounded) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('transducer_comparison_bound'),
                controller: boundController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: strings.boundLabel,
                  errorText: boundError,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              comparisonMachine == null
                  ? strings.noComparisonMachine
                  : strings.selectedMachine(comparisonMachine!.name),
              key: const ValueKey('transducer_comparison_machine'),
            ),
            if (canSelectMachine) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('select_transducer_comparison_machine'),
                onPressed: selectingMachine ? null : onSelectMachine,
                icon: selectingMachine
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open),
                label: Text(strings.chooseMachine),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
            if (selectionError != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  selectionError!,
                  key: const ValueKey(
                    'transducer_comparison_machine_selection_error',
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('compare_transducers'),
              onPressed: onCompare,
              icon: const Icon(Icons.compare_arrows),
              label: Text(strings.compare),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 16),
              TransducerComparisonResultView(
                result: result!,
                strings: strings,
              ),
            ],
          ],
        ),
      );
}

final class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      );
}

final class TransducerBatchResultsView extends StatelessWidget {
  const TransducerBatchResultsView({
    super.key,
    required this.report,
    required this.strings,
  });

  final TransducerBatchReport report;
  final TransducerBatchComparisonStrings strings;

  @override
  Widget build(BuildContext context) {
    if (report.items.isEmpty) {
      return Semantics(
        liveRegion: true,
        child: Text(strings.batchEmpty),
      );
    }
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < report.items.length; index++) ...[
            if (index > 0) const Divider(height: 24),
            _BatchResultRow(item: report.items[index], strings: strings),
          ],
        ],
      ),
    );
  }
}

final class _BatchResultRow extends StatelessWidget {
  const _BatchResultRow({required this.item, required this.strings});

  final TransducerBatchItem item;
  final TransducerBatchComparisonStrings strings;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.inputLabel}: ${_inputWordJson(item.input)}'),
          Text(_batchOutcomeLabel(item.outcome, strings)),
          Text('${strings.outputLabel}: ${_outputWordJson(item.output)}'),
        ],
      );
}

final class TransducerComparisonResultView extends StatelessWidget {
  const TransducerComparisonResultView({
    super.key,
    required this.result,
    required this.strings,
  });

  final TransducerComparisonResult result;
  final TransducerBatchComparisonStrings strings;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _comparisonLabel(result, strings),
              key: const ValueKey('transducer_comparison_result'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(strings.exploredPairs(result.exploredPairs)),
            if (result.witness case final witness?)
              Text('${strings.witnessLabel}: ${_inputWordJson(witness)}'),
            if (result.leftOutput case final output?)
              Text('${strings.leftOutputLabel}: ${_outputWordJson(output)}'),
            if (result.rightOutput case final output?)
              Text('${strings.rightOutputLabel}: ${_outputWordJson(output)}'),
          ],
        ),
      );
}

sealed class _BatchInputParseResult {
  const _BatchInputParseResult();
}

final class _BatchInputSuccess extends _BatchInputParseResult {
  const _BatchInputSuccess(this.inputs);

  final List<TransducerInputWord> inputs;
}

final class _BatchInputFailure extends _BatchInputParseResult {
  const _BatchInputFailure(this.line);

  final int line;
}

_BatchInputParseResult _parseBatchInput(String source) {
  final inputs = <TransducerInputWord>[];
  final lines = const LineSplitter().convert(source);
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! List || decoded.any((value) => value is! String)) {
        return _BatchInputFailure(index + 1);
      }
      inputs.add(TransducerInputWord.fromValues(decoded.cast<String>()));
    } catch (_) {
      return _BatchInputFailure(index + 1);
    }
  }
  return _BatchInputSuccess(List.unmodifiable(inputs));
}

String _inputWordJson(TransducerInputWord word) => jsonEncode(word.values);

String _outputWordJson(TransducerOutputWord word) => jsonEncode(word.values);

String _batchOutcomeLabel(
  TransducerExecutionOutcome outcome,
  TransducerBatchComparisonStrings strings,
) =>
    switch (outcome) {
      TransducerSuccess() => strings.batchSuccess,
      TransducerIncomplete() => strings.batchUndefined,
      TransducerInvalidMachine() => strings.batchInvalidMachine,
      TransducerInvalidInput() => strings.batchInvalidInput,
      TransducerCancelled() => strings.batchCancelled,
      TransducerBounded() => strings.batchBounded,
    };

String _comparisonLabel(
  TransducerComparisonResult result,
  TransducerBatchComparisonStrings strings,
) =>
    switch (result.kind) {
      TransducerComparisonKind.equivalent => strings.exactEquivalent,
      TransducerComparisonKind.different when result.isExact =>
        strings.exactDifferent,
      TransducerComparisonKind.different => strings.boundedDifferent,
      TransducerComparisonKind.inconclusive => strings.boundedInconclusive,
      TransducerComparisonKind.invalid => strings.comparisonInvalid,
    };
