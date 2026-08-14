//
//  help_content_model.dart
//  Turing Lab
//
//  Estrutura leve que representa o conteúdo de ajuda contextual do aplicativo,
//  incluindo tooltips, painéis explicativos, conceitos de teoria de autômatos
//  e atalhos de teclado. Permite busca por palavras-chave, categorização e
//  navegação entre conceitos relacionados para apoiar estudantes durante o uso.
//
//  Thales Matheus Mendonça Santos - January 2026
//
/// Model representing contextual help content for the application.
class HelpContentModel {
  /// Unique identifier for this help content item.
  final String id;

  /// Display title for the help content.
  final String title;

  /// Main body content with explanation or instructions.
  final String content;

  /// Category for grouping help items (e.g., 'canvas', 'automata', 'shortcuts').
  final String category;

  /// Keywords for search functionality.
  final List<String> keywords;

  /// Related concept IDs for navigation between help items.
  final List<String> relatedConcepts;

  /// Icon identifier for visual representation (e.g., 'help', 'info', 'keyboard').
  final String icon;

  const HelpContentModel({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'general',
    this.keywords = const [],
    this.relatedConcepts = const [],
    this.icon = 'help',
  });

  /// Creates a new [HelpContentModel] with updated values.
  HelpContentModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    List<String>? keywords,
    List<String>? relatedConcepts,
    String? icon,
  }) {
    return HelpContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      relatedConcepts: relatedConcepts ?? this.relatedConcepts,
      icon: icon ?? this.icon,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is HelpContentModel &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.category == category &&
        _listEquals(other.keywords, keywords) &&
        _listEquals(other.relatedConcepts, relatedConcepts) &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        content,
        category,
        Object.hashAll(keywords),
        Object.hashAll(relatedConcepts),
        icon,
      );

  /// Helper method for comparing lists in equality check.
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
