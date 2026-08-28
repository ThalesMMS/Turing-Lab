import 'batch_file_service_contract.dart';
import 'batch_file_service_stub.dart'
    if (dart.library.io) 'batch_file_service_io.dart'
    if (dart.library.html) 'batch_file_service_web.dart' as implementation;

export 'batch_file_service_contract.dart';

BatchFileService createBatchFileService() =>
    implementation.createBatchFileService();
