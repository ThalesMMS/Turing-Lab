import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'batch_file_service_contract.dart';

BatchFileService createBatchFileService() => const _WebBatchFileService();

final class _WebBatchFileService implements BatchFileService {
  const _WebBatchFileService();

  @override
  Future<BatchInputFileSelection?> pickInputs({
    required String dialogTitle,
  }) async {
    final selection = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['txt', 'csv'],
      withData: true,
    );
    if (selection == null || selection.files.isEmpty) return null;
    final file = selection.files.single;
    if (file.bytes == null) return null;
    return BatchInputFileSelection(filename: file.name, bytes: file.bytes!);
  }

  @override
  Future<String?> saveReport({
    required String filename,
    required String contents,
    required String dialogTitle,
  }) => FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: [filename.split('.').last],
    bytes: Uint8List.fromList(utf8.encode(contents)),
  );
}
