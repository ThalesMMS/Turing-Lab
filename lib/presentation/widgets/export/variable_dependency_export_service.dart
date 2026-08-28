import 'variable_dependency_export_contract.dart';
import 'variable_dependency_export_service_stub.dart'
    if (dart.library.io) 'variable_dependency_export_service_io.dart'
    if (dart.library.js_interop) 'variable_dependency_export_service_web.dart'
    as implementation;

export 'variable_dependency_export_contract.dart';

VariableDependencyExportService createVariableDependencyExportService() =>
    implementation.createVariableDependencyExportService();
