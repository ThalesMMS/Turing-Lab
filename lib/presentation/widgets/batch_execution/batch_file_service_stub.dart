import 'batch_file_service_contract.dart';

BatchFileService createBatchFileService() =>
    const _UnsupportedBatchFileService();

final class _UnsupportedBatchFileService implements BatchFileService {
  const _UnsupportedBatchFileService();

  @override
  Future<BatchInputFileSelection?> pickInputs({
    required String dialogTitle,
  }) async => null;

  @override
  Future<String?> saveReport({
    required String filename,
    required String contents,
    required String dialogTitle,
  }) async => null;
}
