import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'variable_dependency_export_contract.dart';

VariableDependencyExportService createVariableDependencyExportService() =>
    const _WebVariableDependencyExportService();

final class _WebVariableDependencyExportService
    implements VariableDependencyExportService {
  const _WebVariableDependencyExportService();

  @override
  Future<String?> saveSvg({
    required String suggestedName,
    required String svg,
    required String dialogTitle,
  }) => FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: '$suggestedName.svg',
    type: FileType.custom,
    allowedExtensions: const ['svg'],
    bytes: Uint8List.fromList(utf8.encode(svg)),
  );

  @override
  Future<String?> savePng({
    required String suggestedName,
    required Uint8List bytes,
    required String dialogTitle,
  }) => FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: '$suggestedName.png',
    type: FileType.custom,
    allowedExtensions: const ['png'],
    bytes: bytes,
  );
}
