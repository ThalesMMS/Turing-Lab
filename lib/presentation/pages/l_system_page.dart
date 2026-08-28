import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/l_systems/l_systems.dart';
import '../../core/models/asset_example.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations_help.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../content/l_system_example_content_copy.dart';
import '../l_systems/l_system_editor_controller.dart';
import '../l_systems/l_system_workspace.dart';
import '../providers/formal_extension_editor_providers.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/document_interoperability_binding.dart';
import '../widgets/file_operations_panel.dart';

final class LSystemPage extends ConsumerStatefulWidget {
  const LSystemPage({super.key});

  @override
  ConsumerState<LSystemPage> createState() => _LSystemPageState();
}

final class _LSystemPageState extends ConsumerState<LSystemPage> {
  List<AssetExample<Object>> _examples = const [];
  Object? _examplesFailure;
  bool _examplesLoading = true;

  bool get _examplesEnabled =>
      !_examplesLoading && _examplesFailure == null && _examples.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadExamples();
  }

  Future<void> _loadExamples() async {
    try {
      final catalog = ref
          .read(formalSystemRegistryProvider)
          .moduleFor(LSystemFormalSystemIds.key)
          ?.examples;
      final examples = catalog == null
          ? const <AssetExample<Object>>[]
          : await catalog.loadExamples();
      if (!mounted) return;
      setState(() {
        _examples = List<AssetExample<Object>>.unmodifiable(examples);
        _examplesFailure = null;
        _examplesLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _examples = const [];
        _examplesFailure = error;
        _examplesLoading = false;
      });
    }
  }

  Future<void> _openExamples() async {
    if (!_examplesEnabled) return;
    final examples = _examples;
    final selected = await showModalBottomSheet<LSystemDocument>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final sheetL10n = jflapLocalizationsOf(sheetContext);
        final languageCode = Localizations.localeOf(sheetContext).languageCode;
        return Semantics(
          namesRoute: true,
          label: sheetL10n.workspaceAlgorithmsAndExamplesTooltip,
          child: ListView(
            key: const Key('l-system-examples-list'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    sheetL10n.workspaceAlgorithmsAndExamplesTooltip,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
              ),
              for (final example in examples)
                _exampleTile(sheetContext, example, languageCode),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    _replaceDocument(ref.read(lSystemEditorProvider), selected);
  }

  Widget _exampleTile(
    BuildContext sheetContext,
    AssetExample<Object> example,
    String languageCode,
  ) {
    final copy = LSystemExampleContentCopies.resolve(
      id: example.id,
      languageCode: languageCode,
    );
    void select() {
      final document = example.payload;
      if (document is LSystemDocument) {
        Navigator.of(sheetContext).pop(document);
      }
    }

    return Semantics(
      key: ValueKey('l-system-example-${example.id}'),
      button: true,
      label: copy.semanticLabel,
      onTap: select,
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: select,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.title,
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            copy.summary,
                            copy.learningObjective,
                            copy.limitation,
                          ].join('\n'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _replaceDocument(
    LSystemEditorController controller,
    LSystemDocument document,
  ) {
    controller.replaceDocument(document);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(lSystemEditorProvider);
    final l10n = jflapLocalizationsOf(context);
    final examplesTooltip = _examplesLoading
        ? l10n.workspaceExamplesLoadingTooltip
        : _examplesFailure != null
        ? l10n.workspaceExamplesLoadFailed
        : _examples.isEmpty
        ? l10n.workspaceExamplesEmpty
        : l10n.workspaceAlgorithmsAndExamplesTooltip;
    publishWorkspaceQuickActionsForKey(
      ref,
      LSystemFormalSystemIds.key,
      WorkspaceQuickActions(
        onExamples: _openExamples,
        examplesEnabled: _examplesEnabled,
        examplesTooltip: examplesTooltip,
        // The examples surface is this workspace's Algorithms & Examples
        // equivalent, so it carries the shared icon for consistency.
        examplesIcon: Icons.auto_awesome,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpansionTile(
          key: const Key('l-system-file-operations'),
          title: Semantics(
            header: true,
            child: Text(l10n.localizeWorkflowText('Files')),
          ),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: SingleChildScrollView(
                key: const Key('l-system-file-operations-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FileOperationsPanel(
                  formalSystemRegistry: ref.watch(formalSystemRegistryProvider),
                  interoperability: DocumentInteroperabilityBinding(
                    registry: ref.watch(
                      documentInteroperabilityRegistryProvider,
                    ),
                    systemKey: LSystemFormalSystemIds.key,
                    currentDocument: InteroperableDocument<Object>(
                      document: controller.document,
                      systemKey: LSystemFormalSystemIds.key,
                      schema: ref
                          .watch(formalSystemRegistryProvider)
                          .descriptorFor(LSystemFormalSystemIds.key)!
                          .schema,
                    ),
                    captureCheckpoint: () => controller.document,
                    replace: (document) async {
                      final value = document.document;
                      if (value is! LSystemDocument) {
                        throw StateError(
                          'Imported document is not an L-system.',
                        );
                      }
                      _replaceDocument(controller, value);
                    },
                    restoreCheckpoint: (checkpoint) async {
                      if (checkpoint is LSystemDocument) {
                        _replaceDocument(controller, checkpoint);
                      }
                    },
                    systemLabel: (labelContext, __) => _localizedDocumentName(
                      labelContext,
                      controller.document,
                    ),
                    formatLabel: (_, format) =>
                        format == DefaultFormalSystemIds.jflapXmlFormat
                        ? 'JFLAP XML'
                        : 'Turing Lab JSON',
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: LSystemWorkspace(
            // replaceDocument keeps the controller instance, so key the
            // workspace to the document identity to reload its text drafts
            // and derived visualization after every replacement.
            key: ObjectKey(controller.document),
            controller: controller,
          ),
        ),
      ],
    );
  }
}

String _localizedDocumentName(BuildContext context, LSystemDocument document) {
  if (LSystemExampleContentCopies.ids.contains(document.id)) {
    return LSystemExampleContentCopies.resolve(
      id: document.id,
      languageCode: Localizations.localeOf(context).languageCode,
    ).title;
  }
  return document.name;
}
