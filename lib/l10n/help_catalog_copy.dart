import '../core/models/help_catalog.dart';
import '../core/models/help_content_block.dart';

export '../core/models/help_content_block.dart';

class HelpNodeCopy {
  HelpNodeCopy({
    required this.title,
    this.body = '',
    List<String> keywords = const [],
    List<HelpContentBlock> blocks = const [],
  }) : keywords = List.unmodifiable(keywords),
       blocks = _freezeBlocks(body, blocks);

  final String title;
  final String body;
  final List<String> keywords;
  final List<HelpContentBlock> blocks;

  Iterable<String> get searchableTextSegments sync* {
    yield body;
    for (final block in blocks) {
      yield* block.textSegments;
    }
  }

  static List<HelpContentBlock> _freezeBlocks(
    String body,
    List<HelpContentBlock> blocks,
  ) {
    if (blocks.isEmpty) return const [];

    final snapshot = List<HelpContentBlock>.of(blocks);
    return List.unmodifiable([
      if (body.trim().isNotEmpty &&
          !snapshot.any((block) => block is HelpParagraphBlock))
        HelpParagraphBlock(body),
      ...snapshot,
    ]);
  }
}

class HelpCatalogCopy {
  HelpCatalogCopy(Map<String, HelpNodeCopy> entries)
    : entries = Map.unmodifiable(entries);

  final Map<String, HelpNodeCopy> entries;

  HelpNodeCopy? operator [](String id) => entries[id];

  bool contains(String id) => entries.containsKey(id);
}

HelpCatalogCopy selectHelpCatalogCopy({
  required String localeName,
  required HelpCatalogCopy english,
  required HelpCatalogCopy portuguese,
}) {
  return localeName.startsWith('pt') ? portuguese : english;
}

extension HelpCatalogCopyValidation on HelpCatalog {
  bool hasCompleteHelpCopy(HelpCatalogCopy copy, String id) {
    final node = nodeById(id);
    final localized = copy[id];
    if (node == null || localized == null) return false;
    if (localized.title.trim().isEmpty) return false;
    if (node is! HelpTopicDefinition) return true;
    if (localized.body.trim().isEmpty ||
        localized.keywords.isEmpty ||
        localized.keywords.any((keyword) => keyword.trim().isEmpty)) {
      return false;
    }
    if (!_blocksAreValid(localized.blocks)) return false;
    if (node.contentKind == HelpTopicContentKind.structuredText &&
        !_hasRequiredStructuredBlocks(localized.blocks)) {
      return false;
    }
    return true;
  }

  List<String> validateCopy(HelpCatalogCopy copy) {
    final messages = <String>[];
    final catalogNodes = {for (final node in nodes) node.id: node};

    for (final node in catalogNodes.values) {
      final localized = copy[node.id];
      if (localized == null) {
        messages.add('missing localized entry: ${node.id}');
        continue;
      }
      if (!hasCompleteHelpCopy(copy, node.id)) {
        if (node is HelpTopicDefinition &&
            node.contentKind == HelpTopicContentKind.structuredText &&
            localized.title.trim().isNotEmpty &&
            localized.body.trim().isNotEmpty &&
            localized.keywords.isNotEmpty &&
            localized.keywords.every((keyword) => keyword.trim().isNotEmpty) &&
            _blocksAreValid(localized.blocks)) {
          messages.add('incomplete structured copy: ${node.id}');
        } else {
          messages.add('incomplete localized entry: ${node.id}');
        }
      }
    }

    for (final id in copy.entries.keys) {
      if (!catalogNodes.containsKey(id)) {
        messages.add('orphaned localized entry: $id');
      }
    }

    return messages;
  }

  bool _blocksAreValid(List<HelpContentBlock> blocks) {
    for (final block in blocks) {
      switch (block) {
        case HelpParagraphBlock(:final text):
        case HelpHeadingBlock(:final text):
        case HelpCalloutBlock(:final text):
          if (text.trim().isEmpty) return false;
        case HelpOrderedStepsBlock(:final steps):
          if (steps.isEmpty || steps.any((step) => step.trim().isEmpty)) {
            return false;
          }
      }
    }
    return true;
  }

  bool _hasRequiredStructuredBlocks(List<HelpContentBlock> blocks) {
    return blocks.any((block) => block is HelpParagraphBlock) &&
        blocks.any((block) => block is HelpHeadingBlock) &&
        blocks.any((block) => block is HelpOrderedStepsBlock) &&
        blocks.any((block) => block is HelpCalloutBlock);
  }
}
