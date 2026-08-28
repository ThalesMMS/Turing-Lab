part of '../file_operations_panel.dart';

final class _InteroperabilityPickerCanceled implements Exception {
  const _InteroperabilityPickerCanceled();
}

extension _FileOperationsPanelInteroperability on _FileOperationsPanelState {
  Widget _buildInteroperabilitySection(
    DocumentInteroperabilityBinding binding,
  ) {
    final descriptors = binding.registry.descriptors
        .where((descriptor) => descriptor.systemKey == binding.systemKey)
        .toList(growable: false);
    final canImport = descriptors.any(
      (descriptor) => descriptor.directions.contains(
        DocumentFormatDirection.importDocument,
      ),
    );
    final exportFormats = binding.currentDocument == null
        ? <DocumentFormatId>[]
        : (<DocumentFormatId>{
            for (final descriptor in descriptors)
              if (descriptor.directions.contains(
                DocumentFormatDirection.exportDocument,
              ))
                descriptor.formatId,
          }.toList()..sort((left, right) => left.value.compareTo(right.value)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(binding.systemLabel(context, binding.systemKey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (canImport)
              _buildButton(
                _l10n.interoperabilityImportDocument,
                Icons.upload_file,
                () => _importInteroperableDocument(binding),
                key: const ValueKey<String>('interoperability_import_document'),
              ),
            for (final format in exportFormats)
              _buildButton(
                _l10n.interoperabilityExportAs(
                  binding.formatLabel(context, format),
                ),
                Icons.download,
                () => _exportInteroperableDocument(binding, format),
                key: ValueKey<String>(
                  'interoperability_export_${format.value}',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _importInteroperableDocument(
    DocumentInteroperabilityBinding binding,
  ) async {
    _updatePanelState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: _l10n.interoperabilityImportDocument,
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _showOperationCancelledMessage(_l10n.importCanceled);
        return;
      }
      final file = result.files.single;
      Uint8List? bytes = file.bytes;
      final path = _normalizedJsonPath(file.path);
      if (bytes == null && path != null) {
        final readResult = await _fileService.readBytes(path);
        if (readResult.isSuccess) {
          bytes = readResult.data;
        } else {
          await _showInteroperabilityFailure(
            CodecInternalFailure<InteroperableDocument<Object>>(
              stage: CodecInternalFailureStage.decode,
              message: readResult.error ?? _l10n.fileReadFailed,
            ),
            file.name,
          );
          return;
        }
      }
      if (bytes == null) {
        await _showInteroperabilityFailure(
          CodecUnsupported<InteroperableDocument<Object>>(
            reason: CodecUnsupportedReason.document,
            message: _l10n.selectedFileBytesUnavailable,
          ),
          file.name,
        );
        return;
      }
      final payload = DocumentPayload(
        bytes: bytes,
        filename: file.name,
        mimeType: null,
        sourcePath: file.path,
      );
      final detected = binding.registry.detect(
        payload,
        expectedSystem: binding.systemKey,
      );
      late final CodecOutcome<InteroperableDocument<Object>> outcome;
      late final DocumentFormatId detectedFormat;
      if (detected is CodecSuccess<DetectedDocument>) {
        detectedFormat = detected.value.descriptor.formatId;
        outcome = binding.registry.decode(
          payload,
          expectedSystem: binding.systemKey,
          expectedFormat: detectedFormat,
        );
      } else if (detected is CodecUnsupported<DetectedDocument> &&
          detected.reason == CodecUnsupportedReason.document) {
        final hinted = _decodeUsingExtensionHint(binding, payload);
        if (hinted == null) {
          await _showInteroperabilityFailure(detected, file.name);
          return;
        }
        detectedFormat = hinted.$1;
        outcome = hinted.$2;
      } else {
        await _showInteroperabilityFailure(detected, file.name);
        return;
      }
      if (outcome is! CodecSuccess<InteroperableDocument<Object>>) {
        await _showInteroperabilityFailure(outcome, file.name);
        return;
      }
      final transaction = DocumentImportTransaction<Object, Object?>.prepare(
        outcome: outcome,
        target: CallbackDocumentImportTarget<Object, Object?>(
          captureCheckpoint: binding.captureCheckpoint,
          replace: binding.replace,
          restoreCheckpoint: binding.restoreCheckpoint,
        ),
      );
      if (!mounted) return;
      _updatePanelState(() => _isLoading = false);
      final confirmed = await showDocumentInteroperabilityReviewDialog(
        context,
        preview: DocumentInteroperabilityPreview(
          operation: DocumentInteroperabilityOperation.importDocument,
          fileName: file.name,
          systemLabel: binding.systemLabel(context, outcome.value.systemKey),
          formatLabel: binding.formatLabel(context, detectedFormat),
          schemaVersion: outcome.value.schema.version.value,
          fidelity: outcome.fidelity,
          diagnostics: outcome.diagnostics,
          facts: binding.previewFacts?.call(context, outcome.value) ?? const [],
        ),
      );
      if (confirmed != true) {
        _showOperationCancelledMessage(_l10n.importCanceled);
        return;
      }
      _updatePanelState(() => _isLoading = true);
      await transaction.commit(
        allowLossy: outcome.fidelity == DocumentFidelity.lossy,
      );
      _showSuccessMessage(_l10n.interoperabilityImportSucceeded);
    } catch (error, stackTrace) {
      _showErrorMessage(
        _l10n.interoperabilityOperationFailed,
        retryOperation: () => _importInteroperableDocument(binding),
        stackTrace: stackTrace,
      );
    } finally {
      _updatePanelState(() => _isLoading = false);
    }
  }

  Future<void> _exportInteroperableDocument(
    DocumentInteroperabilityBinding binding,
    DocumentFormatId format,
  ) async {
    final currentDocument = binding.currentDocument;
    if (currentDocument == null) return;
    _updatePanelState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      final outcome = binding.registry.encode(currentDocument, format: format);
      if (outcome is! CodecSuccess<EncodedDocument>) {
        await _showInteroperabilityFailure(
          outcome,
          _l10n.interoperabilityActiveDocument,
        );
        return;
      }
      if (!mounted) return;
      _updatePanelState(() => _isLoading = false);
      final confirmed = await showDocumentInteroperabilityReviewDialog(
        context,
        preview: DocumentInteroperabilityPreview(
          operation: DocumentInteroperabilityOperation.exportDocument,
          fileName: outcome.value.filename,
          systemLabel: binding.systemLabel(context, binding.systemKey),
          formatLabel: binding.formatLabel(context, format),
          schemaVersion: outcome.value.schema.version.value,
          fidelity: outcome.fidelity,
          diagnostics: outcome.diagnostics,
          facts:
              binding.previewFacts?.call(context, currentDocument) ?? const [],
        ),
      );
      if (confirmed != true) {
        _showOperationCancelledMessage(_l10n.exportCanceled);
        return;
      }
      _updatePanelState(() => _isLoading = true);
      final transaction = DocumentExportTransaction.prepare(
        outcome: outcome,
        location: 'picker://${outcome.value.filename}',
        transport: CallbackDocumentTransport(
          read: (_) => throw UnsupportedError('Export transport is write-only'),
          write: (_, bytes, mimeType) =>
              _writeInteroperableExport(outcome.value, bytes, mimeType, format),
        ),
      );
      await transaction.commit(
        allowLossy: outcome.fidelity == DocumentFidelity.lossy,
      );
      _showSuccessMessage(_l10n.interoperabilityExportSucceeded);
    } on _InteroperabilityPickerCanceled {
      _showOperationCancelledMessage(_l10n.exportCanceled);
    } catch (error, stackTrace) {
      _showErrorMessage(
        _l10n.interoperabilityOperationFailed,
        retryOperation: () => _exportInteroperableDocument(binding, format),
        stackTrace: stackTrace,
      );
    } finally {
      _updatePanelState(() => _isLoading = false);
    }
  }

  (DocumentFormatId, CodecOutcome<InteroperableDocument<Object>>)?
  _decodeUsingExtensionHint(
    DocumentInteroperabilityBinding binding,
    DocumentPayload payload,
  ) {
    final extension = payload.normalizedExtension;
    if (extension == null) return null;
    final format = binding.registry.formalSystems.formats
        .forExtension(extension)
        ?.id;
    if (format == null) return null;
    final codecs = binding.registry.formalSystems
        .moduleFor(binding.systemKey)
        ?.codecs
        .where(
          (codec) =>
              codec.descriptor.formatId == format &&
              codec.descriptor.directions.contains(
                DocumentFormatDirection.importDocument,
              ),
        )
        .toList(growable: false);
    if (codecs == null || codecs.length != 1) return null;
    return (
      format,
      binding.registry.decode(
        payload,
        expectedSystem: binding.systemKey,
        expectedFormat: format,
      ),
    );
  }

  Future<void> _writeInteroperableExport(
    EncodedDocument document,
    Uint8List bytes,
    String mimeType,
    DocumentFormatId format,
  ) async {
    final consumesBytes = kIsWeb || _saveFileConsumesBytesInPicker;
    final extension = _bindingExtension(format, document.filename);
    final selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: _l10n.interoperabilityExportDocument,
      fileName: document.filename,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: consumesBytes ? bytes : null,
    );
    if (selectedPath == null) throw const _InteroperabilityPickerCanceled();
    if (consumesBytes) return;
    final result = await _fileService.writeBytes(
      bytes,
      selectedPath,
      mimeType: mimeType,
    );
    if (result.isFailure) {
      throw StateError(result.error ?? _l10n.interoperabilityOperationFailed);
    }
  }

  String _bindingExtension(DocumentFormatId format, String filename) {
    final extension = filename.split('.').last;
    if (extension != filename && extension.isNotEmpty) return extension;
    return format.value;
  }

  Future<void> _showInteroperabilityFailure<T>(
    CodecOutcome<T> outcome,
    String fileName,
  ) async {
    if (!mounted) return;
    _updatePanelState(() => _isLoading = false);
    await showDocumentInteroperabilityFailureDialog<T>(
      context,
      outcome: outcome,
      fileName: fileName,
      onOpenRoadmapIssue: (issue) {
        unawaited(
          launchUrl(
            Uri.parse(
              'https://github.com/ThalesMMS/Turing-Lab-dev/issues/$issue',
            ),
            mode: LaunchMode.externalApplication,
          ),
        );
      },
    );
  }
}
