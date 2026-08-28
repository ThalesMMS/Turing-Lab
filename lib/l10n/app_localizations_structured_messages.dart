import '../core/messages/structured_message.dart';
import 'app_localizations.dart';
import 'app_localizations_workflows.dart';
import 'pumping_lemma_localizations.dart';

/// Resolves locale-neutral domain messages at the presentation boundary.
extension AppLocalizationsStructuredMessages on AppLocalizations {
  String resolveStructuredMessage(
    StructuredMessage message,
  ) => switch (message.stableCode) {
    'simulation.timeout'
        when _matchesArguments(message, const {
          'elapsed': (
            kind: StructuredMessageArgumentKind.durationMilliseconds,
            role: null,
          ),
        }) =>
      simulationOutcomeTimeout(
        Duration(milliseconds: _intArgument(message, 'elapsed')).inSeconds,
      ),
    'simulation.proven-cycle'
        when _matchesArguments(message, const {
          'steps': (kind: StructuredMessageArgumentKind.count, role: null),
        }) =>
      simulationOutcomeProvenCycle(_intArgument(message, 'steps')),
    'simulation.legacy-failure' when _matchesArguments(message, const {}) =>
      simulationOutcomeLegacyFailure,
    'batch.import.case-limit'
        when _matchesArguments(message, const {
          'count': (kind: StructuredMessageArgumentKind.count, role: null),
          'bound': (kind: StructuredMessageArgumentKind.bound, role: null),
        }) =>
      batchImportCaseLimit(
        _intArgument(message, 'count'),
        _intArgument(message, 'bound'),
      ),
    'batch.import.missing-input-column'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'row-number',
          ),
        }) =>
      batchImportMissingInputColumn(_intArgument(message, 'row')),
    'batch.import.duplicate-case-id' when _batchCaseContract(message) =>
      batchImportDuplicateCaseId(_stringArgument(message, 'case')),
    'batch.import.characters-after-closing-quote'
        when _matchesArguments(message, const {}) =>
      batchImportCharactersAfterClosingQuote,
    'batch.import.quote-requires-empty-field'
        when _matchesArguments(message, const {}) =>
      batchImportQuoteRequiresEmptyField,
    'batch.import.unclosed-quote' when _matchesArguments(message, const {}) =>
      batchImportUnclosedQuote,
    'batch.validation.non-empty' when _batchFieldContract(message) =>
      batchValidationNonEmpty(_batchField(this, message)),
    'batch.validation.positive' when _batchFieldContract(message) =>
      batchValidationPositive(_batchField(this, message)),
    'batch.validation.non-negative' when _batchFieldContract(message) =>
      batchValidationNonNegative(_batchField(this, message)),
    'batch.validation.maximum'
        when _matchesArguments(message, const {
          'field': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'validation-field',
          ),
          'bound': (kind: StructuredMessageArgumentKind.bound, role: null),
        }) =>
      batchValidationMaximum(
        _batchField(this, message),
        _intArgument(message, 'bound'),
      ),
    'batch.validation.case-context'
        when _matchesArguments(message, const {
          'index': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'case-index',
          ),
          'case': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'case',
          ),
        }) =>
      batchValidationCaseContext(
        _intArgument(message, 'index'),
        _stringArgument(message, 'case'),
      ),
    'batch.validation.duplicate-case-id' when _batchCaseContract(message) =>
      batchValidationDuplicateCaseId(_stringArgument(message, 'case')),
    'batch.validation.explicit-tokens-required'
        when _batchCaseContract(message) =>
      batchValidationExplicitTokensRequired(_stringArgument(message, 'case')),
    'batch.validation.unknown-case-limits' when _batchCaseContract(message) =>
      batchValidationUnknownCaseLimits(_stringArgument(message, 'case')),
    'batch.validation.selected-trace-case-required'
        when _matchesArguments(message, const {}) =>
      batchValidationSelectedTraceCaseRequired,
    'batch.execution.scalar-tokenization-required'
        when _matchesArguments(message, const {}) =>
      batchExecutionScalarTokenizationRequired,
    'batch.execution.grammar-tokenization-mismatch'
        when _matchesArguments(message, const {}) =>
      batchExecutionGrammarTokenizationMismatch,
    'batch.execution.tm-policy-reason'
        when _matchesArguments(message, const {
          'policy': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'tm-acceptance-policy',
          ),
          'reason': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'tm-acceptance-reason',
          ),
        }) =>
      batchExecutionTmPolicyReason(
        _tmPolicy(this, _stringArgument(message, 'policy')),
        _tmReason(this, _stringArgument(message, 'reason')),
      ),
    'l-system.expansion.duplicate-production-id'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
        }) =>
      localizeWorkflowText('Production IDs must be unique.'),
    'l-system.expansion.unsupported-variant'
        when _matchesArguments(message, const {
          'variant': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'l-system-variant',
          ),
        }) =>
      localizeWorkflowText(
        '${_stringArgument(message, 'variant')} L-systems are preserved but not expanded.',
      ),
    'l-system.turtle.finite-command-argument-required'
        when _matchesArguments(message, const {
          'command': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'turtle-command',
          ),
        }) =>
      localizeWorkflowText(
        'Turtle command ${_stringArgument(message, 'command')} requires a finite number.',
      ),
    'l-system.turtle.non-finite-geometry'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('Turtle movement produced non-finite geometry.'),
    'l-system.turtle.branch-stack-limit'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText(
        'Turtle branch stack exceeded its configured limit.',
      ),
    'l-system.turtle.branch-pop-without-push'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('A branch pop has no matching push.'),
    'l-system.turtle.line-width-invalid'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText(
        'Turtle line width must remain positive and finite.',
      ),
    'l-system.turtle.nested-polygon-unsupported'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('Nested turtle polygons are not supported.'),
    'l-system.turtle.polygon-close-without-begin'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('A polygon close has no matching begin command.'),
    'l-system.turtle.polygon-minimum-points'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('A turtle polygon requires at least three points.'),
    'l-system.turtle.color-unsupported'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('Turtle color commands require a supported color.'),
    'l-system.turtle.line-width-increment-invalid'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText(
        'Turtle line width increment must be positive and finite.',
      ),
    'l-system.turtle.distance-invalid'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('Turtle distance must be positive and finite.'),
    'l-system.turtle.polygon-unclosed'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('A turtle polygon was not closed.'),
    'l-system.turtle.branch-state-unrestored'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'branch-count',
          ),
        }) =>
      localizeWorkflowText(
        '${_intArgument(message, 'count')} turtle branch state(s) were not restored.',
      ),
    'l-system.execution.expansion-cancelled'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('Expansion cancelled.'),
    'l-system.execution.rendering-cancelled'
        when _matchesArguments(message, const {}) =>
      localizeWorkflowText('Rendering cancelled.'),
    'l-system.execution.expansion-bounded'
        when _matchesArguments(message, const {
          'kind': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'expansion-limit-kind',
          ),
          'maximum': (kind: StructuredMessageArgumentKind.bound, role: null),
          'estimate': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'estimated-resource-use',
          ),
        }) =>
      localizeWorkflowText(
        'Expansion stopped at the ${_lSystemLimitKind(_stringArgument(message, 'kind'))} limit.',
      ),
    'l-system.execution.rendering-bounded'
        when _matchesArguments(message, const {
          'maximum': (
            kind: StructuredMessageArgumentKind.bound,
            role: 'segment-limit',
          ),
          'processed': (
            kind: StructuredMessageArgumentKind.count,
            role: 'processed-symbol-count',
          ),
        }) =>
      localizeWorkflowText('Rendering stopped at the segment limit.'),
    'grammar.dependency-graph.summary-counts'
        when _matchesArguments(message, const {
          'variable-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'variable-count',
          ),
          'edge-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'edge-count',
          ),
        }) =>
      grammarDependencySummaryCounts(
        _intArgument(message, 'variable-count'),
        _intArgument(message, 'edge-count'),
      ),
    'grammar.dependency-graph.no-recursion-cycle'
        when _matchesArguments(message, const {}) =>
      grammarDependencyNoRecursionCycle,
    'grammar.dependency-graph.recursion-cycle-count'
        when _matchesArguments(message, const {
          'cycle-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'cycle-count',
          ),
        }) =>
      grammarDependencyRecursionCycleCount(
        _intArgument(message, 'cycle-count'),
      ),
    'grammar.dependency-graph.unreachable-variable'
        when _matchesArguments(message, const {
          'variable': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-variable',
          ),
        }) =>
      grammarDependencyUnreachableVariable(
        _stringArgument(message, 'variable'),
      ),
    'grammar.dependency-graph.nonproductive-variable'
        when _matchesArguments(message, const {
          'variable': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-variable',
          ),
        }) =>
      grammarDependencyNonproductiveVariable(
        _stringArgument(message, 'variable'),
      ),
    'grammar.ll1-conflict.detected' when _grammarLl1ConflictContract(message) =>
      grammarLl1ConflictDetected(
        _grammarLl1ConflictKind(this, _stringArgument(message, 'kind')),
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'lookahead'),
        _stringArgument(message, 'alternatives'),
      ),
    'grammar.ambiguity.no-ll1-conflicts'
        when _matchesArguments(message, const {}) =>
      grammarAmbiguityNoLl1Conflicts,
    'grammar.ambiguity.ll1-conflicts-detected'
        when _matchesArguments(message, const {}) =>
      grammarAmbiguityLl1ConflictsDetected,
    'grammar.ambiguity.non-ll1-does-not-imply-ambiguity'
        when _matchesArguments(message, const {}) =>
      grammarAmbiguityNonLl1DoesNotImplyAmbiguity,
    'grammar.analysis.empty-productions'
        when _matchesArguments(message, const {}) =>
      grammarAnalysisEmptyProductions,
    'grammar.analysis.no-left-recursion'
        when _matchesArguments(message, const {}) =>
      grammarAnalysisNoLeftRecursion,
    'grammar.analysis.first-production-lhs-undeclared'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisFirstProductionLhsUndeclared(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.analysis.first-epsilon-empty-production'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisFirstEpsilonEmptyProduction(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.analysis.first-epsilon-production'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
        }) =>
      grammarAnalysisFirstEpsilonProduction(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'production'),
      ),
    'grammar.analysis.first-terminal-production'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-symbol',
          ),
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
        }) =>
      grammarAnalysisFirstTerminalProduction(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'production'),
      ),
    'grammar.analysis.first-absorbs-first'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'source': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
        }) =>
      grammarAnalysisFirstAbsorbsFirst(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'source'),
        _stringArgument(message, 'production'),
      ),
    'grammar.analysis.first-epsilon-nullable-production'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
        }) =>
      grammarAnalysisFirstEpsilonNullableProduction(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'production'),
      ),
    'grammar.analysis.first-sets-computed'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'grammar-nonterminal-count',
          ),
        }) =>
      grammarAnalysisFirstSetsComputed(_intArgument(message, 'count')),
    'grammar.analysis.follow-start-symbol-undeclared'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-start-symbol',
          ),
        }) =>
      grammarAnalysisFollowStartSymbolUndeclared(
        _stringArgument(message, 'symbol'),
      ),
    'grammar.analysis.follow-start-symbol-missing-entry'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-start-symbol',
          ),
        }) =>
      grammarAnalysisFollowStartSymbolMissingEntry(
        _stringArgument(message, 'symbol'),
      ),
    'grammar.analysis.follow-start-includes-end-marker'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-start-symbol',
          ),
        }) =>
      grammarAnalysisFollowStartIncludesEndMarker(
        _stringArgument(message, 'symbol'),
      ),
    'grammar.analysis.follow-production-lhs-undeclared'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisFollowProductionLhsUndeclared(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.analysis.follow-gains-from-suffix'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'symbols': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-symbol-list',
          ),
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
        }) =>
      grammarAnalysisFollowGainsFromSuffix(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'symbols'),
        _stringArgument(message, 'production'),
      ),
    'grammar.analysis.follow-absorbs-follow'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'source': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
        }) =>
      grammarAnalysisFollowAbsorbsFollow(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'source'),
        _stringArgument(message, 'production'),
      ),
    'grammar.analysis.follow-sets-computed'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'grammar-nonterminal-count',
          ),
        }) =>
      grammarAnalysisFollowSetsComputed(_intArgument(message, 'count')),
    'grammar.analysis.processing-order'
        when _matchesArguments(message, const {
          'non-terminals': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-nonterminal-list',
          ),
        }) =>
      grammarAnalysisProcessingOrder(_stringArgument(message, 'non-terminals')),
    'grammar.analysis.substitution-note'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
          'via': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisSubstitutionNote(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'via'),
      ),
    'grammar.analysis.substitution-derivation'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
          'replacements': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production-list',
          ),
        }) =>
      grammarAnalysisSubstitutionDerivation(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'replacements'),
      ),
    'grammar.analysis.substitution-operation'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'via': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisSubstitutionOperation(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'via'),
      ),
    'grammar.analysis.substitution-rationale'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'via': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisSubstitutionRationale(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'via'),
      ),
    'grammar.analysis.remove-vacuous-recursion-rationale'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisRemoveVacuousRecursionRationale(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.analysis.vacuous-recursion-derivation'
        when _matchesArguments(message, const {
          'productions': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production-list',
          ),
        }) =>
      grammarAnalysisVacuousRecursionDerivation(
        _stringArgument(message, 'productions'),
      ),
    'grammar.analysis.recursive-only-rationale'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisRecursiveOnlyRationale(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.analysis.recursive-only-derivation'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisRecursiveOnlyDerivation(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.analysis.direct-recursion-introduced'
        when _matchesArguments(message, const {
          'introduced': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisDirectRecursionIntroduced(
        _stringArgument(message, 'introduced'),
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.analysis.move-recursive-suffixes-rationale'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'introduced': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisMoveRecursiveSuffixesRationale(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'introduced'),
      ),
    'grammar.analysis.direct-recursion-rewritten'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'introduced': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisDirectRecursionRewritten(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'introduced'),
      ),
    'grammar.analysis.direct-recursion-operation'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarAnalysisDirectRecursionOperation(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.analysis.left-corner-cycle-remains'
        when _matchesArguments(message, const {}) =>
      grammarAnalysisLeftCornerCycleRemains,
    'grammar.analysis.left-recursion-removed'
        when _matchesArguments(message, const {}) =>
      grammarAnalysisLeftRecursionRemoved,
    'grammar.predictive.factoring-introduced'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'introduced': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'prefix': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-symbol-list',
          ),
          'production-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'grammar-production-count',
          ),
        }) =>
      grammarPredictiveFactoringIntroduced(
        _stringArgument(message, 'introduced'),
        _stringArgument(message, 'prefix'),
        _stringArgument(message, 'non-terminal'),
        _intArgument(message, 'production-count'),
      ),
    'grammar.predictive.factoring-derivation'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'introduced': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'prefix': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-symbol-list',
          ),
          'production-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'grammar-production-count',
          ),
        }) =>
      grammarPredictiveFactoringDerivation(
        _intArgument(message, 'production-count'),
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'prefix'),
        _stringArgument(message, 'introduced'),
      ),
    'grammar.predictive.factoring-suffix'
        when _matchesArguments(message, const {
          'introduced': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'suffix': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-symbol-list',
          ),
        }) =>
      grammarPredictiveFactoringSuffix(
        _stringArgument(message, 'introduced'),
        _stringArgument(message, 'suffix'),
      ),
    'grammar.predictive.no-factoring-needed'
        when _matchesArguments(message, const {}) =>
      grammarPredictiveNoFactoringNeeded,
    'grammar.predictive.production-lhs-undeclared'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarPredictiveProductionLhsUndeclared(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.predictive.missing-table-row'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarPredictiveMissingTableRow(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.predictive.missing-follow-or-table-entry'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      grammarPredictiveMissingFollowOrTableEntry(
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.predictive.table-placement-first'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
          'lookahead': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-lookahead',
          ),
        }) =>
      grammarPredictiveTablePlacementFirst(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'lookahead'),
      ),
    'grammar.predictive.table-placement-follow'
        when _matchesArguments(message, const {
          'non-terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production',
          ),
          'lookahead': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-lookahead',
          ),
        }) =>
      grammarPredictiveTablePlacementFollow(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'lookahead'),
      ),
    'grammar.predictive.table-constructed'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'grammar-nonterminal-count',
          ),
        }) =>
      grammarPredictiveTableConstructed(_intArgument(message, 'count')),
    'grammar.predictive.table-no-conflicts'
        when _matchesArguments(message, const {}) =>
      grammarPredictiveTableNoConflicts,
    'grammar.predictive.table-conflicts-detected'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'grammar-conflict-count',
          ),
        }) =>
      grammarPredictiveTableConflictsDetected(_intArgument(message, 'count')),
    'codec.turing-lab-json.invalid-utf8'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonInvalidUtf8,
    'codec.turing-lab-json.root-must-be-object'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonRootMustBeObject,
    'codec.turing-lab-json.malformed-json'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonMalformedJson,
    'codec.turing-lab-json.unsupported-document'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonUnsupportedDocument,
    'codec.turing-lab-json.legacy-envelope-migrated'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonLegacyEnvelopeMigrated,
    'codec.turing-lab-json.unknown-field-preserved'
        when _matchesArguments(message, const {
          'scope': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'json-scope',
          ),
          'field': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'json-field',
          ),
        }) =>
      codecVersionedJsonUnknownFieldPreserved(
        _stringArgument(message, 'scope'),
        _stringArgument(message, 'field'),
      ),
    'codec.turing-lab-json.envelope-version-invalid'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonEnvelopeVersionInvalid,
    'codec.turing-lab-json.unsupported-envelope-version'
        when _matchesArguments(message, const {
          'version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'envelope-version',
          ),
        }) =>
      codecVersionedJsonUnsupportedEnvelopeVersion(
        _intArgument(message, 'version'),
      ),
    'codec.turing-lab-json.missing-document'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonMissingDocument,
    'codec.turing-lab-json.document-key-mismatch'
        when _matchesArguments(message, const {
          'system': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'formal-system',
          ),
        }) =>
      codecVersionedJsonDocumentKeyMismatch(_stringArgument(message, 'system')),
    'codec.turing-lab-json.missing-schema'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonMissingSchema,
    'codec.turing-lab-json.schema-identity-invalid'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonSchemaIdentityInvalid,
    'codec.turing-lab-json.unsupported-schema-version'
        when _matchesArguments(message, const {
          'version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      codecVersionedJsonUnsupportedSchemaVersion(
        _intArgument(message, 'version'),
      ),
    'codec.turing-lab-json.missing-payload'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonMissingPayload,
    'codec.turing-lab-json.source-metadata-invalid'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonSourceMetadataInvalid,
    'codec.turing-lab-json.source-field-invalid'
        when _matchesArguments(message, const {
          'field': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'metadata-field',
          ),
        }) =>
      codecVersionedJsonSourceFieldInvalid(_stringArgument(message, 'field')),
    'codec.turing-lab-json.extensions-invalid'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonExtensionsInvalid,
    'codec.turing-lab-json.migration-path-missing'
        when _matchesArguments(message, const {
          'version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      codecVersionedJsonMigrationPathMissing(_intArgument(message, 'version')),
    'codec.turing-lab-json.migration-rejected'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonMigrationRejected,
    'codec.turing-lab-json.migration-invalid-value'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonMigrationInvalidValue,
    'codec.turing-lab-json.migration-failed'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonMigrationFailed,
    'codec.turing-lab-json.schema-migrated'
        when _matchesArguments(message, const {
          'from': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'from-schema-version',
          ),
          'to': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'to-schema-version',
          ),
        }) =>
      codecVersionedJsonSchemaMigrated(
        _intArgument(message, 'from'),
        _intArgument(message, 'to'),
      ),
    'codec.turing-lab-json.extension-keys-invalid'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonExtensionKeysInvalid,
    'codec.turing-lab-json.payload-value-type-invalid'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonPayloadValueTypeInvalid,
    'codec.turing-lab-json.decoder-value-type-invalid'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonDecoderValueTypeInvalid,
    'codec.turing-lab-json.decoder-failed'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonDecoderFailed,
    'codec.turing-lab-json.encode-document-mismatch'
        when _matchesArguments(message, const {
          'system': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'formal-system',
          ),
        }) =>
      codecVersionedJsonEncodeDocumentMismatch(
        _stringArgument(message, 'system'),
      ),
    'codec.turing-lab-json.encode-schema-unsupported'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonEncodeSchemaUnsupported,
    'codec.turing-lab-json.encode-value-invalid'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonEncodeValueInvalid,
    'codec.turing-lab-json.encoder-failed'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonEncoderFailed,
    'codec.turing-lab-json.source-metadata-normalized'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonSourceMetadataNormalized,
    'codec.turing-lab-json.unknown-fields-sidecar-normalized'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonUnknownFieldsSidecarNormalized,
    'codec.turing-lab-json.envelope-serialization-failed'
        when _matchesArguments(message, const {}) =>
      codecVersionedJsonEnvelopeSerializationFailed,
    'codec.regex-jflap.unsupported-document'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapUnsupportedDocument,
    'codec.regex-jflap.multiple-expressions'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapMultipleExpressions,
    'codec.regex-jflap.multiple-extensions'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapMultipleExtensions,
    'codec.regex-jflap.invalid-extension'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapInvalidExtension,
    'codec.regex-jflap.extension-mismatch'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapExtensionMismatch,
    'codec.regex-jflap.dialect-normalized'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapDialectNormalized,
    'codec.regex-jflap.unsupported-feature'
        when _matchesArguments(message, const {
          'feature': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'feature-description',
          ),
        }) =>
      codecRegexJflapUnsupportedFeature(_stringArgument(message, 'feature')),
    'codec.regex-jflap.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapInvalidDocument,
    'codec.regex-jflap.malformed-document'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapMalformedDocument,
    'codec.regex-jflap.expected-regex-document'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapExpectedRegexDocument,
    'codec.regex-jflap.turing-lab-extension-portability'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapTuringLabExtensionPortability,
    'codec.regex-jflap.empty-set-interoperability'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapEmptySetInteroperability,
    'codec.regex-jflap.unbalanced-parentheses'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapUnbalancedParentheses,
    'codec.regex-jflap.malformed-operators'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapMalformedOperators,
    'codec.regex-jflap.union-missing-operand'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapUnionMissingOperand,
    'codec.regex-jflap.epsilon-left-concatenation'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapEpsilonLeftConcatenation,
    'codec.regex-jflap.epsilon-right-concatenation'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapEpsilonRightConcatenation,
    'codec.regex-jflap.escape-missing-symbol'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapEscapeMissingSymbol,
    'codec.regex-jflap.invalid-source'
        when _matchesArguments(message, const {}) =>
      codecRegexJflapInvalidSource,
    'codec.regex-json.unexpected-decoder-type'
        when _matchesArguments(message, const {}) =>
      codecRegexJsonUnexpectedDecoderType,
    'codec.regex-json.source-of-truth-invalid'
        when _matchesArguments(message, const {}) =>
      codecRegexJsonSourceOfTruthInvalid,
    'codec.regex-json.canonical-ast-mismatch'
        when _matchesArguments(message, const {}) =>
      codecRegexJsonCanonicalAstMismatch,
    'codec.regex-json.expected-regex-document'
        when _matchesArguments(message, const {}) =>
      codecRegexJsonExpectedRegexDocument,
    'codec.regex-json.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecRegexJsonInvalidDocument,
    'codec.regex-json.unsupported-dialect'
        when _matchesArguments(message, const {}) =>
      codecRegexJsonUnsupportedDialect,
    'codec.regex-json.invalid-source'
        when _matchesArguments(message, const {}) =>
      codecRegexJsonInvalidSource,
    'codec.regex-json.unexpected-validation-outcome'
        when _matchesArguments(message, const {}) =>
      codecRegexJsonUnexpectedValidationOutcome,
    'codec.pda-jflap.invalid-utf8' when _matchesArguments(message, const {}) =>
      codecPdaJflapInvalidUtf8,
    'codec.pda-jflap.malformed-xml' when _matchesArguments(message, const {}) =>
      codecPdaJflapMalformedXml,
    'codec.pda-jflap.invalid-root' when _matchesArguments(message, const {}) =>
      codecPdaJflapInvalidRoot,
    'codec.pda-jflap.unsupported-document-type'
        when _matchesArguments(message, const {
          'type': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'document-type',
          ),
        }) =>
      codecPdaJflapUnsupportedDocumentType(_stringArgument(message, 'type')),
    'codec.pda-jflap.missing-automaton'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapMissingAutomaton,
    'codec.pda-jflap.missing-state-id'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapMissingStateId,
    'codec.pda-jflap.duplicate-state-id'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecPdaJflapDuplicateStateId(_stringArgument(message, 'state')),
    'codec.pda-jflap.invalid-state-coordinate'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecPdaJflapInvalidStateCoordinate(_stringArgument(message, 'state')),
    'codec.pda-jflap.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapInvalidDocument,
    'codec.pda-jflap.unknown-transition-endpoints'
        when _codecTransitionEndpointsContract(message) =>
      codecPdaJflapUnknownTransitionEndpoints(
        _optionalStringArgument(message, 'from'),
        _optionalStringArgument(message, 'to'),
      ),
    'codec.pda-jflap.invalid-transition-id'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapInvalidTransitionId,
    'codec.pda-jflap.duplicate-transition-id'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapDuplicateTransitionId,
    'codec.pda-jflap.invalid-acceptance-mode'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapInvalidAcceptanceMode,
    'codec.pda-jflap.malformed-extension'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapMalformedExtension,
    'codec.pda-jflap.canonical-order-import'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapCanonicalOrderImport,
    'codec.pda-jflap.stale-token-extension'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapStaleTokenExtension,
    'codec.pda-jflap.explicit-epsilon-alias-interpreted'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapExplicitEpsilonAliasInterpreted,
    'codec.pda-jflap.pop-word-treated-as-atomic-token'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapPopWordTreatedAsAtomicToken,
    'codec.pda-jflap.acceptance-mode-assumed-final-state'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapAcceptanceModeAssumedFinalState,
    'codec.pda-jflap.requires-pda-document'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapRequiresPdaDocument,
    'codec.pda-jflap.unsupported-schema'
        when _matchesArguments(message, const {
          'version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      codecPdaJflapUnsupportedSchema(_intArgument(message, 'version')),
    'codec.pda-jflap.extension-portability'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapExtensionPortability,
    'codec.pda-jflap.initial-stack-symbol-not-portable'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapInitialStackSymbolNotPortable,
    'codec.pda-jflap.acceptance-mode-not-portable'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapAcceptanceModeNotPortable,
    'codec.pda-jflap.atomic-pop-token-not-portable'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapAtomicPopTokenNotPortable,
    'codec.pda-jflap.atomic-push-token-not-portable'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapAtomicPushTokenNotPortable,
    'codec.pda-jflap.unknown-optional-element'
        when _matchesArguments(message, const {
          'extension': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-key',
          ),
        }) =>
      codecPdaJflapUnknownOptionalElement(
        _stringArgument(message, 'extension'),
      ),
    'codec.pda-jflap.unknown-optional-attribute'
        when _matchesArguments(message, const {
          'extension': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-key',
          ),
        }) =>
      codecPdaJflapUnknownOptionalAttribute(
        _stringArgument(message, 'extension'),
      ),
    'codec.pda-jflap.invalid-note-position'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapInvalidNotePosition,
    'codec.pda-jflap.notes-normalized'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapNotesNormalized,
    'codec.pda-jflap.note-presentation-dropped'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapNotePresentationDropped,
    'codec.pda-jflap.unknown-diagnostic'
        when _matchesArguments(message, const {}) =>
      codecPdaJflapUnknownDiagnostic,
    'codec.pda-json.unexpected-document-type'
        when _matchesArguments(message, const {}) =>
      codecPdaJsonUnexpectedDocumentType,
    'codec.pda-json.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecPdaJsonInvalidDocument,
    'codec.tm-jflap.invalid-utf8' when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidUtf8,
    'codec.tm-jflap.malformed-xml' when _matchesArguments(message, const {}) =>
      codecTmJflapMalformedXml,
    'codec.tm-jflap.invalid-root' when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidRoot,
    'codec.tm-jflap.unsupported-document-type'
        when _matchesArguments(message, const {
          'type': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'document-type',
          ),
        }) =>
      codecTmJflapUnsupportedDocumentType(_stringArgument(message, 'type')),
    'codec.tm-jflap.unsupported-feature'
        when _matchesArguments(message, const {}) =>
      codecTmJflapUnsupportedFeature,
    'codec.tm-jflap.invalid-tape-count'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidTapeCount,
    'codec.tm-jflap.missing-automaton'
        when _matchesArguments(message, const {}) =>
      codecTmJflapMissingAutomaton,
    'codec.tm-jflap.malformed-extension'
        when _matchesArguments(message, const {}) =>
      codecTmJflapMalformedExtension,
    'codec.tm-jflap.canonical-order-import'
        when _matchesArguments(message, const {}) =>
      codecTmJflapCanonicalOrderImport,
    'codec.tm-jflap.canonical-order-export'
        when _matchesArguments(message, const {}) =>
      codecTmJflapCanonicalOrderExport,
    'codec.tm-jflap.variant-mismatch'
        when _matchesArguments(message, const {}) =>
      codecTmJflapVariantMismatch,
    'codec.tm-jflap.tape-count-mismatch'
        when _matchesArguments(message, const {}) =>
      codecTmJflapTapeCountMismatch,
    'codec.tm-jflap.blank-symbol-invalid'
        when _matchesArguments(message, const {}) =>
      codecTmJflapBlankSymbolInvalid,
    'codec.tm-jflap.acceptance-policy-invalid'
        when _matchesArguments(message, const {}) =>
      codecTmJflapAcceptancePolicyInvalid,
    'codec.tm-jflap.incomplete-extension'
        when _matchesArguments(message, const {}) =>
      codecTmJflapIncompleteExtension,
    'codec.tm-jflap.extension-schema-invalid'
        when _matchesArguments(message, const {}) =>
      codecTmJflapExtensionSchemaInvalid,
    'codec.tm-jflap.missing-state-id'
        when _matchesArguments(message, const {}) =>
      codecTmJflapMissingStateId,
    'codec.tm-jflap.duplicate-state-id'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecTmJflapDuplicateStateId(_stringArgument(message, 'state')),
    'codec.tm-jflap.invalid-state-coordinate'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecTmJflapInvalidStateCoordinate(_stringArgument(message, 'state')),
    'codec.tm-jflap.invalid-state-type'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecTmJflapInvalidStateType(_stringArgument(message, 'state')),
    'codec.tm-jflap.invalid-state-properties'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecTmJflapInvalidStateProperties(_stringArgument(message, 'state')),
    'codec.tm-jflap.invalid-initial-state-count'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidInitialStateCount,
    'codec.tm-jflap.unknown-transition-endpoints'
        when _codecTransitionEndpointsContract(message) =>
      codecTmJflapUnknownTransitionEndpoints(
        _optionalStringArgument(message, 'from'),
        _optionalStringArgument(message, 'to'),
      ),
    'codec.tm-jflap.invalid-tape-index'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidTapeIndex,
    'codec.tm-jflap.duplicate-tape-operation'
        when _matchesArguments(message, const {
          'operation': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'operation-name',
          ),
        }) =>
      codecTmJflapDuplicateTapeOperation(_stringArgument(message, 'operation')),
    'codec.tm-jflap.unsupported-read-predicate'
        when _matchesArguments(message, const {}) =>
      codecTmJflapUnsupportedReadPredicate,
    'codec.tm-jflap.invalid-read-symbol'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidReadSymbol,
    'codec.tm-jflap.invalid-write-symbol'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidWriteSymbol,
    'codec.tm-jflap.invalid-move' when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidMove,
    'codec.tm-jflap.invalid-transition-extension'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidTransitionExtension,
    'codec.tm-jflap.invalid-transition-id'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidTransitionId,
    'codec.tm-jflap.duplicate-transition-id'
        when _matchesArguments(message, const {}) =>
      codecTmJflapDuplicateTransitionId,
    'codec.tm-jflap.invalid-transition-label'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
        }) =>
      codecTmJflapInvalidTransitionLabel(
        _stringArgument(message, 'transition'),
      ),
    'codec.tm-jflap.invalid-transition-type'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
        }) =>
      codecTmJflapInvalidTransitionType(_stringArgument(message, 'transition')),
    'codec.tm-jflap.invalid-control-point'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidControlPoint,
    'codec.tm-jflap.transition-identities-reconstructed'
        when _matchesArguments(message, const {}) =>
      codecTmJflapTransitionIdentitiesReconstructed,
    'codec.tm-jflap.invalid-metadata'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidMetadata,
    'codec.tm-jflap.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidDocument,
    'codec.tm-jflap.requires-tm-document'
        when _matchesArguments(message, const {}) =>
      codecTmJflapRequiresTmDocument,
    'codec.tm-jflap.unsupported-schema'
        when _matchesArguments(message, const {
          'version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      codecTmJflapUnsupportedSchema(_intArgument(message, 'version')),
    'codec.tm-jflap.unsupported-tape-count'
        when _matchesArguments(message, const {}) =>
      codecTmJflapUnsupportedTapeCount,
    'codec.tm-jflap.unsupported-operation'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
          'operation': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'operation-name',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'tape-symbol',
          ),
        }) =>
      codecTmJflapUnsupportedOperation(
        _stringArgument(message, 'transition'),
        _stringArgument(message, 'operation'),
        _stringArgument(message, 'symbol'),
      ),
    'codec.tm-jflap.building-block-variant-mismatch'
        when _matchesArguments(message, const {}) =>
      codecTmJflapBuildingBlockVariantMismatch,
    'codec.tm-jflap.recursive-dependency'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-tag',
          ),
        }) =>
      codecTmJflapRecursiveDependency(_stringArgument(message, 'block')),
    'codec.tm-jflap.missing-block-definition'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-tag',
          ),
        }) =>
      codecTmJflapMissingBlockDefinition(_stringArgument(message, 'block')),
    'codec.tm-jflap.ambiguous-block-definition'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-tag',
          ),
        }) =>
      codecTmJflapAmbiguousBlockDefinition(_stringArgument(message, 'block')),
    'codec.tm-jflap.acceptance-policy-conflict'
        when _matchesArguments(message, const {}) =>
      codecTmJflapAcceptancePolicyConflict,
    'codec.tm-jflap.machine-schema-invalid'
        when _matchesArguments(message, const {}) =>
      codecTmJflapMachineSchemaInvalid,
    'codec.tm-jflap.machine-variant-invalid'
        when _matchesArguments(message, const {}) =>
      codecTmJflapMachineVariantInvalid,
    'codec.tm-jflap.machine-tape-count-mismatch'
        when _matchesArguments(message, const {}) =>
      codecTmJflapMachineTapeCountMismatch,
    'codec.tm-jflap.machine-blank-symbol-mismatch'
        when _matchesArguments(message, const {}) =>
      codecTmJflapMachineBlankSymbolMismatch,
    'codec.tm-jflap.missing-block-tag'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      codecTmJflapMissingBlockTag(_stringArgument(message, 'block')),
    'codec.tm-jflap.invalid-node-id'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidNodeId,
    'codec.tm-jflap.duplicate-node-id'
        when _matchesArguments(message, const {}) =>
      codecTmJflapDuplicateNodeId,
    'codec.tm-jflap.invalid-node-coordinate'
        when _matchesArguments(message, const {
          'node': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'node-id',
          ),
        }) =>
      codecTmJflapInvalidNodeCoordinate(_stringArgument(message, 'node')),
    'codec.tm-jflap.invalid-node-state-type'
        when _matchesArguments(message, const {
          'node': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'node-id',
          ),
        }) =>
      codecTmJflapInvalidNodeStateType(_stringArgument(message, 'node')),
    'codec.tm-jflap.invalid-node-properties'
        when _matchesArguments(message, const {
          'node': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'node-id',
          ),
        }) =>
      codecTmJflapInvalidNodeProperties(_stringArgument(message, 'node')),
    'codec.tm-jflap.missing-block-tag-reference'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      codecTmJflapMissingBlockTagReference(_stringArgument(message, 'block')),
    'codec.tm-jflap.invalid-or-duplicate-tape-index'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidOrDuplicateTapeIndex,
    'codec.tm-jflap.transition-identity-conflict'
        when _matchesArguments(message, const {}) =>
      codecTmJflapTransitionIdentityConflict,
    'codec.tm-jflap.building-blocks-imported'
        when _matchesArguments(message, const {}) =>
      codecTmJflapBuildingBlocksImported,
    'codec.tm-jflap.shared-tapes' when _matchesArguments(message, const {}) =>
      codecTmJflapSharedTapes,
    'codec.tm-jflap.unknown-building-block-extension-dropped'
        when _matchesArguments(message, const {}) =>
      codecTmJflapUnknownBuildingBlockExtensionDropped,
    'codec.tm-jflap.building-blocks-exported'
        when _matchesArguments(message, const {}) =>
      codecTmJflapBuildingBlocksExported,
    'codec.tm-jflap.extension-identities'
        when _matchesArguments(message, const {}) =>
      codecTmJflapExtensionIdentities,
    'codec.tm-jflap.extension-portability'
        when _matchesArguments(message, const {}) =>
      codecTmJflapExtensionPortability,
    'codec.tm-jflap.unknown-optional-element'
        when _matchesArguments(message, const {
          'extension': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-key',
          ),
        }) =>
      codecTmJflapUnknownOptionalElement(_stringArgument(message, 'extension')),
    'codec.tm-jflap.unknown-optional-attribute'
        when _matchesArguments(message, const {
          'extension': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-key',
          ),
        }) =>
      codecTmJflapUnknownOptionalAttribute(
        _stringArgument(message, 'extension'),
      ),
    'codec.tm-jflap.invalid-note-position'
        when _matchesArguments(message, const {}) =>
      codecTmJflapInvalidNotePosition,
    'codec.tm-jflap.notes-normalized'
        when _matchesArguments(message, const {}) =>
      codecTmJflapNotesNormalized,
    'codec.tm-jflap.note-presentation-dropped'
        when _matchesArguments(message, const {}) =>
      codecTmJflapNotePresentationDropped,
    'codec.tm-jflap.unknown-diagnostic'
        when _matchesArguments(message, const {}) =>
      codecTmJflapUnknownDiagnostic,
    'codec.tm-json.unexpected-document-type'
        when _matchesArguments(message, const {}) =>
      codecTmJsonUnexpectedDocumentType,
    'codec.tm-json.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecTmJsonInvalidDocument,
    'codec.tm-json.variant-mismatch'
        when _matchesArguments(message, const {}) =>
      codecTmJsonVariantMismatch,
    'codec.tm-json.variant-inferred'
        when _matchesArguments(message, const {}) =>
      codecTmJsonVariantInferred,
    'codec.tm-json.operation-vectors-migrated'
        when _matchesArguments(message, const {}) =>
      codecTmJsonOperationVectorsMigrated,
    'codec.tm-json.endpoints-migrated-to-ids'
        when _matchesArguments(message, const {}) =>
      codecTmJsonEndpointsMigratedToIds,
    'codec.grammar-jflap.unsupported-document-type'
        when _matchesArguments(message, const {
          'type': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'document-type',
          ),
        }) =>
      codecGrammarJflapUnsupportedDocumentType(
        _stringArgument(message, 'type'),
      ),
    'codec.grammar-jflap.empty-grammar'
        when _matchesArguments(message, const {}) =>
      codecGrammarJflapEmptyGrammar,
    'codec.grammar-jflap.missing-production-side'
        when _matchesArguments(message, const {
          'index': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'production-index',
          ),
        }) =>
      codecGrammarJflapMissingProductionSide(_intArgument(message, 'index')),
    'codec.grammar-jflap.start-symbol-undetermined'
        when _matchesArguments(message, const {}) =>
      codecGrammarJflapStartSymbolUndetermined,
    'codec.grammar-jflap.unknown-grammar-type-preserved'
        when _matchesArguments(message, const {
          'type': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-type',
          ),
        }) =>
      codecGrammarJflapUnknownGrammarTypePreserved(
        _stringArgument(message, 'type'),
      ),
    'codec.grammar-jflap.unknown-optional-element'
        when _matchesArguments(message, const {
          'extension': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-key',
          ),
        }) =>
      codecGrammarJflapUnknownOptionalElement(
        _stringArgument(message, 'extension'),
      ),
    'codec.grammar-jflap.tokenization-normalized'
        when _matchesArguments(message, const {}) =>
      codecGrammarJflapTokenizationNormalized,
    'codec.grammar-jflap.requires-grammar-document'
        when _matchesArguments(message, const {}) =>
      codecGrammarJflapRequiresGrammarDocument,
    'codec.grammar-jflap.unsupported-schema'
        when _matchesArguments(message, const {
          'version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      codecGrammarJflapUnsupportedSchema(_intArgument(message, 'version')),
    'codec.grammar-jflap.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecGrammarJflapInvalidDocument,
    'codec.grammar-jflap.token-boundaries-lossy'
        when _matchesArguments(message, const {
          'tokens': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'token-list',
          ),
        }) =>
      codecGrammarJflapTokenBoundariesLossy(_stringArgument(message, 'tokens')),
    'codec.grammar-jflap.classification-lossy'
        when _matchesArguments(message, const {
          'classification': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-classification',
          ),
        }) =>
      codecGrammarJflapClassificationLossy(
        _stringArgument(message, 'classification'),
      ),
    'codec.l-system-jflap.invalid-root'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapInvalidRoot,
    'codec.l-system-jflap.unsupported-document-type'
        when _matchesArguments(message, const {
          'type': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'document-type',
          ),
        }) =>
      codecLSystemJflapUnsupportedDocumentType(
        _stringArgument(message, 'type'),
      ),
    'codec.l-system-jflap.missing-axiom'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapMissingAxiom,
    'codec.l-system-jflap.malformed-xml'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapMalformedXml,
    'codec.l-system-jflap.invalid-utf8'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapInvalidUtf8,
    'codec.l-system-jflap.empty-predecessor'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapEmptyPredecessor,
    'codec.l-system-jflap.invalid-context-predecessor'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'production-left',
          ),
        }) =>
      codecLSystemJflapInvalidContextPredecessor(
        _stringArgument(message, 'production'),
      ),
    'codec.l-system-jflap.invalid-parameter'
        when _matchesArguments(message, const {
          'parameter': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'parameter-name',
          ),
        }) =>
      codecLSystemJflapInvalidParameter(_stringArgument(message, 'parameter')),
    'codec.l-system-jflap.invalid-parameter'
        when _matchesArguments(message, const {
          'parameter': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'parameter-name',
          ),
          'value': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'parameter-value',
          ),
        }) =>
      codecLSystemJflapInvalidParameterValue(
        _stringArgument(message, 'parameter'),
        _stringArgument(message, 'value'),
      ),
    'codec.l-system-jflap.invalid-extension'
        when _matchesArguments(message, const {
          'extension': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-key',
          ),
        }) =>
      codecLSystemJflapInvalidExtension(_stringArgument(message, 'extension')),
    'codec.l-system-jflap.invalid-production-metadata'
        when _matchesArguments(message, const {
          'field': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'metadata-field',
          ),
        }) =>
      codecLSystemJflapInvalidProductionMetadata(
        _stringArgument(message, 'field'),
      ),
    'codec.l-system-jflap.invalid-command-mapping'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapInvalidCommandMapping,
    'codec.l-system-jflap.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapInvalidDocument,
    'codec.l-system-jflap.requires-l-system-document'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapRequiresLSystemDocument,
    'codec.l-system-jflap.unsupported-schema'
        when _matchesArguments(message, const {
          'version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      codecLSystemJflapUnsupportedSchema(_intArgument(message, 'version')),
    'codec.l-system-jflap.decode-failed'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapDecodeFailed,
    'codec.l-system-jflap.encode-failed'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapEncodeFailed,
    'codec.l-system-jflap.advanced-variant-preserved'
        when _matchesArguments(message, const {
          'variants': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'unsupported-variant-list',
          ),
        }) =>
      codecLSystemJflapAdvancedVariantPreserved(
        _stringArgument(message, 'variants'),
      ),
    'codec.l-system-jflap.parameters-preserved'
        when _matchesArguments(message, const {
          'parameters': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'parameter-list',
          ),
        }) =>
      codecLSystemJflapParametersPreserved(
        _stringArgument(message, 'parameters'),
      ),
    'codec.l-system-jflap.execution-extension-restored'
        when _matchesArguments(message, const {
          'features': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-feature-list',
          ),
        }) =>
      codecLSystemJflapExecutionExtensionRestored(
        _stringArgument(message, 'features'),
      ),
    'codec.l-system-jflap.elements-preserved'
        when _matchesArguments(message, const {}) =>
      codecLSystemJflapElementsPreserved,
    'codec.l-system-jflap.execution-extension'
        when _matchesArguments(message, const {
          'features': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-feature-list',
          ),
        }) =>
      codecLSystemJflapExecutionExtension(_stringArgument(message, 'features')),
    'codec.l-system-jflap.advanced-variant-extension'
        when _matchesArguments(message, const {
          'variants': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'unsupported-variant-list',
          ),
        }) =>
      codecLSystemJflapAdvancedVariantExtension(
        _stringArgument(message, 'variants'),
      ),
    'codec.fsa-jflap.invalid-root' when _matchesArguments(message, const {}) =>
      codecFsaJflapInvalidRoot,
    'codec.fsa-jflap.unsupported-document-type'
        when _matchesArguments(message, const {
          'type': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'document-type',
          ),
        }) =>
      codecFsaJflapUnsupportedDocumentType(_stringArgument(message, 'type')),
    'codec.fsa-jflap.building-blocks-unsupported'
        when _matchesArguments(message, const {}) =>
      codecFsaJflapBuildingBlocksUnsupported,
    'codec.fsa-jflap.missing-automaton'
        when _matchesArguments(message, const {}) =>
      codecFsaJflapMissingAutomaton,
    'codec.fsa-jflap.missing-state-id'
        when _matchesArguments(message, const {}) =>
      codecFsaJflapMissingStateId,
    'codec.fsa-jflap.duplicate-state-id'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecFsaJflapDuplicateStateId(_stringArgument(message, 'state')),
    'codec.fsa-jflap.invalid-state-coordinate'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecFsaJflapInvalidStateCoordinate(_stringArgument(message, 'state')),
    'codec.fsa-jflap.multiple-initial-states'
        when _matchesArguments(message, const {}) =>
      codecFsaJflapMultipleInitialStates,
    'codec.fsa-jflap.invalid-document'
        when _matchesArguments(message, const {}) =>
      codecFsaJflapInvalidDocument,
    'codec.fsa-jflap.unsupported-schema'
        when _matchesArguments(message, const {
          'version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      codecFsaJflapUnsupportedSchema(_intArgument(message, 'version')),
    'codec.fsa-jflap.requires-fsa-document'
        when _matchesArguments(message, const {}) =>
      codecFsaJflapRequiresFsaDocument,
    'codec.fsa-jflap.canonical-order-import'
        when _matchesArguments(message, const {}) =>
      codecFsaJflapCanonicalOrderImport,
    'codec.fsa-jflap.canonical-order-export'
        when _matchesArguments(message, const {}) =>
      codecFsaJflapCanonicalOrderExport,
    'codec.fsa-jflap.state-type-dropped'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecFsaJflapStateTypeDropped(_stringArgument(message, 'state')),
    'codec.fsa-jflap.state-properties-dropped'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      codecFsaJflapStatePropertiesDropped(_stringArgument(message, 'state')),
    'codec.fsa-jflap.transition-control-point-dropped'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
          'control-point': (
            kind: StructuredMessageArgumentKind.coordinate,
            role: null,
          ),
        }) =>
      codecFsaJflapTransitionControlPointDropped(
        _stringArgument(message, 'transition'),
        _coordinateArgument(message, 'control-point'),
      ),
    'codec.fsa-jflap.transition-display-label-dropped'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
          'label': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'transition-label',
          ),
        }) =>
      codecFsaJflapTransitionDisplayLabelDropped(
        _stringArgument(message, 'transition'),
      ),
    'codec.fsa-jflap.explicit-epsilon-alias-interpreted'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      codecFsaJflapExplicitEpsilonAliasInterpreted(
        _stringArgument(message, 'symbol'),
      ),
    'codec.fsa-jflap.explicit-epsilon-alias-exported-empty'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
          'aliases': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'epsilon-aliases',
          ),
        }) =>
      codecFsaJflapExplicitEpsilonAliasExportedEmpty(
        _stringArgument(message, 'aliases'),
        _stringArgument(message, 'transition'),
      ),
    'codec.fsa-jflap.multi-symbol-transition-expanded'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'symbol-count',
          ),
        }) =>
      codecFsaJflapMultiSymbolTransitionExpanded(
        _stringArgument(message, 'transition'),
        _intArgument(message, 'count'),
      ),
    'codec.fsa-jflap.unknown-optional-element'
        when _matchesArguments(message, const {
          'extension': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-key',
          ),
        }) =>
      codecFsaJflapUnknownOptionalElement(
        _stringArgument(message, 'extension'),
      ),
    'codec.fsa-jflap.unknown-optional-attribute'
        when _matchesArguments(message, const {
          'extension': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'extension-key',
          ),
        }) =>
      codecFsaJflapUnknownOptionalAttribute(
        _stringArgument(message, 'extension'),
      ),
    'grammar.structural.start-symbol-missing'
        when _matchesArguments(message, const {}) =>
      grammarStructuralStartSymbolMissing,
    'grammar.structural.start-symbol-missing-reachability'
        when _matchesArguments(message, const {}) =>
      grammarStructuralStartSymbolMissingReachability,
    'grammar.structural.start-symbol-not-nonterminal'
        when _grammarStructuralStartSymbolContract(message) =>
      grammarStructuralStartSymbolNotNonterminal(
        _stringArgument(message, 'symbol'),
      ),
    'grammar.structural.start-symbol-not-nonterminal-reachability'
        when _grammarStructuralStartSymbolContract(message) =>
      grammarStructuralStartSymbolNotNonterminalReachability(
        _stringArgument(message, 'symbol'),
      ),
    'grammar.structural.no-productions'
        when _matchesArguments(message, const {}) =>
      grammarStructuralNoProductions,
    'grammar.structural.no-productions-productivity'
        when _matchesArguments(message, const {}) =>
      grammarStructuralNoProductionsProductivity,
    'grammar.structural.production-left-side-empty'
        when _grammarStructuralProductionContract(message) =>
      grammarStructuralProductionLeftSideEmpty(
        _stringArgument(message, 'production'),
      ),
    'grammar.structural.production-left-side-not-single-nonterminal'
        when _grammarStructuralProductionLeftSideContract(message) =>
      grammarStructuralProductionLeftSideNotSingleNonterminal(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'left-side'),
      ),
    'grammar.structural.production-left-side-empty-symbol'
        when _grammarStructuralProductionContract(message) =>
      grammarStructuralProductionLeftSideEmptySymbol(
        _stringArgument(message, 'production'),
      ),
    'grammar.structural.production-left-side-not-nonterminal'
        when _grammarStructuralProductionLeftSideSymbolContract(message) =>
      grammarStructuralProductionLeftSideNotNonterminal(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'grammar.structural.production-unknown-symbol'
        when _grammarStructuralProductionUnknownSymbolContract(message) =>
      grammarStructuralProductionUnknownSymbol(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'grammar.structural.unknown-symbol-reachability'
        when _grammarStructuralSymbolContract(message) =>
      grammarStructuralUnknownSymbolReachability(
        _stringArgument(message, 'symbol'),
      ),
    'grammar.structural.unknown-symbol-productivity'
        when _grammarStructuralSymbolContract(message) =>
      grammarStructuralUnknownSymbolProductivity(
        _stringArgument(message, 'symbol'),
      ),
    'grammar.structural.lambda-production-rhs-not-empty'
        when _grammarStructuralProductionContract(message) =>
      grammarStructuralLambdaProductionRhsNotEmpty(
        _stringArgument(message, 'production'),
      ),
    'grammar.structural.production-rhs-empty'
        when _grammarStructuralProductionContract(message) =>
      grammarStructuralProductionRhsEmpty(
        _stringArgument(message, 'production'),
      ),
    'grammar.structural.unreachable-nonterminals'
        when _grammarStructuralSummaryContract(message) =>
      grammarStructuralUnreachableNonterminals(
        _intArgument(message, 'count'),
        _stringArgument(message, 'symbols'),
      ),
    'grammar.structural.unproductive-nonterminals'
        when _grammarStructuralSummaryContract(message) =>
      grammarStructuralUnproductiveNonterminals(
        _intArgument(message, 'count'),
        _stringArgument(message, 'symbols'),
      ),
    'grammar.structural.unproductive-productions'
        when _grammarStructuralSymbolsSummaryContract(message) =>
      grammarStructuralUnproductiveProductions(
        _stringArgument(message, 'symbols'),
      ),
    'grammar.cnf.grammar-not-cfg'
        when _grammarCnfGrammarTypeContract(message) =>
      grammarCnfGrammarNotCfg(
        _grammarCnfGrammarTypeLabel(this, _stringArgument(message, 'type')),
      ),
    'grammar.cnf.start-symbol-rename-failed'
        when _matchesArguments(message, const {}) =>
      grammarCnfStartSymbolRenameFailed,
    'grammar.cnf.not-strict-cnf' when _grammarCnfViolationsContract(message) =>
      grammarCnfNotStrictCnf(_stringArgument(message, 'violations')),
    'grammar.cnf.nullable-subset-limit-exceeded'
        when _grammarCnfNullableSubsetContract(message) =>
      grammarCnfNullableSubsetLimitExceeded(
        _stringArgument(message, 'production'),
        _intArgument(message, 'nullable-positions'),
        _intArgument(message, 'subsets'),
        _intArgument(message, 'limit'),
      ),
    'grammar.cnf.new-symbol-limit-reached'
        when _grammarCnfNewSymbolLimitContract(message) =>
      grammarCnfNewSymbolLimitReached(_intArgument(message, 'limit')),
    'grammar.cnf.start-symbol-title'
        when _matchesArguments(message, const {}) =>
      grammarCnfStartSymbolTitle,
    'grammar.cnf.start-symbol-rationale'
        when _matchesArguments(message, const {}) =>
      grammarCnfStartSymbolRationale,
    'grammar.cnf.epsilon-title' when _matchesArguments(message, const {}) =>
      grammarCnfEpsilonTitle,
    'grammar.cnf.epsilon-rationale' when _matchesArguments(message, const {}) =>
      grammarCnfEpsilonRationale,
    'grammar.cnf.unit-title' when _matchesArguments(message, const {}) =>
      grammarCnfUnitTitle,
    'grammar.cnf.unit-rationale' when _matchesArguments(message, const {}) =>
      grammarCnfUnitRationale,
    'grammar.cnf.useless-title' when _matchesArguments(message, const {}) =>
      grammarCnfUselessTitle,
    'grammar.cnf.useless-rationale' when _matchesArguments(message, const {}) =>
      grammarCnfUselessRationale,
    'grammar.cnf.binarize-title' when _matchesArguments(message, const {}) =>
      grammarCnfBinarizeTitle,
    'grammar.cnf.binarize-rationale'
        when _matchesArguments(message, const {}) =>
      grammarCnfBinarizeRationale,
    'grammar.gnf.transform-failed' when _matchesArguments(message, const {}) =>
      grammarGnfTransformFailed,
    'grammar.gnf.not-gnf' when _matchesArguments(message, const {}) =>
      grammarGnfNotGnf,
    'grammar.gnf.convert-title' when _matchesArguments(message, const {}) =>
      grammarGnfConvertTitle,
    'grammar.gnf.convert-rationale' when _matchesArguments(message, const {}) =>
      grammarGnfConvertRationale,
    'grammar.to-pda.empty-grammar' when _matchesArguments(message, const {}) =>
      grammarToPdaEmptyGrammar,
    'grammar.to-pda.missing-start-symbol'
        when _matchesArguments(message, const {}) =>
      grammarToPdaMissingStartSymbol,
    'grammar.to-pda.undeclared-start-symbol'
        when _grammarToPdaSymbolContract(message) =>
      grammarToPdaUndeclaredStartSymbol(_stringArgument(message, 'symbol')),
    'grammar.to-pda.duplicate-production-id'
        when _grammarToPdaProductionContract(message) =>
      grammarToPdaDuplicateProductionId(_stringArgument(message, 'production')),
    'grammar.to-pda.not-context-free'
        when _matchesArguments(message, const {}) =>
      grammarToPdaNotContextFree,
    'grammar.to-pda.timed-out' when _grammarToPdaTimeoutContract(message) =>
      grammarToPdaConversionTimedOut(
        Duration(milliseconds: _intArgument(message, 'timeout')).inSeconds,
      ),
    'grammar.to-pda.internal-failure'
        when _matchesArguments(message, const {}) =>
      grammarToPdaInternalConversionFailure,
    'grammar.to-pda.gnf-conversion-failed'
        when _matchesArguments(message, const {}) =>
      grammarToPdaGnfConversionFailed,
    'grammar.to-pda.invalid-gnf-result'
        when _matchesArguments(message, const {}) =>
      grammarToPdaInvalidGnfResult,
    'grammar.to-pda.failed' when _matchesArguments(message, const {}) =>
      grammarToPdaAnalysisFailed,
    'grammar.to-pda.analysis-timed-out'
        when _grammarToPdaTimeoutContract(message) =>
      grammarToPdaAnalysisTimedOut(
        Duration(milliseconds: _intArgument(message, 'timeout')).inSeconds,
      ),
    'grammar.to-pda.validate-grammar'
        when _matchesArguments(message, const {}) =>
      grammarToPdaValidateGrammarStep,
    'grammar.to-pda.create-initial-state'
        when _matchesArguments(message, const {}) =>
      grammarToPdaCreateInitialStateStep,
    'grammar.to-pda.create-processing-state'
        when _matchesArguments(message, const {}) =>
      grammarToPdaCreateProcessingStateStep,
    'grammar.to-pda.create-accepting-state'
        when _matchesArguments(message, const {}) =>
      grammarToPdaCreateAcceptingStateStep,
    'grammar.to-pda.add-transitions'
        when _matchesArguments(message, const {}) =>
      grammarToPdaAddTransitionsStep,
    'grammar.to-fsa.missing-nonterminals'
        when _matchesArguments(message, const {}) =>
      grammarToFsaMissingNonterminals,
    'grammar.to-fsa.undeclared-start-symbol'
        when _matchesArguments(message, const {}) =>
      grammarToFsaUndeclaredStartSymbol,
    'grammar.to-fsa.left-side-not-single'
        when _grammarToFsaProductionContract(message) =>
      grammarToFsaLeftSideNotSingle(_stringArgument(message, 'production')),
    'grammar.to-fsa.unknown-left-nonterminal'
        when _grammarToFsaProductionSymbolContract(message) =>
      grammarToFsaUnknownLeftNonterminal(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'grammar.to-fsa.unknown-right-nonterminal'
        when _grammarToFsaProductionSymbolContract(message) =>
      grammarToFsaUnknownRightNonterminal(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'grammar.to-fsa.too-many-right-symbols'
        when _grammarToFsaProductionContract(message) =>
      grammarToFsaTooManyRightSymbols(_stringArgument(message, 'production')),
    'grammar.to-fsa.first-symbol-not-terminal'
        when _grammarToFsaProductionContract(message) =>
      grammarToFsaFirstSymbolNotTerminal(
        _stringArgument(message, 'production'),
      ),
    'grammar.to-fsa.last-symbol-not-nonterminal'
        when _grammarToFsaProductionContract(message) =>
      grammarToFsaLastSymbolNotNonterminal(
        _stringArgument(message, 'production'),
      ),
    'grammar.brute-force.invalid-limit-non-negative'
        when _bruteForceLimitContract(message) =>
      bruteForceInvalidLimitNonNegative(
        _bruteForceLimitName(this, _stringArgument(message, 'limit')),
      ),
    'grammar.brute-force.invalid-limit-positive'
        when _bruteForceLimitContract(message) =>
      bruteForceInvalidLimitPositive(
        _bruteForceLimitName(this, _stringArgument(message, 'limit')),
      ),
    'grammar.brute-force.empty-grammar'
        when _matchesArguments(message, const {}) =>
      bruteForceEmptyGrammar,
    'grammar.brute-force.invalid-start-symbol'
        when _matchesArguments(message, const {}) =>
      bruteForceInvalidStartSymbol,
    'grammar.brute-force.overlapping-symbols'
        when _matchesArguments(message, const {
          'symbols': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-symbol-list',
          ),
        }) =>
      bruteForceOverlappingSymbols(_stringArgument(message, 'symbols')),
    'grammar.brute-force.malformed-production'
        when _matchesArguments(message, const {}) =>
      bruteForceMalformedProduction,
    'grammar.brute-force.duplicate-production-id'
        when _matchesArguments(message, const {}) =>
      bruteForceDuplicateProductionId,
    'grammar.brute-force.undeclared-symbol'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
          'symbol': (kind: StructuredMessageArgumentKind.symbol, role: null),
        }) =>
      bruteForceUndeclaredSymbol(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'grammar.brute-force.invalid-input-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      bruteForceInvalidInputSymbol(_stringArgument(message, 'symbol')),
    'grammar.input-tokenizer.invalid-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'position': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'input-position',
          ),
        }) =>
      grammarInputTokenizationInvalidSymbol(
        _stringArgument(message, 'symbol'),
        _intArgument(message, 'position') + 1,
      ),
    'grammar.brute-force.cancelled' when _matchesArguments(message, const {}) =>
      bruteForceCancelled,
    'grammar.brute-force.rejected-exhausted'
        when _matchesArguments(message, const {}) =>
      bruteForceRejectedExhausted,
    'grammar.brute-force.accepted-at-limit'
        when _bruteForceLimitContract(message) =>
      bruteForceAcceptedAtLimit(
        _bruteForceLimitName(this, _stringArgument(message, 'limit')),
      ),
    'grammar.brute-force.bounded-at-limit'
        when _bruteForceLimitContract(message) =>
      bruteForceBoundedAtLimit(
        _bruteForceLimitName(this, _stringArgument(message, 'limit')),
      ),
    'regex.simplification.step.start-title'
        when _matchesArguments(message, const {}) =>
      regexSimplificationStartTitle,
    'regex.simplification.step.start-explanation'
        when _matchesArguments(message, const {
          'regex': (kind: StructuredMessageArgumentKind.literal, role: 'regex'),
          'star-height': (
            kind: StructuredMessageArgumentKind.integer,
            role: null,
          ),
          'nesting-depth': (
            kind: StructuredMessageArgumentKind.integer,
            role: null,
          ),
          'operator-count': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
        }) =>
      regexSimplificationStartExplanation(
        _stringArgument(message, 'regex'),
        _intArgument(message, 'star-height'),
        _intArgument(message, 'nesting-depth'),
        _intArgument(message, 'operator-count'),
      ),
    'regex.simplification.step.analyze-title'
        when _matchesArguments(message, const {}) =>
      regexSimplificationAnalyzeTitle,
    'regex.simplification.step.analyze-explanation'
        when _matchesArguments(message, const {
          'regex': (kind: StructuredMessageArgumentKind.literal, role: 'regex'),
          'star-height': (
            kind: StructuredMessageArgumentKind.integer,
            role: null,
          ),
          'nesting-depth': (
            kind: StructuredMessageArgumentKind.integer,
            role: null,
          ),
          'alphabet-size': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
          'operator-count': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
        }) =>
      regexSimplificationAnalyzeExplanation(
        _stringArgument(message, 'regex'),
        _intArgument(message, 'star-height'),
        _intArgument(message, 'nesting-depth'),
        _intArgument(message, 'alphabet-size'),
        _intArgument(message, 'operator-count'),
      ),
    'regex.simplification.step.apply-title'
        when _matchesArguments(message, const {
              'rule': (
                kind: StructuredMessageArgumentKind.outcome,
                role: 'simplification-rule',
              ),
            }) &&
            _regexSimplificationRules.contains(
              _stringArgument(message, 'rule'),
            ) =>
      regexSimplificationApplyTitle(
        regexSimplificationRuleName(_stringArgument(message, 'rule')),
      ),
    'regex.simplification.step.apply-explanation'
        when _matchesArguments(message, const {
              'rule': (
                kind: StructuredMessageArgumentKind.outcome,
                role: 'simplification-rule',
              ),
              'matched': (
                kind: StructuredMessageArgumentKind.literal,
                role: 'regex-subexpression',
              ),
              'replacement': (
                kind: StructuredMessageArgumentKind.literal,
                role: 'regex-subexpression',
              ),
              'position': (
                kind: StructuredMessageArgumentKind.integer,
                role: 'regex-position',
              ),
              'length-delta': (
                kind: StructuredMessageArgumentKind.integer,
                role: 'character-delta',
              ),
            }) &&
            _regexSimplificationRules.contains(
              _stringArgument(message, 'rule'),
            ) =>
      regexSimplificationApplyExplanation(
        regexSimplificationRuleName(_stringArgument(message, 'rule')),
        _stringArgument(message, 'matched'),
        _regexSimplificationPosition(this, _intArgument(message, 'position')),
        _stringArgument(message, 'replacement'),
        regexSimplificationRuleDescription(_stringArgument(message, 'rule')),
        _regexSimplificationLengthChange(
          this,
          _intArgument(message, 'length-delta'),
        ),
      ),
    'regex.simplification.step.generate-samples-title'
        when _matchesArguments(message, const {}) =>
      regexSimplificationGenerateSamplesTitle,
    'regex.simplification.step.generate-samples-explanation'
        when _matchesArguments(message, const {
          'regex': (kind: StructuredMessageArgumentKind.literal, role: 'regex'),
          'sample-count': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
          'samples': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'regex-samples',
          ),
        }) =>
      _intArgument(message, 'sample-count') == 0
          ? regexSimplificationGenerateSamplesEmptyExplanation(
              _stringArgument(message, 'regex'),
            )
          : regexSimplificationGenerateSamplesExplanation(
              _stringArgument(message, 'regex'),
              _intArgument(message, 'sample-count'),
              _stringArgument(message, 'samples'),
            ),
    'regex.simplification.step.no-rule-title'
        when _matchesArguments(message, const {}) =>
      regexSimplificationNoRuleTitle,
    'regex.simplification.step.no-rule-explanation'
        when _matchesArguments(message, const {
          'regex': (kind: StructuredMessageArgumentKind.literal, role: 'regex'),
          'rule-count': (kind: StructuredMessageArgumentKind.count, role: null),
        }) =>
      regexSimplificationNoRuleExplanation(
        _stringArgument(message, 'regex'),
        _intArgument(message, 'rule-count'),
      ),
    'regex.simplification.step.completion-title'
        when _matchesArguments(message, const {}) =>
      regexSimplificationCompletionTitle,
    'regex.simplification.step.completion-explanation'
        when _matchesArguments(message, const {
          'original': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'original-regex',
          ),
          'simplified': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'simplified-regex',
          ),
          'original-length': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
          'simplified-length': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
          'reduction-percent': (
            kind: StructuredMessageArgumentKind.number,
            role: 'length-reduction-percent',
          ),
          'rule-count': (kind: StructuredMessageArgumentKind.count, role: null),
          'star-height': (
            kind: StructuredMessageArgumentKind.integer,
            role: null,
          ),
          'nesting-depth': (
            kind: StructuredMessageArgumentKind.integer,
            role: null,
          ),
          'operator-count': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
        }) =>
      regexSimplificationCompletionExplanation(
        _stringArgument(message, 'original'),
        _intArgument(message, 'original-length'),
        _stringArgument(message, 'simplified'),
        _intArgument(message, 'simplified-length'),
        _numArgument(message, 'reduction-percent').toDouble(),
        _intArgument(message, 'rule-count'),
        _intArgument(message, 'star-height'),
        _intArgument(message, 'nesting-depth'),
        _intArgument(message, 'operator-count'),
      ),
    'regex.simplification.step.no-rule-summary'
        when _matchesArguments(message, const {}) =>
      regexSimplificationNoRuleSummary,
    'regex.simplification.step.rule-summary'
        when _matchesArguments(message, const {
              'rule': (
                kind: StructuredMessageArgumentKind.outcome,
                role: 'simplification-rule',
              ),
              'matched': (
                kind: StructuredMessageArgumentKind.literal,
                role: 'regex-subexpression',
              ),
              'replacement': (
                kind: StructuredMessageArgumentKind.literal,
                role: 'regex-subexpression',
              ),
            }) &&
            _regexSimplificationRules.contains(
              _stringArgument(message, 'rule'),
            ) =>
      regexSimplificationRuleSummary(
        regexSimplificationRuleName(_stringArgument(message, 'rule')),
        _stringArgument(message, 'matched'),
        _stringArgument(message, 'replacement'),
      ),
    'regex.simplification.step-type.label'
        when _regexSimplificationStepTypeContract(message) =>
      regexSimplificationStepTypeLabel(_stringArgument(message, 'type')),
    'regex.simplification.step-type.description'
        when _regexSimplificationStepTypeContract(message) =>
      regexSimplificationStepTypeDescription(_stringArgument(message, 'type')),
    'regex.simplification.rule.name'
        when _regexSimplificationRuleContract(message) =>
      regexSimplificationRuleName(_stringArgument(message, 'rule')),
    'regex.simplification.rule.description'
        when _regexSimplificationRuleContract(message) =>
      regexSimplificationRuleDescription(_stringArgument(message, 'rule')),
    'regex.simplification.empty-input'
        when _matchesArguments(message, const {}) =>
      regexSimplificationEmptyInput,
    'regex.simplification.unmatched-closing-parenthesis'
        when _matchesArguments(message, const {
          'position': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'regex-position',
          ),
        }) =>
      regexSimplificationUnmatchedClosingParenthesis(
        _intArgument(message, 'position') + 1,
      ),
    'regex.simplification.unclosed-opening-parentheses'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'parenthesis-count',
          ),
        }) =>
      regexSimplificationUnclosedOpeningParentheses(
        _intArgument(message, 'count'),
      ),
    'regex.to-nfa.step.start-title' when _matchesArguments(message, const {}) =>
      regexToNfaStartTitle,
    'regex.to-nfa.step.start-explanation'
        when _matchesArguments(message, const {
          'regex': (kind: StructuredMessageArgumentKind.literal, role: 'regex'),
        }) =>
      regexToNfaStartExplanation(_stringArgument(message, 'regex')),
    'regex.to-nfa.step.basic-symbol-title'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'regex-symbol',
          ),
        }) =>
      regexToNfaBasicSymbolTitle(_stringArgument(message, 'symbol')),
    'regex.to-nfa.step.basic-symbol-explanation'
        when _regexToNfaBasicSymbolContract(message) =>
      regexToNfaBasicSymbolExplanation(
        _stringArgument(message, 'symbol'),
        _regexToNfaPosition(this, _intArgument(message, 'position')),
        _stringArgument(message, 'start-state'),
        _stringArgument(message, 'accept-state'),
        _intArgument(message, 'state-count'),
        _intArgument(message, 'transition-count'),
        _stringArgument(message, 'transitions'),
        _intArgument(message, 'stack-size'),
      ),
    'regex.to-nfa.step.concatenation-title'
        when _matchesArguments(message, const {}) =>
      regexToNfaConcatenationTitle,
    'regex.to-nfa.step.concatenation-explanation'
        when _regexToNfaConcatenationContract(message) =>
      regexToNfaConcatenationExplanation(
        _regexToNfaPosition(this, _intArgument(message, 'position')),
        _stringArgument(message, 'first-fragment'),
        _stringArgument(message, 'second-fragment'),
        _stringArgument(message, 'start-state'),
        _stringArgument(message, 'accept-states'),
        _stringArgument(message, 'transitions'),
        _intArgument(message, 'stack-size'),
      ),
    'regex.to-nfa.step.union-title' when _matchesArguments(message, const {}) =>
      regexToNfaUnionTitle,
    'regex.to-nfa.step.union-explanation'
        when _regexToNfaUnionContract(message) =>
      regexToNfaUnionExplanation(
        _regexToNfaPosition(this, _intArgument(message, 'position')),
        _stringArgument(message, 'pattern'),
        _stringArgument(message, 'start-state'),
        _stringArgument(message, 'accept-state'),
        _stringArgument(message, 'transitions'),
        _intArgument(message, 'stack-size'),
      ),
    'regex.to-nfa.step.kleene-star-title'
        when _matchesArguments(message, const {}) =>
      regexToNfaKleeneStarTitle,
    'regex.to-nfa.step.kleene-star-explanation'
        when _regexToNfaUnaryContract(message) =>
      regexToNfaKleeneStarExplanation(
        _stringArgument(message, 'fragment'),
        _regexToNfaPosition(this, _intArgument(message, 'position')),
        _stringArgument(message, 'start-state'),
        _stringArgument(message, 'accept-state'),
        _stringArgument(message, 'transitions'),
        _intArgument(message, 'stack-size'),
      ),
    'regex.to-nfa.step.plus-title' when _matchesArguments(message, const {}) =>
      regexToNfaPlusTitle,
    'regex.to-nfa.step.plus-explanation'
        when _regexToNfaUnaryContract(message) =>
      regexToNfaPlusExplanation(
        _stringArgument(message, 'fragment'),
        _regexToNfaPosition(this, _intArgument(message, 'position')),
        _stringArgument(message, 'start-state'),
        _stringArgument(message, 'accept-state'),
        _stringArgument(message, 'transitions'),
        _intArgument(message, 'stack-size'),
      ),
    'regex.to-nfa.step.optional-title'
        when _matchesArguments(message, const {}) =>
      regexToNfaOptionalTitle,
    'regex.to-nfa.step.optional-explanation'
        when _regexToNfaUnaryContract(message) =>
      regexToNfaOptionalExplanation(
        _stringArgument(message, 'fragment'),
        _regexToNfaPosition(this, _intArgument(message, 'position')),
        _stringArgument(message, 'start-state'),
        _stringArgument(message, 'accept-state'),
        _stringArgument(message, 'transitions'),
        _intArgument(message, 'stack-size'),
      ),
    'regex.to-nfa.step.complete-title'
        when _matchesArguments(message, const {}) =>
      regexToNfaCompleteTitle,
    'regex.to-nfa.step.complete-explanation'
        when _regexToNfaCompleteContract(message) =>
      regexToNfaCompleteExplanation(
        _stringArgument(message, 'start-state'),
        _stringArgument(message, 'accept-state'),
        _intArgument(message, 'state-count'),
        _intArgument(message, 'transition-count'),
      ),
    'regex.to-nfa.step-type.label' when _regexToNfaStepTypeContract(message) =>
      regexToNfaStepTypeLabel(_stringArgument(message, 'type')),
    'regex.to-nfa.step-type.description'
        when _regexToNfaStepTypeContract(message) =>
      regexToNfaStepTypeDescription(_stringArgument(message, 'type')),
    'automaton.fa-to-regex.step-type.label'
        when _faToRegexStepTypeContract(message) =>
      faToRegexStepTypeLabel(_stringArgument(message, 'type')),
    'automaton.fa-to-regex.step-type.description'
        when _faToRegexStepTypeContract(message) =>
      faToRegexStepTypeDescription(_stringArgument(message, 'type')),
    'automaton.fa-to-regex.empty-automaton'
        when _matchesArguments(message, const {}) =>
      faToRegexEmptyAutomaton,
    'automaton.fa-to-regex.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      faToRegexMissingInitialState,
    'automaton.fa-to-regex.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      faToRegexInitialStateOutsideSet,
    'automaton.fa-to-regex.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      faToRegexAcceptingStateOutsideSet,
    'automaton.fa-to-regex.simplification-failed'
        when _matchesArguments(message, const {}) =>
      faToRegexSimplificationFailed,
    'automaton.fa-to-regex.internal-failure'
        when _matchesArguments(message, const {}) =>
      faToRegexInternalFailure,
    'automaton.fsa-to-grammar.empty-automaton'
        when _matchesArguments(message, const {}) =>
      fsaToGrammarEmptyAutomaton,
    'automaton.fsa-to-grammar.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      fsaToGrammarMissingInitialState,
    'automaton.fsa-to-grammar.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      fsaToGrammarInitialStateOutsideSet,
    'automaton.fsa-to-grammar.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      fsaToGrammarAcceptingStateOutsideSet,
    'automaton.dfa-operations.missing-initial-state'
        when _dfaOperationsContextContract(message) =>
      dfaOperationsMissingInitialState(
        _dfaContextSelectValue(_stringArgument(message, 'context')),
      ),
    'automaton.dfa-operations.nondeterministic'
        when _dfaOperationsContextContract(message) =>
      dfaOperationsNondeterministic(
        _dfaContextSelectValue(_stringArgument(message, 'context')),
      ),
    'automaton.dfa-operations.epsilon-transitions-not-allowed'
        when _dfaOperationsContextContract(message) =>
      dfaOperationsEpsilonTransitionsNotAllowed(
        _dfaContextSelectValue(_stringArgument(message, 'context')),
      ),
    'automaton.dfa-operations.symbol-outside-alphabet'
        when _dfaOperationsContextSymbolContract(message) =>
      dfaOperationsSymbolOutsideAlphabet(
        _dfaContextSelectValue(_stringArgument(message, 'context')),
        _stringArgument(message, 'symbol'),
      ),
    'automaton.dfa-operations.empty-alphabet-with-labeled-transitions'
        when _dfaOperationsOperandContract(message) =>
      dfaOperationsEmptyAlphabetWithLabeledTransitions(
        _stringArgument(message, 'operand'),
      ),
    'automaton.dfa-operations.both-operands-missing-initial-state'
        when _matchesArguments(message, const {}) =>
      dfaOperationsBothOperandsMissingInitialState,
    'automaton.dfa-operations.operation-failed'
        when _dfaOperationsOperationContract(message) =>
      dfaOperationsOperationFailed(
        _dfaOperationSelectValue(_stringArgument(message, 'operation')),
      ),
    'automaton.dfa-operations.epsilon-removal-failed'
        when _matchesArguments(message, const {}) =>
      dfaOperationsEpsilonRemovalFailed,
    'automaton.dfa-minimization.empty-dfa'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationEmptyDfa,
    'automaton.dfa-minimization.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationMissingInitialState,
    'automaton.dfa-minimization.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationInitialStateOutsideSet,
    'automaton.dfa-minimization.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationAcceptingStateOutsideSet,
    'automaton.dfa-minimization.nondeterministic-input'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationNondeterministicInput,
    'automaton.dfa-minimization.minimization-failed'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationFailed,
    'automaton.dfa-minimization.minimization-with-steps-failed'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationWithStepsFailed,
    'grammar.cfg-toolkit.reduce-failed'
        when _matchesArguments(message, const {}) =>
      cfgToolkitReduceFailed,
    'grammar.cfg-toolkit.to-cnf-failed'
        when _matchesArguments(message, const {}) =>
      cfgToolkitToCnfFailed,
    'grammar.cfg-toolkit.to-gnf-failed'
        when _matchesArguments(message, const {}) =>
      cfgToolkitToGnfFailed,
    'grammar.cyk.timed-out' when _matchesArguments(message, const {}) =>
      cykTimedOut,
    'grammar.cyk.input-rejected' when _grammarParserInputContract(message) =>
      cykInputRejected(_stringArgument(message, 'input')),
    'grammar.cyk.parse-failed' when _matchesArguments(message, const {}) =>
      cykParseFailed,
    'grammar.parser.empty-grammar' when _matchesArguments(message, const {}) =>
      grammarParserEmptyGrammar,
    'grammar.parser.missing-start-symbol'
        when _matchesArguments(message, const {}) =>
      grammarParserMissingStartSymbol,
    'grammar.parser.start-symbol-not-nonterminal'
        when _matchesArguments(message, const {}) =>
      grammarParserStartSymbolNotNonterminal,
    'grammar.parser.input-rejected' when _grammarParserInputContract(message) =>
      grammarParserInputRejected(_stringArgument(message, 'input')),
    'grammar.parser.all-strategies-failed'
        when _grammarParserStrategyContract(message) =>
      grammarParserAllStrategiesFailed(_stringArgument(message, 'strategy')),
    'grammar.parser.generated-strings-failed'
        when _matchesArguments(message, const {}) =>
      grammarParserGeneratedStringsFailed,
    'grammar.parser.ll1-step-limit-invalid'
        when _grammarParserLimitContract(message) =>
      grammarParserLl1StepLimitInvalid(_intArgument(message, 'limit')),
    'grammar.parser.ll1-conflict'
        when _grammarParserLl1ConflictContract(message) =>
      grammarParserLl1Conflict(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'lookahead'),
        _stringArgument(message, 'alternatives'),
      ),
    'grammar.parser.ll1-cancelled' when _matchesArguments(message, const {}) =>
      grammarParserLl1Cancelled,
    'grammar.parser.ll1-timed-out'
        when _grammarParserTimeoutContract(message) =>
      grammarParserLl1TimedOut(_intArgument(message, 'timeout')),
    'grammar.parser.ll1-step-limit-reached'
        when _grammarParserLimitContract(message) =>
      grammarParserLl1StepLimitReached(_intArgument(message, 'limit')),
    'grammar.parser.ll1-trailing-input'
        when _grammarParserTrailingInputContract(message) =>
      grammarParserLl1TrailingInput(
        _stringArgument(message, 'lookahead'),
        _intArgument(message, 'position'),
      ),
    'grammar.parser.ll1-unexpected-end'
        when _grammarParserExpectedSymbolContract(message) =>
      grammarParserLl1UnexpectedEnd(_stringArgument(message, 'expected')),
    'grammar.parser.ll1-terminal-mismatch'
        when _grammarParserTerminalMismatchContract(message) =>
      grammarParserLl1TerminalMismatch(
        _stringArgument(message, 'expected'),
        _stringArgument(message, 'found'),
        _intArgument(message, 'position'),
      ),
    'grammar.parser.ll1-empty-table-cell'
        when _grammarParserEmptyTableCellContract(message) =>
      grammarParserLl1EmptyTableCell(
        _stringArgument(message, 'non-terminal'),
        _stringArgument(message, 'lookahead'),
        _stringArgument(message, 'expected'),
      ),
    'grammar.parser.ll1-empty-stack'
        when _matchesArguments(message, const {}) =>
      grammarParserLl1EmptyStack,
    'grammar.parser.earley-malformed-production'
        when _matchesArguments(message, const {}) =>
      grammarParserEarleyMalformedProduction,
    'grammar.parser.earley-missing-start-symbol'
        when _matchesArguments(message, const {}) =>
      grammarParserEarleyMissingStartSymbol,
    'grammar.parser.earley-timed-out'
        when _grammarParserTimeoutContract(message) =>
      grammarParserEarleyTimedOut(_intArgument(message, 'timeout')),
    'grammar.parser.recursive-descent-timed-out'
        when _matchesArguments(message, const {}) =>
      grammarParserRecursiveDescentTimedOut,
    'grammar.parser.recursive-descent-failed'
        when _matchesArguments(message, const {}) =>
      grammarParserRecursiveDescentFailed,
    'grammar.lr1.stale-construction'
        when _matchesArguments(message, const {}) =>
      lr1ParserStaleConstruction,
    'grammar.lr1.invalid-grammar' when _matchesArguments(message, const {}) =>
      lr1ParserInvalidGrammar,
    'grammar.lr1.missing-start-symbol'
        when _matchesArguments(message, const {}) =>
      lr1ParserMissingStartSymbol,
    'grammar.lr1.malformed-production'
        when _matchesArguments(message, const {}) =>
      lr1ParserMalformedProduction,
    'grammar.lr1.duplicate-production-id'
        when _lr1ProductionContract(message) =>
      lr1ParserDuplicateProductionId(_stringArgument(message, 'production')),
    'grammar.lr1.undeclared-symbol'
        when _lr1ProductionSymbolContract(message) =>
      lr1ParserUndeclaredSymbol(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'grammar.lr1.construction-cancelled'
        when _matchesArguments(message, const {}) =>
      lr1ParserConstructionCancelled,
    'grammar.lr1.construction-timed-out' when _lr1TimeoutContract(message) =>
      lr1ParserConstructionTimedOut(_intArgument(message, 'timeout')),
    'grammar.lr1.construction-state-limit'
        when _matchesArguments(message, const {}) =>
      lr1ParserConstructionStateLimit,
    'grammar.lr1.construction-item-limit'
        when _matchesArguments(message, const {}) =>
      lr1ParserConstructionItemLimit,
    'grammar.lr1.conflict' when _lr1StateLookaheadContract(message) =>
      lr1ParserConflict(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'lookahead'),
      ),
    'grammar.lr1.cancelled' when _matchesArguments(message, const {}) =>
      lr1ParserCancelled,
    'grammar.lr1.timed-out' when _lr1TimeoutContract(message) =>
      lr1ParserTimedOut(_intArgument(message, 'timeout')),
    'grammar.lr1.step-limit-reached' when _lr1LimitContract(message) =>
      lr1ParserStepLimitReached(_intArgument(message, 'limit')),
    'grammar.lr1.empty-action-cell' when _lr1StateLookaheadContract(message) =>
      lr1ParserEmptyActionCell(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'lookahead'),
      ),
    'grammar.lr1.action-conflict' when _lr1StateLookaheadContract(message) =>
      lr1ParserActionConflict(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'lookahead'),
      ),
    'grammar.lr1.invalid-parser-state'
        when _matchesArguments(message, const {}) =>
      lr1ParserInvalidParserState,
    'grammar.lr1.missing-goto' when _lr1GotoContract(message) =>
      lr1ParserMissingGoto(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'non-terminal'),
      ),
    'grammar.lr1.shifted'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'target-state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'parser-state-id',
          ),
        }) =>
      lr1ParserShifted(
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'target-state'),
      ),
    'grammar.lr1.reduced'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
          'left-side': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
          'right-side': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'grammar-production-right-side',
          ),
        }) =>
      lr1ParserReduced(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'left-side'),
        _stringArgument(message, 'right-side'),
      ),
    'grammar.lr1.accepted' when _matchesArguments(message, const {}) =>
      lr1ParserAccepted,
    'tm.simulation.empty-machine' when _matchesArguments(message, const {}) =>
      tmSimulationEmptyMachine,
    'tm.simulation.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      tmSimulationMissingInitialState,
    'tm.simulation.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      tmSimulationInitialStateOutsideSet,
    'tm.simulation.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      tmSimulationAcceptingStateOutsideSet,
    'tm.simulation.invalid-input-symbol'
        when _tmSymbolContract(message, role: 'input-symbol') =>
      tmSimulationInvalidInputSymbol(_stringArgument(message, 'symbol')),
    'tm.simulation.operations-per-batch-invalid'
        when _matchesArguments(message, const {}) =>
      tmSimulationOperationsPerBatchInvalid,
    'tm.simulation.nondeterministic-conflict'
        when _tmConflictContract(message) =>
      tmSimulationNondeterministicConflict(
        _intArgument(message, 'count'),
        _stringArgument(message, 'state'),
        _stringArgument(message, 'symbol'),
      ),
    'tm.simulation.rejected-no-accepting-configuration'
        when _matchesArguments(message, const {}) =>
      tmSimulationRejectedNoAcceptingConfiguration,
    'tm.simulation.input-not-accepted'
        when _matchesArguments(message, const {}) =>
      tmSimulationInputNotAccepted,
    'tm.simulation.timeout' when _matchesArguments(message, const {}) =>
      tmSimulationTimeout,
    'tm.simulation.infinite-loop' when _matchesArguments(message, const {}) =>
      tmSimulationInfiniteLoop,
    'tm.simulation.step-limit' when _matchesArguments(message, const {}) =>
      tmSimulationStepLimit,
    'tm.simulation.configuration-limit'
        when _matchesArguments(message, const {}) =>
      tmSimulationConfigurationLimit,
    'tm.simulation.dtm-failure' when _tmErrorContract(message) =>
      tmSimulationDtmFailure(_stringArgument(message, 'error')),
    'tm.simulation.ntm-failure' when _tmErrorContract(message) =>
      tmSimulationNtmFailure(_stringArgument(message, 'error')),
    'tm.simulation.simulation-failure' when _tmErrorContract(message) =>
      tmSimulationGenericFailure(_stringArgument(message, 'error')),
    'tm.simulation.accepted-strings-failure' when _tmErrorContract(message) =>
      tmSimulationAcceptedStringsFailure(_stringArgument(message, 'error')),
    'tm.simulation.rejected-strings-failure' when _tmErrorContract(message) =>
      tmSimulationRejectedStringsFailure(_stringArgument(message, 'error')),
    'tm.simulation.analysis-failure' when _tmErrorContract(message) =>
      tmSimulationAnalysisFailure(_stringArgument(message, 'error')),
    'tm.simulation.transition-title'
        when _matchesArguments(message, const {}) =>
      tmSimulationTransitionTitle,
    'tm.simulation.read-symbol' when _tmReadSymbolContract(message) =>
      tmSimulationReadSymbol(
        _stringArgument(message, 'symbol'),
        _intArgument(message, 'position'),
        _stringArgument(message, 'state'),
      ),
    'tm.simulation.applied-rule' when _tmAppliedRuleContract(message) =>
      tmSimulationAppliedRule(
        _stringArgument(message, 'from-state'),
        _stringArgument(message, 'read-symbol'),
        _stringArgument(message, 'to-state'),
        _stringArgument(message, 'write-symbol'),
        _stringArgument(message, 'direction'),
      ),
    'tm.simulation.wrote-symbol' when _tmWroteSymbolContract(message) =>
      tmSimulationWroteSymbol(
        _stringArgument(message, 'symbol'),
        _intArgument(message, 'position'),
      ),
    'tm.simulation.moved-head' when _tmMovedHeadContract(message) =>
      tmSimulationMovedHead(
        _stringArgument(message, 'direction'),
        _intArgument(message, 'position'),
      ),
    'tm.execution.empty-machine' when _matchesArguments(message, const {}) =>
      tmExecutionEmptyMachine,
    'tm.execution.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      tmExecutionMissingInitialState,
    'tm.execution.step-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmExecutionStepLimitInvalid,
    'tm.execution.configuration-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmExecutionConfigurationLimitInvalid,
    'tm.execution.timeout-invalid' when _matchesArguments(message, const {}) =>
      tmExecutionTimeoutInvalid,
    'tm.execution.operations-per-batch-invalid'
        when _matchesArguments(message, const {}) =>
      tmExecutionOperationsPerBatchInvalid,
    'tm.execution.invalid-input-symbol'
        when _tmSymbolContract(message, role: 'input-symbol') =>
      tmExecutionInvalidInputSymbol(_stringArgument(message, 'symbol')),
    'tm.execution.invalid-machine' when _tmDetailContract(message) =>
      tmExecutionInvalidMachine(_stringArgument(message, 'detail')),
    'tm.execution.cancelled' when _matchesArguments(message, const {}) =>
      tmExecutionCancelled,
    'tm.execution.timeout-before-resolution'
        when _matchesArguments(message, const {}) =>
      tmExecutionTimeoutBeforeResolution,
    'tm.execution.entered-final-state' when _tmPolicyContract(message) =>
      tmExecutionEnteredFinalState(_stringArgument(message, 'policy')),
    'tm.execution.halted-accepted' when _tmPolicyContract(message) =>
      tmExecutionHaltedAccepted(_stringArgument(message, 'policy')),
    'tm.execution.halted-rejected' when _matchesArguments(message, const {}) =>
      tmExecutionHaltedRejected,
    'tm.execution.deterministic-conflict' when _tmConflictContract(message) =>
      tmExecutionDeterministicConflict(
        _intArgument(message, 'count'),
        _stringArgument(message, 'state'),
        _stringArgument(message, 'symbol'),
      ),
    'tm.execution.step-limit' when _matchesArguments(message, const {}) =>
      tmExecutionStepLimit,
    'tm.execution.configuration-limit'
        when _matchesArguments(message, const {}) =>
      tmExecutionConfigurationLimit,
    'tm.execution.deterministic-cycle'
        when _matchesArguments(message, const {}) =>
      tmExecutionDeterministicCycle,
    'tm.execution.branch-step-limit'
        when _matchesArguments(message, const {}) =>
      tmExecutionBranchStepLimit,
    'tm.execution.every-branch-rejected'
        when _matchesArguments(message, const {}) =>
      tmExecutionEveryBranchRejected,
    'tm.execution.explored-graph-rejected'
        when _matchesArguments(message, const {}) =>
      tmExecutionExploredGraphRejected,
    'tm.space-profile.empty-machine'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileEmptyMachine,
    'tm.space-profile.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileMissingInitialState,
    'tm.space-profile.max-input-length-invalid'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileMaxInputLengthInvalid,
    'tm.space-profile.candidate-cap-invalid'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileCandidateCapInvalid,
    'tm.space-profile.step-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileStepLimitInvalid,
    'tm.space-profile.configuration-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileConfigurationLimitInvalid,
    'tm.space-profile.timeout-invalid'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileTimeoutInvalid,
    'tm.space-profile.operations-per-batch-invalid'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileOperationsPerBatchInvalid,
    'tm.space-profile.missing-space-metrics'
        when _matchesArguments(message, const {}) =>
      tmSpaceProfileMissingSpaceMetrics,
    'tm.time-profile.max-length-invalid'
        when _matchesArguments(message, const {}) =>
      tmTimeProfileMaxLengthInvalid,
    'tm.time-profile.candidate-cap-invalid'
        when _matchesArguments(message, const {}) =>
      tmTimeProfileCandidateCapInvalid,
    'tm.time-profile.step-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmTimeProfileStepLimitInvalid,
    'tm.time-profile.configuration-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmTimeProfileConfigurationLimitInvalid,
    'tm.time-profile.timeout-invalid'
        when _matchesArguments(message, const {}) =>
      tmTimeProfileTimeoutInvalid,
    'tm.time-profile.operations-per-batch-invalid'
        when _matchesArguments(message, const {}) =>
      tmTimeProfileOperationsPerBatchInvalid,
    'tm.time-profile.complete' when _matchesArguments(message, const {}) =>
      tmTimeProfileComplete,
    'tm.time-profile.incomplete' when _matchesArguments(message, const {}) =>
      tmTimeProfileIncomplete,
    'tm.time-profile.cancelled' when _matchesArguments(message, const {}) =>
      tmTimeProfileCancelled,
    'tm.time-profile.invalid-machine'
        when _matchesArguments(message, const {}) =>
      tmTimeProfileInvalidMachine,
    'tm.reachability.empty-machine' when _matchesArguments(message, const {}) =>
      tmReachabilityEmptyMachine,
    'tm.reachability.invalid-initial-state'
        when _matchesArguments(message, const {}) =>
      tmReachabilityInvalidInitialState,
    'tm.reachability.inputs-required'
        when _matchesArguments(message, const {}) =>
      tmReachabilityInputsRequired,
    'tm.reachability.step-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmReachabilityStepLimitInvalid,
    'tm.reachability.configuration-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmReachabilityConfigurationLimitInvalid,
    'tm.reachability.timeout-invalid'
        when _matchesArguments(message, const {}) =>
      tmReachabilityTimeoutInvalid,
    'tm.reachability.operations-per-batch-invalid'
        when _matchesArguments(message, const {}) =>
      tmReachabilityOperationsPerBatchInvalid,
    'tm.reachability.non-tm-transition'
        when _matchesArguments(message, const {}) =>
      tmReachabilityNonTmTransition,
    'tm.reachability.transition-endpoint-outside-set'
        when _tmTransitionContract(message) =>
      tmReachabilityTransitionEndpointOutsideSet(
        _stringArgument(message, 'transition'),
      ),
    'tm.reachability.input-symbol-outside-alphabet'
        when _tmInputSymbolOutsideAlphabetContract(message) =>
      tmReachabilityInputSymbolOutsideAlphabet(
        _stringArgument(message, 'input'),
        _stringArgument(message, 'symbol'),
      ),
    'tm.reachability.cancelled' when _matchesArguments(message, const {}) =>
      tmReachabilityCancelled,
    'tm.reachability.timeout' when _matchesArguments(message, const {}) =>
      tmReachabilityTimeout,
    'tm.reachability.configuration-limit'
        when _matchesArguments(message, const {}) =>
      tmReachabilityConfigurationLimit,
    'tm.reachability.step-limit' when _matchesArguments(message, const {}) =>
      tmReachabilityStepLimit,
    'tm.reachability.complete' when _matchesArguments(message, const {}) =>
      tmReachabilityComplete,
    'tm.language-explorer.max-input-length-invalid'
        when _matchesArguments(message, const {}) =>
      tmLanguageExplorerMaxInputLengthInvalid,
    'tm.language-explorer.candidate-cap-invalid'
        when _matchesArguments(message, const {}) =>
      tmLanguageExplorerCandidateCapInvalid,
    'tm.language-explorer.step-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmLanguageExplorerStepLimitInvalid,
    'tm.language-explorer.configuration-limit-invalid'
        when _matchesArguments(message, const {}) =>
      tmLanguageExplorerConfigurationLimitInvalid,
    'tm.language-explorer.timeout-invalid'
        when _matchesArguments(message, const {}) =>
      tmLanguageExplorerTimeoutInvalid,
    'tm.language-explorer.operations-per-batch-invalid'
        when _matchesArguments(message, const {}) =>
      tmLanguageExplorerOperationsPerBatchInvalid,
    _
        when message.namespace == 'automaton.fa-to-regex.step' &&
            _faToRegexStepContract(message) =>
      _resolveFaToRegexStep(this, message),
    'automaton.fsa-kleene-star.empty-operand'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarEmptyOperand,
    'automaton.fsa-kleene-star.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarMissingInitialState,
    'automaton.fsa-kleene-star.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarInitialStateOutsideSet,
    'automaton.fsa-kleene-star.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarAcceptingStateOutsideSet,
    'automaton.fsa-kleene-star.non-fsa-transition'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarNonFsaTransition,
    'automaton.fsa-kleene-star.unknown-transition-endpoint'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarUnknownTransitionEndpoint,
    'automaton.fsa-kleene-star.invalid-transition'
        when _fsaKleeneStarTransitionContract(message) =>
      fsaKleeneStarInvalidTransition(_stringArgument(message, 'transition')),
    'automaton.fsa-kleene-star.duplicate-state-ids'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarDuplicateStateIds,
    'automaton.fsa-kleene-star.duplicate-transition-ids'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarDuplicateTransitionIds,
    'automaton.fsa-kleene-star.invalid-result'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarInvalidResult,
    'automaton.fsa-kleene-star.internal-failure'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarInternalFailure,
    'automaton.fsa-kleene-star.clone-title'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarCloneTitle,
    'automaton.fsa-kleene-star.entry-title'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarEntryTitle,
    'automaton.fsa-kleene-star.repeat-title'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarRepeatTitle,
    'automaton.fsa-kleene-star.exit-title'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarExitTitle,
    'automaton.fsa-kleene-star.clone-explanation'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarCloneExplanation,
    'automaton.fsa-kleene-star.entry-explanation'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarEntryExplanation,
    'automaton.fsa-kleene-star.repeat-explanation'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarRepeatExplanation,
    'automaton.fsa-kleene-star.repeat-empty-explanation'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarRepeatEmptyExplanation,
    'automaton.fsa-kleene-star.exit-explanation'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarExitExplanation,
    'automaton.fsa-kleene-star.exit-empty-explanation'
        when _matchesArguments(message, const {}) =>
      fsaKleeneStarExitEmptyExplanation,
    'automaton.fsa-reversal.empty-operand'
        when _matchesArguments(message, const {}) =>
      fsaReversalEmptyOperand,
    'automaton.fsa-reversal.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      fsaReversalMissingInitialState,
    'automaton.fsa-reversal.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      fsaReversalInitialStateOutsideSet,
    'automaton.fsa-reversal.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      fsaReversalAcceptingStateOutsideSet,
    'automaton.fsa-reversal.non-fsa-transition'
        when _matchesArguments(message, const {}) =>
      fsaReversalNonFsaTransition,
    'automaton.fsa-reversal.unknown-transition-endpoint'
        when _matchesArguments(message, const {}) =>
      fsaReversalUnknownTransitionEndpoint,
    'automaton.fsa-reversal.invalid-transition'
        when _fsaReversalTransitionContract(message) =>
      fsaReversalInvalidTransition(_stringArgument(message, 'transition')),
    'automaton.fsa-reversal.duplicate-state-ids'
        when _matchesArguments(message, const {}) =>
      fsaReversalDuplicateStateIds,
    'automaton.fsa-reversal.duplicate-transition-ids'
        when _matchesArguments(message, const {}) =>
      fsaReversalDuplicateTransitionIds,
    'automaton.fsa-reversal.invalid-result'
        when _matchesArguments(message, const {}) =>
      fsaReversalInvalidResult,
    'automaton.fsa-reversal.internal-failure'
        when _matchesArguments(message, const {}) =>
      fsaReversalInternalFailure,
    'automaton.fsa-reversal.clone-title'
        when _matchesArguments(message, const {}) =>
      fsaReversalCloneTitle,
    'automaton.fsa-reversal.reverse-title'
        when _matchesArguments(message, const {}) =>
      fsaReversalReverseTitle,
    'automaton.fsa-reversal.entry-title'
        when _matchesArguments(message, const {}) =>
      fsaReversalEntryTitle,
    'automaton.fsa-reversal.accepting-title'
        when _matchesArguments(message, const {}) =>
      fsaReversalAcceptingTitle,
    'automaton.fsa-reversal.clone-explanation'
        when _matchesArguments(message, const {}) =>
      fsaReversalCloneExplanation,
    'automaton.fsa-reversal.reverse-explanation'
        when _matchesArguments(message, const {}) =>
      fsaReversalReverseExplanation,
    'automaton.fsa-reversal.entry-explanation'
        when _matchesArguments(message, const {}) =>
      fsaReversalEntryExplanation,
    'automaton.fsa-reversal.entry-empty-explanation'
        when _matchesArguments(message, const {}) =>
      fsaReversalEntryEmptyExplanation,
    'automaton.fsa-reversal.accepting-explanation'
        when _matchesArguments(message, const {}) =>
      fsaReversalAcceptingExplanation,
    'automaton.fsa-concatenation.empty-operand'
        when _fsaConcatenationOperandContract(message) =>
      fsaConcatenationEmptyOperand(
        _fsaConcatenationOperandLabel(this, message),
      ),
    'automaton.fsa-concatenation.missing-initial-state'
        when _fsaConcatenationOperandContract(message) =>
      fsaConcatenationMissingInitialState(
        _fsaConcatenationOperandLabel(this, message),
      ),
    'automaton.fsa-concatenation.initial-state-outside-set'
        when _fsaConcatenationOperandContract(message) =>
      fsaConcatenationInitialStateOutsideSet(
        _fsaConcatenationOperandLabel(this, message),
      ),
    'automaton.fsa-concatenation.accepting-state-outside-set'
        when _fsaConcatenationOperandContract(message) =>
      fsaConcatenationAcceptingStateOutsideSet(
        _fsaConcatenationOperandLabel(this, message),
      ),
    'automaton.fsa-concatenation.non-fsa-transition'
        when _fsaConcatenationOperandContract(message) =>
      fsaConcatenationNonFsaTransition(
        _fsaConcatenationOperandLabel(this, message),
      ),
    'automaton.fsa-concatenation.unknown-transition-endpoint'
        when _fsaConcatenationOperandContract(message) =>
      fsaConcatenationUnknownTransitionEndpoint(
        _fsaConcatenationOperandLabel(this, message),
      ),
    'automaton.fsa-concatenation.invalid-transition'
        when _fsaConcatenationTransitionContract(message) =>
      fsaConcatenationInvalidTransition(
        _fsaConcatenationOperandLabel(this, message),
        _stringArgument(message, 'transition'),
      ),
    'automaton.fsa-concatenation.duplicate-state-ids'
        when _matchesArguments(message, const {}) =>
      fsaConcatenationDuplicateStateIds,
    'automaton.fsa-concatenation.duplicate-transition-ids'
        when _matchesArguments(message, const {}) =>
      fsaConcatenationDuplicateTransitionIds,
    'automaton.fsa-concatenation.invalid-result'
        when _matchesArguments(message, const {}) =>
      fsaConcatenationInvalidResult,
    'automaton.fsa-concatenation.internal-failure'
        when _matchesArguments(message, const {}) =>
      fsaConcatenationInternalFailure,
    'automaton.fsa-concatenation.clone-title'
        when _fsaConcatenationOperandContract(message) =>
      fsaConcatenationCloneTitle(_fsaConcatenationOperandLabel(this, message)),
    'automaton.fsa-concatenation.connect-title'
        when _matchesArguments(message, const {}) =>
      fsaConcatenationConnectTitle,
    'automaton.fsa-concatenation.clone-explanation'
        when _fsaConcatenationOperandContract(message) =>
      fsaConcatenationCloneExplanation(
        _fsaConcatenationOperandLabel(this, message),
      ),
    'automaton.fsa-concatenation.connect-explanation'
        when _matchesArguments(message, const {}) =>
      fsaConcatenationConnectExplanation,
    'automaton.fsa-concatenation.connect-empty-explanation'
        when _matchesArguments(message, const {}) =>
      fsaConcatenationConnectEmptyExplanation,
    'algorithm.fsa-determinizer.failed'
        when _matchesArguments(message, const {
          'automaton': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'automaton-label',
          ),
        }) =>
      fsaDeterminizationFailed(_stringArgument(message, 'automaton')),
    'language.comparison.empty-state-set'
        when _languageComparisonValidationContract(message) =>
      languageComparisonValidationEmptyStateSet(
        _languageComparisonAutomatonSideLabel(this, message),
      ),
    'language.comparison.missing-initial-state'
        when _languageComparisonValidationContract(message) =>
      languageComparisonValidationMissingInitialState(
        _languageComparisonAutomatonSideLabel(this, message),
      ),
    'language.comparison.initial-state-outside-set'
        when _languageComparisonValidationContract(message) =>
      languageComparisonValidationInitialStateOutsideSet(
        _lowercaseFirst(_languageComparisonAutomatonSideLabel(this, message)),
      ),
    'language.comparison.internal-failure'
        when _matchesArguments(message, const {}) =>
      languageComparisonAnalysisFailed,
    'language.comparison.trace.validation'
        when _matchesArguments(message, const {}) =>
      languageComparisonDescriptionValidation,
    'language.comparison.trace.initialization'
        when _matchesArguments(message, const {}) =>
      languageComparisonDescriptionInitialization,
    'language.comparison.trace.alphabet-normalization'
        when _matchesArguments(message, const {}) =>
      languageComparisonDescriptionAlphabet,
    'language.comparison.trace.nfa-to-dfa'
        when _languageComparisonTraceAutomatonContract(message) =>
      languageComparisonDescriptionNfaToDfa(
        _stringArgument(message, 'automaton'),
      ),
    'language.comparison.trace.dfa-completion'
        when _languageComparisonTraceAutomatonContract(message) =>
      languageComparisonDescriptionDfaCompletion(
        _stringArgument(message, 'automaton'),
      ),
    'language.comparison.trace.product-construction-start'
        when _matchesArguments(message, const {}) =>
      languageComparisonDescriptionProductStart,
    'language.comparison.trace.product-state-created'
        when _languageComparisonTraceStateContract(message) =>
      languageComparisonDescriptionProductState(
        _stringArgument(message, 'state'),
      ),
    'language.comparison.trace.product-transition-created'
        when _languageComparisonTraceSymbolContract(message) =>
      languageComparisonDescriptionProductTransition(
        _stringArgument(message, 'symbol'),
      ),
    'language.comparison.trace.product-construction-complete'
        when _matchesArguments(message, const {}) =>
      languageComparisonDescriptionProductComplete,
    'language.comparison.trace.bfs-search-start'
        when _matchesArguments(message, const {}) =>
      languageComparisonDescriptionBfsStart,
    'language.comparison.trace.bfs-initial-check'
        when _languageComparisonTraceBooleanContract(message, 'different') =>
      languageComparisonDescriptionInitialCheck(
        _boolArgument(message, 'different').toString(),
      ),
    'language.comparison.trace.bfs-explore-pair'
        when _languageComparisonTracePairContract(message) =>
      languageComparisonDescriptionExplorePair(
        _stringArgument(message, 'state-a'),
        _stringArgument(message, 'state-b'),
      ),
    'language.comparison.trace.bfs-distinguishing-found'
        when _languageComparisonTraceDistinguishingContract(message) =>
      languageComparisonDescriptionCounterexample(
        _stringArgument(message, 'value'),
      ),
    'language.comparison.trace.bfs-complete'
        when _matchesArguments(message, const {}) =>
      languageComparisonDescriptionBfsComplete,
    'language.comparison.trace.result'
        when _languageComparisonTraceBooleanContract(message, 'equivalent') =>
      languageComparisonDescriptionResult(
        _boolArgument(message, 'equivalent').toString(),
      ),
    'language.comparison.trace.error'
        when _matchesArguments(message, const {}) =>
      languageComparisonDescriptionError,
    'language.comparison.trace.unknown'
        when _languageComparisonTraceUnknownContract(message) =>
      languageComparisonDescriptionUnknown,
    'interop.registry.document-unrecognized'
        when _matchesArguments(message, const {}) =>
      interoperabilityUnsupportedDocument,
    'interop.registry.sniff-identity-mismatch'
        when _matchesArguments(message, const {
          'codec': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'codec',
          ),
        }) =>
      interopRegistrySniffIdentityMismatch(_stringArgument(message, 'codec')),
    'interop.registry.sniff-failed'
        when _matchesArguments(message, const {
          'codec': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'codec',
          ),
        }) =>
      interopRegistrySniffFailed(_stringArgument(message, 'codec')),
    'interop.registry.decoded-identity-mismatch'
        when _matchesArguments(message, const {
          'codec': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'codec',
          ),
        }) =>
      interopRegistryDecodedIdentityMismatch(_stringArgument(message, 'codec')),
    'interop.registry.decode-failed'
        when _matchesArguments(message, const {
          'codec': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'codec',
          ),
        }) =>
      interopRegistryDecodeFailed(_stringArgument(message, 'codec')),
    'interop.registry.schema-identity-unregistered'
        when _matchesArguments(message, const {
          'system': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'formal-system',
          ),
          'schema': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'schema',
          ),
        }) =>
      interopRegistrySchemaIdentityUnregistered(
        _stringArgument(message, 'schema'),
        _stringArgument(message, 'system'),
      ),
    'interop.registry.export-route-unavailable'
        when _matchesArguments(message, const {
          'system': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'formal-system',
          ),
          'format': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'document-format',
          ),
          'schema-version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      interopRegistryExportRouteUnavailable(
        _stringArgument(message, 'system'),
        _stringArgument(message, 'format'),
        _intArgument(message, 'schema-version'),
      ),
    'interop.registry.export-schema-unavailable'
        when _matchesArguments(message, const {
          'schema-version': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'schema-version',
          ),
        }) =>
      interopRegistryExportSchemaUnavailable(
        _intArgument(message, 'schema-version'),
      ),
    'interop.registry.encoded-metadata-mismatch'
        when _matchesArguments(message, const {
          'codec': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'codec',
          ),
        }) =>
      interopRegistryEncodedMetadataMismatch(_stringArgument(message, 'codec')),
    'interop.registry.encode-failed'
        when _matchesArguments(message, const {
          'codec': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'codec',
          ),
        }) =>
      interopRegistryEncodeFailed(_stringArgument(message, 'codec')),
    'transducer.analysis.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      transducerAnalysisMissingInitialState,
    'transducer.analysis.multiple-initial-states'
        when _matchesArguments(message, const {
          'count': (kind: StructuredMessageArgumentKind.count, role: null),
        }) =>
      transducerAnalysisMultipleInitialStates(_intArgument(message, 'count')),
    'transducer.analysis.duplicate-state-id'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state',
          ),
        }) =>
      transducerAnalysisDuplicateStateId(_stringArgument(message, 'state')),
    'transducer.analysis.duplicate-transition-id'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition',
          ),
        }) =>
      transducerAnalysisDuplicateTransitionId(
        _stringArgument(message, 'transition'),
      ),
    'transducer.analysis.dangling-source-state'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition',
          ),
        }) =>
      transducerAnalysisDanglingSourceState(
        _stringArgument(message, 'transition'),
      ),
    'transducer.analysis.dangling-target-state'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition',
          ),
        }) =>
      transducerAnalysisDanglingTargetState(
        _stringArgument(message, 'transition'),
      ),
    'transducer.analysis.input-symbol-outside-alphabet'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      transducerAnalysisInputSymbolOutsideAlphabet(
        _stringArgument(message, 'transition'),
        _stringArgument(message, 'symbol'),
      ),
    'transducer.analysis.output-symbol-outside-alphabet'
        when _matchesArguments(message, const {
          'subject': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'output-owner',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'output-symbol',
          ),
        }) =>
      transducerAnalysisOutputSymbolOutsideAlphabet(
        _stringArgument(message, 'subject'),
        _stringArgument(message, 'symbol'),
      ),
    'transducer.analysis.nondeterministic-transition'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      transducerAnalysisNondeterministicTransition(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'symbol'),
      ),
    'transducer.analysis.incomplete-transition-function'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      transducerAnalysisIncompleteTransitionFunction(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'symbol'),
      ),
    'transducer.analysis.empty-identifier'
        when _matchesArguments(message, const {
          'entity': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'entity-kind',
          ),
        }) =>
      transducerAnalysisEmptyIdentifier(_stringArgument(message, 'entity')),
    'transducer.analysis.empty-input-symbol'
        when _matchesArguments(message, const {
          'subject': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'diagnostic-subject',
          ),
        }) =>
      transducerAnalysisEmptyInputSymbol(_stringArgument(message, 'subject')),
    'transducer.analysis.empty-output-symbol'
        when _matchesArguments(message, const {
          'subject': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'diagnostic-subject',
          ),
        }) =>
      transducerAnalysisEmptyOutputSymbol(_stringArgument(message, 'subject')),
    'transducer.analysis.negative-revision'
        when _matchesArguments(message, const {
          'revision': (kind: StructuredMessageArgumentKind.integer, role: null),
        }) =>
      transducerAnalysisNegativeRevision(_intArgument(message, 'revision')),
    'transducer.execution.invalid-machine'
        when _matchesArguments(message, const {
          'diagnostic-count': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
        }) =>
      transducerExecutionInvalidMachine(
        _intArgument(message, 'diagnostic-count'),
      ),
    'transducer.execution.invalid-input-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      transducerExecutionInvalidInputSymbol(_stringArgument(message, 'symbol')),
    'transducer.execution.tokenization-failure'
        when _matchesArguments(message, const {
          'offset': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'input-offset',
          ),
        }) =>
      transducerExecutionTokenizationFailure(_intArgument(message, 'offset')),
    'transducer.execution.invalid-input'
        when _matchesArguments(message, const {}) =>
      transducerInvalidInput,
    'transducer.execution.undefined-transition'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      transducerExecutionUndefinedTransition(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'symbol'),
      ),
    'transducer.execution.cancelled'
        when _matchesArguments(message, const {
          'processed': (kind: StructuredMessageArgumentKind.count, role: null),
        }) =>
      transducerExecutionCancelled(_intArgument(message, 'processed')),
    'transducer.execution.bounded'
        when _matchesArguments(message, const {
          'limit': (kind: StructuredMessageArgumentKind.bound, role: null),
          'processed': (kind: StructuredMessageArgumentKind.count, role: null),
        }) =>
      transducerExecutionBounded(
        _intArgument(message, 'limit'),
        _intArgument(message, 'processed'),
      ),
    'transducer.execution.success'
        when _matchesArguments(message, const {
          'output-count': (
            kind: StructuredMessageArgumentKind.count,
            role: null,
          ),
          'processed': (kind: StructuredMessageArgumentKind.count, role: null),
        }) =>
      transducerExecutionSuccess(
        _intArgument(message, 'processed'),
        _intArgument(message, 'output-count'),
      ),
    'transducer.example.mealy-identity-name'
        when _matchesArguments(message, const {}) =>
      mealyExampleIdentityName,
    'transducer.example.mealy-identity-description'
        when _matchesArguments(message, const {}) =>
      mealyExampleIdentityDescription,
    'transducer.example.mealy-parity-name'
        when _matchesArguments(message, const {}) =>
      mealyExampleParityName,
    'transducer.example.mealy-parity-description'
        when _matchesArguments(message, const {}) =>
      mealyExampleParityDescription,
    'transducer.example.mealy-sequence-name'
        when _matchesArguments(message, const {}) =>
      mealyExampleSequenceName,
    'transducer.example.mealy-sequence-description'
        when _matchesArguments(message, const {}) =>
      mealyExampleSequenceDescription,
    'transducer.example.mealy-partial-name'
        when _matchesArguments(message, const {}) =>
      mealyExamplePartialName,
    'transducer.example.mealy-partial-description'
        when _matchesArguments(message, const {}) =>
      mealyExamplePartialDescription,
    'transducer.example.moore-parity-name'
        when _matchesArguments(message, const {}) =>
      mooreExampleParityName,
    'transducer.example.moore-parity-description'
        when _matchesArguments(message, const {}) =>
      mooreExampleParityDescription,
    'transducer.example.moore-vending-name'
        when _matchesArguments(message, const {}) =>
      mooreExampleVendingName,
    'transducer.example.moore-vending-description'
        when _matchesArguments(message, const {}) =>
      mooreExampleVendingDescription,
    'transducer.example.moore-sequence-name'
        when _matchesArguments(message, const {}) =>
      mooreExampleSequenceName,
    'transducer.example.moore-sequence-description'
        when _matchesArguments(message, const {}) =>
      mooreExampleSequenceDescription,
    'transducer.example.moore-partial-name'
        when _matchesArguments(message, const {}) =>
      mooreExamplePartialName,
    'transducer.example.moore-partial-description'
        when _matchesArguments(message, const {}) =>
      mooreExamplePartialDescription,
    'parser.grammar-xml.malformed-document'
        when _matchesArguments(message, const {}) =>
      parserXmlMalformedDocument,
    'parser.grammar-xml.missing-grammar-element'
        when _matchesArguments(message, const {}) =>
      parserGrammarXmlMissingGrammarElement,
    'parser.grammar-xml.missing-start-element'
        when _matchesArguments(message, const {}) =>
      parserGrammarXmlMissingStartElement,
    'parser.grammar-xml.empty-start-element'
        when _matchesArguments(message, const {}) =>
      parserGrammarXmlEmptyStartElement,
    'parser.grammar-xml.invalid-start-count'
        when _matchesArguments(message, const {
          'count': (kind: StructuredMessageArgumentKind.count, role: null),
        }) =>
      parserGrammarXmlInvalidStartCount(_intArgument(message, 'count')),
    'parser.grammar-xml.incomplete-production'
        when _matchesArguments(message, const {
          'index': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'production-index',
          ),
        }) =>
      parserGrammarXmlIncompleteProduction(_intArgument(message, 'index')),
    'parser.jflap-xml.malformed-document'
        when _matchesArguments(message, const {}) =>
      parserXmlMalformedDocument,
    'parser.jflap-xml.missing-automaton-element'
        when _matchesArguments(message, const {}) =>
      parserJflapXmlMissingAutomatonElement,
    'parser.jflap-xml.empty-automaton'
        when _matchesArguments(message, const {}) =>
      parserJflapXmlEmptyAutomaton,
    'parser.jflap-xml.incomplete-transition'
        when _matchesArguments(message, const {
          'index': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'transition-index',
          ),
        }) =>
      parserJflapXmlIncompleteTransition(_intArgument(message, 'index')),
    'parser.jflap-xml.unknown-transition-endpoints'
        when _matchesArguments(message, const {
          'from': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'source-state',
          ),
          'to': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'target-state',
          ),
        }) =>
      parserJflapXmlUnknownTransitionEndpoints(
        _stringArgument(message, 'from'),
        _stringArgument(message, 'to'),
      ),
    'parser.jflap-xml.unexpected-root-element'
        when _matchesArguments(message, const {
          'actual': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'xml-element',
          ),
        }) =>
      parserJflapXmlUnexpectedRootElement(_stringArgument(message, 'actual')),
    'service.tm-block-editor.duplicate-block-id'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      serviceTmBlockEditorDuplicateBlockId(_stringArgument(message, 'block')),
    'service.tm-block-editor.duplicate-block-name'
        when _matchesArguments(message, const {
          'name': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'block-name',
          ),
        }) =>
      serviceTmBlockEditorDuplicateBlockName(_stringArgument(message, 'name')),
    'service.tm-block-editor.invalid-block-name'
        when _matchesArguments(message, const {}) =>
      serviceTmBlockEditorInvalidBlockName,
    'service.tm-block-editor.referenced-block'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      serviceTmBlockEditorReferencedBlock(_stringArgument(message, 'block')),
    'service.tm-block-editor.missing-owner-machine'
        when _matchesArguments(message, const {
          'machine': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'machine-id',
          ),
        }) =>
      serviceTmBlockEditorMissingOwnerMachine(
        _stringArgument(message, 'machine'),
      ),
    'service.tm-block-editor.missing-anchor-state'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
          'machine': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'machine-id',
          ),
        }) =>
      serviceTmBlockEditorMissingAnchorState(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'machine'),
      ),
    'service.tm-block-editor.state-already-invokes-block'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      serviceTmBlockEditorStateAlreadyInvokesBlock(
        _stringArgument(message, 'state'),
      ),
    'service.tm-block-editor.duplicate-root-state'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      serviceTmBlockEditorDuplicateRootState(_stringArgument(message, 'state')),
    'service.tm-block-editor.missing-invocation'
        when _matchesArguments(message, const {
          'invocation': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'invocation-id',
          ),
        }) =>
      serviceTmBlockEditorMissingInvocation(
        _stringArgument(message, 'invocation'),
      ),
    'service.tm-block-editor.nothing-to-undo'
        when _matchesArguments(message, const {}) =>
      serviceTmBlockEditorNothingToUndo,
    'service.tm-block-editor.nothing-to-redo'
        when _matchesArguments(message, const {}) =>
      serviceTmBlockEditorNothingToRedo,
    'service.tm-block-editor.missing-block'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      serviceTmBlockEditorMissingBlock(_stringArgument(message, 'block')),
    'service.tm-block-editor.invalid-project'
        when _matchesArguments(message, const {
          'diagnostic': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'tm-block-diagnostic',
          ),
        }) =>
      serviceTmBlockEditorInvalidProject(
        _stringArgument(message, 'diagnostic'),
      ),
    'service.manual-conversion-store.malformed-payload'
        when _matchesArguments(message, const {}) =>
      serviceManualConversionStoreMalformedPayload,
    'service.file-operations.operation-failed'
        when _matchesArguments(message, const {
          'operation': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'file-operation',
          ),
        }) =>
      serviceFileOperationsOperationFailed(
        _stringArgument(message, 'operation'),
      ),
    'service.file-operations.access-denied'
        when _matchesArguments(message, const {
          'operation': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'file-operation',
          ),
        }) =>
      serviceFileOperationsAccessDenied(_stringArgument(message, 'operation')),
    'service.file-operations.location-missing'
        when _matchesArguments(message, const {
          'operation': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'file-operation',
          ),
        }) =>
      serviceFileOperationsLocationMissing(
        _stringArgument(message, 'operation'),
      ),
    'service.file-operations.access-failed'
        when _matchesArguments(message, const {
          'operation': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'file-operation',
          ),
        }) =>
      serviceFileOperationsAccessFailed(_stringArgument(message, 'operation')),
    'service.file-operations.web-unsupported'
        when _matchesArguments(message, const {
          'operation': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'file-operation',
          ),
        }) =>
      serviceFileOperationsWebUnsupported(
        _stringArgument(message, 'operation'),
      ),
    'service.file-operations.codec-unsupported'
        when _matchesArguments(message, const {
          'reason': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'codec-unsupported-reason',
          ),
        }) =>
      serviceFileOperationsCodecUnsupported(_stringArgument(message, 'reason')),
    'service.file-operations.codec-ambiguous'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'codec-count',
          ),
        }) =>
      serviceFileOperationsCodecAmbiguous(_intArgument(message, 'count')),
    'service.file-operations.codec-malformed'
        when _matchesArguments(message, const {
          'reason': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'codec-malformed-reason',
          ),
        }) =>
      serviceFileOperationsCodecMalformed(_stringArgument(message, 'reason')),
    'service.file-operations.codec-resource-limit'
        when _matchesArguments(message, const {
          'limit': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'codec-resource-limit',
          ),
          'maximum': (kind: StructuredMessageArgumentKind.bound, role: null),
          'actual': (kind: StructuredMessageArgumentKind.count, role: null),
        }) =>
      serviceFileOperationsCodecResourceLimit(
        _stringArgument(message, 'limit'),
        _intArgument(message, 'actual'),
        _intArgument(message, 'maximum'),
      ),
    'service.file-operations.codec-internal-failure'
        when _matchesArguments(message, const {
          'stage': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'codec-stage',
          ),
        }) =>
      serviceFileOperationsCodecInternalFailure(
        _stringArgument(message, 'stage'),
      ),
    'service.file-operations.interoperability-review-required'
        when _matchesArguments(message, const {}) =>
      serviceFileOperationsInteroperabilityReviewRequired,
    'service.file-operations.lossy-export-requires-confirmation'
        when _matchesArguments(message, const {}) =>
      serviceFileOperationsLossyExportRequiresConfirmation,
    'service.file-operations.invalid-model-type'
        when _matchesArguments(message, const {}) =>
      serviceFileOperationsInvalidModelType,
    'service.simulation-runner.start-failed'
        when _matchesArguments(message, const {}) =>
      serviceSimulationRunnerStartFailed,
    'service.simulation-runner.execution-failed'
        when _matchesArguments(message, const {}) =>
      serviceSimulationRunnerExecutionFailed,
    'service.simulation-runner.worker-failed'
        when _matchesArguments(message, const {}) =>
      serviceSimulationRunnerWorkerFailed,
    'service.simulation-runner.worker-exited-unexpectedly'
        when _matchesArguments(message, const {}) =>
      serviceSimulationRunnerWorkerExitedUnexpectedly,
    'service.simulation-runner.invalid-worker-response'
        when _matchesArguments(message, const {}) =>
      serviceSimulationRunnerInvalidWorkerResponse,
    'pda.simulation.empty-state-set'
        when _matchesArguments(message, const {}) =>
      pdaSimulationEmptyStateSet,
    'pda.simulation.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      pdaSimulationMissingInitialState,
    'pda.simulation.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      pdaSimulationInitialStateOutsideSet,
    'pda.simulation.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      pdaSimulationAcceptingStateOutsideSet,
    'pda.to-cfg.invalid-production-limit'
        when _matchesArguments(message, const {}) =>
      pdaToCfgInvalidProductionLimit,
    'pda.to-cfg.cancelled' when _matchesArguments(message, const {}) =>
      pdaToCfgCancelled,
    'pda.to-cfg.empty-pda' when _matchesArguments(message, const {}) =>
      pdaToCfgEmptyPda,
    'pda.to-cfg.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      pdaToCfgMissingInitialState,
    'pda.to-cfg.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      pdaToCfgInitialStateOutsideSet,
    'pda.to-cfg.missing-accepting-state'
        when _matchesArguments(message, const {}) =>
      pdaToCfgMissingAcceptingState,
    'pda.to-cfg.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      pdaToCfgAcceptingStateOutsideSet,
    'pda.to-cfg.epsilon-pop'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
        }) =>
      pdaToCfgEpsilonPop(_stringArgument(message, 'transition')),
    'pda.to-cfg.production-limit'
        when _matchesArguments(message, const {
          'limit': (kind: StructuredMessageArgumentKind.bound, role: null),
        }) =>
      pdaToCfgProductionLimit(_intArgument(message, 'limit')),
    'pda.to-cfg.no-productions' when _matchesArguments(message, const {}) =>
      pdaToCfgNoProductions,
    'pda.normalization.empty-pda' when _matchesArguments(message, const {}) =>
      pdaNormalizationEmptyPda,
    'pda.normalization.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      pdaNormalizationMissingInitialState,
    'pda.normalization.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      pdaNormalizationInitialStateOutsideSet,
    'pda.normalization.initial-stack-symbol-outside-alphabet'
        when _pdaNormalizationStackSymbolContract(message) =>
      pdaNormalizationInitialStackSymbolOutsideAlphabet(
        _stringArgument(message, 'symbol'),
      ),
    'pda.normalization.missing-accepting-state'
        when _matchesArguments(message, const {}) =>
      pdaNormalizationMissingAcceptingState,
    'pda.normalization.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      pdaNormalizationAcceptingStateOutsideSet,
    'pda.normalization.non-pda-transition'
        when _matchesArguments(message, const {}) =>
      pdaNormalizationNonPdaTransition,
    'pda.normalization.transition-endpoint-outside-set'
        when _pdaNormalizationTransitionContract(message) =>
      pdaNormalizationTransitionEndpointOutsideSet(
        _stringArgument(message, 'transition'),
      ),
    'pda.normalization.transition-pop-symbol-outside-alphabet'
        when _pdaNormalizationTransitionStackSymbolContract(message) =>
      pdaNormalizationTransitionPopSymbolOutsideAlphabet(
        _stringArgument(message, 'transition'),
        _stringArgument(message, 'symbol'),
      ),
    'pda.normalization.transition-push-symbol-outside-alphabet'
        when _pdaNormalizationTransitionStackSymbolContract(message) =>
      pdaNormalizationTransitionPushSymbolOutsideAlphabet(
        _stringArgument(message, 'transition'),
        _stringArgument(message, 'symbol'),
      ),
    'pda.normalization.growth-warning'
        when _pdaNormalizationGrowthContract(message) =>
      pdaNormalizationGrowthWarningSummary(
        _intArgument(message, 'states'),
        _intArgument(message, 'transitions'),
      ),
    'pda.normalization.introduced-nondeterminism'
        when _matchesArguments(message, const {}) =>
      pdaNormalizationIntroducedNondeterminism,
    'pda.normalization.initial-state'
        when _pdaNormalizationStateContract(message) =>
      pdaNormalizationInitialStateDescription(
        _stringArgument(message, 'state'),
      ),
    'pda.normalization.acceptance-state'
        when _matchesArguments(message, const {}) =>
      pdaNormalizationAcceptanceStateDescription,
    'pda.normalization.drain-state' when _matchesArguments(message, const {}) =>
      pdaNormalizationDrainStateDescription,
    'pda.normalization.initialize-transition'
        when _pdaNormalizationStateContract(message) =>
      pdaNormalizationInitializeTransitionDescription(
        _stringArgument(message, 'state'),
      ),
    'pda.normalization.single-pop-transition'
        when _pdaNormalizationTransitionContract(message) =>
      pdaNormalizationSinglePopTransitionDescription(
        _stringArgument(message, 'transition'),
      ),
    'pda.normalization.accept-empty-transition'
        when _pdaNormalizationAcceptEmptyContract(message) =>
      pdaNormalizationAcceptEmptyTransitionDescription(
        _stringArgument(message, 'state'),
        _pdaNormalizationAcceptanceModeLabel(
          this,
          _stringArgument(message, 'mode'),
        ),
      ),
    'pda.normalization.enter-drain-transition'
        when _pdaNormalizationStateContract(message) =>
      pdaNormalizationEnterDrainTransitionDescription(
        _stringArgument(message, 'state'),
      ),
    'pda.normalization.drain-transition'
        when _matchesArguments(message, const {}) =>
      pdaNormalizationDrainTransitionDescription,
    'pda.simplification.empty-pda' when _matchesArguments(message, const {}) =>
      pdaSimplificationEmptyPda,
    'pda.simplification.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationMissingInitialState,
    'pda.simplification.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationInitialStateOutsideSet,
    'pda.simplification.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationAcceptingStateOutsideSet,
    'pda.simplification.missing-accepting-state'
        when _pdaSimplificationAcceptanceModeContract(message) =>
      pdaSimplificationMissingAcceptingState(
        _pdaNormalizationAcceptanceModeLabel(
          this,
          _stringArgument(message, 'mode'),
        ),
      ),
    'pda.simplification.invalid-pda'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationInvalidPda,
    'pda.simplification.non-pda-transition'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationNonPdaTransition,
    'pda.simplification.transition-endpoint-outside-set'
        when _pdaSimplificationTransitionContract(message) =>
      pdaSimplificationTransitionEndpointOutsideSet(
        _stringArgument(message, 'transition'),
      ),
    'pda.simplification.invalid-transition'
        when _pdaSimplificationTransitionContract(message) =>
      pdaSimplificationInvalidTransition(
        _stringArgument(message, 'transition'),
      ),
    'pda.simplification.input-alphabet-empty-symbol'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationInputAlphabetEmptySymbol,
    'pda.simplification.stack-alphabet-empty-symbol'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationStackAlphabetEmptySymbol,
    'pda.simplification.transition-input-symbol-outside-alphabet'
        when _pdaSimplificationTransitionInputContract(message) =>
      pdaSimplificationTransitionInputSymbolOutsideAlphabet(
        _stringArgument(message, 'transition'),
        _stringArgument(message, 'symbol'),
      ),
    'pda.simplification.duplicate-transition-ids'
        when _pdaSimplificationTransitionContract(message) =>
      pdaSimplificationDuplicateTransitionIds(
        _stringArgument(message, 'transition'),
      ),
    'pda.simplification.bounded-length-negative'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationBoundedLengthNegative,
    'pda.simplification.bounded-symbols-empty'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationBoundedSymbolsEmpty,
    'pda.simplification.bounded-symbol-outside-alphabet'
        when _pdaSimplificationInputSymbolContract(message) =>
      pdaSimplificationBoundedSymbolOutsideAlphabet(
        _stringArgument(message, 'symbol'),
      ),
    'pda.simplification.validation-complete'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationValidationComplete,
    'pda.simplification.every-state-reachable'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationEveryStateReachable,
    'pda.simplification.removed-unreachable-states'
        when _pdaSimplificationCountContract(message, 'removed-state-count') =>
      pdaSimplificationRemovedUnreachableStates(_intArgument(message, 'count')),
    'pda.simplification.semantic-usefulness-unavailable'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationSemanticUsefulnessUnavailable,
    'pda.simplification.semantic-usefulness-disabled'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationSemanticUsefulnessDisabled,
    'pda.simplification.strong-bisimulation-computed'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationStrongBisimulationComputed,
    'pda.simplification.strong-bisimulation-disabled'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationStrongBisimulationDisabled,
    'pda.simplification.rebuild-validation-complete'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationRebuildValidationComplete,
    'pda.simplification.bounded-sample-passed'
        when _pdaSimplificationCountContract(message, 'sampled-word-count') =>
      pdaSimplificationBoundedSamplePassed(_intArgument(message, 'count')),
    'pda.simplification.bounded-comparison-disabled'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationBoundedComparisonDisabled,
    'pda.simplification.invalid-rebuilt-pda'
        when _matchesArguments(message, const {}) =>
      pdaSimplificationInvalidRebuiltPda,
    'pda.simplification.bounded-comparison-inconclusive'
        when _pdaSimplificationWordContract(message) =>
      pdaSimplificationBoundedComparisonInconclusive(
        _stringArgument(message, 'word'),
      ),
    'pda.simplification.bounded-comparison-simulation-limit'
        when _pdaSimplificationWordContract(message) =>
      pdaSimplificationBoundedComparisonSimulationLimit(
        _stringArgument(message, 'word'),
      ),
    'pda.simplification.bounded-comparison-acceptance-mismatch'
        when _pdaSimplificationWordContract(message) =>
      pdaSimplificationBoundedComparisonAcceptanceMismatch(
        _stringArgument(message, 'word'),
      ),
    'automaton.simulation.dfa-required'
        when _matchesArguments(message, const {}) =>
      automatonSimulationDfaRequired,
    'automaton.simulation.empty-automaton'
        when _matchesArguments(message, const {}) =>
      automatonSimulationEmptyAutomaton,
    'automaton.simulation.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      automatonSimulationMissingInitialState,
    'automaton.simulation.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      automatonSimulationInitialStateOutsideSet,
    'automaton.simulation.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      automatonSimulationAcceptingStateOutsideSet,
    'automaton.simulation.invalid-input-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      automatonSimulationInvalidInputSymbol(_stringArgument(message, 'symbol')),
    'automaton.simulation.no-dfa-transition'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-label',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      automatonSimulationNoDfaTransition(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'symbol'),
      ),
    'automaton.simulation.rejected-no-accepting-state'
        when _matchesArguments(message, const {}) =>
      automatonSimulationRejectedNoAcceptingState,
    'automaton.simulation.no-nfa-transition'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      automatonSimulationNoNfaTransition(_stringArgument(message, 'symbol')),
    'automaton.simulation.nfa-not-accepted'
        when _matchesArguments(message, const {}) =>
      automatonSimulationNfaNotAccepted,
    'automaton.simulation.computation-tree-timeout'
        when _matchesArguments(message, const {
          'steps': (
            kind: StructuredMessageArgumentKind.count,
            role: 'step-count',
          ),
        }) =>
      automatonSimulationComputationTreeTimeout(_intArgument(message, 'steps')),
    'automaton.simulation.computation-tree-infinite-loop'
        when _matchesArguments(message, const {
          'steps': (
            kind: StructuredMessageArgumentKind.count,
            role: 'step-count',
          ),
        }) =>
      automatonSimulationComputationTreeInfiniteLoop(
        _intArgument(message, 'steps'),
      ),
    'automaton.simulation.dfa-failure'
        when _matchesArguments(message, const {
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
        }) =>
      automatonSimulationDfaFailure(_stringArgument(message, 'error')),
    'automaton.simulation.nfa-failure'
        when _matchesArguments(message, const {
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
        }) =>
      automatonSimulationNfaFailure(_stringArgument(message, 'error')),
    'automaton.simulation.accepted-strings-failure'
        when _matchesArguments(message, const {
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
        }) =>
      automatonSimulationAcceptedStringsFailure(
        _stringArgument(message, 'error'),
      ),
    'automaton.simulation.rejected-strings-failure'
        when _matchesArguments(message, const {
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
        }) =>
      automatonSimulationRejectedStringsFailure(
        _stringArgument(message, 'error'),
      ),
    'automaton.simulation.transition-applied-title'
        when _matchesArguments(message, const {}) =>
      automatonSimulationTransitionAppliedTitle,
    'automaton.simulation.read-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      automatonSimulationReadSymbol(_stringArgument(message, 'symbol')),
    'automaton.simulation.transition-detail'
        when _matchesArguments(message, const {
          'from-state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-label',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'to-state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-label',
          ),
        }) =>
      automatonSimulationTransitionDetail(
        _stringArgument(message, 'from-state'),
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'to-state'),
      ),
    'automaton.simulation.computed-epsilon-closure-title'
        when _matchesArguments(message, const {}) =>
      automatonSimulationComputedEpsilonClosureTitle,
    'automaton.simulation.epsilon-closure-before-reading'
        when _matchesArguments(message, const {}) =>
      automatonSimulationEpsilonClosureBeforeReading,
    'automaton.simulation.epsilon-closure-reached'
        when _matchesArguments(message, const {
          'initial-state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-label',
          ),
          'state-set': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-set',
          ),
        }) =>
      automatonSimulationEpsilonClosureReached(
        _stringArgument(message, 'initial-state'),
        _stringArgument(message, 'state-set'),
      ),
    'automaton.simulation.symbol-consumed-title'
        when _matchesArguments(message, const {}) =>
      automatonSimulationSymbolConsumedTitle,
    'automaton.simulation.nondeterministic-step'
        when _matchesArguments(message, const {}) =>
      automatonSimulationNondeterministicStep,
    'automaton.simulation.active-set-after-transitions'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'state-set': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-set',
          ),
        }) =>
      automatonSimulationActiveSetAfterTransitions(
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'state-set'),
      ),
    'automaton.simulation.expanded-via-epsilon-title'
        when _matchesArguments(message, const {}) =>
      automatonSimulationExpandedViaEpsilonTitle,
    'automaton.simulation.epsilon-after-consuming'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      automatonSimulationEpsilonAfterConsuming(
        _stringArgument(message, 'symbol'),
      ),
    'automaton.simulation.epsilon-closure-expanded'
        when _matchesArguments(message, const {
          'before': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-set',
          ),
          'after': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-set',
          ),
        }) =>
      automatonSimulationEpsilonClosureExpanded(
        _stringArgument(message, 'before'),
        _stringArgument(message, 'after'),
      ),
    'automaton.simulation.initial-state-description'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      automatonSimulationInitialStateDescription(
        _stringArgument(message, 'state'),
      ),
    'automaton.simulation.consumed-symbol-description'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      automatonSimulationConsumedSymbolDescription(
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'state'),
      ),
    'automaton.simulation.initial-epsilon-closure-description'
        when _matchesArguments(message, const {}) =>
      automatonSimulationInitialEpsilonClosureDescription,
    'automaton.nfa-to-dfa.empty-automaton'
        when _matchesArguments(message, const {}) =>
      nfaToDfaEmptyAutomaton,
    'automaton.nfa-to-dfa.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      nfaToDfaMissingInitialState,
    'automaton.nfa-to-dfa.initial-state-outside-set'
        when _matchesArguments(message, const {}) =>
      nfaToDfaInitialStateOutsideSet,
    'automaton.nfa-to-dfa.accepting-state-outside-set'
        when _matchesArguments(message, const {}) =>
      nfaToDfaAcceptingStateOutsideSet,
    'automaton.nfa-to-dfa.state-limit-exceeded'
        when _matchesArguments(message, const {
          'limit': (
            kind: StructuredMessageArgumentKind.bound,
            role: 'dfa-state-limit',
          ),
        }) =>
      nfaToDfaStateLimitExceeded(_intArgument(message, 'limit')),
    'automaton.nfa-to-dfa.conversion-failed'
        when _matchesArguments(message, const {
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
          'with-steps': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'step-capture',
          ),
        }) =>
      nfaToDfaConversionFailed(
        _stringArgument(message, 'error'),
        _boolArgument(message, 'with-steps').toString(),
      ),
    'pda.simulation.search-limits-negative'
        when _matchesArguments(message, const {}) =>
      pdaSimulationSearchLimitsNegative,
    'pda.simulation.memory-limit-negative'
        when _matchesArguments(message, const {}) =>
      pdaSimulationMemoryLimitNegative,
    'pda.simulation.configurations-per-batch-invalid'
        when _matchesArguments(message, const {}) =>
      pdaSimulationConfigurationsPerBatchInvalid,
    'pda.simulation.simulation-failure'
        when _matchesArguments(message, const {
          'operation': (
            kind: StructuredMessageArgumentKind.strategy,
            role: 'simulation-operation',
          ),
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
        }) =>
      pdaSimulationFailure(
        _stringArgument(message, 'operation'),
        _stringArgument(message, 'error'),
      ),
    'pda.simulation.accepted-strings-failure'
        when _matchesArguments(message, const {
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
        }) =>
      pdaSimulationAcceptedStringsFailure(_stringArgument(message, 'error')),
    'pda.simulation.rejected-strings-failure'
        when _matchesArguments(message, const {
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
        }) =>
      pdaSimulationRejectedStringsFailure(_stringArgument(message, 'error')),
    'pda.simulation.timeout' when _matchesArguments(message, const {}) =>
      pdaSimulationTimeout,
    'pda.simulation.infinite-loop' when _matchesArguments(message, const {}) =>
      pdaSimulationInfiniteLoop,
    'pda.simulation.configuration-limit'
        when _matchesArguments(message, const {}) =>
      pdaSimulationConfigurationLimit,
    'pda.simulation.depth-limit' when _matchesArguments(message, const {}) =>
      pdaSimulationDepthLimit,
    'pda.simulation.memory-limit' when _matchesArguments(message, const {}) =>
      pdaSimulationMemoryLimit,
    'pda.simulation.stale-request' when _matchesArguments(message, const {}) =>
      pdaSimulationStaleRequest,
    'pda.simulation.rejected-no-accepting-configuration'
        when _matchesArguments(message, const {}) =>
      pdaSimulationRejectedNoAcceptingConfiguration,
    'pda.simulation.transition-title'
        when _matchesArguments(message, const {}) =>
      pdaSimulationTransitionTitle,
    'pda.simulation.read-input'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      pdaSimulationReadInput(_stringArgument(message, 'symbol')),
    'pda.simulation.stack-action'
        when _matchesArguments(message, const {
          'pop': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
          'push': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
        }) =>
      pdaSimulationStackAction(
        _stringArgument(message, 'pop'),
        _stringArgument(message, 'push'),
      ),
    'pda.simulation.stack-top-change'
        when _matchesArguments(message, const {
          'before': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
          'after': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
        }) =>
      pdaSimulationStackTopChange(
        _stringArgument(message, 'before'),
        _stringArgument(message, 'after'),
      ),
    'pda.simulation.pop-matches'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
        }) =>
      pdaSimulationPopMatches(_stringArgument(message, 'symbol')),
    'pda.simulation.no-pop' when _matchesArguments(message, const {}) =>
      pdaSimulationNoPop,
    'pda.simulation.pushed'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
        }) =>
      pdaSimulationPushed(_stringArgument(message, 'symbol')),
    'pda.simulation.no-push' when _matchesArguments(message, const {}) =>
      pdaSimulationNoPush,
    'pda.simulation.epsilon-move' when _matchesArguments(message, const {}) =>
      pdaSimulationEpsilonMove,
    'pda.analysis.empty-pda' when _matchesArguments(message, const {}) =>
      pdaAnalysisEmptyPda,
    'pda.analysis.invalid-max-input-length'
        when _matchesArguments(message, const {}) =>
      pdaAnalysisInvalidMaxInputLength,
    'pda.analysis.invalid-timeout' when _matchesArguments(message, const {}) =>
      pdaAnalysisInvalidTimeout,
    'pda.analysis.timed-out' when _matchesArguments(message, const {}) =>
      pdaAnalysisTimedOut,
    'pda.analysis.failure'
        when _matchesArguments(message, const {
          'error': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'error-detail',
          ),
        }) =>
      pdaAnalysisFailure(_stringArgument(message, 'error')),
    'pda.language-emptiness.invalid-limits'
        when _matchesArguments(message, const {}) =>
      pdaLanguageEmptinessInvalidLimits,
    'pda.language-emptiness.cancelled'
        when _matchesArguments(message, const {}) =>
      pdaLanguageEmptinessCancelled,
    'pda.language-emptiness.witness-replay-failed'
        when _matchesArguments(message, const {}) =>
      pdaLanguageEmptinessWitnessReplayFailed,
    'grammar.shortest-witness.invalid-limits'
        when _matchesArguments(message, const {}) =>
      pdaLanguageEmptinessCfgInvalidLimits,
    'grammar.shortest-witness.missing-start-symbol'
        when _matchesArguments(message, const {}) =>
      pdaLanguageEmptinessCfgMissingStartSymbol,
    'grammar.shortest-witness.overlapping-symbol-sets'
        when _matchesArguments(message, const {}) =>
      pdaLanguageEmptinessCfgOverlappingSymbolSets,
    'grammar.shortest-witness.invalid-production-left'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
        }) =>
      pdaLanguageEmptinessCfgInvalidProductionLeft(
        _stringArgument(message, 'production'),
      ),
    'grammar.shortest-witness.inconsistent-lambda-metadata'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
        }) =>
      pdaLanguageEmptinessCfgInconsistentLambdaMetadata(
        _stringArgument(message, 'production'),
      ),
    'grammar.shortest-witness.epsilon-mixed'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
        }) =>
      pdaLanguageEmptinessCfgEpsilonMixed(
        _stringArgument(message, 'production'),
      ),
    'grammar.shortest-witness.undeclared-symbol'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-symbol',
          ),
        }) =>
      pdaLanguageEmptinessCfgUndeclaredSymbol(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'grammar.shortest-witness.cancelled'
        when _matchesArguments(message, const {}) =>
      pdaLanguageEmptinessCfgCancelled,
    'grammar.shortest-witness.productivity-limit'
        when _matchesArguments(message, const {
          'limit': (
            kind: StructuredMessageArgumentKind.bound,
            role: 'fixed-point-update-limit',
          ),
        }) =>
      pdaLanguageEmptinessCfgProductivityLimit(_intArgument(message, 'limit')),
    'grammar.shortest-witness.derivation-limit'
        when _matchesArguments(message, const {
          'limit': (
            kind: StructuredMessageArgumentKind.bound,
            role: 'derivation-step-limit',
          ),
        }) =>
      pdaLanguageEmptinessCfgDerivationLimit(_intArgument(message, 'limit')),
    'grammar.shortest-witness.witness-mismatch'
        when _matchesArguments(message, const {}) =>
      pdaLanguageEmptinessCfgWitnessMismatch,
    'grammar.shortest-witness.missing-productive-choice'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-nonterminal',
          ),
        }) =>
      pdaLanguageEmptinessCfgMissingProductiveChoice(
        _stringArgument(message, 'symbol'),
      ),
    'cfg.to-pda.empty-grammar' when _matchesArguments(message, const {}) =>
      cfgToPdaEmptyGrammar,
    'cfg.to-pda.missing-start-symbol'
        when _matchesArguments(message, const {}) =>
      cfgToPdaMissingStartSymbol,
    'cfg.to-pda.undeclared-start-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'start-symbol',
          ),
        }) =>
      cfgToPdaUndeclaredStartSymbol(_stringArgument(message, 'symbol')),
    'cfg.to-pda.malformed-production'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
        }) =>
      cfgToPdaMalformedProduction(_stringArgument(message, 'production')),
    'cfg.to-pda.duplicate-production-id'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
        }) =>
      cfgToPdaDuplicateProductionId(_stringArgument(message, 'production')),
    'cfg.to-pda.undeclared-symbol'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'production-id',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-symbol',
          ),
        }) =>
      cfgToPdaUndeclaredSymbol(
        _stringArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'cfg.to-pda.ll-analysis-failed' when _matchesArguments(message, const {}) =>
      cfgToPdaLlAnalysisFailed,
    'cfg.to-pda.ll-conflict'
        when _matchesArguments(message, const {
          'nonterminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'nonterminal',
          ),
          'lookahead': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'lookahead-symbol',
          ),
          'productions': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'production-id-list',
          ),
        }) =>
      cfgToPdaLlConflict(
        _stringArgument(message, 'nonterminal'),
        _stringArgument(message, 'lookahead'),
        _stringArgument(message, 'productions'),
      ),
    'cfg.to-pda.lr-construction-unavailable'
        when _matchesArguments(message, const {}) =>
      cfgToPdaLrConstructionUnavailable,
    'cfg.to-pda.lr-conflict'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'lr-state',
          ),
          'lookahead': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'lookahead-symbol',
          ),
          'productions': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'production-id-list',
          ),
        }) =>
      cfgToPdaLrConflict(
        _intArgument(message, 'state'),
        _stringArgument(message, 'lookahead'),
        _stringArgument(message, 'productions'),
      ),
    'cfg.to-pda.output-invalid' when _matchesArguments(message, const {}) =>
      cfgToPdaOutputInvalid,
    'tm.multi-tape.cancelled' when _matchesArguments(message, const {}) =>
      tmMultiTapeCancelled,
    'tm.multi-tape.timeout' when _matchesArguments(message, const {}) =>
      tmMultiTapeTimeout,
    'tm.multi-tape.configuration-limit'
        when _matchesArguments(message, const {}) =>
      tmMultiTapeConfigurationLimit,
    'tm.multi-tape.entered-final-state'
        when _matchesArguments(message, const {
          'policy': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'acceptance-policy',
          ),
        }) =>
      tmMultiTapeEnteredFinalState(_stringArgument(message, 'policy')),
    'tm.multi-tape.branch-entered-final-state'
        when _matchesArguments(message, const {
          'policy': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'acceptance-policy',
          ),
        }) =>
      tmMultiTapeBranchEnteredFinalState(_stringArgument(message, 'policy')),
    'tm.multi-tape.halted-accepted'
        when _matchesArguments(message, const {
          'policy': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'acceptance-policy',
          ),
        }) =>
      tmMultiTapeHaltedAccepted(_stringArgument(message, 'policy')),
    'tm.multi-tape.branch-halted-accepted'
        when _matchesArguments(message, const {
          'policy': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'acceptance-policy',
          ),
        }) =>
      tmMultiTapeBranchHaltedAccepted(_stringArgument(message, 'policy')),
    'tm.multi-tape.deterministic-conflict'
        when _matchesArguments(message, const {}) =>
      tmMultiTapeDeterministicConflict,
    'tm.multi-tape.deterministic-cycle'
        when _matchesArguments(message, const {}) =>
      tmMultiTapeDeterministicCycle,
    'tm.multi-tape.step-limit' when _matchesArguments(message, const {}) =>
      tmMultiTapeStepLimit,
    'tm.multi-tape.halted-rejected' when _matchesArguments(message, const {}) =>
      tmMultiTapeHaltedRejected,
    'tm.multi-tape.every-branch-rejected'
        when _matchesArguments(message, const {}) =>
      tmMultiTapeEveryBranchRejected,
    'tm.building-blocks.duplicate-machine-id'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'block-name',
          ),
        }) =>
      tmBuildingBlockDuplicateMachineId(_stringArgument(message, 'block')),
    'tm.building-blocks.empty-block-name'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      tmBuildingBlockEmptyBlockName(_stringArgument(message, 'block')),
    'tm.building-blocks.duplicate-block-name'
        when _matchesArguments(message, const {
          'first-block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
          'second-block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      tmBuildingBlockDuplicateBlockName(
        _stringArgument(message, 'first-block'),
        _stringArgument(message, 'second-block'),
      ),
    'tm.building-blocks.missing-initial-state'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'block-name',
          ),
        }) =>
      tmBuildingBlockMissingInitialState(_stringArgument(message, 'block')),
    'tm.building-blocks.missing-root-initial-state'
        when _matchesArguments(message, const {}) =>
      tmBuildingBlockMissingRootInitialState,
    'tm.building-blocks.tape-count-mismatch'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'block-name',
          ),
          'block-tapes': (
            kind: StructuredMessageArgumentKind.count,
            role: 'block-tape-count',
          ),
          'root-tapes': (
            kind: StructuredMessageArgumentKind.count,
            role: 'root-tape-count',
          ),
        }) =>
      tmBuildingBlockTapeCountMismatch(
        _stringArgument(message, 'block'),
        _intArgument(message, 'block-tapes'),
        _intArgument(message, 'root-tapes'),
      ),
    'tm.building-blocks.blank-symbol-mismatch'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'block-name',
          ),
        }) =>
      tmBuildingBlockBlankSymbolMismatch(_stringArgument(message, 'block')),
    'tm.building-blocks.nested-library'
        when _matchesArguments(message, const {
          'block': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'block-name',
          ),
        }) =>
      tmBuildingBlockNestedLibrary(_stringArgument(message, 'block')),
    'tm.building-blocks.recursive-dependency'
        when _matchesArguments(message, const {
          'cycle': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'dependency-cycle',
          ),
        }) =>
      tmBuildingBlockRecursiveDependency(_stringArgument(message, 'cycle')),
    'tm.building-blocks.duplicate-invocation-id'
        when _matchesArguments(message, const {
          'invocation': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'invocation-id',
          ),
        }) =>
      tmBuildingBlockDuplicateInvocationId(
        _stringArgument(message, 'invocation'),
      ),
    'tm.building-blocks.duplicate-invocation-state'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      tmBuildingBlockDuplicateInvocationState(
        _stringArgument(message, 'state'),
      ),
    'tm.building-blocks.missing-anchor-state'
        when _matchesArguments(message, const {
          'invocation': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'invocation-id',
          ),
        }) =>
      tmBuildingBlockMissingAnchorState(_stringArgument(message, 'invocation')),
    'tm.building-blocks.missing-reference'
        when _matchesArguments(message, const {
          'invocation': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'invocation-id',
          ),
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      tmBuildingBlockMissingReference(
        _stringArgument(message, 'invocation'),
        _stringArgument(message, 'block'),
      ),
    'tm.building-blocks.revision-mismatch'
        when _matchesArguments(message, const {
          'invocation': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'invocation-id',
          ),
          'expected': (
            kind: StructuredMessageArgumentKind.count,
            role: 'expected-revision',
          ),
          'block': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'block-name',
          ),
          'actual': (
            kind: StructuredMessageArgumentKind.count,
            role: 'actual-revision',
          ),
        }) =>
      tmBuildingBlockRevisionMismatch(
        _stringArgument(message, 'invocation'),
        _intArgument(message, 'expected'),
        _stringArgument(message, 'block'),
        _intArgument(message, 'actual'),
      ),
    'tm.building-blocks.accepting-root-invocation'
        when _matchesArguments(message, const {
          'invocation': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'invocation-id',
          ),
          'block': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'block-id',
          ),
        }) =>
      tmBuildingBlockAcceptingRootInvocation(
        _stringArgument(message, 'invocation'),
        _stringArgument(message, 'block'),
      ),
    'tm.building-blocks.invalid-project'
        when _matchesArguments(message, const {}) =>
      tmBuildingBlockInvalidProject,
    'tm.building-blocks.cancelled' when _matchesArguments(message, const {}) =>
      tmBuildingBlockCancelled,
    'tm.building-blocks.timeout' when _matchesArguments(message, const {}) =>
      tmBuildingBlockTimeout,
    'tm.building-blocks.configuration-limit'
        when _matchesArguments(message, const {}) =>
      tmBuildingBlockConfigurationLimit,
    'tm.building-blocks.call-depth-limit'
        when _matchesArguments(message, const {}) =>
      tmBuildingBlockCallDepthLimit,
    'tm.building-blocks.step-limit' when _matchesArguments(message, const {}) =>
      tmBuildingBlockStepLimit,
    'tm.building-blocks.entered-final-state'
        when _matchesArguments(message, const {
          'policy': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'acceptance-policy',
          ),
        }) =>
      tmBuildingBlockEnteredFinalState(_stringArgument(message, 'policy')),
    'tm.building-blocks.halted-accepted'
        when _matchesArguments(message, const {
          'policy': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'acceptance-policy',
          ),
        }) =>
      tmBuildingBlockHaltedAccepted(_stringArgument(message, 'policy')),
    'tm.building-blocks.halted-rejected'
        when _matchesArguments(message, const {}) =>
      tmBuildingBlockHaltedRejected,
    'tm.building-blocks.finite-graph-rejected'
        when _matchesArguments(message, const {}) =>
      tmBuildingBlockFiniteGraphRejected,
    'tm.building-blocks.repeated-configuration'
        when _matchesArguments(message, const {}) =>
      tmBuildingBlockRepeatedConfiguration,
    'tm.building-blocks.enter-block'
        when _matchesArguments(message, const {
          'machine': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'machine-id',
          ),
        }) =>
      tmBuildingBlockEnterBlock(_stringArgument(message, 'machine')),
    'tm.building-blocks.transition'
        when _matchesArguments(message, const {
          'transition': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'transition-id',
          ),
        }) =>
      tmBuildingBlockTransition(_stringArgument(message, 'transition')),
    'tm.building-blocks.return-from-block'
        when _matchesArguments(message, const {
          'machine': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'machine-id',
          ),
        }) =>
      tmBuildingBlockReturnFromBlock(_stringArgument(message, 'machine')),
    'tm.to-unrestricted-grammar.invalid-machine'
        when _tmToGrammarInvalidMachineContract(message) =>
      message.arguments.isEmpty
          ? tmToGrammarInvalidMachine
          : tmToGrammarInvalidMachineDetail(_stringArgument(message, 'detail')),
    'tm.to-unrestricted-grammar.missing-initial-state'
        when _matchesArguments(message, const {}) =>
      tmToGrammarMissingInitialState,
    'tm.to-unrestricted-grammar.no-accepting-state'
        when _matchesArguments(message, const {}) =>
      tmToGrammarNoAcceptingState,
    'tm.to-unrestricted-grammar.multi-tape-unsupported'
        when _tmToGrammarMultiTapeContract(message) =>
      message.arguments.isEmpty
          ? tmToGrammarMultiTapeUnsupportedGeneric
          : tmToGrammarMultiTapeUnsupported(_intArgument(message, 'tapes')),
    'tm.to-unrestricted-grammar.building-blocks-unsupported'
        when _tmToGrammarBuildingBlocksContract(message) =>
      message.arguments.isEmpty
          ? tmToGrammarBuildingBlocksUnsupportedGeneric
          : tmToGrammarBuildingBlocksUnsupported(
              _stringArgument(message, 'blocks'),
            ),
    'tm.to-unrestricted-grammar.blank-in-input-alphabet'
        when _tmToGrammarSymbolContract(message, role: 'tape-symbol') =>
      message.arguments.isEmpty
          ? tmToGrammarBlankInInputAlphabetGeneric
          : tmToGrammarBlankInInputAlphabet(_stringArgument(message, 'symbol')),
    'tm.to-unrestricted-grammar.input-outside-tape-alphabet'
        when _tmToGrammarSymbolContract(message, role: 'input-symbol') =>
      message.arguments.isEmpty
          ? tmToGrammarInputOutsideTapeAlphabetGeneric
          : tmToGrammarInputOutsideTapeAlphabet(
              _stringArgument(message, 'symbol'),
            ),
    'tm.to-unrestricted-grammar.construction-limit'
        when _tmToGrammarConstructionLimitContract(message) =>
      message.arguments.containsKey('limit')
          ? tmToGrammarConstructionLimit(_intArgument(message, 'limit'))
          : message.arguments.containsKey('detail')
          ? tmToGrammarConstructionLimitDetail(
              _stringArgument(message, 'detail'),
            )
          : tmToGrammarConstructionLimitGeneric,
    'tm.to-unrestricted-grammar.output-invalid'
        when _tmToGrammarOutputInvalidContract(message) =>
      message.arguments.isEmpty
          ? tmToGrammarOutputInvalidGeneric
          : tmToGrammarOutputInvalid(_stringArgument(message, 'detail')),
    'tm.to-unrestricted-grammar.unreachable-state'
        when _tmToGrammarStateContract(message) =>
      message.arguments.isEmpty
          ? tmToGrammarUnreachableStateGeneric
          : tmToGrammarUnreachableState(_stringArgument(message, 'state')),
    'algorithm.fsa-determinizer.failed'
        when _matchesArguments(message, const {
          'automaton': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'automaton-label',
          ),
        }) =>
      fsaDeterminizerFailed(_stringArgument(message, 'automaton')),
    'validation.fsa-empty' when _matchesArguments(message, const {}) =>
      validationFsaEmpty,
    'validation.fsa-no-initial' when _matchesArguments(message, const {}) =>
      validationFsaNoInitial,
    'validation.fsa-invalid-initial'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationFsaInvalidInitial(_stringArgument(message, 'state')),
    'validation.fsa-empty-alphabet' when _matchesArguments(message, const {}) =>
      validationFsaEmptyAlphabet,
    'validation.fsa-invalid-accepting'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationFsaInvalidAccepting(_stringArgument(message, 'state')),
    'validation.fsa-bad-from'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationFsaBadFrom(_stringArgument(message, 'state')),
    'validation.fsa-bad-to'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationFsaBadTo(_stringArgument(message, 'state')),
    'validation.fsa-bad-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      validationFsaBadSymbol(_stringArgument(message, 'symbol')),
    'validation.fsa-nondeterministic'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'transition-count',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      validationFsaNondeterministic(
        _stringArgument(message, 'state'),
        _intArgument(message, 'count'),
        _stringArgument(message, 'symbol'),
      ),
    'validation.pda-empty' when _matchesArguments(message, const {}) =>
      validationPdaEmpty,
    'validation.pda-no-initial' when _matchesArguments(message, const {}) =>
      validationPdaNoInitial,
    'validation.pda-invalid-initial'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationPdaInvalidInitial(_stringArgument(message, 'state')),
    'validation.pda-no-accepting' when _matchesArguments(message, const {}) =>
      validationPdaNoAccepting,
    'validation.pda-empty-input-alphabet'
        when _matchesArguments(message, const {}) =>
      validationPdaEmptyInputAlphabet,
    'validation.pda-empty-stack-alphabet'
        when _matchesArguments(message, const {}) =>
      validationPdaEmptyStackAlphabet,
    'validation.pda-invalid-initial-stack'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
        }) =>
      validationPdaInvalidInitialStack(_stringArgument(message, 'symbol')),
    'validation.pda-invalid-accepting'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationPdaInvalidAccepting(_stringArgument(message, 'state')),
    'validation.pda-bad-from'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationPdaBadFrom(_stringArgument(message, 'state')),
    'validation.pda-bad-to'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationPdaBadTo(_stringArgument(message, 'state')),
    'validation.pda-bad-input-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      validationPdaBadInputSymbol(_stringArgument(message, 'symbol')),
    'validation.pda-bad-stack-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
        }) =>
      validationPdaBadStackSymbol(_stringArgument(message, 'symbol')),
    'validation.pda-bad-push-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'stack-symbol',
          ),
        }) =>
      validationPdaBadPushSymbol(_stringArgument(message, 'symbol')),
    'validation.tm-empty' when _matchesArguments(message, const {}) =>
      validationTmEmpty,
    'validation.tm-no-initial' when _matchesArguments(message, const {}) =>
      validationTmNoInitial,
    'validation.tm-invalid-initial'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationTmInvalidInitial(_stringArgument(message, 'state')),
    'validation.tm-no-accepting' when _matchesArguments(message, const {}) =>
      validationTmNoAccepting,
    'validation.tm-empty-input-alphabet'
        when _matchesArguments(message, const {}) =>
      validationTmEmptyInputAlphabet,
    'validation.tm-empty-tape-alphabet'
        when _matchesArguments(message, const {}) =>
      validationTmEmptyTapeAlphabet,
    'validation.tm-empty-blank' when _matchesArguments(message, const {}) =>
      validationTmEmptyBlank,
    'validation.tm-blank-not-in-tape'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'blank-symbol',
          ),
        }) =>
      validationTmBlankNotInTape(_stringArgument(message, 'symbol')),
    'validation.tm-input-not-in-tape'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      validationTmInputNotInTape(_stringArgument(message, 'symbol')),
    'validation.tm-invalid-accepting'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationTmInvalidAccepting(_stringArgument(message, 'state')),
    'validation.tm-bad-from'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationTmBadFrom(_stringArgument(message, 'state')),
    'validation.tm-bad-to'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      validationTmBadTo(_stringArgument(message, 'state')),
    'validation.tm-bad-read-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'tape-symbol',
          ),
        }) =>
      validationTmBadReadSymbol(_stringArgument(message, 'symbol')),
    'validation.tm-bad-write-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'tape-symbol',
          ),
        }) =>
      validationTmBadWriteSymbol(_stringArgument(message, 'symbol')),
    'validation.tm-bad-move'
        when _matchesArguments(message, const {
          'direction': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'move-direction',
          ),
        }) =>
      validationTmBadMove(_stringArgument(message, 'direction')),
    'validation.cfg-empty' when _matchesArguments(message, const {}) =>
      validationCfgEmpty,
    'validation.cfg-no-nonterminals'
        when _matchesArguments(message, const {}) =>
      validationCfgNoNonterminals,
    'validation.cfg-no-terminals' when _matchesArguments(message, const {}) =>
      validationCfgNoTerminals,
    'validation.cfg-empty-start' when _matchesArguments(message, const {}) =>
      validationCfgEmptyStart,
    'validation.cfg-bad-start'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'start-symbol',
          ),
        }) =>
      validationCfgBadStart(_stringArgument(message, 'symbol')),
    'validation.cfg-empty-left'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'production-index',
          ),
        }) =>
      validationCfgEmptyLeft(_intArgument(message, 'production')),
    'validation.cfg-bad-left'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'production-index',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-symbol',
          ),
        }) =>
      validationCfgBadLeft(
        _intArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'validation.cfg-empty-right'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'production-index',
          ),
        }) =>
      validationCfgEmptyRight(_intArgument(message, 'production')),
    'validation.cfg-bad-symbol'
        when _matchesArguments(message, const {
          'production': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'production-index',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'grammar-symbol',
          ),
        }) =>
      validationCfgBadSymbol(
        _intArgument(message, 'production'),
        _stringArgument(message, 'symbol'),
      ),
    'validation.input-empty' when _matchesArguments(message, const {}) =>
      validationInputEmpty,
    'validation.input-invalid-symbol'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'position': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'input-position',
          ),
        }) =>
      validationInputInvalidSymbol(
        _stringArgument(message, 'symbol'),
        _intArgument(message, 'position'),
      ),
    'automata.nfa-to-dfa.initial-epsilon-closure-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepInitialEpsilonClosureTitle,
    'automata.nfa-to-dfa.initial-epsilon-closure-explanation'
        when _matchesArguments(message, const {
          'initial-state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-label',
          ),
          'epsilon-closure': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'contains-accepting-state': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'accepting-state-presence',
          ),
        }) =>
      nfaToDfaStepInitialEpsilonClosureExplanation(
        _stringArgument(message, 'initial-state'),
        _stringArgument(message, 'epsilon-closure'),
        _boolArgument(message, 'contains-accepting-state').toString(),
      ),
    'automata.nfa-to-dfa.initial-epsilon-closure-step-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepInitialEpsilonClosureStepTitle,
    'automata.nfa-to-dfa.initial-state'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-label',
          ),
        }) =>
      nfaToDfaStepInitialState(_stringArgument(message, 'state')),
    'automata.nfa-to-dfa.epsilon-closure-reached'
        when _matchesArguments(message, const {
          'state-set': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      nfaToDfaStepEpsilonClosureReached(_stringArgument(message, 'state-set')),
    'automata.nfa-to-dfa.initial-state-is-accepting'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepInitialStateIsAccepting,
    'automata.nfa-to-dfa.process-symbol-title'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      nfaToDfaStepProcessSymbolTitle(_stringArgument(message, 'symbol')),
    'automata.nfa-to-dfa.process-symbol-explanation'
        when _matchesArguments(message, const {
          'current-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'reachable-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      nfaToDfaStepProcessSymbolExplanation(
        _stringArgument(message, 'current-states'),
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'reachable-states'),
      ),
    'automata.nfa-to-dfa.process-symbol-step-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepProcessSymbolStepTitle,
    'automata.nfa-to-dfa.current-dfa-state-set'
        when _matchesArguments(message, const {
          'state-set': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      nfaToDfaStepCurrentDfaStateSet(_stringArgument(message, 'state-set')),
    'automata.nfa-to-dfa.collect-symbol-destinations'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      nfaToDfaStepCollectSymbolDestinations(_stringArgument(message, 'symbol')),
    'automata.nfa-to-dfa.reachable-before-epsilon-closure'
        when _matchesArguments(message, const {
          'state-set': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      nfaToDfaStepReachableBeforeEpsilonClosure(
        _stringArgument(message, 'state-set'),
      ),
    'automata.nfa-to-dfa.epsilon-closure-of-reachable-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepEpsilonClosureOfReachableTitle,
    'automata.nfa-to-dfa.epsilon-closure-of-reachable-explanation'
        when _matchesArguments(message, const {
          'reachable-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'epsilon-closure': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'is-new-state': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'new-state',
          ),
          'contains-accepting-state': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'accepting-state-presence',
          ),
        }) =>
      nfaToDfaStepEpsilonClosureOfReachableExplanation(
        _stringArgument(message, 'reachable-states'),
        _stringArgument(message, 'epsilon-closure'),
        _boolArgument(message, 'is-new-state').toString(),
        _boolArgument(message, 'contains-accepting-state').toString(),
      ),
    'automata.nfa-to-dfa.epsilon-closure-of-reachable-step-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepEpsilonClosureOfReachableStepTitle,
    'automata.nfa-to-dfa.epsilon-transitions-do-not-consume-input'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepEpsilonTransitionsDoNotConsumeInput,
    'automata.nfa-to-dfa.epsilon-closure-reached-from-states'
        when _matchesArguments(message, const {
          'reachable-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'epsilon-closure': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      nfaToDfaStepEpsilonClosureReachedFromStates(
        _stringArgument(message, 'reachable-states'),
        _stringArgument(message, 'epsilon-closure'),
      ),
    'automata.nfa-to-dfa.new-dfa-state-set'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepNewDfaStateSet,
    'automata.nfa-to-dfa.existing-dfa-state-set'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepExistingDfaStateSet,
    'automata.nfa-to-dfa.accepting-dfa-state-set'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepAcceptingDfaStateSet,
    'automata.nfa-to-dfa.create-dfa-state-title'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
        }) =>
      nfaToDfaStepCreateDfaStateTitle(_stringArgument(message, 'state')),
    'automata.nfa-to-dfa.create-dfa-state-explanation'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
          'state-set': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'is-accepting': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'accepting-state',
          ),
        }) =>
      nfaToDfaStepCreateDfaStateExplanation(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'state-set'),
        _boolArgument(message, 'is-accepting').toString(),
      ),
    'automata.nfa-to-dfa.create-dfa-state-step-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepCreateDfaStateStepTitle,
    'automata.nfa-to-dfa.subset-construction-distinct-state-sets'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepSubsetConstructionDistinctStateSets,
    'automata.nfa-to-dfa.dfa-state-represents-nfa-set'
        when _matchesArguments(message, const {
          'state-set': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      nfaToDfaStepDfaStateRepresentsNfaSet(
        _stringArgument(message, 'state-set'),
      ),
    'automata.nfa-to-dfa.accepting-dfa-state'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepAcceptingDfaState,
    'automata.nfa-to-dfa.non-accepting-dfa-state'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepNonAcceptingDfaState,
    'automata.nfa-to-dfa.create-dfa-transition-title'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      nfaToDfaStepCreateDfaTransitionTitle(_stringArgument(message, 'symbol')),
    'automata.nfa-to-dfa.create-dfa-transition-explanation'
        when _matchesArguments(message, const {
          'from-state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'to-state': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'state-id',
          ),
          'from-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'to-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      nfaToDfaStepCreateDfaTransitionExplanation(
        _stringArgument(message, 'from-state'),
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'to-state'),
        _stringArgument(message, 'from-states'),
        _stringArgument(message, 'to-states'),
      ),
    'automata.nfa-to-dfa.create-dfa-transition-step-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepCreateDfaTransitionStepTitle,
    'automata.nfa-to-dfa.nfa-transition-reachability'
        when _matchesArguments(message, const {
          'from-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'to-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      nfaToDfaStepNfaTransitionReachability(
        _stringArgument(message, 'from-states'),
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'to-states'),
      ),
    'automata.nfa-to-dfa.single-deterministic-transition'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepSingleDeterministicTransition,
    'automata.nfa-to-dfa.completion-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepCompletionTitle,
    'automata.nfa-to-dfa.completion-explanation'
        when _matchesArguments(message, const {
          'state-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'dfa-state-count',
          ),
          'transition-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'dfa-transition-count',
          ),
          'accepting-state-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'accepting-state-count',
          ),
        }) =>
      nfaToDfaStepCompletionExplanation(
        _intArgument(message, 'state-count'),
        _intArgument(message, 'transition-count'),
        _intArgument(message, 'accepting-state-count'),
      ),
    'automata.nfa-to-dfa.completion-step-title'
        when _matchesArguments(message, const {}) =>
      nfaToDfaStepCompletionStepTitle,
    'automata.nfa-to-dfa.created-state-count'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'dfa-state-count',
          ),
        }) =>
      nfaToDfaStepCreatedStateCount(_intArgument(message, 'count')),
    'automata.nfa-to-dfa.created-transition-count'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'dfa-transition-count',
          ),
        }) =>
      nfaToDfaStepCreatedTransitionCount(_intArgument(message, 'count')),
    'automata.nfa-to-dfa.marked-accepting-state-count'
        when _matchesArguments(message, const {
          'count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'accepting-state-count',
          ),
        }) =>
      nfaToDfaStepMarkedAcceptingStateCount(_intArgument(message, 'count')),
    'automaton.dfa-minimization.step.initial-partition-title'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationStepInitialPartitionTitle,
    'automaton.dfa-minimization.step.initial-partition-explanation'
        when _matchesArguments(message, const {
          'accepting-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'non-accepting-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      dfaMinimizationStepInitialPartitionExplanation(
        _stringArgument(message, 'accepting-states'),
        _stringArgument(message, 'non-accepting-states'),
      ),
    'automaton.dfa-minimization.step.remove-unreachable-title'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationStepRemoveUnreachableTitle,
    'automaton.dfa-minimization.step.remove-unreachable-explanation'
        when _matchesArguments(message, const {
          'unreachable-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'reachable-state-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'reachable-state-count',
          ),
        }) =>
      dfaMinimizationStepRemoveUnreachableExplanation(
        _stringArgument(message, 'unreachable-states'),
        _intArgument(message, 'reachable-state-count'),
      ),
    'automaton.dfa-minimization.step.select-set-title'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationStepSelectSetTitle,
    'automaton.dfa-minimization.step.select-set-explanation'
        when _matchesArguments(message, const {
          'states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
        }) =>
      dfaMinimizationStepSelectSetExplanation(
        _stringArgument(message, 'states'),
      ),
    'automaton.dfa-minimization.step.find-predecessors-title'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      dfaMinimizationStepFindPredecessorsTitle(
        _stringArgument(message, 'symbol'),
      ),
    'automaton.dfa-minimization.step.find-predecessors-explanation'
        when _matchesArguments(message, const {
          'states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'predecessors': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'has-predecessors': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'predecessor-presence',
          ),
        }) =>
      dfaMinimizationStepFindPredecessorsExplanation(
        _stringArgument(message, 'states'),
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'predecessors'),
        _boolArgument(message, 'has-predecessors').toString(),
      ),
    'automaton.dfa-minimization.step.split-class-title'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationStepSplitClassTitle,
    'automaton.dfa-minimization.step.split-class-explanation'
        when _matchesArguments(message, const {
          'split-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
          'intersection-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'difference-states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'old-partition-size': (
            kind: StructuredMessageArgumentKind.count,
            role: 'partition-size',
          ),
          'new-partition-size': (
            kind: StructuredMessageArgumentKind.count,
            role: 'partition-size',
          ),
        }) =>
      dfaMinimizationStepSplitClassExplanation(
        _stringArgument(message, 'split-states'),
        _stringArgument(message, 'symbol'),
        _stringArgument(message, 'intersection-states'),
        _stringArgument(message, 'difference-states'),
        _intArgument(message, 'old-partition-size'),
        _intArgument(message, 'new-partition-size'),
      ),
    'automaton.dfa-minimization.step.no-split-title'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      dfaMinimizationStepNoSplitTitle(_stringArgument(message, 'symbol')),
    'automaton.dfa-minimization.step.no-split-explanation'
        when _matchesArguments(message, const {
          'states': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      dfaMinimizationStepNoSplitExplanation(
        _stringArgument(message, 'states'),
        _stringArgument(message, 'symbol'),
      ),
    'automaton.dfa-minimization.step.partition-stable-title'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationStepPartitionStableTitle,
    'automaton.dfa-minimization.step.partition-stable-explanation'
        when _matchesArguments(message, const {
          'partition-size': (
            kind: StructuredMessageArgumentKind.count,
            role: 'partition-size',
          ),
        }) =>
      dfaMinimizationStepPartitionStableExplanation(
        _intArgument(message, 'partition-size'),
      ),
    'automaton.dfa-minimization.step.create-minimized-state-title'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-id',
          ),
        }) =>
      dfaMinimizationStepCreateMinimizedStateTitle(
        _stringArgument(message, 'state'),
      ),
    'automaton.dfa-minimization.step.create-minimized-state-explanation'
        when _matchesArguments(message, const {
          'state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-id',
          ),
          'equivalence-class': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-labels',
          ),
          'is-initial': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'initial-state',
          ),
          'is-accepting': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'accepting-state',
          ),
        }) =>
      dfaMinimizationStepCreateMinimizedStateExplanation(
        _stringArgument(message, 'state'),
        _stringArgument(message, 'equivalence-class'),
        _boolArgument(message, 'is-initial').toString(),
        _boolArgument(message, 'is-accepting').toString(),
      ),
    'automaton.dfa-minimization.step.create-minimized-transition-title'
        when _matchesArguments(message, const {
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      dfaMinimizationStepCreateMinimizedTransitionTitle(
        _stringArgument(message, 'symbol'),
      ),
    'automaton.dfa-minimization.step.create-minimized-transition-explanation'
        when _matchesArguments(message, const {
          'from-state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-id',
          ),
          'to-state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-id',
          ),
          'symbol': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'input-symbol',
          ),
        }) =>
      dfaMinimizationStepCreateMinimizedTransitionExplanation(
        _stringArgument(message, 'from-state'),
        _stringArgument(message, 'to-state'),
        _stringArgument(message, 'symbol'),
      ),
    'automaton.dfa-minimization.step.completion-title'
        when _matchesArguments(message, const {}) =>
      dfaMinimizationStepCompletionTitle,
    'automaton.dfa-minimization.step.completion-explanation'
        when _matchesArguments(message, const {
          'original-state-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'state-count',
          ),
          'minimized-state-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'state-count',
          ),
          'transition-count': (
            kind: StructuredMessageArgumentKind.count,
            role: 'transition-count',
          ),
          'reduction': (
            kind: StructuredMessageArgumentKind.integer,
            role: 'state-reduction',
          ),
          'has-reduction': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'state-reduction-presence',
          ),
        }) =>
      dfaMinimizationStepCompletionExplanation(
        _intArgument(message, 'original-state-count'),
        _intArgument(message, 'minimized-state-count'),
        _intArgument(message, 'transition-count'),
        _intArgument(message, 'reduction'),
        _boolArgument(message, 'has-reduction').toString(),
      ),
    'grammar.cyk.step.initialize-title'
        when _matchesArguments(message, const {}) =>
      cykStepInitializeTitle,
    'grammar.cyk.step.initialize-explanation'
        when _matchesArguments(message, const {
          'input': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'input-string',
          ),
          'table-size': (
            kind: StructuredMessageArgumentKind.count,
            role: 'token-count',
          ),
        }) =>
      cykStepInitializeExplanation(
        _stringArgument(message, 'input'),
        _intArgument(message, 'table-size'),
      ),
    'grammar.cyk.step.initialize-step-title'
        when _matchesArguments(message, const {}) =>
      cykStepInitializeStepTitle,
    'grammar.cyk.step.initialize-input-bullet'
        when _matchesArguments(message, const {
          'input': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'input-string',
          ),
          'table-size': (
            kind: StructuredMessageArgumentKind.count,
            role: 'token-count',
          ),
        }) =>
      cykStepInitializeInputBullet(
        _stringArgument(message, 'input'),
        _intArgument(message, 'table-size'),
      ),
    'grammar.cyk.step.initialize-table-bullet'
        when _matchesArguments(message, const {}) =>
      cykStepInitializeTableBullet,
    'grammar.cyk.step.fill-base-case-title'
        when _matchesArguments(message, const {
          'terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'terminal',
          ),
        }) =>
      cykStepFillBaseCaseTitle(_stringArgument(message, 'terminal')),
    'grammar.cyk.step.fill-base-case-explanation'
        when _matchesArguments(message, const {
          'position': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'input-position',
          ),
          'terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'terminal',
          ),
          'variables': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
          'has-variables': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'deriving-variable-presence',
          ),
        }) =>
      cykStepFillBaseCaseExplanation(
        _intArgument(message, 'position'),
        _stringArgument(message, 'terminal'),
        _stringArgument(message, 'variables'),
        _boolArgument(message, 'has-variables').toString(),
      ),
    'grammar.cyk.step.fill-base-case-step-title'
        when _matchesArguments(message, const {
          'terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'terminal',
          ),
        }) =>
      cykStepFillBaseCaseStepTitle(_stringArgument(message, 'terminal')),
    'grammar.cyk.step.fill-base-case-fragment-bullet'
        when _matchesArguments(message, const {
          'position': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'input-position',
          ),
          'terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'terminal',
          ),
        }) =>
      cykStepFillBaseCaseFragmentBullet(
        _intArgument(message, 'position'),
        _stringArgument(message, 'terminal'),
      ),
    'grammar.cyk.step.fill-base-case-production-bullet'
        when _matchesArguments(message, const {}) =>
      cykStepFillBaseCaseProductionBullet,
    'grammar.cyk.step.fill-base-case-empty-bullet'
        when _matchesArguments(message, const {
          'terminal': (
            kind: StructuredMessageArgumentKind.symbol,
            role: 'terminal',
          ),
        }) =>
      cykStepFillBaseCaseEmptyBullet(_stringArgument(message, 'terminal')),
    'grammar.cyk.step.fill-base-case-added-bullet'
        when _matchesArguments(message, const {
          'variables': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
        }) =>
      cykStepFillBaseCaseAddedBullet(_stringArgument(message, 'variables')),
    'grammar.cyk.step.process-cell-title'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
        }) =>
      cykStepProcessCellTitle(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
      ),
    'grammar.cyk.step.process-cell-explanation'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
          'length': (
            kind: StructuredMessageArgumentKind.count,
            role: 'substring-length',
          ),
        }) =>
      cykStepProcessCellExplanation(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
        _stringArgument(message, 'substring'),
        _intArgument(message, 'length'),
      ),
    'grammar.cyk.step.process-cell-step-title'
        when _matchesArguments(message, const {
          'substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
        }) =>
      cykStepProcessCellStepTitle(_stringArgument(message, 'substring')),
    'grammar.cyk.step.process-cell-location-bullet'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'length': (
            kind: StructuredMessageArgumentKind.count,
            role: 'substring-length',
          ),
        }) =>
      cykStepProcessCellLocationBullet(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
        _intArgument(message, 'length'),
      ),
    'grammar.cyk.step.process-cell-split-bullet'
        when _matchesArguments(message, const {}) =>
      cykStepProcessCellSplitBullet,
    'grammar.cyk.step.check-split-title'
        when _matchesArguments(message, const {
          'split-point': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'split-position',
          ),
        }) =>
      cykStepCheckSplitTitle(_intArgument(message, 'split-point')),
    'grammar.cyk.step.check-split-explanation'
        when _matchesArguments(message, const {
          'substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
          'left-substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
          'right-substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
          'left-row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'left-column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'right-row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'right-column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'left-variables': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
          'right-variables': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
          'has-left-variables': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'left-variable-presence',
          ),
          'has-right-variables': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'right-variable-presence',
          ),
        }) =>
      cykStepCheckSplitExplanation(
        _stringArgument(message, 'substring'),
        _stringArgument(message, 'left-substring'),
        _stringArgument(message, 'right-substring'),
        _intArgument(message, 'left-row'),
        _intArgument(message, 'left-column'),
        _intArgument(message, 'right-row'),
        _intArgument(message, 'right-column'),
        _stringArgument(message, 'left-variables'),
        _stringArgument(message, 'right-variables'),
        _boolArgument(message, 'has-left-variables').toString(),
        _boolArgument(message, 'has-right-variables').toString(),
      ),
    'grammar.cyk.step.check-split-step-title'
        when _matchesArguments(message, const {
          'left-substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
          'right-substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
        }) =>
      cykStepCheckSplitStepTitle(
        _stringArgument(message, 'left-substring'),
        _stringArgument(message, 'right-substring'),
      ),
    'grammar.cyk.step.check-split-left-bullet'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'variables': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
          'has-variables': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'left-variable-presence',
          ),
        }) =>
      cykStepCheckSplitLeftBullet(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
        _stringArgument(message, 'variables'),
        _boolArgument(message, 'has-variables').toString(),
      ),
    'grammar.cyk.step.check-split-right-bullet'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'variables': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
          'has-variables': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'right-variable-presence',
          ),
        }) =>
      cykStepCheckSplitRightBullet(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
        _stringArgument(message, 'variables'),
        _boolArgument(message, 'has-variables').toString(),
      ),
    'grammar.cyk.step.check-split-production-bullet'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
        }) =>
      cykStepCheckSplitProductionBullet(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
      ),
    'grammar.cyk.step.apply-production-title'
        when _matchesArguments(message, const {
          'variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'left-variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'right-variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
        }) =>
      cykStepApplyProductionTitle(
        _stringArgument(message, 'variable'),
        _stringArgument(message, 'left-variable'),
        _stringArgument(message, 'right-variable'),
      ),
    'grammar.cyk.step.apply-production-explanation'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'left-variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'right-variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
        }) =>
      cykStepApplyProductionExplanation(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
        _stringArgument(message, 'variable'),
        _stringArgument(message, 'left-variable'),
        _stringArgument(message, 'right-variable'),
        _stringArgument(message, 'substring'),
      ),
    'grammar.cyk.step.apply-production-step-title'
        when _matchesArguments(message, const {
          'variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'left-variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'right-variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
        }) =>
      cykStepApplyProductionStepTitle(
        _stringArgument(message, 'variable'),
        _stringArgument(message, 'left-variable'),
        _stringArgument(message, 'right-variable'),
      ),
    'grammar.cyk.step.apply-production-combine-bullet'
        when _matchesArguments(message, const {}) =>
      cykStepApplyProductionCombineBullet,
    'grammar.cyk.step.apply-production-derivation-bullet'
        when _matchesArguments(message, const {
          'left-variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'right-variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
          'substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
        }) =>
      cykStepApplyProductionDerivationBullet(
        _stringArgument(message, 'left-variable'),
        _stringArgument(message, 'right-variable'),
        _stringArgument(message, 'variable'),
        _stringArgument(message, 'substring'),
      ),
    'grammar.cyk.step.apply-production-add-bullet'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'variable': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'nonterminal',
          ),
        }) =>
      cykStepApplyProductionAddBullet(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
        _stringArgument(message, 'variable'),
      ),
    'grammar.cyk.step.complete-cell-title'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
        }) =>
      cykStepCompleteCellTitle(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
      ),
    'grammar.cyk.step.complete-cell-explanation'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
          'substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
          'nonterminals': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
          'has-nonterminals': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'nonterminal-presence',
          ),
        }) =>
      cykStepCompleteCellExplanation(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
        _stringArgument(message, 'substring'),
        _stringArgument(message, 'nonterminals'),
        _boolArgument(message, 'has-nonterminals').toString(),
      ),
    'grammar.cyk.step.complete-cell-step-title'
        when _matchesArguments(message, const {
          'row': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-row',
          ),
          'column': (
            kind: StructuredMessageArgumentKind.positionIndex,
            role: 'table-column',
          ),
        }) =>
      cykStepCompleteCellStepTitle(
        _intArgument(message, 'row'),
        _intArgument(message, 'column'),
      ),
    'grammar.cyk.step.complete-cell-substring-bullet'
        when _matchesArguments(message, const {
          'substring': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'substring',
          ),
        }) =>
      cykStepCompleteCellSubstringBullet(_stringArgument(message, 'substring')),
    'grammar.cyk.step.complete-cell-empty-bullet'
        when _matchesArguments(message, const {}) =>
      cykStepCompleteCellEmptyBullet,
    'grammar.cyk.step.complete-cell-nonterminals-bullet'
        when _matchesArguments(message, const {
          'nonterminals': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
        }) =>
      cykStepCompleteCellNonterminalsBullet(
        _stringArgument(message, 'nonterminals'),
      ),
    'grammar.cyk.step.check-acceptance-title'
        when _matchesArguments(message, const {}) =>
      cykStepCheckAcceptanceTitle,
    'grammar.cyk.step.check-acceptance-explanation'
        when _matchesArguments(message, const {
          'input': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'input-string',
          ),
          'start-symbol': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'start-symbol',
          ),
          'nonterminals': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
          'has-nonterminals': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'final-cell-presence',
          ),
          'accepted': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'acceptance-result',
          ),
        }) =>
      cykStepCheckAcceptanceExplanation(
        _stringArgument(message, 'input'),
        _stringArgument(message, 'start-symbol'),
        _stringArgument(message, 'nonterminals'),
        _boolArgument(message, 'has-nonterminals').toString(),
        _boolArgument(message, 'accepted').toString(),
      ),
    'grammar.cyk.step.check-acceptance-step-title'
        when _matchesArguments(message, const {}) =>
      cykStepCheckAcceptanceStepTitle,
    'grammar.cyk.step.check-acceptance-final-cell-bullet'
        when _matchesArguments(message, const {
          'nonterminals': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'nonterminal-list',
          ),
        }) =>
      cykStepCheckAcceptanceFinalCellBullet(
        _stringArgument(message, 'nonterminals'),
      ),
    'grammar.cyk.step.check-acceptance-accepted-bullet'
        when _matchesArguments(message, const {
          'start-symbol': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'start-symbol',
          ),
        }) =>
      cykStepCheckAcceptanceAcceptedBullet(
        _stringArgument(message, 'start-symbol'),
      ),
    'grammar.cyk.step.check-acceptance-rejected-bullet'
        when _matchesArguments(message, const {
          'start-symbol': (
            kind: StructuredMessageArgumentKind.identifier,
            role: 'start-symbol',
          ),
        }) =>
      cykStepCheckAcceptanceRejectedBullet(
        _stringArgument(message, 'start-symbol'),
      ),
    'grammar.cyk.step.completion-title'
        when _matchesArguments(message, const {}) =>
      cykStepCompletionTitle,
    'grammar.cyk.step.completion-explanation'
        when _matchesArguments(message, const {
          'input': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'input-string',
          ),
          'total-cells': (
            kind: StructuredMessageArgumentKind.count,
            role: 'cell-count',
          ),
          'filled-cells': (
            kind: StructuredMessageArgumentKind.count,
            role: 'filled-cell-count',
          ),
          'accepted': (
            kind: StructuredMessageArgumentKind.boolean,
            role: 'acceptance-result',
          ),
        }) =>
      cykStepCompletionExplanation(
        _stringArgument(message, 'input'),
        _intArgument(message, 'total-cells'),
        _intArgument(message, 'filled-cells'),
        _boolArgument(message, 'accepted').toString(),
      ),
    'grammar.cyk.step.completion-step-title'
        when _matchesArguments(message, const {}) =>
      cykStepCompletionStepTitle,
    'grammar.cyk.step.completion-filled-cells-bullet'
        when _matchesArguments(message, const {
          'total-cells': (
            kind: StructuredMessageArgumentKind.count,
            role: 'cell-count',
          ),
          'filled-cells': (
            kind: StructuredMessageArgumentKind.count,
            role: 'filled-cell-count',
          ),
        }) =>
      cykStepCompletionFilledCellsBullet(
        _intArgument(message, 'total-cells'),
        _intArgument(message, 'filled-cells'),
      ),
    'grammar.cyk.step.completion-accepted-bullet'
        when _matchesArguments(message, const {}) =>
      cykStepCompletionAcceptedBullet,
    'grammar.cyk.step.completion-rejected-bullet'
        when _matchesArguments(message, const {}) =>
      cykStepCompletionRejectedBullet,
    _ when message.namespace == 'pumping' => resolvePumpingLemmaMessage(
      message,
    ),
    _ => structuredMessageUnknown(message.stableCode),
  };
}

