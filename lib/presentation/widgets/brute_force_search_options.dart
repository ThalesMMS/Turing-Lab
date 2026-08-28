import 'package:flutter/material.dart';

import '../../core/models/brute_force_parse_models.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';

class BruteForceSearchOptions extends StatelessWidget {
  const BruteForceSearchOptions({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.depthController,
    required this.frontierController,
    required this.resultCapController,
    required this.timeLimitController,
    required this.onLimitsChanged,
    this.progress,
  });

  final BruteForceDerivationMode mode;
  final ValueChanged<BruteForceDerivationMode> onModeChanged;
  final TextEditingController depthController;
  final TextEditingController frontierController;
  final TextEditingController resultCapController;
  final TextEditingController timeLimitController;
  final VoidCallback onLimitsChanged;
  final BruteForceSearchProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final fields = <Widget>[
      _NumberField(
        key: const ValueKey('brute-force-depth-limit'),
        controller: depthController,
        label: l10n.localizeWorkflowText('Maximum depth'),
        onChanged: onLimitsChanged,
      ),
      _NumberField(
        key: const ValueKey('brute-force-frontier-limit'),
        controller: frontierController,
        label: l10n.localizeWorkflowText('Maximum frontier size'),
        onChanged: onLimitsChanged,
      ),
      _NumberField(
        key: const ValueKey('brute-force-result-cap'),
        controller: resultCapController,
        label: l10n.localizeWorkflowText('Witness limit'),
        onChanged: onLimitsChanged,
      ),
      _NumberField(
        key: const ValueKey('brute-force-time-limit'),
        controller: timeLimitController,
        label: l10n.localizeWorkflowText('Time limit (ms)'),
        onChanged: onLimitsChanged,
      ),
    ];

    return Card.outlined(
      key: const ValueKey('brute-force-search-options'),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.localizeWorkflowText('Bounded search options'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BruteForceDerivationMode>(
              key: const ValueKey('brute-force-derivation-mode'),
              initialValue: mode,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.localizeWorkflowText('Derivation mode'),
              ),
              items: BruteForceDerivationMode.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        l10n.localizeWorkflowText(switch (value) {
                          BruteForceDerivationMode.leftmost => 'Leftmost',
                          BruteForceDerivationMode.rightmost => 'Rightmost',
                          BruteForceDerivationMode.allPositions =>
                            'All positions',
                        }),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) onModeChanged(value);
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 560
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: fields
                      .map((field) => SizedBox(width: width, child: field))
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.localizeWorkflowText(
                'Recursive grammars can grow quickly. A reached limit is inconclusive, not rejection.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (progress case final progress?) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.localizeWorkflowText(
                    'Searching: ${formatter.integer(progress.statistics.exploredNodes)} '
                    'explored, ${formatter.integer(progress.statistics.frontierSize)} '
                    'queued, ${formatter.integer(progress.witnessCount)} witnesses',
                  ),
                  key: const ValueKey('brute-force-live-progress'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
