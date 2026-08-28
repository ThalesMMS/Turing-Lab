//
//  file_operations_panel.dart
//  Turing Lab
//
//  UI panel that groups save, load, and export actions for automata,
//  grammars, PDAs, and Turing machines in the supported formats, showing
//  only the operations each module is allowed by the release scope.
//  The widget orchestrates FileOperationsService, talks to FilePicker,
//  and shows progress for async operations, updating host-screen
//  callbacks.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/entities/turing_machine_entity.dart';
import '../../core/annotations/document_annotation_collection.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/result.dart';
import '../../core/services/file_operations_gateway.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'utils/platform_file_loader.dart';
import 'error_banner.dart';
import 'document_interoperability_binding.dart';
import 'document_interoperability_failure_dialog.dart';
import 'document_interoperability_preview.dart';
import 'document_interoperability_review_dialog.dart';
import 'import_error_dialog.dart';
import 'interoperability_presentation_labels.dart';
import 'registered_file_operation.dart';
import 'visual_export_binding.dart';

part 'file_operations/file_operations_panel_picker_helpers.dart';
part 'file_operations/file_operations_panel_fsa_actions.dart';
part 'file_operations/file_operations_panel_machine_actions.dart';
part 'file_operations/file_operations_panel_converters.dart';
part 'file_operations/file_operations_panel_feedback.dart';
part 'file_operations/file_operations_panel_interoperability.dart';
part 'file_operations/file_operations_panel_visual_export.dart';

const _kFsaJflapExportButtonKey = ValueKey<String>('fsa_jflap_export_button');
const _kFsaJflapImportButtonKey = ValueKey<String>('fsa_jflap_import_button');
const _kFsaJsonExportButtonKey = ValueKey<String>('fsa_json_export_button');
const _kFsaJsonImportButtonKey = ValueKey<String>('fsa_json_import_button');
const _kFsaSvgExportButtonKey = ValueKey<String>('fsa_svg_export_button');
const _kFsaPngExportButtonKey = ValueKey<String>('fsa_png_export_button');

