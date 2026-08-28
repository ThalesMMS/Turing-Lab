//
//  examples_asset_data_source.dart
//  Turing Lab
//
//  Provides typed examples from assets, combining category metadata
//  with converters for the current models.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../converters/asset_example_converters.dart';
import '../../core/models/asset_example.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/regex_preset.dart';
import '../../core/models/tm.dart';
import '../../core/result.dart';
import '../../core/repositories/examples_repository.dart';
import '../tm/tm_block_example_catalog.dart';

export '../../core/models/asset_example.dart'
    show AssetExample, DifficultyLevel, ExampleCategory, ExampleComplexityLevel;

/// Enhanced data source for loading example automatons from assets (Examples v1)
class ExamplesAssetDataSource implements ExamplesRepository {
  ExamplesAssetDataSource({FormalSystemRegistry? registry})
    : _registry = registry ?? FormalSystemRegistry.defaultRegistry;

  final FormalSystemRegistry _registry;

  static const _systemByCategory = {
    ExampleCategory.dfa: DefaultFormalSystemIds.fsa,
    ExampleCategory.nfa: DefaultFormalSystemIds.fsa,
    ExampleCategory.cfg: DefaultFormalSystemIds.grammar,
    ExampleCategory.pda: DefaultFormalSystemIds.pda,
    ExampleCategory.tm: DefaultFormalSystemIds.tm,
    ExampleCategory.regex: DefaultFormalSystemIds.regex,
  };

