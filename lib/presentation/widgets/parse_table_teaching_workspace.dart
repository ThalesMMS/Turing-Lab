import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/algorithms/grammar_analyzer.dart';
import '../../core/grammar/teaching/grammar_teaching_sessions.dart';
import '../../core/grammar/teaching/grammar_teaching_content.dart';
import '../../core/grammar/teaching/grammar_teaching_session_store.dart';
import '../../core/models/grammar.dart';
import '../../core/models/lr1_models.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../content/grammar_teaching_content_copy.dart';

class ParseTableTeachingWorkspace extends StatefulWidget {
  static final ll1ContentReference = GrammarTeachingContent.parseTableLl1;
  static final lr1ContentReference = GrammarTeachingContent.parseTableLr1;

  factory ParseTableTeachingWorkspace.ll1({
    Key? key,
    required Grammar grammar,
    required LL1ParseTable table,
    GrammarTeachingSessionStore? store,
  }) {
    return ParseTableTeachingWorkspace._(
      key: key,
      initialSession:
          store?.loadLl1(grammar, table) ??
          ParseTableTeachingSession.fromLl1(grammar, table),
      store: store,
    );
  }

  factory ParseTableTeachingWorkspace.lr1({
    Key? key,
    required Grammar grammar,
    required LR1Construction construction,
    GrammarTeachingSessionStore? store,
  }) {
    return ParseTableTeachingWorkspace._(
      key: key,
      initialSession:
          store?.loadLr1(grammar, construction) ??
          ParseTableTeachingSession.fromLr1(grammar, construction),
      store: store,
    );
  }

  const ParseTableTeachingWorkspace._({
    super.key,
    required this.initialSession,
    this.store,
  });

  final ParseTableTeachingSession initialSession;
  final GrammarTeachingSessionStore? store;

  @override
  State<ParseTableTeachingWorkspace> createState() =>
      _ParseTableTeachingWorkspaceState();
}

