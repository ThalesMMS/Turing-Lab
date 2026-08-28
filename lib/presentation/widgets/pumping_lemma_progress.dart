//
//  pumping_lemma_progress.dart
//  Turing Lab
//
//  Renders the Pumping Lemma game progress panel with aggregated metrics
//  and recent history. Watches the dedicated provider, computes
//  percentages locally, and presents cards and lists for pedagogical
//  reading.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../../presentation/providers/pumping_lemma_progress_provider.dart';
import '../../core/constants/monospace_typography.dart';
import '../../core/pumping_lemma/pumping_lemma.dart';
import '../content/pumping_lemma_problem_content_copy.dart';
import '../localization/locale_value_formatter.dart';

/// Progress tracking panel for the Pumping Lemma Game.
class PumpingLemmaProgress extends ConsumerWidget {
  const PumpingLemmaProgress({
    super.key,
    this.theorem = PumpingLemmaTheorem.regular,
  });

  final PumpingLemmaTheorem theorem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = theorem == PumpingLemmaTheorem.regular
        ? regularPumpingLemmaProgressProvider
        : contextFreePumpingLemmaProgressProvider;
    final progress = ref.watch(provider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildOverallProgress(context, progress),
            const SizedBox(height: 16),
            _buildStatistics(context, progress),
            const SizedBox(height: 16),
            _buildChallengeHistory(context, progress),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            appLocalizationsOf(context).progressTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallProgress(
    BuildContext context,
    PumpingLemmaProgressState progress,
  ) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final ratio = progress.totalChallenges > 0
        ? progress.completedChallenges / progress.totalChallenges
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizationsOf(context).overallProgress,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Semantics(
            key: const ValueKey('pumping-overall-progress'),
            container: true,
            label: l10n.overallProgress,
            value: formatter.integer((ratio * 100).round()),
            child: ExcludeSemantics(
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatter.integersInLocalizedText(
                    l10n.challengesCompleted(
                      progress.completedChallenges,
                      progress.totalChallenges,
                    ),
                    [progress.completedChallenges, progress.totalChallenges],
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatter.percentFromRatio(ratio, decimalDigits: 0),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(
    BuildContext context,
    PumpingLemmaProgressState progress,
  ) {
    final formatter = LocaleValueFormatter.of(context);
    final accuracy = progress.attempts > 0
        ? progress.score / progress.attempts
        : 0.0;
    final cards = <Widget>[
      _buildStatCard(
        context,
        title: appLocalizationsOf(context).accuracy,
        value: formatter.percentFromRatio(accuracy, decimalDigits: 0),
        icon: Icons.gps_fixed,
        color: _getAccuracyColor(accuracy),
      ),
      _buildStatCard(
        context,
        title: appLocalizationsOf(context).correctCount,
        value: formatter.integer(progress.score),
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      _buildStatCard(
        context,
        title: appLocalizationsOf(context).attempts,
        value: formatter.integer(progress.attempts),
        icon: Icons.quiz,
        color: Colors.blue,
      ),
      _buildStatCard(
        context,
        title: appLocalizationsOf(context).score,
        value:
            '${formatter.integer(progress.score)}/'
            '${formatter.integer(progress.totalChallenges)}',
        icon: Icons.star,
        color: Colors.orange,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizationsOf(context).statistics,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildStatisticsGrid(context, cards),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context, List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBodySize = MediaQuery.textScalerOf(context).scale(14);
        final textScale = scaledBodySize / 14;
        final availableCardWidth = (constraints.maxWidth - 8) / 2;
        final useOneColumn = availableCardWidth < 112 * textScale;
        final cardWidth = useOneColumn
            ? constraints.maxWidth
            : availableCardWidth;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeHistory(
    BuildContext context,
    PumpingLemmaProgressState progress,
  ) {
    final entries = progress.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizationsOf(context).challengeHistory,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          _buildEmptyHistory(context)
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _buildHistoryItem(context, entry, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    PumpingLemmaHistoryEntry entry,
    int index,
  ) {
    switch (entry.type) {
      case PumpingLemmaHistoryType.attempt:
        return _buildAttemptItem(context, entry, index);
      case PumpingLemmaHistoryType.retry:
        return _buildRetryItem(context, entry);
    }
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            appLocalizationsOf(context).noChallengesCompletedYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            appLocalizationsOf(context).completeSomeChallengesHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptItem(
    BuildContext context,
    PumpingLemmaHistoryEntry entry,
    int index,
  ) {
    final color = entry.isCorrect == true ? Colors.green : Colors.red;
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final fallbackTitle = l10n.challengeNumber(entry.challengeId ?? index + 1);
    final title = entry.challengeContentId == null
        ? fallbackTitle
        : PumpingLemmaProblemContentCopies.resolve(
            id: entry.challengeContentId!,
            languageCode: l10n.localeName,
            fallbackTitle: fallbackTitle,
          ).title;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avatar = CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: Text(
              formatter.integer(index + 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (entry.language != null)
                Text(
                  entry.language!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamilyFallback: kMonospaceFontFamilyFallback,
                  ),
                ),
              Text(
                formatter.timeOfDay(entry.timestamp),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          );
          final resultLabel = Text(
            entry.isCorrect == true
                ? appLocalizationsOf(context).correctShort
                : appLocalizationsOf(context).wrong,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          );
          final resultIcon = Icon(
            entry.isCorrect == true ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 20,
          );
          final compactResult = Row(
            mainAxisSize: MainAxisSize.min,
            children: [resultIcon, const SizedBox(width: 4), resultLabel],
          );

          if (constraints.maxWidth < 320) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 44),
                  child: compactResult,
                ),
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: details),
              Column(children: [resultIcon, resultLabel]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRetryItem(BuildContext context, PumpingLemmaHistoryEntry entry) {
    final color = Colors.amber.shade700;
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final fallbackTitle = l10n.challengeFallback('${entry.challengeId ?? '-'}');
    final title = entry.challengeContentId == null
        ? fallbackTitle
        : PumpingLemmaProblemContentCopies.resolve(
            id: entry.challengeContentId!,
            languageCode: l10n.localeName,
            fallbackTitle: fallbackTitle,
          ).title;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: const Icon(Icons.refresh, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalizationsOf(context).retrySelected,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                if (entry.language != null)
                  Text(
                    entry.language!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamilyFallback: kMonospaceFontFamilyFallback,
                    ),
                  ),
                Text(
                  formatter.timeOfDay(entry.timestamp),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
