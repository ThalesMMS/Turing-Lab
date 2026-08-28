//
//  language_comparison_viewer.dart
//  Turing Lab
//
//  Widget for viewing language-equivalence comparison results between two
//  finite automata. Shows the comparison outcome, a distinguishing string
//  (counterexample), the two automata side by side or stacked, an optional
//  product automaton, and a navigable algorithm trace. A comparison that could
//  not decide is rendered as an explicit error or inconclusive surface with no
//  automaton at all, so a stopped run can never read as a verdict.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/monospace_typography.dart';
import '../../core/models/equivalence_comparison_result.dart';
import '../../core/models/fsa.dart';
import '../../core/models/language_comparison_outcome.dart';
import '../../features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/automata_diagnostics_localizations.dart';
import '../localization/locale_value_formatter.dart';
import 'language_comparison_semantics.dart';
import 'language_comparison_step_view_model.dart';
import 'read_only_fsa_graphview_canvas.dart';

/// Widget for visualizing language equivalence comparison results.
///
/// Displays the comparison outcome, the distinguishing string when the
/// languages differ, both automata, an optional product automaton, and a
/// navigable algorithm trace.
///
/// Exactly one of [comparisonResult] and [failure] must be supplied. Passing a
/// [failure] renders the explicit stopped-comparison surface: no automaton is
/// drawn and no verdict is derived, which is what keeps a failed
/// determinization or an exhausted budget from being presented as an
/// equivalence answer.
class LanguageComparisonViewer extends StatefulWidget {
  const LanguageComparisonViewer({
    super.key,
    required this.comparisonResult,
    this.failure,
    this.automatonATitle,
    this.automatonBTitle,
    this.showProductAutomaton = false,
    this.showSteps = false,
  }) : assert(
         (comparisonResult == null) != (failure == null),
         'Supply exactly one of comparisonResult or failure.',
       );

  /// Builds the decided or stopped surface from one typed controller outcome.
  factory LanguageComparisonViewer.fromOutcome({
    Key? key,
    required LanguageComparisonOutcome outcome,
    String? automatonATitle,
    String? automatonBTitle,
    bool showProductAutomaton = false,
    bool showSteps = false,
  }) {
    return switch (outcome) {
      LanguageComparisonCompleted(:final result) => LanguageComparisonViewer(
        key: key,
        comparisonResult: result,
        automatonATitle: automatonATitle,
        automatonBTitle: automatonBTitle,
        showProductAutomaton: showProductAutomaton,
        showSteps: showSteps,
      ),
      final LanguageComparisonFailure failure => LanguageComparisonViewer(
        key: key,
        comparisonResult: null,
        failure: failure,
        automatonATitle: automatonATitle,
        automatonBTitle: automatonBTitle,
        showProductAutomaton: showProductAutomaton,
        showSteps: showSteps,
      ),
    };
  }

  /// Renders the stopped-comparison surface for [failure].
  const LanguageComparisonViewer.unavailable({
    Key? key,
    required LanguageComparisonFailure failure,
  }) : this(key: key, comparisonResult: null, failure: failure);

  /// The comparison result to display, or null when [failure] is set.
  final EquivalenceComparisonResult? comparisonResult;

  /// Why the comparison could not decide, or null when it did.
  final LanguageComparisonFailure? failure;

  /// Optional title for the first automaton (defaults to "Automaton A")
  final String? automatonATitle;

  /// Optional title for the second automaton (defaults to "Automaton B")
  final String? automatonBTitle;

  /// Whether the product automaton section starts expanded
  final bool showProductAutomaton;

  /// Whether the algorithm trace section starts expanded
  final bool showSteps;

  @override
  State<LanguageComparisonViewer> createState() =>
      _LanguageComparisonViewerState();
}

