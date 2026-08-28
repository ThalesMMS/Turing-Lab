import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';

void main() {
  final timestamp = DateTime.utc(2026, 8, 25);

  DocumentAnnotation annotation({
    String id = 'note-1',
    String text = 'Remember **this**',
    AnnotationAttachment? attachment,
  }) {
    return DocumentAnnotation(
      id: id,
      documentId: 'doc-1',
      documentRevision: 'revision-1',
      text: text,
      x: 12,
      y: 24,
      attachment: attachment,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  test('annotation JSON round-trip preserves typed data', () {
    final original = annotation(
      attachment: const AnnotationAttachment(
        type: AnnotationTargetType.state,
        targetId: 'q0',
        offsetX: 3,
        offsetY: 4,
      ),
    );

    expect(DocumentAnnotation.fromJson(original.toJson()), original);
  });

  test('sanitization normalizes line endings and removes control characters',
      () {
    expect(annotation(text: 'a\r\nb\u0000\u0008\tc').text, 'a\nb\tc');
  });

  test('Unicode text is lossless and oversized text is rejected', () {
    final unicode = annotation(text: 'λ, ε, 漢字, and emoji 🧠');
    expect(DocumentAnnotation.fromJson(unicode.toJson()), unicode);
    expect(
      () => annotation(
        text: List.filled(
          DocumentAnnotation.maximumTextLength + 1,
          'x',
        ).join(),
      ),
      throwsArgumentError,
    );
  });

  test('collection searches text and attachment targets', () {
    final collection = DocumentAnnotationCollection(
      documentId: 'doc-1',
      documentRevision: 'revision-1',
      annotations: [
        annotation(),
        annotation(
          id: 'note-2',
          text: 'Second',
          attachment: const AnnotationAttachment(
            type: AnnotationTargetType.production,
            targetId: 'S -> a',
          ),
        ),
      ],
    );

    expect(collection.search('remember').single.id, 'note-1');
    expect(collection.search('s -> a').single.id, 'note-2');
  });

  test('collection rejects annotations from another revision', () {
    expect(
      () => DocumentAnnotationCollection(
        documentId: 'doc-1',
        documentRevision: 'revision-2',
        annotations: [annotation()],
      ),
      throwsArgumentError,
    );
  });

  test('deleting an attachment target can delete, detach, or preserve notes',
      () {
    final attached = annotation(
      attachment: const AnnotationAttachment(
        type: AnnotationTargetType.state,
        targetId: 'q0',
        offsetX: 3,
        offsetY: 4,
      ),
    );
    final collection = DocumentAnnotationCollection(
      documentId: 'doc-1',
      documentRevision: 'revision-1',
      annotations: [attached],
    );

    expect(
      collection
          .resolveTargetDeletion(
            type: AnnotationTargetType.state,
            targetId: 'q0',
            policy: AnnotationTargetDeletionPolicy.delete,
            timestamp: timestamp,
          )
          .annotations,
      isEmpty,
    );
    final detached = collection.resolveTargetDeletion(
      type: AnnotationTargetType.state,
      targetId: 'q0',
      policy: AnnotationTargetDeletionPolicy.detach,
      resolvedPosition: (x: 50, y: 60),
      timestamp: timestamp,
    );
    expect(detached.annotations.single.attachment, isNull);
    expect(detached.annotations.single.x, 53);
    expect(detached.annotations.single.y, 64);
    expect(
      collection
          .resolveTargetDeletion(
            type: AnnotationTargetType.state,
            targetId: 'q0',
            policy: AnnotationTargetDeletionPolicy.keepUnresolved,
            timestamp: timestamp,
          )
          .annotations
          .single
          .attachment,
      attached.attachment,
    );
  });

  test('extensions merge annotations without discarding foreign data', () {
    final collection = DocumentAnnotationCollection(
      documentId: 'doc-1',
      documentRevision: 'revision-1',
      annotations: [annotation()],
    );
    final extensions = extensionsWithAnnotations(
      DocumentExtensionBag({'foreign': true}),
      collection,
    );

    expect(extensions.values['foreign'], isTrue);
    expect(annotationsFromExtensions(extensions), collection);
  });

  test('semantic comparison ignores notes while fidelity includes them', () {
    final left = DocumentExtensionBag({'foreign': true});
    final right = extensionsWithAnnotations(
      left,
      DocumentAnnotationCollection(
        documentId: 'doc-1',
        documentRevision: 'revision-1',
        annotations: [annotation()],
      ),
    );

    expect(semanticExtensionsEqual(left, right), isTrue);
    expect(annotationFidelityEqual(left, right), isFalse);
  });
}