typedef _ArgumentContract = ({
  StructuredMessageArgumentKind kind,
  String? role,
});

bool _matchesArguments(
  StructuredMessage message,
  Map<String, _ArgumentContract> expected,
) {
  if (message.arguments.length != expected.length) return false;
  for (final entry in expected.entries) {
    final argument = message.arguments[entry.key];
    if (argument == null ||
        argument.kind != entry.value.kind ||
        argument.role != entry.value.role) {
      return false;
    }
  }
  return true;
}

bool _codecTransitionEndpointsContract(StructuredMessage message) {
  if (message.arguments.length > 2) return false;
  for (final entry in message.arguments.entries) {
    final expectedRole = switch (entry.key) {
      'from' => 'source-state',
      'to' => 'target-state',
      _ => null,
    };
    if (expectedRole == null ||
        entry.value.kind != StructuredMessageArgumentKind.identifier ||
        entry.value.role != expectedRole) {
      return false;
    }
  }
  return true;
}

String _optionalStringArgument(StructuredMessage message, String key) =>
    switch (message.arguments[key]?.value) {
      final String value => value,
      _ => '',
    };

bool _grammarLl1ConflictContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'kind': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'll1-conflict-kind',
      ),
      'non-terminal': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-nonterminal',
      ),
      'lookahead': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-lookahead',
      ),
      'alternatives': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'grammar-productions',
      ),
    }) &&
    const {
      'first-first',
      'first-follow',
    }.contains(_stringArgument(message, 'kind'));

