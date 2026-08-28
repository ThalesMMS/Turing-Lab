import '../formal_systems/document_format.dart';
import '../formal_systems/formal_system_ids.dart';

final class DocumentSchemaRange {
  factory DocumentSchemaRange({required int minimum, required int maximum}) {
    if (minimum <= 0 || maximum < minimum) {
      throw ArgumentError.value(
        {'minimum': minimum, 'maximum': maximum},
        'range',
        'interop.descriptor.invalid-schema-range',
      );
    }
    return DocumentSchemaRange._(minimum, maximum);
  }

  const DocumentSchemaRange._(this.minimum, this.maximum);

  final int minimum;
  final int maximum;

  bool contains(int version) => version >= minimum && version <= maximum;

  bool overlaps(DocumentSchemaRange other) =>
      minimum <= other.maximum && other.minimum <= maximum;
}

final class CodecSemanticCapabilityId {
  factory CodecSemanticCapabilityId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'interop.descriptor.empty-semantic-capability-id',
      );
    }
    return CodecSemanticCapabilityId._(value);
  }

  const CodecSemanticCapabilityId._(this.value);

  final String value;

  static const stateIds = CodecSemanticCapabilityId._('state-ids');
  static const stateNames = CodecSemanticCapabilityId._('state-names');
  static const statePositions = CodecSemanticCapabilityId._('state-positions');
  static const stateLabels = CodecSemanticCapabilityId._('state-labels');
  static const initialStates = CodecSemanticCapabilityId._('initial-states');
  static const acceptingStates = CodecSemanticCapabilityId._(
    'accepting-states',
  );
  static const transitionLabels = CodecSemanticCapabilityId._(
    'transition-labels',
  );
  static const tokenVectors = CodecSemanticCapabilityId._('token-vectors');
  static const transitionOutputs = CodecSemanticCapabilityId._(
    'transition-outputs',
  );
  static const stateOutputs = CodecSemanticCapabilityId._('state-outputs');
  static const stackOperations = CodecSemanticCapabilityId._(
    'stack-operations',
  );
  static const tapeOperations = CodecSemanticCapabilityId._('tape-operations');
  static const buildingBlocks = CodecSemanticCapabilityId._('building-blocks');
  static const notes = CodecSemanticCapabilityId._('notes');
  static const extensions = CodecSemanticCapabilityId._('extensions');

  @override
  bool operator ==(Object other) =>
      other is CodecSemanticCapabilityId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class CodecSecurityLimits {
  factory CodecSecurityLimits({
    int maximumBytes = 4 * 1024 * 1024,
    int maximumDepth = 64,
    int maximumElements = 100000,
    int maximumCollectionEntries = 100000,
  }) {
    final values = [
      maximumBytes,
      maximumDepth,
      maximumElements,
      maximumCollectionEntries,
    ];
    if (values.any((value) => value <= 0)) {
      throw ArgumentError('Every codec security limit must be positive.');
    }
    return CodecSecurityLimits._(
      maximumBytes,
      maximumDepth,
      maximumElements,
      maximumCollectionEntries,
    );
  }

  const CodecSecurityLimits._(
    this.maximumBytes,
    this.maximumDepth,
    this.maximumElements,
    this.maximumCollectionEntries,
  );

  final int maximumBytes;
  final int maximumDepth;
  final int maximumElements;
  final int maximumCollectionEntries;
}

final class CodecDescriptor {
  CodecDescriptor({
    required this.codecId,
    required this.namespace,
    required this.systemKey,
    required this.formatId,
    required this.schemas,
    required Set<DocumentFormatDirection> directions,
    required this.priority,
    required this.compatibilityOwner,
    required List<String> canonicalFixtures,
    required Set<CodecSemanticCapabilityId> semanticCapabilities,
    required Set<String> knownUnsupportedFields,
    CodecSecurityLimits? securityLimits,
  }) : directions = Set<DocumentFormatDirection>.unmodifiable(directions),
       canonicalFixtures = List<String>.unmodifiable(canonicalFixtures),
       semanticCapabilities = Set<CodecSemanticCapabilityId>.unmodifiable(
         semanticCapabilities,
       ),
       knownUnsupportedFields = Set<String>.unmodifiable(
         knownUnsupportedFields,
       ),
       securityLimits = securityLimits ?? CodecSecurityLimits() {
    if (codecId.value.trim().isEmpty || namespace.value.trim().isEmpty) {
      throw ArgumentError('Codec id and namespace must not be empty.');
    }
    if (directions.isEmpty) {
      throw ArgumentError('A codec must declare at least one direction.');
    }
    if (compatibilityOwner.trim().isEmpty) {
      throw ArgumentError('Codec compatibility owner must not be empty.');
    }
    if (canonicalFixtures.isEmpty ||
        canonicalFixtures.any((path) => path.trim().isEmpty)) {
      throw ArgumentError('Codec canonical fixture paths must not be empty.');
    }
  }

  final DocumentCodecId codecId;
  final CapabilityNamespaceId namespace;
  final FormalSystemKey systemKey;
  final DocumentFormatId formatId;
  final DocumentSchemaRange schemas;
  final Set<DocumentFormatDirection> directions;
  final int priority;
  final String compatibilityOwner;
  final List<String> canonicalFixtures;
  final Set<CodecSemanticCapabilityId> semanticCapabilities;
  final Set<String> knownUnsupportedFields;
  final CodecSecurityLimits securityLimits;
}

final class CodecSniffResult {
  factory CodecSniffResult({
    required int confidence,
    FormalSystemKey? detectedSystem,
    int? detectedSchemaVersion,
  }) {
    if (confidence < 0 || confidence > 100) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'interop.descriptor.invalid-sniff-confidence',
      );
    }
    if (detectedSchemaVersion != null && detectedSchemaVersion <= 0) {
      throw ArgumentError.value(
        detectedSchemaVersion,
        'detectedSchemaVersion',
        'interop.descriptor.invalid-sniff-schema-version',
      );
    }
    return CodecSniffResult._(
      confidence,
      detectedSystem,
      detectedSchemaVersion,
    );
  }

  const CodecSniffResult._(
    this.confidence,
    this.detectedSystem,
    this.detectedSchemaVersion,
  );

  static const none = CodecSniffResult._(0, null, null);

  final int confidence;
  final FormalSystemKey? detectedSystem;
  final int? detectedSchemaVersion;
}
