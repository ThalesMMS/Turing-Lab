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
import '../converters/asset_example_converters.dart';
import '../../core/models/asset_example.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/regex_preset.dart';
import '../../core/models/tm.dart';
import '../../core/result.dart';
import '../../core/repositories/examples_repository.dart';

export '../../core/models/asset_example.dart'
    show AssetExample, DifficultyLevel, ExampleCategory, ExampleComplexityLevel;

/// Enhanced data source for loading example automatons from assets (Examples v1)
class ExamplesAssetDataSource implements ExamplesRepository {
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
      {ExampleCategory.dfa, ExampleCategory.nfa},
      convertAssetJsonToFsa,
    );
  }

  @override
  Future<Result<AssetExample<Grammar>>> loadTypedCfgExample(String name) {
    return _loadTypedExample(
      name,
      {ExampleCategory.cfg},
      convertAssetJsonToGrammar,
    );
  }

  @override
  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name) {
    return _loadTypedExample(
      name,
      {ExampleCategory.pda},
      convertAssetJsonToPda,
    );
  }

  @override
  Future<Result<AssetExample<TM>>> loadTypedTmExample(String name) {
    return _loadTypedExample(
      name,
      {ExampleCategory.tm},
      convertAssetJsonToTm,
    );
  }

  @override
  Future<Result<AssetExample<RegexPreset>>> loadTypedRegexExample(String name) {
    return _loadTypedExample(
      name,
      {ExampleCategory.regex},
      convertAssetJsonToRegexPreset,
    );
  }

  @override
  Future<ListResult<AssetExample<FSA>>> loadAllTypedFsaExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.dfa, ExampleCategory.nfa},
      loadTypedFsaExample,
    );
  }

  @override
  Future<ListResult<AssetExample<Grammar>>> loadAllTypedCfgExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.cfg},
      loadTypedCfgExample,
    );
  }

  @override
  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.pda},
      loadTypedPdaExample,
    );
  }

  @override
  Future<ListResult<AssetExample<TM>>> loadAllTypedTmExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.tm},
      loadTypedTmExample,
    );
  }

  @override
  Future<ListResult<AssetExample<RegexPreset>>> loadAllTypedRegexExamples() {
    return _loadAllTypedExamples(
      {ExampleCategory.regex},
      loadTypedRegexExample,
    );
  }

  Future<ListResult<AssetExample<T>>> _loadAllTypedExamples<T extends Object>(
    Set<ExampleCategory> categories,
    Future<Result<AssetExample<T>>> Function(String name) load,
  ) async {
    final examples = <AssetExample<T>>[];

    for (final entry in _exampleMetadata.entries) {
      if (!categories.contains(entry.value.category)) {
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
    String name,
    Set<ExampleCategory> categories,
    Result<T> Function(Map<String, dynamic> json, String exampleName) convert,
  ) async {
    final metadata = _exampleMetadata[name];
    if (metadata == null) {
      return Failure('Example not found: $name');
    }

    if (!categories.contains(metadata.category)) {
      return Failure(
        'Example "$name" belongs to ${metadata.category.name.toUpperCase()}, '
        'not ${categories.map((category) => category.name.toUpperCase()).join('/')}',
      );
    }

    final assetPath = 'assets/examples/${metadata.fileName}';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return Failure(
          'Example $name has invalid JSON structure. Expected an object.',
        );
      }

      final conversionResult = convert(decoded, name);
      if (conversionResult.isFailure) {
        return Failure(conversionResult.error!);
      }

      return Success(
        AssetExample<T>(
          name: name,
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
          'Example asset not found for $name. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $name: $message');
    } on PlatformException catch (e) {
      final message = e.message ?? e.toString();
      if (message.contains('Unable to load asset')) {
        return Failure(
          'Example asset not found for $name. Expected at $assetPath',
        );
      }
      return Failure('Error loading example $name: $e');
    } on FormatException catch (e) {
      return Failure('Invalid JSON for example $name: ${e.message}');
    } on TypeError catch (e) {
      return Failure('Example $name has invalid data: ${e.toString()}');
    }
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

  const _ExampleMetadata({
    required this.fileName,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.tags,
    required this.estimatedComplexity,
  });
}
