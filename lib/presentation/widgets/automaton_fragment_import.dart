import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/annotations/annotations.dart';
import '../../core/automaton_fragments/automaton_fragments.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/fsa.dart';
import '../../core/models/pda.dart';
import '../../core/models/pda_acceptance_mode.dart';
import '../../core/models/tm.dart';
import '../../core/transducers/transducers.dart';
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/automaton_fragment_localizations.dart';
import '../localization/locale_value_formatter.dart';
import '../providers/document_annotations_provider.dart';
import 'automaton_canvas_document_actions.dart';

Future<AutomatonFragmentPlan?> showAutomatonFragmentReviewDialog(
  BuildContext context, {
  required Object destination,
  required Object source,
  DocumentAnnotationCollection? destinationAnnotations,
  DocumentAnnotationCollection? sourceAnnotations,
  required String destinationRevision,
  required Vector2 initialAnchor,
  DocumentFidelity fidelity = DocumentFidelity.exact,
  List<CodecDiagnostic> codecDiagnostics = const [],
}) {
  return showDialog<AutomatonFragmentPlan>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AutomatonFragmentReviewDialog(
      destination: destination,
      source: source,
      destinationAnnotations: destinationAnnotations,
      sourceAnnotations: sourceAnnotations,
      destinationRevision: destinationRevision,
      initialAnchor: initialAnchor,
      fidelity: fidelity,
      codecDiagnostics: codecDiagnostics,
    ),
  );
}

final class AutomatonFragmentImportButton extends ConsumerStatefulWidget {
  const AutomatonFragmentImportButton({
    super.key,
    required this.systemKey,
    required this.destination,
    required this.controller,
    required this.documentId,
    required this.documentRevision,
    required this.onCommitted,
    this.actionsController,
    this.showButton = true,
  });

  final FormalSystemKey systemKey;
  final Object destination;
  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final String documentId;
  final String documentRevision;
  final ValueChanged<AutomatonFragmentPlan> onCommitted;
  final AutomatonCanvasDocumentActionsController? actionsController;
  final bool showButton;

  @override
  ConsumerState<AutomatonFragmentImportButton> createState() =>
      _AutomatonFragmentImportButtonState();
}

