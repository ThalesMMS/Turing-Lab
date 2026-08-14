//
//  tape_drawer.dart
//  Turing Lab
//
//  Bottom drawer para visualização da fita da Máquina de Turing, acessível
//  durante edição e simulação. Mostra células, posição da cabeça e operações.
//
//  Created for Phase 1 improvements - November 2025
//

import 'package:flutter/material.dart';

/// Estado da fita em um momento específico
class TapeState {
  final List<String> cells;
  final int headPosition;
  final String blankSymbol;
  final String? lastOperation;
  final String? lastReadSymbol;
  final String? lastWriteSymbol;

  /// Optional explicit tape-cell highlights coming from a selected simulation step.
  ///
  /// These are indices into [cells] (not the visible window). When indices fall
  /// outside the current tape length, they are treated as blanks.
  final Set<int> highlightedCellIndices;

  const TapeState({
    required this.cells,
    required this.headPosition,
    this.blankSymbol = '□',
    this.lastOperation,
    this.lastReadSymbol,
    this.lastWriteSymbol,
    this.highlightedCellIndices = const <int>{},
  });

  /// Fita vazia/inicial
  TapeState.initial({this.blankSymbol = '□'})
      : cells = const [],
        headPosition = 0,
        lastOperation = null,
        lastReadSymbol = null,
        lastWriteSymbol = null,
        highlightedCellIndices = const <int>{};

  bool get isEmpty => cells.isEmpty;

  /// Célula sob a cabeça
  String get currentCell {
    if (headPosition < 0 || headPosition >= cells.length) {
      return blankSymbol;
    }
    return cells[headPosition];
  }

  /// True se a célula atual foi lida na última operação
  bool get wasRead => lastReadSymbol != null;

  /// True se a célula atual foi escrita na última operação
  bool get wasWritten => lastWriteSymbol != null;

  /// Retorna células visíveis (com padding de blanks se necessário)
  List<String> getVisibleCells({int padding = 3}) {
    if (cells.isEmpty) {
      return List.filled(padding * 2 + 1, blankSymbol);
    }

    final start = headPosition - padding;
    final end = headPosition + padding + 1;
    final result = <String>[];

    for (var i = start; i < end; i++) {
      if (i < 0 || i >= cells.length) {
        result.add(blankSymbol);
      } else {
        result.add(cells[i]);
      }
    }

    return result;
  }

  /// Índice da cabeça nas células visíveis
  int getHeadIndexInVisible({int padding = 3}) {
    return padding;
  }
}

/// Painel flutuante para visualização da fita
class TMTapePanel extends StatefulWidget {
  final TapeState tapeState;
  final Set<String> tapeAlphabet;
  final bool isSimulating;
  final VoidCallback? onClear;
  final void Function(int cellIndex, String newValue)? onCellEdit;

  const TMTapePanel({
    super.key,
    required this.tapeState,
    required this.tapeAlphabet,
    this.isSimulating = false,
    this.onClear,
    this.onCellEdit,
  });

  @override
  State<TMTapePanel> createState() => _TMTapePanelState();
}

