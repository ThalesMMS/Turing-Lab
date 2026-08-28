import '../core/models/computation_branch.dart';
import '../core/models/language_comparison_outcome.dart';
import '../presentation/widgets/computation_branch_inspector.dart';
import '../presentation/widgets/language_comparison_step_view_model.dart';
import 'app_localizations.dart';

/// Typed localized copy for automata diagnostics and language comparison.
extension AutomataDiagnosticsLocalizations on AppLocalizations {
  ComputationBranchInspectorLabels get computationBranchInspectorLabels =>
      _LocalizedComputationBranchInspectorLabels(this);

  String languageComparisonFailureReason(
    LanguageComparisonFailureReason reason,
  ) => switch (reason) {
    LanguageComparisonFailureReason.malformedInput =>
      languageComparisonInvalidInput,
    LanguageComparisonFailureReason.determinization ||
    LanguageComparisonFailureReason.normalization ||
    LanguageComparisonFailureReason.productConstruction =>
      languageComparisonConversionFailed,
    LanguageComparisonFailureReason.timeout => timeout,
    LanguageComparisonFailureReason.stateLimit =>
      languageComparisonLimitReached,
    LanguageComparisonFailureReason.internalError =>
      languageComparisonAnalysisFailed,
  };

  String languageComparisonFailureExplanation(
    LanguageComparisonFailureReason reason,
  ) => switch (reason) {
    LanguageComparisonFailureReason.malformedInput =>
      languageComparisonFailureMalformedExplanation,
    LanguageComparisonFailureReason.determinization =>
      languageComparisonFailureDeterminizationExplanation,
    LanguageComparisonFailureReason.normalization =>
      languageComparisonFailureNormalizationExplanation,
    LanguageComparisonFailureReason.productConstruction =>
      languageComparisonFailureProductExplanation,
    LanguageComparisonFailureReason.timeout =>
      languageComparisonFailureTimeoutExplanation,
    LanguageComparisonFailureReason.stateLimit =>
      languageComparisonFailureStateLimitExplanation,
    LanguageComparisonFailureReason.internalError =>
      languageComparisonFailureInternalExplanation,
  };

  String languageComparisonStatus(LanguageComparisonStatus status) =>
      switch (status) {
        LanguageComparisonStatus.equivalent => equivalent,
        LanguageComparisonStatus.notEquivalent => notEquivalent,
        LanguageComparisonStatus.inconclusive => languageComparisonInconclusive,
        LanguageComparisonStatus.error => languageComparisonAnalysisFailed,
      };