class _ParseTableTeachingWorkspaceState
    extends State<ParseTableTeachingWorkspace> {
  late ParseTableTeachingSession _session;
  bool _teachingMode = false;
  bool _showReference = true;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
  }

  @override
  void didUpdateWidget(covariant ParseTableTeachingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSession.sourceGrammarId !=
            widget.initialSession.sourceGrammarId ||
        oldWidget.initialSession.sourceRevision !=
            widget.initialSession.sourceRevision ||
        oldWidget.initialSession.kind != widget.initialSession.kind) {
      _session = widget.initialSession;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLocalizationsOf(context);
    final references = _session.references.values.toList()
      ..sort((left, right) {
        final section = left.section.compareTo(right.section);
        if (section != 0) return section;
        final row = left.row.compareTo(right.row);
        return row != 0 ? row : left.column.compareTo(right.column);
      });
    final focusReference = references.firstOrNull;
    final content = GrammarTeachingContentCopies.resolve(
      reference: _session.contentReference,
      languageCode: Localizations.localeOf(context).languageCode,
      arguments: {
        'row': focusReference?.row,
        'column': focusReference?.column,
        'alternatives':
            focusReference?.alternatives.map((item) => item.id).toList() ??
            const <String>[],
      },
    );
    return FocusTraversalGroup(
      child: Semantics(
        container: true,
        label: strings.localizeWorkflowText(
          'Editable parse-table teaching workspace',
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
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  key: const ValueKey('parse-table-teaching-mode'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.localizeWorkflowText('Teaching mode')),
                  subtitle: Text(
                    strings.localizeWorkflowText(
                      'Edit your table without changing the generated reference.',
                    ),
                  ),
                  value: _teachingMode,
                  onChanged: (value) => setState(() => _teachingMode = value),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton.outlined(
                      key: const ValueKey('undo-parse-table-edit'),
                      tooltip: strings.localizeWorkflowText('Undo'),
                      onPressed: _teachingMode && _session.canUndo
                          ? () => _apply(_session.undo())
                          : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton.outlined(
                      key: const ValueKey('redo-parse-table-edit'),
                      tooltip: strings.localizeWorkflowText('Redo'),
                      onPressed: _teachingMode && _session.canRedo
                          ? () => _apply(_session.redo())
                          : null,
                      icon: const Icon(Icons.redo),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showReference = !_showReference),
                      icon: Icon(
                        _showReference ? Icons.visibility_off : Icons.compare,
                      ),
                      label: Text(
                        strings.localizeWorkflowText(
                          _showReference
                              ? 'Hide generated answers'
                              : 'Show generated answers',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  strings.localizeWorkflowText(
                    'Type a production ID, shift/reduce action, or GOTO state. Conflict cells offer every generated action.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth < 600
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final reference in references)
                          SizedBox(
                            width: width,
                            child: _TeachingCell(
                              key: ValueKey('teaching-cell-${reference.key}'),
                              reference: reference,
                              draft: _session.draftFor(reference.key),
                              diagnostic: _session.validationFor(reference.key),
                              teachingMode: _teachingMode,
                              showReference: _showReference,
                              onChanged: (value) => _apply(
                                _session.editCell(reference.key, value),
                              ),
                              onAlternative: (id) => _apply(
                                _session.chooseAlternative(reference.key, id),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _apply(ParseTableTeachingSession next) {
    setState(() => _session = next);
    unawaited(widget.store?.saveParseTable(_session));
  }
}

class _TeachingCell extends StatefulWidget {
  const _TeachingCell({
    super.key,
    required this.reference,
    required this.draft,
    required this.diagnostic,
    required this.teachingMode,
    required this.showReference,
    required this.onChanged,
    required this.onAlternative,
  });

  final ParseTableTeachingCellReference reference;
  final String draft;
  final ParseTableTeachingDiagnostic diagnostic;
  final bool teachingMode;
  final bool showReference;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onAlternative;

  @override
  State<_TeachingCell> createState() => _TeachingCellState();
}

class _TeachingCellState extends State<_TeachingCell> {
  late final TextEditingController _controller;

  ParseTableTeachingCellReference get reference => widget.reference;
  String get draft => widget.draft;
  ParseTableTeachingDiagnostic get diagnostic => widget.diagnostic;
  bool get teachingMode => widget.teachingMode;
  bool get showReference => widget.showReference;
  ValueChanged<String> get onChanged => widget.onChanged;
  ValueChanged<String> get onAlternative => widget.onAlternative;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: draft);
  }

  @override
  void didUpdateWidget(covariant _TeachingCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft != draft && _controller.text != draft) {
      _controller.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLocalizationsOf(context);
    final valid =
        diagnostic.code != ParseTableTeachingDiagnosticCode.incorrectEntry;
    return Semantics(
      container: true,
      label:
          '${reference.section} ${reference.row}, ${reference.column} '
          '${strings.localizeWorkflowText('table cell')}',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: reference.hasConflict
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${reference.section} [${reference.row}, ${reference.column}]',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (reference.hasConflict)
              Text(
                strings.localizeWorkflowText(
                  'Conflict. Choose the action you want to test.',
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('parse-table-input-${reference.key}'),
              controller: _controller,
              enabled: teachingMode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: strings.localizeWorkflowText('Your entry'),
                suffixIcon: draft.isEmpty
                    ? null
                    : Icon(
                        valid ? Icons.check_circle : Icons.error_outline,
                        color: valid
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
              ),
              onChanged: onChanged,
            ),
            if (teachingMode && reference.hasConflict) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final alternative in reference.alternatives)
                    ChoiceChip(
                      key: ValueKey(
                        'parse-conflict-${reference.key}-${alternative.id}',
                      ),
                      label: Text(alternative.display),
                      selected:
                          draft == alternative.id ||
                          draft == alternative.display,
                      onSelected: (_) => onAlternative(alternative.id),
                    ),
                ],
              ),
            ],
            if (_shouldAnnounce(draft)) ...[
              const SizedBox(height: 6),
              Semantics(
                liveRegion: true,
                child: Text(
                  strings.localizeWorkflowText(_diagnosticLabel(diagnostic)),
                  key: ValueKey('parse-table-result-${reference.key}'),
                ),
              ),
            ],
            if (showReference) ...[
              const Divider(),
              Semantics(
                readOnly: true,
                label:
                    '${strings.localizeWorkflowText('Generated answer for')} '
                    '${reference.row}, ${reference.column}',
                child: Text(
                  '${strings.localizeWorkflowText('Generated, read only')}: '
                  '${reference.alternatives.isEmpty ? '∅' : reference.alternatives.map((item) => item.display).join(' / ')}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldAnnounce(String value) =>
      value.isNotEmpty || reference.alternatives.isEmpty;

  static String _diagnosticLabel(
    ParseTableTeachingDiagnostic diagnostic,
  ) => switch (diagnostic.code) {
    ParseTableTeachingDiagnosticCode.validEquivalent => 'Correct entry.',
    ParseTableTeachingDiagnosticCode.validConflictChoice =>
      'Valid conflict choice. The other generated actions remain unchanged.',
    ParseTableTeachingDiagnosticCode.validEmpty =>
      'This generated cell is empty.',
    ParseTableTeachingDiagnosticCode.incorrectEntry =>
      'This entry does not match a generated action.',
    ParseTableTeachingDiagnosticCode.sourceChanged =>
      'The source grammar changed.',
    ParseTableTeachingDiagnosticCode.invalidPayload =>
      'The saved table exercise could not be restored.',
  };
}
