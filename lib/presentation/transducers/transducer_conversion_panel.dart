//
//  transducer_conversion_panel.dart
//  Turing Lab
//
//  Mealy ↔ Moore conversion tools: explains the equivalence contract,
//  converts the active machine, reports whether the result is exact or
//  differs by the Moore initial output, lists the construction steps with
//  bounded differential evidence, and opens the result in the other
//  transducer workspace.
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/transducers/transducers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/workspace_registry_provider.dart';
import '../widgets/app_snackbar.dart';
import 'mealy_workspace_definition.dart';
import 'moore_workspace_definition.dart';

/// Words up to this length are simulated on both machines as evidence.
const int kTransducerConversionEvidenceLength = 4;
const int _evidenceBatchSize = 32;

/// Upper bound on the words simulated for the evidence summary, so a wide
/// input alphabet cannot make the conversion enumerate
/// |Σ|^[kTransducerConversionEvidenceLength] inputs.
const int kTransducerConversionEvidenceMaxWords = 2000;

final class TransducerConversionPanel extends ConsumerStatefulWidget {
  const TransducerConversionPanel({super.key, required this.machine});

  static const Key convertKey = ValueKey('transducer_conversion_convert');
  static const Key openKey = ValueKey('transducer_conversion_open');

  final DeterministicFiniteStateTransducer machine;

  @override
  ConsumerState<TransducerConversionPanel> createState() =>
      _TransducerConversionPanelState();
}