  LocalizedLanguageComparisonStep localizeLanguageComparisonStep(
    LanguageComparisonStepViewModel step,
  ) {
    final data = step.data;
    final unknown = languageComparisonValueUnknown;
    String value(Object? raw) => _formalValue(raw, unknown);
    String statePair(Object? first, Object? second) =>
        languageComparisonValueStatePair(value(first), value(second));
    String beforeAfter(Object? before, Object? after) =>
        languageComparisonValueBeforeAfter(value(before), value(after));
    String boolean(Object? raw) => raw is bool ? (raw ? yes : no) : value(raw);
    String acceptance(Object? first, Object? second) =>
        first is bool && second is bool
        ? languageComparisonValueAcceptance(first.toString(), second.toString())
        : unknown;
    String displayString(Object? raw) {
      final formal = raw?.toString() ?? '';
      return formal.isEmpty ? emptyStringEpsilon : formal;
    }

    return switch (step.type) {
      LanguageComparisonStepType.validation => LocalizedLanguageComparisonStep(
        title: languageComparisonStepValidation,
        description: languageComparisonDescriptionValidation,
        details: [
          if (data['automatonA'] != null)
            LanguageComparisonStepDetail(automatonA, value(data['automatonA'])),
          if (data['automatonB'] != null)
            LanguageComparisonStepDetail(automatonB, value(data['automatonB'])),
        ],
      ),
      LanguageComparisonStepType.initialization =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepInitialization,
          description: languageComparisonDescriptionInitialization,
          details: const [],
        ),
      LanguageComparisonStepType.alphabetNormalization =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepAlphabetNormalization,
          description: languageComparisonDescriptionAlphabet,
          details: [
            LanguageComparisonStepDetail(
              languageComparisonDetailAutomatonAAlphabet,
              value(data['alphabetA']),
            ),
            LanguageComparisonStepDetail(
              languageComparisonDetailAutomatonBAlphabet,
              value(data['alphabetB']),
            ),
            LanguageComparisonStepDetail(
              languageComparisonDetailSharedAlphabet,
              value(data['sharedAlphabet']),
            ),
          ],
        ),
      LanguageComparisonStepType.nfaToDfa => LocalizedLanguageComparisonStep(
        title: languageComparisonStepDfaConversion,
        description: languageComparisonDescriptionNfaToDfa(
          value(data['automaton']),
        ),
        details: [
          if (data['automaton'] != null)
            LanguageComparisonStepDetail(
              languageComparisonDetailAutomaton,
              value(data['automaton']),
            ),
          LanguageComparisonStepDetail(
            states,
            beforeAfter(data['statesBefore'], data['statesAfter']),
          ),
        ],
      ),
      LanguageComparisonStepType.dfaCompletion =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepDfaCompletion,
          description: languageComparisonDescriptionDfaCompletion(
            value(data['automaton']),
          ),
          details: [
            if (data['automaton'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailAutomaton,
                value(data['automaton']),
              ),
            LanguageComparisonStepDetail(
              states,
              beforeAfter(data['statesBefore'], data['statesAfter']),
            ),
            if (data['wasCompleted'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailSinkState,
                data['wasCompleted'] == true
                    ? languageComparisonValueAdded
                    : languageComparisonValueNotNeeded,
              ),
          ],
        ),
      LanguageComparisonStepType.productConstructionStart =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepProductConstruction,
          description: languageComparisonDescriptionProductStart,
          details: [
            if (data['alphabetSize'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailAlphabetSize,
                value(data['alphabetSize']),
              ),
          ],
        ),
      LanguageComparisonStepType.productStateCreated =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepProductStateCreated,
          description: languageComparisonDescriptionProductState(
            value(data['productState']),
          ),
          details: [
            LanguageComparisonStepDetail(
              languageComparisonDetailStatePair,
              statePair(data['stateA'], data['stateB']),
            ),
            if (data['productState'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailProductState,
                value(data['productState']),
              ),
            if (data['isAccepting'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailAccepting,
                boolean(data['isAccepting']),
              ),
          ],
        ),
      LanguageComparisonStepType.productTransitionCreated =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepProductTransition,
          description: languageComparisonDescriptionProductTransition(
            value(data['symbol']),
          ),
          details: [
            LanguageComparisonStepDetail(
              transitionLabel,
              languageComparisonValueBeforeAfter(
                value(data['fromState']),
                value(data['toState']),
              ),
            ),
            if (data['symbol'] != null)
              LanguageComparisonStepDetail(symbolLabel, value(data['symbol'])),
            if (data['targetIsNew'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailTarget,
                data['targetIsNew'] == true
                    ? languageComparisonValueNew
                    : languageComparisonValueExisting,
              ),
          ],
        ),
      LanguageComparisonStepType.productConstructionComplete =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepProductComplete,
          description: languageComparisonDescriptionProductComplete,
          details: [
            LanguageComparisonStepDetail(states, value(data['totalStates'])),
            LanguageComparisonStepDetail(
              transitions,
              value(data['totalTransitions']),
            ),
            LanguageComparisonStepDetail(
              languageComparisonDetailAcceptingStates,
              value(data['acceptingStates']),
            ),
          ],
        ),
      LanguageComparisonStepType.bfsSearchStart =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepBfsSearch,
          description: languageComparisonDescriptionBfsStart,
          details: [
            LanguageComparisonStepDetail(
              languageComparisonDetailInitialPair,
              statePair(data['initialStateA'], data['initialStateB']),
            ),
          ],
        ),
      LanguageComparisonStepType.bfsInitialCheck =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepInitialPairCheck,
          description: languageComparisonDescriptionInitialCheck(
            (data['acceptsA'] != data['acceptsB']).toString(),
          ),
          details: [
            LanguageComparisonStepDetail(
              languageComparisonDetailStatePair,
              statePair(data['stateA'], data['stateB']),
            ),
            LanguageComparisonStepDetail(
              languageComparisonDetailAcceptance,
              acceptance(data['acceptsA'], data['acceptsB']),
            ),
          ],
        ),
      LanguageComparisonStepType.bfsExplorePair =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepStatePairVisit,
          description: languageComparisonDescriptionExplorePair(
            value(data['stateA']),
            value(data['stateB']),
          ),
          details: [
            if (data['stateA'] != null || data['stateB'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailStatePair,
                statePair(data['stateA'], data['stateB']),
              ),
            if (data['currentPath'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailPath,
                displayString(data['currentPath']),
              ),
            if (data['pathLength'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailPathLength,
                value(data['pathLength']),
              ),
          ],
        ),
      LanguageComparisonStepType.bfsDistinguishingFound =>
        LocalizedLanguageComparisonStep(
          title: languageComparisonStepCounterexampleFound,
          description: languageComparisonDescriptionCounterexample(
            displayString(data['distinguishingString']),
          ),
          details: [
            if (data['distinguishingString'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailDistinguishingString,
                displayString(data['distinguishingString']),
              ),
            if (data['stateA'] != null || data['stateB'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailStatePair,
                statePair(data['stateA'], data['stateB']),
              ),
            if (data['acceptsA'] != null || data['acceptsB'] != null)
              LanguageComparisonStepDetail(
                languageComparisonDetailAcceptance,
                acceptance(data['acceptsA'], data['acceptsB']),
              ),
            if (data['symbol'] != null)
              LanguageComparisonStepDetail(symbolLabel, value(data['symbol'])),
          ],
        ),
      LanguageComparisonStepType.bfsComplete => LocalizedLanguageComparisonStep(
        title: languageComparisonStepBfsComplete,
        description: languageComparisonDescriptionBfsComplete,
        details: [
          if (data['totalPairsExplored'] != null)
            LanguageComparisonStepDetail(
              languageComparisonDetailPairsExplored,
              value(data['totalPairsExplored']),
            ),
        ],
      ),
      LanguageComparisonStepType.result => LocalizedLanguageComparisonStep(
        title: languageComparisonStepResult,
        description: languageComparisonDescriptionResult(
          (data['isEquivalent'] == true).toString(),
        ),
        details: [
          if (data['isEquivalent'] != null)
            LanguageComparisonStepDetail(
              languageComparisonDetailEquivalent,
              boolean(data['isEquivalent']),
            ),
          if (data['distinguishingString'] != null)
            LanguageComparisonStepDetail(
              languageComparisonDetailDistinguishingString,
              displayString(data['distinguishingString']),
            ),
        ],
      ),
      LanguageComparisonStepType.error => LocalizedLanguageComparisonStep(
        title: languageComparisonStepError,
        description: languageComparisonDescriptionError,
        details: [
          if (data['reason'] != null)
            LanguageComparisonStepDetail(
              languageComparisonDetailReason,
              value(data['reason']),
            ),
          if (data['stage'] != null)
            LanguageComparisonStepDetail(
              languageComparisonDetailStage,
              value(data['stage']),
            ),
          if (data['message'] != null)
            LanguageComparisonStepDetail(
              languageComparisonDetailMessage,
              value(data['message']),
            ),
        ],
      ),
      LanguageComparisonStepType.unknown => LocalizedLanguageComparisonStep(
        title: languageComparisonStepUnknown,
        description: languageComparisonDescriptionUnknown,
        details: [
          LanguageComparisonStepDetail(
            languageComparisonDetailRawType,
            value(data['_rawType']),
          ),
          for (final entry in data.entries)
            if (entry.key != '_rawType')
              LanguageComparisonStepDetail(entry.key, value(entry.value)),
        ],
      ),
    };
  }
}

class LocalizedLanguageComparisonStep {
  const LocalizedLanguageComparisonStep({
    required this.title,
    required this.description,
    required this.details,
  });

  final String title;
  final String description;
  final List<LanguageComparisonStepDetail> details;
}

class _LocalizedComputationBranchInspectorLabels
    extends ComputationBranchInspectorLabels {
  _LocalizedComputationBranchInspectorLabels(this.l10n)
    : super(
        title: l10n.computationBranchesTitle,
        inspectorSemanticLabel: l10n.computationBranchesInspectorSemantic,
        branchSelectorLabel: l10n.computationBranchesBranch,
        hierarchyTitle: l10n.computationBranchesConfigurations,
        detailsTitle: l10n.computationBranchesConfigurationDetails,
        configurationLabel: l10n.computationBranchesConfiguration,
        transitionLabel: l10n.transitionLabel,
        outcomeLabelPrefix: l10n.computationBranchesOutcome,
        highlightBranch: l10n.computationBranchesHighlight,
        selectConfiguration: l10n.computationBranchesSelectConfiguration,
        noBranches: l10n.computationBranchesNone,
        noConfigurations: l10n.computationBranchesNoConfigurations,
        unavailableTitle: l10n.computationBranchesUnavailable,
        previousBranch: l10n.computationBranchesPreviousBranch,
        nextBranch: l10n.computationBranchesNextBranch,
        previousConfigurations: l10n.computationBranchesPreviousConfigurations,
        nextConfigurations: l10n.computationBranchesNextConfigurations,
      );

  final AppLocalizations l10n;

  @override
  String branchName(int index, ComputationBranch branch) =>
      branch.summary?.isNotEmpty == true
      ? branch.summary!
      : l10n.computationBranchesBranchName(index + 1);

  @override
  String configurationName(int index) =>
      l10n.computationBranchesConfigurationName(index + 1);

  @override
  String branchPosition(int index, int total) =>
      l10n.computationBranchesBranchPosition(index, total);

  @override
  String configurationRange(int start, int end, int total) =>
      l10n.computationBranchesConfigurationRange(start, end, total);

  @override
  String outcomeLabel(ComputationBranchOutcome outcome) => switch (outcome) {
    ComputationBranchOutcome.accepted => l10n.computationBranchesAccepted,
    ComputationBranchOutcome.rejected => l10n.computationBranchesRejected,
    ComputationBranchOutcome.dead => l10n.computationBranchesDead,
    ComputationBranchOutcome.boundedUnknown =>
      l10n.computationBranchesBoundedUnknown,
    ComputationBranchOutcome.cycle => l10n.computationBranchesCycle,
    ComputationBranchOutcome.cancelled => l10n.computationBranchesCancelled,
    ComputationBranchOutcome.failed => l10n.computationBranchesFailed,
  };

  @override
  String unavailableReason(ComputationBranchesUnavailableReason reason) =>
      switch (reason) {
        ComputationBranchesUnavailableReason.simulationNotRun =>
          l10n.computationBranchesSimulationNotRun,
        ComputationBranchesUnavailableReason.branchesNotRecorded =>
          l10n.computationBranchesNotRecorded,
        ComputationBranchesUnavailableReason.deterministicExecution =>
          l10n.computationBranchesDeterministic,
        ComputationBranchesUnavailableReason.unsupportedSource =>
          l10n.computationBranchesUnsupported,
      };

  @override
  String configurationDetailsSemanticLabel(
    String configuration,
    ComputationBranchOutcome? outcome,
  ) => l10n.computationBranchesConfigurationSemantic(
    (outcome != null).toString(),
    configuration,
    outcome == null ? '' : outcomeLabel(outcome),
  );

  @override
  String branchOption(String branch, String outcome) =>
      l10n.computationBranchesBranchOption(branch, outcome);

  @override
  String branchAnnouncement(String position, String branch, String outcome) =>
      l10n.computationBranchesBranchAnnouncement(position, branch, outcome);

  @override
  String outcomeSemanticLabel(String outcome) =>
      l10n.computationBranchesOutcomeSemantic(outcome);

  @override
  String unavailableSemanticLabel(
    ComputationBranchesUnavailableReason reason,
  ) => l10n.computationBranchesUnavailableSemantic(unavailableReason(reason));
}

String _formalValue(Object? raw, String unknown) {
  if (raw == null) return unknown;
  if (raw is Iterable) return raw.map((item) => item.toString()).join(', ');
  return raw.toString();
}
