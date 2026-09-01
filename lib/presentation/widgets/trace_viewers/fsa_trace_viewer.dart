import 'package:flutter/material.dart';

import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';
import '../../../core/services/simulation_highlight_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../empty_string_notation.dart';
import 'base_trace_viewer.dart';
import '../../../core/constants/monospace_typography.dart';

/// FSA-specific presentation layered on the shared trace viewer behavior.
class FsaTraceViewer extends StatelessWidget {
  final SimulationResult result;
  final SimulationHighlightService highlightService;
  final double animationSpeed;

  const FsaTraceViewer({
    super.key,
    required this.result,
    required this.highlightService,
    this.animationSpeed = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: BaseTraceViewer(
        result: result,
        title: l10n.stepByStepExecution,
        highlightService: highlightService,
        animationSpeed: animationSpeed,
        ensureSelectedStepVisible: false,
        buildStepLine: (step, index) => _buildStepLine(
          context,
          step,
          index,
          l10n,
        ),
        detailsBuilder: (context, step, index) => _buildStepDetails(
          context,
          step,
          index,
          l10n,
        ),
      ),
    );
  }

  Widget _buildStepLine(
    BuildContext context,
    SimulationStep step,
    int index,
    AppLocalizations l10n,
  ) {
    final isFinal = index == result.steps.length - 1;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              EmptyStringNotation.format(context, _describeStep(index, l10n)),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isFinal && result.isAccepted)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.tertiary,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildStepDetails(
    BuildContext context,
    SimulationStep step,
    int index,
    AppLocalizations l10n,
  ) {
    final isFinal = index == result.steps.length - 1;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isFinal
        ? (result.isAccepted ? colorScheme.tertiary : colorScheme.error)
        : colorScheme.primary;
    final icon = isFinal
        ? (result.isAccepted ? Icons.check_circle : Icons.cancel)
        : Icons.play_circle;
    final consumed = index == 0 ? null : step.usedTransition;
    final nextState = _nextStateFor(index);
    final remaining = step.remainingInput;
    final emptyStringSymbol = EmptyStringNotation.symbolOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                '${l10n.stepLabel} ${index + 1}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            EmptyStringNotation.format(context, _describeStep(index, l10n)),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (consumed != null) ...[
            const SizedBox(height: 4),
            Text(
              EmptyStringNotation.format(context, l10n.consumedValue(consumed)),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontFamilyFallback: kMonospaceFontFamilyFallback),
            ),
          ],
          if (nextState != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.nextStateValue(_formatState(nextState)),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontFamilyFallback: kMonospaceFontFamilyFallback),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.remainingInputValue(
              remaining.isEmpty ? emptyStringSymbol : '"$remaining"',
            ),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontFamilyFallback: kMonospaceFontFamilyFallback),
          ),
        ],
      ),
    );
  }

  String _describeStep(int index, AppLocalizations l10n) {
    if (index < 0 || index >= result.steps.length) return '';
    final step = result.steps[index];

    if (index == 0) {
      final input =
          step.remainingInput.isEmpty ? 'ε' : '"${step.remainingInput}"';
      return l10n.simulationStartDescription(
        _formatState(step.currentState),
        input,
      );
    }

    if (index == result.steps.length - 1) {
      final verdict =
          result.isAccepted ? l10n.acceptedLower : l10n.rejectedLower;
      return l10n.simulationFinalDescription(
        _formatState(step.currentState),
        verdict,
      );
    }

    final consumed = step.usedTransition ??
        (result.steps[index - 1].remainingInput.isNotEmpty
            ? result.steps[index - 1].remainingInput[0]
            : 'ε');
    final remaining = step.remainingInput.isEmpty
        ? l10n.noInputRemaining
        : l10n.remainingQuoted(step.remainingInput);
    final nextState = _nextStateFor(index) ?? step.currentState;

    return l10n.simulationReadDescription(
      consumed,
      _formatState(step.currentState),
      _formatState(nextState),
      remaining,
    );
  }

  String _formatState(String state) => state.isEmpty ? '∅' : state;

  String? _nextStateFor(int index) {
    if (index + 1 >= result.steps.length) return null;
    return result.steps[index + 1].currentState;
  }
}
