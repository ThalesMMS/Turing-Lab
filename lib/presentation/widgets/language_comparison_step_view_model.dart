//
//  language_comparison_step_view_model.dart
//  Turing Lab
//
//  Adapts the untyped algorithm-step maps produced by LanguageComparator into
//  typed view models before they reach the widget tree. Every known payload
//  becomes a recognized kind with named details; unknown payloads keep a
//  clearly identified fallback instead of being rendered as raw maps.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/material.dart';

/// Semantic family of a comparison step, which drives its icon and accent.
enum LanguageComparisonStepKind {
  validation,
  alphabet,
  conversion,
  product,
  search,
  counterexample,
  result,
  error,
  unknown;

  /// Stable, locale-independent key used by semantic identifiers and tests.
  String get semanticsValue => name;
}

/// A single labelled fact attached to a comparison step.
@immutable
class LanguageComparisonStepDetail {
  const LanguageComparisonStepDetail(this.label, this.value);

  /// English source label, localized through the workflow prose bridge.
  final String label;

  /// Already formatted value; state labels and symbols are shown verbatim.
  final String value;
}

/// Typed presentation of one entry of a comparison trace.
@immutable
class LanguageComparisonStepViewModel {
  const LanguageComparisonStepViewModel({
    required this.stepNumber,
    required this.kind,
    required this.title,
    required this.description,
    required this.details,
  });

  final int stepNumber;
  final LanguageComparisonStepKind kind;

  /// English source title, localized through the workflow prose bridge.
  final String title;

  /// English source description straight from the trace payload.
  final String description;

  final List<LanguageComparisonStepDetail> details;