bool _grammarStructuralStartSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-start-symbol',
      ),
    });

bool _grammarStructuralProductionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'production': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'production-id',
      ),
    });

bool _grammarStructuralProductionLeftSideContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'production': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'production-id',
      ),
      'left-side': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'grammar-symbol-list',
      ),
    });

bool _grammarStructuralProductionLeftSideSymbolContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'production': (
    kind: StructuredMessageArgumentKind.identifier,
    role: 'production-id',
  ),
  'symbol': (
    kind: StructuredMessageArgumentKind.symbol,
    role: 'grammar-nonterminal',
  ),
});

bool _grammarStructuralProductionUnknownSymbolContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'production': (
    kind: StructuredMessageArgumentKind.identifier,
    role: 'production-id',
  ),
  'symbol': (kind: StructuredMessageArgumentKind.symbol, role: null),
});

bool _grammarStructuralSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'symbol': (kind: StructuredMessageArgumentKind.symbol, role: null),
    });

bool _grammarStructuralSummaryContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'count': (
        kind: StructuredMessageArgumentKind.count,
        role: 'diagnostic-count',
      ),
      'symbols': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'grammar-symbol-list',
      ),
    });

bool _grammarStructuralSymbolsSummaryContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'symbols': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'grammar-symbol-list',
      ),
    });

bool _grammarCnfGrammarTypeContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'type': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'grammar-type',
      ),
    }) &&
    const {
      'regular',
      'contextFree',
      'contextSensitive',
      'unrestricted',
    }.contains(_stringArgument(message, 'type'));

String _grammarCnfGrammarTypeLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      'regular' => l10n.grammarCnfTypeRegular,
      'contextFree' => l10n.grammarCnfTypeContextFree,
      'contextSensitive' => l10n.grammarCnfTypeContextSensitive,
      'unrestricted' => l10n.grammarCnfTypeUnrestricted,
      _ => value,
    };

bool _grammarCnfViolationsContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'violations': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'grammar-violation-list',
      ),
    });

bool _grammarCnfNullableSubsetContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'production': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'production-id',
      ),
      'nullable-positions': (
        kind: StructuredMessageArgumentKind.count,
        role: 'nullable-position-count',
      ),
      'subsets': (
        kind: StructuredMessageArgumentKind.count,
        role: 'nullable-subset-count',
      ),
      'limit': (
        kind: StructuredMessageArgumentKind.bound,
        role: 'nullable-subset-limit',
      ),
    });

bool _grammarCnfNewSymbolLimitContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'limit': (
        kind: StructuredMessageArgumentKind.bound,
        role: 'new-symbol-limit',
      ),
    });

