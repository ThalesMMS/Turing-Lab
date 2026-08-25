import 'package:flutter/material.dart';

import '../../core/models/conversion_step_history.dart';
import '../../core/models/fsa.dart';
import '../../l10n/app_localizations_help.dart';
import 'before_after_comparison.dart';
import 'error_banner.dart';

class FSAConversionComparisonPanel extends StatelessWidget {
  const FSAConversionComparisonPanel({
    super.key,
    required this.history,
    required this.currentAutomaton,
  });

  final ConversionHistory? history;
  final FSA? currentAutomaton;

  @override
  Widget build(BuildContext context) {
    final conversionHistory = history;
    if (conversionHistory == null ||
        conversionHistory.initialSnapshot == null ||
        conversionHistory.finalSnapshot == null ||
        currentAutomaton == null) {
      return const SizedBox.shrink();
    }

    final l10n = jflapLocalizationsOf(context);
    late final FSA beforeAutomaton;
    late final FSA afterAutomaton;
    try {
      beforeAutomaton = FSA.fromJson(conversionHistory.initialSnapshot!);
      afterAutomaton = FSA.fromJson(conversionHistory.finalSnapshot!);
    } catch (error, stackTrace) {
      _logConversionHistoryError(conversionHistory, error, stackTrace);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 112,
          child: ErrorBanner(
            key: const Key('fsa-conversion-comparison-error'),
            message: l10n.conversionComparisonUnavailable,
            severity: ErrorSeverity.warning,
            showRetryButton: false,
            showDismissButton: false,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 320,
        child: BeforeAfterComparison(
          beforeAutomaton: beforeAutomaton,
          afterAutomaton: afterAutomaton,
          transformationDescription: l10n.conversionComparisonResult,
          showStatistics: true,
        ),
      ),
    );
  }

  static void _logConversionHistoryError(
    ConversionHistory history,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[FSAPage] Failed to deserialize conversion comparison history '
      '${history.id}: $error',
    );
    debugPrint(stackTrace.toString());
  }
}
