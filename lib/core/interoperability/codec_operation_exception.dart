import '../messages/structured_message.dart';

/// Locale-neutral exception bridge for synchronous codec APIs.
final class CodecOperationException implements Exception {
  const CodecOperationException({
    required this.compatibilityCode,
    required this.structuredMessage,
  });

  final String compatibilityCode;
  final StructuredMessage structuredMessage;

  @override
  String toString() => compatibilityCode;
}
