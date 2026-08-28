import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/algorithms/grammar_to_pda/cfg_to_pda.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';

final class CfgToPdaConstructionWorkspace extends StatefulWidget {
  const CfgToPdaConstructionWorkspace({
    super.key,
    required this.grammar,
    required this.sourceRevision,
    required this.orientation,
    required this.onOpen,
    required this.onCancel,
    this.invalidated = false,
  });

  final Grammar grammar;
  final int sourceRevision;
  final CfgToPdaOrientation orientation;
  final Future<void> Function(PDA pda) onOpen;
  final VoidCallback onCancel;
  final bool invalidated;

  @override
  State<CfgToPdaConstructionWorkspace> createState() =>
      _CfgToPdaConstructionWorkspaceState();
}

final class _CfgToPdaConstructionWorkspaceState
    extends State<CfgToPdaConstructionWorkspace> {
  CfgToPdaConstructionReport? _report;
  CfgToPdaDifferentialReport? _evidence;
  Object? _error;
  int _selectedStep = 0;
  int _serial = 0;
  bool _building = false;
  bool _checking = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (!widget.invalidated) _buildReport();
  }

  @override
  void didUpdateWidget(CfgToPdaConstructionWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sourceChanged =
        oldWidget.grammar.id != widget.grammar.id ||
        oldWidget.sourceRevision != widget.sourceRevision ||
        oldWidget.orientation != widget.orientation;
    if (widget.invalidated) {
      _serial++;
    } else if (sourceChanged || oldWidget.invalidated) {
      _buildReport();
    }
  }

  @override
  void dispose() {
    _serial++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final report = _report;
    return Card.outlined(
      key: const ValueKey('cfg-to-pda-construction-workspace'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.localizeWorkflowText(
                  widget.orientation == CfgToPdaOrientation.ll
                      ? 'CFG to PDA (LL) construction preview'
                      : 'CFG to PDA (LR) construction preview',
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text(widget.grammar.name),
            const SizedBox(height: 12),
            if (widget.invalidated)
              _MessageCard(
                key: const ValueKey('cfg-pda-invalidated'),
                icon: Icons.warning_amber,
                text: l10n.localizeWorkflowText(
                  'The source grammar changed. Reopen the preview for the current revision.',
                ),
                color: Theme.of(context).colorScheme.error,
              )
            else if (_error != null)
              _MessageCard(
                key: const ValueKey('cfg-pda-error'),
                icon: Icons.error_outline,
                text:
                    '${l10n.localizeWorkflowText('The CFG to PDA construction failed.')} $_error',
                color: Theme.of(context).colorScheme.error,
              )
            else if (_building || report == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (!report.isCompleted)
              _buildBlocked(context, report)
            else
              _buildCompleted(context, report),
          ],
        ),
      ),
    );
  }

  Widget _buildBlocked(
    BuildContext context,
    CfgToPdaConstructionReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    return Column(
      key: const ValueKey('cfg-pda-blocked'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MessageCard(
          icon: Icons.block,
          text: l10n.localizeWorkflowText(switch (report.outcome) {
            CfgToPdaConstructionOutcome.llConflict =>
              'LL(1) conflicts block the LL construction.',
            CfgToPdaConstructionOutcome.lrConflict =>
              'Canonical LR(1) conflicts block the LR construction.',
            CfgToPdaConstructionOutcome.invalidGrammar =>
              'The source is not a valid context-free grammar.',
            _ => 'The construction prerequisite could not be completed.',
          }),
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < report.diagnostics.length; index++)
          ListTile(
            key: ValueKey('cfg-pda-diagnostic-$index'),
            minTileHeight: 48,
            leading: const Icon(Icons.report_outlined),
            title: Text(_diagnosticText(context, report.diagnostics[index])),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton(
            key: const ValueKey('cfg-pda-cancel'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: widget.onCancel,
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(
    BuildContext context,
    CfgToPdaConstructionReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final selected =
        report.steps[_selectedStep.clamp(0, report.steps.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(widget.orientation.name.toUpperCase())),
            Chip(
              label: Text(
                '${l10n.localizeWorkflowText('Acceptance')}: '
                '${l10n.localizeWorkflowText('final state after all input')}',
              ),
            ),
            Chip(
              label: Text(
                '${l10n.localizeWorkflowText('States')}: '
                '${formatter.integer(report.pda!.states.length)}',
              ),
            ),
            Chip(
              label: Text(
                '${l10n.localizeWorkflowText('Transitions')}: '
                '${formatter.integer(report.pda!.transitions.length)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAssumptions(context, report),
        const SizedBox(height: 16),
        _buildStepNavigator(context, report, selected),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final grammar = _GrammarPreview(
              grammar: widget.grammar,
              selectedProductionIds: _productionIds(selected),
            );
            final pda = _PdaPreview(
              pda: report.pda!,
              selectedTransitionIds: selected.transitionIds.toSet(),
              onTransitionSelected: (transitionId) {
                final provenance = report.provenanceFor(transitionId);
                if (provenance == null) return;
                setState(() => _selectedStep = provenance.stepIndex);
              },
            );
            if (constraints.maxWidth < 820) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [grammar, const SizedBox(height: 12), pda],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: grammar),
                const SizedBox(width: 12),
                Expanded(child: pda),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _buildEvidence(context, report),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('cfg-pda-cancel'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
              onPressed: _opening ? null : widget.onCancel,
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton.icon(
              key: const ValueKey('cfg-pda-open'),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
              onPressed: _opening
                  ? null
                  : () async {
                      setState(() => _opening = true);
                      try {
                        await widget.onOpen(report.pda!);
                      } finally {
                        if (mounted) setState(() => _opening = false);
                      }
                    },
              icon: _opening
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new),
              label: Text(l10n.localizeWorkflowText('Open in PDA editor')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssumptions(
    BuildContext context,
    CfgToPdaConstructionReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    final assumptions = report.assumptions.toList()
      ..sort((left, right) => left.index.compareTo(right.index));
    return Semantics(
      label: l10n.localizeWorkflowText('Construction assumptions'),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(l10n.localizeWorkflowText('Construction assumptions')),
        children: [
          for (final assumption in assumptions)
            ListTile(
              minTileHeight: 48,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(_assumptionText(context, assumption)),
            ),
        ],
      ),
    );
  }

  Widget _buildStepNavigator(
    BuildContext context,
    CfgToPdaConstructionReport report,
    CfgToPdaStep selected,
  ) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final delta = switch (event.logicalKey) {
          LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowRight => 1,
          LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.arrowLeft => -1,
          _ => 0,
        };
        if (delta == 0) return KeyEventResult.ignored;
        setState(() {
          _selectedStep = (_selectedStep + delta).clamp(
            0,
            report.steps.length - 1,
          );
        });
        return KeyEventResult.handled;
      },
      child: Semantics(
        label: l10n.localizeWorkflowText(
          'Construction steps. Use arrow keys to change the selected step.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.localizeWorkflowText('Construction steps'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 260,
              child: ListView.builder(
                key: const ValueKey('cfg-pda-step-list'),
                itemCount: report.steps.length,
                itemBuilder: (context, index) {
                  final step = report.steps[index];
                  return ListTile(
                    key: ValueKey('cfg-pda-step-$index'),
                    selected: step.index == selected.index,
                    minTileHeight: 48,
                    leading: CircleAvatar(
                      child: Text(formatter.integer(index + 1)),
                    ),
                    title: Text(_stepText(context, step)),
                    subtitle: Text(_stepSources(context, step)),
                    onTap: () => setState(() => _selectedStep = index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidence(
    BuildContext context,
    CfgToPdaConstructionReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.localizeWorkflowText('Bounded differential evidence'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          l10n.localizeWorkflowText(
            'Finite samples can detect a mismatch but cannot prove language equivalence.',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('cfg-pda-run-samples'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(180, 48)),
            onPressed: _checking ? null : () => _checkSamples(report),
            icon: _checking
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined),
            label: Text(l10n.localizeWorkflowText('Run sampled check')),
          ),
        ),
        if (_evidence != null) ...[
          const SizedBox(height: 8),
          for (final sample in _evidence!.samples)
            ListTile(
              minTileHeight: 48,
              leading: Icon(
                sample.outcome == CfgToPdaSampleOutcome.mismatch
                    ? Icons.error_outline
                    : sample.outcome == CfgToPdaSampleOutcome.boundedUnknown
                    ? Icons.help_outline
                    : Icons.check_circle_outline,
              ),
              title: Text(
                sample.input.isEmpty
                    ? l10n.localizeWorkflowText('Empty input')
                    : sample.input,
              ),
              subtitle: Text(
                l10n.localizeWorkflowText(switch (sample.outcome) {
                  CfgToPdaSampleOutcome.matchingAcceptance =>
                    'Grammar and PDA accepted this sample.',
                  CfgToPdaSampleOutcome.matchingRejection =>
                    'Grammar and PDA rejected this sample.',
                  CfgToPdaSampleOutcome.mismatch =>
                    'Grammar and PDA disagree on this sample.',
                  CfgToPdaSampleOutcome.boundedUnknown =>
                    'The sampled check was inconclusive within its bounds.',
                }),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _buildReport() async {
    final serial = ++_serial;
    setState(() {
      _building = true;
      _error = null;
      _report = null;
      _evidence = null;
      _selectedStep = 0;
    });
    try {
      final request = _ConstructionRequest(
        grammar: widget.grammar,
        sourceRevision: widget.sourceRevision,
        orientation: widget.orientation,
      );
      final report = await Isolate.run(request.run);
      if (!mounted || serial != _serial) return;
      setState(() {
        _report = report;
        _building = false;
      });
    } on Object catch (error) {
      if (!mounted || serial != _serial) return;
      setState(() {
        _error = error;
        _building = false;
      });
    }
  }

  Future<void> _checkSamples(CfgToPdaConstructionReport report) async {
    final serial = _serial;
    setState(() {
      _checking = true;
      _evidence = null;
    });
    try {
      final request = _DifferentialRequest(
        grammar: widget.grammar,
        report: report,
        inputs: _sampleInputs(widget.grammar),
      );
      final evidence = await Isolate.run(request.run);
      if (!mounted || serial != _serial) return;
      setState(() {
        _evidence = evidence;
        _checking = false;
      });
    } on Object catch (error) {
      if (!mounted || serial != _serial) return;
      setState(() {
        _error = error;
        _checking = false;
      });
    }
  }

  Set<String> _productionIds(CfgToPdaStep step) => step.sources
      .map((source) => source.productionId)
      .whereType<String>()
      .toSet();

  String _stepSources(BuildContext context, CfgToPdaStep step) {
    final l10n = appLocalizationsOf(context);
    String entry(String label, String values) => '$label: $values';
    final productions = _productionIds(step).toList()..sort();
    final lrCells =
        step.sources
            .where((source) => source.lrState != null)
            .map((source) => 'I${source.lrState}/${source.lookahead}')
            .toSet()
            .toList()
          ..sort();
    return [
      if (productions.isNotEmpty)
        entry(l10n.localizeWorkflowText('Productions'), productions.join(', ')),
      if (lrCells.isNotEmpty)
        '${l10n.localizeWorkflowText('LR cells')}: ${lrCells.join(', ')}',
      if (step.stateIds.isNotEmpty)
        '${l10n.localizeWorkflowText('States')}: ${step.stateIds.join(', ')}',
      if (step.transitionIds.isNotEmpty)
        entry(
          l10n.localizeWorkflowText('Transitions'),
          step.transitionIds.join(', '),
        ),
    ].join(' · ');
  }

  String _stepText(BuildContext context, CfgToPdaStep step) =>
      appLocalizationsOf(context).localizeWorkflowText(switch (step.kind) {
        CfgToPdaStepKind.createState => 'Create PDA state',
        CfgToPdaStepKind.initializeStack => 'Initialize the LL stack',
        CfgToPdaStepKind.expandVariable => 'Expand a grammar variable',
        CfgToPdaStepKind.matchTerminal => 'Match an input terminal',
        CfgToPdaStepKind.shiftTerminal => 'Shift an input terminal',
        CfgToPdaStepKind.reduceProduction => 'Reduce by a production',
        CfgToPdaStepKind.acceptStart => 'Recognize the start variable',
        CfgToPdaStepKind.popBottomMarker => 'Verify the bottom marker',
      });

  String _assumptionText(
    BuildContext context,
    CfgToPdaAssumption assumption,
  ) => appLocalizationsOf(context).localizeWorkflowText(switch (assumption) {
    CfgToPdaAssumption.contextFreeSource =>
      'The source must be a valid context-free grammar.',
    CfgToPdaAssumption.finalStateAfterInput =>
      'Acceptance requires all input consumed and the final state reached.',
    CfgToPdaAssumption.bottomMarkerInitialized =>
      'A collision-safe bottom marker initializes the stack.',
    CfgToPdaAssumption.llPredictiveConflictFree =>
      'The canonical LL(1) table must be conflict-free.',
    CfgToPdaAssumption.llTopDownExpansion =>
      'LL transitions expand the leftmost stack variable top-down.',
    CfgToPdaAssumption.lrCanonicalConflictFree =>
      'The canonical LR(1) table must be conflict-free.',
    CfgToPdaAssumption.lrBottomUpReduction =>
      'LR transitions shift terminals and reduce production right sides bottom-up.',
    CfgToPdaAssumption.sampledEvidenceNotProof =>
      'Finite differential samples are evidence, not an equivalence proof.',
  });

  String _diagnosticText(BuildContext context, CfgToPdaDiagnostic diagnostic) {
    final l10n = appLocalizationsOf(context);
    if (diagnostic.structuredMessage case final structured?) {
      return l10n.resolveStructuredMessage(structured);
    }
    return switch (diagnostic.code) {
      CfgToPdaDiagnosticCode.emptyGrammar => l10n.localizeWorkflowText(
        'The grammar has no productions.',
      ),
      CfgToPdaDiagnosticCode.missingStartSymbol => l10n.localizeWorkflowText(
        'The grammar has no start symbol.',
      ),
      CfgToPdaDiagnosticCode.undeclaredStartSymbol =>
        '${l10n.localizeWorkflowText('The start symbol is undeclared')}: '
            '${diagnostic.symbol}',
      CfgToPdaDiagnosticCode.malformedProduction =>
        '${l10n.localizeWorkflowText('Malformed CFG production')}: '
            '${diagnostic.productionId}',
      CfgToPdaDiagnosticCode.duplicateProductionId =>
        '${l10n.localizeWorkflowText('Duplicate production ID')}: '
            '${diagnostic.productionId}',
      CfgToPdaDiagnosticCode.undeclaredSymbol =>
        '${l10n.localizeWorkflowText('Undeclared production symbol')}: '
            '${diagnostic.symbol} (${diagnostic.productionId})',
      CfgToPdaDiagnosticCode.llConflict =>
        'LL(1) [${diagnostic.nonTerminal}, ${diagnostic.lookahead}]: '
            '${diagnostic.relatedProductionIds.join(' / ')}',
      CfgToPdaDiagnosticCode.lrConflict =>
        'LR(1) I${diagnostic.lrState} / ${diagnostic.lookahead}: '
            '${diagnostic.relatedProductionIds.join(' / ')}',
      CfgToPdaDiagnosticCode.llAnalysisFailed ||
      CfgToPdaDiagnosticCode.lrConstructionUnavailable ||
      CfgToPdaDiagnosticCode.outputInvalid =>
        '${l10n.localizeWorkflowText('Construction diagnostic')}: '
            '${diagnostic.detailCode}',
    };
  }
}

final class _GrammarPreview extends StatelessWidget {
  const _GrammarPreview({
    required this.grammar,
    required this.selectedProductionIds,
  });

  final Grammar grammar;
  final Set<String> selectedProductionIds;

  @override
  Widget build(BuildContext context) {
    final productions = grammar.productions.toList()
      ..sort((left, right) {
        final order = left.order.compareTo(right.order);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    return _PreviewCard(
      title: appLocalizationsOf(context).localizeWorkflowText('Source grammar'),
      child: SizedBox(
        height: 300,
        child: ListView(
          children: [
            for (final production in productions)
              ListTile(
                key: ValueKey('cfg-pda-production-${production.id}'),
                selected: selectedProductionIds.contains(production.id),
                minTileHeight: 48,
                leading: const Icon(Icons.rule),
                title: Text(production.stringRepresentation),
                subtitle: Text(production.id),
              ),
          ],
        ),
      ),
    );
  }
}

final class _PdaPreview extends StatelessWidget {
  const _PdaPreview({
    required this.pda,
    required this.selectedTransitionIds,
    required this.onTransitionSelected,
  });

  final PDA pda;
  final Set<String> selectedTransitionIds;
  final ValueChanged<String> onTransitionSelected;

  @override
  Widget build(BuildContext context) {
    final transitions = pda.pdaTransitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return _PreviewCard(
      title: appLocalizationsOf(context).localizeWorkflowText('PDA preview'),
      child: SizedBox(
        height: 300,
        child: ListView(
          children: [
            for (final transition in transitions)
              ListTile(
                key: ValueKey('cfg-pda-transition-${transition.id}'),
                selected: selectedTransitionIds.contains(transition.id),
                minTileHeight: 48,
                leading: const Icon(Icons.arrow_forward),
                title: Text(
                  '${transition.fromState.id} → ${transition.toState.id}',
                ),
                subtitle: Text(
                  '${transition.label} · '
                  '[${transition.pushSymbols.join(', ')}]',
                ),
                onTap: () => onTransitionSelected(transition.id),
              ),
          ],
        ),
      ),
    );
  }
}

final class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}

final class _MessageCard extends StatelessWidget {
  const _MessageCard({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

final class _ConstructionRequest {
  const _ConstructionRequest({
    required this.grammar,
    required this.sourceRevision,
    required this.orientation,
  });

  final Grammar grammar;
  final int sourceRevision;
  final CfgToPdaOrientation orientation;

  CfgToPdaConstructionReport run() => orientation == CfgToPdaOrientation.ll
      ? CfgToPdaConverter.buildLl(grammar, sourceRevision: sourceRevision)
      : CfgToPdaConverter.buildLr(grammar, sourceRevision: sourceRevision);
}

final class _DifferentialRequest {
  const _DifferentialRequest({
    required this.grammar,
    required this.report,
    required this.inputs,
  });

  final Grammar grammar;
  final CfgToPdaConstructionReport report;
  final List<String> inputs;

  CfgToPdaDifferentialReport run() =>
      CfgToPdaDifferentialChecker.check(grammar, report, inputs);
}

List<String> _sampleInputs(Grammar grammar) {
  final terminals = grammar.terminals.toList()..sort();
  final samples = <String>{''};
  for (final terminal in terminals.take(6)) {
    samples.add(terminal);
  }
  for (final first in terminals.take(5)) {
    for (final second in terminals.take(5)) {
      samples.add('$first$second');
      if (samples.length >= 24) break;
    }
    if (samples.length >= 24) break;
  }
  return samples.toList()..sort();
}
