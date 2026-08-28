import '../../core/formal_systems/formal_systems.dart';
import 'moore_jflap_document_codec.dart';
import 'moore_json_document_codec.dart';

abstract final class MooreDocumentCodecs {
  static const jflap = MooreJflapDocumentCodec();

  static final json = MooreJsonDocumentCodec();

  static List<DocumentCodecCapability<Object>> get all => [jflap, json];
}
