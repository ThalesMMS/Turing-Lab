part of '../file_operations_panel.dart';

extension _FileOperationsPanelFeedback on _FileOperationsPanelState {
  Future<void> _handleImportFailure({
    required String fileName,
    required String errorMessage,
    required Future<void> Function() retryOperation,
    StackTrace? stackTrace,
  }) async {
    final trimmedMessage = errorMessage.trim();
    final isCritical = _isCriticalImportError(trimmedMessage);

    if (isCritical) {
      await _showImportErrorDialog(
        fileName: fileName,
        errorMessage: trimmedMessage,
        retryOperation: retryOperation,
        stackTrace: stackTrace,
      );
    } else {
      _showErrorMessage(
        trimmedMessage,
        retryOperation: retryOperation,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _showImportErrorDialog({
    required String fileName,
    required String errorMessage,
    required Future<void> Function() retryOperation,
    StackTrace? stackTrace,
  }) async {
    _pendingRetry = retryOperation;

    final errorType = _resolveImportErrorType(errorMessage);
    final friendlyMessage = _friendlyMessageFor(errorType);
    final technicalDetails = _composeTechnicalDetails(errorMessage, stackTrace);

    if (!mounted) return;

    _updatePanelState(() {
      _isLoading = false;
      _feedback = null;
    });

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ImportErrorDialog(
          fileName: fileName,
          errorType: errorType,
          detailedMessage: friendlyMessage,
          technicalDetails: technicalDetails,
          showTechnicalDetails: technicalDetails != null,
          onRetry: () {
            Navigator.of(dialogContext).pop();
            _retryLastOperation();
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
            _dismissFeedback();
          },
        );
      },
    );
  }

  String? _composeTechnicalDetails(String message, StackTrace? stackTrace) {
    if (message.isEmpty && stackTrace == null) {
      return null;
    }

    if (stackTrace == null) {
      return message;
    }

    final buffer = StringBuffer(message);
    buffer
      ..writeln()
      ..writeln(stackTrace.toString());
    return buffer.toString();
  }

  ImportErrorType _resolveImportErrorType(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('could not access')) {
      return ImportErrorType.inaccessibleFile;
    }
    if (normalized.contains('corrupt') ||
        normalized.contains('unreadable') ||
        normalized.contains('readable data')) {
      return ImportErrorType.corruptedData;
    }
    if (normalized.contains('json')) {
      return ImportErrorType.invalidJSON;
    }
    if (_containsVersionToken(normalized)) {
      return ImportErrorType.unsupportedVersion;
    }
    if (normalized.contains('xml') ||
        normalized.contains('jflap') ||
        normalized.contains('parse')) {
      return ImportErrorType.malformedJFF;
    }
    return ImportErrorType.invalidAutomaton;
  }

  String _friendlyMessageFor(ImportErrorType type) {
    switch (type) {
      case ImportErrorType.malformedJFF:
        return 'The selected JFLAP file could not be parsed. Please verify the file integrity and try again.';
      case ImportErrorType.invalidJSON:
        return 'The import contains JSON sections that are invalid. Fix the JSON structure and retry.';
      case ImportErrorType.unsupportedVersion:
        return 'This file targets a newer JFLAP schema version. Export it again using a compatible version and retry.';
      case ImportErrorType.inaccessibleFile:
        return 'Turing Lab could not access the selected file. Pick it again from the system dialog and keep it available until the import finishes.';
      case ImportErrorType.corruptedData:
        return 'The file appears to be corrupted or unreadable. Restore a valid backup before importing again.';
      case ImportErrorType.invalidAutomaton:
        return 'The automaton definition is inconsistent. Review the transitions and states before retrying the import.';
    }
  }

  bool _isCriticalImportError(String message) {
    final normalized = message.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.contains('xml') ||
        normalized.contains('json') ||
        normalized.contains('parse') ||
        normalized.contains('malformed') ||
        _containsVersionToken(normalized) ||
        normalized.contains('could not access') ||
        normalized.contains('invalid') ||
        normalized.contains('corrupt') ||
        normalized.contains('unreadable') ||
        normalized.contains('readable data');
  }

  bool _containsVersionToken(String message) {
    return RegExp(r'\bversion\b', caseSensitive: false).hasMatch(message);
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;

    _updatePanelState(() {
      _feedback = _PanelFeedback(
        message: message,
        severity: ErrorSeverity.info,
      );
    });
    _pendingRetry = null;
  }

  void _showSuccessMessage(String message) {
    _showInfoMessage(message);
  }

  void _showOperationCancelledMessage(String message) {
    _showInfoMessage(message);
  }

  void _showErrorMessage(
    String message, {
    Future<void> Function()? retryOperation,
    StackTrace? stackTrace,
  }) {
    if (stackTrace != null) {
      debugPrintStack(label: message, stackTrace: stackTrace);
    }

    if (!mounted) return;

    _updatePanelState(() {
      _feedback = _PanelFeedback(
        message: message,
        severity: ErrorSeverity.error,
        canRetry: retryOperation != null,
      );
    });
    _pendingRetry = retryOperation;
  }

  void _retryLastOperation() {
    final retryOperation = _pendingRetry;
    if (retryOperation == null || _isLoading) {
      return;
    }

    _updatePanelState(() {
      _feedback = null;
    });

    retryOperation();
  }

  void _dismissFeedback() {
    if (!mounted) return;

    _updatePanelState(() {
      _feedback = null;
    });
    _pendingRetry = null;
  }
}
