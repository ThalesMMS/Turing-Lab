//
//  grammar_provider.dart
//  Turing Lab
//
//  Manages formal grammar editing in the workspace, keeping productions,
//  the start symbol, selected type, and recent conversion results while
//  integrating transformation services to generate automata and PDAs
//  consumed by widgets and visual feedback.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/grammar_to_fsa_converter.dart';
import '../../core/algorithms/grammar_to_pda_converter.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/production.dart';
import '../../core/messages/structured_message.dart';
import '../../core/result.dart';

/// Types of conversions that can be triggered from the grammar workspace.
enum GrammarConversionKind {
  grammarToFsa,
  grammarToPda,
  grammarToPdaStandard,
  grammarToPdaGreibach,
}

/// State for managing grammar editing and conversions.
class GrammarState {
  final String documentId;
  final int documentGeneration;
  final String name;
  final String startSymbol;
  final List<Production> productions;
  final GrammarType type;
  final bool isConverting;
  final String? error;
  final StructuredMessage? structuredError;
  final int nextProductionId;
  final GrammarConversionKind? activeConversion;
  final Result<PDA>? lastPdaResult;

  const GrammarState({
    required this.documentId,
    required this.documentGeneration,
    required this.name,
    required this.startSymbol,
    required this.productions,
    required this.type,
    required this.isConverting,
    required this.nextProductionId,
    this.activeConversion,
    this.lastPdaResult,
    this.error,
    this.structuredError,
  });

  factory GrammarState.initial() {
    return const GrammarState(
      documentId: 'grammar_default',
      documentGeneration: 0,
      name: 'My Grammar',
      startSymbol: 'S',
      productions: [],
      type: GrammarType.regular,
      isConverting: false,
      nextProductionId: 1,
      activeConversion: null,
      lastPdaResult: null,
    );
  }

  GrammarState copyWith({
    String? documentId,
    int? documentGeneration,
    String? name,
    String? startSymbol,
    List<Production>? productions,
    GrammarType? type,
    bool? isConverting,
    Object? error = _noErrorUpdate,
    Object? structuredError = _noStructuredErrorUpdate,
    int? nextProductionId,
    Object? activeConversion = _noActiveConversionUpdate,
    Object? lastPdaResult = _noPdaResultUpdate,
  }) {
    return GrammarState(
      documentId: documentId ?? this.documentId,
      documentGeneration: documentGeneration ?? this.documentGeneration,
      name: name ?? this.name,
      startSymbol: startSymbol ?? this.startSymbol,
      productions: productions ?? this.productions,
      type: type ?? this.type,
      isConverting: isConverting ?? this.isConverting,
      error: error == _noErrorUpdate ? this.error : error as String?,
      structuredError: structuredError == _noStructuredErrorUpdate
          ? (error == _noErrorUpdate ? this.structuredError : null)
          : structuredError as StructuredMessage?,
      nextProductionId: nextProductionId ?? this.nextProductionId,
      activeConversion: activeConversion == _noActiveConversionUpdate
          ? this.activeConversion
          : activeConversion as GrammarConversionKind?,
      lastPdaResult: lastPdaResult == _noPdaResultUpdate
          ? this.lastPdaResult
          : lastPdaResult as Result<PDA>?,
    );
  }
}

const _noErrorUpdate = Object();
const _noStructuredErrorUpdate = Object();
const _noActiveConversionUpdate = Object();
const _noPdaResultUpdate = Object();

const _symbolListEquality = ListEquality<String>();

/// Normalized right-side input used by atomic production-group mutations.
class ProductionAlternativeDraft {
  const ProductionAlternativeDraft({
    required this.rightSide,
    this.isLambda = false,
  });

  final List<String> rightSide;
  final bool isLambda;

  bool get isValid => isLambda
      ? rightSide.isEmpty
      : rightSide.isNotEmpty && !rightSide.contains('');
}

/// Describes the outcome of an atomic production-group mutation.
class ProductionGroupMutationResult {
  const ProductionGroupMutationResult({
    required this.changed,
    this.addedCount = 0,
    this.duplicateCount = 0,
    this.removedCount = 0,
    this.invalid = false,
  });

  final bool changed;
  final int addedCount;
  final int duplicateCount;
  final int removedCount;
  final bool invalid;
}

/// Provider notifier responsible for updating grammar state and running conversions.
class GrammarProvider extends StateNotifier<GrammarState> {
  GrammarProvider() : super(GrammarState.initial());