  /// Adapts one raw trace entry.
  ///
  /// [fallbackStepNumber] is used when the payload carries no usable step
  /// number, so numbering stays contiguous even for malformed traces.
  factory LanguageComparisonStepViewModel.fromPayload(
    Map<String, dynamic> payload, {
    required int fallbackStepNumber,
  }) {
    final rawType = payload['type']?.toString() ?? '';
    final data = _stepDataMap(payload['data']);
    final stepNumber = _stepNumber(payload['stepNumber'], fallbackStepNumber);
    final description = payload['description']?.toString() ?? '';

    switch (rawType) {
      case 'validation':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.validation,
          title: 'Validation',
          description: description,
          details: [
            if (data['automatonA'] != null)
              LanguageComparisonStepDetail(
                'Automaton A',
                _formatStepValue(data['automatonA']),
              ),
            if (data['automatonB'] != null)
              LanguageComparisonStepDetail(
                'Automaton B',
                _formatStepValue(data['automatonB']),
              ),
          ],
        );
      case 'initialization':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.validation,
          title: 'Initialization',
          description: description,
          details: const [],
        );
      case 'alphabet_normalization':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.alphabet,
          title: 'Alphabet Normalization',
          description: description,
          details: [
            LanguageComparisonStepDetail(
              'Automaton A alphabet',
              _formatStepValue(data['alphabetA']),
            ),
            LanguageComparisonStepDetail(
              'Automaton B alphabet',
              _formatStepValue(data['alphabetB']),
            ),
            LanguageComparisonStepDetail(
              'Shared alphabet',
              _formatStepValue(data['sharedAlphabet']),
            ),
          ],
        );
      case 'nfa_to_dfa':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.conversion,
          title: 'DFA Conversion',
          description: description,
          details: [
            if (data['automaton'] != null)
              LanguageComparisonStepDetail(
                'Automaton',
                _formatStepValue(data['automaton']),
              ),
            LanguageComparisonStepDetail(
              'States',
              _formatBeforeAfter(data['statesBefore'], data['statesAfter']),
            ),
          ],
        );
      case 'dfa_completion':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.conversion,
          title: 'DFA Completion',
          description: description,
          details: [
            if (data['automaton'] != null)
              LanguageComparisonStepDetail(
                'Automaton',
                _formatStepValue(data['automaton']),
              ),
            LanguageComparisonStepDetail(
              'States',
              _formatBeforeAfter(data['statesBefore'], data['statesAfter']),
            ),
            if (data['wasCompleted'] != null)
              LanguageComparisonStepDetail(
                'Sink state',
                data['wasCompleted'] == true ? 'added' : 'not needed',
              ),
          ],
        );
      case 'product_construction_start':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.product,
          title: 'Product Construction',
          description: description,
          details: [
            if (data['alphabetSize'] != null)
              LanguageComparisonStepDetail(
                'Alphabet size',
                _formatStepValue(data['alphabetSize']),
              ),
          ],
        );
      case 'product_state_created':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.product,
          title: 'Product State Created',
          description: description,
          details: [
            LanguageComparisonStepDetail(
              'State pair',
              _formatStatePair(data['stateA'], data['stateB']),
            ),
            if (data['productState'] != null)
              LanguageComparisonStepDetail(
                'Product state',
                _formatStepValue(data['productState']),
              ),
            if (data['isAccepting'] != null)
              LanguageComparisonStepDetail(
                'Accepting',
                _formatBoolean(data['isAccepting']),
              ),
          ],
        );
      case 'product_transition_created':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.product,
          title: 'Product Transition',
          description: description,
          details: [
            LanguageComparisonStepDetail(
              'Transition',
              '${_formatStepValue(data['fromState'])} -> '
                  '${_formatStepValue(data['toState'])}',
            ),
            if (data['symbol'] != null)
              LanguageComparisonStepDetail(
                'Symbol',
                _formatSymbol(data['symbol']),
              ),
            if (data['targetIsNew'] != null)
              LanguageComparisonStepDetail(
                'Target',
                data['targetIsNew'] == true ? 'new' : 'existing',
              ),
          ],
        );
      case 'product_construction_complete':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.product,
          title: 'Product Construction Complete',
          description: description,
          details: [
            LanguageComparisonStepDetail(
              'States',
              _formatStepValue(data['totalStates']),
            ),
            LanguageComparisonStepDetail(
              'Transitions',
              _formatStepValue(data['totalTransitions']),
            ),
            LanguageComparisonStepDetail(
              'Accepting states',
              _formatStepValue(data['acceptingStates']),
            ),
          ],
        );
      case 'bfs_search_start':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.search,
          title: 'BFS Search',
          description: description,
          details: [
            LanguageComparisonStepDetail(
              'Initial pair',
              _formatStatePair(data['initialStateA'], data['initialStateB']),
            ),
          ],
        );
      case 'bfs_initial_check':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.search,
          title: 'Initial Pair Check',
          description: description,
          details: [
            LanguageComparisonStepDetail(
              'State pair',
              _formatStatePair(data['stateA'], data['stateB']),
            ),
            LanguageComparisonStepDetail(
              'Acceptance',
              _formatAcceptance(data['acceptsA'], data['acceptsB']),
            ),
          ],
        );
      case 'bfs_explore_pair':
      case 'bfs_exploration':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.search,
          title: 'State Pair Visit',
          description: description,
          details: [
            if (data['stateA'] != null || data['stateB'] != null)
              LanguageComparisonStepDetail(
                'State pair',
                _formatStatePair(data['stateA'], data['stateB']),
              ),
            if (data['currentPath'] != null)
              LanguageComparisonStepDetail(
                'Path',
                _formatPath(data['currentPath']),
              ),
            if (data['pathLength'] != null)
              LanguageComparisonStepDetail(
                'Path length',
                _formatStepValue(data['pathLength']),
              ),
          ],
        );
      case 'bfs_distinguishing_found':
      case 'counterexample_found':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.counterexample,
          title: 'Counterexample Found',
          description: description,
          details: [
            if (data['distinguishingString'] != null)
              LanguageComparisonStepDetail(
                'Distinguishing string',
                _formatDisplayString(data['distinguishingString']),
              ),
            if (data['stateA'] != null || data['stateB'] != null)
              LanguageComparisonStepDetail(
                'State pair',
                _formatStatePair(data['stateA'], data['stateB']),
              ),
            if (data['acceptsA'] != null || data['acceptsB'] != null)
              LanguageComparisonStepDetail(
                'Acceptance',
                _formatAcceptance(data['acceptsA'], data['acceptsB']),
              ),
            if (data['symbol'] != null)
              LanguageComparisonStepDetail(
                'Symbol',
                _formatSymbol(data['symbol']),
              ),
          ],
        );
      case 'bfs_complete':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.search,
          title: 'BFS Complete',
          description: description,
          details: [
            if (data['totalPairsExplored'] != null)
              LanguageComparisonStepDetail(
                'Pairs explored',
                _formatStepValue(data['totalPairsExplored']),
              ),
          ],
        );
      case 'result':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: data['isEquivalent'] == true
              ? LanguageComparisonStepKind.result
              : LanguageComparisonStepKind.counterexample,
          title: 'Comparison Result',
          description: description,
          details: [
            if (data['isEquivalent'] != null)
              LanguageComparisonStepDetail(
                'Equivalent',
                _formatBoolean(data['isEquivalent']),
              ),
            if (data['distinguishingString'] != null)
              LanguageComparisonStepDetail(
                'Distinguishing string',
                _formatDisplayString(data['distinguishingString']),
              ),
          ],
        );
      case 'error':
      case 'comparison_error':
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.error,
          title: 'Comparison Error',
          description: description,
          details: [
            if (data['reason'] != null)
              LanguageComparisonStepDetail(
                'Reason',
                _formatStepValue(data['reason']),
              ),
            if (data['stage'] != null)
              LanguageComparisonStepDetail(
                'Stage',
                _formatStepValue(data['stage']),
              ),
            if (data['message'] != null)
              LanguageComparisonStepDetail(
                'Message',
                _formatStepValue(data['message']),
              ),
          ],
        );
      default:
        return LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: LanguageComparisonStepKind.unknown,
          title: 'Unknown Step',
          description: description,
          details: [
            LanguageComparisonStepDetail(
              'Raw type',
              rawType.isEmpty ? 'untyped' : rawType,
            ),
            for (final entry in data.entries)
              LanguageComparisonStepDetail(
                entry.key,
                _formatStepValue(entry.value),
              ),
          ],
        );
    }
  }

  IconData get icon {
    return switch (kind) {
      LanguageComparisonStepKind.validation => Icons.rule,
      LanguageComparisonStepKind.alphabet => Icons.sort_by_alpha,
      LanguageComparisonStepKind.conversion => Icons.transform,
      LanguageComparisonStepKind.product => Icons.grid_on,
      LanguageComparisonStepKind.search => Icons.manage_search,
      LanguageComparisonStepKind.counterexample => Icons.warning_amber,
      LanguageComparisonStepKind.result => Icons.check_circle,
      LanguageComparisonStepKind.error => Icons.error_outline,
      LanguageComparisonStepKind.unknown => Icons.help_outline,
    };
  }

  Color accentColor(ColorScheme colorScheme) {
    return switch (kind) {
      LanguageComparisonStepKind.validation => colorScheme.primary,
      LanguageComparisonStepKind.alphabet => colorScheme.secondary,
      LanguageComparisonStepKind.conversion => colorScheme.tertiary,
      LanguageComparisonStepKind.product => colorScheme.tertiary,
      LanguageComparisonStepKind.search => colorScheme.primary,
      LanguageComparisonStepKind.counterexample => colorScheme.error,
      LanguageComparisonStepKind.result => colorScheme.primary,
      LanguageComparisonStepKind.error => colorScheme.error,
      LanguageComparisonStepKind.unknown => colorScheme.outline,
    };
  }
}

