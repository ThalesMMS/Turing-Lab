import 'document_annotation.dart';

enum AnnotationTargetDeletionPolicy { delete, detach, keepUnresolved }

final class DocumentAnnotationCollection {
  static const int schemaVersion = 1;
  static const int maximumAnnotations = 10000;

  DocumentAnnotationCollection({
    required this.documentId,
    required this.documentRevision,
    Iterable<DocumentAnnotation> annotations = const [],
  }) : annotations = List<DocumentAnnotation>.unmodifiable(
          annotations.toList()
            ..sort((left, right) {
              final byLayer = left.zIndex.compareTo(right.zIndex);
              return byLayer != 0 ? byLayer : left.id.compareTo(right.id);
            }),
        ) {
    final issues = validate();
    if (issues.isNotEmpty) throw ArgumentError(issues.join('\n'));
  }

  final String documentId;
  final String documentRevision;
  final List<DocumentAnnotation> annotations;

  List<String> validate() {
    final issues = <String>[
      if (documentId.trim().isEmpty) 'Document id must not be empty.',
      if (documentRevision.trim().isEmpty)
        'Document revision must not be empty.',
      if (annotations.length > maximumAnnotations)
        'Annotation count exceeds $maximumAnnotations.',
    ];
    final ids = <String>{};
    for (final annotation in annotations) {
      if (!ids.add(annotation.id)) {
        issues.add('Duplicate annotation id ${annotation.id}.');
      }
      if (annotation.documentId != documentId) {
        issues.add('Annotation ${annotation.id} belongs to another document.');
      }
      if (annotation.documentRevision != documentRevision) {
        issues.add('Annotation ${annotation.id} belongs to another revision.');
      }
      issues.addAll(annotation.validate());
    }
    return issues;
  }

  DocumentAnnotation? byId(String id) {
    for (final annotation in annotations) {
      if (annotation.id == id) return annotation;
    }
    return null;
  }

  List<DocumentAnnotation> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return annotations;
    return List<DocumentAnnotation>.unmodifiable(
      annotations.where(
        (annotation) =>
            annotation.text.toLowerCase().contains(normalized) ||
            annotation.styleRole.name.contains(normalized) ||
            (annotation.attachment?.targetId
                    .toLowerCase()
                    .contains(normalized) ??
                false),
      ),
    );
  }

  DocumentAnnotationCollection upsert(DocumentAnnotation annotation) {
    final existing = byId(annotation.id);
    if (existing == null && annotations.length >= maximumAnnotations) {
      throw StateError('Annotation limit $maximumAnnotations reached.');
    }
    return _replace([
      for (final item in annotations)
        if (item.id != annotation.id) item,
      annotation.copyWith(documentRevision: documentRevision),
    ]);
  }

  DocumentAnnotationCollection remove(String id) =>
      _replace(annotations.where((annotation) => annotation.id != id));

  DocumentAnnotationCollection duplicate(
    String id, {
    required String newId,
    required DateTime timestamp,
    double offset = 24,
  }) {
    final source = byId(id);
    if (source == null) throw StateError('Unknown annotation $id.');
    final nextLayer = annotations.isEmpty
        ? 0
        : annotations
                .map((annotation) => annotation.zIndex)
                .reduce((left, right) => left > right ? left : right) +
            1;
    return upsert(
      source.copyWith(
        id: newId,
        x: source.x + offset,
        y: source.y + offset,
        attachment: source.attachment?.copyWith(
          offsetX: source.attachment!.offsetX + offset,
          offsetY: source.attachment!.offsetY + offset,
        ),
        zIndex: nextLayer,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  DocumentAnnotationCollection resolveTargetDeletion({
    required AnnotationTargetType type,
    required String targetId,
    required AnnotationTargetDeletionPolicy policy,
    ({double x, double y})? resolvedPosition,
    required DateTime timestamp,
  }) {
    final affected = annotations.where(
      (annotation) =>
          annotation.attachment?.type == type &&
          annotation.attachment?.targetId == targetId,
    );
    if (affected.isEmpty) return this;
    final result = <DocumentAnnotation>[];
    for (final annotation in annotations) {
      final matches = annotation.attachment?.type == type &&
          annotation.attachment?.targetId == targetId;
      if (!matches) {
        result.add(annotation);
      } else if (policy == AnnotationTargetDeletionPolicy.detach) {
        final attachment = annotation.attachment!;
        result.add(
          annotation.copyWith(
            x: resolvedPosition == null
                ? annotation.x
                : resolvedPosition.x + attachment.offsetX,
            y: resolvedPosition == null
                ? annotation.y
                : resolvedPosition.y + attachment.offsetY,
            attachment: null,
            updatedAt: timestamp,
          ),
        );
      } else if (policy == AnnotationTargetDeletionPolicy.keepUnresolved) {
        result.add(annotation.copyWith(updatedAt: timestamp));
      }
    }
    return _replace(result);
  }

  DocumentAnnotationCollection rebindRevision(String revision) =>
      DocumentAnnotationCollection(
        documentId: documentId,
        documentRevision: revision,
        annotations: [
          for (final annotation in annotations)
            annotation.copyWith(documentRevision: revision),
        ],
      );

  Map<String, Object?> toJson() => {
        'version': schemaVersion,
        'documentId': documentId,
        'documentRevision': documentRevision,
        'annotations':
            annotations.map((annotation) => annotation.toJson()).toList(),
      };

  factory DocumentAnnotationCollection.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != schemaVersion) {
      throw FormatException(
          'Unsupported annotation collection version $version.');
    }
    final rawAnnotations = json['annotations'];
    if (rawAnnotations is! List) {
      throw const FormatException('Annotations must be a list.');
    }
    if (rawAnnotations.length > maximumAnnotations) {
      throw const FormatException('Annotation collection exceeds its limit.');
    }
    return DocumentAnnotationCollection(
      documentId: json['documentId'] as String,
      documentRevision: json['documentRevision'] as String,
      annotations: rawAnnotations.map((value) {
        if (value is! Map) {
          throw const FormatException('Annotation entry must be an object.');
        }
        return DocumentAnnotation.fromJson(value.cast<String, dynamic>());
      }),
    );
  }

  DocumentAnnotationCollection _replace(Iterable<DocumentAnnotation> values) =>
      DocumentAnnotationCollection(
        documentId: documentId,
        documentRevision: documentRevision,
        annotations: values,
      );

  @override
  bool operator ==(Object other) {
    if (other is! DocumentAnnotationCollection ||
        other.documentId != documentId ||
        other.documentRevision != documentRevision ||
        other.annotations.length != annotations.length) {
      return false;
    }
    for (var index = 0; index < annotations.length; index++) {
      if (annotations[index] != other.annotations[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        documentId,
        documentRevision,
        Object.hashAll(annotations),
      );
}
