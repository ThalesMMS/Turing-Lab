import '../interoperability/codec_descriptor.dart';
import '../interoperability/codec_outcome.dart';
import '../interoperability/codec_source.dart';

abstract interface class DocumentCodecCapability<TDocument extends Object> {
  CodecDescriptor get descriptor;

  CodecSniffResult sniff(DocumentPayload payload);

  CodecOutcome<InteroperableDocument<TDocument>> decode(
    DocumentPayload payload,
  );

  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<TDocument> document, {
    String? filename,
  });
}
