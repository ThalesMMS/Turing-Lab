import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/interoperable_document_sidecar_provider.dart';

void main() {
  const schema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('sample.schema'),
    version: DocumentSchemaVersion(1),
  );
  const key = FormalSystemKey(
    type: FormalSystemTypeId('sample'),
    variant: FormalSystemVariantId('default'),
  );

  test('same document identity preserves extensions after an editor update',
      () {
    final imported = InteroperableDocument<Object>(
      document: const _SampleDocument('doc-1', 'before'),
      systemKey: key,
      schema: schema,
      sourceMetadata: const DocumentSourceMetadata(
        application: 'External tool',
      ),
      extensions: DocumentExtensionBag({
        '/unknown': const {'value': 7},
      }),
    );
    final entry = InteroperableDocumentSidecarEntry(
      document: imported,
      documentIdentity: 'doc-1',
    );

    final resolved = resolveInteroperableDocument(
      sidecar: entry,
      currentDocument: const _SampleDocument('doc-1', 'after edit'),
      documentIdentity: 'doc-1',
      systemKey: key,
      schema: schema,
    );

    expect((resolved.document as _SampleDocument).value, 'after edit');
    expect(resolved.extensions.values['/unknown'], const {'value': 7});
    expect(resolved.sourceMetadata.application, 'External tool');
  });

  test('new document identity does not inherit extensions', () {
    final entry = InteroperableDocumentSidecarEntry(
      document: InteroperableDocument<Object>(
        document: const _SampleDocument('doc-1', 'old'),
        systemKey: key,
        schema: schema,
        extensions: DocumentExtensionBag({'/unknown': true}),
      ),
      documentIdentity: 'doc-1',
    );

    final resolved = resolveInteroperableDocument(
      sidecar: entry,
      currentDocument: const _SampleDocument('doc-2', 'new'),
      documentIdentity: 'doc-2',
      systemKey: key,
      schema: schema,
    );

    expect(resolved.extensions.isEmpty, isTrue);
  });

  test('current annotations merge with preserved imported extensions', () {
    final entry = InteroperableDocumentSidecarEntry(
      document: InteroperableDocument<Object>(
        document: const _SampleDocument('doc-1', 'old'),
        systemKey: key,
        schema: schema,
        extensions: DocumentExtensionBag({'foreign': true}),
      ),
      documentIdentity: 'doc-1',
    );
    final annotations = DocumentAnnotationCollection(
      documentId: 'doc-1',
      documentRevision: '1',
      annotations: [
        DocumentAnnotation(
          id: 'note-1',
          documentId: 'doc-1',
          documentRevision: '1',
          text: 'Current note',
          x: 1,
          y: 2,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ],
    );

    final resolved = resolveInteroperableDocument(
      sidecar: entry,
      currentDocument: const _SampleDocument('doc-1', 'current'),
      documentIdentity: 'doc-1',
      systemKey: key,
      schema: schema,
      annotations: annotations,
    );

    expect(resolved.extensions.values['foreign'], isTrue);
    expect(annotationsFromExtensions(resolved.extensions), annotations);
  });

  test('reused model id from a new origin does not inherit extensions', () {
    final entry = InteroperableDocumentSidecarEntry(
      document: InteroperableDocument<Object>(
        document: const _SampleDocument('reused', 'old'),
        systemKey: key,
        schema: schema,
        extensions: DocumentExtensionBag({'/unknown': true}),
      ),
      documentIdentity: ('reused', 1),
    );

    final resolved = resolveInteroperableDocument(
      sidecar: entry,
      currentDocument: const _SampleDocument('reused', 'new origin'),
      documentIdentity: ('reused', 2),
      systemKey: key,
      schema: schema,
    );

    expect(resolved.extensions.isEmpty, isTrue);
  });

  test('editor and auto-layout commits preserve imported FSA extensions', () {
    final notifier = AutomatonStateNotifier();
    final imported = _fsa('reused', 'Imported');
    notifier.replaceAutomaton(imported);
    final importedGeneration = notifier.state.documentGeneration;
    final entry = InteroperableDocumentSidecarEntry(
      document: InteroperableDocument<Object>(
        document: imported,
        systemKey: DefaultFormalSystemIds.fsa,
        schema: schema,
        sourceMetadata: const DocumentSourceMetadata(application: 'JFLAP'),
        extensions: DocumentExtensionBag({'/unknown': true}),
      ),
      documentIdentity: (imported.id, importedGeneration),
    );

    // Canvas and auto-layout both commit through updateAutomaton.
    final edited = _fsa('reused', 'Edited and laid out');
    notifier.updateAutomaton(edited);

    expect(notifier.state.documentGeneration, importedGeneration);
    final resolved = resolveInteroperableDocument(
      sidecar: entry,
      currentDocument: notifier.currentAutomaton!,
      documentIdentity: (
        notifier.currentAutomaton!.id,
        notifier.state.documentGeneration,
      ),
      systemKey: DefaultFormalSystemIds.fsa,
      schema: schema,
    );
    expect((resolved.document as FSA).name, 'Edited and laid out');
    expect(resolved.extensions.values['/unknown'], isTrue);
    expect(resolved.sourceMetadata.application, 'JFLAP');
  });

  test('replacement with a reused FSA id starts a new origin', () {
    final notifier = AutomatonStateNotifier();
    final imported = _fsa('reused', 'Imported');
    notifier.replaceAutomaton(imported);
    final generation = notifier.state.documentGeneration;
    final entry = InteroperableDocumentSidecarEntry(
      document: InteroperableDocument<Object>(
        document: imported,
        systemKey: DefaultFormalSystemIds.fsa,
        schema: schema,
        extensions: DocumentExtensionBag({'/unknown': true}),
      ),
      documentIdentity: (imported.id, generation),
    );

    notifier.replaceAutomaton(_fsa('reused', 'New document'));
    final resolved = resolveInteroperableDocument(
      sidecar: entry,
      currentDocument: notifier.currentAutomaton!,
      documentIdentity: (
        notifier.currentAutomaton!.id,
        notifier.state.documentGeneration,
      ),
      systemKey: DefaultFormalSystemIds.fsa,
      schema: schema,
    );

    expect(notifier.state.documentGeneration, generation + 1);
    expect(resolved.extensions.isEmpty, isTrue);
  });
}

FSA _fsa(String id, String name) {
  final now = DateTime(2026);
  return FSA(
    id: id,
    name: name,
    states: const {},
    transitions: const {},
    alphabet: const {},
    acceptingStates: const {},
    created: now,
    modified: now,
    bounds: const Rectangle<double>(0, 0, 400, 300),
  );
}

final class _SampleDocument {
  const _SampleDocument(this.id, this.value);

  final String id;
  final String value;
}