class _TMTapePanelState extends State<TMTapePanel>
    with TickerProviderStateMixin {
  late AnimationController _headAnimationController;
  late AnimationController _readBadgeController;
  late AnimationController _writeBadgeController;
  late AnimationController _cellScaleController;
  late AnimationController _expansionController;
  late AnimationController _expansionGlowController;
  late ScrollController _horizontalScrollController;
  late Animation<double> _readBadgeOpacity;
  late Animation<double> _writeBadgeOpacity;
  late Animation<double> _cellScaleAnimation;
  late Animation<double> _expansionSlideAnimation;
  late Animation<double> _expansionGlowAnimation;
  int _previousTapeLength = 0;
  String? _previousCellContent;
  bool _isExpanding = false;

  @override
  void initState() {
    super.initState();
    _headAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _readBadgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _writeBadgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cellScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expansionGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _horizontalScrollController = ScrollController();
    _previousTapeLength = widget.tapeState.cells.length;
    _previousCellContent = widget.tapeState.currentCell;

    // Initialize animations
    _readBadgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _readBadgeController, curve: Curves.easeIn),
    );
    _writeBadgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _writeBadgeController, curve: Curves.easeIn),
    );
    _cellScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_cellScaleController);
    _expansionSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expansionController, curve: Curves.easeOut),
    );
    _expansionGlowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_expansionGlowController);

    // Set initial animation state
    if (widget.tapeState.wasRead) {
      _readBadgeController.value = 1.0;
    }
    if (widget.tapeState.wasWritten) {
      _writeBadgeController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TMTapePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle tape expansion (length change)
    final currentTapeLength = widget.tapeState.cells.length;
    if (_previousTapeLength != currentTapeLength) {
      if (currentTapeLength > _previousTapeLength) {
        // Tape expanded - trigger slide-in animation and glow effect
        _isExpanding = true;
        _expansionController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _isExpanding = false;
            });
          }
        });
        _expansionGlowController.forward(from: 0);
      }
      _previousTapeLength = currentTapeLength;
    }

    // Handle head position change
    if (oldWidget.tapeState.headPosition != widget.tapeState.headPosition) {
      _headAnimationController.forward(from: 0);
      _scrollToHead();
    }

    // Trigger read badge animation when read symbol changes
    if (oldWidget.tapeState.lastReadSymbol != widget.tapeState.lastReadSymbol) {
      if (widget.tapeState.wasRead) {
        _readBadgeController.forward(from: 0);
      } else {
        _readBadgeController.reset();
      }
    }

    // Trigger write badge animation when write symbol changes
    if (oldWidget.tapeState.lastWriteSymbol !=
        widget.tapeState.lastWriteSymbol) {
      if (widget.tapeState.wasWritten) {
        _writeBadgeController.forward(from: 0);
      } else {
        _writeBadgeController.reset();
      }
    }

    // Trigger cell content scale animation when cell content changes
    final currentCellContent = widget.tapeState.currentCell;
    if (_previousCellContent != null &&
        _previousCellContent != currentCellContent) {
      _cellScaleController.forward(from: 0);
    }
    _previousCellContent = currentCellContent;
  }

  void _scrollToHead() {
    // Auto-scroll para manter cabeça centralizada na viewport
    if (_horizontalScrollController.hasClients) {
      const cellWidth = 50.0; // Adjusted for compact view
      final scrollPosition = _horizontalScrollController.position;
      final viewportWidth = scrollPosition.viewportDimension;

      // Calcula offset para centralizar a cabeça
      final headCenterOffset = widget.tapeState.headPosition * cellWidth;
      final targetOffset =
          headCenterOffset - (viewportWidth / 2) + (cellWidth / 2);

      // Clamp para não ultrapassar os limites do conteúdo
      final minOffset = scrollPosition.minScrollExtent;
      final maxOffset = scrollPosition.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(minOffset, maxOffset);

      _horizontalScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _headAnimationController.dispose();
    _readBadgeController.dispose();
    _writeBadgeController.dispose();
    _cellScaleController.dispose();
    _expansionController.dispose();
    _expansionGlowController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _showCellEditDialog(int cellIndex, String currentSymbol) async {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: currentSymbol);
    final focusNode = FocusNode();

    // Request focus after dialog is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Cell $cellIndex', style: theme.textTheme.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick selection buttons for tape alphabet
            if (widget.tapeAlphabet.isNotEmpty) ...[
              Text(
                'Tape Alphabet:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Blank symbol button
                  _buildSymbolButton(widget.tapeState.blankSymbol, () {
                    controller.text = widget.tapeState.blankSymbol;
                  }, theme),
                  // Tape alphabet symbols
                  ...widget.tapeAlphabet.map(
                    (symbol) => _buildSymbolButton(symbol, () {
                      controller.text = symbol;
                    }, theme),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            // Text input field
            TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Symbol',
                hintText: 'Enter a symbol',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                  },
                ),
              ),
              maxLength: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.isEmpty
                  ? widget.tapeState.blankSymbol
                  : controller.text;
              Navigator.of(context).pop(value);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    controller.dispose();
    focusNode.dispose();

    if (result != null && mounted) {
      widget.onCellEdit?.call(cellIndex, result);
    }
  }

  Widget _buildSymbolButton(
    String symbol,
    VoidCallback onPressed,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          symbol,
          style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxPanelWidth =
        (MediaQuery.sizeOf(context).width - 32).clamp(0.0, 300.0).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: maxPanelWidth,
        constraints: BoxConstraints(maxWidth: maxPanelWidth),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - wrapped in RepaintBoundary to isolate from tape animations
            RepaintBoundary(
              child: Row(
                children: [
                  Icon(
                    Icons.horizontal_rule,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tape (Head: ${widget.tapeState.headPosition})',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onClear != null)
                    SizedBox(
                      width: 60,
                      height: 24,
                      child: TextButton(
                        onPressed: widget.onClear,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: theme.colorScheme.error,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 12),

            // Tape Visual
            SizedBox(
              height: 60,
              child: _buildTapeContent(theme), // Always compact mode
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTapeContent(ThemeData theme) {
    if (widget.tapeState.isEmpty) {
      return Center(
        child: Text(
          'Empty (□: ${widget.tapeState.blankSymbol})',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final visibleCells = widget.tapeState.getVisibleCells(padding: 4);
    final headIndex = widget.tapeState.getHeadIndexInVisible(padding: 4);
    const padding = 4;
    final startIndex = widget.tapeState.headPosition - padding;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(visibleCells.length, (index) {
          final isHead = index == headIndex;
          final wasRead = isHead && widget.tapeState.wasRead;
          final wasWritten = isHead && widget.tapeState.wasWritten;
          final actualCellIndex = startIndex + index;
          final isHighlighted =
              widget.tapeState.highlightedCellIndices.contains(actualCellIndex);

          // Determine if this cell is at the edge (newly expanded)
          final isAtLeftEdge = index == 0;
          final isAtRightEdge = index == visibleCells.length - 1;
          final isNewCell = _isExpanding && (isAtLeftEdge || isAtRightEdge);

          return _buildTapeCell(
            visibleCells[index],
            actualCellIndex,
            isHead,
            wasRead,
            wasWritten,
            isHighlighted,
            theme,
            isNewCell: isNewCell,
            slideFromLeft: isAtLeftEdge,
          );
        }),
      ),
    );
  }

  Widget _buildTapeCell(
    String symbol,
    int cellIndex,
    bool isHead,
    bool wasRead,
    bool wasWritten,
    bool isHighlighted,
    ThemeData theme, {
    bool isNewCell = false,
    bool slideFromLeft = false,
  }) {
    final canEdit = !widget.isSimulating && widget.onCellEdit != null;

    final cellWidget = AnimatedBuilder(
      animation: _expansionGlowAnimation,
      builder: (context, child) {
        // Calculate glow intensity based on animation value
        final glowIntensity = isNewCell ? _expansionGlowAnimation.value : 0.0;
        final glowColor = theme.colorScheme.primary.withValues(
          alpha: 0.4 * glowIntensity,
        );

        return Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isHead
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isHighlighted
                  ? theme.colorScheme.tertiary
                  : isHead
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isHighlighted
                  ? 2.5
                  : isHead
                      ? 2
                      : 1,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isNewCell && glowIntensity > 0
                ? [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 8 * glowIntensity,
                      spreadRadius: 2 * glowIntensity,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Main cell content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isHead)
                Icon(
                  Icons.arrow_downward,
                  size: 10,
                  color: theme.colorScheme.primary,
                ),
              AnimatedBuilder(
                animation: _cellScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isHead ? _cellScaleAnimation.value : 1.0,
                    child: child,
                  );
                },
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isHead ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'monospace',
                    color: isHead
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          // Read indicator badge (top-left) with fade-in animation
          if (wasRead)
            Positioned(
              top: 2,
              left: 2,
              child: FadeTransition(
                opacity: _readBadgeOpacity,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.visibility,
                    size: 8,
                    color: theme.colorScheme.onTertiary,
                  ),
                ),
              ),
            ),
          // Write indicator badge (top-right) with fade-in animation
          if (wasWritten)
            Positioned(
              top: 2,
              right: 2,
              child: FadeTransition(
                opacity: _writeBadgeOpacity,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 8,
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Wrap with slide animation if this is a new cell from expansion
    Widget result = cellWidget;
    if (isNewCell) {
      result = AnimatedBuilder(
        animation: _expansionSlideAnimation,
        builder: (context, child) {
          final offset = slideFromLeft
              ? Offset(-(1.0 - _expansionSlideAnimation.value), 0.0)
              : Offset(1.0 - _expansionSlideAnimation.value, 0.0);
          return SlideTransition(
            position: AlwaysStoppedAnimation(offset),
            child: FadeTransition(
              opacity: _expansionSlideAnimation,
              child: child,
            ),
          );
        },
        child: cellWidget,
      );
    }

    // Wrap in RepaintBoundary to isolate individual cell repaints
    // This prevents other cells from repainting when only one cell animates
    final boundedResult = RepaintBoundary(child: result);

    if (!canEdit) {
      return boundedResult;
    }

    return InkWell(
      onTap: () => _showCellEditDialog(cellIndex, symbol),
      borderRadius: BorderRadius.circular(4),
      child: boundedResult,
    );
  }
}