bool _grammarToPdaSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'start-symbol',
      ),
    });

bool _grammarToPdaProductionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'production': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'production-id',
      ),
    });

bool _grammarToPdaTimeoutContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'timeout': (
        kind: StructuredMessageArgumentKind.durationMilliseconds,
        role: 'timeout',
      ),
    });

bool _tmToGrammarInvalidMachineContract(StructuredMessage message) =>
    message.arguments.isEmpty ||
    _matchesArguments(message, const {
      'detail': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'error-detail',
      ),
    });

bool _tmToGrammarMultiTapeContract(StructuredMessage message) =>
    message.arguments.isEmpty ||
    _matchesArguments(message, const {
      'tapes': (kind: StructuredMessageArgumentKind.count, role: 'tape-count'),
    });

bool _tmToGrammarBuildingBlocksContract(StructuredMessage message) =>
    message.arguments.isEmpty ||
    _matchesArguments(message, const {
      'blocks': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'building-block-ids',
      ),
    });

bool _tmToGrammarSymbolContract(
  StructuredMessage message, {
  required String role,
}) =>
    message.arguments.isEmpty ||
    _matchesArguments(message, {
      'symbol': (kind: StructuredMessageArgumentKind.symbol, role: role),
    });

bool _tmToGrammarConstructionLimitContract(StructuredMessage message) {
  if (message.arguments.isEmpty) return true;
  return _matchesArguments(message, const {
        'limit': (
          kind: StructuredMessageArgumentKind.bound,
          role: 'production-limit',
        ),
      }) ||
      _matchesArguments(message, const {
        'detail': (
          kind: StructuredMessageArgumentKind.literal,
          role: 'error-detail',
        ),
      });
}

