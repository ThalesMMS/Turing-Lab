final class TMBlockExampleContentCopy {
  const TMBlockExampleContentCopy({
    required this.title,
    required this.summary,
    required this.learningObjective,
    required this.limitation,
    required this.accessibleDescription,
  });

  final String title;
  final String summary;
  final String learningObjective;
  final String limitation;
  final String accessibleDescription;

  String get semanticLabel => [
    title,
    summary,
    learningObjective,
    limitation,
    accessibleDescription,
  ].join(' ');
}

abstract final class TMBlockExampleContentCopies {
  static const id = 'tm-building-blocks-composition';

  static final _entries = List<_TMBlockExampleContentEntry>.unmodifiable([
    _entry(
      id: 'tm-building-blocks-composition',
      en: const TMBlockExampleContentCopy(
        title: 'Reusable two-tape building blocks',
        summary:
            'A shared-tape project combines scan, rewind, copy, compare, and nested composition blocks.',
        learningObjective:
            'Trace how a state invokes a named submachine and how nested blocks continue on the same two tapes.',
        limitation:
            'The project keeps native building-block references. Formats without this structure may require inlining and can lose extension metadata.',
        accessibleDescription:
            'The root machine invokes a composition block. That block calls scan and then rewind; separate copy and compare definitions demonstrate other reusable operations on the same two tapes.',
      ),
      pt: const TMBlockExampleContentCopy(
        title: 'Blocos reutilizáveis para MT de duas fitas',
        summary:
            'Um projeto com fitas compartilhadas combina blocos de varredura, retorno, cópia, comparação e composição aninhada.',
        learningObjective:
            'Acompanhe como um estado chama uma submáquina nomeada e como blocos aninhados continuam nas mesmas duas fitas.',
        limitation:
            'O projeto mantém referências nativas aos blocos. Formatos sem essa estrutura podem exigir expansão e perder metadados de extensão.',
        accessibleDescription:
            'A máquina raiz chama um bloco de composição. Esse bloco executa a varredura e depois o retorno; definições separadas de cópia e comparação demonstram outras operações reutilizáveis nas mesmas duas fitas.',
      ),
    ),
  ]);

  static TMBlockExampleContentCopy resolve({
    required String id,
    required String languageCode,
  }) {
    final entry = _entries.firstWhere(
      (candidate) => candidate.id == id,
      orElse: () => throw StateError('tm-block-example.copy-id'),
    );
    return languageCode.toLowerCase().startsWith('pt') ? entry.pt : entry.en;
  }
}

final class _TMBlockExampleContentEntry {
  const _TMBlockExampleContentEntry({
    required this.id,
    required this.en,
    required this.pt,
  });

  final String id;
  final TMBlockExampleContentCopy en;
  final TMBlockExampleContentCopy pt;
}

_TMBlockExampleContentEntry _entry({
  required String id,
  required TMBlockExampleContentCopy en,
  required TMBlockExampleContentCopy pt,
}) => _TMBlockExampleContentEntry(id: id, en: en, pt: pt);
