import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/presentation/providers/document_annotations_provider.dart';

void main() {
  const key = DefaultFormalSystemIds.fsa;
  final timestamp = DateTime.utc(2026, 8, 25);

  test('add, edit, duplicate, undo, and redo preserve annotation history', () {
    final notifier = DocumentAnnotationsNotifier();
    final note = notifier.add(
      key: key,
      documentId: 'doc-1',
      documentRevision: '1',
      x: 10,
      y: 20,
      text: 'First',
      timestamp: timestamp,
    );
    notifier.update(
      key,
      note.copyWith(text: 'Edited', updatedAt: timestamp),
    );
    final duplicate = notifier.duplicate(key, note.id, timestamp: timestamp);

    expect(notifier.state[key]!.annotations, hasLength(2));
    expect(duplicate, isNotNull);
    notifier.undo(key);
    expect(notifier.state[key]!.annotations, hasLength(1));
    expect(notifier.state[key]!.annotations.single.text, 'Edited');
    notifier.redo(key);
    expect(notifier.state[key]!.annotations, hasLength(2));
  });

  test('switching document identity clears inherited annotations', () {
    final notifier = DocumentAnnotationsNotifier();
    notifier.add(
      key: key,
      documentId: 'doc-1',
      documentRevision: '1',
      x: 0,
      y: 0,
      timestamp: timestamp,
    );

    final replacement = notifier.collectionFor(
      key,
      documentId: 'doc-2',
      documentRevision: '1',
    );

    expect(replacement.annotations, isEmpty);
    expect(replacement.documentId, 'doc-2');
    expect(notifier.canUndo(key), isFalse);
  });

  test('related target deletions create one annotation history entry', () {
    final notifier = DocumentAnnotationsNotifier();
    for (final target in const [
      AnnotationAttachment(
        type: AnnotationTargetType.state,
        targetId: 'q0',
      ),
      AnnotationAttachment(
        type: AnnotationTargetType.transition,
        targetId: 't0',
      ),
    ]) {
      notifier.add(
        key: key,
        documentId: 'doc-1',
        documentRevision: '1',
        x: 0,
        y: 0,
        attachment: target,
        timestamp: timestamp,
      );
    }

    notifier.resolveTargetDeletions(
      key: key,
      targets: const [
        (
          type: AnnotationTargetType.state,
          targetId: 'q0',
          resolvedPosition: null,
        ),
        (
          type: AnnotationTargetType.transition,
          targetId: 't0',
          resolvedPosition: null,
        ),
      ],
      policy: AnnotationTargetDeletionPolicy.delete,
      timestamp: timestamp,
    );

    expect(notifier.state[key]!.annotations, isEmpty);
    notifier.undo(key);
    expect(notifier.state[key]!.annotations, hasLength(2));
  });
}
