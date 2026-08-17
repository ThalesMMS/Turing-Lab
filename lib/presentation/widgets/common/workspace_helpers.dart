import '../../../l10n/app_localizations.dart';

String buildAutomatonWorkspaceStatus({
  required AppLocalizations l10n,
  required int stateCount,
  required int transitionCount,
  required bool hasInitialState,
  required bool hasAcceptingState,
  bool hasNondeterministicTransitions = false,
  bool hasLambdaTransitions = false,
}) {
  if (stateCount == 0 && transitionCount == 0) {
    return l10n.workspaceStatusNoAutomaton;
  }

  final warnings = <String>[
    if (!hasInitialState) l10n.workspaceStatusMissingInitialState,
    if (!hasAcceptingState) l10n.workspaceStatusNoAcceptingStates,
    if (hasNondeterministicTransitions) l10n.workspaceStatusNondeterministic,
    if (hasLambdaTransitions) l10n.workspaceStatusLambdaTransitions,
  ];
  final counts = l10n.workspaceStatusCounts(
    l10n.canvasViewportStateCount(stateCount),
    l10n.canvasViewportTransitionCount(transitionCount),
  );

  if (warnings.isEmpty) {
    return counts;
  }

  return l10n.workspaceStatusWithWarnings(warnings.join(' · '), counts);
}
