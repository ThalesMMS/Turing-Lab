import 'document_format.dart';
import 'default_formal_system_modules.dart';
import 'formal_system_capabilities.dart';
import 'formal_system_configuration.dart';
import 'formal_system_descriptor.dart';
import 'formal_system_ids.dart';
import 'formal_system_module.dart';

final class FormalSystemRegistry {
  factory FormalSystemRegistry({
    required Iterable<FormalSystemModule<Object>> modules,
    required Iterable<DocumentFormatDescriptor> formats,
  }) {
    final moduleList = List<FormalSystemModule<Object>>.unmodifiable(modules);
    final formatList = List<DocumentFormatDescriptor>.unmodifiable(formats);
    final issues = _validate(moduleList, formatList);
    if (issues.isNotEmpty) {
      throw FormalSystemConfigurationException(issues);
    }
    return FormalSystemRegistry._validated(moduleList, formatList);
  }

  FormalSystemRegistry._validated(
    List<FormalSystemModule<Object>> modules,
    List<DocumentFormatDescriptor> formats,
  )   : modules = List<FormalSystemModule<Object>>.unmodifiable(modules),
        formats = DocumentFormatCatalog(formats),
        _byKey = Map<FormalSystemKey, FormalSystemModule<Object>>.unmodifiable({
          for (final module in modules) module.descriptor.key: module,
        });

  static final defaultRegistry = FormalSystemRegistry(
    modules: DefaultFormalSystemModules.modules,
    formats: DefaultFormalSystemModules.formats,
  );

  final List<FormalSystemModule<Object>> modules;
  final DocumentFormatCatalog formats;
  final Map<FormalSystemKey, FormalSystemModule<Object>> _byKey;

  List<FormalSystemDescriptor> get descriptors =>
      List<FormalSystemDescriptor>.unmodifiable(
        modules.map((module) => module.descriptor),
      );

  FormalSystemModule<Object>? moduleFor(FormalSystemKey key) => _byKey[key];

  FormalSystemDescriptor? descriptorFor(FormalSystemKey key) =>
      moduleFor(key)?.descriptor;

  FormalSystemDescriptor? descriptorForRoute(WorkspaceRouteId route) {
    for (final module in modules) {
      if (module.descriptor.route == route) return module.descriptor;
    }
    return null;
  }

  FormalSystemDescriptor? descriptorForSchema(DocumentSchemaId schema) {
    for (final module in modules) {
      if (module.descriptor.schema.id == schema) return module.descriptor;
    }
    return null;
  }

  DocumentFormatDescriptor? formatFor(DocumentFormatId format) =>
      formats[format];

  List<FormalSystemDescriptor> availableFor(
          FormalSystemCapability capability) =>
      List<FormalSystemDescriptor>.unmodifiable(
        modules.map((module) => module.descriptor).where(
            (descriptor) => descriptor.capabilities.supports(capability)),
      );

  List<FormalSystemModule<Object>> modulesSupportingFormat(
    DocumentFormatId format,
    DocumentFormatDirection direction,
  ) =>
      List<FormalSystemModule<Object>>.unmodifiable(
        modules.where(
          (module) =>
              module.descriptor.formatSupport(format)?.supports(direction) ??
              false,
        ),
      );
}

