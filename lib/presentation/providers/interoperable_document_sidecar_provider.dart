import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/annotations/annotations.dart';
import '../../core/interoperability/interoperability.dart';

final class InteroperableDocumentSidecarEntry {
  const InteroperableDocumentSidecarEntry({
    required this.document,
    required this.documentIdentity,
  });

  final InteroperableDocument<Object> document;
  final Object documentIdentity;
}

class InteroperableDocumentSidecarNotifier extends StateNotifier<
    Map<FormalSystemKey, InteroperableDocumentSidecarEntry>> {
  InteroperableDocumentSidecarNotifier() : super(const {});

  void store(
    InteroperableDocument<Object> document, {
    required Object documentIdentity,
  }) {
    state = Map.unmodifiable({
      ...state,
      document.systemKey: InteroperableDocumentSidecarEntry(
        document: document,
        documentIdentity: documentIdentity,
      ),
    });
  }

  void remove(FormalSystemKey key) {
    if (!state.containsKey(key)) return;
    final updated = Map<FormalSystemKey, InteroperableDocumentSidecarEntry>.of(
      state,
    )..remove(key);
    state = Map.unmodifiable(updated);
  }

  void restore(
    FormalSystemKey key,
    InteroperableDocumentSidecarEntry? entry,
  ) {
    if (entry == null) {
      remove(key);
      return;
    }
    state = Map.unmodifiable({...state, key: entry});
  }
}

final interoperableDocumentSidecarProvider = StateNotifierProvider<
    InteroperableDocumentSidecarNotifier,
    Map<FormalSystemKey, InteroperableDocumentSidecarEntry>>((ref) {
  return InteroperableDocumentSidecarNotifier();
});

InteroperableDocument<Object> resolveInteroperableDocument({
  required InteroperableDocumentSidecarEntry? sidecar,
  required Object currentDocument,
  required Object documentIdentity,
  required FormalSystemKey systemKey,
  required DocumentSchemaDescriptor schema,
  DocumentAnnotationCollection? annotations,
}) {
  if (sidecar != null && sidecar.documentIdentity == documentIdentity) {
    return InteroperableDocument<Object>(
      document: currentDocument,
      systemKey: systemKey,
      schema: sidecar.document.schema,
      sourceMetadata: sidecar.document.sourceMetadata,
      extensions: extensionsWithAnnotations(
        sidecar.document.extensions,
        annotations,
      ),
    );
  }
  return InteroperableDocument<Object>(
    document: currentDocument,
    systemKey: systemKey,
    schema: schema,
    extensions: extensionsWithAnnotations(DocumentExtensionBag(), annotations),
  );
}
