enum AnnotationStyleRole { note, information, warning, question, todo }

enum AnnotationTargetType {
  canvas,
  state,
  transition,
  production,
  tableCell,
}

final class AnnotationAttachment {
  const AnnotationAttachment({
    required this.type,
    required this.targetId,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  final AnnotationTargetType type;
  final String targetId;
  final double offsetX;
  final double offsetY;

  List<String> validate() => [
        if (type == AnnotationTargetType.canvas)
          'Canvas annotations must not use an attachment.',
        if (targetId.trim().isEmpty) 'Attachment target id must not be empty.',
        if (!offsetX.isFinite || !offsetY.isFinite)
          'Attachment offset must be finite.',
      ];

  AnnotationAttachment copyWith({
    AnnotationTargetType? type,
    String? targetId,
    double? offsetX,
    double? offsetY,
  }) =>
      AnnotationAttachment(
        type: type ?? this.type,
        targetId: targetId ?? this.targetId,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
      );

  Map<String, Object?> toJson() => {
        'type': type.name,
        'targetId': targetId,
        'offset': {'x': offsetX, 'y': offsetY},
      };

  factory AnnotationAttachment.fromJson(Map<String, dynamic> json) {
    final offset = _stringMap(json['offset'], 'Attachment offset');
    return AnnotationAttachment(
      type: AnnotationTargetType.values.byName(json['type'] as String),
      targetId: json['targetId'] as String,
      offsetX: _finiteDouble(offset['x'], 'Attachment offset x'),
      offsetY: _finiteDouble(offset['y'], 'Attachment offset y'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AnnotationAttachment &&
      other.type == type &&
      other.targetId == targetId &&
      other.offsetX == offsetX &&
      other.offsetY == offsetY;

  @override
  int get hashCode => Object.hash(type, targetId, offsetX, offsetY);
}

final class DocumentAnnotation {
  static const int schemaVersion = 1;
  static const int maximumTextLength = 20000;
  static const double defaultWidth = 240;
  static const double defaultHeight = 140;
  static const double minimumWidth = 120;
  static const double minimumHeight = 56;
  static const double maximumExtent = 4096;
  static const Object _unset = Object();

  DocumentAnnotation({
    required this.id,
    required this.documentId,
    required this.documentRevision,
    required String text,
    required this.x,
    required this.y,
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.attachment,
    this.styleRole = AnnotationStyleRole.note,
    this.zIndex = 0,
    this.collapsed = false,
    required this.createdAt,
    required this.updatedAt,
    this.authorLabel,
  }) : text = sanitizeAnnotationText(text) {
    final issues = validate();
    if (issues.isNotEmpty) throw ArgumentError(issues.join('\n'));
  }

  final String id;
  final String documentId;
  final String documentRevision;
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final AnnotationAttachment? attachment;
  final AnnotationStyleRole styleRole;
  final int zIndex;
  final bool collapsed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorLabel;

  List<String> validate() => [
        if (id.trim().isEmpty) 'Annotation id must not be empty.',
        if (documentId.trim().isEmpty) 'Document id must not be empty.',
        if (documentRevision.trim().isEmpty)
          'Document revision must not be empty.',
        if (text.length > maximumTextLength)
          'Annotation text exceeds $maximumTextLength characters.',
        if (![x, y, width, height].every((value) => value.isFinite))
          'Annotation geometry must be finite.',
        if (width < minimumWidth || width > maximumExtent)
          'Annotation width must be between $minimumWidth and $maximumExtent.',
        if (height < minimumHeight || height > maximumExtent)
          'Annotation height must be between $minimumHeight and $maximumExtent.',
        if (zIndex < 0) 'Annotation z-index must not be negative.',
        if (updatedAt.isBefore(createdAt))
          'Annotation update time must not precede creation time.',
        if (authorLabel?.trim().isEmpty ?? false)
          'Author label must be absent or non-empty.',
        if (attachment != null) ...attachment!.validate(),
      ];

  DocumentAnnotation copyWith({
    String? id,
    String? documentId,
    String? documentRevision,
    String? text,
    double? x,
    double? y,
    double? width,
    double? height,
    Object? attachment = _unset,
    AnnotationStyleRole? styleRole,
    int? zIndex,
    bool? collapsed,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? authorLabel = _unset,
  }) =>
      DocumentAnnotation(
        id: id ?? this.id,
        documentId: documentId ?? this.documentId,
        documentRevision: documentRevision ?? this.documentRevision,
        text: text ?? this.text,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        attachment: attachment == _unset
            ? this.attachment
            : attachment as AnnotationAttachment?,
        styleRole: styleRole ?? this.styleRole,
        zIndex: zIndex ?? this.zIndex,
        collapsed: collapsed ?? this.collapsed,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        authorLabel:
            authorLabel == _unset ? this.authorLabel : authorLabel as String?,
      );

  DocumentAnnotation resized({required double width, required double height}) =>
      copyWith(
        width: width.clamp(minimumWidth, maximumExtent).toDouble(),
        height: height.clamp(minimumHeight, maximumExtent).toDouble(),
      );

  Map<String, Object?> toJson() => {
        'version': schemaVersion,
        'id': id,
        'documentId': documentId,
        'documentRevision': documentRevision,
        'text': text,
        'position': {'x': x, 'y': y},
        'size': {'width': width, 'height': height},
        if (attachment != null) 'attachment': attachment!.toJson(),
        'styleRole': styleRole.name,
        'zIndex': zIndex,
        'collapsed': collapsed,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        if (authorLabel != null) 'authorLabel': authorLabel,
      };

  factory DocumentAnnotation.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != schemaVersion) {
      throw FormatException('Unsupported annotation version $version.');
    }
    final position = _stringMap(json['position'], 'Annotation position');
    final size = _stringMap(json['size'], 'Annotation size');
    final attachment = json['attachment'];
    return DocumentAnnotation(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      documentRevision: json['documentRevision'] as String,
      text: json['text'] as String,
      x: _finiteDouble(position['x'], 'Annotation x'),
      y: _finiteDouble(position['y'], 'Annotation y'),
      width: _finiteDouble(size['width'], 'Annotation width'),
      height: _finiteDouble(size['height'], 'Annotation height'),
      attachment: attachment == null
          ? null
          : AnnotationAttachment.fromJson(
              _stringMap(attachment, 'Annotation attachment'),
            ),
      styleRole: AnnotationStyleRole.values.byName(json['styleRole'] as String),
      zIndex: json['zIndex'] as int,
      collapsed: json['collapsed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      authorLabel: json['authorLabel'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DocumentAnnotation &&
      other.id == id &&
      other.documentId == documentId &&
      other.documentRevision == documentRevision &&
      other.text == text &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.attachment == attachment &&
      other.styleRole == styleRole &&
      other.zIndex == zIndex &&
      other.collapsed == collapsed &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.authorLabel == authorLabel;

  @override
  int get hashCode => Object.hashAll([
        id,
        documentId,
        documentRevision,
        text,
        x,
        y,
        width,
        height,
        attachment,
        styleRole,
        zIndex,
        collapsed,
        createdAt,
        updatedAt,
        authorLabel,
      ]);
}

String sanitizeAnnotationText(String source) {
  final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final buffer = StringBuffer();
  for (final rune in normalized.runes) {
    if (rune == 0x09 || rune == 0x0a || rune >= 0x20) {
      buffer.writeCharCode(rune);
    }
  }
  final text = buffer.toString();
  if (text.length > DocumentAnnotation.maximumTextLength) {
    throw ArgumentError(
      'Annotation text exceeds ${DocumentAnnotation.maximumTextLength} characters.',
    );
  }
  return text;
}

Map<String, dynamic> _stringMap(Object? value, String label) {
  if (value is! Map) throw FormatException('$label must be an object.');
  try {
    return value.cast<String, dynamic>();
  } on TypeError {
    throw FormatException('$label must use string keys.');
  }
}

double _finiteDouble(Object? value, String label) {
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('$label must be finite.');
  }
  return value.toDouble();
}
