//
//  tm_transition_operations_editor.dart
//  Turing Lab
//
//  Edits one atomic read/write/move operation for every TM tape.
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/tm_transition.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../tm/direction_icon.dart';
import 'transition_editor_actions.dart';
import 'transition_editor_shell.dart';

typedef TmTransitionSubmit = void Function({
  required String readSymbol,
  required String writeSymbol,
  required TapeDirection direction,
});

typedef TmTransitionVectorSubmit = void Function({
  required List<String> readSymbols,
  required List<String> writeSymbols,
  required List<TapeDirection> directions,
});

class TmTransitionOperationsEditor extends StatefulWidget {
  TmTransitionOperationsEditor({
    super.key,
    String? initialRead,
    String? initialWrite,
    TapeDirection? initialDirection,
    Iterable<String>? initialReads,
    Iterable<String>? initialWrites,
    Iterable<TapeDirection>? initialDirections,
    int tapeCount = 1,
    this.onSubmit,
    this.onSubmitVectors,
    required this.onCancel,
    this.onDelete,
  })  : initialReads = List<String>.unmodifiable(
          initialReads ??
              List<String>.filled(tapeCount, initialRead ?? '',
                  growable: false),
        ),
        initialWrites = List<String>.unmodifiable(
          initialWrites ??
              List<String>.filled(
                tapeCount,
                initialWrite ?? '',
                growable: false,
              ),
        ),
        initialDirections = List<TapeDirection>.unmodifiable(
          initialDirections ??
              List<TapeDirection>.filled(
                tapeCount,
                initialDirection ?? TapeDirection.right,
                growable: false,
              ),
        ) {
    if (tapeCount < 1 ||
        this.initialReads.length != tapeCount ||
        this.initialWrites.length != tapeCount ||
        this.initialDirections.length != tapeCount) {
      throw ArgumentError('The editor requires one operation per tape.');
    }
    if (onSubmit == null && onSubmitVectors == null) {
      throw ArgumentError('A TM transition submit callback is required.');
    }
  }

  final List<String> initialReads;
  final List<String> initialWrites;
  final List<TapeDirection> initialDirections;
  final TmTransitionSubmit? onSubmit;
  final TmTransitionVectorSubmit? onSubmitVectors;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  int get tapeCount => initialReads.length;

  @override
  State<TmTransitionOperationsEditor> createState() =>
      _TmTransitionOperationsEditorState();
}

class _TmTransitionOperationsEditorState
    extends State<TmTransitionOperationsEditor> {
  late final List<TextEditingController> _readControllers = [
    for (final value in widget.initialReads) TextEditingController(text: value),
  ];
  late final List<TextEditingController> _writeControllers = [
    for (final value in widget.initialWrites)
      TextEditingController(text: value),
  ];
  late final List<TapeDirection> _directions =
      List<TapeDirection>.of(widget.initialDirections);
  bool _showValidationErrors = false;

  @override
  void dispose() {
    for (final controller in [..._readControllers, ..._writeControllers]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    final reads = _readControllers
        .map((controller) => controller.text.trim())
        .toList(growable: false);
    final writes = _writeControllers
        .map((controller) => controller.text.trim())
        .toList(growable: false);
    if (reads.any((symbol) => symbol.isEmpty) ||
        writes.any((symbol) => symbol.isEmpty)) {
      setState(() => _showValidationErrors = true);
      return;
    }
    widget.onSubmitVectors?.call(
      readSymbols: reads,
      writeSymbols: writes,
      directions: List<TapeDirection>.unmodifiable(_directions),
    );
    widget.onSubmit?.call(
      readSymbol: reads.first,
      writeSymbol: writes.first,
      direction: _directions.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _SubmitIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _SubmitIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
      },
      child: Actions(
        actions: {
          _SubmitIntent: CallbackAction<_SubmitIntent>(
            onInvoke: (_) {
              _handleSubmit();
              return null;
            },
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (_) {
              widget.onCancel();
              return null;
            },
          ),
        },
        child: TransitionEditorShell(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.72,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var tape = 0; tape < widget.tapeCount; tape++) ...[
                      if (widget.tapeCount > 1)
                        Semantics(
                          header: true,
                          child: Text(
                            '${appLocalizationsOf(context).traceTape} ${tape + 1}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      _buildTapeFields(context, tape),
                      if (tape + 1 < widget.tapeCount)
                        const Divider(height: 28),
                    ],
                    const SizedBox(height: 12),
                    TransitionEditorActions(
                      onCancel: widget.onCancel,
                      onDelete: widget.onDelete,
                      onSave: _handleSubmit,
                      baseFocusOrder: widget.tapeCount * 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapeFields(BuildContext context, int tape) {
    final l10n = appLocalizationsOf(context);
    final suffix = widget.tapeCount == 1 ? '' : ' ${tape + 1}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusTraversalOrder(
          order: NumericFocusOrder((tape * 3).toDouble()),
          child: TextField(
            key: ValueKey('tm-transition-read-$tape'),
            controller: _readControllers[tape],
            decoration: InputDecoration(
              labelText: '${l10n.tmReadSymbol}$suffix',
              border: const OutlineInputBorder(),
              errorText: _showValidationErrors &&
                      _readControllers[tape].text.trim().isEmpty
                  ? l10n.tmReadSymbolRequired
                  : null,
            ),
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            autofocus: tape == 0,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_showValidationErrors) setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        FocusTraversalOrder(
          order: NumericFocusOrder((tape * 3 + 1).toDouble()),
          child: TextField(
            key: ValueKey('tm-transition-write-$tape'),
            controller: _writeControllers[tape],
            decoration: InputDecoration(
              labelText: '${l10n.tmWriteSymbol}$suffix',
              border: const OutlineInputBorder(),
              errorText: _showValidationErrors &&
                      _writeControllers[tape].text.trim().isEmpty
                  ? l10n.tmWriteSymbolRequired
                  : null,
            ),
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_showValidationErrors) setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        FocusTraversalOrder(
          order: NumericFocusOrder((tape * 3 + 2).toDouble()),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '${l10n.tmDirection}$suffix',
              border: const OutlineInputBorder(),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<TapeDirection>(
                    value: _directions[tape],
                    items: [
                      for (final direction in TapeDirection.values)
                        DropdownMenuItem(
                          value: direction,
                          child: TMDirectionIndicator(direction: direction),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _directions[tape] = value);
                      }
                    },
                  ),
                ),
                TMDirectionSelector(
                  selected: _directions[tape],
                  onChanged: (value) {
                    setState(() => _directions[tape] = value);
                  },
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
