import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/grammar.dart';
import '../../core/grammar/teaching/grammar_teaching_content.dart';
import '../../core/grammar/teaching/grammar_teaching_session_store.dart';
import '../../core/models/lr1_models.dart';
import '../../core/models/production.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../empty_string_notation.dart';
import '../content/grammar_teaching_content_copy.dart';
import 'derivation_tree_view.dart';
import 'parse_table_teaching_workspace.dart';

class LR1TeachingWorkspace extends StatefulWidget {
  const LR1TeachingWorkspace({
    super.key,
    required this.grammar,
    required this.construction,
    required this.parseResult,
    this.sessionStore,
  });

  final Grammar grammar;
  static final contentReference = GrammarTeachingContent.lr1Construction;
  final LR1Construction construction;
  final LR1ParseResult parseResult;
  final GrammarTeachingSessionStore? sessionStore;

  @override
  State<LR1TeachingWorkspace> createState() => _LR1TeachingWorkspaceState();
}

class _LR1TeachingWorkspaceState extends State<LR1TeachingWorkspace> {
  int _selectedState = 0;
  int _selectedStep = 0;
  ({int state, String symbol})? _selectedCell;
  Timer? _playbackTimer;

  List<LR1ParseStep> get _steps => widget.parseResult.steps;

  @override
  void didUpdateWidget(covariant LR1TeachingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.construction, widget.construction) ||
        !identical(oldWidget.parseResult, widget.parseResult)) {
      _stopPlayback();
      _selectedState = 0;
      _selectedStep = 0;
      _selectedCell = null;
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCell = _selectedCell;
    final content = GrammarTeachingContentCopies.resolve(
      reference: LR1TeachingWorkspace.contentReference,
      languageCode: Localizations.localeOf(context).languageCode,
      arguments: {
        'state': widget.construction.states[_selectedState].id,
        'lookahead': selectedCell?.symbol,
        'actions': selectedCell == null
            ? const <String>[]
            : widget.construction.table
                  .actionsAt(selectedCell.state, selectedCell.symbol)
                  .map((action) => action.stableKey)
                  .toList(),
        'conflicts': widget.construction.table.conflicts.length,
      },
    );
    return FocusTraversalGroup(
      child: Semantics(
        container: true,
        label: content.title,
        hint: content.accessibleDescription,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(content.instruction),
            const SizedBox(height: 12),
            _sectionTitle(context, 'Canonical collection', Icons.hub_outlined),
            const SizedBox(height: 8),
            _buildStateSelector(context, content),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final state = widget.construction.states[_selectedState];
                final panels = <Widget>[
                  _buildGrammar(context),
                  _buildItemSet(context, state),
                ];
                if (constraints.maxWidth >= 840) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: panels[0]),
                      const SizedBox(width: 12),
                      Expanded(child: panels[1]),
                    ],
                  );
                }
                return Column(
                  children: [panels[0], const SizedBox(height: 12), panels[1]],
                );
              },
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'ACTION / GOTO table', Icons.table_chart),
            const SizedBox(height: 8),
            _buildParseTable(context),
            const SizedBox(height: 12),
            ParseTableTeachingWorkspace.lr1(
              grammar: widget.grammar,
              construction: widget.construction,
              store: widget.sessionStore,
            ),
            if (widget.construction.table.conflicts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildConflicts(context),
            ],
            if (_steps.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle(
                context,
                'Shift-reduce execution',
                Icons.format_list_numbered,
              ),
              const SizedBox(height: 8),
              _buildPlayback(context),
              const SizedBox(height: 8),
              _buildStep(context, _steps[_selectedStep]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            appLocalizationsOf(context).localizeWorkflowText(text),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildStateSelector(
    BuildContext context,
    GrammarTeachingContentCopy content,
  ) {
    return Semantics(
      container: true,
      label: content.accessibleDescription,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final state in widget.construction.states)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  key: ValueKey('lr1-state-${state.index}'),
                  label: Text(state.id),
                  selected: state.index == _selectedState,
                  onSelected: (_) => _selectState(state.index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammar(BuildContext context) {
    final selectedProduction = _steps.isEmpty
        ? null
        : _steps[_selectedStep].reducedProductionId;
    final productions = widget.grammar.productions.toList()
      ..sort(_compareProductions);
    return _outlinedPanel(
      context,
      title: 'Grammar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.construction.augmentedProduction.leftSide.single} → '
            '${widget.grammar.startSymbol}',
          ),
          const Divider(),
          for (final production in productions)
            Container(
              key: ValueKey('lr1-production-${production.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: production.id == selectedProduction
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.7)
                    : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _productionDisplay(
                  production,
                  EmptyStringNotation.symbolOf(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemSet(BuildContext context, LR1State state) {
    final l10n = appLocalizationsOf(context);
    final outgoing =
        widget.construction.transitions
            .where((transition) => transition.fromState == state.index)
            .toList()
          ..sort((a, b) => a.symbol.compareTo(b.symbol));
    return _outlinedPanel(
      context,
      title:
          '${state.id} · viable prefix: '
          '${state.viablePrefix.isEmpty ? EmptyStringNotation.symbolOf(context) : state.viablePrefix.join(' ')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in state.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: SelectableText(item.display),
            ),
          if (outgoing.isNotEmpty) ...[
            const Divider(),
            Text(
              appLocalizationsOf(context).localizeWorkflowText('Transitions'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final transition in outgoing)
                  ActionChip(
                    tooltip: l10n.localizeWorkflowText(
                      '${transition.sourceItems.length} source item(s)',
                    ),
                    label: Text(
                      '${transition.symbol} → I${transition.toState}',
                    ),
                    onPressed: () => _selectState(transition.toState),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParseTable(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final terminals = widget.construction.table.terminals.toList()..sort();
    final nonTerminals = widget.construction.table.nonTerminals.toList()
      ..sort();
    return Semantics(
      label: l10n.localizeWorkflowText('Canonical LR(1) ACTION and GOTO table'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          key: const ValueKey('lr1-parse-table'),
          headingRowHeight: 48,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 64,
          columns: [
            DataColumn(label: Text(l10n.localizeWorkflowText('State'))),
            for (final terminal in terminals)
              DataColumn(
                label: Text(l10n.localizeWorkflowText('ACTION $terminal')),
              ),
            for (final nonTerminal in nonTerminals)
              DataColumn(
                label: Text(l10n.localizeWorkflowText('GOTO $nonTerminal')),
              ),
          ],
          rows: [
            for (final state in widget.construction.states)
              DataRow(
                selected: state.index == _selectedState,
                cells: [
                  DataCell(
                    Text(state.id),
                    onTap: () => _selectState(state.index),
                  ),
                  for (final terminal in terminals)
                    _actionCell(context, state.index, terminal),
                  for (final nonTerminal in nonTerminals)
                    _gotoCell(context, state.index, nonTerminal),
                ],
              ),
          ],
        ),
      ),
    );
  }

  DataCell _actionCell(BuildContext context, int state, String lookahead) {
    final l10n = appLocalizationsOf(context);
    final actions = widget.construction.table.actionsAt(state, lookahead);
    final selected =
        _selectedCell?.state == state && _selectedCell?.symbol == lookahead;
    return DataCell(
      Semantics(
        button: true,
        selected: selected,
        label: l10n.localizeWorkflowText(
          'ACTION I$state, $lookahead: '
          '${actions.isEmpty ? 'empty' : actions.map((a) => a.display).join(', ')}',
        ),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : actions.length > 1
              ? Theme.of(context).colorScheme.errorContainer
              : null,
          child: Text(actions.map((action) => action.display).join(' / ')),
        ),
      ),
      onTap: () => _selectCell(state, lookahead),
    );
  }

  DataCell _gotoCell(BuildContext context, int state, String nonTerminal) {
    final l10n = appLocalizationsOf(context);
    final target = widget.construction.table.gotoAt(state, nonTerminal);
    final sources = widget.construction.table.gotoSourceItemsAt(
      state,
      nonTerminal,
    );
    final selected =
        _selectedCell?.state == state && _selectedCell?.symbol == nonTerminal;
    return DataCell(
      Semantics(
        button: true,
        selected: selected,
        label: l10n.localizeWorkflowText(
          'GOTO I$state, $nonTerminal: ${target ?? 'empty'}',
        ),
        child: Tooltip(
          message: sources.isEmpty
              ? l10n.localizeWorkflowText('No source items')
              : sources.map((item) => item.display).join('\n'),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: Alignment.center,
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Text(target?.toString() ?? ''),
          ),
        ),
      ),
      onTap: () => _selectCell(state, nonTerminal),
    );
  }

  Widget _buildConflicts(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return _outlinedPanel(
      context,
      title: 'Conflicts (all actions preserved)',
      color: Theme.of(context).colorScheme.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final conflict in widget.construction.table.conflicts)
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 8,
                title: Text(
                  l10n.localizeWorkflowText(
                    '${conflict.kind == LR1ConflictKind.shiftReduce ? 'Shift/reduce' : 'Reduce/reduce'} '
                    'at [${conflict.stateId}, ${conflict.lookahead}]',
                  ),
                ),
                subtitle: Text(
                  l10n.localizeWorkflowText(
                    'Actions: ${conflict.actions.map((a) => a.display).join(', ')}\n'
                    'Witness prefix: ${conflict.viablePrefix.isEmpty ? EmptyStringNotation.symbolOf(context) : conflict.viablePrefix.join(' ')}\n'
                    'Sources: ${conflict.actions.expand((a) => a.sourceItems).map((i) => i.display).join(' · ')}',
                  ),
                ),
                onTap: () => _selectCell(conflict.state, conflict.lookahead),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayback(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final playing = _playbackTimer?.isActive ?? false;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.localizeWorkflowText('Reset execution'),
          onPressed: _selectedStep == 0 ? null : () => _selectStep(0),
          icon: const Icon(Icons.restart_alt),
        ),
        IconButton(
          tooltip: l10n.localizeWorkflowText('Previous step'),
          onPressed: _selectedStep == 0
              ? null
              : () => _selectStep(_selectedStep - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: l10n.localizeWorkflowText(
            playing ? 'Pause execution' : 'Play execution',
          ),
          onPressed: _steps.length < 2 ? null : _togglePlayback,
          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
        ),
        IconButton(
          tooltip: l10n.localizeWorkflowText('Next step'),
          onPressed: _selectedStep >= _steps.length - 1
              ? null
              : () => _selectStep(_selectedStep + 1),
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              l10n.localizeWorkflowText(
                'Step ${_selectedStep + 1} of ${_steps.length}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, LR1ParseStep step) {
    final l10n = appLocalizationsOf(context);
    return _outlinedPanel(
      context,
      title: l10n.localizeWorkflowText(step.action?.display ?? 'Diagnostic'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _detail(
            context,
            'State stack',
            _stack(step.stateStackBefore, step.stateStackAfter),
          ),
          _detail(
            context,
            'Symbol stack',
            _stack(step.symbolStackBefore, step.symbolStackAfter),
          ),
          _detail(context, 'Remaining input', step.remainingInput.join(' ')),
          _detail(
            context,
            'Lookup',
            '[I${step.lookupState}, ${step.lookahead}]',
          ),
          if (step.reducedProductionId != null)
            _detail(
              context,
              'Reduction',
              '${step.reducedProductionId} · pop ${step.popCount}',
            ),
          _detail(
            context,
            'Explanation',
            step.structuredMessage == null
                ? l10n.localizeWorkflowText(step.message)
                : l10n.resolveStructuredMessage(step.structuredMessage!),
          ),
          if (step.partialTree != null) ...[
            const SizedBox(height: 8),
            DerivationTreeView(tree: step.partialTree!),
          ],
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '${appLocalizationsOf(context).localizeWorkflowText(label)}: $value',
      ),
    );
  }

  Widget _outlinedPanel(
    BuildContext context, {
    required String title,
    required Widget child,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            appLocalizationsOf(context).localizeWorkflowText(title),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  void _selectState(int state) {
    _stopPlayback();
    setState(() => _selectedState = state);
  }

  void _selectCell(int state, String symbol) {
    _stopPlayback();
    final matchingStep = _steps.indexWhere(
      (step) => step.lookupState == state && step.lookahead == symbol,
    );
    setState(() {
      _selectedState = state;
      _selectedCell = (state: state, symbol: symbol);
      if (matchingStep >= 0) _selectedStep = matchingStep;
    });
  }

  void _selectStep(int index) {
    _stopPlayback();
    _applyStep(index);
  }

  void _applyStep(int index) {
    final step = _steps[index];
    setState(() {
      _selectedStep = index;
      _selectedState = step.lookupState;
      _selectedCell = (state: step.lookupState, symbol: step.lookahead);
    });
  }

  void _togglePlayback() {
    if (_playbackTimer?.isActive ?? false) {
      _stopPlayback();
      setState(() {});
      return;
    }
    if (_selectedStep >= _steps.length - 1) _applyStep(0);
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted || _selectedStep >= _steps.length - 1) {
        timer.cancel();
        if (mounted) setState(() {});
        return;
      }
      _applyStep(_selectedStep + 1);
    });
    setState(() {});
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  String _stack(List<Object> before, List<Object> after) =>
      '${before.join(' ')} → ${after.join(' ')}';

  static int _compareProductions(Production a, Production b) {
    final order = a.order.compareTo(b.order);
    return order != 0 ? order : a.id.compareTo(b.id);
  }

  static String _productionDisplay(
    Production production,
    String emptyStringSymbol,
  ) {
    final right = production.rightSide.isEmpty
        ? emptyStringSymbol
        : production.rightSide.join(' ');
    return '${production.id}: ${production.leftSide.join(' ')} → $right';
  }
}
