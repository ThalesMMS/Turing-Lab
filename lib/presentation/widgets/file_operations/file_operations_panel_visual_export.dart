part of '../file_operations_panel.dart';

extension _FileOperationsPanelVisualExport on _FileOperationsPanelState {
  Widget _buildVisualExportSection(
    VisualExportBinding binding, {
    required bool showTitle,
  }) {
    final formats = binding.supportedFormats(_registry);
    if (formats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          _buildSectionTitle(_l10n.fileOperationsTitle),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final format in formats)
              _buildButton(
                _l10n.interoperabilityExportAs(
                  defaultDocumentFormatLabel(context, format),
                ),
                Icons.image_outlined,
                () => _exportVisual(binding, format),
                key: ValueKey<String>('visual_export_${format.value}'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportVisual(
    VisualExportBinding binding,
    DocumentFormatId format,
  ) async {
    final producer = binding.producers[format];
    if (producer == null ||
        !binding.supportedFormats(_registry).contains(format)) {
      _showErrorMessage(_l10n.interoperabilityOperationFailed);
      return;
    }
    _updatePanelState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      final artifact = await producer(
        includeAnnotations: _includeAnnotationsInVisualExports,
      );
      final extension = artifact.filename.split('.').last;
      final consumesBytes = kIsWeb || _saveFileConsumesBytesInPicker;
      final selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: _l10n.interoperabilityExportDocument,
        fileName: artifact.filename,
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: consumesBytes ? artifact.bytes : null,
      );
      if (selectedPath == null) {
        _showOperationCancelledMessage(_l10n.exportCanceled);
        return;
      }
      if (!consumesBytes) {
        final result = await _fileService.writeBytes(
          artifact.bytes,
          selectedPath,
          mimeType: artifact.mimeType,
        );
        if (result.isFailure) {
          throw StateError(
            result.error ?? _l10n.interoperabilityOperationFailed,
          );
        }
      }
      _showSuccessMessage(_l10n.interoperabilityExportSucceeded);
    } catch (error, stackTrace) {
      _showErrorMessage(
        _l10n.interoperabilityOperationFailed,
        retryOperation: () => _exportVisual(binding, format),
        stackTrace: stackTrace,
      );
    } finally {
      _updatePanelState(() => _isLoading = false);
    }
  }
}
