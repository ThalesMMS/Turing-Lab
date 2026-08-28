import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/annotations/annotations.dart';
import '../../core/formal_systems/formal_system_ids.dart';
import '../../core/interoperability/codec_outcome.dart';

final documentAnnotationsProvider = StateNotifierProvider<
    DocumentAnnotationsNotifier,
    Map<FormalSystemKey, DocumentAnnotationCollection>>((ref) {
  return DocumentAnnotationsNotifier();
});

DocumentAnnotationCollection? annotationsForDocument(
  Map<FormalSystemKey, DocumentAnnotationCollection> collections,
  FormalSystemKey key,
  String documentId,
) {
  final collection = collections[key];
  return collection?.documentId == documentId ? collection : null;
}

DocumentAnnotationCollection? annotationsFromImportedDocument(
  InteroperableDocument<Object> document, {
  required String documentId,
  required String documentRevision,
}) {
  final collection = annotationsFromExtensions(document.extensions);
  if (collection == null) return null;
  if (collection.documentId != documentId) {
    throw const FormatException(
      'Imported annotations belong to a different document.',
    );
  }
  return collection.rebindRevision(documentRevision);
}

class DocumentAnnotationsNotifier
    extends StateNotifier<Map<FormalSystemKey, DocumentAnnotationCollection>> {
  DocumentAnnotationsNotifier() : super(const {});

  final Map<FormalSystemKey, List<DocumentAnnotationCollection>> _undo = {};
  final Map<FormalSystemKey, List<DocumentAnnotationCollection>> _redo = {};
  int _nextId = 0;

  DocumentAnnotationCollection collectionFor(
    FormalSystemKey key, {
    required String documentId,
    required String documentRevision,
  }) {
    final existing = state[key];
    if (existing != null && existing.documentId == documentId) {
      if (existing.documentRevision == documentRevision) return existing;
      final rebound = existing.rebindRevision(documentRevision);
      state = Map.unmodifiable({...state, key: rebound});
      return rebound;
    }
    final created = DocumentAnnotationCollection(
      documentId: documentId,
      documentRevision: documentRevision,
    );
    state = Map.unmodifiable({...state, key: created});
    _undo.remove(key);
    _redo.remove(key);
    return created;
  }

  void restore(
    FormalSystemKey key,
    DocumentAnnotationCollection? collection,
  ) {
    if (collection == null) {
      if (!state.containsKey(key)) return;
      final updated = Map<FormalSystemKey, DocumentAnnotationCollection>.of(
        state,
      )..remove(key);
      state = Map.unmodifiable(updated);
    } else {
      state = Map.unmodifiable({...state, key: collection});
    }
    _undo.remove(key);
    _redo.remove(key);
  }

  /// Replaces a collection while retaining one undo/redo checkpoint.
  ///
  /// Returns whether a new history entry was created so a canvas mutation can
  /// attach the matching sidecar history companion only when needed.
  bool replaceAsMutation(
    FormalSystemKey key,
    DocumentAnnotationCollection collection,
  ) {
    final current = state[key];
    if (current == collection) return false;
    _commit(key, collection);
    return true;
  }

  DocumentAnnotation add({
    required FormalSystemKey key,
    required String documentId,
    required String documentRevision,
    required double x,
    required double y,
    String text = '',
    AnnotationAttachment? attachment,
    AnnotationStyleRole styleRole = AnnotationStyleRole.note,
    double width = DocumentAnnotation.defaultWidth,
    double height = DocumentAnnotation.defaultHeight,
    bool collapsed = false,
    DateTime? timestamp,
  }) {
    final current = collectionFor(
      key,
      documentId: documentId,
      documentRevision: documentRevision,
    );
    final now = timestamp ?? DateTime.now().toUtc();
    final annotation = DocumentAnnotation(
      id: _newId(now),
      documentId: documentId,
      documentRevision: documentRevision,
      text: text,
      x: x,
      y: y,
      attachment: attachment,
      styleRole: styleRole,
      width: width,
      height: height,
      collapsed: collapsed,
      zIndex: current.annotations.length,
      createdAt: now,
      updatedAt: now,
    );
    _commit(key, current.upsert(annotation));
    return annotation;
  }

  void update(FormalSystemKey key, DocumentAnnotation annotation) {
    final current = state[key];
    if (current == null || current.byId(annotation.id) == null) return;
    _commit(key, current.upsert(annotation));
  }

  void remove(FormalSystemKey key, String id) {
    final current = state[key];
    if (current == null || current.byId(id) == null) return;
    _commit(key, current.remove(id));
  }

  DocumentAnnotation? duplicate(
    FormalSystemKey key,
    String id, {
    DateTime? timestamp,
  }) {
    final current = state[key];
    if (current == null || current.byId(id) == null) return null;
    final now = timestamp ?? DateTime.now().toUtc();
    final next = current.duplicate(
      id,
      newId: _newId(now),
      timestamp: now,
    );
    _commit(key, next);
    return next.annotations.last;
  }

  void resolveTargetDeletion({
    required FormalSystemKey key,
    required AnnotationTargetType type,
    required String targetId,
    required AnnotationTargetDeletionPolicy policy,
    ({double x, double y})? resolvedPosition,
    DateTime? timestamp,
  }) {
    resolveTargetDeletions(
      key: key,
      targets: [
        (
          type: type,
          targetId: targetId,
          resolvedPosition: resolvedPosition,
        ),
      ],
      policy: policy,
      timestamp: timestamp,
    );
  }

  void resolveTargetDeletions({
    required FormalSystemKey key,
    required Iterable<
            ({
              AnnotationTargetType type,
              String targetId,
              ({double x, double y})? resolvedPosition,
            })>
        targets,
    required AnnotationTargetDeletionPolicy policy,
    DateTime? timestamp,
  }) {
    final current = state[key];
    if (current == null) return;
    final now = timestamp ?? DateTime.now().toUtc();
    var next = current;
    for (final target in targets) {
      next = next.resolveTargetDeletion(
        type: target.type,
        targetId: target.targetId,
        policy: policy,
        resolvedPosition: target.resolvedPosition,
        timestamp: now,
      );
    }
    if (next != current) _commit(key, next);
  }

  bool canUndo(FormalSystemKey key) => _undo[key]?.isNotEmpty ?? false;
  bool canRedo(FormalSystemKey key) => _redo[key]?.isNotEmpty ?? false;

  void undo(FormalSystemKey key) {
    final history = _undo[key];
    final current = state[key];
    if (history == null || history.isEmpty || current == null) return;
    final previous = history.removeLast();
    (_redo[key] ??= []).add(current);
    state = Map.unmodifiable({...state, key: previous});
  }

  void redo(FormalSystemKey key) {
    final future = _redo[key];
    final current = state[key];
    if (future == null || future.isEmpty || current == null) return;
    final next = future.removeLast();
    (_undo[key] ??= []).add(current);
    state = Map.unmodifiable({...state, key: next});
  }

  void _commit(FormalSystemKey key, DocumentAnnotationCollection next) {
    final current = state[key];
    if (current == next) return;
    if (current != null) {
      final history = _undo[key] ??= [];
      history.add(current);
      if (history.length > 100) history.removeAt(0);
    }
    _redo.remove(key);
    state = Map.unmodifiable({...state, key: next});
  }

  String _newId(DateTime timestamp) =>
      'annotation-${timestamp.microsecondsSinceEpoch}-${_nextId++}';
}