  static const Map<String, _ExampleMetadata> _exampleMetadata = {
    // DFA Examples - Basic Concepts
    'AFD - Termina com A': _ExampleMetadata(
      fileName: 'afd_ends_with_a.json',
      category: ExampleCategory.dfa,
      difficulty: DifficultyLevel.easy,
      description:
          'DFA que reconhece palavras terminando com "a". Demonstra conceitos básicos de estados finais.',
      tags: ['dfa', 'basic', 'patterns', 'ending'],
      estimatedComplexity: ExampleComplexityLevel.low,
    ),
    'AFD - Binário divisível por 3': _ExampleMetadata(
      fileName: 'afd_binary_divisible_by_3.json',
      category: ExampleCategory.dfa,
      difficulty: DifficultyLevel.medium,
      description:
          'DFA que reconhece números binários divisíveis por 3. Usa aritmética modular.',
      tags: ['dfa', 'modular', 'binary', 'division'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'AFD - Paridade AB': _ExampleMetadata(
      fileName: 'afd_parity_AB.json',
      category: ExampleCategory.dfa,
      difficulty: DifficultyLevel.medium,
      description:
          'DFA que verifica se há número par de "a"s e "b"s. Demonstra contagem simultânea.',
      tags: ['dfa', 'parity', 'counting', 'multiple-counters'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'AFD - Contém AB': _ExampleMetadata(
      fileName: 'afd_contains_ab.json',
      category: ExampleCategory.dfa,
      difficulty: DifficultyLevel.easy,
      description:
          'DFA que reconhece palavras que contêm a sequência "ab" em qualquer posição.',
      tags: ['dfa', 'substring', 'contains', 'patterns'],
      estimatedComplexity: ExampleComplexityLevel.low,
    ),

    // NFA Examples - Non-deterministic concepts
    'AFNλ - A ou AB': _ExampleMetadata(
      fileName: 'afn_lambda_a_or_ab.json',
      category: ExampleCategory.nfa,
      difficulty: DifficultyLevel.medium,
      description:
          'NFA com ramificação ε para explorar "ab" e transição explícita de "a" para aceitação imediata.',
      tags: ['nfa', 'epsilon', 'choice', 'non-deterministic'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),

    // Grammar Examples - Context-Free concepts
    'GLC - Palíndromo': _ExampleMetadata(
      fileName: 'glc_palindrome.json',
      category: ExampleCategory.cfg,
      difficulty: DifficultyLevel.hard,
      description:
          'Gramática livre de contexto para palíndromos. Demonstra recursão.',
      tags: ['cfg', 'palindrome', 'recursion', 'context-free'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'GLC - Parênteses balanceados': _ExampleMetadata(
      fileName: 'glc_balanced_parentheses.json',
      category: ExampleCategory.cfg,
      difficulty: DifficultyLevel.medium,
      description:
          'GLC que gera strings de parênteses balanceados. Simula comportamento de pilha.',
      tags: ['cfg', 'parentheses', 'balanced', 'stack'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'GLC - a^n b^n': _ExampleMetadata(
      fileName: 'glc_anbn.json',
      category: ExampleCategory.cfg,
      difficulty: DifficultyLevel.medium,
      description:
          'GLC que gera a linguagem a^n b^n com a mesma quantidade de símbolos a e b.',
      tags: ['cfg', 'anbn', 'counting', 'recursion'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'GLC - Zeros em quantidade par': _ExampleMetadata(
      fileName: 'glc_even_zeros.json',
      category: ExampleCategory.cfg,
      difficulty: DifficultyLevel.easy,
      description:
          'Gramática regular que gera cadeias binárias com quantidade par de zeros.',
      tags: ['cfg', 'regular', 'binary', 'parity'],
      estimatedComplexity: ExampleComplexityLevel.low,
    ),
    'GLC - Expressões aritméticas': _ExampleMetadata(
      fileName: 'glc_arithmetic_expressions.json',
      category: ExampleCategory.cfg,
      difficulty: DifficultyLevel.hard,
      description:
          'GLC clássica para expressões com soma, multiplicação, parênteses e identificadores.',
      tags: ['cfg', 'arithmetic', 'expressions', 'precedence'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),

    // PDA Examples - Pushdown concepts
    'APD - Parênteses Balanceados': _ExampleMetadata(
      fileName: 'apda_balanced_parentheses.json',
      category: ExampleCategory.pda,
      difficulty: DifficultyLevel.medium,
      description:
          'Autômato de pilha que reconhece cadeias de parênteses balanceados usando a pilha para rastrear aberturas pendentes.',
      tags: ['pda', 'parentheses', 'balanced', 'stack'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'APD - a^n b^n': _ExampleMetadata(
      fileName: 'apda_anbn.json',
      category: ExampleCategory.pda,
      difficulty: DifficultyLevel.hard,
      description:
          'Autômato de pilha que reconhece a linguagem a^n b^n ao empilhar símbolos para cada a e desempilhar para cada b.',
      tags: ['pda', 'anbn', 'stack', 'context-free'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'APD - Palíndromo': _ExampleMetadata(
      fileName: 'apda_palindrome.json',
      category: ExampleCategory.pda,
      difficulty: DifficultyLevel.hard,
      description:
          'Autômato de pilha não determinístico que empilha a primeira metade da palavra e desempilha a segunda para validar palíndromos.',
      tags: ['pda', 'palindrome', 'stack', 'non-deterministic', 'mirroring'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'APD - a^n b^2n': _ExampleMetadata(
      fileName: 'apda_anb2n.json',
      category: ExampleCategory.pda,
      difficulty: DifficultyLevel.hard,
      description:
          'Autômato de pilha que reconhece a linguagem a^n b^2n empilhando dois marcadores para cada a.',
      tags: ['pda', 'anb2n', 'stack', 'counting'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'APD - w#reverse(w)': _ExampleMetadata(
      fileName: 'apda_mirrored_separator.json',
      category: ExampleCategory.pda,
      difficulty: DifficultyLevel.medium,
      description:
          'Autômato de pilha determinístico que compara uma palavra com seu reverso após o separador #.',
      tags: ['pda', 'reverse', 'separator', 'deterministic'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),

    // Turing Machine Examples - Computational power
    'MT - a^n b^n': _ExampleMetadata(
      fileName: 'tm_anbn.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.hard,
      description:
          'Máquina de Turing que reconhece a linguagem a^n b^n marcando pares correspondentes de a e b na fita.',
      tags: ['tm', 'anbn', 'language', 'recognition'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'MT - Binário para unário': _ExampleMetadata(
      fileName: 'tm_binary_to_unary.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.hard,
      description:
          'Máquina de Turing que converte números binários para unários.',
      tags: ['tm', 'conversion', 'binary', 'unary'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'MT - Cópia de string': _ExampleMetadata(
      fileName: 'tm_copy_string.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.hard,
      description:
          'Máquina de Turing que copia uma string binária para uma nova região da fita.',
      tags: ['tm', 'copy', 'string', 'tape'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'MT - Incremento binário': _ExampleMetadata(
      fileName: 'tm_increment.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.medium,
      description:
          'Máquina de Turing que incrementa um número binário em uma unidade.',
      tags: ['tm', 'binary', 'increment', 'arithmetic'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'MT - Verificador de palíndromo': _ExampleMetadata(
      fileName: 'tm_palindrome.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.hard,
      description:
          'Máquina de Turing que verifica se uma string binária é um palíndromo.',
      tags: ['tm', 'palindrome', 'binary', 'verification'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'MT multifitas - Cópia em duas fitas': _ExampleMetadata(
      fileName: 'tm_multitape_copy.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.medium,
      description:
          'Copia uma palavra binária da fita de entrada para uma segunda fita em passos atômicos.',
      tags: ['tm', 'multi-tape', 'copy', 'atomic'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'MT multifitas - Comparação': _ExampleMetadata(
      fileName: 'tm_multitape_comparison.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.hard,
      description:
          'Compara as duas partes de uma entrada w#w usando a segunda fita como memória.',
      tags: ['tm', 'multi-tape', 'comparison', 'work-tape'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'MT multifitas - Palíndromo': _ExampleMetadata(
      fileName: 'tm_multitape_palindrome.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.hard,
      description:
          'Compara a entrada de trás para frente com uma cópia percorrida para a direita.',
      tags: ['tm', 'multi-tape', 'palindrome', 'comparison'],
      estimatedComplexity: ExampleComplexityLevel.high,
    ),
    'MT multifitas - Fita de trabalho': _ExampleMetadata(
      fileName: 'tm_multitape_work_tape.json',
      category: ExampleCategory.tm,
      difficulty: DifficultyLevel.medium,
      description:
          'Usa uma segunda fita como contador unário sem alterar a entrada.',
      tags: ['tm', 'multi-tape', 'work-tape', 'unary'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),

    // Regular expression examples
    'Regex - Repetição de A': _ExampleMetadata(
      fileName: 'regex_a_star.json',
      category: ExampleCategory.regex,
      difficulty: DifficultyLevel.easy,
      description: 'Expressão que aceita zero ou mais ocorrências de a.',
      tags: ['regex', 'kleene-star', 'repetition'],
      estimatedComplexity: ExampleComplexityLevel.low,
    ),
    'Regex - Termina com AB': _ExampleMetadata(
      fileName: 'regex_ends_with_ab.json',
      category: ExampleCategory.regex,
      difficulty: DifficultyLevel.medium,
      description: 'Expressão sobre a e b para cadeias que terminam em ab.',
      tags: ['regex', 'suffix', 'union', 'concatenation'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'Regex - Binário iniciado por 0': _ExampleMetadata(
      fileName: 'regex_binary_starts_zero.json',
      category: ExampleCategory.regex,
      difficulty: DifficultyLevel.easy,
      description:
          'Expressão para cadeias binárias não vazias iniciadas por zero.',
      tags: ['regex', 'binary', 'prefix'],
      estimatedComplexity: ExampleComplexityLevel.low,
    ),
    'Regex - Pares AB ou BA': _ExampleMetadata(
      fileName: 'regex_ab_or_ba_pairs.json',
      category: ExampleCategory.regex,
      difficulty: DifficultyLevel.medium,
      description: 'Expressão que repete blocos ab ou ba.',
      tags: ['regex', 'union', 'pairs', 'repetition'],
      estimatedComplexity: ExampleComplexityLevel.medium,
    ),
    'Regex - Blocos de A e B': _ExampleMetadata(
      fileName: 'regex_a_then_b.json',
      category: ExampleCategory.regex,
      difficulty: DifficultyLevel.easy,
      description:
          'Expressão para qualquer quantidade de a seguida por qualquer quantidade de b.',
      tags: ['regex', 'concatenation', 'kleene-star'],
      estimatedComplexity: ExampleComplexityLevel.low,
    ),
  };

  @override
  Future<Result<AssetExample<FSA>>> loadTypedFsaExample(String name) {
    return _loadTypedExample(
      name,
      DefaultFormalSystemIds.fsa,
      convertAssetJsonToFsa,
    );
  }

  @override
  Future<Result<AssetExample<Grammar>>> loadTypedCfgExample(String name) {
    return _loadTypedExample(
      name,
      DefaultFormalSystemIds.grammar,
      convertAssetJsonToGrammar,
    );
  }

  @override
  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name) {
    return _loadTypedExample(
      name,
      DefaultFormalSystemIds.pda,
      convertAssetJsonToPda,
    );
  }

  @override
  Future<Result<AssetExample<TM>>> loadTypedTmExample(String name) async {
    if (name == TMBlockExampleCatalog.exampleName) {
      final examples = await const TMBlockExampleCatalog().loadExamples();
      return Success(examples.single);
    }
    return _loadTypedExample(
      name,
      DefaultFormalSystemIds.tm,
      convertAssetJsonToTm,
    );
  }

  @override
  Future<Result<AssetExample<RegexPreset>>> loadTypedRegexExample(String name) {
    return _loadTypedExample(
      name,
      DefaultFormalSystemIds.regex,
      convertAssetJsonToRegexPreset,
    );
  }

  @override
  Future<ListResult<AssetExample<FSA>>> loadAllTypedFsaExamples() {
    return _loadAllTypedExamples(
      DefaultFormalSystemIds.fsa,
      loadTypedFsaExample,
    );
  }

  @override
  Future<ListResult<AssetExample<Grammar>>> loadAllTypedCfgExamples() {
    return _loadAllTypedExamples(
      DefaultFormalSystemIds.grammar,
      loadTypedCfgExample,
    );
  }

  @override
  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples() {
    return _loadAllTypedExamples(
      DefaultFormalSystemIds.pda,
      loadTypedPdaExample,
    );
  }

  @override
  Future<ListResult<AssetExample<TM>>> loadAllTypedTmExamples() async {
    final bundled = await _loadAllTypedExamples(
      DefaultFormalSystemIds.tm,
      loadTypedTmExample,
    );
    if (bundled.isFailure) return Failure(bundled.error!);
    final blockExamples = await const TMBlockExampleCatalog().loadExamples();
    return Success([...bundled.data!, ...blockExamples]);
  }

  @override
  Future<ListResult<AssetExample<RegexPreset>>> loadAllTypedRegexExamples() {
    return _loadAllTypedExamples(
      DefaultFormalSystemIds.regex,
      loadTypedRegexExample,
    );
  }

  Future<ListResult<AssetExample<T>>> _loadAllTypedExamples<T extends Object>(
    FormalSystemKey systemKey,
    Future<Result<AssetExample<T>>> Function(String name) load,
  ) async {
    final availability = _ensureExamplesAvailable(systemKey);
    if (availability != null) return Failure(availability);
    final examples = <AssetExample<T>>[];

    for (final entry in _exampleMetadata.entries) {
      if (entry.value.systemKey != systemKey) {
        continue;
      }

      final result = await load(entry.key);
      if (result.isFailure) {
        return Failure(result.error!);
      }
      examples.add(result.data!);
    }

    return Success(examples);
  }

  Future<Result<AssetExample<T>>> _loadTypedExample<T extends Object>(
    String lookupKey,
    FormalSystemKey systemKey,
    Result<T> Function(Map<String, dynamic> json, String exampleName) convert,
  ) async {
    final availability = _ensureExamplesAvailable(systemKey);
    if (availability != null) return Failure(availability);
    final legacyEntry = _exampleMetadata.entries
        .where((entry) => entry.key == lookupKey || entry.value.id == lookupKey)
        .firstOrNull;
    final metadata = legacyEntry?.value;
    if (metadata == null) {
      return Failure('Example not found: $lookupKey');
    }
    final displayName = legacyEntry!.key;

    if (metadata.systemKey != systemKey) {
      return Failure(
        'Example "$lookupKey" belongs to ${metadata.category.name.toUpperCase()}, '
        'not ${systemKey.type.value.toUpperCase()}',
      );
    }

    final assetPath = 'assets/examples/${metadata.fileName}';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return Failure(
          'Example $displayName has invalid JSON structure. Expected an object.',
        );
      }

      final conversionResult = convert(decoded, displayName);
      if (conversionResult.isFailure) {
        return Failure(conversionResult.error!);
      }

      return Success(
        AssetExample<T>(
          id: metadata.id,
          name: displayName,
          description: metadata.description,
          category: metadata.category,
          difficultyLevel: metadata.difficulty,
          complexityLevel: metadata.estimatedComplexity,
          tags: metadata.tags,
          payload: conversionResult.data!,
        ),
      );
    } on FlutterError catch (e) {
      final message = e.message;
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $displayName. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $displayName: $message');
    } on PlatformException catch (e) {
      final message = e.message ?? e.toString();
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $displayName. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $displayName: $e');
    } on FormatException catch (e) {
      return Failure('Invalid JSON for example $displayName: ${e.message}');
    } on TypeError catch (e) {
      return Failure('Example $displayName has invalid data: ${e.toString()}');
    }
  }

  /// Loads examples supplied by an operational registry extension module.
  Future<List<AssetExample<Object>>> loadRegisteredExamples(
    FormalSystemKey systemKey,
  ) async {
    final module = _registry.moduleFor(systemKey);
    if (module == null || !module.descriptor.capabilities.examples.isEnabled) {
      throw StateError('Examples are unavailable for ${systemKey.value}');
    }
    final catalog = module.examples;
    if (catalog != null) return catalog.loadExamples();
    final builtInLoader = _builtInCatalogs[systemKey];
    if (builtInLoader != null) return builtInLoader();
    throw StateError(
      'No registered example catalog is available for ${systemKey.value}',
    );
  }

  Map<FormalSystemKey, Future<List<AssetExample<Object>>> Function()>
  get _builtInCatalogs => {
    DefaultFormalSystemIds.fsa: () => _unwrap(loadAllTypedFsaExamples()),
    DefaultFormalSystemIds.grammar: () => _unwrap(loadAllTypedCfgExamples()),
    DefaultFormalSystemIds.pda: () => _unwrap(loadAllTypedPdaExamples()),
    DefaultFormalSystemIds.tm: () => _unwrap(loadAllTypedTmExamples()),
    DefaultFormalSystemIds.regex: () => _unwrap(loadAllTypedRegexExamples()),
  };

  Future<List<AssetExample<Object>>> _unwrap<T extends Object>(
    Future<ListResult<AssetExample<T>>> resultFuture,
  ) async {
    final result = await resultFuture;
    if (result.isFailure) throw StateError(result.error!);
    return result.data!.cast<AssetExample<Object>>();
  }

  String? _ensureExamplesAvailable(FormalSystemKey systemKey) {
    final descriptor = _registry.descriptorFor(systemKey);
    if (descriptor == null || !descriptor.capabilities.examples.isEnabled) {
      return 'Examples are unavailable for ${systemKey.value}';
    }
    return null;
  }

  /// Gets all available categories
  List<ExampleCategory> getAvailableCategories() {
    return ExampleCategory.values;
  }

  /// Gets examples count by category
  Map<ExampleCategory, int> getExamplesCountByCategory() {
    final counts = <ExampleCategory, int>{};
    for (final category in ExampleCategory.values) {
      counts[category] = _exampleMetadata.values
          .where((meta) => meta.category == category)
          .length;
    }
    return counts;
  }

  /// Search examples by tags or description
  List<String> searchExamples(String query) {
    final results = <String>[];
    final lowerQuery = query.toLowerCase();

    for (final entry in _exampleMetadata.entries) {
      if (entry.key.toLowerCase().contains(lowerQuery) ||
          entry.value.description.toLowerCase().contains(lowerQuery) ||
          entry.value.tags.any(
            (tag) => tag.toLowerCase().contains(lowerQuery),
          )) {
        results.add(entry.key);
      }
    }

    return results;
  }
}

/// Metadata for an example.
class _ExampleMetadata {
  final String fileName;
  final ExampleCategory category;
  final DifficultyLevel difficulty;
  final String description;
  final List<String> tags;
  final ExampleComplexityLevel estimatedComplexity;

  String get id {
    final extension = fileName.lastIndexOf('.');
    final stem = extension < 0 ? fileName : fileName.substring(0, extension);
    return 'asset/${stem.toLowerCase()}';
  }

  FormalSystemKey get systemKey =>
      ExamplesAssetDataSource._systemByCategory[category]!;

  const _ExampleMetadata({
    required this.fileName,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.tags,
    required this.estimatedComplexity,
  });
}
