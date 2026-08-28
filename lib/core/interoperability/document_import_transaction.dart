import 'dart:async';

import 'codec_outcome.dart';

typedef DocumentCheckpointCapture<TCheckpoint> = FutureOr<TCheckpoint>
    Function();
typedef DocumentCheckpointRestore<TCheckpoint> = FutureOr<void> Function(
  TCheckpoint checkpoint,
);

abstract interface class DocumentImportTarget<TDocument extends Object,
    TCheckpoint> {
  FutureOr<TCheckpoint> captureCheckpoint();

  Future<void> replace(InteroperableDocument<TDocument> document);

  FutureOr<void> restore(TCheckpoint checkpoint);
}

final class CallbackDocumentImportTarget<TDocument extends Object, TCheckpoint>
    implements DocumentImportTarget<TDocument, TCheckpoint> {
  const CallbackDocumentImportTarget({
    required DocumentCheckpointCapture<TCheckpoint> captureCheckpoint,
    required Future<void> Function(InteroperableDocument<TDocument> document)
        replace,
    required DocumentCheckpointRestore<TCheckpoint> restoreCheckpoint,
  })  : _captureCheckpoint = captureCheckpoint,
        _replace = replace,
        _restoreCheckpoint = restoreCheckpoint;

  final DocumentCheckpointCapture<TCheckpoint> _captureCheckpoint;
  final Future<void> Function(InteroperableDocument<TDocument> document)
      _replace;
  final DocumentCheckpointRestore<TCheckpoint> _restoreCheckpoint;

  @override
  FutureOr<TCheckpoint> captureCheckpoint() => _captureCheckpoint();

  @override
  Future<void> replace(InteroperableDocument<TDocument> document) =>
      _replace(document);

  @override
  FutureOr<void> restore(TCheckpoint checkpoint) =>
      _restoreCheckpoint(checkpoint);
}

final class DocumentImportRollbackFailure implements Exception {
  const DocumentImportRollbackFailure({
    required this.replaceError,
    required this.rollbackError,
  });

  final Object replaceError;
  final Object rollbackError;

  static const code = 'document-import.rollback-failed';
}

final class DocumentImportTransaction<TDocument extends Object, TCheckpoint> {
  DocumentImportTransaction._(
    this.outcome,
    this._target,
  );

  factory DocumentImportTransaction.prepare({
    required CodecOutcome<InteroperableDocument<TDocument>> outcome,
    required DocumentImportTarget<TDocument, TCheckpoint> target,
  }) {
    return DocumentImportTransaction._(outcome, target);
  }

  final CodecOutcome<InteroperableDocument<TDocument>> outcome;
  final DocumentImportTarget<TDocument, TCheckpoint> _target;
  _TransactionState _state = _TransactionState.prepared;

  bool get requiresLossConfirmation =>
      outcome is CodecSuccess<InteroperableDocument<TDocument>> &&
      (outcome as CodecSuccess<InteroperableDocument<TDocument>>).fidelity ==
          DocumentFidelity.lossy;

  Future<void> commit({bool allowLossy = false}) async {
    if (_state != _TransactionState.prepared) {
      throw StateError('Import transaction is not in a committable state');
    }
    final result = outcome;
    if (result is! CodecSuccess<InteroperableDocument<TDocument>>) {
      throw StateError('Only a successful decode can be committed');
    }
    if (result.fidelity == DocumentFidelity.lossy && !allowLossy) {
      throw StateError('Lossy import requires explicit confirmation');
    }
    _state = _TransactionState.committing;
    late final TCheckpoint checkpoint;
    try {
      checkpoint = await _target.captureCheckpoint();
    } catch (_) {
      _state = _TransactionState.prepared;
      rethrow;
    }
    try {
      await _target.replace(result.value);
      _state = _TransactionState.committed;
    } catch (replaceError, replaceStackTrace) {
      try {
        await _target.restore(checkpoint);
      } catch (rollbackError) {
        _state = _TransactionState.rollbackFailed;
        throw DocumentImportRollbackFailure(
          replaceError: replaceError,
          rollbackError: rollbackError,
        );
      }
      _state = _TransactionState.prepared;
      Error.throwWithStackTrace(replaceError, replaceStackTrace);
    }
  }
}

enum _TransactionState { prepared, committing, committed, rollbackFailed }
