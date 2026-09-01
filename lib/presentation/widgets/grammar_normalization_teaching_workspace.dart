import 'dart:async';

import 'package:flutter/material.dart';

import '../empty_string_notation.dart';

import '../../core/constants/monospace_typography.dart';
import '../../core/grammar/teaching/grammar_teaching_sessions.dart';
import '../../core/grammar/teaching/grammar_teaching_session_store.dart';
import '../../core/models/grammar.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../content/grammar_teaching_content_copy.dart';

class GrammarNormalizationTeachingWorkspace extends StatefulWidget {
  static final contentReferences =
      NormalizationTeachingSession.contentReferences;

  factory GrammarNormalizationTeachingWorkspace({
    Key? key,
    required Grammar grammar,
    GrammarTeachingSessionStore? store,
  }) {
    return GrammarNormalizationTeachingWorkspace._(
      key: key,
      grammar: grammar,
      store: store,
      initialSession:
          store?.loadNormalization(grammar) ??
          NormalizationTeachingSession.start(grammar),
    );
  }

  const GrammarNormalizationTeachingWorkspace._({
    super.key,
    required this.grammar,
    required this.initialSession,
    this.store,
  });

  final Grammar grammar;
  final NormalizationTeachingSession initialSession;
  final GrammarTeachingSessionStore? store;

  @override
  State<GrammarNormalizationTeachingWorkspace> createState() =>
      _GrammarNormalizationTeachingWorkspaceState();
}

