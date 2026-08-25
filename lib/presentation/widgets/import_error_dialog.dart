import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import 'retry_button.dart';

/// Types of import errors surfaced by [ImportErrorDialog].
enum ImportErrorType {
  malformedJFF,
  invalidJSON,
  unsupportedVersion,
  inaccessibleFile,
  corruptedData,
  invalidAutomaton,
}

class _ErrorDialogVisuals {
  const _ErrorDialogVisuals({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}

const Map<ImportErrorType, _ErrorDialogVisuals> _dialogVisuals = {
  ImportErrorType.malformedJFF: _ErrorDialogVisuals(
    icon: Icons.topic_outlined,
    color: Color(0xFFC62828),
  ),
  ImportErrorType.invalidJSON: _ErrorDialogVisuals(
    icon: Icons.code_off,
    color: Color(0xFFE65100),
  ),
  ImportErrorType.unsupportedVersion: _ErrorDialogVisuals(
    icon: Icons.update_disabled,
    color: Color(0xFF1565C0),
  ),
  ImportErrorType.inaccessibleFile: _ErrorDialogVisuals(
    icon: Icons.folder_off_outlined,
    color: Color(0xFF00838F),
  ),
  ImportErrorType.corruptedData: _ErrorDialogVisuals(
    icon: Icons.bug_report_outlined,
    color: Color(0xFFD84315),
  ),
  ImportErrorType.invalidAutomaton: _ErrorDialogVisuals(
    icon: Icons.device_hub,
    color: Color(0xFF6A1B9A),
  ),
};

/// Dialog explaining why an import failed and how the user can recover.
class ImportErrorDialog extends StatelessWidget {
  const ImportErrorDialog({
    super.key,
    required this.fileName,
    required this.errorType,
    required this.detailedMessage,
    this.technicalDetails,
    this.showTechnicalDetails = false,
    required this.onRetry,
    required this.onCancel,
  });

  /// Name of the file the user attempted to import.
  final String fileName;

  /// Categorisation of the failure.
  final ImportErrorType errorType;

  /// Friendly explanation of the failure.
  final String detailedMessage;

  /// Optional technical stack trace or parser message.
  final String? technicalDetails;

  /// Whether the details section starts expanded.
  final bool showTechnicalDetails;

  /// Invoked when the user elects to retry the import.
  final VoidCallback onRetry;

  /// Invoked when the user cancels the flow.
  final VoidCallback onCancel;

  bool get _hasTechnicalDetails =>
      technicalDetails != null && technicalDetails!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final visuals = _dialogVisuals[errorType]!;
    final theme = Theme.of(context);
    final l10n = appLocalizationsOf(context);
    final title = switch (errorType) {
      ImportErrorType.malformedJFF => l10n.importErrorMalformedJff,
      ImportErrorType.invalidJSON => l10n.importErrorInvalidJson,
      ImportErrorType.unsupportedVersion => l10n.importErrorUnsupportedVersion,
      ImportErrorType.inaccessibleFile => l10n.importErrorInaccessibleFile,
      ImportErrorType.corruptedData => l10n.importErrorCorruptedData,
      ImportErrorType.invalidAutomaton => l10n.importErrorInvalidAutomaton,
    };

    return Semantics(
      namesRoute: true,
      label: l10n.importErrorDialogSemantics,
      child: AlertDialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: _DialogTitle(visuals: visuals, title: title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FileChip(fileName: fileName, color: visuals.color),
              const SizedBox(height: 16),
              Text(detailedMessage, style: theme.textTheme.bodyMedium),
              if (_hasTechnicalDetails) ...[
                const SizedBox(height: 16),
                _TechnicalDetailsSection(
                  details: technicalDetails!,
                  initiallyExpanded: showTechnicalDetails,
                ),
              ],
            ],
          ),
        ),
        actions: [
          Semantics(
            label: l10n.cancelImport,
            button: true,
            child: TextButton(onPressed: onCancel, child: Text(l10n.cancel)),
          ),
          RetryButton(onPressed: onRetry),
        ],
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.visuals, required this.title});

  final _ErrorDialogVisuals visuals;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(visuals.icon, size: 48, color: visuals.color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: visuals.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.fileName, required this.color});

  final String fileName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 20, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalDetailsSection extends StatefulWidget {
  const _TechnicalDetailsSection({
    required this.details,
    required this.initiallyExpanded,
  });

  final String details;
  final bool initiallyExpanded;

  @override
  State<_TechnicalDetailsSection> createState() =>
      _TechnicalDetailsSectionState();
}

class _TechnicalDetailsSectionState extends State<_TechnicalDetailsSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(
            _expanded ? l10n.hideTechnicalDetails : l10n.viewTechnicalDetails,
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: SingleChildScrollView(
              child: Text(widget.details, style: theme.textTheme.bodySmall),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
