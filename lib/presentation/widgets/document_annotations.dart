import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/annotations/annotations.dart';
import '../../core/formal_systems/formal_system_ids.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../providers/document_annotations_provider.dart';
import 'automaton_canvas_document_actions.dart';

typedef AnnotationAttachmentPositionResolver =
    Offset? Function(AnnotationAttachment attachment);

class CanvasDocumentAnnotationsLayer extends ConsumerStatefulWidget {
  const CanvasDocumentAnnotationsLayer({
    super.key,
    required this.systemKey,
    required this.documentId,
    required this.documentRevision,
    required this.worldToScreen,
    required this.screenToWorld,
    required this.viewportListenable,
    required this.resolveAttachmentPosition,
  });

  final FormalSystemKey systemKey;
  final String documentId;
  final String documentRevision;
  final Offset Function(Offset world) worldToScreen;
  final Offset Function(Offset screen) screenToWorld;
  final Listenable viewportListenable;
  final AnnotationAttachmentPositionResolver resolveAttachmentPosition;

  @override
  ConsumerState<CanvasDocumentAnnotationsLayer> createState() =>
      _CanvasDocumentAnnotationsLayerState();
}

class _CanvasDocumentAnnotationsLayerState
    extends ConsumerState<CanvasDocumentAnnotationsLayer> {
  final Map<String, Offset> _dragOffsets = {};
  final Map<String, Offset> _resizeOffsets = {};

  @override
  Widget build(BuildContext context) {
    final collection = annotationsForDocument(
      ref.watch(documentAnnotationsProvider),
      widget.systemKey,
      widget.documentId,
    );
    final annotations = collection?.annotations ?? const <DocumentAnnotation>[];
    return AnimatedBuilder(
      animation: widget.viewportListenable,
      builder: (context, _) => Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final annotation in annotations)
            _positionedAnnotation(annotation),
        ],
      ),
    );
  }

  Widget _positionedAnnotation(DocumentAnnotation annotation) {
    final resizeOffset = _resizeOffsets[annotation.id] ?? Offset.zero;
    final renderedAnnotation = resizeOffset == Offset.zero
        ? annotation
        : annotation.resized(
            width: annotation.width + resizeOffset.dx,
            height: annotation.height + resizeOffset.dy,
          );
    final attachmentPosition = annotation.attachment == null
        ? null
        : widget.resolveAttachmentPosition(annotation.attachment!);
    final worldPosition = attachmentPosition == null
        ? Offset(annotation.x, annotation.y)
        : attachmentPosition +
              Offset(
                annotation.attachment!.offsetX,
                annotation.attachment!.offsetY,
              );
    final screenPosition =
        widget.worldToScreen(worldPosition) +
        (_dragOffsets[annotation.id] ?? Offset.zero);
    return Positioned(
      key: ValueKey('canvas-annotation-${annotation.id}'),
      left: screenPosition.dx,
      top: screenPosition.dy,
      width: renderedAnnotation.width,
      height: renderedAnnotation.collapsed
          ? DocumentAnnotation.minimumHeight
          : renderedAnnotation.height,
      child: DocumentAnnotationCard(
        annotation: renderedAnnotation,
        attachmentResolved:
            annotation.attachment == null || attachmentPosition != null,
        onDragUpdate: (delta) {
          setState(() {
            _dragOffsets[annotation.id] =
                (_dragOffsets[annotation.id] ?? Offset.zero) + delta;
          });
        },
        onDragEnd: () => _finishDrag(annotation, worldPosition),
        onEdit: () => _edit(annotation),
        onDuplicate: () => ref
            .read(documentAnnotationsProvider.notifier)
            .duplicate(widget.systemKey, annotation.id),
        onToggleCollapsed: () => _update(
          annotation.copyWith(
            collapsed: !annotation.collapsed,
            updatedAt: DateTime.now().toUtc(),
          ),
        ),
        onDelete: () => _confirmDelete(annotation),
        onResize: (delta) {
          setState(() {
            _resizeOffsets[annotation.id] =
                (_resizeOffsets[annotation.id] ?? Offset.zero) + delta;
          });
        },
        onResizeEnd: () => _finishResize(annotation),
      ),
    );
  }

  void _finishDrag(DocumentAnnotation annotation, Offset worldPosition) {
    final delta = _dragOffsets.remove(annotation.id) ?? Offset.zero;
    if (delta == Offset.zero) {
      if (mounted) setState(() {});
      return;
    }
    final screenStart = widget.worldToScreen(worldPosition);
    final worldEnd = widget.screenToWorld(screenStart + delta);
    final worldDelta = worldEnd - worldPosition;
    final attachment = annotation.attachment;
    _update(
      attachment == null
          ? annotation.copyWith(
              x: annotation.x + worldDelta.dx,
              y: annotation.y + worldDelta.dy,
              updatedAt: DateTime.now().toUtc(),
            )
          : annotation.copyWith(
              attachment: attachment.copyWith(
                offsetX: attachment.offsetX + worldDelta.dx,
                offsetY: attachment.offsetY + worldDelta.dy,
              ),
              updatedAt: DateTime.now().toUtc(),
            ),
    );
  }

  void _finishResize(DocumentAnnotation annotation) {
    final delta = _resizeOffsets.remove(annotation.id) ?? Offset.zero;
    if (delta == Offset.zero) {
      if (mounted) setState(() {});
      return;
    }
    _update(
      annotation
          .resized(
            width: annotation.width + delta.dx,
            height: annotation.height + delta.dy,
          )
          .copyWith(updatedAt: DateTime.now().toUtc()),
    );
  }

  void _update(DocumentAnnotation annotation) {
    ref
        .read(documentAnnotationsProvider.notifier)
        .update(widget.systemKey, annotation);
  }

  Future<void> _edit(DocumentAnnotation annotation) async {
    final edited = await showDocumentAnnotationDialog(
      context,
      annotation: annotation,
    );
    if (edited != null && mounted) _update(edited);
  }

  Future<void> _confirmDelete(DocumentAnnotation annotation) async {
    final l10n = appLocalizationsOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.documentNoteDeleteTitle),
        content: Text(l10n.documentNoteDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref
          .read(documentAnnotationsProvider.notifier)
          .remove(widget.systemKey, annotation.id);
    }
  }
}

