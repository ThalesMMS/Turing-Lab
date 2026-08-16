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

import '../../../l10n/app_localizations_resolver.dart';
import 'transition_editor_actions.dart';

class TransitionLabelEditorForm extends StatefulWidget {
  const TransitionLabelEditorForm({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    required this.onCancel,
    this.onDelete,
    this.autofocus = false,
    this.touchOptimized = false,
    this.fieldLabel,
    this.cancelLabel,
    this.deleteLabel,
    this.saveLabel,
    this.semanticLabel,
  });

  final String initialValue;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;
  final bool autofocus;
  final bool touchOptimized;
  final String? fieldLabel;
  final String? cancelLabel;
  final String? deleteLabel;
  final String? saveLabel;
  final String? semanticLabel;

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
    final l10n = appLocalizationsOf(context);
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
            label: widget.semanticLabel ?? l10n.transitionEditLabelSemantics,
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
                      labelText: widget.fieldLabel ?? l10n.transitionLabel,
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
                TransitionEditorActions(
                  onCancel: _handleCancel,
                  onDelete: widget.onDelete == null ? null : _handleDelete,
                  onSave: _handleSubmit,
                  cancelLabel: widget.cancelLabel,
                  deleteLabel: widget.deleteLabel,
                  saveLabel: widget.saveLabel,
                  baseFocusOrder: 1,
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
