import 'dart:typed_data';

import 'codec_outcome.dart';
import 'codec_source.dart';

abstract interface class DocumentTransport {
  Future<DocumentPayload> read(String location);

  Future<void> write(
    String location,
    Uint8List bytes, {
    required String mimeType,
  });
}

typedef DocumentPayloadReader =
    Future<DocumentPayload> Function(String location);
typedef DocumentPayloadWriter =
    Future<void> Function(String location, Uint8List bytes, String mimeType);

final class CallbackDocumentTransport implements DocumentTransport {
  const CallbackDocumentTransport({
    required DocumentPayloadReader read,
    required DocumentPayloadWriter write,
  }) : _read = read,
       _write = write;

  final DocumentPayloadReader _read;
  final DocumentPayloadWriter _write;

  @override
  Future<DocumentPayload> read(String location) => _read(location);

  @override
  Future<void> write(
    String location,
    Uint8List bytes, {
    required String mimeType,
  }) => _write(location, bytes, mimeType);
}

final class DocumentExportTransaction {
  DocumentExportTransaction._(this.outcome, this._transport, this._location);

  factory DocumentExportTransaction.prepare({
    required CodecOutcome<EncodedDocument> outcome,
    required DocumentTransport transport,
    required String location,
  }) {
    if (location.trim().isEmpty) {
      throw ArgumentError.value(
        location,
        'location',
        'interop.transport.empty-location',
      );
    }
    return DocumentExportTransaction._(outcome, transport, location);
  }

  final CodecOutcome<EncodedDocument> outcome;
  final DocumentTransport _transport;
  final String _location;
  _ExportTransactionState _state = _ExportTransactionState.prepared;

  bool get requiresLossConfirmation =>
      outcome is CodecSuccess<EncodedDocument> &&
      (outcome as CodecSuccess<EncodedDocument>).fidelity ==
          DocumentFidelity.lossy;

  Future<void> commit({bool allowLossy = false}) async {
    if (_state != _ExportTransactionState.prepared) {
      throw StateError('Export transaction is already committing or committed');
    }
    final result = outcome;
    if (result is! CodecSuccess<EncodedDocument>) {
      throw StateError('Only a successful encode can be committed');
    }
    if (result.fidelity == DocumentFidelity.lossy && !allowLossy) {
      throw StateError('Lossy export requires explicit confirmation');
    }
    _state = _ExportTransactionState.committing;
    try {
      await _transport.write(
        _location,
        result.value.bytes,
        mimeType: result.value.mimeType,
      );
      _state = _ExportTransactionState.committed;
    } catch (_) {
      _state = _ExportTransactionState.prepared;
      rethrow;
    }
  }
}

enum _ExportTransactionState { prepared, committing, committed }

final class MemoryDocumentTransport implements DocumentTransport {
  final Map<String, _MemoryTransportEntry> _documents = {};

  @override
  Future<DocumentPayload> read(String location) async {
    final document = _documents[location];
    if (document == null) throw StateError('No document at $location');
    return DocumentPayload(
      bytes: document.bytes,
      filename: document.filename,
      mimeType: document.mimeType,
      sourcePath: location,
    );
  }

  @override
  Future<void> write(
    String location,
    Uint8List bytes, {
    required String mimeType,
  }) async {
    _documents[location] = _MemoryTransportEntry(
      Uint8List.fromList(bytes),
      mimeType,
      location.split(RegExp(r'[/\\]')).last,
    );
  }
}

final class _MemoryTransportEntry {
  const _MemoryTransportEntry(this.bytes, this.mimeType, this.filename);

  final Uint8List bytes;
  final String mimeType;
  final String filename;
}