  static final RegExp _productionIdPattern = RegExp(r'^p(\d+)$');

  void updateName(String value) {
    state = state.copyWith(name: value, error: null);
  }

  void updateStartSymbol(String value) {
    if (value.isEmpty) {
      return;
    }
    state = state.copyWith(startSymbol: value, error: null);
  }

  void addProduction({
    required List<String> leftSide,
    required List<String> rightSide,
    bool isLambda = false,
  }) {
    final production = Production(
      id: 'p${state.nextProductionId}',
      leftSide: leftSide,
      rightSide: rightSide,
      isLambda: isLambda,
      order: state.productions.length,
    );
    state = state.copyWith(
      productions: [...state.productions, production],
      nextProductionId: state.nextProductionId + 1,
      error: null,
    );
  }

  /// Adds all new alternatives in one state update and ignores duplicates.
  ProductionGroupMutationResult addProductionAlternatives({
    required List<String> leftSide,
    required Iterable<ProductionAlternativeDraft> alternatives,
  }) {
    final drafts = alternatives.toList(growable: false);
    if (!_validLeftSide(leftSide) ||
        drafts.isEmpty ||
        drafts.any((draft) => !draft.isValid)) {
      return const ProductionGroupMutationResult(changed: false, invalid: true);
    }

    final accepted = <ProductionAlternativeDraft>[];
    var duplicateCount = 0;
    for (final draft in drafts) {
      final alreadyExists = state.productions.any(
        (production) =>
            _sameLeftSide(production.leftSide, leftSide) &&
            _sameAlternative(production, draft),
      );
      final repeatedInBatch = accepted.any(
        (candidate) => _sameDraft(candidate, draft),
      );
      if (alreadyExists || repeatedInBatch) {
        duplicateCount++;
      } else {
        accepted.add(draft);
      }
    }

    if (accepted.isEmpty) {
      return ProductionGroupMutationResult(
        changed: false,
        duplicateCount: duplicateCount,
      );
    }

    var nextId = state.nextProductionId;
    final additions = <Production>[];
    for (final draft in accepted) {
      additions.add(
        Production(
          id: 'p$nextId',
          leftSide: List<String>.from(leftSide),
          rightSide: List<String>.from(draft.rightSide),
          isLambda: draft.isLambda,
          order: state.productions.length + additions.length,
        ),
      );
      nextId++;
    }

    state = state.copyWith(
      productions: _withSequentialOrder([...state.productions, ...additions]),
      nextProductionId: nextId,
      error: null,
      lastPdaResult: null,
    );

    return ProductionGroupMutationResult(
      changed: true,
      addedCount: additions.length,
      duplicateCount: duplicateCount,
    );
  }

  void updateProduction(
    String id, {
    required List<String> leftSide,
    required List<String> rightSide,
    bool isLambda = false,
  }) {
    final index = state.productions.indexWhere((p) => p.id == id);
    if (index == -1) {
      return;
    }

    final updated = state.productions[index].copyWith(
      leftSide: leftSide,
      rightSide: rightSide,
      isLambda: isLambda,
    );

    final productions = [...state.productions];
    productions[index] = updated;

    state = state.copyWith(productions: productions, error: null);
  }

  void deleteProduction(String id) {
    final remaining = state.productions.where((p) => p.id != id).toList();
    state = state.copyWith(
      productions: _withSequentialOrder(remaining),
      error: null,
      lastPdaResult: null,
    );
  }

