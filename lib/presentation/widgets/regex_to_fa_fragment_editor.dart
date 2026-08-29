import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/manual_conversions/manual_conversion_session.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart' as automaton;
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../../l10n/conversion_preview_localizations.dart';
import '../localization/locale_value_formatter.dart';
import '../localization/manual_conversion_localizations.dart';

/// A form-based finite-automaton editor for one Regex-to-FA requirement.
class RegexToFaFragmentEditor extends StatefulWidget {
  const RegexToFaFragmentEditor({
    super.key,
    required this.requirement,
    required this.onSubmit,
  });

  final ManualConversionRequirement requirement;
  final ValueChanged<Map<String, Object?>> onSubmit;

  @override
  State<RegexToFaFragmentEditor> createState() =>
      _RegexToFaFragmentEditorState();
}

class _RegexToFaFragmentEditorState extends State<RegexToFaFragmentEditor> {
  final List<_StateDraft> _states = [];
  final List<_TransitionDraft> _transitions = [];
  String? _statusMessage;

  Map<String, Object?> get _payload => widget.requirement.expectedPayload;

  Map<String, Object?> get _invariants =>
      Map<String, Object?>.from(_payload['invariants']! as Map);

  List<String> get _alphabet =>
      (_invariants['alphabet']! as List).cast<String>();

  String get _nodeId => _payload['nodeId']! as String;

