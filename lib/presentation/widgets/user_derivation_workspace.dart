import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/monospace_typography.dart';
import '../../core/grammar/teaching/grammar_teaching_content.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../empty_string_notation.dart';
import '../content/grammar_teaching_content_copy.dart';
import '../localization/locale_value_formatter.dart';
import 'derivation_tree_view.dart';

class UserDerivationWorkspace extends StatefulWidget {
  const UserDerivationWorkspace({
    super.key,
    required this.grammar,
    required this.target,
    this.initialMode = UserDerivationMode.leftmost,
    this.challenge,
    this.invalidationCode,
    this.onSessionChanged,
    this.onInvalidatedRestart,
  });

  final PhraseStructureGrammar grammar;
  static final contentReference = GrammarTeachingContent.userDerivation;
  final GrammarSymbolSequence target;
  final UserDerivationMode initialMode;
  final UserDerivationChallenge? challenge;
  final UserDerivationDiagnosticCode? invalidationCode;
  final ValueChanged<UserDerivationSession>? onSessionChanged;
  final VoidCallback? onInvalidatedRestart;

  @override
  State<UserDerivationWorkspace> createState() =>
      _UserDerivationWorkspaceState();
}

class _UserDerivationWorkspaceState extends State<UserDerivationWorkspace> {
  UserDerivationSession? _session;
  UserDerivationMode? _mode;
  String? _selectedProductionId;
  ProductionApplication? _preview;
  UserDerivationDiagnostic? _moveDiagnostic;
  UserDerivationHintResult? _hint;
  UserDerivationHintProgress? _hintProgress;
  UserDerivationHintCancellationToken? _hintCancellationToken;
  bool _hintRunning = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.grammar is UnrestrictedGrammar
        ? UserDerivationMode.unrestrictedOccurrence
        : widget.initialMode;
    _startSession();
  }

  @override
  void didUpdateWidget(UserDerivationWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final invalidation = widget.invalidationCode;
    if (invalidation != null &&
        (invalidation != oldWidget.invalidationCode ||
            widget.grammar.id != oldWidget.grammar.id ||
            widget.grammar.revision != oldWidget.grammar.revision ||
            widget.target != oldWidget.target)) {
      _hintCancellationToken?.cancel();
      final session = _session;
      if (session != null) {
        _session = session.invalidate(
          UserDerivationDiagnostic(code: invalidation),
        );
        widget.onSessionChanged?.call(_session!);
      }
    }
  }

  @override
  void dispose() {
    _hintCancellationToken?.cancel();
    super.dispose();
  }

  void _startSession() {
    final result = UserDerivationSession.start(
      grammar: widget.grammar,
      target: widget.target,
      mode: _mode!,
      challenge: widget.challenge,
    );
    _session = result.session;
    _moveDiagnostic = result.diagnostics.firstOrNull;
    _selectedProductionId = null;
    _preview = null;
    _hint = null;
    _hintProgress = null;
    if (_session != null) widget.onSessionChanged?.call(_session!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final session = _session;
    if (session == null) {
      return _MessageCard(
        text: _diagnosticText(context, _moveDiagnostic?.code),
      );
    }
    final allApplications = PhraseProductionApplicator.allApplications(
      session.currentForm,
      widget.grammar.phraseProductions,
    );
    final selectedApplications = allApplications
        .where(
          (application) => application.production.id == _selectedProductionId,
        )
        .toList(growable: false);
    final tree = session.buildCfgTree(widget.grammar);
    final content = GrammarTeachingContentCopies.resolve(
      reference: UserDerivationWorkspace.contentReference,
      languageCode: Localizations.localeOf(context).languageCode,
      arguments: {
        'target': widget.target.toString(),
        'production': _selectedProductionId,
        'occurrence': _preview?.occurrence.startIndex,
        'limit': widget.challenge?.maxSteps,
      },
    );

    return Semantics(
      container: true,
      label: content.title,
      hint: content.accessibleDescription,
      child: Card.outlined(
        key: const ValueKey('user-derivation-workspace'),
        margin: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        content.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.localizeWorkflowText(
                      'Copy structured derivation',
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: () => _copyReport(context),
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              Text(content.instruction),
              const SizedBox(height: 4),
              Text(
                '${l10n.localizeWorkflowText('Target')}: ${widget.target}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamilyFallback: kMonospaceFontFamilyFallback,
                ),
              ),
              const SizedBox(height: 12),
              _buildModeSelector(context, session),
              const SizedBox(height: 12),
              _StatusBanner(session: session),
              const SizedBox(height: 12),
              Text(
                l10n.localizeWorkflowText('Current sentential form'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _SequenceChips(
                sequence: session.currentForm,
                highlightStart: _preview?.occurrence.startIndex,
                highlightLength: _preview?.production.left.length,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.localizeWorkflowText('Choose a production'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...widget.grammar.phraseProductions.map((production) {
                final matches = allApplications.where(
                  (application) => application.production.id == production.id,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Semantics(
                    button: true,
                    enabled: matches.isNotEmpty,
                    selected: production.id == _selectedProductionId,
                    child: ListTile(
                      key: ValueKey('manual-production-${production.id}'),
                      minTileHeight: 48,
                      selected: production.id == _selectedProductionId,
                      enabled: matches.isNotEmpty && session.isCurrent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      title: Text(
                        '${production.left} → ${production.right}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamilyFallback: kMonospaceFontFamilyFallback,
                        ),
                      ),
                      subtitle: Text(
                        matches.isEmpty
                            ? l10n.localizeWorkflowText(
                                'No matching occurrence',
                              )
                            : l10n.localizeWorkflowText(
                                '${matches.length} matching occurrence(s)',
                              ),
                      ),
                      onTap: matches.isEmpty || !session.isCurrent
                          ? null
                          : () => setState(() {
                              _selectedProductionId = production.id;
                              _preview = null;
                              _moveDiagnostic = null;
                            }),
                    ),
                  ),
                );
              }),
              if (_selectedProductionId != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.localizeWorkflowText('Choose the exact occurrence'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedApplications
                      .map(
                        (application) => ChoiceChip(
                          key: ValueKey(
                            'manual-occurrence-${application.production.id}-'
                            '${application.occurrence.startIndex}',
                          ),
                          selected:
                              _preview?.production.id ==
                                  application.production.id &&
                              _preview?.occurrence.startIndex ==
                                  application.occurrence.startIndex,
                          label: Text(
                            l10n.localizeWorkflowText(
                              'Position ${formatter.integer(application.occurrence.startIndex + 1)}',
                            ),
                          ),
                          onSelected: session.isCurrent
                              ? (_) => _selectOccurrence(application)
                              : null,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (_moveDiagnostic != null) ...[
                const SizedBox(height: 8),
                Text(
                  _diagnosticText(context, _moveDiagnostic!.code),
                  key: const ValueKey('manual-derivation-diagnostic'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_preview != null) ...[
                const SizedBox(height: 16),
                _buildPreview(context, _preview!),
              ],
              const SizedBox(height: 16),
              _buildHistoryControls(context, session),
              const SizedBox(height: 12),
              _buildHintControls(context, session),
              if (session.steps.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildHistory(context, session),
              ],
              if (tree != null) ...[
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      l10n.localizeWorkflowText('Current derivation tree'),
                    ),
                    children: [DerivationTreeView(tree: tree)],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    UserDerivationSession session,
  ) {
    final l10n = appLocalizationsOf(context);
    final baseModes = widget.grammar is UnrestrictedGrammar
        ? const [UserDerivationMode.unrestrictedOccurrence]
        : const [
            UserDerivationMode.leftmost,
            UserDerivationMode.rightmost,
            UserDerivationMode.unrestrictedOccurrence,
          ];
    final modes = widget.challenge == null
        ? baseModes
        : [...baseModes, UserDerivationMode.challengeEnforced];
    return DropdownButtonFormField<UserDerivationMode>(
      key: const ValueKey('manual-derivation-mode'),
      initialValue: _mode,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: l10n.localizeWorkflowText('Derivation mode'),
        helperText: session.cursor > 0
            ? l10n.localizeWorkflowText(
                'Restart before changing the derivation mode.',
              )
            : null,
      ),
      items: modes
          .map(
            (mode) => DropdownMenuItem(
              value: mode,
              child: Text(_modeText(context, mode)),
            ),
          )
          .toList(growable: false),
      onChanged: session.cursor > 0 || !session.isCurrent
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _mode = value;
                _startSession();
              });
            },
    );
  }

  Widget _buildPreview(BuildContext context, ProductionApplication preview) {
    final l10n = appLocalizationsOf(context);
    return Card(
      key: const ValueKey('manual-derivation-preview'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.localizeWorkflowText('Move preview'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _SequenceChips(
              sequence: preview.after,
              highlightStart: preview.occurrence.startIndex,
              highlightLength: preview.production.right.length,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('manual-derivation-commit'),
              onPressed: _commitPreview,
              icon: const Icon(Icons.check),
              label: Text(l10n.localizeWorkflowText('Apply this move')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryControls(
    BuildContext context,
    UserDerivationSession session,
  ) {
    final l10n = appLocalizationsOf(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('manual-derivation-undo'),
          onPressed: session.canUndo && session.isCurrent ? _undo : null,
          icon: const Icon(Icons.undo),
          label: Text(l10n.localizeWorkflowText('Undo move')),
        ),
        OutlinedButton.icon(
          key: const ValueKey('manual-derivation-redo'),
          onPressed: session.canRedo && session.isCurrent ? _redo : null,
          icon: const Icon(Icons.redo),
          label: Text(l10n.localizeWorkflowText('Redo move')),
        ),
        OutlinedButton.icon(
          key: const ValueKey('manual-derivation-restart'),
          onPressed: session.isCurrent ? _restart : widget.onInvalidatedRestart,
          icon: const Icon(Icons.restart_alt),
          label: Text(
            l10n.localizeWorkflowText(
              session.isCurrent ? 'Restart' : 'Start a new session',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHintControls(
    BuildContext context,
    UserDerivationSession session,
  ) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final hint = _hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('manual-derivation-hint'),
          onPressed: !session.isCurrent || session.isComplete
              ? null
              : _hintRunning
              ? _hintCancellationToken?.cancel
              : _requestHint,
          icon: Icon(_hintRunning ? Icons.stop : Icons.lightbulb_outline),
          label: Text(
            l10n.localizeWorkflowText(
              _hintRunning ? 'Cancel hint search' : 'Request bounded hint',
            ),
          ),
        ),
        if (_hintProgress case final progress?) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.localizeWorkflowText(
                'Hint search: ${formatter.integer(progress.statistics.expandedForms)} '
                'expanded, ${formatter.integer(progress.statistics.frontierSize)} '
                'queued',
              ),
            ),
          ),
        ],
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            _hintText(context, hint),
            key: const ValueKey('manual-derivation-hint-result'),
          ),
          if (hint.suggestion != null)
            TextButton.icon(
              onPressed: () => _selectOccurrence(hint.suggestion!),
              icon: const Icon(Icons.visibility),
              label: Text(l10n.localizeWorkflowText('Preview suggested move')),
            ),
        ],
      ],
    );
  }

  Widget _buildHistory(BuildContext context, UserDerivationSession session) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.localizeWorkflowText('Derivation history'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        for (var index = 0; index < session.steps.length; index++)
          ListTile(
            key: ValueKey('manual-derivation-step-${index + 1}'),
            dense: true,
            selected: index == session.cursor - 1,
            title: Text(
              '${formatter.integer(index + 1)}. '
              '${session.steps[index].productionId} @ '
              '${formatter.integer(session.steps[index].startIndex + 1)}',
            ),
            subtitle: Text(
              '${session.steps[index].before} → '
              '${session.steps[index].after}',
            ),
            trailing: TextButton(
              onPressed: session.isCurrent
                  ? () => _branchFrom(index + 1)
                  : null,
              child: Text(l10n.localizeWorkflowText('Branch here')),
            ),
          ),
      ],
    );
  }

  void _selectOccurrence(ProductionApplication application) {
    final session = _session!;
    final result = session.preview(
      grammar: widget.grammar,
      productionId: application.production.id,
      startIndex: application.occurrence.startIndex,
    );
    setState(() {
      _selectedProductionId = application.production.id;
      _preview = result.preview;
      _moveDiagnostic = result.diagnostics.firstOrNull;
    });
  }

  void _commitPreview() {
    final preview = _preview!;
    final result = _session!.apply(
      grammar: widget.grammar,
      productionId: preview.production.id,
      startIndex: preview.occurrence.startIndex,
    );
    _acceptCommand(result);
  }

  void _undo() => _acceptCommand(_session!.undo(widget.grammar));
  void _redo() => _acceptCommand(_session!.redo(widget.grammar));
  void _restart() => _acceptCommand(_session!.restart(widget.grammar));
  void _branchFrom(int index) =>
      _acceptCommand(_session!.branchFromStep(widget.grammar, index));

  void _acceptCommand(UserDerivationCommandResult result) {
    _hintCancellationToken?.cancel();
    setState(() {
      _session = result.session;
      _selectedProductionId = null;
      _preview = null;
      _moveDiagnostic = result.diagnostics.firstOrNull;
      _hint = null;
      _hintProgress = null;
      _hintRunning = false;
    });
    widget.onSessionChanged?.call(result.session);
  }

  Future<void> _requestHint() async {
    final token = UserDerivationHintCancellationToken();
    setState(() {
      _hintCancellationToken = token;
      _hintRunning = true;
      _hint = null;
      _hintProgress = null;
    });
    final result = await UserDerivationHintSearch.run(
      session: _session!,
      grammar: widget.grammar,
      cancellationToken: token,
      onProgress: (progress) {
        if (!mounted || !identical(token, _hintCancellationToken)) return;
        setState(() => _hintProgress = progress);
      },
    );
    if (!mounted || !identical(token, _hintCancellationToken)) return;
    setState(() {
      _hint = result;
      _hintRunning = false;
      _hintProgress = null;
      _hintCancellationToken = null;
    });
  }

  Future<void> _copyReport(BuildContext context) async {
    final report = <String, Object?>{
      ..._session!.toStructuredReport(),
      if (_hint != null) 'latestHint': _hint!.toJson(),
    };
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(report)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appLocalizationsOf(
            context,
          ).localizeWorkflowText('Structured derivation copied'),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.session});

  final UserDerivationSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final (icon, color, text) = switch (session.status) {
      UserDerivationStatus.active => (
        Icons.edit_outlined,
        Theme.of(context).colorScheme.primary,
        l10n.localizeWorkflowText('Choose the next derivation move.'),
      ),
      UserDerivationStatus.success => (
        Icons.check_circle,
        Theme.of(context).colorScheme.tertiary,
        l10n.localizeWorkflowText('Target reached'),
      ),
      UserDerivationStatus.localDeadEnd => (
        Icons.info,
        Theme.of(context).colorScheme.secondary,
        l10n.localizeWorkflowText(
          'Local dead end. This is not proof that the grammar cannot derive the target.',
        ),
      ),
      UserDerivationStatus.invalidated => (
        Icons.warning_amber,
        Theme.of(context).colorScheme.error,
        l10n.localizeWorkflowText(
          'The grammar or target changed. Start a new session.',
        ),
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _SequenceChips extends StatelessWidget {
  const _SequenceChips({
    required this.sequence,
    this.highlightStart,
    this.highlightLength,
  });

  final GrammarSymbolSequence sequence;
  final int? highlightStart;
  final int? highlightLength;

  @override
  Widget build(BuildContext context) {
    final symbols = sequence.isEmpty
        ? <PhraseGrammarSymbol>[
            TerminalGrammarSymbol(EmptyStringNotation.symbolOf(context)),
          ]
        : sequence.symbols;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(symbols.length, (index) {
        final start = highlightStart;
        final length = highlightLength ?? 0;
        final highlighted =
            start != null && index >= start && index < start + length;
        return Chip(
          backgroundColor: highlighted
              ? Theme.of(context).colorScheme.tertiaryContainer
              : symbols[index] is NonterminalGrammarSymbol
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
          label: Text(
            symbols[index].value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamilyFallback: kMonospaceFontFamilyFallback,
              fontWeight: highlighted ? FontWeight.w700 : null,
            ),
          ),
        );
      }),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
  );
}

String _modeText(BuildContext context, UserDerivationMode mode) {
  final l10n = appLocalizationsOf(context);
  return l10n.localizeWorkflowText(switch (mode) {
    UserDerivationMode.leftmost => 'Leftmost',
    UserDerivationMode.rightmost => 'Rightmost',
    UserDerivationMode.unrestrictedOccurrence => 'Any occurrence',
    UserDerivationMode.challengeEnforced => 'Challenge rules',
  });
}

String _diagnosticText(
  BuildContext context,
  UserDerivationDiagnosticCode? code,
) {
  final source = switch (code) {
    UserDerivationDiagnosticCode.invalidGrammar => 'The grammar is invalid.',
    UserDerivationDiagnosticCode.invalidTarget => 'The target is invalid.',
    UserDerivationDiagnosticCode.incompatibleMode =>
      'This derivation mode is not available for the grammar.',
    UserDerivationDiagnosticCode.missingChallenge =>
      'Challenge rules are missing.',
    UserDerivationDiagnosticCode.sourceChanged => 'The source grammar changed.',
    UserDerivationDiagnosticCode.targetChanged => 'The target changed.',
    UserDerivationDiagnosticCode.sessionComplete =>
      'The derivation is already complete.',
    UserDerivationDiagnosticCode.productionMissing =>
      'The selected production no longer exists.',
    UserDerivationDiagnosticCode.occurrenceDoesNotMatch =>
      'The production does not match at that token position.',
    UserDerivationDiagnosticCode.occurrenceRestricted =>
      'That occurrence is not allowed by the selected derivation mode.',
    UserDerivationDiagnosticCode.challengeProductionRestricted =>
      'Challenge rules do not allow that production.',
    UserDerivationDiagnosticCode.challengeStepLimit =>
      'The challenge step limit was reached.',
    UserDerivationDiagnosticCode.terminalMismatch =>
      'This terminal form differs from the target.',
    UserDerivationDiagnosticCode.noAvailableProduction =>
      'No production applies to the current form.',
    UserDerivationDiagnosticCode.invalidHistoryIndex =>
      'That history position is unavailable.',
    UserDerivationDiagnosticCode.invalidPayload =>
      'The saved derivation session is malformed.',
    UserDerivationDiagnosticCode.unsupportedSchema =>
      'The saved derivation session version is unsupported.',
    null => 'Unable to start the derivation session.',
  };
  return appLocalizationsOf(context).localizeWorkflowText(source);
}

String _hintText(BuildContext context, UserDerivationHintResult hint) {
  final formatter = LocaleValueFormatter.of(context);
  final source = switch (hint.outcome) {
    UserDerivationHintOutcome.suggested =>
      'Search-derived suggestion: apply ${hint.suggestion!.production.id} at '
          'position ${formatter.integer(hint.suggestion!.occurrence.startIndex + 1)}.',
    UserDerivationHintOutcome.noSuggestion =>
      'No hint was found. This is not a global non-membership claim.',
    UserDerivationHintOutcome.boundedUnknown =>
      'Hint search reached the ${hint.limit?.name ?? 'resource'} limit. The result is inconclusive.',
    UserDerivationHintOutcome.cancelled => 'Hint search was cancelled.',
    UserDerivationHintOutcome.invalidSession =>
      'Hint search cannot run on this session.',
  };
  return appLocalizationsOf(context).localizeWorkflowText(source);
}