Map<String, dynamic> _stepDataMap(Object? rawData) {
  if (rawData is Map) {
    return rawData.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

int _stepNumber(Object? rawStepNumber, int fallbackStepNumber) {
  if (rawStepNumber is int) return rawStepNumber;
  if (rawStepNumber is num) return rawStepNumber.toInt();
  if (rawStepNumber is String) {
    return int.tryParse(rawStepNumber) ?? fallbackStepNumber;
  }
  return fallbackStepNumber;
}

String _formatBeforeAfter(Object? before, Object? after) {
  if (before == null && after == null) return 'unknown';
  return '${_formatStepValue(before)} -> ${_formatStepValue(after)}';
}

String _formatStatePair(Object? stateA, Object? stateB) {
  if (stateA == null && stateB == null) return 'unknown';
  return '${_formatStepValue(stateA)} / ${_formatStepValue(stateB)}';
}

String _formatAcceptance(Object? acceptsA, Object? acceptsB) {
  if (acceptsA is bool && acceptsB is bool) {
    final a = acceptsA ? 'accepts' : 'rejects';
    final b = acceptsB ? 'accepts' : 'rejects';
    return 'A $a, B $b';
  }
  return 'unknown';
}

String _formatBoolean(Object? value) {
  if (value is bool) return value ? 'yes' : 'no';
  return _formatStepValue(value);
}

String _formatSymbol(Object? value) {
  final symbol = _formatStepValue(value);
  return symbol.isEmpty ? 'ε' : symbol;
}

String _formatPath(Object? value) {
  final path = _formatStepValue(value);
  return path.isEmpty ? 'ε' : path;
}

String _formatDisplayString(Object? value) {
  final string = _formatStepValue(value);
  return string.isEmpty ? 'ε (empty string)' : '"$string"';
}

String _formatStepValue(Object? value) {
  if (value == null) return 'unknown';
  if (value is Iterable) {
    return value.map(_formatStepValue).join(', ');
  }
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${_formatStepValue(entry.value)}')
        .join(', ');
  }
  return value.toString();
}
