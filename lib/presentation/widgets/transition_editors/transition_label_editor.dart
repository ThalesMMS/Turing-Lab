//
//  transition_label_editor.dart
//  Turing Lab
//
//  Creates accessible form to adjust transition labels with keyboard support, touch buttons and standard shortcuts. Encapsulates submission, cancellation and accessibility semantics logic to be reused in various editing flows.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransitionLabelEditorForm extends StatefulWidget {
  const TransitionLabelEditorForm({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    required this.onCancel,
    this.onDelete,
    this.autofocus = false,
    this.touchOptimized = false,
    this.fieldLabel = 'Label',
    this.cancelLabel = 'Cancel',
    this.deleteLabel = 'Delete',
    this.saveLabel = 'Save',
    this.semanticLabel = 'Edit transition label',
  });

  final String initialValue;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;
  final bool autofocus;
  final bool touchOptimized;
  final String fieldLabel;
  final String cancelLabel;
  final String deleteLabel;
  final String saveLabel;
  final String semanticLabel;

  @override
  State<TransitionLabelEditorForm> createState() =>
      _TransitionLabelEditorFormState();
}

class _TransitionLabelEditorFormState extends State<TransitionLabelEditorForm> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onSubmit(_controller.text.trim());
  }

  void _handleCancel() {
    widget.onCancel();
  }

  void _handleDelete() {
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.enter): const _SubmitIntent(),
      LogicalKeySet(LogicalKeyboardKey.numpadEnter): const _SubmitIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): const _CancelIntent(),
    };

    return Shortcuts(
      shortcuts: shortcuts,
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
              _handleCancel();
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              _handleCancel();
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Semantics(
            container: true,
            label: widget.semanticLabel,
            explicitChildNodes: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(0.0),
                  child: TextField(
                    controller: _controller,
                    autofocus: widget.autofocus,
                    decoration: InputDecoration(
                      labelText: widget.fieldLabel,
                      border: const OutlineInputBorder(),
                    ),
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                SizedBox(height: widget.touchOptimized ? 16 : 8),
                if (widget.touchOptimized)
                  Row(
                    children: [
                      Expanded(
                        child: FocusTraversalOrder(
                          order: NumericFocusOrder(
                            widget.onDelete != null ? 2.0 : 1.0,
                          ),
                          child: OutlinedButton(
                            onPressed: _handleCancel,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Text(widget.cancelLabel),
                          ),
                        ),
                      ),
                      if (widget.onDelete != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FocusTraversalOrder(
                            order: const NumericFocusOrder(1.0),
                            child: OutlinedButton(
                              onPressed: _handleDelete,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              child: Text(widget.deleteLabel),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        child: FocusTraversalOrder(
                          order: NumericFocusOrder(
                            widget.onDelete != null ? 3.0 : 2.0,
                          ),
                          child: FilledButton(
                            onPressed: _handleSubmit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Text(widget.saveLabel),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      if (widget.onDelete != null)
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(1.0),
                          child: TextButton(
                            onPressed: _handleDelete,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                            ),
                            child: Text(
                              widget.deleteLabel,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      FocusTraversalOrder(
                        order: NumericFocusOrder(
                          widget.onDelete != null ? 2.0 : 1.0,
                        ),
                        child: TextButton(
                          onPressed: _handleCancel,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          child: Text(widget.cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FocusTraversalOrder(
                        order: NumericFocusOrder(
                          widget.onDelete != null ? 3.0 : 2.0,
                        ),
                        child: FilledButton(
                          onPressed: _handleSubmit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          child: Text(widget.saveLabel),
                        ),
                      ),
                    ],
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
