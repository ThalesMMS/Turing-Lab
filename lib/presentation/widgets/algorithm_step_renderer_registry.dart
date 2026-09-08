//
//  algorithm_step_renderer_registry.dart
//  Turing Lab
//
//  Renderers for algorithm step data. Typed payloads (CYK) are keyed by
//  runtime type; conversion steps are keyed by AlgorithmType and read the
//  generic AlgorithmStep.properties contract produced by toProperties().
//

import 'package:flutter/material.dart';

import '../../core/models/algorithm_step.dart';
import '../../core/models/cyk_step.dart';
import '../../core/models/regex_to_nfa_step.dart'
    show RegexToNFAStepType, RegexToNFAStepTypeExtension;
import '../../core/models/state.dart' as automata;
import '../../core/models/transition.dart';
import '../../core/models/typed_algorithm_step.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'grammar/grammar_sentential_form_card.dart';
import 'step_explanation_card.dart';

typedef AlgorithmStepRenderer =
    Widget Function(BuildContext context, AlgorithmStep step, Object payload);

/// Renders a step from its generic [AlgorithmStep.properties]. Returns null
/// when the properties carry none of the keys the renderer understands so the
/// viewer can fall back to the generic property list.
typedef AlgorithmStepPropertiesRenderer =
    Widget? Function(BuildContext context, AlgorithmStep step);

class AlgorithmStepRendererRegistry {
  final Map<Type, AlgorithmStepRenderer> _renderers = {};
  final Map<AlgorithmType, AlgorithmStepPropertiesRenderer>
  _propertiesRenderers = {};

  AlgorithmStepRendererRegistry();

  factory AlgorithmStepRendererRegistry.withDefaults() {
    return AlgorithmStepRendererRegistry()
      ..register<CYKStep>(_renderCykStep)
      ..registerProperties(AlgorithmType.nfaToDfa, _renderNfaToDfaStep)
      ..registerProperties(
        AlgorithmType.dfaMinimization,
        _renderDfaMinimizationStep,
      )
      ..registerProperties(AlgorithmType.regexToNfa, _renderRegexToNfaStep);
  }

  void register<T>(AlgorithmStepRenderer renderer) {
    _renderers[T] = renderer;
  }

  /// Registers a renderer that reads [AlgorithmStep.properties] for steps of
  /// [type] instead of a typed payload.
  void registerProperties(
    AlgorithmType type,
    AlgorithmStepPropertiesRenderer renderer,
  ) {
    _propertiesRenderers[type] = renderer;
  }

  AlgorithmStepRenderer? lookup(Type payloadType) {
    return _renderers[payloadType];
  }

  AlgorithmStepPropertiesRenderer? lookupProperties(AlgorithmType type) {
    return _propertiesRenderers[type];
  }

  bool hasRenderer(Type payloadType) {
    return _renderers.containsKey(payloadType);
  }

  bool hasPropertiesRenderer(AlgorithmType type) {
    return _propertiesRenderers.containsKey(type);
  }

  void clear() {
    _renderers.clear();
    _propertiesRenderers.clear();
  }

