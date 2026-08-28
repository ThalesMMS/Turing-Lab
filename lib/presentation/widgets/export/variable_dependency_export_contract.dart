import 'dart:typed_data';

abstract interface class VariableDependencyExportService {
  Future<String?> saveSvg({
    required String suggestedName,
    required String svg,
    required String dialogTitle,
  });

  Future<String?> savePng({
    required String suggestedName,
    required Uint8List bytes,
    required String dialogTitle,
  });
}
