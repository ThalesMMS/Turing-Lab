import 'conversion_capability.dart';
import 'document_codec_capability.dart';
import 'example_catalog_capability.dart';
import 'formal_system_descriptor.dart';
import 'session_capability.dart';

abstract interface class FormalSystemModule<TDocument extends Object> {
  FormalSystemDescriptor get descriptor;

  List<DocumentCodecCapability<TDocument>> get codecs;

  List<ConversionCapability<TDocument, Object>> get conversions;

  ExampleCatalogCapability<TDocument>? get examples;

  SessionCapability<TDocument>? get session;
}

final class DescriptorFormalSystemModule implements FormalSystemModule<Object> {
  const DescriptorFormalSystemModule(this.descriptor);

  @override
  final FormalSystemDescriptor descriptor;

  @override
  List<DocumentCodecCapability<Object>> get codecs => const [];

  @override
  List<ConversionCapability<Object, Object>> get conversions => const [];

  @override
  ExampleCatalogCapability<Object>? get examples => null;

  @override
  SessionCapability<Object>? get session => null;
}
