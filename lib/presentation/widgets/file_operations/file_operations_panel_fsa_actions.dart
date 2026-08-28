part of '../file_operations_panel.dart';

extension _FileOperationsPanelFsaActions on _FileOperationsPanelState {
  Future<void> _saveAutomatonAsJFLAP() async {
    if (widget.automaton == null) return;
    _updatePanelState(() => _isLoading = true);

    try {
      Result<String>? saveResult;

      if (kIsWeb) {
        saveResult = await _fileService.saveAutomatonToJFLAP(
          widget.automaton!,
          '${widget.automaton!.name}.jff',
        );
      } else {
        saveResult = await _saveTextFileWithPicker(
          dialogTitle: _l10n.saveAutomatonAsJflap,
          fileName: '${widget.automaton!.name}.jff',
          allowedExtensions: ['jff'],
          contents: _fileService.serializeAutomatonToJFLAPString(
            widget.automaton!,
          ),
          writeToPath: (path) =>
              _fileService.saveAutomatonToJFLAP(widget.automaton!, path),
        );

        if (saveResult == null) {
          return;
        }
      }

      if (saveResult.isSuccess) {
        final successMessage = kIsWeb
            ? _l10n.downloadStartedFor(saveResult.data ?? 'automaton.jff')
            : _l10n.automatonSavedSuccessfully;
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          _l10n.failedToSaveAutomaton(_localizedFailure(saveResult)),
          retryOperation: _saveAutomatonAsJFLAP,
        );
      }
    } on CodecOperationException catch (e) {
      _showErrorMessage(
        _l10n.errorSavingAutomaton(_localizedException(e)),
        retryOperation: _saveAutomatonAsJFLAP,
      );
    } catch (e, stackTrace) {
      _showErrorMessage(
        _l10n.errorSavingAutomaton(_localizedException(e)),
        retryOperation: _saveAutomatonAsJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAutomatonFromJFLAP() async {
    _updatePanelState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jff'],
        dialogTitle: _l10n.loadJflapAutomaton,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final loadResult = await loadAutomatonFromPlatformFile(
          _fileService,
          file,
        );

        if (loadResult.isSuccess) {
          widget.onAutomatonLoaded?.call(loadResult.data!);
          _showSuccessMessage(_l10n.automatonLoadedSuccessfully);
        } else {
          await _handleImportFailure(
            fileName: file.name,
            errorMessage: _localizedFailure(loadResult),
            retryOperation: _loadAutomatonFromJFLAP,
          );
        }
      } else {
        _showOperationCancelledMessage(_l10n.importCanceled);
      }
    } catch (e, stackTrace) {
      await _handleImportFailure(
        fileName: _l10n.fileSectionFsa,
        errorMessage: _l10n.errorLoadingAutomaton('$e'),
        retryOperation: _loadAutomatonFromJFLAP,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAutomatonAsJson() async {
    if (widget.automaton == null) return;
    _updatePanelState(() => _isLoading = true);

    try {
      Result<String>? saveResult;

      if (kIsWeb) {
        saveResult = await _fileService.saveAutomatonToJson(
          widget.automaton!,
          '${widget.automaton!.name}.json',
        );
      } else {
        saveResult = await _saveTextFileWithPicker(
          dialogTitle: _l10n.saveAutomatonAsJson,
          fileName: '${widget.automaton!.name}.json',
          allowedExtensions: ['json'],
          contents: _fileService.serializeAutomatonToJsonString(
            widget.automaton!,
          ),
          writeToPath: (path) =>
              _fileService.saveAutomatonToJson(widget.automaton!, path),
        );

        if (saveResult == null) {
          return;
        }
      }

      if (saveResult.isSuccess) {
        final successMessage = kIsWeb
            ? _l10n.downloadStartedFor(saveResult.data ?? 'automaton.json')
            : _l10n.automatonSavedSuccessfully;
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          _l10n.failedToSaveAutomatonJson(_localizedFailure(saveResult)),
          retryOperation: _saveAutomatonAsJson,
        );
      }
    } on CodecOperationException catch (e) {
      _showErrorMessage(
        _l10n.errorSavingAutomatonJson(_localizedException(e)),
        retryOperation: _saveAutomatonAsJson,
      );
    } catch (e, stackTrace) {
      _showErrorMessage(
        _l10n.errorSavingAutomatonJson(_localizedException(e)),
        retryOperation: _saveAutomatonAsJson,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAutomatonFromJson() async {
    _updatePanelState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: _l10n.loadAutomatonJson,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final loadResult = await _loadAutomatonJsonFromPlatformFile(file);

        if (loadResult.isSuccess) {
          widget.onAutomatonLoaded?.call(loadResult.data!);
          _showSuccessMessage(_l10n.automatonLoadedSuccessfully);
        } else {
          await _handleImportFailure(
            fileName: file.name,
            errorMessage: _localizedFailure(loadResult),
            retryOperation: _loadAutomatonFromJson,
          );
        }
      } else {
        _showOperationCancelledMessage(_l10n.importCanceled);
      }
    } catch (e, stackTrace) {
      await _handleImportFailure(
        fileName: 'JSON',
        errorMessage: _l10n.errorLoadingAutomatonJson('$e'),
        retryOperation: _loadAutomatonFromJson,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportAutomatonAsSVG() async {
    if (widget.automaton == null) return;
    _updatePanelState(() => _isLoading = true);
    try {
      Result<String>? exportResult;
      if (kIsWeb) {
        exportResult = await _fileService.exportFsaToSVG(
          widget.automaton!,
          '${widget.automaton!.name}.svg',
          emptyAutomatonLabel: _svgEmptyAutomatonLabel,
          tmLegendLabel: _svgTmLegendLabel,
          includeAnnotations: _includeAnnotationsInVisualExports,
          annotations: widget.annotations,
        );
      } else {
        exportResult = await _saveTextFileWithPicker(
          dialogTitle: _l10n.exportAutomatonAsSvg,
          fileName: '${widget.automaton!.name}.svg',
          allowedExtensions: ['svg'],
          contents: _fileService.exportFsaToSvgString(
            widget.automaton!,
            emptyAutomatonLabel: _svgEmptyAutomatonLabel,
            tmLegendLabel: _svgTmLegendLabel,
            includeAnnotations: _includeAnnotationsInVisualExports,
            annotations: widget.annotations,
          ),
          writeToPath: (path) => _fileService.exportFsaToSVG(
            widget.automaton!,
            path,
            emptyAutomatonLabel: _svgEmptyAutomatonLabel,
            tmLegendLabel: _svgTmLegendLabel,
            includeAnnotations: _includeAnnotationsInVisualExports,
            annotations: widget.annotations,
          ),
          cancelMessage: _l10n.exportCanceled,
        );

        if (exportResult == null) {
          return;
        }
      }

      if (exportResult.isSuccess) {
        final successMessage = kIsWeb
            ? _l10n.downloadStartedFor(exportResult.data ?? 'automaton.svg')
            : _l10n.automatonExportedSuccessfully;
        _showSuccessMessage(successMessage);
      } else {
        _showErrorMessage(
          _l10n.failedToExportAutomaton(
            _l10n.localizeWorkflowText('${exportResult.error}'),
          ),
          retryOperation: _exportAutomatonAsSVG,
        );
      }
    } catch (e, stackTrace) {
      _showErrorMessage(
        _l10n.errorExportingAutomaton(_l10n.localizeWorkflowText('$e')),
        retryOperation: _exportAutomatonAsSVG,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportAutomatonAsPNG() async {
    if (widget.automaton == null) return;
    _updatePanelState(() => _isLoading = true);

    try {
      Result<String>? exportResult;
      final pngBytesResult = await _fileService.exportAutomatonToPngBytes(
        widget.automaton!,
        includeAnnotations: _includeAnnotationsInVisualExports,
        annotations: widget.annotations,
      );
      if (pngBytesResult.isFailure) {
        _showErrorMessage(
          _l10n.failedToExportAutomatonPng('${pngBytesResult.error}'),
          retryOperation: _exportAutomatonAsPNG,
        );
        return;
      }

      exportResult = await _saveBinaryFileWithPicker(
        dialogTitle: _l10n.exportAutomatonAsPng,
        fileName: '${widget.automaton!.name}.png',
        allowedExtensions: ['png'],
        bytes: pngBytesResult.data!,
        writeToPath: (path) =>
            _fileService.writePngBytesToPath(pngBytesResult.data!, path),
      );

      if (exportResult == null) {
        return;
      }

      if (exportResult.isSuccess) {
        _showSuccessMessage(_l10n.automatonExportedSuccessfully);
      } else {
        _showErrorMessage(
          _l10n.failedToExportAutomatonPng('${exportResult.error}'),
          retryOperation: _exportAutomatonAsPNG,
        );
      }
    } catch (e, stackTrace) {
      _showErrorMessage(
        _l10n.errorExportingAutomatonPng('$e'),
        retryOperation: _exportAutomatonAsPNG,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        _updatePanelState(() => _isLoading = false);
      }
    }
  }
}
