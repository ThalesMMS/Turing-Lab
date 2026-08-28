import 'package:xml/xml.dart';

import '../../core/annotations/annotations.dart';
import '../../core/interoperability/interoperability.dart';
import 'codec_utils.dart';

DocumentAnnotationCollection? readJflapAnnotations(
  XmlElement automaton, {
  required String documentId,
  required String documentRevision,
  required Map<String, Object?> extensions,
  required List<CodecDiagnostic> diagnostics,
}) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final annotations = <DocumentAnnotation>[];
  var index = 0;
  for (final note in automaton.findElements('note')) {
    final x = double.tryParse(note.getElement('x')?.innerText.trim() ?? '');
    final y = double.tryParse(note.getElement('y')?.innerText.trim() ?? '');
    if (x == null || y == null || !x.isFinite || !y.isFinite) {
      final invalidNotes =
          extensions['invalidNoteXml'] as List<String>? ?? <String>[];
      invalidNotes.add(note.toXmlString());
      extensions['invalidNoteXml'] = invalidNotes;
      diagnostics.add(CodecDiagnostic(
        code: 'jflap.note-invalid-position-preserved',
        message: 'A note with an invalid position was preserved as raw XML.',
        path: '/structure/automaton/note[$index]',
      ));
      index++;
      continue;
    }
    annotations.add(
      DocumentAnnotation(
        id: 'jflap-note-$index',
        documentId: documentId,
        documentRevision: documentRevision,
        text: note.getElement('text')?.innerText ?? '',
        x: x,
        y: y,
        createdAt: epoch,
        updatedAt: epoch,
      ),
    );
    index++;
  }
  if (annotations.isEmpty) return null;
  diagnostics.add(const CodecDiagnostic(
    code: 'jflap.notes-normalized',
    message: 'JFLAP notes were imported with the default Turing Lab style.',
    path: '/structure/automaton/note',
    disposition: CodecDiagnosticDisposition.normalized,
  ));
  final collection = DocumentAnnotationCollection(
    documentId: documentId,
    documentRevision: documentRevision,
    annotations: annotations,
  );
  extensions[documentAnnotationsExtensionKey] = collection.toJson();
  return collection;
}

void writeJflapAnnotations(
  XmlBuilder builder,
  DocumentExtensionBag extensions,
  List<CodecDiagnostic> diagnostics,
) {
  writeXmlExtensions(builder, extensions.values['invalidNoteXml']);
  final collection = annotationsFromExtensions(extensions);
  if (collection == null) return;
  for (final annotation in collection.annotations) {
    builder.element('note', nest: () {
      builder.element('text', nest: annotation.text);
      builder.element('x', nest: formatXmlNumber(annotation.x));
      builder.element('y', nest: formatXmlNumber(annotation.y));
    });
    final unsupported = <String>[
      if (annotation.attachment != null) 'attachment',
      if (annotation.styleRole != AnnotationStyleRole.note) 'style',
      if (annotation.width != DocumentAnnotation.defaultWidth ||
          annotation.height != DocumentAnnotation.defaultHeight)
        'size',
      if (annotation.collapsed) 'collapsed state',
      if (annotation.authorLabel != null) 'author metadata',
    ];
    if (unsupported.isNotEmpty) {
      diagnostics.add(CodecDiagnostic(
        code: 'jflap.note-presentation-dropped',
        message: 'JFLAP cannot store this note\'s ${unsupported.join(', ')}.',
        path: '\$.extensions.$documentAnnotationsExtensionKey.${annotation.id}',
        sourceValue: unsupported,
        disposition: CodecDiagnosticDisposition.dropped,
      ));
    }
  }
}
