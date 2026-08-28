import 'conversion_capability.dart';
import 'document_format.dart';
import 'document_schema.dart';
import 'formal_system_capabilities.dart';
import 'formal_system_ids.dart';

enum FormalSystemCategory { automaton, grammar, expression, learning }

final class FormalSystemDescriptor {
  FormalSystemDescriptor({
    required this.key,
    required this.schema,
    required this.route,
    required this.category,
    required this.localizationNamespace,
    required this.semanticsNamespace,
    required this.capabilities,
    Iterable<DocumentFormatSupport> formats = const [],
    Iterable<ConversionEdge> conversions = const [],
  })  : formats = List<DocumentFormatSupport>.unmodifiable(formats),
        conversions = List<ConversionEdge>.unmodifiable(conversions);

  final FormalSystemKey key;
  final DocumentSchemaDescriptor schema;
  final WorkspaceRouteId route;
  final FormalSystemCategory category;
  final CapabilityNamespaceId localizationNamespace;
  final CapabilityNamespaceId semanticsNamespace;
  final FormalSystemCapabilities capabilities;
  final List<DocumentFormatSupport> formats;
  final List<ConversionEdge> conversions;

  DocumentFormatSupport? formatSupport(DocumentFormatId id) {
    for (final support in formats) {
      if (support.formatId == id) return support;
    }
    return null;
  }
}
