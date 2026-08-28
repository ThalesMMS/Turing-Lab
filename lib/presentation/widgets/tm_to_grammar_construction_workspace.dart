import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/models/tm.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';

final class TMToGrammarConstructionWorkspace extends StatefulWidget {
  const TMToGrammarConstructionWorkspace({
    super.key,
    required this.tm,
    required this.sourceRevision,
    required this.invalidated,
    required this.onOpen,
    required this.onCancel,
  });

  final TM tm;
  final int sourceRevision;
  final bool invalidated;
  final Future<void> Function(TMToGrammarConstructionReport report) onOpen;
  final VoidCallback onCancel;

  @override
  State<TMToGrammarConstructionWorkspace> createState() =>
      _TMToGrammarConstructionWorkspaceState();
}

final class _TMToGrammarConstructionWorkspaceState
    extends State<TMToGrammarConstructionWorkspace> {
  TMToGrammarConstructionReport? _report;
  TMToGrammarDifferentialReport? _evidence;
  TMToGrammarProductionFamily? _family;
  String? _selectedProductionId;
  Object? _error;
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
  void didUpdateWidget(TMToGrammarConstructionWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.tm.id != widget.tm.id ||
        oldWidget.sourceRevision != widget.sourceRevision;
    if (widget.invalidated) {
      _serial++;
    } else if (changed || oldWidget.invalidated) {
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
      key: const ValueKey('tm-to-grammar-workspace'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.localizeWorkflowText(
                  'TM to unrestricted grammar construction preview',
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text(widget.tm.name),
            const SizedBox(height: 12),
            if (widget.invalidated)
              _MessageCard(
                key: const ValueKey('tm-grammar-invalidated'),
                icon: Icons.warning_amber,
                color: Theme.of(context).colorScheme.error,
                text: l10n.localizeWorkflowText(
                  'The source TM changed. Reopen the preview for the current revision.',
                ),
              )
            else if (_error != null)
              _MessageCard(
                icon: Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                text:
                    '${l10n.localizeWorkflowText('The TM to grammar construction failed.')} $_error',
              )
            else if (_building || report == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
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
    TMToGrammarConstructionReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    return Column(
      key: const ValueKey('tm-grammar-blocked'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MessageCard(
          icon: Icons.block,
          color: Theme.of(context).colorScheme.error,
          text: l10n.localizeWorkflowText(
            report.outcome == TMToGrammarOutcome.unsupportedMachine
                ? 'This TM uses features outside the supported conversion subset.'
                : 'The TM cannot be converted until its diagnostics are resolved.',
          ),
        ),
        for (var index = 0; index < report.diagnostics.length; index++)
          ListTile(
            key: ValueKey('tm-grammar-diagnostic-$index'),
            minTileHeight: 48,
            leading: const Icon(Icons.report_outlined),
            title: Text(_diagnosticText(context, report.diagnostics[index])),
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton(
            key: const ValueKey('tm-grammar-cancel'),
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
    TMToGrammarConstructionReport report,
  ) {
    final l10n = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    final grammar = report.grammar!;
    final selectedId = _selectedProductionId ?? grammar.productions.first.id;
    final selected = grammar.productions.firstWhere(
      (production) => production.id == selectedId,
      orElse: () => grammar.productions.first,
    );
    final selectedProvenance = report.provenanceFor(selected.id)!;
    final visible = grammar.productions
        .where(
          (production) =>
              _family == null ||
              report.provenanceFor(production.id)?.family == _family,
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(
                l10n.localizeWorkflowText('Single tape, two-way infinite'),
              ),
            ),
            Chip(
              label: Text(
                '${l10n.localizeWorkflowText('Acceptance')}: '
                '${l10n.localizeWorkflowText('entering a final state')}',
              ),
            ),
            Chip(
              label: Text(
                '${l10n.localizeWorkflowText('Productions')}: '
                '${valueFormatter.integer(grammar.productions.length)}',
              ),
            ),
            Chip(
              label: Text(
                '${l10n.localizeWorkflowText('Variables')}: '
                '${valueFormatter.integer(grammar.nonterminals.length)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAssumptions(context, report),
        if (report.diagnostics.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final diagnostic in report.diagnostics)
            _MessageCard(
              icon: Icons.info_outline,
              color: Theme.of(context).colorScheme.tertiary,
              text: _diagnosticText(context, diagnostic),
            ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<TMToGrammarProductionFamily?>(
          key: const ValueKey('tm-grammar-family-filter'),
          initialValue: _family,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.localizeWorkflowText('Production family'),
          ),
          items: [
            DropdownMenuItem<TMToGrammarProductionFamily?>(
              value: null,
              child: Text(l10n.localizeWorkflowText('All families')),
            ),
            for (final family in TMToGrammarProductionFamily.values)
              DropdownMenuItem<TMToGrammarProductionFamily?>(
                value: family,
                child: Text(_familyText(context, family)),
              ),
          ],
          onChanged: (family) => setState(() => _family = family),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tmPreview = _SourceTmPreview(
              tm: widget.tm,
              provenance: selectedProvenance,
            );
            final grammarPreview = _GrammarProductionPreview(
              productions: visible,
              report: report,
              selectedId: selected.id,
              onSelected: (id) => setState(() => _selectedProductionId = id),
            );
            if (constraints.maxWidth < 820) {
              return Column(
                children: [
                  tmPreview,
                  const SizedBox(height: 12),
                  grammarPreview,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tmPreview),
                const SizedBox(width: 12),
                Expanded(child: grammarPreview),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _SelectedProductionDetails(
          productionText: '${selected.left} → ${selected.right}',
          family: _familyText(context, selectedProvenance.family),
          invariant: selectedProvenance.invariantCode,
        ),
        const SizedBox(height: 16),
        _buildEvidence(context, report),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('tm-grammar-copy-report'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(150, 48)),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: const JsonEncoder.withIndent(
                      '  ',
                    ).convert(report.toStructuredJson()),
                  ),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.localizeWorkflowText('Construction report copied.'),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: Text(l10n.localizeWorkflowText('Copy report')),
            ),
            OutlinedButton(
              key: const ValueKey('tm-grammar-cancel'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 48)),
              onPressed: _opening ? null : widget.onCancel,
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton.icon(
              key: const ValueKey('tm-grammar-open'),
              style: FilledButton.styleFrom(minimumSize: const Size(190, 48)),
              onPressed: _opening
                  ? null
                  : () async {
                      setState(() => _opening = true);
                      try {
                        await widget.onOpen(report);
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
              label: Text(
                l10n.localizeWorkflowText(
                  'Open in unrestricted grammar editor',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssumptions(
    BuildContext context,
    TMToGrammarConstructionReport report,
  ) {
    final assumptions = report.assumptions.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final l10n = appLocalizationsOf(context);
    return ExpansionTile(
      title: Text(l10n.localizeWorkflowText('Construction assumptions')),
      initiallyExpanded: true,
      children: [
        for (final assumption in assumptions)
          ListTile(
            minTileHeight: 48,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(_assumptionText(context, assumption)),
          ),
      ],
    );
  }

  Widget _buildEvidence(
    BuildContext context,
    TMToGrammarConstructionReport report,
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
            key: const ValueKey('tm-grammar-run-samples'),
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
        if (_evidence != null)
          for (final sample in _evidence!.samples)
            ListTile(
              minTileHeight: 48,
              leading: Icon(
                sample.outcome == TMToGrammarSampleOutcome.mismatch
                    ? Icons.error_outline
                    : sample.outcome == TMToGrammarSampleOutcome.boundedUnknown
                    ? Icons.help_outline
                    : Icons.check_circle_outline,
              ),
              title: Text(
                sample.inputTokens.isEmpty
                    ? l10n.localizeWorkflowText('Empty input')
                    : sample.inputTokens.join(' · '),
              ),
              subtitle: Text(
                l10n.localizeWorkflowText(switch (sample.outcome) {
                  TMToGrammarSampleOutcome.matchingAcceptance =>
                    'TM and grammar accepted this sample.',
                  TMToGrammarSampleOutcome.matchingRejection =>
                    'TM and grammar rejected this sample.',
                  TMToGrammarSampleOutcome.mismatch =>
                    'TM and grammar disagree on this sample.',
                  TMToGrammarSampleOutcome.boundedUnknown =>
                    'The sampled check was inconclusive within its bounds.',
                  TMToGrammarSampleOutcome.invalid =>
                    'The sampled check could not validate this input.',
                }),
              ),
            ),
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
      _family = null;
      _selectedProductionId = null;
    });
    try {
      final request = _ConstructionRequest(
        tm: widget.tm,
        sourceRevision: widget.sourceRevision,
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

  Future<void> _checkSamples(TMToGrammarConstructionReport report) async {
    final serial = _serial;
    setState(() {
      _checking = true;
      _evidence = null;
    });
    try {
      final evidence = await TMToGrammarDifferentialChecker.check(
        widget.tm,
        report,
        _sampleInputs(widget.tm),
      );
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

  String _familyText(
    BuildContext context,
    TMToGrammarProductionFamily family,
  ) => _tmToGrammarProductionFamilyText(context, family);

  String _assumptionText(
    BuildContext context,
    TMToGrammarAssumption assumption,
  ) => appLocalizationsOf(context).localizeWorkflowText(switch (assumption) {
    TMToGrammarAssumption.singleTape =>
      'Only single-tape machines are supported.',
    TMToGrammarAssumption.twoWayInfiniteTape =>
      'The tape is infinite in both directions.',
    TMToGrammarAssumption.finalStateAcceptance =>
      'Entering a final state accepts immediately.',
    TMToGrammarAssumption.deterministicOrNondeterministic =>
      'Deterministic and nondeterministic transitions are preserved.',
    TMToGrammarAssumption.atomicTokenSymbols =>
      'Tape and grammar symbols remain atomic tokens.',
    TMToGrammarAssumption.finiteWindowChosenByDerivation =>
      'Each derivation chooses enough finite blank padding for its computation.',
    TMToGrammarAssumption.sampledEvidenceNotProof =>
      'Finite differential samples are evidence, not an equivalence proof.',
  });

  String _diagnosticText(
    BuildContext context,
    TMToGrammarDiagnostic diagnostic,
  ) {
    final l10n = appLocalizationsOf(context);
    return switch (diagnostic.code) {
      TMToGrammarDiagnosticCode.invalidMachine => l10n.localizeWorkflowText(
        'The TM model is invalid.',
      ),
      TMToGrammarDiagnosticCode.missingInitialState =>
        l10n.localizeWorkflowText('The TM has no valid initial state.'),
      TMToGrammarDiagnosticCode.noAcceptingState => l10n.localizeWorkflowText(
        'The TM has no accepting state, so the generated language is empty.',
      ),
      TMToGrammarDiagnosticCode.multiTapeUnsupported =>
        l10n.localizeWorkflowText(
          'Multi-tape conversion is not supported; use a single-tape TM.',
        ),
      TMToGrammarDiagnosticCode.buildingBlocksUnsupported =>
        l10n.localizeWorkflowText(
          'Inline or remove building blocks before conversion.',
        ),
      TMToGrammarDiagnosticCode.blankInInputAlphabet =>
        l10n.localizeWorkflowText(
          'The blank symbol cannot also be an input symbol.',
        ),
      TMToGrammarDiagnosticCode.inputOutsideTapeAlphabet =>
        '${l10n.localizeWorkflowText('Input symbol outside the tape alphabet')}: '
            '${diagnostic.symbol}',
      TMToGrammarDiagnosticCode.constructionLimit => l10n.localizeWorkflowText(
        'The production construction limit was reached.',
      ),
      TMToGrammarDiagnosticCode.outputInvalid => l10n.localizeWorkflowText(
        'The generated grammar did not validate.',
      ),
      TMToGrammarDiagnosticCode.unreachableState =>
        '${l10n.localizeWorkflowText('Unreachable state preserved')}: '
            '${diagnostic.stateId}',
    };
  }
}

final class _ConstructionRequest {
  const _ConstructionRequest({required this.tm, required this.sourceRevision});

  final TM tm;
  final int sourceRevision;

  TMToGrammarConstructionReport run() =>
      TMToGrammarConverter.build(tm, sourceRevision: sourceRevision);
}

String _tmToGrammarProductionFamilyText(
  BuildContext context,
  TMToGrammarProductionFamily family,
) => appLocalizationsOf(context).localizeWorkflowText(switch (family) {
  TMToGrammarProductionFamily.initialization => 'Initialization',
  TMToGrammarProductionFamily.inputCell => 'Input encoding',
  TMToGrammarProductionFamily.boundaryBlank => 'Blank boundaries',
  TMToGrammarProductionFamily.moveLeft => 'Move left',
  TMToGrammarProductionFamily.moveRight => 'Move right',
  TMToGrammarProductionFamily.stay => 'Stay move',
  TMToGrammarProductionFamily.acceptingState => 'Accepting state',
  TMToGrammarProductionFamily.cleanupLeft => 'Cleanup left sweep',
  TMToGrammarProductionFamily.cleanupRight => 'Cleanup right sweep',
});

final class _SourceTmPreview extends StatelessWidget {
  const _SourceTmPreview({required this.tm, required this.provenance});

  final TM tm;
  final TMToGrammarProductionProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final selectedStates = provenance.sources
        .map((source) => source.stateId)
        .whereType<String>()
        .toSet();
    final selectedTransitions = provenance.sources
        .map((source) => source.transitionId)
        .whereType<String>()
        .toSet();
    final states = tm.states.toList()..sort((a, b) => a.id.compareTo(b.id));
    final transitions = tm.tmTransitions.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return _PreviewCard(
      title: appLocalizationsOf(context).localizeWorkflowText('Source TM'),
      child: SizedBox(
        height: 360,
        child: ListView(
          children: [
            for (final state in states)
              ListTile(
                selected: selectedStates.contains(state.id),
                minTileHeight: 48,
                leading: const Icon(Icons.circle_outlined),
                title: Text(state.label),
                subtitle: Text(state.id),
              ),
            for (final transition in transitions)
              ListTile(
                key: ValueKey('tm-grammar-source-${transition.id}'),
                selected: selectedTransitions.contains(transition.id),
                minTileHeight: 48,
                leading: const Icon(Icons.arrow_forward),
                title: Text(
                  '${transition.fromState.label} → ${transition.toState.label}',
                ),
                subtitle: Text('${transition.id} · ${transition.label}'),
              ),
          ],
        ),
      ),
    );
  }
}

final class _GrammarProductionPreview extends StatelessWidget {
  const _GrammarProductionPreview({
    required this.productions,
    required this.report,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PhraseStructureProduction> productions;
  final TMToGrammarConstructionReport report;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => _PreviewCard(
    title: appLocalizationsOf(context).localizeWorkflowText('Result grammar'),
    child: SizedBox(
      height: 360,
      child: ListView.builder(
        key: const ValueKey('tm-grammar-production-list'),
        itemCount: productions.length,
        itemBuilder: (context, index) {
          final production = productions[index];
          final provenance = report.provenanceFor(production.id)!;
          return ListTile(
            key: ValueKey('tm-grammar-production-${production.id}'),
            selected: production.id == selectedId,
            minTileHeight: 48,
            title: Text('${production.left} → ${production.right}'),
            subtitle: Text(
              _tmToGrammarProductionFamilyText(context, provenance.family),
            ),
            onTap: () => onSelected(production.id),
          );
        },
      ),
    ),
  );
}

final class _SelectedProductionDetails extends StatelessWidget {
  const _SelectedProductionDetails({
    required this.productionText,
    required this.family,
    required this.invariant,
  });

  final String productionText;
  final String family;
  final String invariant;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      child: ListTile(
        minTileHeight: 64,
        leading: const Icon(Icons.account_tree_outlined),
        title: Text(productionText),
        subtitle: Text('$family · $invariant'),
      ),
    ),
  );
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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
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
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
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

List<List<String>> _sampleInputs(TM tm) {
  final alphabet = tm.alphabet.toList()..sort();
  final samples = <List<String>>[const []];
  for (final symbol in alphabet.take(4)) {
    samples.add([symbol]);
  }
  for (final first in alphabet.take(3)) {
    for (final second in alphabet.take(3)) {
      samples.add([first, second]);
    }
  }
  return samples;
}
