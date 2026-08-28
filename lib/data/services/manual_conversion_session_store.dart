import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/manual_conversions/manual_conversion_session.dart';
import '../../core/messages/structured_message.dart';

class ManualConversionSessionStore {
  const ManualConversionSessionStore(this._preferences);

  static const keyPrefix = 'manual_conversion_session.';

  final SharedPreferences _preferences;

  Future<bool> save(String workspaceKey, ManualConversionSession session) {
    return _preferences.setString(
      '$keyPrefix$workspaceKey',
      jsonEncode(session.toJson()),
    );
  }

  ManualConversionRestoreResult load(
    String workspaceKey, {
    required String documentId,
    required int revision,
  }) {
    try {
      final encoded = _preferences.getString('$keyPrefix$workspaceKey');
      if (encoded == null) {
        return const ManualConversionRestoreResult();
      }
      return ManualConversionSession.restore(
        jsonDecode(encoded),
        documentId: documentId,
        revision: revision,
      );
    } on Object {
      return ManualConversionRestoreResult(
        diagnostics: [
          ManualConversionDiagnostic(
            code: ManualConversionDiagnosticCode.malformedPayload,
            message: 'service.manual-conversion-store.malformed-payload',
            structuredMessage: StructuredMessage(
              namespace: 'service',
              code: 'manual-conversion-store.malformed-payload',
              category: StructuredMessageCategory.conversion,
              severity: StructuredMessageSeverity.error,
            ),
          ),
        ],
      );
    }
  }

  Future<bool> clear(String workspaceKey) {
    return _preferences.remove('$keyPrefix$workspaceKey');
  }
}
