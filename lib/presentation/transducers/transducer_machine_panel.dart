import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/annotations/annotations.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/transducers/transducers.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../providers/document_annotations_provider.dart';
import '../providers/interoperable_document_sidecar_provider.dart';
import '../widgets/document_interoperability_binding.dart';
import '../widgets/file_operations_panel.dart';
import '../widgets/export/transducer_visual_exporter.dart';
import '../widgets/visual_export_binding.dart';
import 'graphview_transducer_canvas_controller.dart';

final class TransducerMachinePanel<
  TMachine extends DeterministicFiniteStateTransducer
>
    extends ConsumerStatefulWidget {
  const TransducerMachinePanel({
    super.key,
    required this.machine,
    required this.controller,
    required this.systemKey,
    required this.schema,
    required this.registry,
    required this.formalSystems,
    required this.replaceDocument,
  });

  final TMachine machine;
  final GraphViewTransducerCanvasController<TMachine> controller;
  final FormalSystemKey systemKey;
  final DocumentSchemaDescriptor schema;
  final DocumentInteroperabilityRegistry registry;
  final FormalSystemRegistry formalSystems;
  final void Function(TMachine machine) replaceDocument;

  @override
  ConsumerState<TransducerMachinePanel<TMachine>> createState() =>
      _TransducerMachinePanelState<TMachine>();
}

final class _TransducerMachinePanelState<
  TMachine extends DeterministicFiniteStateTransducer
