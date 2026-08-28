import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'variable_dependency_export_contract.dart';

VariableDependencyExportService createVariableDependencyExportService() =>
    const _IoVariableDependencyExportService();

final class _IoVariableDependencyExportService
    implements VariableDependencyExportService {
  const _IoVariableDependencyExportService();

  @override
  Future<String?> saveSvg({
    required String suggestedName,
    required String svg,
    required String dialogTitle,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: '$suggestedName.svg',
      type: FileType.custom,
      allowedExtensions: const ['svg'],
    );
    if (path == null) return null;
    await File(path).writeAsString(svg);
    return path;
  }

  @override
  Future<String?> savePng({
    required String suggestedName,
    required Uint8List bytes,
    required String dialogTitle,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: '$suggestedName.png',
      type: FileType.custom,
      allowedExtensions: const ['png'],
    );
    if (path == null) return null;
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