String? _normalizedJsonPath(String? path) {
  if (path == null) {
    return null;
  }

  final trimmed = path.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Panel for file operations (save/load/export)
class FileOperationsPanel extends StatefulWidget {
  final FSA? automaton;
  final Grammar? grammar;
  final PDA? pda;
  final TM? turingMachine;
  final ValueChanged<FSA>? onAutomatonLoaded;
  final ValueChanged<Grammar>? onGrammarLoaded;
  final FileOperationsGateway? fileService;
  final FormalSystemRegistry? formalSystemRegistry;
  final FormalSystemKey automatonSystemKey;
  final FormalSystemKey? registeredSystemKey;
  final String? registeredSectionLabel;
  final List<RegisteredFileOperation> registeredOperations;
  final DocumentInteroperabilityBinding? interoperability;
  final VisualExportBinding? visualExport;
  final DocumentAnnotationCollection? annotations;

  const FileOperationsPanel({
    super.key,
    this.automaton,
    this.grammar,
    this.pda,
    this.turingMachine,
    this.onAutomatonLoaded,
    this.onGrammarLoaded,
    this.fileService,
    this.formalSystemRegistry,
    this.automatonSystemKey = DefaultFormalSystemIds.fsa,
    this.registeredSystemKey,
    this.registeredSectionLabel,
    this.registeredOperations = const [],
    this.interoperability,
    this.visualExport,
    this.annotations,
  });

  @override
  State<FileOperationsPanel> createState() => _FileOperationsPanelState();
}

class _PanelFeedback {
  const _PanelFeedback({
    required this.message,
    required this.severity,
    this.canRetry = false,
  });

  final String message;
  final ErrorSeverity severity;
  final bool canRetry;
}

class _FileOperationsPanelState extends State<FileOperationsPanel> {
  bool _includeAnnotationsInVisualExports = false;
  late final FileOperationsGateway _fileService;
  bool _isLoading = false;
  _PanelFeedback? _feedback;
  Future<void> Function()? _pendingRetry;

  AppLocalizations get _l10n => appLocalizationsOf(context);

  String _localizedFailure<T>(Result<T> result) {
    final structuredMessage = result.structuredError;
    if (structuredMessage != null) {
      return _l10n.resolveStructuredMessage(structuredMessage);
    }
    return result.error ?? _l10n.unknownError;
  }

  String _localizedException(Object error) {
    if (error case CodecOperationException(:final structuredMessage)) {
      return _l10n.resolveStructuredMessage(structuredMessage);
    }
    return _l10n.localizeWorkflowText('$error');
  }

  String get _svgEmptyAutomatonLabel => _l10n.svgNoStatesDefined;

  String get _svgTmLegendLabel => _l10n.svgTmLegend;

  FormalSystemRegistry get _registry =>
      widget.formalSystemRegistry ?? FormalSystemRegistry.defaultRegistry;

  bool _supports(
    FormalSystemKey key,
    DocumentFormatId format,
    DocumentFormatDirection direction,
  ) {
    return _registry
            .descriptorFor(key)
            ?.formatSupport(format)
            ?.supports(direction) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    _fileService = widget.fileService ?? createFileOperationsGateway();
  }

  void _updatePanelState(VoidCallback callback) {
    if (!mounted) {
      return;
    }
    setState(callback);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final registeredSystemKey = widget.registeredSystemKey;
    final visibleRegisteredOperations = registeredSystemKey == null
        ? const <RegisteredFileOperation>[]
        : widget.registeredOperations
              .where(
                (operation) => _supports(
                  registeredSystemKey,
                  operation.format,
                  operation.direction,
                ),
              )
              .toList(growable: false);
    final interoperability = widget.interoperability;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_feedback != null) ...[
              ErrorBanner(
                message: _feedback!.message,
                severity: _feedback!.severity,
                showRetryButton: _feedback!.canRetry && !_isLoading,
                onRetry: _feedback!.canRetry && !_isLoading
                    ? _retryLastOperation
                    : null,
                onDismiss: _dismissFeedback,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              l10n.fileOperationsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (interoperability != null) ...[
              _buildInteroperabilitySection(interoperability),
              const SizedBox(height: 16),
            ],

            if (widget.visualExport case final visualExport?) ...[
              _buildVisualExportSection(
                visualExport,
                showTitle: interoperability == null,
              ),
              const SizedBox(height: 16),
            ],

            // FSA operations
            if ((widget.automaton != null ||
                    widget.onAutomatonLoaded != null) &&
                interoperability?.systemKey != widget.automatonSystemKey) ...[
              _buildSectionTitle(l10n.fileSectionFsa),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.automaton != null &&
                      _supports(
                        widget.automatonSystemKey,
                        DefaultFormalSystemIds.jflapXmlFormat,
                        DocumentFormatDirection.exportDocument,
                      ))
                    _buildButton(
                      kIsWeb ? l10n.downloadJflap : l10n.saveAsJflap,
                      Icons.save,
                      () => _saveAutomatonAsJFLAP(),
                      key: _kFsaJflapExportButtonKey,
                    ),
                  if (_supports(
                    widget.automatonSystemKey,
                    DefaultFormalSystemIds.jflapXmlFormat,
                    DocumentFormatDirection.importDocument,
                  ))
                    _buildButton(
                      l10n.loadJflap,
                      Icons.folder_open,
                      () => _loadAutomatonFromJFLAP(),
                      key: _kFsaJflapImportButtonKey,
                    ),
                  if (widget.automaton != null &&
                      _supports(
                        widget.automatonSystemKey,
                        DefaultFormalSystemIds.turingLabJsonFormat,
                        DocumentFormatDirection.exportDocument,
                      ))
                    _buildButton(
                      kIsWeb ? l10n.downloadJson : l10n.saveAsJson,
                      Icons.data_object,
                      () => _saveAutomatonAsJson(),
                      key: _kFsaJsonExportButtonKey,
                    ),
                  if (_supports(
                    widget.automatonSystemKey,
                    DefaultFormalSystemIds.turingLabJsonFormat,
                    DocumentFormatDirection.importDocument,
                  ))
                    _buildButton(
                      l10n.loadJson,
                      Icons.upload_file,
                      () => _loadAutomatonFromJson(),
                      key: _kFsaJsonImportButtonKey,
                    ),
                  if (widget.automaton != null &&
                      _supports(
                        widget.automatonSystemKey,
                        DefaultFormalSystemIds.svgFormat,
                        DocumentFormatDirection.exportDocument,
                      ))
                    _buildButton(
                      kIsWeb ? l10n.downloadSvg : l10n.exportSvg,
                      Icons.image,
                      () => _exportAutomatonAsSVG(),
                      key: _kFsaSvgExportButtonKey,
                    ),
                  if (widget.automaton != null &&
                      _supports(
                        widget.automatonSystemKey,
                        DefaultFormalSystemIds.pngFormat,
                        DocumentFormatDirection.exportDocument,
                      ) &&
                      !kIsWeb)
                    _buildButton(
                      l10n.exportPng,
                      Icons.photo,
                      () => _exportAutomatonAsPNG(),
                      key: _kFsaPngExportButtonKey,
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Grammar operations
            if (widget.grammar != null &&
                interoperability?.systemKey !=
                    DefaultFormalSystemIds.grammar) ...[
              _buildSectionTitle(l10n.fileSectionGrammar),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_supports(
                    DefaultFormalSystemIds.grammar,
                    DefaultFormalSystemIds.jflapXmlFormat,
                    DocumentFormatDirection.exportDocument,
                  ))
                    _buildButton(
                      kIsWeb ? l10n.downloadJflap : l10n.saveAsJflap,
                      Icons.save,
                      () => _saveGrammarAsJFLAP(),
                    ),
                  if (_supports(
                    DefaultFormalSystemIds.grammar,
                    DefaultFormalSystemIds.jflapXmlFormat,
                    DocumentFormatDirection.importDocument,
                  ))
                    _buildButton(
                      l10n.loadJflap,
                      Icons.folder_open,
                      () => _loadGrammarFromJFLAP(),
                    ),
                  if (_supports(
                    DefaultFormalSystemIds.grammar,
                    DefaultFormalSystemIds.svgFormat,
                    DocumentFormatDirection.exportDocument,
                  ))
                    _buildButton(
                      kIsWeb ? l10n.downloadSvg : l10n.exportSvg,
                      Icons.image,
                      () => _exportGrammarAsSVG(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (widget.pda != null) ...[
              _buildSectionTitle(l10n.fileSectionPda),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_supports(
                    DefaultFormalSystemIds.pda,
                    DefaultFormalSystemIds.svgFormat,
                    DocumentFormatDirection.exportDocument,
                  ))
                    _buildButton(
                      kIsWeb ? l10n.downloadSvg : l10n.exportSvg,
                      Icons.image,
                      () => _exportPdaAsSVG(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (widget.turingMachine != null) ...[
              _buildSectionTitle(l10n.fileSectionTm),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_supports(
                    DefaultFormalSystemIds.tm,
                    DefaultFormalSystemIds.svgFormat,
                    DocumentFormatDirection.exportDocument,
                  ))
                    _buildButton(
                      kIsWeb ? l10n.downloadSvg : l10n.exportSvg,
                      Icons.image,
                      () => _exportTuringMachineAsSVG(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (visibleRegisteredOperations.isNotEmpty) ...[
              if (widget.registeredSectionLabel case final label?) ...[
                _buildSectionTitle(label),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final operation in visibleRegisteredOperations)
                    _buildButton(
                      operation.label,
                      operation.icon,
                      operation.onPressed,
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (widget.annotations?.annotations.isNotEmpty ?? false) ...[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(_l10n.includeNotesInVisualExports),
                subtitle: Text(_l10n.includeNotesInVisualExportsDescription),
                value: _includeAnnotationsInVisualExports,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(
                        () => _includeAnnotationsInVisualExports = value,
                      ),
              ),
              const SizedBox(height: 8),
            ],

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
