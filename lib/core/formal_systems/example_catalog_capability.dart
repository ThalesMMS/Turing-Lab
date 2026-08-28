import 'formal_system_ids.dart';
import '../models/asset_example.dart';

abstract interface class ExampleCatalogCapability<TDocument extends Object> {
  CapabilityNamespaceId get namespace;

  Future<List<AssetExample<TDocument>>> loadExamples();
}