class DocumentAnnotationsMenuActionHost extends StatefulWidget {
  const DocumentAnnotationsMenuActionHost({
    super.key,
    required this.actionsController,
    required this.systemKey,
    required this.documentId,
    required this.documentRevision,
  });

  final AutomatonCanvasDocumentActionsController actionsController;
  final FormalSystemKey systemKey;
  final String documentId;
  final String documentRevision;

  @override
  State<DocumentAnnotationsMenuActionHost> createState() =>
      _DocumentAnnotationsMenuActionHostState();
}

class _DocumentAnnotationsMenuActionHostState
    extends State<DocumentAnnotationsMenuActionHost> {
  @override
  void initState() {
    super.initState();
    widget.actionsController.bindDocumentNotes(this, _showManager);
  }

  @override
  void didUpdateWidget(covariant DocumentAnnotationsMenuActionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actionsController != widget.actionsController) {
      oldWidget.actionsController.unbind(this);
      widget.actionsController.bindDocumentNotes(this, _showManager);
    }
  }

  @override
  void dispose() {
    widget.actionsController.unbind(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  void _showManager() {
    showDocumentAnnotationsManager(
      context,
      systemKey: widget.systemKey,
      documentId: widget.documentId,
      documentRevision: widget.documentRevision,
    );
  }
}

Future<void> showDocumentAnnotationsManager(
  BuildContext context, {
  required FormalSystemKey systemKey,
  required String documentId,
  required String documentRevision,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: DocumentAnnotationsPanel(
          systemKey: systemKey,
          documentId: documentId,
          documentRevision: documentRevision,
        ),
      ),
    ),
  );
}

class DocumentAnnotationCard extends StatelessWidget {
  const DocumentAnnotationCard({
    super.key,
    required this.annotation,
    required this.attachmentResolved,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onEdit,
    required this.onDuplicate,
    required this.onToggleCollapsed,
    required this.onDelete,
    required this.onResize,
    required this.onResizeEnd,
  });