  /// Replaces one left-side group atomically, preserving retained IDs.
  ProductionGroupMutationResult replaceProductionGroup({
    required List<String> originalLeftSide,
    required List<String> leftSide,
    required Iterable<ProductionAlternativeDraft> alternatives,
  }) {
    final drafts = alternatives.toList(growable: false);
    final sourceProductions = state.productions
        .where(
          (production) => _sameLeftSide(production.leftSide, originalLeftSide),
        )
        .toList(growable: false);
    if (!_validLeftSide(leftSide) ||
        drafts.isEmpty ||
        drafts.any((draft) => !draft.isValid) ||
        sourceProductions.isEmpty) {
      return const ProductionGroupMutationResult(changed: false, invalid: true);
    }

    final desired = <ProductionAlternativeDraft>[];
    var duplicateCount = 0;
    for (final draft in drafts) {
      if (desired.any((candidate) => _sameDraft(candidate, draft))) {
        duplicateCount++;
      } else {
        desired.add(draft);
      }
    }

    final sameGroup = _sameLeftSide(originalLeftSide, leftSide);
    final targetProductions = sameGroup
        ? const <Production>[]
        : state.productions
              .where(
                (production) => _sameLeftSide(production.leftSide, leftSide),
              )
              .toList(growable: false);
    final retainedSourceIds = <String>{};
    var nextId = state.nextProductionId;
    var addedCount = 0;
    final replacement = <Production>[...targetProductions];

    for (final draft in desired) {
      final targetDuplicate = targetProductions.any(
        (production) => _sameAlternative(production, draft),
      );
      if (targetDuplicate) {
        duplicateCount++;
        continue;
      }

      final retained = sourceProductions.firstWhereOrNull(
        (production) =>
            !retainedSourceIds.contains(production.id) &&
            _sameAlternative(production, draft),
      );
      if (retained != null) {
        retainedSourceIds.add(retained.id);
        replacement.add(
          sameGroup
              ? retained
              : retained.copyWith(leftSide: List<String>.from(leftSide)),
        );
      } else {
        replacement.add(
          Production(
            id: 'p$nextId',
            leftSide: List<String>.from(leftSide),
            rightSide: List<String>.from(draft.rightSide),
            isLambda: draft.isLambda,
          ),
        );
        nextId++;
        addedCount++;
      }
    }

    final sourceIds = sourceProductions
        .map((production) => production.id)
        .toSet();
    final targetIds = targetProductions
        .map((production) => production.id)
        .toSet();
    final removedIds = {...sourceIds, ...targetIds};
    final anchorId = targetProductions.isNotEmpty
        ? targetProductions.first.id
        : sourceProductions.first.id;
    final anchorIndex = state.productions.indexWhere(
      (production) => production.id == anchorId,
    );
    final insertionIndex = state.productions
        .take(anchorIndex)
        .where((production) => !removedIds.contains(production.id))
        .length;
    final rebuilt = state.productions
        .where((production) => !removedIds.contains(production.id))
        .toList();
    rebuilt.insertAll(insertionIndex, replacement);
    final ordered = _withSequentialOrder(rebuilt);

    if (const ListEquality<Production>().equals(ordered, state.productions)) {
      return ProductionGroupMutationResult(
        changed: false,
        duplicateCount: duplicateCount,
      );
    }

    state = state.copyWith(
      productions: ordered,
      nextProductionId: nextId,
      error: null,
      lastPdaResult: null,
    );
    return ProductionGroupMutationResult(
      changed: true,
      addedCount: addedCount,
      duplicateCount: duplicateCount,
      removedCount: sourceProductions.length - retainedSourceIds.length,
    );
  }

  /// Deletes every alternative for [leftSide] and returns the removed count.
  int deleteProductionGroup(List<String> leftSide) {
    final remaining = state.productions
        .where((production) => !_sameLeftSide(production.leftSide, leftSide))
        .toList();
    final removedCount = state.productions.length - remaining.length;
    if (removedCount == 0) {
      return 0;
    }
    state = state.copyWith(
      productions: _withSequentialOrder(remaining),
      error: null,
      lastPdaResult: null,
    );
    return removedCount;
  }

  /// Moves one structural left-side group without changing its alternatives.
  bool reorderProductionGroup(int oldIndex, int newIndex) {
    final groups = <List<Production>>[];
    for (final production in state.productions) {
      final index = groups.indexWhere(
        (group) => _sameLeftSide(group.first.leftSide, production.leftSide),
      );
      if (index == -1) {
        groups.add([production]);
      } else {
        groups[index].add(production);
      }
    }
    if (oldIndex < 0 ||
        oldIndex >= groups.length ||
        newIndex < 0 ||
        newIndex >= groups.length ||
        oldIndex == newIndex) {
      return false;
    }

    final moved = groups.removeAt(oldIndex);
    groups.insert(newIndex, moved);
    state = state.copyWith(
      productions: _withSequentialOrder(groups.expand((group) => group)),
      error: null,
      lastPdaResult: null,
    );
    return true;
  }

  void clearProductions() {
    state = state.copyWith(
      productions: const <Production>[],
      nextProductionId: 1,
      error: null,
      lastPdaResult: null,
    );
  }

