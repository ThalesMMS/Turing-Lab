//
//  tm_transition_operations_editor.dart
//  Turing Lab
//
//  Provides a compact form to edit Turing-machine transition reads,
//  writes, and direction. Keeps minimal field state, validates
//  submissions, and delivers the result via callback for contextual
//  editors.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/tm_transition.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../tm/direction_icon.dart';
import 'transition_editor_actions.dart';
import 'transition_editor_shell.dart';

class TmTransitionOperationsEditor extends StatefulWidget {
  const TmTransitionOperationsEditor({
    super.key,
    required this.initialRead,
    required this.initialWrite,
    required this.initialDirection,
    required this.onSubmit,
    required this.onCancel,
    this.onDelete,
  });

  final String initialRead;
  final String initialWrite;
  final TapeDirection initialDirection;
  final void Function({
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection direction,
  }) onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  State<TmTransitionOperationsEditor> createState() =>
      _TmTransitionOperationsEditorState();
}

class _TmTransitionOperationsEditorState
    extends State<TmTransitionOperationsEditor> {
  late final TextEditingController _readController = TextEditingController(
    text: widget.initialRead,
  );
  late final TextEditingController _writeController = TextEditingController(
    text: widget.initialWrite,
  );
  late TapeDirection _direction = widget.initialDirection;
  bool _showValidationErrors = false;

  @override
  void dispose() {
    _readController.dispose();
    _writeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final readSymbol = _readController.text.trim();
    final writeSymbol = _writeController.text.trim();
    if (readSymbol.isEmpty || writeSymbol.isEmpty) {
      setState(() {
        _showValidationErrors = true;
      });
      return;
    }
    widget.onSubmit(
      readSymbol: readSymbol,
      writeSymbol: writeSymbol,
      direction: _direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _SubmitIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _SubmitIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
      },
      child: Actions(
        actions: {
          _SubmitIntent: CallbackAction<_SubmitIntent>(
            onInvoke: (intent) {
              _handleSubmit();
              return null;
            },
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (intent) {
              widget.onCancel();
              return null;
            },
          ),
        },
        child: TransitionEditorShell(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(0.0),
                  child: TextField(
                    controller: _readController,
                    decoration: InputDecoration(
                      labelText: l10n.tmReadSymbol,
                      border: const OutlineInputBorder(),
                      errorText: _showValidationErrors &&
                              _readController.text.trim().isEmpty
                          ? l10n.tmReadSymbolRequired
                          : null,
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_showValidationErrors) {
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1.0),
                  child: TextField(
                    controller: _writeController,
                    decoration: InputDecoration(
                      labelText: l10n.tmWriteSymbol,
                      border: const OutlineInputBorder(),
                      errorText: _showValidationErrors &&
                              _writeController.text.trim().isEmpty
                          ? l10n.tmWriteSymbolRequired
                          : null,
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_showValidationErrors) {
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2.0),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.tmDirection,
                      border: const OutlineInputBorder(),
                    ),
                    child: Column(
                      children: [
                        DropdownButtonHideUnderline(
                          child: DropdownButton<TapeDirection>(
                            value: _direction,
                            items: TapeDirection.values
                                .map(
                                  (direction) => DropdownMenuItem(
                                    value: direction,
                                    child: TMDirectionIndicator(
                                      direction: direction,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _direction = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        TMDirectionSelector(
                          selected: _direction,
                          onChanged: (value) {
                            setState(() {
                              _direction = value;
                            });
                          },
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TransitionEditorActions(
                  onCancel: widget.onCancel,
                  onDelete: widget.onDelete,
                  onSave: _handleSubmit,
                  baseFocusOrder: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