bool _tmToGrammarOutputInvalidContract(StructuredMessage message) =>
    message.arguments.isEmpty ||
    _matchesArguments(message, const {
      'detail': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'error-detail',
      ),
    });

bool _tmToGrammarStateContract(StructuredMessage message) =>
    message.arguments.isEmpty ||
    _matchesArguments(message, const {
      'state': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'state-id',
      ),
    });

bool _grammarToFsaProductionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'production': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'production-id',
      ),
    });

bool _grammarToFsaProductionSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'production': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'production-id',
      ),
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'nonterminal',
      ),
    });

bool _dfaOperationsContextContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'context': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'dfa-context',
      ),
    }) &&
    const {
      'dfa',
      'complement',
      'prefix-closure',
      'suffix-closure',
      'operand-a',
      'operand-b',
    }.contains(_stringArgument(message, 'context'));

bool _dfaOperationsContextSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'context': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'dfa-context',
      ),
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'input-symbol',
      ),
    }) &&
    const {
      'dfa',
      'complement',
      'prefix-closure',
      'suffix-closure',
      'operand-a',
      'operand-b',
    }.contains(_stringArgument(message, 'context'));

bool _dfaOperationsOperandContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'operand': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'dfa-operand',
      ),
    }) &&
    const {'a', 'b'}.contains(_stringArgument(message, 'operand'));