  @override
  void didUpdateWidget(covariant RegexToFaFragmentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requirement.id != widget.requirement.id) {
      _states.clear();
      _transitions.clear();
      _statusMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInvariantCard(context),
        const SizedBox(height: 16),
        _buildSectionHeader(
          context,
          title: 'States',
          countLabel: _countLabel(
            context,
            _states.length,
            _invariants['stateCount'] as int,
          ),
          actionKey: const ValueKey('regex-fa-add-state'),
          actionLabel: 'Add state',
          actionIcon: Icons.add_circle_outline,
          onPressed: () => _editState(),
        ),
        const SizedBox(height: 8),
        if (_states.isEmpty)
          const _EmptyEditorMessage(
            icon: Icons.circle_outlined,
            message: 'Add states, then mark one entry state and any exits.',
          )
        else
          for (var index = 0; index < _states.length; index++)
            _buildStateCard(context, index),
        const SizedBox(height: 16),
        _buildSectionHeader(
          context,
          title: 'Transitions',
          countLabel: _countLabel(
            context,
            _transitions.length,
            _invariants['transitionCount'] as int,
          ),
          actionKey: const ValueKey('regex-fa-add-transition'),
          actionLabel: 'Add transition',
          actionIcon: Icons.add_link,
          onPressed: _states.isEmpty ? null : () => _editTransition(),
        ),
        const SizedBox(height: 8),
        if (_transitions.isEmpty)
          const _EmptyEditorMessage(
            icon: Icons.arrow_forward,
            message: 'No transitions in this fragment yet.',
          )
        else
          for (var index = 0; index < _transitions.length; index++)
            _buildTransitionCard(context, index),
        Semantics(
          liveRegion: true,
          container: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _statusMessage == null
                  ? ''
                  : l10n.localizeWorkflowText(_statusMessage!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const ValueKey('regex-fa-check-fragment'),
          onPressed: _submit,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(l10n.localizeWorkflowText('Check fragment')),
        ),
      ],
    );
  }

  Widget _buildInvariantCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appLocalizationsOf(context);
    final span = Map<String, Object?>.from(_payload['sourceSpan']! as Map);
    final acceptingCount = (_invariants['acceptingStateIds']! as List).length;
    final invariantSummary = l10n.manualConversionInvariantSummary(
      stateCount: _invariants['stateCount']! as int,
      transitionCount: _invariants['transitionCount']! as int,
      acceptingCount: acceptingCount,
      alphabet: _alphabet,
    );
    return Semantics(
      container: true,
      label: l10n.localizeWorkflowText(
        'Active syntax node and fragment invariant',
      ),
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.localizeWorkflowText('Active syntax node'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SelectableText(
                l10n.localizeWorkflowText(
                  '$_nodeId · ${_payload['nodeKind']} · source '
                  '[${span['start']}, ${span['end']})',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.localizeWorkflowText('Fragment invariant'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(invariantSummary),
              const SizedBox(height: 8),
              Text(
                l10n.localizeWorkflowText(
                  'State and transition IDs must be unique. New IDs include '
                  'the syntax-node ID to avoid sibling collisions.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String countLabel,
    required Key actionKey,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback? onPressed,
  }) {
    final l10n = appLocalizationsOf(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Semantics(
          header: true,
          child: Text(
            '${l10n.localizeWorkflowText(title)} · $countLabel',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        OutlinedButton.icon(
          key: actionKey,
          onPressed: onPressed,
          icon: Icon(actionIcon),
          label: Text(l10n.localizeWorkflowText(actionLabel)),
        ),
      ],
    );
  }

  Widget _buildStateCard(BuildContext context, int index) {
    final l10n = appLocalizationsOf(context);
    final state = _states[index];
    final roles = <String>[
      if (state.isInitial) l10n.localizeWorkflowText('entry'),
      if (state.isAccepting) l10n.localizeWorkflowText('accepting'),
    ];
    final roleText = roles.isEmpty
        ? l10n.localizeWorkflowText('ordinary')
        : roles.join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        container: true,
        label: l10n.localizeWorkflowText(
          'State ${state.label}, ID ${state.id}, $roleText',
        ),
        child: ListTile(
          title: Text(state.label),
          subtitle: SelectableText('${state.id} · $roleText'),
          leading: Icon(
            state.isAccepting
                ? Icons.adjust
                : state.isInitial
                ? Icons.play_circle_outline
                : Icons.circle_outlined,
          ),
          trailing: PopupMenuButton<_EditorAction>(
            tooltip: l10n.localizeWorkflowText(
              'State actions for ${state.label}',
            ),
            onSelected: (action) {
              switch (action) {
                case _EditorAction.edit:
                  _editState(index);
                case _EditorAction.remove:
                  _removeState(index);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _EditorAction.edit,
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.localizeWorkflowText('Edit state')),
                ),
              ),
              PopupMenuItem(
                value: _EditorAction.remove,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.localizeWorkflowText('Remove state')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransitionCard(BuildContext context, int index) {
    final l10n = appLocalizationsOf(context);
    final transition = _transitions[index];
    final label = transition.isEpsilon
        ? 'ε'
        : (transition.symbols.toList()..sort()).join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        container: true,
        label: l10n.localizeWorkflowText(
          'Transition ${transition.id}, from ${transition.fromStateId} '
          'to ${transition.toStateId}, input $label',
        ),
        child: ListTile(
          leading: const Icon(Icons.arrow_forward),
          title: Text('${transition.fromStateId} → ${transition.toStateId}'),
          subtitle: SelectableText('$label · ${transition.id}'),
          trailing: PopupMenuButton<_EditorAction>(
            tooltip: l10n.localizeWorkflowText(
              'Transition actions for ${transition.id}',
            ),
            onSelected: (action) {
              switch (action) {
                case _EditorAction.edit:
                  _editTransition(index);
                case _EditorAction.remove:
                  setState(() {
                    _transitions.removeAt(index);
                    _statusMessage = 'Transition removed.';
                  });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _EditorAction.edit,
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.localizeWorkflowText('Edit transition')),
                ),
              ),
              PopupMenuItem(
                value: _EditorAction.remove,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.localizeWorkflowText('Remove transition')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editState([int? index]) async {
    final existing = index == null ? null : _states[index];
    final nextNumber = _nextAvailableNumber(
      _states.map((state) => state.id),
      '${_safeNodeId}_s',
    );
    final draft = await showDialog<_StateDraft>(
      context: context,
      builder: (context) => _StateDraftDialog(
        isEditing: existing != null,
        initial:
            existing ??
            _StateDraft(
              id: '${_safeNodeId}_s$nextNumber',
              label: 'q$nextNumber',
              isInitial: _states.isEmpty,
              isAccepting: false,
            ),
        existingIds: {
          for (var stateIndex = 0; stateIndex < _states.length; stateIndex++)
            if (stateIndex != index) _states[stateIndex].id,
        },
      ),
    );
    if (draft == null || !mounted) return;
    setState(() {
      if (draft.isInitial) {
        for (var stateIndex = 0; stateIndex < _states.length; stateIndex++) {
          if (stateIndex != index) {
            _states[stateIndex] = _states[stateIndex].copyWith(
              isInitial: false,
            );
          }
        }
      }
      if (index == null) {
        _states.add(draft);
      } else {
        final previousId = _states[index].id;
        _states[index] = draft;
        if (previousId != draft.id) {
          for (
            var transitionIndex = 0;
            transitionIndex < _transitions.length;
            transitionIndex++
          ) {
            final transition = _transitions[transitionIndex];
            _transitions[transitionIndex] = transition.copyWith(
              fromStateId: transition.fromStateId == previousId
                  ? draft.id
                  : transition.fromStateId,
              toStateId: transition.toStateId == previousId
                  ? draft.id
                  : transition.toStateId,
            );
          }
        }
      }
      _statusMessage = index == null ? 'State added.' : 'State updated.';
    });
  }

  Future<void> _removeState(int index) async {
    final l10n = appLocalizationsOf(context);
    final state = _states[index];
    final connected = _transitions
        .where(
          (transition) =>
              transition.fromStateId == state.id ||
              transition.toStateId == state.id,
        )
        .length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.localizeWorkflowText('Remove state?')),
        content: Text(
          l10n.localizeWorkflowText(
            connected == 0
                ? 'Remove ${state.label} from this fragment?'
                : 'Remove ${state.label} and its $connected connected '
                      '${connected == 1 ? 'transition' : 'transitions'}?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.localizeWorkflowText('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.localizeWorkflowText('Remove state')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _states.removeAt(index);
      _transitions.removeWhere(
        (transition) =>
            transition.fromStateId == state.id ||
            transition.toStateId == state.id,
      );
      _statusMessage = 'State removed.';
    });
  }

  Future<void> _editTransition([int? index]) async {
    if (_states.isEmpty) {
      setState(
        () => _statusMessage = 'Add a state before adding a transition.',
      );
      return;
    }
    final existing = index == null ? null : _transitions[index];
    final nextNumber = _nextAvailableNumber(
      _transitions.map((transition) => transition.id),
      '${_safeNodeId}_t',
    );
    final draft = await showDialog<_TransitionDraft>(
      context: context,
      builder: (context) => _TransitionDraftDialog(
        isEditing: existing != null,
        initial:
            existing ??
            _TransitionDraft(
              id: '${_safeNodeId}_t$nextNumber',
              fromStateId: _states.first.id,
              toStateId: _states.first.id,
              symbols: const <String>{},
              isEpsilon: false,
            ),
        states: List<_StateDraft>.unmodifiable(_states),
        alphabet: _alphabet,
        existingIds: {
          for (
            var transitionIndex = 0;
            transitionIndex < _transitions.length;
            transitionIndex++
          )
            if (transitionIndex != index) _transitions[transitionIndex].id,
        },
      ),
    );
    if (draft == null || !mounted) return;
    setState(() {
      if (index == null) {
        _transitions.add(draft);
      } else {
        _transitions[index] = draft;
      }
      _statusMessage = index == null
          ? 'Transition added.'
          : 'Transition updated.';
    });
  }

  void _submit() {
    if (_states.isEmpty) {
      setState(() => _statusMessage = 'Add at least one state.');
      return;
    }
    final initialStates = _states.where((state) => state.isInitial).toList();
    if (initialStates.length != 1) {
      setState(() => _statusMessage = 'Mark exactly one entry state.');
      return;
    }
    final statesById = <String, automaton.State>{};
    for (var index = 0; index < _states.length; index++) {
      final draft = _states[index];
      statesById[draft.id] = automaton.State(
        id: draft.id,
        label: draft.label,
        position: Vector2(100 + (index % 4) * 140, 100 + (index ~/ 4) * 120),
        isInitial: draft.isInitial,
        isAccepting: draft.isAccepting,
      );
    }
    final transitions = <FSATransition>{
      for (final draft in _transitions)
        FSATransition(
          id: draft.id,
          fromState: statesById[draft.fromStateId]!,
          toState: statesById[draft.toStateId]!,
          inputSymbols: draft.isEpsilon ? const {} : draft.symbols,
          lambdaSymbol: draft.isEpsilon ? 'ε' : null,
        ),
    };
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final rows = (_states.length + 3) ~/ 4;
    final fsa = FSA(
      id: 'learner_${_safeNodeId}_fsa',
      name: 'Learner fragment for $_nodeId',
      states: statesById.values.toSet(),
      transitions: transitions,
      alphabet: _alphabet.toSet(),
      initialState: statesById[initialStates.single.id],
      acceptingStates: {
        for (final draft in _states)
          if (draft.isAccepting) statesById[draft.id]!,
      },
      created: epoch,
      modified: epoch,
      bounds: math.Rectangle<double>(
        0,
        0,
        math.max(320, math.min(4, _states.length) * 140 + 100),
        math.max(240, rows * 120 + 100),
      ),
    );
    widget.onSubmit({'fragment': fsa.toJson()});
  }

  String get _safeNodeId => _nodeId.replaceAll(RegExp('[^A-Za-z0-9_]'), '_');

  static int _nextAvailableNumber(Iterable<String> ids, String prefix) {
    final reserved = ids.toSet();
    var number = 0;
    while (reserved.contains('$prefix$number')) {
      number++;
    }
    return number;
  }

  static String _countLabel(BuildContext context, int actual, int expected) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final formattedActual = formatter.integer(actual);
    final formattedExpected = formatter.integer(expected);
    return l10n.conversionPreviewText(
      '$formattedActual of $formattedExpected expected',
      '$formattedActual de $formattedExpected esperados',
    );
  }
}

class _StateDraftDialog extends StatefulWidget {
  const _StateDraftDialog({
    required this.isEditing,
    required this.initial,
    required this.existingIds,
  });

  final bool isEditing;
  final _StateDraft initial;
  final Set<String> existingIds;

  @override
  State<_StateDraftDialog> createState() => _StateDraftDialogState();
}

class _StateDraftDialogState extends State<_StateDraftDialog> {
  late final TextEditingController _idController;
  late final TextEditingController _labelController;
  late bool _isInitial;
  late bool _isAccepting;
  String? _idError;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initial.id);
    _labelController = TextEditingController(text: widget.initial.label);
    _isInitial = widget.initial.isInitial;
    _isAccepting = widget.initial.isAccepting;
  }

  @override
  void dispose() {
    _idController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return AlertDialog(
      title: Text(
        l10n.localizeWorkflowText(
          widget.isEditing ? 'Edit state' : 'Add state',
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('regex-fa-state-id'),
              controller: _idController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.localizeWorkflowText('State ID'),
                helperText: l10n.localizeWorkflowText(
                  'Use a unique ID in this construction.',
                ),
                errorText: _idError == null
                    ? null
                    : l10n.localizeWorkflowText(_idError!),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_idError != null) setState(() => _idError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('regex-fa-state-label'),
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.localizeWorkflowText('Display label'),
                helperText: l10n.localizeWorkflowText(
                  'Shown in the automaton editor.',
                ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            CheckboxListTile(
              key: const ValueKey('regex-fa-state-initial'),
              value: _isInitial,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.localizeWorkflowText('Entry state')),
              subtitle: Text(
                l10n.localizeWorkflowText(
                  'The fragment must have exactly one.',
                ),
              ),
              onChanged: (value) => setState(() => _isInitial = value ?? false),
            ),
            CheckboxListTile(
              key: const ValueKey('regex-fa-state-accepting'),
              value: _isAccepting,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.localizeWorkflowText('Accepting state')),
              subtitle: Text(
                l10n.localizeWorkflowText('Marks an exit from this fragment.'),
              ),
              onChanged: (value) =>
                  setState(() => _isAccepting = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.localizeWorkflowText('Cancel')),
        ),
        FilledButton(
          key: const ValueKey('regex-fa-save-state'),
          onPressed: _save,
          child: Text(l10n.localizeWorkflowText('Save state')),
        ),
      ],
    );
  }

  void _save() {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      setState(() => _idError = 'Enter a state ID.');
      return;
    }
    if (widget.existingIds.contains(id)) {
      setState(() => _idError = 'Use a unique state ID.');
      return;
    }
    Navigator.of(context).pop(
      _StateDraft(
        id: id,
        label: _labelController.text.trim().isEmpty
            ? id
            : _labelController.text.trim(),
        isInitial: _isInitial,
        isAccepting: _isAccepting,
      ),
    );
  }
}

class _TransitionDraftDialog extends StatefulWidget {
  const _TransitionDraftDialog({
    required this.isEditing,
    required this.initial,
    required this.states,
    required this.alphabet,
    required this.existingIds,
  });

  final bool isEditing;
  final _TransitionDraft initial;
  final List<_StateDraft> states;
  final List<String> alphabet;
  final Set<String> existingIds;

  @override
  State<_TransitionDraftDialog> createState() => _TransitionDraftDialogState();
}

class _TransitionDraftDialogState extends State<_TransitionDraftDialog> {
  late final TextEditingController _idController;
  late String _fromStateId;
  late String _toStateId;
  late Set<String> _symbols;
  late bool _isEpsilon;
  String? _idError;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initial.id);
    _fromStateId = widget.initial.fromStateId;
    _toStateId = widget.initial.toStateId;
    _symbols = widget.initial.symbols.toSet();
    _isEpsilon = widget.initial.isEpsilon;
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return AlertDialog(
      title: Text(
        l10n.localizeWorkflowText(
          widget.isEditing ? 'Edit transition' : 'Add transition',
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('regex-fa-transition-id'),
              controller: _idController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.localizeWorkflowText('Transition ID'),
                helperText: l10n.localizeWorkflowText(
                  'Use a unique ID in this construction.',
                ),
                errorText: _idError == null
                    ? null
                    : l10n.localizeWorkflowText(_idError!),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_idError != null) setState(() => _idError = null);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('regex-fa-transition-from'),
              initialValue: _fromStateId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.localizeWorkflowText('From state'),
                border: const OutlineInputBorder(),
              ),
              items: _stateItems(context),
              onChanged: (value) {
                if (value != null) setState(() => _fromStateId = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('regex-fa-transition-to'),
              initialValue: _toStateId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.localizeWorkflowText('To state'),
                border: const OutlineInputBorder(),
              ),
              items: _stateItems(context),
              onChanged: (value) {
                if (value != null) setState(() => _toStateId = value);
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              key: const ValueKey('regex-fa-transition-epsilon'),
              value: _isEpsilon,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.localizeWorkflowText('Epsilon transition')),
              subtitle: Text(
                l10n.localizeWorkflowText('Consumes no input symbol.'),
              ),
              onChanged: (value) {
                setState(() {
                  _isEpsilon = value ?? false;
                  if (_isEpsilon) _symbols.clear();
                  _inputError = null;
                });
              },
            ),
            if (!_isEpsilon) ...[
              Text(
                l10n.localizeWorkflowText('Input symbols'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final symbol in widget.alphabet)
                    FilterChip(
                      key: ValueKey('regex-fa-symbol-$symbol'),
                      label: Text(symbol),
                      selected: _symbols.contains(symbol),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _symbols.add(symbol);
                          } else {
                            _symbols.remove(symbol);
                          }
                          _inputError = null;
                        });
                      },
                    ),
                ],
              ),
              if (_inputError case final error?) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.localizeWorkflowText(error),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.localizeWorkflowText('Cancel')),
        ),
        FilledButton(
          key: const ValueKey('regex-fa-save-transition'),
          onPressed: _save,
          child: Text(l10n.localizeWorkflowText('Save transition')),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _stateItems(BuildContext context) => [
    for (final state in widget.states)
      DropdownMenuItem(value: state.id, child: Text(state.label)),
  ];

  void _save() {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      setState(() => _idError = 'Enter a transition ID.');
      return;
    }
    if (widget.existingIds.contains(id)) {
      setState(() => _idError = 'Use a unique transition ID.');
      return;
    }
    if (!_isEpsilon && _symbols.isEmpty) {
      setState(() => _inputError = 'Choose an input symbol or epsilon.');
      return;
    }
    Navigator.of(context).pop(
      _TransitionDraft(
        id: id,
        fromStateId: _fromStateId,
        toStateId: _toStateId,
        symbols: _symbols,
        isEpsilon: _isEpsilon,
      ),
    );
  }
}

