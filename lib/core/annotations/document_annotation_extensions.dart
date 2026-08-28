import '../interoperability/codec_source.dart';
import 'package:collection/collection.dart';
import 'document_annotation_collection.dart';

const documentAnnotationsExtensionKey = 'turingLab.annotations';

DocumentAnnotationCollection? annotationsFromExtensions(
  DocumentExtensionBag extensions,
) {
  final value = extensions.values[documentAnnotationsExtensionKey];
  if (value == null) return null;
  if (value is! Map) {
    throw const FormatException('Document annotations must be an object.');
  }
  return DocumentAnnotationCollection.fromJson(
    value.cast<String, dynamic>(),
  );
}

DocumentExtensionBag extensionsWithAnnotations(
  DocumentExtensionBag extensions,
  DocumentAnnotationCollection? annotations,
) {
  final values = Map<String, Object?>.of(extensions.values);
  if (annotations == null || annotations.annotations.isEmpty) {
    values.remove(documentAnnotationsExtensionKey);
  } else {
    values[documentAnnotationsExtensionKey] = annotations.toJson();
  }
  return DocumentExtensionBag(values);
}

bool semanticExtensionsEqual(
  DocumentExtensionBag left,
  DocumentExtensionBag right,
) {
  Map<String, Object?> withoutAnnotations(DocumentExtensionBag bag) =>
      Map<String, Object?>.of(bag.values)
        ..remove(documentAnnotationsExtensionKey);
  return const DeepCollectionEquality().equals(
    withoutAnnotations(left),
    withoutAnnotations(right),
  );
}

bool annotationFidelityEqual(
  DocumentExtensionBag left,
  DocumentExtensionBag right,
) =>
    const DeepCollectionEquality().equals(left.values, right.values);
