import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/asset_example.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations_help.dart';
import '../content/example_suggested_simulations.dart';
import '../content/unrestricted_grammar_example_content_copy.dart';
import '../providers/formal_extension_editor_providers.dart';
import '../providers/tm_to_grammar_provider.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../unrestricted_grammar/unrestricted_grammar_workspace.dart';
import '../unrestricted_grammar/unrestricted_grammar_editor_controller.dart';
import '../unrestricted_grammar/unrestricted_grammar_workspace_strings.dart';
import '../widgets/document_interoperability_binding.dart';
import '../widgets/example_suggested_simulations_text.dart';
import '../widgets/file_operations_panel.dart';

final class UnrestrictedGrammarPage extends ConsumerStatefulWidget {
  const UnrestrictedGrammarPage({super.key});

  @override
  ConsumerState<UnrestrictedGrammarPage> createState() =>
      _UnrestrictedGrammarPageState();
}

final class _UnrestrictedGrammarPageState
    extends ConsumerState<UnrestrictedGrammarPage> {
  List<AssetExample<Object>> _examples = const [];
  bool _examplesLoading = true;
  bool _examplesFailed = false;

  @override
  void initState() {
    super.initState();
    _loadExamples();
  }

  Future<void> _loadExamples() async {
    final catalog = ref
        .read(formalSystemRegistryProvider)
        .moduleFor(UnrestrictedGrammarCapabilities.systemKey)
        ?.examples;
    if (catalog == null) {
      _examplesLoading = false;
      _examplesFailed = true;
      return;
    }

    try {
      final loaded = await catalog.loadExamples();
      if (!mounted) return;
      setState(() {
        _examples = loaded
            .where((example) => example.payload is UnrestrictedGrammar)
            .toList(growable: false);
        _examplesLoading = false;
        _examplesFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _examples = const [];
        _examplesLoading = false;
        _examplesFailed = true;
      });
    }
  }

  /// Examples section rendered at the end of the Algorithms & Examples
  /// surface (compact sheet and wide dock panel alike).
  Widget _buildExamplesSection(
    BuildContext context,
    VoidCallback closeSurface,
  ) {
    final l10n = jflapLocalizationsOf(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final Widget body;
    if (_examplesLoading) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_examplesFailed) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.workspaceExamplesLoadFailed),
      );
    } else if (_examples.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.workspaceExamplesEmpty),
      );
    } else {
      body = Column(
        key: const Key('unrestricted-grammar-examples-list'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final example in _examples)
            _exampleTile(context, example, languageCode, closeSurface),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.workspaceExamplesTooltip,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        body,
      ],
    );
  }

  Widget _exampleTile(
    BuildContext context,
    AssetExample<Object> example,
    String languageCode,
    VoidCallback closeSurface,
  ) {
    final copy = UnrestrictedGrammarExampleContentCopies.resolve(
      id: example.id,
      languageCode: languageCode,
    );
    final suggestions = ExampleSuggestedSimulations.resolve(example.id);
    void select() {
      ref
          .read(unrestrictedGrammarEditorProvider)
          .replaceGrammar(example.payload as UnrestrictedGrammar);
      closeSurface();
    }

    return Semantics(
      key: ValueKey('unrestricted-grammar-example-${example.id}'),
      button: true,
      label: [
        copy.semanticLabel,
        ExampleSuggestedSimulationsText.semanticLabel(context, suggestions),
      ].join(' '),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            copy.summary,
                            copy.learningObjective,
                            copy.limitation,
                          ].join('\n'),
                        ),
                        const SizedBox(height: 8),
                        ExampleSuggestedSimulationsText(
                          suggestions: suggestions,
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

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(unrestrictedGrammarEditorProvider);
    final strings = UnrestrictedGrammarWorkspaceStrings.forLocale(
      Localizations.localeOf(context),
    );
    final conversionReport = ref.watch(tmToGrammarOpenedReportProvider);
    final matchingReport =
        conversionReport?.grammar?.id == controller.grammar.id &&
            conversionReport?.grammar?.revision == controller.grammar.revision
        ? conversionReport
        : null;
    return UnrestrictedGrammarWorkspace(
      controller: controller,
      strings: strings,
      examplesSectionBuilder: _buildExamplesSection,
      onQuickActionsChanged: (actions) => publishWorkspaceQuickActionsForKey(
        ref,
        UnrestrictedGrammarCapabilities.systemKey,
        actions,
      ),
      infoPanel: _buildInfoPanel(
        controller: controller,
        strings: strings,
        matchingReport: matchingReport,
      ),
    );
  }

  Widget _buildInfoPanel({
    required UnrestrictedGrammarEditorController controller,
    required UnrestrictedGrammarWorkspaceStrings strings,
    required TMToGrammarConstructionReport? matchingReport,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (matchingReport != null)
        ExpansionTile(
          key: const ValueKey('tm-grammar-opened-provenance'),
          leading: const Icon(Icons.account_tree_outlined),
          title: Text(
            strings.usesPortuguese
                ? 'Proveniência da conversão de MT'
                : 'TM conversion provenance',
          ),
          subtitle: Text(
            '${matchingReport.sourceTmId} · '
            '${matchingReport.productionProvenance.length} '
            '${strings.usesPortuguese ? 'produções mapeadas' : 'mapped productions'}',
          ),
          children: [
            SizedBox(
              height: 240,
              child: ListView.builder(
                itemCount: matchingReport.productionProvenance.length,
                itemBuilder: (context, index) {
                  final provenance = matchingReport.productionProvenance[index];
                  final transitions =
                      provenance.sources
                          .map((source) => source.transitionId)
                          .whereType<String>()
                          .toSet()
                          .toList()
                        ..sort();
                  final states =
                      provenance.sources
                          .map((source) => source.stateId)
                          .whereType<String>()
                          .toSet()
                          .toList()
                        ..sort();
                  return ListTile(
                    minTileHeight: 48,
                    title: Text(provenance.productionId),
                    subtitle: Text(
                      '${provenance.family.name} · '
                      '${transitions.isEmpty ? states.join(', ') : transitions.join(', ')}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ExpansionTile(
        key: const Key('unrestricted-grammar-file-operations'),
        title: Text(strings.usesPortuguese ? 'Arquivos' : 'Files'),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: SingleChildScrollView(
              key: const Key('unrestricted-grammar-file-operations-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FileOperationsPanel(
                formalSystemRegistry: ref.watch(formalSystemRegistryProvider),
                interoperability: DocumentInteroperabilityBinding(
                  registry: ref.watch(documentInteroperabilityRegistryProvider),
                  systemKey: UnrestrictedGrammarCapabilities.systemKey,
                  currentDocument: InteroperableDocument<Object>(
                    document: controller.grammar,
                    systemKey: UnrestrictedGrammarCapabilities.systemKey,
                    schema: ref
                        .watch(formalSystemRegistryProvider)
                        .descriptorFor(
                          UnrestrictedGrammarCapabilities.systemKey,
                        )!
                        .schema,
                  ),
                  captureCheckpoint: () => controller.grammar,
                  replace: (document) async {
                    final value = document.document;
                    if (value is! UnrestrictedGrammar) {
                      throw StateError(
                        'Imported document is not an unrestricted grammar.',
                      );
                    }
                    controller.replaceGrammar(value);
                  },
                  restoreCheckpoint: (checkpoint) async {
                    if (checkpoint is UnrestrictedGrammar) {
                      controller.replaceGrammar(checkpoint);
                    }
                  },
                  systemLabel: (_, __) => controller.grammar.name,
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
    ],
  );
}
