//
//  algorithm_step_renderer_registry.dart
//  Turing Lab
//
//  Type-keyed renderers for algorithm step payloads.
//

import 'package:flutter/material.dart';

import '../../core/models/algorithm_step.dart';
import '../../core/models/cyk_step.dart';
import '../../core/models/dfa_minimization_step.dart';
import '../../core/models/nfa_to_dfa_step.dart';
import '../../core/models/regex_to_nfa_step.dart';
import '../../core/models/state.dart' as automata;
import '../../core/models/transition.dart';
import '../../core/models/typed_algorithm_step.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'grammar_sentential_form_card.dart';
import 'step_explanation_card.dart';

typedef AlgorithmStepRenderer =
    Widget Function(BuildContext context, AlgorithmStep step, Object payload);

class AlgorithmStepRendererRegistry {
  final Map<Type, AlgorithmStepRenderer> _renderers = {};

  AlgorithmStepRendererRegistry();

  factory AlgorithmStepRendererRegistry.withDefaults() {
    return AlgorithmStepRendererRegistry()
      ..register<CYKStep>(_renderCykStep)
      ..register<NFAToDFAStep>(_renderNfaToDfaStep)
      ..register<DFAMinimizationStep>(_renderDfaMinimizationStep)
      ..register<RegexToNFAStep>(_renderRegexToNfaStep);
  }

  void register<T>(AlgorithmStepRenderer renderer) {
    _renderers[T] = renderer;
  }

  AlgorithmStepRenderer? lookup(Type payloadType) {
    return _renderers[payloadType];
  }

  bool hasRenderer(Type payloadType) {
    return _renderers.containsKey(payloadType);
  }

  void clear() {
    _renderers.clear();
  }

  Widget? render(BuildContext context, AlgorithmStep step) {
    final payload = extractDetectedPayload(step);
    if (payload == null) return null;

    final renderer = lookup(payload.runtimeType);
    return renderer?.call(context, step, payload);
  }
}

Widget _renderCykStep(
  BuildContext context,
  AlgorithmStep step,
  Object payload,
) {
  final typedStep = payload as CYKStep;
  final stepExplanation = typedStep.baseStep.stepExplanation;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (stepExplanation != null && !stepExplanation.isEmpty) ...[
        GrammarSententialFormCard(explanation: stepExplanation),
        const SizedBox(height: 8),
        StepExplanationCard(explanation: stepExplanation),
        const SizedBox(height: 8),
      ],
      _TypedStepData(
        title: 'CYK Step Data',
        rows: _compactRows({
          'Operation': typedStep.stepType.displayName,
          'Cell': typedStep.cellCoordinates,
          'Substring': typedStep.substring,
          'Terminal': typedStep.terminal,
          'Split point': typedStep.splitPoint,
          'Left cell': _cellCoordinates(typedStep.leftRow, typedStep.leftCol),
          'Right cell': _cellCoordinates(
            typedStep.rightRow,
            typedStep.rightCol,
          ),
          'Left variables': typedStep.leftNonTerminals,
          'Right variables': typedStep.rightNonTerminals,
          'Production': typedStep.productionSummary,
          'Added variable': typedStep.addedNonTerminal,
          'Cell variables': typedStep.cellNonTerminals,
          'Accepted': typedStep.isAccepted ? true : null,
          'Cell modified': typedStep.cellModified ? true : null,
        }),
      ),
    ],
  );
}

Widget _renderNfaToDfaStep(
  BuildContext context,
  AlgorithmStep step,
  Object payload,
) {
  final typedStep = payload as NFAToDFAStep;
  return _TypedStepData(
    title: 'Typed Step Data',
    rows: _compactRows({
      'Operation': typedStep.stepType.displayName,
      'Current states': typedStep.currentStateSet,
      'Processed symbol': typedStep.processedSymbol,
      'Epsilon closure': typedStep.epsilonClosure,
      'Reachable states': typedStep.reachableStates,
      'Next state set': typedStep.nextStateSet,
      'Accepting state': typedStep.isAcceptingState,
      'New state': typedStep.isNewState,
      'DFA state': typedStep.dfaStateLabel ?? typedStep.dfaStateId,
    }),
  );
}

Widget _renderDfaMinimizationStep(
  BuildContext context,
  AlgorithmStep step,
  Object payload,
) {
  final typedStep = payload as DFAMinimizationStep;
  return _TypedStepData(
    title: 'Typed Step Data',
    rows: _compactRows({
      'Operation': typedStep.stepType.displayName,
      'Partition size': typedStep.partitionSize,
      'Processing set': typedStep.processingSet,
      'Distinguishing symbol': typedStep.distinguishingSymbol,
      'Predecessors': typedStep.predecessors,
      'Split set': typedStep.splitSet,
      'Caused split': typedStep.causedSplit,
      'Equivalence class':
          typedStep.equivalenceClassStates ?? typedStep.equivalenceClassId,
    }),
  );
}

Widget _renderRegexToNfaStep(
  BuildContext context,
  AlgorithmStep step,
  Object payload,
) {
  final typedStep = payload as RegexToNFAStep;
  final l10n = appLocalizationsOf(context);
  return _TypedStepData(
    title: 'Typed Step Data',
    rows: _compactRows({
      'Operation': l10n.resolveStructuredMessage(
        typedStep.stepType.labelMessage,
      ),
      'Regex fragment': typedStep.regexFragment,
      'Regex position': typedStep.regexPosition,
      'Processed symbol': typedStep.processedSymbol,
      'Created states': typedStep.createdStates,
      'Created transitions': typedStep.createdTransitions,
      'Fragment start': typedStep.fragmentStartState,
      'Fragment accept': typedStep.fragmentAcceptState,
      'Stack size': typedStep.stackSize,
      'Final NFA': typedStep.isFinalNFA,
    }),
  );
}

List<_TypedStepRow> _compactRows(Map<String, Object?> values) {
  return values.entries
      .where((entry) => entry.value != null)
      .map((entry) => _TypedStepRow(entry.key, entry.value))
      .toList(growable: false);
}

String _formatTypedValue(Object? value) {
  if (value == null) return '';
  if (value is String) return value.isEmpty ? 'ε' : value;
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is automata.State) return value.label;
  if (value is Transition) {
    return '${value.fromState.label} → ${value.toState.label} (${value.label})';
  }
  if (value is Iterable) {
    final items = value.map(_formatTypedValue).toList();
    return items.isEmpty ? '∅' : items.join(', ');
  }

  return value.toString();
}

String? _cellCoordinates(int? row, int? col) {
  if (row == null || col == null) return null;
  return '[$row][$col]';
}

class _TypedStepRow {
  final String label;
  final Object? value;

  const _TypedStepRow(this.label, this.value);
}

class _TypedStepData extends StatelessWidget {
  final String title;
  final List<_TypedStepRow> rows;

  const _TypedStepData({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.data_object, size: 18, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.localizeWorkflowText(title),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      l10n.localizeWorkflowText(row.label),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _localizeTypedValue(l10n, row.value),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

String _localizeTypedValue(AppLocalizations l10n, Object? value) {
  if (value is bool) return value ? l10n.yes : l10n.no;
  if (value is String) {
    if (value == 'Yes' || value == 'No') return value;
    return l10n.localizeWorkflowText(_formatTypedValue(value));
  }
  if (value is automata.State || value is Transition) {
    return _formatTypedValue(value);
  }
  if (value is Iterable) {
    final items = value
        .map((item) => _localizeTypedValue(l10n, item))
        .toList(growable: false);
    return items.isEmpty ? '∅' : items.join(', ');
  }
  return _formatTypedValue(value);
}
