import 'package:flutter/material.dart';

import '../../core/interoperability/interoperability.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/automaton_fragment_localizations.dart';
import 'document_interoperability_preview.dart';

Future<bool?> showDocumentInteroperabilityReviewDialog(
  BuildContext context, {
  required DocumentInteroperabilityPreview preview,
}) async {
  final previousFocus = FocusManager.instance.primaryFocus;
  try {
    return await showDialog<bool>(
      context: context,
      builder: (_) => DocumentInteroperabilityReviewDialog(preview: preview),
    );
  } finally {
    previousFocus?.requestFocus();
  }
}

/// Reviews codec detection and fidelity before a transaction is committed.
class DocumentInteroperabilityReviewDialog extends StatelessWidget {
  const DocumentInteroperabilityReviewDialog({
    super.key,
    required this.preview,
  });

  final DocumentInteroperabilityPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final isImport =
        preview.operation == DocumentInteroperabilityOperation.importDocument;
    final title = isImport
        ? l10n.interoperabilityImportReviewTitle
        : l10n.interoperabilityExportReviewTitle;
    final confirmLabel = preview.isLossy
        ? (isImport
              ? l10n.interoperabilityImportWithLoss
              : l10n.interoperabilityExportWithLoss)
        : (isImport
              ? l10n.interoperabilityReplaceDocument
              : l10n.interoperabilityExportDocument);

    return Semantics(
      namesRoute: true,
      child: AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        icon: const ExcludeSemantics(child: Icon(Icons.fact_check_outlined)),
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.interoperabilityReviewPrompt),
              const SizedBox(height: 16),
              _PreviewFacts(preview: preview),
              if (preview.isLossy) ...[
                const SizedBox(height: 16),
                _LossWarning(
                  message: isImport
                      ? l10n.interoperabilityLossyImportWarning
                      : l10n.interoperabilityLossyExportWarning,
                ),
              ],
              if (preview.diagnostics.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.interoperabilityChangesTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final diagnostic in preview.diagnostics)
                  _DiagnosticTile(diagnostic: diagnostic),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _PreviewFacts extends StatelessWidget {
  const _PreviewFacts({required this.preview});

  final DocumentInteroperabilityPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final fidelity = switch (preview.fidelity) {
      DocumentFidelity.exact => l10n.interoperabilityFidelityExact,
      DocumentFidelity.normalized => l10n.interoperabilityFidelityNormalized,
      DocumentFidelity.lossy => l10n.interoperabilityFidelityLossy,
    };
    final facts = <(String, String)>[
      (l10n.interoperabilityFileLabel, preview.fileName),
      (l10n.interoperabilityTypeLabel, preview.systemLabel),
      (l10n.interoperabilityFormatLabel, preview.formatLabel),
      (l10n.interoperabilityVersionLabel, '${preview.schemaVersion}'),
      (l10n.interoperabilityFidelityLabel, fidelity),
      for (final fact in preview.facts) (fact.label, fact.value),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (label, value) in facts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: SelectableText(value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LossWarning extends StatelessWidget {
  const _LossWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                color: colors.onErrorContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({required this.diagnostic});

  final CodecDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final location = diagnostic.location;
    final disposition = switch (diagnostic.disposition) {
      CodecDiagnosticDisposition.preserved =>
        l10n.interoperabilityDiagnosticPreserved,
      CodecDiagnosticDisposition.normalized =>
        l10n.interoperabilityDiagnosticNormalized,
      CodecDiagnosticDisposition.dropped =>
        l10n.interoperabilityDiagnosticDropped,
    };
    final paths = <String>{
      if (diagnostic.path case final path?) path,
      if (location?.path case final path?) path,
    };
    final details = <String>[
      for (final path in paths) l10n.interoperabilityDiagnosticPath(path),
      if (location?.line case final line?)
        if (location?.column case final column?)
          l10n.interoperabilityDiagnosticLineColumn(line, column)
        else
          l10n.interoperabilityDiagnosticLine(line),
      if (diagnostic.sourceValue != null)
        l10n.interoperabilityDiagnosticSourceValueRecorded,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(disposition, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                l10n.localizedAutomatonFragmentCodecDiagnostic(diagnostic),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  details.join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                l10n.interoperabilityDiagnosticTechnicalCode(diagnostic.code),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
