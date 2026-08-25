part of '../file_operations_panel.dart';

extension _FileOperationsPanelPickerHelpers on _FileOperationsPanelState {
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Key? key,
  }) {
    return ElevatedButton.icon(
      key: key,
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  bool get _saveFileConsumesBytesInPicker =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<String?> _selectSaveDestination({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    Uint8List? bytes,
  }) {
    return FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      bytes: _saveFileConsumesBytesInPicker ? bytes : null,
    );
  }

  Future<Result<String>?> _saveTextFileWithPicker({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required String contents,
    required Future<StringResult> Function(String path) writeToPath,
    String? cancelMessage,
  }) async {
    final selectedPath = await _selectSaveDestination(
      dialogTitle: dialogTitle,
      fileName: fileName,
      allowedExtensions: allowedExtensions,
      bytes: Uint8List.fromList(utf8.encode(contents)),
    );

    if (selectedPath == null) {
      _showOperationCancelledMessage(cancelMessage ?? _l10n.saveCanceled);
      return null;
    }

    if (_saveFileConsumesBytesInPicker) {
      return Success(selectedPath);
    }

    return writeToPath(selectedPath);
  }

  Future<Result<String>?> _saveBinaryFileWithPicker({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required Uint8List bytes,
    required Future<StringResult> Function(String path) writeToPath,
  }) async {
    final selectedPath = await _selectSaveDestination(
      dialogTitle: dialogTitle,
      fileName: fileName,
      allowedExtensions: allowedExtensions,
      bytes: bytes,
    );

    if (selectedPath == null) {
      _showOperationCancelledMessage(_l10n.exportCanceled);
      return null;
    }

    if (_saveFileConsumesBytesInPicker) {
      return Success(selectedPath);
    }

    return writeToPath(selectedPath);
  }
}