  Widget? render(BuildContext context, AlgorithmStep step) {
    final payload = extractDetectedPayload(step);
    if (payload != null) {
      final renderer = lookup(payload.runtimeType);
      if (renderer != null) {
        return renderer(context, step, payload);
      }
    }
    return lookupProperties(step.type)?.call(context, step);
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

Widget? _renderNfaToDfaStep(BuildContext context, AlgorithmStep step) {
  final properties = step.properties;
  final rows = _compactRows({
    'Operation': _string(properties, 'stepType'),
    'Current states': _labelsOrIds(
      properties,
      'currentStateLabels',
      'currentStateIds',
    ),
    'Processed symbol': _string(properties, 'processedSymbol'),
    'Epsilon closure': _labelsOrIds(
      properties,
      'epsilonClosureLabels',
      'epsilonClosureIds',
    ),
    'Reachable states': _labelsOrIds(
      properties,
      'reachableStateLabels',
      'reachableStateIds',
    ),
    'Next state set': _labelsOrIds(
      properties,
      'nextStateLabels',
      'nextStateIds',
    ),
    'Accepting state': _bool(properties, 'isAcceptingState'),
    'New state': _bool(properties, 'isNewState'),
    'DFA state':
        _string(properties, 'dfaStateLabel') ??
        _string(properties, 'dfaStateId'),
  });
  if (rows.isEmpty) return null;
  return _TypedStepData(title: 'Typed Step Data', rows: rows);
}

Widget? _renderDfaMinimizationStep(BuildContext context, AlgorithmStep step) {
  final properties = step.properties;
  final rows = _compactRows({
    'Operation': _string(properties, 'stepType'),
    'Partition size': _int(properties, 'partitionSize'),
    'Processing set': _labelsOrIds(
      properties,
      'processingSetLabels',
      'processingSetIds',
    ),
    'Distinguishing symbol': _string(properties, 'distinguishingSymbol'),
    'Predecessors': _labelsOrIds(
      properties,
      'predecessorStateLabels',
      'predecessorStateIds',
    ),
    'Split set': _labelsOrIds(properties, 'splitSetLabels', 'splitSetIds'),
    'Caused split': _bool(properties, 'causedSplit'),
    'Equivalence class':
        _labelsOrIds(
          properties,
          'equivalenceClassStateLabels',
          'equivalenceClassStateIds',
        ) ??
        _string(properties, 'equivalenceClassId'),
  });
  if (rows.isEmpty) return null;
  return _TypedStepData(title: 'Typed Step Data', rows: rows);
}

Widget? _renderRegexToNfaStep(BuildContext context, AlgorithmStep step) {
  final properties = step.properties;
  final l10n = appLocalizationsOf(context);
  final stepTypeCode = _string(properties, 'stepTypeCode');
  final stepType = stepTypeCode == null
      ? null
      : RegexToNFAStepType.values.cast<RegexToNFAStepType?>().firstWhere(
          (type) => type!.name == stepTypeCode,
          orElse: () => null,
        );
  final rows = _compactRows({
    'Operation': stepType == null
        ? _string(properties, 'stepType')
        : l10n.resolveStructuredMessage(stepType.labelMessage),
    'Regex fragment': _string(properties, 'regexFragment'),
    'Regex position': _int(properties, 'regexPosition'),
    'Processed symbol': _string(properties, 'processedSymbol'),
    'Created states': _labelsOrIds(
      properties,
      'createdStateLabels',
      'createdStateIds',
    ),
    'Created transitions': _labelsOrIds(
      properties,
      'createdTransitionSummaries',
      'createdTransitionIds',
    ),
    'Fragment start':
        _string(properties, 'fragmentStartStateLabel') ??
        _string(properties, 'fragmentStartStateId'),
    'Fragment accept':
        _string(properties, 'fragmentAcceptStateLabel') ??
        _string(properties, 'fragmentAcceptStateId'),
    'Stack size': _int(properties, 'stackSize'),
    'Final NFA': _bool(properties, 'isFinalNFA'),
  });
  if (rows.isEmpty) return null;
  return _TypedStepData(title: 'Typed Step Data', rows: rows);
}

String? _string(Map<String, dynamic> properties, String key) {
  final value = properties[key];
  return value is String ? value : null;
}

int? _int(Map<String, dynamic> properties, String key) {
  final value = properties[key];
  return value is int ? value : null;
}

bool? _bool(Map<String, dynamic> properties, String key) {
  final value = properties[key];
  return value is bool ? value : null;
}

List<String>? _stringList(Map<String, dynamic> properties, String key) {
  final value = properties[key];
  if (value is! Iterable) return null;
  final items = value.map((item) => item.toString()).toList(growable: false);
  return items.isEmpty ? null : items;
}

/// Prefers the human-readable label list and falls back to the ID list that
/// older persisted steps carry.
List<String>? _labelsOrIds(
  Map<String, dynamic> properties,
  String labelsKey,
  String idsKey,
) {
  return _stringList(properties, labelsKey) ?? _stringList(properties, idsKey);
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