class _AutomatonFragmentImportButtonState
    extends ConsumerState<AutomatonFragmentImportButton> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.actionsController?.bindImport(this, _import);
  }

  @override
  void didUpdateWidget(covariant AutomatonFragmentImportButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actionsController != widget.actionsController) {
      oldWidget.actionsController?.unbind(this);
      widget.actionsController?.bindImport(this, _import);
    }
  }

  @override
  void dispose() {
    widget.actionsController?.unbind(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showButton) return const SizedBox.shrink();
    final l10n = appLocalizationsOf(context);
    return Semantics(
      button: true,
      label: l10n.canvasImportAutomatonAction,
      hint: l10n.canvasImportAutomatonHint,
      child: IconButton.filledTonal(
        key: const ValueKey('automaton-fragment-import-button'),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        tooltip: l10n.canvasImportAutomatonAction,
        onPressed: _busy ? null : _import,
        icon: _busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.account_tree_outlined),
      ),
    );
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: appLocalizationsOf(
          context,
        ).automatonFragmentFilePickerTitle,
        type: FileType.any,
        withData: true,
      );
      if (!mounted || picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = await _bytesFor(file);
      if (!mounted) return;
      if (bytes == null) {
        await _showFailure(
          appLocalizationsOf(context).automatonFragmentUnreadableFile,
        );
        return;
      }
      final registry = ref.read(documentInteroperabilityRegistryProvider);
      final payload = DocumentPayload(
        bytes: bytes,
        filename: file.name,
        sourcePath: file.path,
      );
      final outcome = _decode(registry, payload);
      if (outcome is! CodecSuccess<InteroperableDocument<Object>>) {
        await _showFailure(_failureMessage(context, outcome));
        return;
      }
      final source = outcome.value.document;
      final sourceAnnotations = annotationsFromExtensions(
        outcome.value.extensions,
      );
      final destinationAnnotations = annotationsForDocument(
        ref.read(documentAnnotationsProvider),
        widget.systemKey,
        widget.documentId,
      );
      if (!mounted) return;
      final center = widget.controller.viewportCenterWorld;
      final plan = await showAutomatonFragmentReviewDialog(
        context,
        destination: widget.destination,
        source: source,
        destinationAnnotations: destinationAnnotations,
        sourceAnnotations: sourceAnnotations,
        destinationRevision: widget.documentRevision,
        initialAnchor: Vector2(center.dx, center.dy),
        fidelity: outcome.fidelity,
        codecDiagnostics: outcome.diagnostics,
      );
      if (!mounted || plan == null || !plan.canCommit) return;
      _commit(plan);
      widget.onCommitted(plan);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            appLocalizationsOf(context).automatonFragmentImportedSummary(
              plan.importedStateIds.length,
              plan.importedTransitionIds.length,
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        await _showFailure(
          appLocalizationsOf(
            context,
          ).automatonFragmentImportFailed(error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List?> _bytesFor(PlatformFile file) async {
    if (file.bytes case final bytes?) return bytes;
    final path = file.path;
    if (path == null || path.trim().isEmpty) return null;
    final result = await ref.read(fileOperationsProvider).readBytes(path);
    return result.isSuccess ? result.data : null;
  }

  CodecOutcome<InteroperableDocument<Object>> _decode(
    DocumentInteroperabilityRegistry registry,
    DocumentPayload payload,
  ) {
    final detected = registry.detect(payload, expectedSystem: widget.systemKey);
    if (detected is CodecSuccess<DetectedDocument>) {
      return registry.decode(
        payload,
        expectedSystem: widget.systemKey,
        expectedFormat: detected.value.descriptor.formatId,
      );
    }
    final extension = payload.normalizedExtension;
    final format = extension == null
        ? null
        : registry.formalSystems.formats.forExtension(extension)?.id;
    if (format != null) {
      return registry.decode(
        payload,
        expectedSystem: widget.systemKey,
        expectedFormat: format,
      );
    }
    return switch (detected) {
      CodecUnsupported(
        :final reason,
        :final message,
        :final roadmapIssue,
        :final structuredMessage,
      ) =>
        CodecUnsupported(
          reason: reason,
          message: message,
          roadmapIssue: roadmapIssue,
          structuredMessage: structuredMessage,
        ),
      CodecAmbiguous(:final codecIds) => CodecAmbiguous(codecIds: codecIds),
      CodecMalformed(
        :final reason,
        :final message,
        :final location,
        :final cause,
        :final structuredMessage,
      ) =>
        CodecMalformed(
          reason: reason,
          message: message,
          location: location,
          cause: cause,
          structuredMessage: structuredMessage,
        ),
      CodecResourceLimit(:final limit, :final maximum, :final actual) =>
        CodecResourceLimit(limit: limit, maximum: maximum, actual: actual),
      CodecInternalFailure(
        :final stage,
        :final message,
        :final cause,
        :final structuredMessage,
      ) =>
        CodecInternalFailure(
          stage: stage,
          message: message,
          cause: cause,
          structuredMessage: structuredMessage,
        ),
      CodecSuccess() => throw StateError('Unexpected detection outcome.'),
    };
  }

  void _commit(AutomatonFragmentPlan plan) {
    final annotationsNotifier = ref.read(documentAnnotationsProvider.notifier);
    var annotationCommitted = false;
    final annotations = plan.annotations;
    if (annotations != null) {
      annotationCommitted = annotationsNotifier.replaceAsMutation(
        widget.systemKey,
        annotations,
      );
    }
    try {
      widget.controller.replaceDocumentAsMutation(
        plan.preview!,
        companion: annotationCommitted
            ? CallbackGraphViewHistoryCompanion(
                onUndo: () => annotationsNotifier.undo(widget.systemKey),
                onRedo: () => annotationsNotifier.redo(widget.systemKey),
              )
            : null,
      );
    } catch (_) {
      if (annotationCommitted) annotationsNotifier.undo(widget.systemKey);
      rethrow;
    }
  }

  Future<void> _showFailure(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizationsOf(context).automatonFragmentCannotImport),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }
}

class _AutomatonFragmentReviewDialog extends StatefulWidget {
  const _AutomatonFragmentReviewDialog({
    required this.destination,
    required this.source,
    required this.destinationAnnotations,
    required this.sourceAnnotations,
    required this.destinationRevision,
    required this.initialAnchor,
    required this.fidelity,
    required this.codecDiagnostics,
  });

  final Object destination;
  final Object source;
  final DocumentAnnotationCollection? destinationAnnotations;
  final DocumentAnnotationCollection? sourceAnnotations;
  final String destinationRevision;
  final Vector2 initialAnchor;
  final DocumentFidelity fidelity;
  final List<CodecDiagnostic> codecDiagnostics;

  @override
  State<_AutomatonFragmentReviewDialog> createState() =>
      _AutomatonFragmentReviewDialogState();
}

class _AutomatonFragmentReviewDialogState
    extends State<_AutomatonFragmentReviewDialog> {
  late Set<String> _selectedStateIds;
  late ImportedInitialStatePolicy _initialPolicy;
  PdaConflictResolution _pdaAcceptance = PdaConflictResolution.reject;
  PdaConflictResolution _pdaStack = PdaConflictResolution.reject;
  late final TextEditingController _anchorX;
  late final TextEditingController _anchorY;
  var _anchorFieldsInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedStateIds = _stateIds(widget.source).toSet();
    _initialPolicy =
        _hasInitial(widget.destination) && _hasInitial(widget.source)
        ? ImportedInitialStatePolicy.keepDestination
        : ImportedInitialStatePolicy.reject;
    _anchorX = TextEditingController();
    _anchorY = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_anchorFieldsInitialized) return;
    final formatter = LocaleValueFormatter.of(context);
    _anchorX.text = formatter.decimal(widget.initialAnchor.x, decimalDigits: 1);
    _anchorY.text = formatter.decimal(widget.initialAnchor.y, decimalDigits: 1);
    _anchorFieldsInitialized = true;
  }

  @override
  void dispose() {
    _anchorX.dispose();
    _anchorY.dispose();
    super.dispose();
  }

  Vector2 get _anchor => Vector2(
    _parseLocalizedCoordinate(context, _anchorX.text) ?? widget.initialAnchor.x,
    _parseLocalizedCoordinate(context, _anchorY.text) ?? widget.initialAnchor.y,
  );

  AutomatonFragmentPlan get _plan => AutomatonFragmentCombiner.prepare(
    AutomatonFragmentRequest(
      destination: widget.destination,
      source: widget.source,
      destinationAnnotations: widget.destinationAnnotations,
      sourceAnnotations: widget.sourceAnnotations,
      destinationRevision: widget.destinationRevision,
      selectedStateIds: _selectedStateIds,
      insertionAnchor: _anchor,
      initialStatePolicy: _initialPolicy,
      pdaAcceptanceResolution: _pdaAcceptance,
      pdaInitialStackResolution: _pdaStack,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final plan = _plan;
    final configurationChanges = _configurationChanges(
      l10n,
      widget.destination,
      plan.preview,
    );
    final states = _stateIds(widget.source);
    final hasInitialConflict =
        _hasInitial(widget.destination) && _hasInitial(widget.source);
    final pdaDestination = widget.destination;
    final pdaSource = widget.source;
    final acceptanceConflict =
        pdaDestination is PDA &&
        pdaSource is PDA &&
        pdaDestination.acceptanceMode != pdaSource.acceptanceMode;
    final stackConflict =
        pdaDestination is PDA &&
        pdaSource is PDA &&
        pdaDestination.initialStackSymbol != pdaSource.initialStackSymbol;
    return AlertDialog(
      title: Text(l10n.automatonFragmentPreviewTitle),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.automatonFragmentSourceFidelity(
                  _fidelityLabel(l10n, widget.fidelity),
                ),
              ),
              if (widget.codecDiagnostics.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final diagnostic in widget.codecDiagnostics)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '• '),
                        TextSpan(
                          text: l10n.localizedAutomatonFragmentCodecDiagnostic(
                            diagnostic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.automatonFragmentStatesToImport,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final id in states)
                      MergeSemantics(
                        key: ValueKey('fragment-state-$id'),
                        child: Semantics(
                          label: l10n.canvasStateSemantics(id),
                          child: CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: ExcludeSemantics(child: Text(id)),
                            value: _selectedStateIds.contains(id),
                            onChanged: (selected) => setState(() {
                              if (selected == true) {
                                _selectedStateIds.add(id);
                              } else {
                                _selectedStateIds.remove(id);
                              }
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.automatonFragmentInsertionAnchor,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _anchorX,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'X'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _anchorY,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Y'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              if (hasInitialConflict) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<ImportedInitialStatePolicy>(
                  key: const ValueKey('fragment-initial-policy'),
                  initialValue: _initialPolicy,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.automatonFragmentInitialStateAfterImport,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: ImportedInitialStatePolicy.keepDestination,
                      child: Text(
                        l10n.automatonFragmentKeepCurrentInitialState,
                      ),
                    ),
                    DropdownMenuItem(
                      value: ImportedInitialStatePolicy.useImported,
                      child: Text(
                        l10n.automatonFragmentUseImportedInitialState,
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _initialPolicy = value);
                  },
                ),
              ],
              if (acceptanceConflict)
                CheckboxListTile(
                  key: const ValueKey('fragment-pda-acceptance-resolution'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.automatonFragmentUseDestinationAcceptance),
                  subtitle: Text(l10n.automatonFragmentSourceModeDiffers),
                  value: _pdaAcceptance == PdaConflictResolution.useDestination,
                  onChanged: (selected) => setState(() {
                    _pdaAcceptance = selected == true
                        ? PdaConflictResolution.useDestination
                        : PdaConflictResolution.reject;
                  }),
                ),
              if (stackConflict)
                CheckboxListTile(
                  key: const ValueKey('fragment-pda-stack-resolution'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.automatonFragmentUseDestinationStackSymbol),
                  subtitle: Text(l10n.automatonFragmentSourceSymbolDiffers),
                  value: _pdaStack == PdaConflictResolution.useDestination,
                  onChanged: (selected) => setState(() {
                    _pdaStack = selected == true
                        ? PdaConflictResolution.useDestination
                        : PdaConflictResolution.reject;
                  }),
                ),
              const SizedBox(height: 16),
              Text(
                l10n.automatonFragmentExactChanges,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                l10n.automatonFragmentCloneSummary(
                  plan.importedStateIds.length,
                  plan.importedTransitionIds.length,
                  plan.annotationSourceMap.length,
                  plan.blockSourceMap.length,
                ),
              ),
              for (final change in configurationChanges)
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '• '),
                      TextSpan(text: change),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(l10n.automatonFragmentStructuralImportExplanation),
              if (plan.diagnostics.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final diagnostic in plan.diagnostics)
                  _DiagnosticRow(diagnostic: diagnostic),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('fragment-apply-button'),
          onPressed: plan.canCommit
              ? () => Navigator.of(context).pop(plan)
              : null,
          child: Text(l10n.apply),
        ),
      ],
    );
  }
}

