sealed class HelpNodeDefinition {
  HelpNodeDefinition({required this.id, required this.icon});

  final String id;
  final String icon;
}

sealed class HelpGroupDefinition extends HelpNodeDefinition {
  HelpGroupDefinition({
    required super.id,
    required super.icon,
    required List<HelpNodeDefinition> children,
  }) : children = List.unmodifiable(children);

  final List<HelpNodeDefinition> children;
}

final class HelpCategoryDefinition extends HelpGroupDefinition {
  HelpCategoryDefinition({
    required super.id,
    required super.icon,
    required super.children,
  });
}

final class HelpSubsectionDefinition extends HelpGroupDefinition {
  HelpSubsectionDefinition({
    required super.id,
    required super.icon,
    required super.children,
  });
}

enum HelpTopicContentKind { text, structuredText, aboutAndLicenses }

final class HelpTopicDefinition extends HelpNodeDefinition {
  HelpTopicDefinition({
    required super.id,
    required super.icon,
    List<String> relatedTopicIds = const [],
    this.contentKind = HelpTopicContentKind.text,
  }) : relatedTopicIds = List.unmodifiable(relatedTopicIds);

  HelpTopicDefinition.structured({
    required super.id,
    required super.icon,
    List<String> relatedTopicIds = const [],
  })  : relatedTopicIds = List.unmodifiable(relatedTopicIds),
        contentKind = HelpTopicContentKind.structuredText;

  final List<String> relatedTopicIds;
  final HelpTopicContentKind contentKind;
}

final class HelpTopicPath {
  HelpTopicPath(
      {required List<HelpGroupDefinition> ancestors, required this.topic})
      : ancestors = List.unmodifiable(ancestors);

  final List<HelpGroupDefinition> ancestors;
  final HelpTopicDefinition topic;

  List<String> get ancestorIds =>
      ancestors.map((ancestor) => ancestor.id).toList();
}

final class HelpCatalog {
  HelpCatalog({required List<HelpCategoryDefinition> roots})
      : roots = List.unmodifiable(roots);

  final List<HelpCategoryDefinition> roots;

  static final Expando<Map<String, HelpNodeDefinition>> _indexCache =
      Expando<Map<String, HelpNodeDefinition>>('helpCatalogIndex');

  Iterable<HelpNodeDefinition> get nodes sync* {
    for (final root in roots) {
      yield* _flatten(root);
    }
  }

  HelpNodeDefinition? nodeById(String id) {
    final index = _indexCache[this] ??= {
      for (final node in nodes) node.id: node,
    };
    return index[id];
  }

  Iterable<String> get topicIds =>
      nodes.whereType<HelpTopicDefinition>().map((topic) => topic.id);

  HelpTopicPath? pathForTopic(String topicId) {
    for (final root in roots) {
      final path = _findTopic(root, topicId, const []);
      if (path != null) return path;
    }
    return null;
  }

  List<String> validateStructure() {
    final messages = <String>[];
    final seen = <String>{};
    final rootCategories = Set<HelpCategoryDefinition>.identity()
      ..addAll(roots);

    for (final node in nodes) {
      if (node case final HelpCategoryDefinition category
          when !rootCategories.contains(category)) {
        messages.add('category nested below a category: ${category.id}');
      }
      if (!seen.add(node.id)) {
        messages.add('duplicate node id: ${node.id}');
      }
    }

    for (final topic in nodes.whereType<HelpTopicDefinition>()) {
      for (final relatedId in topic.relatedTopicIds) {
        if (nodeById(relatedId) is! HelpTopicDefinition) {
          messages.add(
            'topic ${topic.id} references missing related topic: $relatedId',
          );
        }
      }
    }
    return messages;
  }

  static Iterable<HelpNodeDefinition> _flatten(HelpNodeDefinition node) sync* {
    yield node;
    if (node case final HelpGroupDefinition group) {
      for (final child in group.children) {
        yield* _flatten(child);
      }
    }
  }

  static HelpTopicPath? _findTopic(
    HelpNodeDefinition node,
    String topicId,
    List<HelpGroupDefinition> ancestors,
  ) {
    if (node case final HelpTopicDefinition topic) {
      return topic.id == topicId
          ? HelpTopicPath(ancestors: ancestors, topic: topic)
          : null;
    }
    if (node case final HelpGroupDefinition group) {
      final nextAncestors = [...ancestors, group];
      for (final child in group.children) {
        final path = _findTopic(child, topicId, nextAncestors);
        if (path != null) return path;
      }
    }
    return null;
  }
}
