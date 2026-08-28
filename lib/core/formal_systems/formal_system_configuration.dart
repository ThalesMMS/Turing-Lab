enum FormalSystemConfigurationIssueCode {
  duplicateFormalSystemKey,
  duplicateRoute,
  duplicateSchema,
  duplicateFormat,
  duplicateExtension,
  duplicateConversionEdge,
  duplicateLocalizationNamespace,
  duplicateSemanticsNamespace,
  duplicateExampleNamespace,
  duplicateSessionNamespace,
  unknownFormat,
  unknownConversionTarget,
  invalidIdentifier,
  invalidSchemaVersion,
  invalidRoute,
  invalidExtension,
}

final class FormalSystemConfigurationIssue
    implements Comparable<FormalSystemConfigurationIssue> {
  FormalSystemConfigurationIssue({
    required this.code,
    required this.value,
    required Iterable<String> owners,
  }) : owners = List<String>.unmodifiable(owners.toList()..sort());

  final FormalSystemConfigurationIssueCode code;
  final String value;
  final List<String> owners;

  @override
  int compareTo(FormalSystemConfigurationIssue other) {
    final codeComparison = code.name.compareTo(other.code.name);
    if (codeComparison != 0) return codeComparison;
    final valueComparison = value.compareTo(other.value);
    if (valueComparison != 0) return valueComparison;
    return owners.join('\u0000').compareTo(other.owners.join('\u0000'));
  }

  @override
  String toString() => '${code.name}: $value [${owners.join(', ')}]';
}

final class FormalSystemConfigurationException implements Exception {
  FormalSystemConfigurationException(
      Iterable<FormalSystemConfigurationIssue> issues)
      : issues = List<FormalSystemConfigurationIssue>.unmodifiable(
          issues.toList()..sort(),
        );

  final List<FormalSystemConfigurationIssue> issues;

  @override
  String toString() =>
      'Formal-system configuration is invalid:\n${issues.map((issue) => '- $issue').join('\n')}';
}
