import 'package:flutter/material.dart';

import '../../core/models/tm.dart';
import '../../core/models/tm_reachability_report.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../empty_string_notation.dart';
import '../localization/locale_value_formatter.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_presentation_primitives.dart';

/// Presents structural and bounded-semantic reachability evidence.
class TMReachabilityResultView extends StatelessWidget {
  const TMReachabilityResultView({
    super.key,
    required this.report,
    required this.sourceTm,
  });

  final TMReachabilityReport report;
  final TM? sourceTm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    final tm = sourceTm;
    String localized(String source) => l10n.localizeWorkflowText(source);
    String witnessSummary(TMReachabilityWitness witness) => localizeTMInteger(
      valueFormatter,
      (marker) => l10n.localizeWorkflowText(
        'Input ${witness.input.isEmpty ? EmptyStringNotation.symbolOf(context) : witness.input} '
        '• step $marker',
      ),
      witness.step,
    );
    String stateName(String id) {
      final state = tm?.states
          .where((candidate) => candidate.id == id)
          .firstOrNull;
      if (state == null || state.label.isEmpty || state.label == id) return id;
      return '${state.label} ($id)';
    }

    List<String> names(Set<String> ids) =>
        (ids.map(stateName).toList()..sort());
    final witnesses = report.witnessesByStateId.values.toList()
      ..sort((left, right) {
        final byStep = left.step.compareTo(right.step);
        return byStep != 0 ? byStep : left.stateId.compareTo(right.stateId);
      });
    final incomplete = report.status == TMReachabilityStatus.boundedIncomplete;
    final invalid = report.status == TMReachabilityStatus.invalidMachine;
    final reportMessage = report.structuredMessage == null
        ? report.message
        : l10n.resolveStructuredMessage(report.structuredMessage!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTMFocusBanner(context, TMAnalysisFocus.reachability),
          const SizedBox(height: 12),
          buildTMStatusMessage(
            context,
            message: reportMessage,
            isPositive: report.isComplete,
            isWarning: incomplete,
          ),
          if (invalid) const SizedBox(height: 8),
          buildTMMetricRow(
            context,
            localized('Input scope'),
            report.inputs
                .map(
                  (input) => input.isEmpty
                      ? EmptyStringNotation.symbolOf(context)
                      : input,
                )
                .join(', '),
          ),
          buildTMMetricRow(
            context,
            localized('Semantic exploration'),
            report.isComplete
                ? localized('Complete for this input scope')
                : localized('Incomplete'),
            isWarning: !report.isComplete,
          ),
          buildTMMetricRow(
            context,
            localized('Configurations explored'),
            valueFormatter.integer(report.configurationsExplored),
          ),
          buildTMMetricRow(
            context,
            localized('Transitions explored'),
            valueFormatter.integer(report.transitionsExplored),
          ),
          buildTMMetricRow(
            context,
            localized('Step limit'),
            valueFormatter.integer(report.maxSteps),
          ),
          buildTMMetricRow(
            context,
            localized('Configuration limit'),
            valueFormatter.integer(report.maxConfigurations),
          ),
          buildTMMetricRow(
            context,
            localized('Time limit'),
            '${valueFormatter.integer(report.timeout.inSeconds)} s',
          ),
          if (report.limit != null)
            buildTMMetricRow(
              context,
              localized('Limit reached'),
              localized(report.limit!.name),
              isWarning: true,
            ),
          const SizedBox(height: 12),
          buildTMChipList(
            context,
            label: localized(
              'Structurally reachable (exact over-approximation)',
            ),
            values: names(report.structurallyReachableStateIds),
          ),
          buildTMChipList(
            context,
            label: localized('Reached within bounds'),
            values: names(report.reachedWithinBoundsStateIds),
          ),
          buildTMChipList(
            context,
            label: incomplete
                ? localized('Not observed before a bound stopped exploration')
                : localized('Not observed for this input scope'),
            values: names(report.notObservedWithinBoundsStateIds),
            isWarning: true,
          ),
          buildTMChipList(
            context,
            label: localized('Structurally unreachable (exact)'),
            values: names(report.structurallyUnreachableStateIds),
            isWarning: true,
          ),
          if (witnesses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              localized('Shortest witnesses'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            for (final witness in witnesses)
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  key: Key('tm-reachability-witness-${witness.stateId}'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(stateName(witness.stateId)),
                  subtitle: Semantics(
                    container: true,
                    label: witnessSummary(witness),
                    child: ExcludeSemantics(
                      child: Text(witnessSummary(witness)),
                    ),
                  ),
                  children: [
                    buildTMMetricRow(
                      context,
                      localized('Head position'),
                      valueFormatter.integer(witness.headPosition),
                    ),
                    buildTMMetricRow(
                      context,
                      localized('Read symbol'),
                      witness.readSymbol,
                    ),
                    buildTMMetricRow(
                      context,
                      localized('Incoming transition'),
                      witness.incomingTransitionId ?? l10n.initialConfiguration,
                    ),
                    buildTMChipList(
                      context,
                      label: localized('State trace'),
                      values: witness.stateIds,
                    ),
                    buildTMChipList(
                      context,
                      label: localized('Transition trace'),
                      values: witness.transitionIds,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