final class _TransducerConversionPanelState
    extends ConsumerState<TransducerConversionPanel> {
  TransducerConversionResult<Object>? _result;
  DeterministicFiniteStateTransducer? _convertedFrom;
  ({int words, TransducerInputWord? mismatch, bool truncated})? _evidence;

  bool get _isMealy => widget.machine is MealyMachine;

  @override
  void didUpdateWidget(covariant TransducerConversionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.machine, widget.machine) &&
        !identical(_convertedFrom, widget.machine)) {
      // A different document invalidates a report computed for another one.
      setState(() {
        _result = null;
        _evidence = null;
        _convertedFrom = null;
      });
    }
  }

  Future<void> _convert() async {
    final machine = widget.machine;
    final TransducerConversionResult<Object> result = switch (machine) {
      final MealyMachine mealy => TransducerConverter.mealyToMoore(mealy),
      final MooreMachine moore => TransducerConverter.mooreToMealy(moore),
      _ => throw StateError('Unsupported transducer'),
    };
    setState(() {
      _result = result;
      _convertedFrom = machine;
      _evidence = null;
    });
    if (result is! TransducerConversionReport<Object>) return;
    final evidence = await _collectEvidence(machine, result);
    if (!mounted || !identical(_result, result)) return;
    setState(() => _evidence = evidence);
  }

  Future<({int words, TransducerInputWord? mismatch, bool truncated})?>
  _collectEvidence(
    DeterministicFiniteStateTransducer source,
    TransducerConversionReport<Object> report,
  ) async {
    final left = _simulatorFor(source);
    final right = _simulatorFor(
      report.machine as DeterministicFiniteStateTransducer,
    );
    final prefix = report.droppedInitialOutput?.values ?? const <String>[];
    final alphabet = source.inputAlphabet.map((s) => s.value).toList()..sort();
    var words = <List<String>>[[]];
    var batchTruncated = false;
    var count = 0;
    for (
      var length = 0;
      length <= kTransducerConversionEvidenceLength;
      length++
    ) {
      for (final word in words) {
        // Yield before the first batch and between batches on every platform.
        if (count % _evidenceBatchSize == 0) {
          await Future<void>.delayed(Duration.zero);
          if (!mounted || !identical(_result, report)) return null;
        }
        final input = TransducerInputWord.fromValues(word);
        final l = left.run(input);
        final r = right.run(input);
        count++;
        // The Mealy result never emits the Moore initial output, so the
        // Moore side is compared after that prefix in either direction.
        final mooreOutput = source is MooreMachine ? l.output : r.output;
        final mealyOutput = source is MooreMachine ? r.output : l.output;
        final expected = [...prefix, ...mealyOutput.values];
        if (l.runtimeType != r.runtimeType ||
            !_listEquals(mooreOutput.values, expected)) {
          return (words: count, mismatch: input, truncated: false);
        }
      }
      if (count >= kTransducerConversionEvidenceMaxWords) {
        return (
          words: count,
          mismatch: null,
          truncated:
              batchTruncated ||
              (length < kTransducerConversionEvidenceLength &&
                  alphabet.isNotEmpty),
        );
      }
      // The last generation is never simulated, so do not allocate it.
      if (length == kTransducerConversionEvidenceLength) break;
      // Generate lazily so the word budget also bounds allocation.
      final remaining = kTransducerConversionEvidenceMaxWords - count;
      batchTruncated = words.length * alphabet.length > remaining;
      words = words
          .expand((word) => alphabet.map((symbol) => [...word, symbol]))
          .take(remaining)
          .toList();
    }
    return (words: count, mismatch: null, truncated: false);
  }

  static DeterministicTransducerSimulator _simulatorFor(
    DeterministicFiniteStateTransducer machine,
  ) => switch (machine) {
    final MealyMachine mealy => DeterministicTransducerSimulator.mealy(mealy),
    final MooreMachine moore => DeterministicTransducerSimulator.moore(moore),
    _ => throw StateError('Unsupported transducer'),
  };

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _openResult(TransducerConversionReport<Object> report) async {
    final l10n = appLocalizationsOf(context);
    final targetKey = _isMealy
        ? TransducerFormalSystemIds.moore
        : TransducerFormalSystemIds.mealy;
    final destinationHasMachine = _isMealy
        ? ref.read(mooreEditorProvider).document.states.isNotEmpty
        : ref.read(mealyEditorProvider).document.states.isNotEmpty;
    if (destinationHasMachine) {
      final replace =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.conversionReplaceTitle),
              content: Text(l10n.transducerConversionReplaceMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.replaceInput),
                ),
              ],
            ),
          ) ??
          false;
      if (!replace || !mounted) return;
    }
    final workspaceIndex = ref
        .read(workspacePresentationRegistryProvider)
        .indexOfKey(targetKey);
    if (workspaceIndex == null) return;
    if (_isMealy) {
      ref
          .read(mooreEditorProvider.notifier)
          .replaceDocument(report.machine as MooreMachine);
    } else {
      ref
          .read(mealyEditorProvider.notifier)
          .replaceDocument(report.machine as MealyMachine);
    }
    ref.read(homeNavigationProvider.notifier).setIndex(workspaceIndex);
    if (!mounted) return;
    showAppSnackBar(
      context,
      message: l10n.transducerConversionOpened(_isMealy ? 'Moore' : 'Mealy'),
      tone: AppSnackBarTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final theme = Theme.of(context);
    final result = _result;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.transducerConversionContract,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            _isMealy
                ? l10n.transducerConversionMealyToMooreHint
                : l10n.transducerConversionMooreToMealyHint,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: TransducerConversionPanel.convertKey,
            onPressed: widget.machine.states.isEmpty ? null : _convert,
            icon: const Icon(Icons.swap_horiz),
            label: Text(
              _isMealy
                  ? l10n.transducerConvertToMoore
                  : l10n.transducerConvertToMealy,
            ),
          ),
          if (result is TransducerConversionFailure<Object>) ...[
            const SizedBox(height: 12),
            Text(
              l10n.transducerConversionRejected,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            for (final diagnostic in result.diagnostics)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${l10n.resolveStructuredMessage(diagnostic.structuredMessage)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
          if (result is TransducerConversionReport<Object>)
            _buildReport(context, l10n, theme, result),
        ],
      ),
    );
  }

  Widget _buildReport(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    TransducerConversionReport<Object> report,
  ) {
    final target = report.machine as DeterministicFiniteStateTransducer;
    final evidence = _evidence;
    final exact = report.outcome == TransducerConversionOutcome.exact;
    return Column(
      key: const ValueKey('transducer_conversion_report'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            exact
                ? l10n.transducerConversionExact
                : l10n.transducerConversionConventionDifference(
                    renderOutputWord(report.droppedInitialOutput!),
                  ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: exact
                  ? theme.colorScheme.primary
                  : theme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.transducerConversionSummary(
            report.sourceStateCount,
            report.sourceTransitionCount,
            target.states.length,
            target.transitions.length,
          ),
          style: theme.textTheme.bodySmall,
        ),
        if (evidence == null) ...[
          const SizedBox(height: 4),
          const LinearProgressIndicator(),
        ],
        if (evidence != null) ...[
          const SizedBox(height: 4),
          Text(
            evidence.mismatch == null
                ? evidence.truncated
                      ? l10n.transducerConversionEvidenceTruncated(
                          evidence.words,
                        )
                      : l10n.transducerConversionEvidence(
                          evidence.words,
                          kTransducerConversionEvidenceLength,
                        )
                : l10n.transducerConversionEvidenceMismatch(
                    evidence.mismatch!.values.isEmpty
                        ? 'λ'
                        : evidence.mismatch!.values.join(' '),
                  ),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: TransducerConversionPanel.openKey,
          onPressed: () => _openResult(report),
          icon: const Icon(Icons.open_in_new),
          label: Text(
            _isMealy
                ? l10n.transducerConversionOpenMoore
                : l10n.transducerConversionOpenMealy,
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.transducerConversionSteps, style: theme.textTheme.titleSmall),
        for (final (index, step) in report.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${index + 1}. ${_stepText(l10n, step)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  static String _stepText(
    AppLocalizations l10n,
    TransducerConversionStep step,
  ) => switch (step.kind) {
    TransducerConversionStepKind.createStateCopy =>
      l10n.transducerConversionStepCreateCopy(
        step.detail ?? step.subject,
        step.subject,
        step.output ?? 'λ',
      ),
    TransducerConversionStepKind.mapTransition =>
      l10n.transducerConversionStepMapTransition(
        step.subject,
        step.output ?? 'λ',
        step.detail ?? '',
      ),
    TransducerConversionStepKind.carryTargetOutput =>
      l10n.transducerConversionStepCarryOutput(
        step.subject,
        step.output ?? 'λ',
        step.detail ?? '',
      ),
    TransducerConversionStepKind.dropInitialOutput =>
      l10n.transducerConversionStepDropInitial(
        step.output ?? 'λ',
        step.subject,
      ),
    TransducerConversionStepKind.pruneUnreachableCopy =>
      l10n.transducerConversionStepPrune(step.subject),
  };
}
