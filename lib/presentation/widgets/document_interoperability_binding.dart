import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import 'document_interoperability_preview.dart';

typedef InteroperabilityLabelResolver<T> = String Function(
  BuildContext context,
  T value,
);

typedef InteroperabilityFactResolver = Iterable<DocumentInteroperabilityFact>
    Function(
  BuildContext context,
  InteroperableDocument<Object> document,
);

/// Host adapter used by the generic file panel without inspecting model types.
final class DocumentInteroperabilityBinding {
  const DocumentInteroperabilityBinding({
    required this.registry,
    required this.systemKey,
    required this.currentDocument,
    required this.replace,
    required this.captureCheckpoint,
    required this.restoreCheckpoint,
    required this.systemLabel,
    required this.formatLabel,
    this.previewFacts,
  });

  final DocumentInteroperabilityRegistry registry;
  final FormalSystemKey systemKey;
  final InteroperableDocument<Object>? currentDocument;
  final Future<void> Function(InteroperableDocument<Object> document) replace;
  final FutureOr<Object?> Function() captureCheckpoint;
  final FutureOr<void> Function(Object? checkpoint) restoreCheckpoint;
  final InteroperabilityLabelResolver<FormalSystemKey> systemLabel;
  final InteroperabilityLabelResolver<DocumentFormatId> formatLabel;
  final InteroperabilityFactResolver? previewFacts;
}
