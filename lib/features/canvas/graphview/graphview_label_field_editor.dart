//
//  graphview_label_field_editor.dart
//  Turing Lab
//
//  Overlay widget that edits transition labels directly on GraphView,
//  coordinating focus, confirmation, and cancellation with the canvas. The
//  implementation manages FocusNode lifecycles and invokes the shared edit
//  form so the experience stays consistent.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../../presentation/widgets/transition_editors/transition_editor_shell.dart';
import '../../../presentation/widgets/transition_editors/transition_label_editor.dart';

/// Overlay editor used by the GraphView canvas to update transition labels.
class GraphViewLabelFieldEditor extends StatelessWidget {
  const GraphViewLabelFieldEditor({
    super.key,
    required this.initialValue,
    required this.onSubmit,
    required this.onCancel,
    this.onDelete,
  });

  final String initialValue;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return TransitionEditorShell(
      child: TransitionLabelEditorForm(
        initialValue: initialValue,
        onSubmit: onSubmit,
        onCancel: onCancel,
        onDelete: onDelete,
        autofocus: true,
        touchOptimized: true,
      ),
    );
  }
}
