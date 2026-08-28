import 'dart:typed_data';

import 'variable_dependency_export_contract.dart';

VariableDependencyExportService createVariableDependencyExportService() =>
    const _UnsupportedVariableDependencyExportService();

final class _UnsupportedVariableDependencyExportService
    implements VariableDependencyExportService {
  const _UnsupportedVariableDependencyExportService();

  @override
  Future<String?> saveSvg({
    required String suggestedName,
    required String svg,
    required String dialogTitle,
  }) async => null;

  @override
  Future<String?> savePng({
    required String suggestedName,
    required Uint8List bytes,
    required String dialogTitle,
  }) async => null;
}