class _GrammarNormalizationTeachingWorkspaceState
    extends State<GrammarNormalizationTeachingWorkspace> {
  late NormalizationTeachingSession _session;
  late final TextEditingController _draftController;
  bool _showReference = false;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _draftController = TextEditingController(text: _currentDraft);
  }

  @override
  void didUpdateWidget(
    covariant GrammarNormalizationTeachingWorkspace oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSession.sourceGrammarId !=
            widget.initialSession.sourceGrammarId ||
        oldWidget.initialSession.sourceRevision !=
            widget.initialSession.sourceRevision) {
      _session = widget.initialSession;
      _syncDraft();
    }
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  String get _currentDraft =>
      _session.currentState.drafts[_session.currentState.selectedStage]!;

  @override
  Widget build(BuildContext context) {
    final strings = appLocalizationsOf(context);
    final stage = _session.currentState.selectedStage;
    final diagnostics = _session.currentDiagnostics;
    final content = GrammarTeachingContentCopies.resolve(
      reference:
          GrammarNormalizationTeachingWorkspace.contentReferences[stage.index],
      languageCode: Localizations.localeOf(context).languageCode,
      arguments: const {},
    );
    return FocusTraversalGroup(
      child: Semantics(
        container: true,
        label: strings.localizeWorkflowText(
          'Grammar normalization teaching workspace',
        ),
        child: Card.outlined(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  label: content.title,
                  hint: content.accessibleDescription,
                  child: ExcludeSemantics(
                    child: Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(content.instruction),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in NormalizationTeachingStage.values)
                      ChoiceChip(
                        key: ValueKey('normalization-stage-${item.name}'),
                        label: Text(_stageLabel(item)),
                        avatar:
                            _session.currentState.completedStages.contains(item)
                            ? const Icon(Icons.check, size: 18)
                            : null,
                        selected: item == stage,
                        onSelected: (_) =>
                            _apply(_session.selectStage(item), syncDraft: true),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('normalization-draft'),
                  controller: _draftController,
                  minLines: 6,
                  maxLines: 14,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontFamilyFallback: kMonospaceFontFamilyFallback,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: strings.localizeWorkflowText(
                      'Your intermediate productions',
                    ),
                    helperText: strings.localizeWorkflowText(
                      'Your draft stays here when validation finds a mistake.',
                    ),
                  ),
                  onChanged: (value) => _apply(_session.updateDraft(value)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('validate-normalization-draft'),
                      onPressed: () => _apply(_session.validateCurrent()),
                      icon: const Icon(Icons.rule),
                      label: Text(strings.localizeWorkflowText('Check step')),
                    ),
                    IconButton.outlined(
                      key: const ValueKey('undo-normalization-draft'),
                      tooltip: strings.localizeWorkflowText('Undo'),
                      onPressed: _session.canUndo
                          ? () => _apply(_session.undo(), syncDraft: true)
                          : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton.outlined(
                      key: const ValueKey('redo-normalization-draft'),
                      tooltip: strings.localizeWorkflowText('Redo'),
                      onPressed: _session.canRedo
                          ? () => _apply(_session.redo(), syncDraft: true)
                          : null,
                      icon: const Icon(Icons.redo),
                    ),
                    TextButton.icon(
                      key: const ValueKey('toggle-normalization-reference'),
                      onPressed: () =>
                          setState(() => _showReference = !_showReference),
                      icon: Icon(
                        _showReference ? Icons.visibility_off : Icons.compare,
                      ),
                      label: Text(
                        strings.localizeWorkflowText(
                          _showReference
                              ? 'Hide reference'
                              : 'Compare with reference',
                        ),
                      ),
                    ),
                  ],
                ),
                if (diagnostics.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    label: strings.localizeWorkflowText(
                      'Normalization validation result',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final diagnostic in diagnostics)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _diagnosticText(diagnostic),
                              key: ValueKey(
                                'normalization-diagnostic-${diagnostic.code.name}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (_showReference) ...[
                  const SizedBox(height: 12),
                  _ReferenceGrammar(grammar: _session.referenceFor(stage)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _apply(NormalizationTeachingSession next, {bool syncDraft = false}) {
    _session = next;
    if (syncDraft) _syncDraft();
    unawaited(widget.store?.saveNormalization(_session));
    if (mounted) setState(() {});
  }

  void _syncDraft() {
    _draftController.value = TextEditingValue(
      text: _currentDraft,
      selection: TextSelection.collapsed(offset: _currentDraft.length),
    );
  }

  String _stageLabel(NormalizationTeachingStage stage) {
    final localizations = appLocalizationsOf(context);
    return localizations.localizeWorkflowText(switch (stage) {
      NormalizationTeachingStage.lambda => 'Remove lambda',
      NormalizationTeachingStage.unit => 'Remove unit productions',
      NormalizationTeachingStage.useless => 'Remove useless productions',
      NormalizationTeachingStage.cnf => 'Finish CNF',
    });
  }

  String _diagnosticText(NormalizationTeachingDiagnostic diagnostic) {
    final localizations = appLocalizationsOf(context);
    final line = diagnostic.line == null
        ? ''
        : ' ${localizations.localizeWorkflowText('Line')} ${diagnostic.line}.';
    final detail = diagnostic.detail == null ? '' : ' ${diagnostic.detail}';
    final text = switch (diagnostic.code) {
      NormalizationTeachingDiagnosticCode.validEquivalent =>
        'Valid equivalent step.',
      NormalizationTeachingDiagnosticCode.duplicate =>
        'Duplicate production.$line',
      NormalizationTeachingDiagnosticCode.invalidSymbol =>
        'Unknown symbol.$line$detail',
      NormalizationTeachingDiagnosticCode.invalidSyntax =>
        'Use the form A -> symbol symbol.$line',
      NormalizationTeachingDiagnosticCode.outOfOrder =>
        'This matches the ${diagnostic.stage?.name ?? 'later'} step, which comes later.',
      NormalizationTeachingDiagnosticCode.missingProduction =>
        'Missing production:$detail',
      NormalizationTeachingDiagnosticCode.unexpectedProduction =>
        'Unexpected production:$detail',
      NormalizationTeachingDiagnosticCode.sourceChanged =>
        'The source grammar changed. Start a new exercise.',
      NormalizationTeachingDiagnosticCode.invalidPayload =>
        'The saved exercise could not be restored.',
    };
    return localizations.localizeWorkflowText(text);
  }
}

class _ReferenceGrammar extends StatelessWidget {
  const _ReferenceGrammar({required this.grammar});

  final Grammar grammar;

  @override
  Widget build(BuildContext context) {
    final productions = grammar.productions.toList()
      ..sort((left, right) {
        final order = left.order.compareTo(right.order);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    return Semantics(
      container: true,
      readOnly: true,
      label: appLocalizationsOf(
        context,
      ).localizeWorkflowText('Generated reference grammar'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              appLocalizationsOf(
                context,
              ).localizeWorkflowText('Generated reference. Read only.'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final production in productions)
              Text(
                '${production.leftSide.single} → '
                '${production.isLambda || production.rightSide.isEmpty ? EmptyStringNotation.symbolOf(context) : production.rightSide.join(' ')}',
                style: const TextStyle(
                  fontFamilyFallback: kMonospaceFontFamilyFallback,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
