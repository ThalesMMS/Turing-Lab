import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/tm_building_blocks.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_structured_messages.dart';
import '../../localization/locale_value_formatter.dart';
import '../../providers/tm_block_library_provider.dart';

class TMBlockLibraryPanel extends ConsumerWidget {
  const TMBlockLibraryPanel({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(tmBlockLibraryProvider);
    final notifier = ref.read(tmBlockLibraryProvider.notifier);
    final project = state.project;
    if (project == null) {
      return const SizedBox.shrink();
    }
    final active = state.activeBlockId == null
        ? null
        : project.definitions[state.activeBlockId];
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tmBlockLibraryTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.tmBlockLibraryDescription),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.canvasUndoAction,
              onPressed: state.canUndo ? notifier.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: l10n.canvasRedoAction,
              onPressed: state.canRedo ? notifier.redo : null,
              icon: const Icon(Icons.redo),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NoticeCard(text: l10n.tmBlockSharedTapeNotice),
        if (state.lastError case final error?) ...[
          const SizedBox(height: 12),
          _ErrorCard(
            error: l10n.resolveStructuredMessage(error),
            onDismiss: notifier.clearError,
          ),
        ],
        const SizedBox(height: 12),
        _Breadcrumbs(state: state),
        const SizedBox(height: 12),
        if (active == null)
          _LibraryList(state: state)
        else
          _BlockDetail(definition: active, state: state),
      ],
    );
  }
}

class _LibraryList extends ConsumerWidget {
  const _LibraryList({required this.state});

  final TMBlockLibraryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final project = state.project!;
    final definitions = project.definitions.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: () => _showNameDialog(
              context,
              title: l10n.tmBlockCreateTitle,
              action: l10n.tmBlockCreate,
              onSubmit: ref
                  .read(tmBlockLibraryProvider.notifier)
                  .createDefinition,
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.tmBlockCreate),
          ),
        ),
        const SizedBox(height: 12),
        if (definitions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.tmBlockLibraryEmpty)),
          )
        else
          for (final definition in definitions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BlockTile(definition: definition, state: state),
            ),
      ],
    );
  }
}

class _BlockTile extends ConsumerWidget {
  const _BlockTile({required this.definition, required this.state});

  final TMBlockDefinition definition;
  final TMBlockLibraryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formatter = LocaleValueFormatter.of(context);
    final notifier = ref.read(tmBlockLibraryProvider.notifier);
    final errors = state.diagnostics.where(
      (diagnostic) =>
          diagnostic.blockId == definition.id &&
          diagnostic.severity == TMBlockDiagnosticSeverity.error,
    );
    final valid = errors.isEmpty;
    return Semantics(
      button: true,
      label: definition.name,
      hint: valid ? l10n.tmBlockValid : l10n.tmBlockInvalid,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(
            Icons.account_tree_outlined,
            color: valid
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          title: Text(definition.name),
          subtitle: Text(
            '${_localizedBlockRevision(l10n, formatter, definition.revision)} · '
            '${_localizedMachineSummary(formatter, l10n, definition.machine.states.length, definition.machine.tmTransitions.length)}',
          ),
          onTap: () => notifier.openDefinition(definition.id),
          trailing: PopupMenuButton<_BlockAction>(
            tooltip: definition.name,
            onSelected: (action) =>
                _handleAction(context, ref, action, definition),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _BlockAction.insert,
                child: Text(l10n.tmBlockInsert),
              ),
              PopupMenuItem(
                value: _BlockAction.rename,
                child: Text(l10n.tmBlockRename),
              ),
              PopupMenuItem(
                value: _BlockAction.duplicate,
                child: Text(l10n.tmBlockDuplicate),
              ),
              PopupMenuItem(
                value: _BlockAction.delete,
                child: Text(l10n.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockDetail extends ConsumerWidget {
  const _BlockDetail({required this.definition, required this.state});

  final TMBlockDefinition definition;
  final TMBlockLibraryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formatter = LocaleValueFormatter.of(context);
    final notifier = ref.read(tmBlockLibraryProvider.notifier);
    final project = state.project!;
    final nested = definition.invocations
        .map((node) => project.definitions[node.reference.blockId])
        .whereType<TMBlockDefinition>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(definition.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(_localizedBlockRevision(l10n, formatter, definition.revision)),
        Text(
          _localizedMachineSummary(
            formatter,
            l10n,
            definition.machine.states.length,
            definition.machine.tmTransitions.length,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => notifier.insertOnRootCanvas(definition.id),
              icon: const Icon(Icons.add_box_outlined),
              label: Text(l10n.tmBlockInsert),
            ),
            OutlinedButton.icon(
              onPressed: () => _showNameDialog(
                context,
                title: l10n.tmBlockRenameTitle,
                action: l10n.tmBlockRename,
                initialValue: definition.name,
                onSubmit: (name) =>
                    notifier.renameDefinition(definition.id, name),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.tmBlockRename),
            ),
            OutlinedButton.icon(
              onPressed: () => notifier.duplicateDefinition(definition.id),
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.tmBlockDuplicate),
            ),
          ],
        ),
        if (nested.isNotEmpty) ...[
          const SizedBox(height: 20),
          for (final child in nested)
            ListTile(
              leading: const Icon(Icons.subdirectory_arrow_right),
              title: Text(child.name),
              subtitle: Text(l10n.tmBlockRevision(child.revision)),
              onTap: () => notifier.openNestedDefinition(child.id),
            ),
        ],
      ],
    );
  }
}

class _Breadcrumbs extends ConsumerWidget {
  const _Breadcrumbs({required this.state});

