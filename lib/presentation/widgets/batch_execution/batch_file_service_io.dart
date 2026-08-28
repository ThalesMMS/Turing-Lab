import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'batch_file_service_contract.dart';

BatchFileService createBatchFileService() => const _IoBatchFileService();

final class _IoBatchFileService implements BatchFileService {
  const _IoBatchFileService();

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
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) return null;
    return BatchInputFileSelection(filename: file.name, bytes: bytes);
  }

  @override
  Future<String?> saveReport({
    required String filename,
    required String contents,
    required String dialogTitle,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    final pickerWritesBytes = Platform.isAndroid || Platform.isIOS;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: [filename.split('.').last],
      bytes: pickerWritesBytes ? bytes : null,
    );
    if (path == null) return null;
    if (!pickerWritesBytes) await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}
