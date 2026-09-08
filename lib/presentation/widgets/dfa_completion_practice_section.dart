//
//  dfa_completion_practice_section.dart
//  Turing Lab
//
//  Guided practice for completing a DFA by hand. Watches the active automaton
//  and lists the (state, symbol) pairs that still lack a transition, the trap
//  candidates, the next hint, and a reveal action that runs the automatic
//  completion.
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/fsa/dfa_completion_practice.dart';
import '../../core/models/state.dart' as automata;
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../providers/automaton_state_provider.dart';

class DfaCompletionPracticeSection extends ConsumerWidget {
  const DfaCompletionPracticeSection({
    super.key,
    required this.onReveal,
    required this.onClose,
  });

  static const Key revealKey = ValueKey('dfa_practice_reveal');
  static const Key closeKey = ValueKey('dfa_practice_close');
  static const Key statusKey = ValueKey('dfa_practice_status');

  /// Runs the automatic completion; null when no DFA is available.
  final VoidCallback? onReveal;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = appLocalizationsOf(context);
    final theme = Theme.of(context);
    final automaton = ref.watch(automatonStateProvider).currentAutomaton;
    final audit = DfaCompletionPractice.audit(automaton);
    final status = _statusText(l10n, audit);
    final statusColor = switch (audit.status) {
      DfaCompletionPracticeStatus.complete => theme.colorScheme.primary,
      DfaCompletionPracticeStatus.incomplete => theme.colorScheme.error,
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return Card(
      key: const ValueKey('dfa_practice_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.practiceDfaCompletionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (audit.alphabet.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.dfaPracticeGoal('{${audit.alphabet.join(', ')}}'),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                status,
                key: statusKey,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (audit.missing.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final entry in audit.missing)
                Padding(
                  key: ValueKey(
                    'dfa_practice_missing_${entry.state.id}_${entry.symbol}',
                  ),
                  padding: const EdgeInsetsDirectional.only(start: 8, top: 2),
                  child: Text(
                    '• ${l10n.dfaPracticeMissingPair(_label(entry.state), entry.symbol)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
            if (audit.trapCandidates.isNotEmpty &&
                audit.status == DfaCompletionPracticeStatus.incomplete) ...[
              const SizedBox(height: 8),
              Text(
                l10n.dfaPracticeTrapCandidates(
                  audit.trapCandidates.map(_label).join(', '),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (audit.hint case final hint?) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dfaPracticeHintTitle,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hintText(l10n, hint, audit),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: revealKey,
                  onPressed:
                      audit.status == DfaCompletionPracticeStatus.incomplete
                      ? onReveal
                      : null,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(l10n.dfaPracticeReveal),
                ),
                OutlinedButton(
                  key: closeKey,
                  onPressed: onClose,
                  child: Text(l10n.dfaPracticeClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _label(automata.State state) =>
      state.label.isEmpty ? state.id : state.label;

  static String _statusText(AppLocalizations l10n, DfaCompletionAudit audit) {
    return switch (audit.status) {
      DfaCompletionPracticeStatus.noAutomaton => l10n.dfaPracticeNoAutomaton,
      DfaCompletionPracticeStatus.emptyAlphabet =>
        l10n.dfaPracticeEmptyAlphabet,
      DfaCompletionPracticeStatus.notDeterministic =>
        l10n.dfaPracticeNotDeterministic,
      DfaCompletionPracticeStatus.complete => l10n.dfaPracticeComplete,
      DfaCompletionPracticeStatus.incomplete => l10n.dfaPracticeMissingCount(
        audit.missing.length,
      ),
    };
  }

  static String _hintText(
    AppLocalizations l10n,
    DfaCompletionHint hint,
    DfaCompletionAudit audit,
  ) {
    final trap = audit.trapCandidates.isEmpty
        ? ''
        : _label(audit.trapCandidates.first);
    return switch (hint) {
      DfaCompletionHint.createTrapState => l10n.dfaPracticeHintCreateTrap,
      DfaCompletionHint.routeMissingToTrap => l10n.dfaPracticeHintRouteToTrap(
        trap,
      ),
      DfaCompletionHint.loopTrapOnEverySymbol => l10n.dfaPracticeHintLoopTrap(
        trap,
      ),
    };
  }
}