class _LanguageComparisonViewerState extends State<LanguageComparisonViewer> {
  // Canvas identity is owned here rather than by the build method. The slot
  // keys keep each ReadOnlyFsaGraphViewCanvas - and therefore the private
  // controller and automaton notifier it creates and disposes - alive when the
  // layout moves a canvas between the side-by-side row and the stacked column,
  // so a resize does not reset the viewport. The canvas keys address the inner
  // GraphView surface.
  final GlobalKey _automatonASlotKey = GlobalKey(debugLabel: 'comparison-a');
  final GlobalKey _automatonBSlotKey = GlobalKey(debugLabel: 'comparison-b');
  final GlobalKey _automatonACanvasKey = GlobalKey();
  final GlobalKey _automatonBCanvasKey = GlobalKey();
  final GlobalKey _productCanvasKey = GlobalKey();

  bool _showProductAutomatonSection = false;
  bool _showStepsSection = false;
  int _selectedStepIndex = 0;

  List<Map<String, dynamic>> get _steps =>
      widget.comparisonResult?.steps ?? const [];

  @override
  void initState() {
    super.initState();
    _showProductAutomatonSection = widget.showProductAutomaton;
    _showStepsSection = widget.showSteps;
  }

  @override
  void didUpdateWidget(covariant LanguageComparisonViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new trace can be shorter than the one that was being browsed.
    final stepCount = _steps.length;
    if (_selectedStepIndex >= stepCount) {
      _selectedStepIndex = stepCount == 0 ? 0 : stepCount - 1;
    }
  }