  final DocumentAnnotation annotation;
  final bool attachmentResolved;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onResize;
  final VoidCallback onResizeEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final colors = Theme.of(context).colorScheme;
    final background = switch (annotation.styleRole) {
      AnnotationStyleRole.note => colors.tertiaryContainer,
      AnnotationStyleRole.information => colors.primaryContainer,
      AnnotationStyleRole.warning => colors.errorContainer,
      AnnotationStyleRole.question => colors.secondaryContainer,
      AnnotationStyleRole.todo => colors.surfaceContainerHighest,
    };
    final foreground = switch (annotation.styleRole) {
      AnnotationStyleRole.note => colors.onTertiaryContainer,
      AnnotationStyleRole.information => colors.onPrimaryContainer,
      AnnotationStyleRole.warning => colors.onErrorContainer,
      AnnotationStyleRole.question => colors.onSecondaryContainer,
      AnnotationStyleRole.todo => colors.onSurface,
    };
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): onEdit,
        const SingleActivator(LogicalKeyboardKey.delete): onDelete,
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            onDuplicate,
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            onToggleCollapsed,
      },
      child: Focus(
        child: Semantics(
          container: true,
          label: l10n.documentNoteSemantics(annotation.text),
          hint: l10n.documentNoteKeyboardHint,
          child: Material(
            color: background,
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (focusContext) => Listener(
                    onPointerDown: (_) => Focus.of(focusContext).requestFocus(),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) => onDragUpdate(details.delta),
                      onPanEnd: (_) => onDragEnd(),
                      onPanCancel: onDragEnd,
                      onDoubleTap: onEdit,
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(
                              attachmentResolved
                                  ? Icons.drag_indicator
                                  : Icons.link_off,
                              color: foreground,
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: annotation.collapsed
                                  ? l10n.documentNoteExpand
                                  : l10n.documentNoteCollapse,
                              onPressed: onToggleCollapsed,
                              icon: Icon(
                                annotation.collapsed
                                    ? Icons.expand_more
                                    : Icons.expand_less,
                                color: foreground,
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: l10n.documentNoteActions,
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    onEdit();
                                  case 'duplicate':
                                    onDuplicate();
                                  case 'delete':
                                    onDelete();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l10n.edit),
                                ),
                                PopupMenuItem(
                                  value: 'duplicate',
                                  child: Text(l10n.documentNoteDuplicate),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!annotation.collapsed)
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(12, 4, 20, 16),
                            child: _SafeAnnotationText(
                              text: annotation.text,
                              color: foreground,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Semantics(
                            label: l10n.documentNoteResize,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) => onResize(details.delta),
                              onPanEnd: (_) => onResizeEnd(),
                              onPanCancel: onResizeEnd,
                              child: SizedBox.square(
                                dimension: 44,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: foreground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DocumentAnnotationsPanel extends ConsumerStatefulWidget {
  const DocumentAnnotationsPanel({
    super.key,
    required this.systemKey,
    required this.documentId,
    required this.documentRevision,
  });

  final FormalSystemKey systemKey;
  final String documentId;
  final String documentRevision;

  @override
  ConsumerState<DocumentAnnotationsPanel> createState() =>
      _DocumentAnnotationsPanelState();
}

class DocumentAnnotationsSection extends StatelessWidget {
  const DocumentAnnotationsSection({
    super.key,
    required this.systemKey,
    required this.documentId,
    required this.documentRevision,
  });

  final FormalSystemKey systemKey;
  final String documentId;
  final String documentRevision;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.sticky_note_2_outlined),
        title: Text(l10n.documentNotesTitle),
        subtitle: Text(l10n.documentNotesDescription),
        children: [
          SizedBox(
            height: 420,
            child: DocumentAnnotationsPanel(
              systemKey: systemKey,
              documentId: documentId,
              documentRevision: documentRevision,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentAnnotationsPanelState
    extends ConsumerState<DocumentAnnotationsPanel> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final collection = annotationsForDocument(
      ref.watch(documentAnnotationsProvider),
      widget.systemKey,
      widget.documentId,
    );
    final annotations = collection?.search(_query) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.documentNotesTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: [
                  IconButton(
                    tooltip: l10n.documentNoteUndo,
                    onPressed:
                        ref
                            .read(documentAnnotationsProvider.notifier)
                            .canUndo(widget.systemKey)
                        ? () => ref
                              .read(documentAnnotationsProvider.notifier)
                              .undo(widget.systemKey)
                        : null,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: l10n.documentNoteRedo,
                    onPressed:
                        ref
                            .read(documentAnnotationsProvider.notifier)
                            .canRedo(widget.systemKey)
                        ? () => ref
                              .read(documentAnnotationsProvider.notifier)
                              .redo(widget.systemKey)
                        : null,
                    icon: const Icon(Icons.redo),
                  ),
                  FilledButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.documentNoteAdd),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              labelText: l10n.documentNoteSearch,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: annotations.isEmpty
              ? Center(child: Text(l10n.documentNoteNoMatches))
              : ListView.builder(
                  itemCount: annotations.length,
                  itemBuilder: (context, index) {
                    final annotation = annotations[index];
                    return ListTile(
                      leading: Icon(_styleIcon(annotation.styleRole)),
                      title: Text(
                        annotation.text.isEmpty
                            ? l10n.documentNoteEmpty
                            : annotation.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        annotation.attachment == null
                            ? l10n.documentNoteFree
                            : l10n.documentNoteAttachment(
                                _attachmentTypeLabel(
                                  l10n,
                                  annotation.attachment!.type,
                                ),
                                annotation.attachment!.targetId,
                              ),
                      ),
                      onTap: () => _edit(annotation),
                      trailing: PopupMenuButton<String>(
                        tooltip: l10n.documentNoteActions,
                        onSelected: (value) {
                          if (value == 'duplicate') {
                            ref
                                .read(documentAnnotationsProvider.notifier)
                                .duplicate(widget.systemKey, annotation.id);
                          } else if (value == 'delete') {
                            _confirmDelete(annotation);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text(l10n.documentNoteDuplicate),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _add() async {
    final now = DateTime.now().toUtc();
    final draft = DocumentAnnotation(
      id: 'draft',
      documentId: widget.documentId,
      documentRevision: widget.documentRevision,
      text: '',
      x: 24,
      y: 24,
      createdAt: now,
      updatedAt: now,
    );
    final edited = await showDocumentAnnotationDialog(
      context,
      annotation: draft,
    );
    if (edited == null || !mounted) return;
    ref
        .read(documentAnnotationsProvider.notifier)
        .add(
          key: widget.systemKey,
          documentId: widget.documentId,
          documentRevision: widget.documentRevision,
          x: edited.x,
          y: edited.y,
          text: edited.text,
          attachment: edited.attachment,
          styleRole: edited.styleRole,
          width: edited.width,
          height: edited.height,
          collapsed: edited.collapsed,
        );
  }

  Future<void> _edit(DocumentAnnotation annotation) async {
    final edited = await showDocumentAnnotationDialog(
      context,
      annotation: annotation,
    );
    if (edited != null && mounted) {
      ref
          .read(documentAnnotationsProvider.notifier)
          .update(widget.systemKey, edited);
    }
  }

  Future<void> _confirmDelete(DocumentAnnotation annotation) async {
    final l10n = appLocalizationsOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.documentNoteDeleteTitle),
        content: Text(l10n.documentNoteDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref
          .read(documentAnnotationsProvider.notifier)
          .remove(widget.systemKey, annotation.id);
    }
  }
}

Future<DocumentAnnotation?> showDocumentAnnotationDialog(
  BuildContext context, {
  required DocumentAnnotation annotation,
}) {
  return showDialog<DocumentAnnotation>(
    context: context,
    builder: (context) =>
        _DocumentAnnotationEditorDialog(annotation: annotation),
  );
}

class _DocumentAnnotationEditorDialog extends StatefulWidget {
  const _DocumentAnnotationEditorDialog({required this.annotation});

  final DocumentAnnotation annotation;

  @override
  State<_DocumentAnnotationEditorDialog> createState() =>
      _DocumentAnnotationEditorDialogState();
}

class _DocumentAnnotationEditorDialogState
    extends State<_DocumentAnnotationEditorDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _targetController;
  late AnnotationStyleRole _style;
  AnnotationTargetType? _targetType;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.annotation.text);
    _targetController = TextEditingController(
      text: widget.annotation.attachment?.targetId ?? '',
    );
    _style = widget.annotation.styleRole;
    _targetType = widget.annotation.attachment?.type;
  }

  @override
  void dispose() {
    _textController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return AlertDialog(
      title: Text(l10n.documentNoteEditTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                autofocus: true,
                minLines: 4,
                maxLines: 10,
                maxLength: DocumentAnnotation.maximumTextLength,
                decoration: InputDecoration(
                  labelText: l10n.documentNoteTextLabel,
                  helperText: l10n.documentNoteTextHelp,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AnnotationStyleRole>(
                initialValue: _style,
                decoration: InputDecoration(
                  labelText: l10n.documentNoteStyleLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final value in AnnotationStyleRole.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(_styleRoleLabel(l10n, value)),
                    ),
                ],
                onChanged: (value) => setState(() => _style = value ?? _style),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AnnotationTargetType?>(
                initialValue: _targetType,
                decoration: InputDecoration(
                  labelText: l10n.documentNoteAttachmentLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.documentNoteNoAttachment),
                  ),
                  for (final value in AnnotationTargetType.values)
                    if (value != AnnotationTargetType.canvas)
                      DropdownMenuItem(
                        value: value,
                        child: Text(_attachmentTypeLabel(l10n, value)),
                      ),
                ],
                onChanged: (value) => setState(() => _targetType = value),
              ),
              if (_targetType != null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _targetController,
                  decoration: InputDecoration(
                    labelText: l10n.documentNoteTargetIdLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveChanges)),
      ],
    );
  }

  void _save() {
    final target = _targetController.text.trim();
    if (_targetType != null && target.isEmpty) return;
    Navigator.pop(
      context,
      widget.annotation.copyWith(
        text: _textController.text,
        styleRole: _style,
        attachment: _targetType == null
            ? null
            : AnnotationAttachment(
                type: _targetType!,
                targetId: target,
                offsetX: widget.annotation.attachment?.offsetX ?? 0,
                offsetY: widget.annotation.attachment?.offsetY ?? 0,
              ),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }
}

class _SafeAnnotationText extends StatelessWidget {
  const _SafeAnnotationText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(color: color);
    return Text.rich(
      TextSpan(style: base, children: _safeSpans(text, base)),
      textScaler: MediaQuery.textScalerOf(context),
    );
  }
}

String _styleRoleLabel(AppLocalizations l10n, AnnotationStyleRole role) =>
    switch (role) {
      AnnotationStyleRole.note => l10n.documentNoteStyleNote,
      AnnotationStyleRole.information => l10n.documentNoteStyleInformation,
      AnnotationStyleRole.warning => l10n.documentNoteStyleWarning,
      AnnotationStyleRole.question => l10n.documentNoteStyleQuestion,
      AnnotationStyleRole.todo => l10n.documentNoteStyleTodo,
    };

String _attachmentTypeLabel(AppLocalizations l10n, AnnotationTargetType type) =>
    switch (type) {
      AnnotationTargetType.canvas => l10n.documentNoteTargetCanvas,
      AnnotationTargetType.state => l10n.documentNoteTargetState,
      AnnotationTargetType.transition => l10n.documentNoteTargetTransition,
      AnnotationTargetType.production => l10n.documentNoteTargetProduction,
      AnnotationTargetType.tableCell => l10n.documentNoteTargetTableCell,
    };

List<InlineSpan> _safeSpans(String text, TextStyle? base) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'(\*\*[^*]+\*\*|_[^_]+_|`[^`]+`)');
  var cursor = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    final value = match.group(0)!;
    if (value.startsWith('**')) {
      spans.add(
        TextSpan(
          text: value.substring(2, value.length - 2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else if (value.startsWith('_')) {
      spans.add(
        TextSpan(
          text: value.substring(1, value.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: value.substring(1, value.length - 1),
          style: base?.copyWith(fontFamily: 'monospace'),
        ),
      );
    }
    cursor = match.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}

IconData _styleIcon(AnnotationStyleRole style) => switch (style) {
  AnnotationStyleRole.note => Icons.sticky_note_2_outlined,
  AnnotationStyleRole.information => Icons.info_outline,
  AnnotationStyleRole.warning => Icons.warning_amber,
  AnnotationStyleRole.question => Icons.help_outline,
  AnnotationStyleRole.todo => Icons.check_box_outlined,
};
