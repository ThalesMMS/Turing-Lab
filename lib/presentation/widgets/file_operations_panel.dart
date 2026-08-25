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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/entities/turing_machine_entity.dart';
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
import '../../l10n/app_localizations_workflows.dart';
import 'utils/platform_file_loader.dart';
import 'error_banner.dart';
import 'import_error_dialog.dart';

part 'file_operations/file_operations_panel_picker_helpers.dart';
part 'file_operations/file_operations_panel_fsa_actions.dart';
part 'file_operations/file_operations_panel_machine_actions.dart';
part 'file_operations/file_operations_panel_converters.dart';
part 'file_operations/file_operations_panel_feedback.dart';

class _FileOperationCapabilities {
  const _FileOperationCapabilities({
    this.supportsJflapImport = false,
    this.supportsJflapExport = false,
    this.supportsJsonImport = false,
    this.supportsJsonExport = false,
    this.supportsSvgExport = false,
    this.supportsPngExport = false,
  });

  final bool supportsJflapImport;
  final bool supportsJflapExport;
  final bool supportsJsonImport;
  final bool supportsJsonExport;
  final bool supportsSvgExport;
  final bool supportsPngExport;
}

const _fsaCapabilities = _FileOperationCapabilities(
  supportsJflapImport: true,
  supportsJflapExport: true,
  supportsJsonImport: true,
  supportsJsonExport: true,
  supportsSvgExport: true,
  supportsPngExport: true,
);

const _grammarCapabilities = _FileOperationCapabilities(
  supportsJflapImport: true,
  supportsJflapExport: true,
  supportsSvgExport: true,
);

const _pdaCapabilities = _FileOperationCapabilities(
  supportsSvgExport: true,
);

const _tmCapabilities = _FileOperationCapabilities(
  supportsSvgExport: true,
);

const _kFsaJflapExportButtonKey = ValueKey<String>(
  'fsa_jflap_export_button',
);
const _kFsaJflapImportButtonKey = ValueKey<String>(
  'fsa_jflap_import_button',
);
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

  const FileOperationsPanel({
    super.key,
    this.automaton,
    this.grammar,
    this.pda,
    this.turingMachine,
    this.onAutomatonLoaded,
    this.onGrammarLoaded,
    this.fileService,
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
  late final FileOperationsGateway _fileService;
  bool _isLoading = false;
  _PanelFeedback? _feedback;
  Future<void> Function()? _pendingRetry;

  AppLocalizations get _l10n => appLocalizationsOf(context);

  String get _svgEmptyAutomatonLabel => _l10n.svgNoStatesDefined;

  String get _svgTmLegendLabel => _l10n.svgTmLegend;

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

            // FSA operations
            if (widget.automaton != null) ...[
              _buildSectionTitle(l10n.fileSectionFsa),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_fsaCapabilities.supportsJflapExport)
                    _buildButton(
                      kIsWeb ? l10n.downloadJflap : l10n.saveAsJflap,
                      Icons.save,
                      () => _saveAutomatonAsJFLAP(),
                      key: _kFsaJflapExportButtonKey,
                    ),
                  if (_fsaCapabilities.supportsJflapImport)
                    _buildButton(
                      l10n.loadJflap,
                      Icons.folder_open,
                      () => _loadAutomatonFromJFLAP(),
                      key: _kFsaJflapImportButtonKey,
                    ),
                  if (_fsaCapabilities.supportsJsonExport)
                    _buildButton(
                      kIsWeb ? l10n.downloadJson : l10n.saveAsJson,
                      Icons.data_object,
                      () => _saveAutomatonAsJson(),
                      key: _kFsaJsonExportButtonKey,
                    ),
                  if (_fsaCapabilities.supportsJsonImport)
                    _buildButton(
                      l10n.loadJson,
                      Icons.upload_file,
                      () => _loadAutomatonFromJson(),
                      key: _kFsaJsonImportButtonKey,
                    ),
                  if (_fsaCapabilities.supportsSvgExport)
                    _buildButton(
                      kIsWeb ? l10n.downloadSvg : l10n.exportSvg,
                      Icons.image,
                      () => _exportAutomatonAsSVG(),
                      key: _kFsaSvgExportButtonKey,
                    ),
                  if (_fsaCapabilities.supportsPngExport && !kIsWeb)
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
            if (widget.grammar != null) ...[
              _buildSectionTitle(l10n.fileSectionGrammar),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_grammarCapabilities.supportsJflapExport)
                    _buildButton(
                      kIsWeb ? l10n.downloadJflap : l10n.saveAsJflap,
                      Icons.save,
                      () => _saveGrammarAsJFLAP(),
                    ),
                  if (_grammarCapabilities.supportsJflapImport)
                    _buildButton(
                      l10n.loadJflap,
                      Icons.folder_open,
                      () => _loadGrammarFromJFLAP(),
                    ),
                  if (_grammarCapabilities.supportsSvgExport)
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
                  if (_pdaCapabilities.supportsSvgExport)
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
                  if (_tmCapabilities.supportsSvgExport)
                    _buildButton(
                      kIsWeb ? l10n.downloadSvg : l10n.exportSvg,
                      Icons.image,
                      () => _exportTuringMachineAsSVG(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
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