  final TMBlockLibraryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(tmBlockLibraryProvider.notifier);
    final project = state.project!;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ActionChip(
          label: Text(l10n.tmBlockRootBreadcrumb),
          onPressed: () => notifier.navigateToDepth(0),
        ),
        for (var index = 0; index < state.navigationPath.length; index++) ...[
          const Icon(Icons.chevron_right, size: 18),
          ActionChip(
            label: Text(
              project.definitions[state.navigationPath[index]]?.name ??
                  state.navigationPath[index],
            ),
            onPressed: () => notifier.navigateToDepth(index + 1),
          ),
        ],
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onDismiss});

  final String error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text(error),
      trailing: IconButton(
        tooltip: AppLocalizations.of(context).close,
        onPressed: onDismiss,
        icon: const Icon(Icons.close),
      ),
    ),
  );
}

enum _BlockAction { insert, rename, duplicate, delete }

Future<void> _handleAction(
  BuildContext context,
  WidgetRef ref,
  _BlockAction action,
  TMBlockDefinition definition,
) async {
  final l10n = AppLocalizations.of(context);
  final notifier = ref.read(tmBlockLibraryProvider.notifier);
  switch (action) {
    case _BlockAction.insert:
      notifier.insertOnRootCanvas(definition.id);
    case _BlockAction.rename:
      await _showNameDialog(
        context,
        title: l10n.tmBlockRenameTitle,
        action: l10n.tmBlockRename,
        initialValue: definition.name,
        onSubmit: (name) => notifier.renameDefinition(definition.id, name),
      );
    case _BlockAction.duplicate:
      notifier.duplicateDefinition(definition.id);
    case _BlockAction.delete:
      final project = ref.read(tmBlockLibraryProvider).project!;
      final referenced = <TMBlockInvocationNode>[
        ...project.rootInvocations,
        for (final block in project.definitions.values) ...block.invocations,
      ].any((node) => node.reference.blockId == definition.id);
      if (!referenced) {
        notifier.deleteDefinition(definition.id, detachInvocations: false);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.tmBlockDeleteReferencedTitle),
          content: Text(l10n.tmBlockDeleteReferencedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.tmBlockDetachAndDelete),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        notifier.deleteDefinition(definition.id, detachInvocations: true);
      }
  }
}

Future<void> _showNameDialog(
  BuildContext context, {
  required String title,
  required String action,
  required ValueChanged<String> onSubmit,
  String initialValue = '',
}) async {
  final l10n = AppLocalizations.of(context);
  var draft = initialValue;
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextFormField(
        initialValue: initialValue,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.tmBlockNameLabel),
        textInputAction: TextInputAction.done,
        onChanged: (value) => draft = value,
        onFieldSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(draft),
          child: Text(action),
        ),
      ],
    ),
  );
  if (value != null && value.trim().isNotEmpty) onSubmit(value);
}

String _localizedBlockRevision(
  AppLocalizations l10n,
  LocaleValueFormatter formatter,
  int revision,
) {
  const marker = 987654321;
  return l10n
      .tmBlockRevision(marker)
      .replaceFirst('$marker', formatter.integer(revision));
}

String _localizedMachineSummary(
  LocaleValueFormatter formatter,
  AppLocalizations l10n,
  int states,
  int transitions,
) {
  const statesMarker = 987654321;
  const transitionsMarker = 123456789;
  return l10n
      .tmBlockMachineSummary(statesMarker, transitionsMarker)
      .replaceFirst('$statesMarker', formatter.integer(states))
      .replaceFirst('$transitionsMarker', formatter.integer(transitions));
}