  /// Restores the full productions list (used for undo after destructive actions).
  void setProductions(List<Production> productions) {
    final maxId = productions
        .map((production) => _productionIdNumber(production.id))
        .fold<int>(0, (previous, value) => value > previous ? value : previous);

    state = state.copyWith(
      productions: productions,
      nextProductionId: maxId + 1,
      error: null,
      lastPdaResult: null,
    );
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Resets the grammar editor to a fresh grammar definition.
  void createNewGrammar({
    String? name,
    String? startSymbol,
    GrammarType? type,
  }) {
    state = GrammarState(
      documentId: 'grammar_${DateTime.now().microsecondsSinceEpoch}',
      documentGeneration: state.documentGeneration + 1,
      name: name ?? 'My Grammar',
      startSymbol: startSymbol ?? 'S',
      productions: const [],
      type: type ?? GrammarType.regular,
      isConverting: false,
      nextProductionId: 1,
      error: null,
      activeConversion: null,
      lastPdaResult: null,
    );
  }

  Grammar buildGrammar() {
    final now = DateTime.now();
    final nonTerminals = <String>{state.startSymbol};
    final terminals = <String>{};

    for (final production in state.productions) {
      if (production.leftSide.isNotEmpty) {
        nonTerminals.add(production.leftSide.first);
      }
    }

    final productions = state.productions.map((production) {
      if (production.isLambda || production.rightSide.length < 2) {
        return production;
      }
      final normalizedRightSide = _mergeDeclaredNonterminalFragments(
        production.rightSide,
        nonTerminals,
      );
      return _symbolListEquality.equals(
            normalizedRightSide,
            production.rightSide,
          )
          ? production
          : production.copyWith(rightSide: normalizedRightSide);
    }).toList(growable: false);

    for (final production in productions) {
      if (production.isLambda) {
        continue;
      }

      for (final symbol in production.rightSide) {
        if (_isLambda(symbol)) {
          continue;
        }

        if (nonTerminals.contains(symbol) || _looksLikeNonTerminal(symbol)) {
          nonTerminals.add(symbol);
        } else {
          terminals.add(symbol);
        }
      }
    }

    terminals.removeWhere(_isLambda);

    return Grammar(
      id: state.documentId,
      name: state.name,
      terminals: terminals,
      nonterminals: nonTerminals,
      startSymbol: state.startSymbol,
      productions: productions.toSet(),
      type: state.type,
      created: now,
      modified: now,
    );
  }

  static List<String> _mergeDeclaredNonterminalFragments(
    List<String> symbols,
    Set<String> declaredNonterminals,
  ) {
    final candidates = declaredNonterminals
        .where((symbol) => symbol.length > 1)
        .toSet();
    if (symbols.length < 2 || candidates.isEmpty) {
      return List<String>.from(symbols);
    }

    var maximumCandidateLength = 0;
    for (final candidate in candidates) {
      if (candidate.length > maximumCandidateLength) {
        maximumCandidateLength = candidate.length;
      }
    }

    final normalized = <String>[];
    var index = 0;
    while (index < symbols.length) {
      String? bestMatch;
      var bestEnd = index;
      final buffer = StringBuffer();

      for (var end = index; end < symbols.length; end++) {
        buffer.write(symbols[end]);
        final joined = buffer.toString();
        if (joined.length > maximumCandidateLength) {
          break;
        }
        if (candidates.contains(joined)) {
          bestMatch = joined;
          bestEnd = end + 1;
        }
      }

      if (bestMatch != null && bestEnd > index + 1) {
        normalized.add(bestMatch);
        index = bestEnd;
      } else {
        normalized.add(symbols[index]);
        index++;
      }
    }

    return normalized;
  }

  /// Restores an exact editor snapshot after a failed document replacement.
  void restoreDocumentCheckpoint(GrammarState checkpoint) {
    state = checkpoint;
  }

  void applyGrammar(Grammar grammar) {
    state = state.copyWith(
      documentId: grammar.id,
      documentGeneration: state.documentGeneration + 1,
      name: grammar.name,
      startSymbol: grammar.startSymbol,
      type: grammar.type,
      productions: grammar.productions.toList()
        ..sort((a, b) {
          final orderComparison = a.order.compareTo(b.order);
          if (orderComparison != 0) return orderComparison;
          return a.id.compareTo(b.id);
        }),
      error: null,
      lastPdaResult: null,
      activeConversion: null,
      nextProductionId: _nextProductionIdFor(grammar),
      isConverting: false,
    );
  }

  int _nextProductionIdFor(Grammar grammar) {
    return grammar.productions
            .map((p) {
              return _productionIdNumber(p.id);
            })
            .fold<int>(0, (prev, value) => value > prev ? value : prev) +
        1;
  }

  static int _productionIdNumber(String id) {
    final match = _productionIdPattern.firstMatch(id);
    return match == null ? 0 : int.parse(match.group(1)!);
  }

  static bool _validLeftSide(List<String> leftSide) =>
      leftSide.isNotEmpty && !leftSide.contains('');

  static bool _sameLeftSide(List<String> left, List<String> right) =>
      _symbolListEquality.equals(left, right);

  static bool _sameAlternative(
    Production production,
    ProductionAlternativeDraft draft,
  ) =>
      production.isLambda == draft.isLambda &&
      _symbolListEquality.equals(production.rightSide, draft.rightSide);

  static bool _sameDraft(
    ProductionAlternativeDraft left,
    ProductionAlternativeDraft right,
  ) =>
      left.isLambda == right.isLambda &&
      _symbolListEquality.equals(left.rightSide, right.rightSide);

  static List<Production> _withSequentialOrder(
    Iterable<Production> productions,
  ) => productions
      .toList(growable: false)
      .asMap()
      .entries
      .map(
        (entry) => entry.value.order == entry.key
            ? entry.value
            : entry.value.copyWith(order: entry.key),
      )
      .toList(growable: false);

  Future<Result<FSA>> convertToAutomaton() async {
    if (state.productions.isEmpty) {
      final result = ResultFactory.failure<FSA>(
        'Add at least one production before converting.',
      );
      state = state.copyWith(
        error: result.error,
        structuredError: result.structuredError,
        lastPdaResult: null,
      );
      return result;
    }

    final grammar = buildGrammar();
    state = state.copyWith(
      isConverting: true,
      error: null,
      structuredError: null,
      activeConversion: GrammarConversionKind.grammarToFsa,
      lastPdaResult: null,
    );

    final result = GrammarToFSAConverter.convert(grammar);

    if (result.isSuccess) {
      state = state.copyWith(
        isConverting: false,
        error: null,
        structuredError: null,
        activeConversion: null,
      );
    } else {
      state = state.copyWith(
        isConverting: false,
        error: result.error,
        structuredError: result.structuredError,
        activeConversion: null,
      );
    }

    return result;
  }

  Future<Result<PDA>> convertToPda() {
    return _performPdaConversion(
      converter: GrammarToPDAConverter.convertGrammarToPDA,
      conversionType: GrammarConversionKind.grammarToPda,
    );
  }

  Future<Result<PDA>> convertToPdaStandard() {
    return _performPdaConversion(
      converter: GrammarToPDAConverter.convertGrammarToPDAStandard,
      conversionType: GrammarConversionKind.grammarToPdaStandard,
    );
  }

  Future<Result<PDA>> convertToPdaGreibach() {
    return _performPdaConversion(
      converter: GrammarToPDAConverter.convertGrammarToPDAGreibach,
      conversionType: GrammarConversionKind.grammarToPdaGreibach,
    );
  }

  Future<Result<PDA>> _performPdaConversion({
    required Result<PDA> Function(Grammar grammar) converter,
    required GrammarConversionKind conversionType,
  }) async {
    if (state.productions.isEmpty) {
      final result = ResultFactory.failure<PDA>(
        'Add at least one production before converting.',
      );
      state = state.copyWith(
        error: result.error,
        lastPdaResult: result,
        activeConversion: null,
        isConverting: false,
      );
      return result;
    }

    final grammar = buildGrammar();
    state = state.copyWith(
      isConverting: true,
      error: null,
      activeConversion: conversionType,
    );

    final result = converter(grammar);

    state = state.copyWith(
      isConverting: false,
      error: result.error,
      activeConversion: null,
      lastPdaResult: result,
    );

    return result;
  }

  bool _isLambda(String symbol) =>
      symbol == 'ε' || symbol == 'λ' || symbol.toLowerCase() == 'lambda';

  bool _looksLikeNonTerminal(String symbol) {
    final uppercaseRegex = RegExp(r'^[A-Z]$');
    return uppercaseRegex.hasMatch(symbol);
  }
}

/// Global grammar provider instance.
final grammarProvider = StateNotifierProvider<GrammarProvider, GrammarState>((
  ref,
) {
  return GrammarProvider();
});