>
    extends ConsumerState<TransducerMachinePanel<TMachine>> {
  late final TextEditingController _inputAlphabet;
  late final TextEditingController _outputAlphabet;
  late final FocusNode _inputFocus;
  late final FocusNode _outputFocus;
  Set<TransducerInputSymbol> _lastInputAlphabet = const {};
  Set<TransducerOutputSymbol> _lastOutputAlphabet = const {};
  String _statusFingerprint = '';
  bool _announceStatus = false;

  @override
  void initState() {
    super.initState();
    _inputAlphabet = TextEditingController();
    _outputAlphabet = TextEditingController();
    _inputFocus = FocusNode();
    _outputFocus = FocusNode();
    _inputFocus.addListener(_handleInputFocusChange);
    _outputFocus.addListener(_handleOutputFocusChange);
    _syncControllers(force: true);
    _statusFingerprint = _fingerprint(widget.machine);
  }

  @override
  void didUpdateWidget(covariant TransducerMachinePanel<TMachine> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
    final nextFingerprint = _fingerprint(widget.machine);
    if (nextFingerprint != _statusFingerprint) {
      _statusFingerprint = nextFingerprint;
      _announceStatus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _announceStatus) setState(() => _announceStatus = false);
      });
    }
  }

  void _syncControllers({bool force = false}) {
    if ((force ||
            !setEquals(widget.machine.inputAlphabet, _lastInputAlphabet)) &&
        !_inputFocus.hasFocus) {
      _inputAlphabet.text = widget.machine.inputAlphabet
          .map((symbol) => symbol.value)
          .join('\n');
      _lastInputAlphabet = widget.machine.inputAlphabet;
    }
    if ((force ||
            !setEquals(widget.machine.outputAlphabet, _lastOutputAlphabet)) &&
        !_outputFocus.hasFocus) {
      _outputAlphabet.text = widget.machine.outputAlphabet
          .map((symbol) => symbol.value)
          .join('\n');
      _lastOutputAlphabet = widget.machine.outputAlphabet;
    }
  }

  void _handleInputFocusChange() {
    if (!_inputFocus.hasFocus) _syncControllers();
  }

  void _handleOutputFocusChange() {
    if (!_outputFocus.hasFocus) _syncControllers();
  }

  @override
  void dispose() {
    _inputFocus.removeListener(_handleInputFocusChange);
    _outputFocus.removeListener(_handleOutputFocusChange);
    _inputAlphabet.dispose();
    _outputAlphabet.dispose();
    _inputFocus.dispose();
    _outputFocus.dispose();
    super.dispose();
  }

  Set<String> _tokens(TextEditingController controller) =>
      controller.text.split('\n').where((token) => token.isNotEmpty).toSet();

  String _fingerprint(TMachine machine) => TransducerAnalyzer.analyze(machine)
      .diagnostics
      .map((diagnostic) => '${diagnostic.code.name}:${diagnostic.subject}')
      .join('|');

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final sidecar = ref.watch(
      interoperableDocumentSidecarProvider,
    )[widget.systemKey];
    final annotations = annotationsForDocument(
      ref.watch(documentAnnotationsProvider),
      widget.systemKey,
      widget.machine.id.value,
    );
    final currentDocument = resolveInteroperableDocument(
      sidecar: sidecar,
      currentDocument: widget.machine,
      documentIdentity: widget.machine.id.value,
      systemKey: widget.systemKey,
      schema: widget.schema,
      annotations: annotations,
    );
    final analysis = TransducerAnalyzer.analyze(widget.machine);
    final status = <String>[
      if (analysis.isStructurallyValid)
        l10n.transducerMachineValid
      else
        l10n.transducerMachineInvalid,
      if (analysis.isDeterministic)
        l10n.transducerMachineDeterministic
      else
        l10n.transducerMachineNondeterministic,
      if (analysis.isComplete)
        l10n.transducerMachineComplete
      else
        l10n.transducerMachinePartial,
    ].join('. ');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          l10n.transducerMachineInfo,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: _announceStatus,
          container: true,
          label: status,
          excludeSemantics: true,
          child: Text(status),
        ),
        for (final diagnostic in analysis.diagnostics)
          if (diagnostic.severity == TransducerDiagnosticSeverity.error)
            ListTile(
              dense: true,
              leading: const Icon(Icons.error_outline),
              title: Text(
                l10n.resolveStructuredMessage(diagnostic.structuredMessage),
              ),
            ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('transducer-input-alphabet'),
          controller: _inputAlphabet,
          focusNode: _inputFocus,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: l10n.transducerInputAlphabet,
            helperText: l10n.transducerAlphabetHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('transducer-output-alphabet'),
          controller: _outputAlphabet,
          focusNode: _outputFocus,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: l10n.transducerOutputAlphabet,
            helperText: l10n.transducerAlphabetHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('transducer-apply-alphabets'),
          onPressed: () => widget.controller.updateAlphabets(
            inputAlphabet: _tokens(
              _inputAlphabet,
            ).map(TransducerInputSymbol.new).toSet(),
            outputAlphabet: _tokens(
              _outputAlphabet,
            ).map(TransducerOutputSymbol.new).toSet(),
          ),
          child: Text(l10n.transducerApplyAlphabets),
        ),
        const SizedBox(height: 12),
        FileOperationsPanel(
          formalSystemRegistry: widget.formalSystems,
          annotations: annotations,
          visualExport: VisualExportBinding(
            systemKey: widget.systemKey,
            producers: {
              DefaultFormalSystemIds.svgFormat:
                  ({required includeAnnotations}) async =>
                      TransducerVisualExporter.svg(
                        widget.machine,
                        annotations: includeAnnotations ? annotations : null,
                      ),
              DefaultFormalSystemIds.pngFormat:
                  ({required includeAnnotations}) =>
                      TransducerVisualExporter.png(
                        widget.machine,
                        annotations: includeAnnotations ? annotations : null,
                      ),
            },
          ),
          interoperability: DocumentInteroperabilityBinding(
            registry: widget.registry,
            systemKey: widget.systemKey,
            currentDocument: currentDocument,
            captureCheckpoint: () => _TransducerImportCheckpoint<TMachine>(
              machine: widget.machine,
              sidecar: ref.read(
                interoperableDocumentSidecarProvider,
              )[widget.systemKey],
              annotations: ref.read(
                documentAnnotationsProvider,
              )[widget.systemKey],
            ),
            replace: (document) async {
              final value = document.document;
              if (value is! TMachine) {
                throw StateError('Imported document has the wrong type.');
              }
              widget.replaceDocument(value);
              ref
                  .read(interoperableDocumentSidecarProvider.notifier)
                  .store(document, documentIdentity: value.id.value);
              ref
                  .read(documentAnnotationsProvider.notifier)
                  .restore(
                    widget.systemKey,
                    annotationsFromImportedDocument(
                      document,
                      documentId: value.id.value,
                      documentRevision: '${value.revision.value}',
                    ),
                  );
            },
            restoreCheckpoint: (checkpoint) async {
              final snapshot =
                  checkpoint! as _TransducerImportCheckpoint<TMachine>;
              widget.replaceDocument(snapshot.machine);
              ref
                  .read(interoperableDocumentSidecarProvider.notifier)
                  .restore(widget.systemKey, snapshot.sidecar);
              ref
                  .read(documentAnnotationsProvider.notifier)
                  .restore(widget.systemKey, snapshot.annotations);
            },
            systemLabel: (_, __) => switch (widget.systemKey) {
              TransducerFormalSystemIds.mealy => l10n.homeNavigationMealyLabel,
              TransducerFormalSystemIds.moore => l10n.homeNavigationMooreLabel,
              _ => widget.machine.name,
            },
            formatLabel: (_, format) =>
                format == DefaultFormalSystemIds.jflapXmlFormat
                ? l10n.interoperabilityFormatJflapXml
                : l10n.interoperabilityFormatTuringLabJson,
          ),
        ),
      ],
    );
  }
}

final class _TransducerImportCheckpoint<
  TMachine extends DeterministicFiniteStateTransducer
> {
  const _TransducerImportCheckpoint({
    required this.machine,
    required this.sidecar,
    required this.annotations,
  });

  final TMachine machine;
  final InteroperableDocumentSidecarEntry? sidecar;
  final DocumentAnnotationCollection? annotations;
}