bool _dfaOperationsOperationContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'operation': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'dfa-operation',
      ),
    }) &&
    const {
      'union',
      'intersection',
      'difference',
      'complement',
      'prefix-closure',
      'suffix-closure',
      'remove-lambda',
      'unknown',
    }.contains(_stringArgument(message, 'operation'));

String _dfaContextSelectValue(String value) => switch (value) {
  'complement' => 'complementDfa',
  'prefix-closure' => 'prefixClosure',
  'suffix-closure' => 'suffixClosure',
  'operand-a' => 'operandA',
  'operand-b' => 'operandB',
  _ => value,
};

String _dfaOperationSelectValue(String value) => switch (value) {
  'prefix-closure' => 'prefixClosure',
  'suffix-closure' => 'suffixClosure',
  'remove-lambda' => 'removeLambda',
  _ => value,
};

bool _grammarParserInputContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'input': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'input-string',
      ),
    });

bool _grammarParserStrategyContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'strategy': (
        kind: StructuredMessageArgumentKind.strategy,
        role: 'parser-strategy',
      ),
    }) &&
    const {
      'auto',
      'bruteForce',
      'cyk',
      'll',
      'lr',
    }.contains(_stringArgument(message, 'strategy'));

bool _grammarParserLimitContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'limit': (
        kind: StructuredMessageArgumentKind.bound,
        role: 'parser-step-limit',
      ),
    });