class _EmptyEditorMessage extends StatelessWidget {
  const _EmptyEditorMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                appLocalizationsOf(context).localizeWorkflowText(message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _EditorAction { edit, remove }

class _StateDraft {
  const _StateDraft({
    required this.id,
    required this.label,
    required this.isInitial,
    required this.isAccepting,
  });

  final String id;
  final String label;
  final bool isInitial;
  final bool isAccepting;

  _StateDraft copyWith({bool? isInitial}) => _StateDraft(
    id: id,
    label: label,
    isInitial: isInitial ?? this.isInitial,
    isAccepting: isAccepting,
  );
}

class _TransitionDraft {
  _TransitionDraft({
    required this.id,
    required this.fromStateId,
    required this.toStateId,
    required Set<String> symbols,
    required this.isEpsilon,
  }) : symbols = Set<String>.unmodifiable(symbols);

  final String id;
  final String fromStateId;
  final String toStateId;
  final Set<String> symbols;
  final bool isEpsilon;

  _TransitionDraft copyWith({String? fromStateId, String? toStateId}) =>
      _TransitionDraft(
        id: id,
        fromStateId: fromStateId ?? this.fromStateId,
        toStateId: toStateId ?? this.toStateId,
        symbols: symbols,
        isEpsilon: isEpsilon,
      );
}
