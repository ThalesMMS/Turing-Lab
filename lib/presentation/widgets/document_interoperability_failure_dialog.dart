import 'package:flutter/material.dart';

import '../../core/interoperability/interoperability.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';

Future<void> showDocumentInteroperabilityFailureDialog<T>(
  BuildContext context, {
  required CodecOutcome<T> outcome,
  required String fileName,
  ValueChanged<int>? onOpenRoadmapIssue,
}) async {
  final previousFocus = FocusManager.instance.primaryFocus;
  try {
    await showDialog<void>(
      context: context,
      builder: (_) => DocumentInteroperabilityFailureDialog<T>(
        outcome: outcome,
        fileName: fileName,
        onOpenRoadmapIssue: onOpenRoadmapIssue,
      ),
    );
  } finally {
    previousFocus?.requestFocus();
  }
}

/// Presents a typed codec failure without exposing parser exceptions as copy.
class DocumentInteroperabilityFailureDialog<T> extends StatelessWidget {
  const DocumentInteroperabilityFailureDialog({
    super.key,
    required this.outcome,
    required this.fileName,
    this.onOpenRoadmapIssue,
  }) : assert(outcome is! CodecSuccess<T>);

  final CodecOutcome<T> outcome;
  final String fileName;
  final ValueChanged<int>? onOpenRoadmapIssue;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final title = _title(context);
    final issue = switch (outcome) {
      CodecUnsupported<T>(:final roadmapIssue) => roadmapIssue,
      _ => null,
    };

    return Semantics(
      namesRoute: true,
      child: AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        icon: const ExcludeSemantics(child: Icon(Icons.error_outline)),
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(fileName, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              Text(_description(context)),
              if (_locationDescription(context) case final location?) ...[
                const SizedBox(height: 12),
                SelectableText(
                  location,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          if (issue != null && onOpenRoadmapIssue != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onOpenRoadmapIssue!(issue);
              },
              icon: const ExcludeSemantics(child: Icon(Icons.open_in_new)),
              label: Text(l10n.interoperabilityRoadmapIssue(issue)),
            ),
        ],
      ),
    );
  }

  String _title(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return switch (outcome) {
      CodecUnsupported<T>() => l10n.interoperabilityUnsupportedTitle,
      CodecAmbiguous<T>() => l10n.interoperabilityAmbiguousTitle,
      CodecMalformed<T>() => l10n.interoperabilityMalformedTitle,
      CodecResourceLimit<T>() => l10n.interoperabilityResourceLimitTitle,
      CodecInternalFailure<T>() => l10n.interoperabilityInternalFailureTitle,
      CodecSuccess<T>() => throw StateError('A success is not a failure'),
    };
  }

  String _description(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final structuredMessage = switch (outcome) {
      CodecUnsupported<T>(:final structuredMessage) => structuredMessage,
      CodecMalformed<T>(:final structuredMessage) => structuredMessage,
      CodecInternalFailure<T>(:final structuredMessage) => structuredMessage,
      _ => null,
    };
    if (structuredMessage != null) {
      return l10n.resolveStructuredMessage(structuredMessage);
    }
    return switch (outcome) {
      CodecUnsupported<T>(:final reason) => switch (reason) {
        CodecUnsupportedReason.document =>
          l10n.interoperabilityUnsupportedDocument,
        CodecUnsupportedReason.feature =>
          l10n.interoperabilityUnsupportedFeature,
        CodecUnsupportedReason.schema => l10n.interoperabilityUnsupportedSchema,
        CodecUnsupportedReason.format => l10n.interoperabilityUnsupportedFormat,
        CodecUnsupportedReason.direction =>
          l10n.interoperabilityUnsupportedDirection,
      },
      CodecAmbiguous<T>(:final codecIds) =>
        l10n.interoperabilityAmbiguousDescription(
          codecIds.map((id) => id.value).join(', '),
        ),
      CodecMalformed<T>(:final reason) => switch (reason) {
        CodecMalformedReason.syntax => l10n.interoperabilityMalformedSyntax,
        CodecMalformedReason.invalidUtf8 => l10n.interoperabilityMalformedUtf8,
        CodecMalformedReason.missingField =>
          l10n.interoperabilityMalformedMissingField,
        CodecMalformedReason.invalidValue =>
          l10n.interoperabilityMalformedInvalidValue,
        CodecMalformedReason.duplicateIdentity =>
          l10n.interoperabilityMalformedDuplicateIdentity,
      },
      CodecResourceLimit<T>(:final limit, :final maximum, :final actual) =>
        l10n.interoperabilityResourceLimitDescription(
          _limitLabel(context, limit),
          actual,
          maximum,
        ),
      CodecInternalFailure<T>() =>
        l10n.interoperabilityInternalFailureDescription,
      CodecSuccess<T>() => throw StateError('A success is not a failure'),
    };
  }

  String? _locationDescription(BuildContext context) {
    final malformed = outcome;
    if (malformed is! CodecMalformed<T>) return null;
    final location = malformed.location;
    if (location == null) return null;
    final l10n = appLocalizationsOf(context);
    final parts = <String>[
      if (location.path case final path?)
        l10n.interoperabilityDiagnosticPath(path),
      if (location.line case final line?)
        if (location.column case final column?)
          l10n.interoperabilityDiagnosticLineColumn(line, column)
        else
          l10n.interoperabilityDiagnosticLine(line),
      if (location.offset case final offset?)
        l10n.interoperabilityDiagnosticOffset(offset),
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String _limitLabel(BuildContext context, CodecResourceLimitKind limit) {
    final l10n = appLocalizationsOf(context);
    return switch (limit) {
      CodecResourceLimitKind.bytes => l10n.interoperabilityLimitBytes,
      CodecResourceLimitKind.xmlDepth => l10n.interoperabilityLimitXmlDepth,
      CodecResourceLimitKind.xmlElements =>
        l10n.interoperabilityLimitXmlElements,
      CodecResourceLimitKind.xmlDtdOrEntity =>
        l10n.interoperabilityLimitXmlDtdOrEntity,
      CodecResourceLimitKind.jsonDepth => l10n.interoperabilityLimitJsonDepth,
      CodecResourceLimitKind.collectionEntries =>
        l10n.interoperabilityLimitCollectionEntries,
    };
  }
}