bool _grammarParserTimeoutContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'timeout': (
        kind: StructuredMessageArgumentKind.durationMilliseconds,
        role: 'parser-timeout',
      ),
    });

bool _grammarParserLl1ConflictContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'non-terminal': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-nonterminal',
      ),
      'lookahead': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-lookahead',
      ),
      'alternatives': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'grammar-productions',
      ),
    });

bool _grammarParserTrailingInputContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'lookahead': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'input-symbol',
      ),
      'position': (
        kind: StructuredMessageArgumentKind.positionIndex,
        role: 'input-position',
      ),
    });

bool _grammarParserExpectedSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'expected': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'expected-symbol',
      ),
    });

bool _grammarParserTerminalMismatchContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'expected': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'expected-symbol',
      ),
      'found': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'found-symbol',
      ),
      'position': (
        kind: StructuredMessageArgumentKind.positionIndex,
        role: 'input-position',
      ),
    });

bool _grammarParserEmptyTableCellContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'non-terminal': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-nonterminal',
      ),
      'lookahead': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-lookahead',
      ),
      'expected': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'expected-symbol-list',
      ),
    });

bool _lr1ProductionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'production': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'production-id',
      ),
    });

bool _lr1ProductionSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'production': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'production-id',
      ),
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-symbol',
      ),
    });

bool _lr1TimeoutContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'timeout': (
        kind: StructuredMessageArgumentKind.durationMilliseconds,
        role: 'parser-timeout',
      ),
    });

bool _lr1LimitContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'limit': (
        kind: StructuredMessageArgumentKind.bound,
        role: 'parser-step-limit',
      ),
    });

bool _lr1StateLookaheadContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'state': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'parser-state-id',
      ),
      'lookahead': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-lookahead',
      ),
    });

bool _lr1GotoContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'state': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'parser-state-id',
      ),
      'non-terminal': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'grammar-nonterminal',
      ),
    });

bool _tmSymbolContract(StructuredMessage message, {required String role}) =>
    _matchesArguments(message, {
      'symbol': (kind: StructuredMessageArgumentKind.symbol, role: role),
    });

bool _tmConflictContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'count': (
    kind: StructuredMessageArgumentKind.count,
    role: 'transition-count',
  ),
  'state': (kind: StructuredMessageArgumentKind.identifier, role: 'state-id'),
  'symbol': (kind: StructuredMessageArgumentKind.symbol, role: 'tape-symbol'),
});

bool _tmErrorContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'error': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'error-detail',
      ),
    });

bool _tmDetailContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'detail': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'error-detail',
      ),
    });

bool _tmReadSymbolContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'symbol': (kind: StructuredMessageArgumentKind.symbol, role: 'tape-symbol'),
  'position': (
    kind: StructuredMessageArgumentKind.positionIndex,
    role: 'tape-position',
  ),
  'state': (kind: StructuredMessageArgumentKind.identifier, role: 'state-id'),
});

bool _tmAppliedRuleContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'from-state': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'state-id',
      ),
      'read-symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'tape-symbol',
      ),
      'to-state': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'state-id',
      ),
      'write-symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'tape-symbol',
      ),
      'direction': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'tape-direction',
      ),
    });

bool _tmWroteSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'tape-symbol',
      ),
      'position': (
        kind: StructuredMessageArgumentKind.positionIndex,
        role: 'tape-position',
      ),
    });

bool _tmMovedHeadContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'direction': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'tape-direction',
      ),
      'position': (
        kind: StructuredMessageArgumentKind.positionIndex,
        role: 'tape-position',
      ),
    });

bool _tmPolicyContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'policy': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'acceptance-policy',
      ),
    }) &&
    const {
      'finalState',
      'halting',
      'finalStateOrHalting',
    }.contains(_stringArgument(message, 'policy'));

bool _tmTransitionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'transition': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'transition-id',
      ),
    });

bool _tmInputSymbolOutsideAlphabetContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'input': (kind: StructuredMessageArgumentKind.literal, role: 'input-word'),
  'symbol': (kind: StructuredMessageArgumentKind.symbol, role: 'input-symbol'),
});

bool _pdaNormalizationStackSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'stack-symbol',
      ),
    });

bool _pdaNormalizationTransitionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'transition': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'transition-id',
      ),
    });

bool _pdaNormalizationTransitionStackSymbolContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'transition': (
    kind: StructuredMessageArgumentKind.identifier,
    role: 'transition-id',
  ),
  'symbol': (kind: StructuredMessageArgumentKind.symbol, role: 'stack-symbol'),
});

bool _pdaNormalizationGrowthContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'states': (
        kind: StructuredMessageArgumentKind.count,
        role: 'generated-state-count',
      ),
      'transitions': (
        kind: StructuredMessageArgumentKind.count,
        role: 'generated-transition-count',
      ),
    });

bool _pdaNormalizationStateContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'state': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'state-id',
      ),
    });

bool _pdaNormalizationAcceptEmptyContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'state': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'state-id',
      ),
      'mode': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'acceptance-mode',
      ),
    }) &&
    const {
      'final-state',
      'empty-stack',
      'both',
    }.contains(_stringArgument(message, 'mode'));

String _pdaNormalizationAcceptanceModeLabel(
  AppLocalizations l10n,
  String value,
) => switch (value) {
  'final-state' => l10n.pdaAcceptanceFinalState,
  'empty-stack' => l10n.pdaAcceptanceEmptyStack,
  'both' => l10n.pdaAcceptanceBoth,
  _ => value,
};

bool _pdaSimplificationAcceptanceModeContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'mode': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'acceptance-mode',
      ),
    }) &&
    const {
      'final-state',
      'empty-stack',
      'both',
    }.contains(_stringArgument(message, 'mode'));

bool _pdaSimplificationTransitionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'transition': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'transition-id',
      ),
    });

bool _pdaSimplificationTransitionInputContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'transition': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'transition-id',
      ),
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'input-symbol',
      ),
    });

bool _pdaSimplificationInputSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'input-symbol',
      ),
    });

bool _pdaSimplificationCountContract(StructuredMessage message, String role) =>
    _matchesArguments(message, {
      'count': (kind: StructuredMessageArgumentKind.count, role: role),
    });

bool _pdaSimplificationWordContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'word': (kind: StructuredMessageArgumentKind.literal, role: 'input-word'),
    });

bool _bruteForceLimitContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'limit': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'brute-force-limit',
      ),
    }) &&
    const {
      'max-depth',
      'max-frontier-size',
      'max-explored-nodes',
      'max-retained-states',
      'max-symbol-count',
      'result-cap',
      'time-limit',
      'operations-per-batch',
      'depth',
      'frontier',
      'exploredNodes',
      'retainedStates',
      'symbolCount',
      'time',
    }.contains(_stringArgument(message, 'limit'));

String _bruteForceLimitName(AppLocalizations l10n, String value) =>
    l10n.localizeWorkflowText(switch (value) {
      'max-depth' => 'Maximum depth',
      'max-frontier-size' => 'Maximum frontier size',
      'max-explored-nodes' => 'Maximum explored nodes',
      'max-retained-states' => 'Maximum retained states',
      'max-symbol-count' => 'Maximum symbol count',
      'result-cap' => 'Witness limit',
      'time-limit' => 'Time limit',
      'operations-per-batch' => 'Operations per batch',
      'depth' => 'depth',
      'frontier' => 'frontier',
      'exploredNodes' => 'explored nodes',
      'retainedStates' => 'retained states',
      'symbolCount' => 'symbol count',
      'time' => 'time',
      _ => value,
    });

String _grammarLl1ConflictKind(AppLocalizations l10n, String value) =>
    switch (value) {
      'first-first' => l10n.grammarLl1ConflictKindFirstFirst,
      'first-follow' => l10n.grammarLl1ConflictKindFirstFollow,
      _ => value,
    };

int _intArgument(StructuredMessage message, String key) =>
    message.arguments[key]!.value as int;

String _stringArgument(StructuredMessage message, String key) =>
    message.arguments[key]!.value as String;

String _coordinateArgument(StructuredMessage message, String key) {
  final value = message.arguments[key]!.value;
  if (value is Map) {
    return '(${value['x']}, ${value['y']})';
  }
  return value.toString();
}

num _numArgument(StructuredMessage message, String key) =>
    message.arguments[key]!.value as num;

const _regexSimplificationStepTypes = {
  'start',
  'analyze',
  'applyRule',
  'noRuleApplicable',
  'generateSamples',
  'completion',
};

const _regexSimplificationRules = {
  'emptyUnion',
  'emptyUnionLeft',
  'emptySetConcatenation',
  'emptySetConcatenationLeft',
  'emptyStringConcatenation',
  'emptyStringConcatenationLeft',
  'starIdempotence',
  'emptySetStar',
  'emptyStringStar',
  'unionIdempotence',
  'doubleStar',
  'plusToStar',
  'plusToStarAlt',
  'plusExpansion',
  'optionalExpansion',
  'optionalStarSimplification',
  'starConcatenationIdempotence',
  'unionStarDistribution',
  'redundantParentheses',
  'characterClassCreation',
};

bool _regexSimplificationStepTypeContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'type': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'simplification-step-type',
      ),
    }) &&
    _regexSimplificationStepTypes.contains(_stringArgument(message, 'type'));

bool _regexSimplificationRuleContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'rule': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'simplification-rule',
      ),
    }) &&
    _regexSimplificationRules.contains(_stringArgument(message, 'rule'));

String _regexSimplificationPosition(AppLocalizations l10n, int position) =>
    position < 0
    ? l10n.regexSimplificationPositionUnavailable
    : l10n.regexSimplificationPositionValue(position);

String _regexSimplificationLengthChange(AppLocalizations l10n, int delta) =>
    delta > 0
    ? l10n.regexSimplificationLengthReduced(delta)
    : delta < 0
    ? l10n.regexSimplificationLengthIncreased(-delta)
    : l10n.regexSimplificationLengthUnchanged;

const _regexToNfaStepTypes = {
  'start',
  'basicSymbol',
  'concatenation',
  'union',
  'kleeneStar',
  'plus',
  'optional',
  'complete',
};

bool _regexToNfaStepTypeContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'type': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'regex-to-nfa-step-type',
      ),
    }) &&
    _regexToNfaStepTypes.contains(_stringArgument(message, 'type'));

bool _regexToNfaBasicSymbolContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'symbol': (kind: StructuredMessageArgumentKind.literal, role: 'regex-symbol'),
  'position': (
    kind: StructuredMessageArgumentKind.integer,
    role: 'regex-position',
  ),
  'start-state': (
    kind: StructuredMessageArgumentKind.literal,
    role: 'state-label',
  ),
  'accept-state': (
    kind: StructuredMessageArgumentKind.literal,
    role: 'state-label',
  ),
  'state-count': (kind: StructuredMessageArgumentKind.count, role: null),
  'transition-count': (kind: StructuredMessageArgumentKind.count, role: null),
  'transitions': (
    kind: StructuredMessageArgumentKind.literal,
    role: 'nfa-transitions',
  ),
  'stack-size': (kind: StructuredMessageArgumentKind.count, role: null),
});

bool _regexToNfaConcatenationContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'position': (
        kind: StructuredMessageArgumentKind.integer,
        role: 'regex-position',
      ),
      'first-fragment': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'regex-fragment',
      ),
      'second-fragment': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'regex-fragment',
      ),
      'start-state': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-label',
      ),
      'accept-states': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-labels',
      ),
      'transitions': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'nfa-transitions',
      ),
      'stack-size': (kind: StructuredMessageArgumentKind.count, role: null),
    });

bool _regexToNfaUnionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'position': (
        kind: StructuredMessageArgumentKind.integer,
        role: 'regex-position',
      ),
      'pattern': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'regex-fragment',
      ),
      'start-state': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-label',
      ),
      'accept-state': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-label',
      ),
      'transitions': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'nfa-transitions',
      ),
      'stack-size': (kind: StructuredMessageArgumentKind.count, role: null),
    });

bool _regexToNfaUnaryContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'fragment': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'regex-fragment',
      ),
      'position': (
        kind: StructuredMessageArgumentKind.integer,
        role: 'regex-position',
      ),
      'start-state': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-label',
      ),
      'accept-state': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-label',
      ),
      'transitions': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'nfa-transitions',
      ),
      'stack-size': (kind: StructuredMessageArgumentKind.count, role: null),
    });

bool _regexToNfaCompleteContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'start-state': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-label',
      ),
      'accept-state': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-label',
      ),
      'state-count': (kind: StructuredMessageArgumentKind.count, role: null),
      'transition-count': (
        kind: StructuredMessageArgumentKind.count,
        role: null,
      ),
    });

String _regexToNfaPosition(AppLocalizations l10n, int position) => position < 0
    ? l10n.regexToNfaPositionUnavailable
    : l10n.regexToNfaPositionValue(position);

bool _faToRegexStepContract(
  StructuredMessage message,
) => switch (message.code) {
  'title' =>
    _matchesArguments(message, const {
          'type': (
            kind: StructuredMessageArgumentKind.outcome,
            role: 'fa-to-regex-step-type',
          ),
          'state': (
            kind: StructuredMessageArgumentKind.literal,
            role: 'state-label',
          ),
        }) &&
        _faToRegexStepTypes.contains(_stringArgument(message, 'type')),
  'validation-explanation' => _matchesArguments(message, const {
    'state-count': (kind: StructuredMessageArgumentKind.count, role: null),
    'transition-count': (kind: StructuredMessageArgumentKind.count, role: null),
    'has-initial-state': (
      kind: StructuredMessageArgumentKind.boolean,
      role: 'automaton-validation',
    ),
    'has-accepting-states': (
      kind: StructuredMessageArgumentKind.boolean,
      role: 'automaton-validation',
    ),
  }),
  'add-initial-state-explanation' => _matchesArguments(message, const {
    'new-state': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-label',
    ),
    'old-state': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-label',
    ),
  }),
  'add-final-state-explanation' => _matchesArguments(message, const {
    'new-state': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-label',
    ),
    'old-states': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-labels',
    ),
  }),
  'select-state-explanation' ||
  'complete-elimination-explanation' => _matchesArguments(message, const {
    'state': (kind: StructuredMessageArgumentKind.literal, role: 'state-label'),
    'remaining-state-count': (
      kind: StructuredMessageArgumentKind.count,
      role: null,
    ),
  }),
  'find-incoming-explanation' ||
  'find-outgoing-explanation' => _matchesArguments(message, const {
    'state': (kind: StructuredMessageArgumentKind.literal, role: 'state-label'),
    'transition-count': (kind: StructuredMessageArgumentKind.count, role: null),
    'states': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-labels',
    ),
  }),
  'find-self-loop-explanation' => _matchesArguments(message, const {
    'state': (kind: StructuredMessageArgumentKind.literal, role: 'state-label'),
    'has-loop': (
      kind: StructuredMessageArgumentKind.boolean,
      role: 'self-loop-presence',
    ),
    'self-loop-regex': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'regular-expression',
    ),
  }),
  'create-bypass-explanation' => _matchesArguments(message, const {
    'state': (kind: StructuredMessageArgumentKind.literal, role: 'state-label'),
    'transition-count': (kind: StructuredMessageArgumentKind.count, role: null),
    'path-regex': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'regular-expression',
    ),
  }),
  'combine-transitions-explanation' => _matchesArguments(message, const {
    'from-state': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-label',
    ),
    'to-state': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-label',
    ),
    'regex-count': (kind: StructuredMessageArgumentKind.count, role: null),
    'regexes': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'regular-expressions',
    ),
    'resulting-regex': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'regular-expression',
    ),
  }),
  'extract-regex-explanation' => _matchesArguments(message, const {
    'initial-state': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-label',
    ),
    'final-state': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'state-label',
    ),
    'regex': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'regular-expression',
    ),
  }),
  'completion-explanation' => _matchesArguments(message, const {
    'original-state-count': (
      kind: StructuredMessageArgumentKind.count,
      role: null,
    ),
    'regex': (
      kind: StructuredMessageArgumentKind.literal,
      role: 'regular-expression',
    ),
    'step-count': (kind: StructuredMessageArgumentKind.count, role: null),
  }),
  'elimination-summary' => _matchesArguments(message, const {
    'has-state': (
      kind: StructuredMessageArgumentKind.boolean,
      role: 'state-elimination-presence',
    ),
    'state': (kind: StructuredMessageArgumentKind.literal, role: 'state-label'),
    'incoming-state-count': (
      kind: StructuredMessageArgumentKind.count,
      role: null,
    ),
    'outgoing-state-count': (
      kind: StructuredMessageArgumentKind.count,
      role: null,
    ),
    'has-self-loop': (
      kind: StructuredMessageArgumentKind.boolean,
      role: 'self-loop-presence',
    ),
  }),
  _ => false,
};

bool _faToRegexStepTypeContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'type': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'fa-to-regex-step-type',
      ),
    }) &&
    _faToRegexStepTypes.contains(_stringArgument(message, 'type'));

String _resolveFaToRegexStep(
  AppLocalizations l10n,
  StructuredMessage message,
) => switch (message.code) {
  'title' => l10n.faToRegexStepTitle(
    _stringArgument(message, 'type'),
    _stringArgument(message, 'state'),
  ),
  'validation-explanation' => l10n.faToRegexValidationExplanation(
    _intArgument(message, 'state-count'),
    _intArgument(message, 'transition-count'),
    _boolArgument(message, 'has-initial-state').toString(),
    _boolArgument(message, 'has-accepting-states').toString(),
  ),
  'add-initial-state-explanation' => l10n.faToRegexAddInitialStateExplanation(
    _stringArgument(message, 'new-state'),
    _stringArgument(message, 'old-state'),
  ),
  'add-final-state-explanation' => l10n.faToRegexAddFinalStateExplanation(
    _stringArgument(message, 'new-state'),
    _stringArgument(message, 'old-states'),
  ),
  'select-state-explanation' => l10n.faToRegexSelectStateExplanation(
    _stringArgument(message, 'state'),
    _intArgument(message, 'remaining-state-count'),
  ),
  'find-incoming-explanation' => l10n.faToRegexFindIncomingExplanation(
    _stringArgument(message, 'state'),
    _intArgument(message, 'transition-count'),
    _stringArgument(message, 'states'),
  ),
  'find-outgoing-explanation' => l10n.faToRegexFindOutgoingExplanation(
    _stringArgument(message, 'state'),
    _intArgument(message, 'transition-count'),
    _stringArgument(message, 'states'),
  ),
  'find-self-loop-explanation' => l10n.faToRegexFindSelfLoopExplanation(
    _boolArgument(message, 'has-loop').toString(),
    _stringArgument(message, 'state'),
    _stringArgument(message, 'self-loop-regex'),
  ),
  'create-bypass-explanation' => l10n.faToRegexCreateBypassExplanation(
    _intArgument(message, 'transition-count'),
    _stringArgument(message, 'state'),
    _stringArgument(message, 'path-regex'),
  ),
  'combine-transitions-explanation' =>
    l10n.faToRegexCombineTransitionsExplanation(
      _intArgument(message, 'regex-count'),
      _stringArgument(message, 'from-state'),
      _stringArgument(message, 'to-state'),
      _stringArgument(message, 'regexes'),
      _stringArgument(message, 'resulting-regex'),
    ),
  'complete-elimination-explanation' =>
    l10n.faToRegexCompleteEliminationExplanation(
      _stringArgument(message, 'state'),
      _intArgument(message, 'remaining-state-count'),
    ),
  'extract-regex-explanation' => l10n.faToRegexExtractRegexExplanation(
    _stringArgument(message, 'initial-state'),
    _stringArgument(message, 'final-state'),
    _stringArgument(message, 'regex'),
  ),
  'completion-explanation' => l10n.faToRegexCompletionExplanation(
    _intArgument(message, 'original-state-count'),
    _stringArgument(message, 'regex'),
    _intArgument(message, 'step-count'),
  ),
  'elimination-summary' => l10n.faToRegexEliminationSummary(
    _boolArgument(message, 'has-state').toString(),
    _stringArgument(message, 'state'),
    _intArgument(message, 'incoming-state-count'),
    _intArgument(message, 'outgoing-state-count'),
    _boolArgument(message, 'has-self-loop').toString(),
  ),
  _ => l10n.structuredMessageUnknown(message.stableCode),
};

const _faToRegexStepTypes = {
  'validation',
  'addInitialState',
  'addFinalState',
  'selectState',
  'findIncoming',
  'findOutgoing',
  'findSelfLoop',
  'createBypass',
  'combineTransitions',
  'completeElimination',
  'extractRegex',
  'completion',
};

bool _boolArgument(StructuredMessage message, String key) =>
    message.arguments[key]!.value as bool;

String _lSystemLimitKind(String value) => switch (value) {
  'estimatedMemory' => 'estimatedBytes',
  _ => value,
};

bool _languageComparisonValidationContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'automaton': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'automaton-side',
      ),
    }) &&
    switch (message.code) {
      'empty-state-set' ||
      'missing-initial-state' ||
      'initial-state-outside-set' =>
        _languageComparisonAutomatonSideValues.contains(
          _stringArgument(message, 'automaton'),
        ),
      _ => false,
    };

String _languageComparisonAutomatonSideLabel(
  AppLocalizations l10n,
  StructuredMessage message,
) {
  final label = switch (_stringArgument(message, 'automaton')) {
    'A' => l10n.automatonA,
    'B' => l10n.automatonB,
    _ => 'Automaton',
  };
  return l10n.localeName.startsWith('pt') ? _lowercaseFirst(label) : label;
}

String _lowercaseFirst(String value) =>
    value.isEmpty ? value : '${value[0].toLowerCase()}${value.substring(1)}';

const _languageComparisonAutomatonSideValues = {'A', 'B'};

bool _languageComparisonTraceAutomatonContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'automaton': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'automaton-side',
      ),
    }) &&
    _languageComparisonAutomatonSideValues.contains(
      _stringArgument(message, 'automaton'),
    );

bool _languageComparisonTraceStateContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'state': (
        kind: StructuredMessageArgumentKind.literal,
        role: 'state-label',
      ),
    });

bool _languageComparisonTraceSymbolContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'symbol': (
        kind: StructuredMessageArgumentKind.symbol,
        role: 'input-symbol',
      ),
    });

bool _languageComparisonTraceBooleanContract(
  StructuredMessage message,
  String key,
) => _matchesArguments(message, {
  key: (
    kind: StructuredMessageArgumentKind.boolean,
    role: key == 'different'
        ? 'acceptance-difference'
        : 'comparison-equivalence',
  ),
});

bool _languageComparisonTracePairContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'state-a': (kind: StructuredMessageArgumentKind.literal, role: 'state-label'),
  'state-b': (kind: StructuredMessageArgumentKind.literal, role: 'state-label'),
});

bool _languageComparisonTraceDistinguishingContract(
  StructuredMessage message,
) => _matchesArguments(message, const {
  'value': (
    kind: StructuredMessageArgumentKind.literal,
    role: 'distinguishing-string',
  ),
});

bool _languageComparisonTraceUnknownContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'type': (kind: StructuredMessageArgumentKind.literal, role: 'trace-type'),
    });

bool _fsaKleeneStarTransitionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'transition': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'transition-id',
      ),
    }) &&
    _stringArgument(message, 'transition').isNotEmpty;

bool _fsaReversalTransitionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'transition': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'transition-id',
      ),
    }) &&
    _stringArgument(message, 'transition').isNotEmpty;

const _fsaConcatenationOperandValues = {'left', 'right'};

bool _fsaConcatenationOperandContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'operand': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'fsa-operand',
      ),
    }) &&
    _fsaConcatenationOperandValues.contains(
      _stringArgument(message, 'operand'),
    );

bool _fsaConcatenationTransitionContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'operand': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'fsa-operand',
      ),
      'transition': (
        kind: StructuredMessageArgumentKind.identifier,
        role: 'transition-id',
      ),
    }) &&
    _fsaConcatenationOperandValues.contains(
      _stringArgument(message, 'operand'),
    ) &&
    _stringArgument(message, 'transition').isNotEmpty;

String _fsaConcatenationOperandLabel(
  AppLocalizations l10n,
  StructuredMessage message,
) => switch (_stringArgument(message, 'operand')) {
  'left' => l10n.fsaConcatenationLeftOperand,
  'right' => l10n.fsaConcatenationRightOperand,
  _ => l10n.fsaConcatenationLeftOperand,
};

bool _batchFieldContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'field': (
        kind: StructuredMessageArgumentKind.outcome,
        role: 'validation-field',
      ),
    });

bool _batchCaseContract(StructuredMessage message) =>
    _matchesArguments(message, const {
      'case': (kind: StructuredMessageArgumentKind.identifier, role: 'case'),
    });

String _batchField(AppLocalizations l10n, StructuredMessage message) =>
    l10n.localizeWorkflowText(switch (_stringArgument(message, 'field')) {
      'case-id' => 'Case ID',
      'explicit-input-tokens' => 'Explicit input tokens',
      'step-limit' => 'Step limit',
      'configuration-limit' => 'Configuration limit',
      'timeout' => 'Timeout',
      'retained-trace-limit' => 'Retained trace limit',
      'model-id' => 'Model ID',
      'model-revision' => 'Model revision',
      'strategy-id' => 'Strategy ID',
      'maximum-concurrency' => 'Maximum concurrency',
      'batch-size' => 'Batch size',
      'request-generation' => 'Request generation',
      final value => value,
    });

String _tmPolicy(AppLocalizations l10n, String value) =>
    l10n.localizeWorkflowText(switch (value) {
      'finalState' => 'Final state',
      'halting' => 'Halting',
      'finalStateOrHalting' => 'Final state or halting',
      _ => value,
    });

String _tmReason(AppLocalizations l10n, String value) =>
    l10n.localizeWorkflowText(switch (value) {
      'enteredFinalState' => 'entered a final state',
      'haltedInFinalState' => 'halted in a final state',
      'haltedOutsideFinalState' => 'halted outside a final state',
      'reachableConfigurationsExhausted' =>
        'reachable configurations were exhausted',
      'deterministicCycle' => 'an exact configuration repeated',
      'stepLimit' => 'the step limit was reached',
      'configurationLimit' => 'the configuration limit was reached',
      'timeout' => 'the timeout was reached',
      'cancelled' => 'the simulation was cancelled',
      'invalidMachine' => 'the machine is invalid',
      _ => value,
    });
