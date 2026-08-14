import 'package:file_picker/file_picker.dart';

import '../../../core/models/fsa.dart';
import '../../../core/models/grammar.dart';
import '../../../core/result.dart';
import '../../../core/services/file_operations_gateway.dart';

const _kUnreadableFileMessage =
    'Turing Lab could not access the selected file data. Pick the file again and keep it available until the import finishes.';

String? _normalizedPath(String? path) {
  if (path == null) {
    return null;
  }

  final trimmed = path.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Loads an automaton from the provided [PlatformFile], preferring in-memory
/// bytes when available to support web targets where no physical path exists.
Future<Result<FSA>> loadAutomatonFromPlatformFile(
  FileOperationsGateway service,
  PlatformFile file,
) async {
  if (file.bytes != null) {
    return service.loadAutomatonFromBytes(file.bytes!);
  }

  final normalizedPath = _normalizedPath(file.path);
  if (normalizedPath != null) {
    return service.loadAutomatonFromJFLAP(normalizedPath);
  }

  return const Failure<FSA>(_kUnreadableFileMessage);
}

/// Loads a grammar from the provided [PlatformFile], preferring in-memory
/// bytes when available to support web targets where no physical path exists.
Future<Result<Grammar>> loadGrammarFromPlatformFile(
  FileOperationsGateway service,
  PlatformFile file,
) async {
  if (file.bytes != null) {
    return service.loadGrammarFromBytes(file.bytes!);
  }

  final normalizedPath = _normalizedPath(file.path);
  if (normalizedPath != null) {
    return service.loadGrammarFromJFLAP(normalizedPath);
  }

  return const Failure<Grammar>(_kUnreadableFileMessage);
}
