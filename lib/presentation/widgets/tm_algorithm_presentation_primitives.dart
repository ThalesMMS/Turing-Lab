import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';
import 'tm_algorithm_execution_controller.dart';

/// Localized banner identifying the report family currently being shown.
class TMAnalysisFocusBanner extends StatelessWidget {
  const TMAnalysisFocusBanner({super.key, required this.focus});

  final TMAnalysisFocus focus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (focus) {
      TMAnalysisFocus.termination => 'Termination and Cycles',
      TMAnalysisFocus.reachability =>
        'Structural and bounded semantic reachability',
      TMAnalysisFocus.language => 'Language Explorer',
      TMAnalysisFocus.tape => 'Tape Trace',
      TMAnalysisFocus.time => 'Time Profile',
      TMAnalysisFocus.space => 'Space Profile',
    };
    final text = appLocalizationsOf(
      context,
    ).localizeWorkflowText('Analysis focus: $label');
    return Semantics(
      container: true,
      header: true,
      label: text,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A localized label/value row shared by report widgets.
class TMMetricRow extends StatelessWidget {
  const TMMetricRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.isWarning = false,
    this.isError = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool isWarning;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = appLocalizationsOf(context);
    final localizedLabel = localizations.localizeWorkflowText(label);
    final localizedValue = localizations.localizeWorkflowText(value);
    Color? valueColor;
    if (isError) {
      valueColor = colorScheme.error;
    } else if (isWarning) {
      valueColor = colorScheme.tertiary;
    } else if (highlight) {
      valueColor = colorScheme.primary;
    }

    return Semantics(
      label: '$localizedLabel: $localizedValue',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  localizedLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Flexible(
                child: Text(
                  localizedValue,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: highlight ? FontWeight.bold : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labeled, localized collection of compact report values.
class TMChipList extends StatelessWidget {
  const TMChipList({
    super.key,
    required this.label,
    required this.values,
    this.isWarning = false,
  });

  final String label;
  final List<String> values;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final localizations = appLocalizationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.localizeWorkflowText(label),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in values)
                Chip(
                  label: Text(localizations.localizeWorkflowText(value)),
                  backgroundColor: isWarning
                      ? colorScheme.errorContainer.withValues(alpha: 0.5)
                      : colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  side: BorderSide(
                    color: isWarning
                        ? colorScheme.error
                        : colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Localized status line with a visual and semantic severity cue.
class TMStatusMessage extends StatelessWidget {
  const TMStatusMessage({
    super.key,
    required this.message,
    this.isWarning = false,
    this.isPositive = false,
  });

  final String message;
  final bool isWarning;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localized = appLocalizationsOf(context).localizeWorkflowText(message);
    final (textColor, icon) = isPositive
        ? (colorScheme.primary, Icons.check_circle_outline)
        : isWarning
        ? (colorScheme.error, Icons.warning_amber_outlined)
        : (colorScheme.onSurfaceVariant, Icons.info_outline);
    return Semantics(
      liveRegion: isWarning,
      label: localized,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  localized,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatTMAnalysisDuration(BuildContext context, Duration duration) {
  final valueFormatter = LocaleValueFormatter.of(context);
  if (duration.inMilliseconds >= 1) {
    return '${valueFormatter.integer(duration.inMilliseconds)} ms';
  }
  if (duration.inMicroseconds >= 1) {
    return '${valueFormatter.integer(duration.inMicroseconds)} μs';
  }
  return '${valueFormatter.integer(duration.inMicroseconds * 1000)} ns';
}

/// Localizes a generated message whose integer placeholder needs display-only
/// grouping. Generated methods interpolate [int] values verbatim, so a marker
/// preserves the translated template while the active locale formats the
/// final value.
String localizeTMInteger(
  LocaleValueFormatter formatter,
  String Function(int marker) localize,
  int value,
) {
  const marker = 987654321;
  return localize(marker).replaceFirst('$marker', formatter.integer(value));
}

Widget buildTMFocusBanner(BuildContext context, TMAnalysisFocus focus) =>
    TMAnalysisFocusBanner(focus: focus);

Widget buildTMMetricRow(
  BuildContext context,
  String label,
  String value, {
  bool highlight = false,
  bool isWarning = false,
  bool isError = false,
}) => TMMetricRow(
  label: label,
  value: value,
  highlight: highlight,
  isWarning: isWarning,
  isError: isError,
);

Widget buildTMChipList(
  BuildContext context, {
  required String label,
  required List<String> values,
  bool isWarning = false,
}) => TMChipList(label: label, values: values, isWarning: isWarning);

Widget buildTMStatusMessage(
  BuildContext context, {
  required String message,
  bool isWarning = false,
  bool isPositive = false,
}) => TMStatusMessage(
  message: message,
  isWarning: isWarning,
  isPositive: isPositive,
);