double? _parseLocalizedCoordinate(BuildContext context, String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) return null;
  final format = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  );
  final decimalSeparator = format.symbols.DECIMAL_SEP;
  final alternateDecimalSeparator = decimalSeparator == ',' ? '.' : ',';
  if (trimmed.contains(alternateDecimalSeparator) &&
      !trimmed.contains(decimalSeparator)) {
    final separatorCount = alternateDecimalSeparator.allMatches(trimmed).length;
    final fractionalLength =
        trimmed.length - trimmed.lastIndexOf(alternateDecimalSeparator) - 1;
    if (separatorCount == 1 && fractionalLength != 3) {
      final normalized = trimmed.replaceAll(alternateDecimalSeparator, '.');
      final alternateDecimal = double.tryParse(normalized);
      if (alternateDecimal != null) return alternateDecimal;
    }
  }
  return format.tryParse(trimmed)?.toDouble() ?? double.tryParse(trimmed);
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.diagnostic});

  final AutomatonFragmentDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final blocking = diagnostic.isBlocking;
    final color = blocking
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;
    return Semantics(
      liveRegion: blocking,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              blocking ? Icons.error_outline : Icons.info_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.localizedAutomatonFragmentDiagnostic(diagnostic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _stateIds(Object document) {
  final values = switch (document) {
    FSA(:final states) => states.map((state) => state.id),
    PDA(:final states) => states.map((state) => state.id),
    TM(:final states) => states.map((state) => state.id),
    MealyMachine(:final states) => states.map((state) => state.id.value),
    MooreMachine(:final states) => states.map((state) => state.id.value),
    _ => const Iterable<String>.empty(),
  };
  return values.toList()..sort();
}

bool _hasInitial(Object document) => switch (document) {
  FSA(:final states) => states.any((state) => state.isInitial),
  PDA(:final states) => states.any((state) => state.isInitial),
  TM(:final states) => states.any((state) => state.isInitial),
  MealyMachine(:final states) => states.any((state) => state.isInitial),
  MooreMachine(:final states) => states.any((state) => state.isInitial),
  _ => false,
};

List<String> _configurationChanges(
  AppLocalizations l10n,
  Object destination,
  Object? preview,
) {
  if (preview == null) return const [];
  final changes = <String>[];
  switch ((destination, preview)) {
    case (final FSA destination, final FSA result):
      changes.add(
        _setAddition(
          l10n,
          l10n.automatonFragmentInputAlphabet,
          destination.alphabet,
          result.alphabet,
        ),
      );
    case (final PDA destination, final PDA result):
      changes
        ..add(
          _setAddition(
            l10n,
            l10n.automatonFragmentInputAlphabet,
            destination.alphabet,
            result.alphabet,
          ),
        )
        ..add(
          _setAddition(
            l10n,
            l10n.automatonFragmentStackAlphabet,
            destination.stackAlphabet,
            result.stackAlphabet,
          ),
        )
        ..add(
          l10n.automatonFragmentAcceptanceModeUnchanged(
            _acceptanceModeLabel(l10n, result.acceptanceMode),
          ),
        )
        ..add(
          l10n.automatonFragmentInitialStackSymbolUnchanged(
            result.initialStackSymbol,
          ),
        );
    case (final TM destination, final TM result):
      changes
        ..add(
          _setAddition(
            l10n,
            l10n.automatonFragmentInputAlphabet,
            destination.alphabet,
            result.alphabet,
          ),
        )
        ..add(
          _setAddition(
            l10n,
            l10n.automatonFragmentTapeAlphabet,
            destination.tapeAlphabet,
            result.tapeAlphabet,
          ),
        )
        ..add(
          l10n.automatonFragmentTapeConfigurationUnchanged(
            result.tapeCount,
            result.blankSymbol,
          ),
        );
    case (final MealyMachine destination, final MealyMachine result):
      changes
        ..add(
          _setAddition(
            l10n,
            l10n.automatonFragmentInputAlphabet,
            destination.inputAlphabet.map((symbol) => symbol.value).toSet(),
            result.inputAlphabet.map((symbol) => symbol.value).toSet(),
          ),
        )
        ..add(
          _setAddition(
            l10n,
            l10n.automatonFragmentOutputAlphabet,
            destination.outputAlphabet.map((symbol) => symbol.value).toSet(),
            result.outputAlphabet.map((symbol) => symbol.value).toSet(),
          ),
        );
    case (final MooreMachine destination, final MooreMachine result):
      changes
        ..add(
          _setAddition(
            l10n,
            l10n.automatonFragmentInputAlphabet,
            destination.inputAlphabet.map((symbol) => symbol.value).toSet(),
            result.inputAlphabet.map((symbol) => symbol.value).toSet(),
          ),
        )
        ..add(
          _setAddition(
            l10n,
            l10n.automatonFragmentOutputAlphabet,
            destination.outputAlphabet.map((symbol) => symbol.value).toSet(),
            result.outputAlphabet.map((symbol) => symbol.value).toSet(),
          ),
        );
    default:
      break;
  }
  final beforeInitial = _initialStateId(destination);
  final afterInitial = _initialStateId(preview);
  changes.add(
    beforeInitial == afterInitial
        ? l10n.automatonFragmentInitialStateUnchanged(
            afterInitial ?? l10n.automatonFragmentUnset,
          )
        : l10n.automatonFragmentInitialStateChanged(
            beforeInitial ?? l10n.automatonFragmentUnset,
            afterInitial ?? l10n.automatonFragmentUnset,
          ),
  );
  return changes;
}

String _setAddition(
  AppLocalizations l10n,
  String label,
  Set<String> before,
  Set<String> after,
) {
  final added = after.difference(before).toList()..sort();
  return added.isEmpty
      ? l10n.automatonFragmentSetUnchanged(label)
      : l10n.automatonFragmentSetAdds(label, added.join(', '));
}

String _fidelityLabel(AppLocalizations l10n, DocumentFidelity fidelity) =>
    switch (fidelity) {
      DocumentFidelity.exact => l10n.interoperabilityFidelityExact,
      DocumentFidelity.normalized => l10n.interoperabilityFidelityNormalized,
      DocumentFidelity.lossy => l10n.interoperabilityFidelityLossy,
    };

String _acceptanceModeLabel(AppLocalizations l10n, PDAAcceptanceMode mode) =>
    switch (mode) {
      PDAAcceptanceMode.finalState => l10n.acceptanceModeFinalState,
      PDAAcceptanceMode.emptyStack => l10n.acceptanceModeEmptyStack,
      PDAAcceptanceMode.both => l10n.acceptanceModeBoth,
    };

String? _initialStateId(Object document) => switch (document) {
  FSA(:final initialState) => initialState?.id,
  PDA(:final initialState) => initialState?.id,
  TM(:final initialState) => initialState?.id,
  MealyMachine(:final states) => _transducerInitialId(states),
  MooreMachine(:final states) => _transducerInitialId(states),
  _ => null,
};

String? _transducerInitialId(Iterable<TransducerState> states) {
  for (final state in states) {
    if (state.isInitial) return state.id.value;
  }
  return null;
}

String _failureMessage(BuildContext context, CodecOutcome<Object?> outcome) {
  final l10n = appLocalizationsOf(context);
  final isPortuguese = l10n.localeName.toLowerCase().startsWith('pt');
  final structuredMessage = switch (outcome) {
    CodecUnsupported(:final structuredMessage) => structuredMessage,
    CodecMalformed(:final structuredMessage) => structuredMessage,
    CodecInternalFailure(:final structuredMessage) => structuredMessage,
    _ => null,
  };
  if (structuredMessage != null) {
    return l10n.resolveStructuredMessage(structuredMessage);
  }
  return switch (outcome) {
    CodecUnsupported(:final reason, :final message) =>
      isPortuguese
          ? _unsupportedCodecFailureDescription(l10n, reason)
          : message,
    CodecAmbiguous(:final codecIds) =>
      l10n.interoperabilityAmbiguousDescription(
        codecIds.map((id) => id.value).join(', '),
      ),
    CodecMalformed(:final reason, :final message) =>
      isPortuguese ? _malformedCodecFailureDescription(l10n, reason) : message,
    CodecResourceLimit(:final limit, :final maximum, :final actual) =>
      l10n.interoperabilityResourceLimitDescription(
        _codecLimitLabel(l10n, limit),
        actual,
        maximum,
      ),
    CodecInternalFailure(:final message) =>
      isPortuguese ? l10n.interoperabilityInternalFailureDescription : message,
    CodecSuccess() => throw StateError('codec.success-not-a-failure'),
  };
}

String _unsupportedCodecFailureDescription(
  AppLocalizations l10n,
  CodecUnsupportedReason reason,
) => switch (reason) {
  CodecUnsupportedReason.document => l10n.interoperabilityUnsupportedDocument,
  CodecUnsupportedReason.feature => l10n.interoperabilityUnsupportedFeature,
  CodecUnsupportedReason.schema => l10n.interoperabilityUnsupportedSchema,
  CodecUnsupportedReason.format => l10n.interoperabilityUnsupportedFormat,
  CodecUnsupportedReason.direction => l10n.interoperabilityUnsupportedDirection,
};

String _malformedCodecFailureDescription(
  AppLocalizations l10n,
  CodecMalformedReason reason,
) => switch (reason) {
  CodecMalformedReason.syntax => l10n.interoperabilityMalformedSyntax,
  CodecMalformedReason.invalidUtf8 => l10n.interoperabilityMalformedUtf8,
  CodecMalformedReason.missingField =>
    l10n.interoperabilityMalformedMissingField,
  CodecMalformedReason.invalidValue =>
    l10n.interoperabilityMalformedInvalidValue,
  CodecMalformedReason.duplicateIdentity =>
    l10n.interoperabilityMalformedDuplicateIdentity,
};

String _codecLimitLabel(AppLocalizations l10n, CodecResourceLimitKind limit) =>
    switch (limit) {
      CodecResourceLimitKind.bytes => l10n.interoperabilityLimitBytes,
      CodecResourceLimitKind.xmlDepth => l10n.interoperabilityLimitXmlDepth,
      CodecResourceLimitKind.xmlElements =>
        l10n.interoperabilityLimitXmlElements,
      CodecResourceLimitKind.xmlDtdOrEntity =>
        l10n.interoperabilityLimitXmlDtdOrEntity,
      CodecResourceLimitKind.jsonDepth => l10n.interoperabilityLimitJsonDepth,
      CodecResourceLimitKind.collectionEntries =>
        l10n.interoperabilityLimitCollectionEntries,
    };