  LanguageComparisonOutcome get _outcome {
    final failure = widget.failure;
    if (failure != null) {
      return failure;
    }
    return LanguageComparisonCompleted(widget.comparisonResult!);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = appLocalizationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _ComparisonLayoutMetrics.resolve(constraints);
        final content = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildSections(
              l10n: l10n,
              colorScheme: colorScheme,
              textTheme: textTheme,
              metrics: metrics,
            ),
          ),
        );

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(12),
          // The surface has to survive both hosts it is mounted in: a bounded
          // dialog box, where the content scrolls, and a scrolling parent that
          // hands it an unbounded height, where it must size to its content.
          child: constraints.hasBoundedHeight
              ? SingleChildScrollView(child: content)
              : content,
        );
      },
    );
  }

  List<Widget> _buildSections({
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required _ComparisonLayoutMetrics metrics,
  }) {
    final failure = widget.failure;
    if (failure != null) {
      return [
        _buildStatusHeader(l10n, colorScheme, textTheme),
        const SizedBox(height: 16),
        _buildFailureSection(failure, l10n, colorScheme, textTheme),
      ];
    }

    final result = widget.comparisonResult!;
    return [
      _buildStatusHeader(l10n, colorScheme, textTheme),
      const SizedBox(height: 16),
      if (!result.isEquivalent && result.distinguishingString != null) ...[
        _buildCounterexampleSection(result, l10n, colorScheme, textTheme),
        const SizedBox(height: 16),
      ],
      _buildStatistics(result, l10n, colorScheme, textTheme),
      const SizedBox(height: 16),
      _buildAutomataComparison(result, l10n, colorScheme, textTheme, metrics),
      if (result.productAutomaton != null) ...[
        const SizedBox(height: 16),
        _buildProductAutomatonSection(
          result.productAutomaton!,
          l10n,
          colorScheme,
          textTheme,
          metrics,
        ),
      ],
      if (result.steps.isNotEmpty) ...[
        const SizedBox(height: 16),
        _buildStepsSection(l10n, colorScheme, textTheme),
      ],
    ];
  }

  Widget _buildStatusHeader(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final outcome = _outcome;
    final status = outcome.status;
    final badgeColor = switch (status) {
      LanguageComparisonStatus.equivalent => colorScheme.primary,
      LanguageComparisonStatus.notEquivalent => colorScheme.error,
      LanguageComparisonStatus.inconclusive => colorScheme.tertiary,
      LanguageComparisonStatus.error => colorScheme.error,
    };
    final badgeIcon = switch (status) {
      LanguageComparisonStatus.equivalent => Icons.check_circle,
      LanguageComparisonStatus.notEquivalent => Icons.cancel,
      LanguageComparisonStatus.inconclusive => Icons.help_outline,
      LanguageComparisonStatus.error => Icons.error_outline,
    };
    final badgeText = _statusText(l10n, status);
    final executionTimeMs = widget.comparisonResult?.executionTimeMs;
    final formatter = LocaleValueFormatter.of(context);

    return Semantics(
      identifier: LanguageComparisonSemantics.status,
      label: l10n.languageComparisonStatusSemantic(badgeText),
      container: true,
      explicitChildNodes: true,
      child: Container(
        key: LanguageComparisonSemantics.statusKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, color: badgeColor, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    badgeText,
                    style: textTheme.titleLarge?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (executionTimeMs != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: colorScheme.onSurface,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${formatter.integer(executionTimeMs)}ms',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _statusText(AppLocalizations l10n, LanguageComparisonStatus status) {
    return l10n.languageComparisonStatus(status);
  }

  Widget _buildFailureSection(
    LanguageComparisonFailure failure,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final reasonText = _failureReasonText(l10n, failure.reason);
    final explanation = l10n.languageComparisonFailureExplanation(
      failure.reason,
    );
    final structuredDetail = failure.structuredMessage == null
        ? null
        : l10n.resolveStructuredMessage(failure.structuredMessage!);
    final accent = failure.reason.isInconclusive
        ? colorScheme.tertiary
        : colorScheme.error;

    return Semantics(
      identifier: LanguageComparisonSemantics.error,
      label: l10n.languageComparisonFailureSemantic(reasonText, explanation),
      container: true,
      explicitChildNodes: true,
      child: Container(
        key: LanguageComparisonSemantics.failureKey(failure.reason),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.report_problem_outlined, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reasonText,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              explanation,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (structuredDetail != null &&
                structuredDetail != explanation) ...[
              const SizedBox(height: 8),
              Text(
                structuredDetail,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _failureReasonText(
    AppLocalizations l10n,
    LanguageComparisonFailureReason reason,
  ) {
    return l10n.languageComparisonFailureReason(reason);
  }

  Widget _buildCounterexampleSection(
    EquivalenceComparisonResult result,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final distinguishingString = result.distinguishingString!;
    final displayString = distinguishingString.isEmpty
        ? l10n.emptyStringEpsilon
        : '"$distinguishingString"';

    return Semantics(
      identifier: LanguageComparisonSemantics.witness,
      label: l10n.languageComparisonWitnessSemantic(displayString),
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.distinguishingStringFound,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.text_fields, color: colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayString,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: kMonospaceFontFamilyFallback,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.distinguishingStringExplanation,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(
    EquivalenceComparisonResult result,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final automatonA = result.originalAutomaton;
    final automatonB = result.comparedAutomaton;
    final formatter = LocaleValueFormatter.of(context);
    final entries = <(String, int)>[
      (l10n.statesA, automatonA.states.length),
      (l10n.statesB, automatonB.states.length),
      (l10n.transitionsA, automatonA.transitions.length),
      (l10n.transitionsB, automatonB.transitions.length),
    ];

    return Semantics(
      identifier: LanguageComparisonSemantics.statistics,
      label: _localizedStatisticsSemantic(
        l10n,
        formatter,
        statesA: automatonA.states.length,
        statesB: automatonB.states.length,
        transitionsA: automatonA.transitions.length,
        transitionsB: automatonB.transitions.length,
      ),
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        // A Wrap instead of a Row: four stat columns plus their separators do
        // not fit a narrow phone, and at large text scales they do not fit a
        // tablet either.
        child: Wrap(
          alignment: WrapAlignment.spaceAround,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final entry in entries)
              _buildStatItem(
                label: entry.$1,
                value: entry.$2,
                formatter: formatter,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    required LocaleValueFormatter formatter,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.integer(value),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAutomataComparison(
    EquivalenceComparisonResult result,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    _ComparisonLayoutMetrics metrics,
  ) {
    final sectionA = KeyedSubtree(
      key: _automatonASlotKey,
      child: _buildAutomatonSection(
        l10n: l10n,
        automaton: result.originalAutomaton,
        title: widget.automatonATitle ?? l10n.automatonA,
        semanticsIdentifier: LanguageComparisonSemantics.canvasA,
        canvasKey: _automatonACanvasKey,
        canvasHeight: metrics.canvasHeight,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
    );
    final sectionB = KeyedSubtree(
      key: _automatonBSlotKey,
      child: _buildAutomatonSection(
        l10n: l10n,
        automaton: result.comparedAutomaton,
        title: widget.automatonBTitle ?? l10n.automatonB,
        semanticsIdentifier: LanguageComparisonSemantics.canvasB,
        canvasKey: _automatonBCanvasKey,
        canvasHeight: metrics.canvasHeight,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
    );

    if (metrics.isStacked) {
      return Column(
        key: LanguageComparisonSemantics.layoutKey(isStacked: true),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [sectionA, const SizedBox(height: 16), sectionB],
      );
    }

    return Row(
      key: LanguageComparisonSemantics.layoutKey(isStacked: false),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: sectionA),
        const SizedBox(width: 16),
        Expanded(child: sectionB),
      ],
    );
  }

  Widget _buildAutomatonSection({
    required FSA automaton,
    required AppLocalizations l10n,
    required String title,
    required String semanticsIdentifier,
    required GlobalKey canvasKey,
    required double canvasHeight,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_tree, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Semantics(
          identifier: semanticsIdentifier,
          label: _canvasDescription(l10n, title, automaton),
          container: true,
          explicitChildNodes: true,
          child: SizedBox(
            height: canvasHeight,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                child: ReadOnlyFsaGraphViewCanvas(
                  automaton: automaton,
                  canvasKey: canvasKey,
                  edgeRenderMode: TuringLabEdgeRenderMode.groupedFsa,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _canvasDescription(
    AppLocalizations l10n,
    String title,
    FSA automaton,
  ) {
    return l10n.languageComparisonCanvasSemantic(
      title,
      automaton.states.length,
      automaton.transitions.length,
    );
  }

  Widget _buildProductAutomatonSection(
    FSA productAutomaton,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
    _ComparisonLayoutMetrics metrics,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionToggle(
          expanded: _showProductAutomatonSection,
          onToggle: () => setState(() {
            _showProductAutomatonSection = !_showProductAutomatonSection;
          }),
          icon: Icons.grid_on,
          iconColor: colorScheme.tertiary,
          title: l10n.productAutomaton,
          badgeText: l10n.optional,
          badgeColor: colorScheme.tertiary,
          backgroundColor: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        if (_showProductAutomatonSection) ...[
          const SizedBox(height: 8),
          Semantics(
            identifier: LanguageComparisonSemantics.productCanvas,
            label: _canvasDescription(
              l10n,
              l10n.productAutomaton,
              productAutomaton,
            ),
            container: true,
            explicitChildNodes: true,
            child: SizedBox(
              height: metrics.canvasHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ReadOnlyFsaGraphViewCanvas(
                    automaton: productAutomaton,
                    canvasKey: _productCanvasKey,
                    edgeRenderMode: TuringLabEdgeRenderMode.groupedFsa,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepsSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final steps = _steps;
    final formatter = LocaleValueFormatter.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionToggle(
          expanded: _showStepsSection,
          onToggle: () => setState(() {
            _showStepsSection = !_showStepsSection;
          }),
          icon: Icons.list_alt,
          iconColor: colorScheme.primary,
          title: l10n.algorithmSteps,
          badgeText: formatter.inLocalizedTemplate(
            l10n.stepsCount,
            steps.length,
          ),
          badgeColor: colorScheme.primary,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        if (_showStepsSection) ...[
          const SizedBox(height: 8),
          _buildStepNavigation(steps.length, l10n, colorScheme, textTheme),
          const SizedBox(height: 8),
          _buildStepCard(
            LanguageComparisonStepViewModel.fromPayload(
              steps[_selectedStepIndex],
              fallbackStepNumber: _selectedStepIndex + 1,
            ),
            l10n,
            colorScheme,
            textTheme,
          ),
        ],
      ],
    );
  }

  Widget _buildStepNavigation(
    int stepCount,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final position = l10n.stepOf(_selectedStepIndex + 1, stepCount);
    final canGoBack = _selectedStepIndex > 0;
    final canGoForward = _selectedStepIndex < stepCount - 1;

    return Semantics(
      identifier: LanguageComparisonSemantics.stepNavigation,
      label: position,
      container: true,
      explicitChildNodes: true,
      child: Row(
        children: [
          Semantics(
            identifier: LanguageComparisonSemantics.previousStep,
            container: true,
            child: IconButton(
              key: const ValueKey<String>(
                LanguageComparisonSemantics.previousStep,
              ),
              icon: const Icon(Icons.chevron_left),
              tooltip: l10n.previousStepLower,
              onPressed: canGoBack
                  ? () => setState(() => _selectedStepIndex -= 1)
                  : null,
            ),
          ),
          Expanded(
            child: Text(
              position,
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Semantics(
            identifier: LanguageComparisonSemantics.nextStep,
            container: true,
            child: IconButton(
              key: const ValueKey<String>(LanguageComparisonSemantics.nextStep),
              icon: const Icon(Icons.chevron_right),
              tooltip: l10n.nextStepLower,
              onPressed: canGoForward
                  ? () => setState(() => _selectedStepIndex += 1)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionToggle({
    required bool expanded,
    required VoidCallback onToggle,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color backgroundColor,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              expanded ? Icons.expand_more : Icons.chevron_right,
              color: colorScheme.onSurface,
              size: 20,
            ),
            const SizedBox(width: 8),
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    LanguageComparisonStepViewModel step,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final accentColor = step.accentColor(colorScheme);
    final formatter = LocaleValueFormatter.of(context);
    final localizedStep = l10n.localizeLanguageComparisonStep(step);
    final title = localizedStep.title;
    final description = localizedStep.description;

    return Semantics(
      identifier: LanguageComparisonSemantics.selectedStep,
      label: formatter.inLocalizedTemplate(
        (value) => l10n.languageComparisonStepSemantic(value, title),
        step.stepNumber,
      ),
      container: true,
      explicitChildNodes: true,
      child: Card(
        key: LanguageComparisonSemantics.stepKey(_selectedStepIndex),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor,
                child: Text(
                  formatter.integer(step.stepNumber),
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(step.icon, color: accentColor, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(description, style: textTheme.bodySmall),
                    ],
                    if (localizedStep.details.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final detail in localizedStep.details)
                            _buildStepDetailChip(
                              detail,
                              l10n,
                              colorScheme,
                              textTheme,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDetailChip(
    LanguageComparisonStepDetail detail,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            detail.label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail.value,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedStatisticsSemantic(
  AppLocalizations l10n,
  LocaleValueFormatter formatter, {
  required int statesA,
  required int statesB,
  required int transitionsA,
  required int transitionsB,
}) {
  var text = l10n.languageComparisonStatisticsSemantic(
    statesA,
    statesB,
    transitionsA,
    transitionsB,
  );
  for (final value in [statesA, statesB, transitionsA, transitionsB]) {
    final raw = value.toString();
    final localized = formatter.integer(value);
    if (raw == localized) continue;
    final index = text.indexOf(raw);
    if (index >= 0) {
      text = text.replaceRange(index, index + raw.length, localized);
    }
  }
  return text;
}

/// Layout decisions the comparison surface derives from its incoming box.
@immutable
class _ComparisonLayoutMetrics {
  const _ComparisonLayoutMetrics({
    required this.isStacked,
    required this.canvasHeight,
  });

  /// Below this content width the two automata are stacked instead of placed
  /// side by side, which is what keeps the canvases from being clipped on
  /// phones and in split-view panes.
  static const double stackBreakpoint = 640;

  /// Height assumed when the host imposes no height of its own.
  static const double _unboundedHeightBudget = 720;

  final bool isStacked;
  final double canvasHeight;

  factory _ComparisonLayoutMetrics.resolve(BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : stackBreakpoint;
    final isStacked = width < stackBreakpoint;
    final height = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : _unboundedHeightBudget;
    final preferred = isStacked ? 200.0 : 260.0;
    return _ComparisonLayoutMetrics(
      isStacked: isStacked,
      canvasHeight: math.max(140.0, math.min(preferred, height * 0.45)),
    );
  }
}
