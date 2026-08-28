import 'dart:typed_data';

final class BatchInputFileSelection {
  const BatchInputFileSelection({required this.filename, required this.bytes});

  final String filename;
  final Uint8List bytes;
}

abstract interface class BatchFileService {
  Future<BatchInputFileSelection?> pickInputs({required String dialogTitle});

  Future<String?> saveReport({
    required String filename,
    required String contents,
    required String dialogTitle,
  });
}