List<FormalSystemConfigurationIssue> _validate(
  List<FormalSystemModule<Object>> modules,
  List<DocumentFormatDescriptor> formats,
) {
  final issues = <FormalSystemConfigurationIssue>[
    ...validateDocumentFormats(formats),
  ];
  final formatsById = {for (final format in formats) format.id};
  final keys = {for (final module in modules) module.descriptor.key};
  final keysByValue = <String, List<String>>{};
  final routes = <String, List<String>>{};
  final schemas = <String, List<String>>{};
  final localizationNamespaces = <String, List<String>>{};
  final semanticsNamespaces = <String, List<String>>{};
  final exampleNamespaces = <String, List<String>>{};
  final sessionNamespaces = <String, List<String>>{};
  final conversionEdges = <String, List<String>>{};

  for (final module in modules) {
    final descriptor = module.descriptor;
    final owner = descriptor.key.value;
    _record(keysByValue, descriptor.key.value, owner);
    _record(routes, descriptor.route.value, owner);
    _record(schemas, descriptor.schema.id.value, owner);
    _record(
      localizationNamespaces,
      descriptor.localizationNamespace.value,
      owner,
    );
    _record(semanticsNamespaces, descriptor.semanticsNamespace.value, owner);
    final exampleNamespace = module.examples?.namespace.value;
    if (exampleNamespace != null) {
      _record(exampleNamespaces, exampleNamespace, owner);
      _validateNamespace(issues, exampleNamespace, owner);
    }
    final sessionNamespace = module.session?.namespace.value;
    if (sessionNamespace != null) {
      _record(sessionNamespaces, sessionNamespace, owner);
      _validateNamespace(issues, sessionNamespace, owner);
    }

    for (final value in [
      descriptor.key.type.value,
      descriptor.key.variant.value,
      descriptor.schema.id.value,
      descriptor.localizationNamespace.value,
      descriptor.semanticsNamespace.value,
    ]) {
      if (value.trim().isEmpty) {
        issues.add(FormalSystemConfigurationIssue(
          code: FormalSystemConfigurationIssueCode.invalidIdentifier,
          value: value,
          owners: [owner],
        ));
      }
    }
    if (descriptor.schema.version.value <= 0) {
      issues.add(FormalSystemConfigurationIssue(
        code: FormalSystemConfigurationIssueCode.invalidSchemaVersion,
        value: '${descriptor.schema.version.value}',
        owners: [owner],
      ));
    }
    if (!descriptor.route.value.startsWith('/')) {
      issues.add(FormalSystemConfigurationIssue(
        code: FormalSystemConfigurationIssueCode.invalidRoute,
        value: descriptor.route.value,
        owners: [owner],
      ));
    }
    for (final support in descriptor.formats) {
      if (!formatsById.contains(support.formatId)) {
        issues.add(FormalSystemConfigurationIssue(
          code: FormalSystemConfigurationIssueCode.unknownFormat,
          value: support.formatId.value,
          owners: [owner],
        ));
      }
      final preferred = support.preferredExtension;
      if (preferred != null && (preferred.isEmpty || preferred.contains('.'))) {
        issues.add(FormalSystemConfigurationIssue(
          code: FormalSystemConfigurationIssueCode.invalidExtension,
          value: preferred,
          owners: [owner],
        ));
      }
    }
    for (final edge in descriptor.conversions) {
      _record(conversionEdges, edge.stableKey, owner);
      if (!keys.contains(edge.target)) {
        issues.add(FormalSystemConfigurationIssue(
          code: FormalSystemConfigurationIssueCode.unknownConversionTarget,
          value: edge.target.value,
          owners: [owner],
        ));
      }
    }
  }

  _duplicates(
    issues,
    keysByValue,
    FormalSystemConfigurationIssueCode.duplicateFormalSystemKey,
  );
  _duplicates(
    issues,
    routes,
    FormalSystemConfigurationIssueCode.duplicateRoute,
  );
  _duplicates(
    issues,
    schemas,
    FormalSystemConfigurationIssueCode.duplicateSchema,
  );
  _duplicates(
    issues,
    conversionEdges,
    FormalSystemConfigurationIssueCode.duplicateConversionEdge,
  );
  _duplicates(
    issues,
    localizationNamespaces,
    FormalSystemConfigurationIssueCode.duplicateLocalizationNamespace,
  );
  _duplicates(
    issues,
    semanticsNamespaces,
    FormalSystemConfigurationIssueCode.duplicateSemanticsNamespace,
  );
  _duplicates(
    issues,
    exampleNamespaces,
    FormalSystemConfigurationIssueCode.duplicateExampleNamespace,
  );
  _duplicates(
    issues,
    sessionNamespaces,
    FormalSystemConfigurationIssueCode.duplicateSessionNamespace,
  );
  return issues..sort();
}

void _validateNamespace(
  List<FormalSystemConfigurationIssue> issues,
  String namespace,
  String owner,
) {
  if (namespace.trim().isEmpty) {
    issues.add(FormalSystemConfigurationIssue(
      code: FormalSystemConfigurationIssueCode.invalidIdentifier,
      value: namespace,
      owners: [owner],
    ));
  }
}

void _record(Map<String, List<String>> values, String value, String owner) {
  values.putIfAbsent(value, () => []).add(owner);
}

void _duplicates(
  List<FormalSystemConfigurationIssue> issues,
  Map<String, List<String>> values,
  FormalSystemConfigurationIssueCode code,
) {
  for (final entry in values.entries) {
    if (entry.value.length < 2) continue;
    issues.add(FormalSystemConfigurationIssue(
      code: code,
      value: entry.key,
      owners: entry.value,
    ));
  }
}
