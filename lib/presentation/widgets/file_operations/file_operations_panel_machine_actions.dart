part of '../file_operations_panel.dart';

extension _FileOperationsPanelMachineActions on _FileOperationsPanelState {
  Future<void> _performTextFileAction({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required String Function() contentsProvider,
    required Future<StringResult> Function(String targetName) webSaveCall,
    required Future<StringResult> Function(String path) writeToPath,
    required String cancelMessage,
    required String Function(Result<String> result) successMessageBuilder,
    required String Function(String error) formatFailure,
    required String Function(String error) formatException,
    required Future<void> Function() retryOperation,
  }) async {
    _updatePanelState(() => _isLoading = true);

    try {
      Result<String>? result;

      if (kIsWeb) {
        result = await webSaveCall(fileName);
      } else {
        result = await _saveTextFileWithPicker(
          dialogTitle: dialogTitle,
          fileName: fileName,
          allowedExtensions: allowedExtensions,
          contents: contentsProvider(),
          writeToPath: writeToPath,
          cancelMessage: cancelMessage,
        );

        if (result == null) {
          return;
        }
      }

      if (result.isSuccess) {
        _showSuccessMessage(successMessageBuilder(result));
      } else {
        _showErrorMessage(
          formatFailure(_localizedFailure(result)),
          retryOperation: retryOperation,
        );
      }
    } on CodecOperationException catch (e) {
      _showErrorMessage(
        formatException(_localizedException(e)),
        retryOperation: retryOperation,
      );
    } catch (e, stackTrace) {
      _showErrorMessage(
        formatException(_localizedException(e)),
        retryOperation: retryOperation,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveGrammarAsJFLAP() async {
    if (widget.grammar == null) return;
    final grammar = widget.grammar!;
    final fileName = '${grammar.name}.cfg';

    await _performTextFileAction(
      dialogTitle: _l10n.saveGrammarAsJflap,
      fileName: fileName,
      allowedExtensions: const ['cfg'],
      contentsProvider: () =>
          _fileService.serializeGrammarToJFLAPString(grammar),
      webSaveCall: (targetName) =>
          _fileService.saveGrammarToJFLAP(grammar, targetName),
      writeToPath: (path) => _fileService.saveGrammarToJFLAP(grammar, path),
      cancelMessage: _l10n.saveCanceled,
      successMessageBuilder: (result) => kIsWeb
          ? _l10n.downloadStartedFor(result.data ?? 'grammar.cfg')
          : _l10n.grammarSavedSuccessfully,
      formatFailure: _l10n.failedToSaveGrammar,
      formatException: _l10n.errorSavingGrammar,
      retryOperation: _saveGrammarAsJFLAP,
    );
  }

  Future<void> _loadGrammarFromJFLAP() async {
    _updatePanelState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cfg'],
        dialogTitle: _l10n.loadJflapGrammar,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final loadResult = await loadGrammarFromPlatformFile(
          _fileService,
          file,
        );

        if (loadResult.isSuccess) {
          widget.onGrammarLoaded?.call(loadResult.data!);
          _showSuccessMessage(_l10n.grammarLoadedSuccessfully);
        } else {
          await _handleImportFailure(
            fileName: file.name,
            errorMessage: _localizedFailure(loadResult),
            retryOperation: _loadGrammarFromJFLAP,
          );
        }
      } else {
        _showOperationCancelledMessage(_l10n.importCanceled);
      }
    } catch (e, stackTrace) {
      await _handleImportFailure(
        fileName: _l10n.fileSectionGrammar,
        errorMessage: _l10n.errorLoadingGrammar('$e'),
        retryOperation: _loadGrammarFromJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportGrammarAsSVG() async {
    if (widget.grammar == null) return;
    final grammar = widget.grammar!;
    final fileName = '${grammar.name}.svg';

    await _performTextFileAction(
      dialogTitle: _l10n.exportGrammarAsSvg,
      fileName: fileName,
      allowedExtensions: const ['svg'],
      contentsProvider: () => _fileService.exportGrammarModelToSvgString(
        grammar,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      webSaveCall: (targetName) => _fileService.exportGrammarModelToSVG(
        grammar,
        targetName,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      writeToPath: (path) => _fileService.exportGrammarModelToSVG(
        grammar,
        path,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      cancelMessage: _l10n.exportCanceled,
      successMessageBuilder: (result) => kIsWeb
          ? _l10n.downloadStartedFor(result.data ?? 'grammar.svg')
          : _l10n.grammarExportedSuccessfully,
      formatFailure: _l10n.failedToExportGrammar,
      formatException: _l10n.errorExportingGrammar,
      retryOperation: _exportGrammarAsSVG,
    );
  }

  Future<void> _exportPdaAsSVG() async {
    if (widget.pda == null) return;
    final pda = widget.pda!;
    final fileName = '${pda.name}.svg';

    await _performTextFileAction(
      dialogTitle: _l10n.exportPdaAsSvg,
      fileName: fileName,
      allowedExtensions: const ['svg'],
      contentsProvider: () => _fileService.exportPdaToSvgString(
        pda,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      webSaveCall: (targetName) => _fileService.exportPdaToSVG(
        pda,
        targetName,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      writeToPath: (path) => _fileService.exportPdaToSVG(
        pda,
        path,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      cancelMessage: _l10n.exportCanceled,
      successMessageBuilder: (result) => kIsWeb
          ? _l10n.downloadStartedFor(result.data ?? 'pda.svg')
          : _l10n.pdaExportedSuccessfully,
      formatFailure: _l10n.failedToExportPda,
      formatException: _l10n.errorExportingPda,
      retryOperation: _exportPdaAsSVG,
    );
  }

  Future<void> _exportTuringMachineAsSVG() async {
    if (widget.turingMachine == null) return;
    final turingMachine = widget.turingMachine!;
    final tmEntity = _convertTmToEntity(turingMachine);
    final fileName = '${turingMachine.name}.svg';

    await _performTextFileAction(
      dialogTitle: _l10n.exportTmAsSvg,
      fileName: fileName,
      allowedExtensions: const ['svg'],
      contentsProvider: () => _fileService.exportTuringMachineToSvgString(
        tmEntity,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      webSaveCall: (targetName) => _fileService.exportTuringMachineToSVG(
        tmEntity,
        targetName,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      writeToPath: (path) => _fileService.exportTuringMachineToSVG(
        tmEntity,
        path,
        emptyAutomatonLabel: _svgEmptyAutomatonLabel,
        tmLegendLabel: _svgTmLegendLabel,
        emptyStringSymbol: _emptyStringSymbol,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      ),
      cancelMessage: _l10n.exportCanceled,
      successMessageBuilder: (result) => kIsWeb
          ? _l10n.downloadStartedFor(result.data ?? 'tm.svg')
          : _l10n.tmExportedSuccessfully,
      formatFailure: _l10n.failedToExportTm,
      formatException: _l10n.errorExportingTm,
      retryOperation: _exportTuringMachineAsSVG,
    );
  }
}
