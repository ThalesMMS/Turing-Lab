import '../messages/structured_message.dart';
import '../models/validation_diagnostic.dart';

class ValidationIssue {
  final String code;
  final String message;
  final String? location;

  /// Optional structured diagnostics payload. When present, UI layers can show
  /// actionable suggestions/highlights without parsing [message].
  final ValidationDiagnostic? diagnostic;

  /// Optional locale-neutral semantic message for presentation resolvers.
  final StructuredMessage? structuredMessage;

  const ValidationIssue(
    this.code,
    this.message, {
    this.location,
    this.diagnostic,
    this.structuredMessage,
  });
}
