//
//  tape_drawer.dart
//  Turing Lab
//
//  Bottom drawer for Turing-machine tape visualization, available during
//  editing and simulation. Shows cells, head position, and operations.
//
//  Created for Phase 1 improvements - November 2025
//

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_resolver.dart';
import '../../../core/constants/monospace_typography.dart';

/// Tape state at a specific moment
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

  /// Empty/initial tape
  TapeState.initial({this.blankSymbol = '□'})
      : cells = const [],
        headPosition = 0,
        lastOperation = null,
        lastReadSymbol = null,
        lastWriteSymbol = null,
        highlightedCellIndices = const <int>{};

  bool get isEmpty => cells.isEmpty;

  /// Cell under the head
  String get currentCell {
    if (headPosition < 0 || headPosition >= cells.length) {
      return blankSymbol;
    }
    return cells[headPosition];
  }

  /// True if the current cell was read in the last operation
  bool get wasRead => lastReadSymbol != null;

  /// True if the current cell was written in the last operation
  bool get wasWritten => lastWriteSymbol != null;

  /// Returns visible cells (padded with blanks if needed)
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

  /// Head index within the visible cells
  int getHeadIndexInVisible({int padding = 3}) {
    return padding;
  }
}

/// Floating panel for tape visualization
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
  /// Cell width (50) plus its horizontal margins (2 + 2).
  static const double _cellExtent = 54.0;

  /// Dimmed off-tape cells rendered on both ends so the tape reads as
  /// infinite while it slides under the fixed head frame.
  static const int _phantomCells = 3;

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
  bool _needsCenterJump = true;

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

    // The scroll view only exists once the tape has cells; center the head
    // as soon as it first appears.
    if (oldWidget.tapeState.isEmpty && !widget.tapeState.isEmpty) {
      _needsCenterJump = true;
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

  /// Offset that puts the head cell exactly under the fixed center frame.
  ///
  /// The row starts with a side spacer sized to (viewport - cell) / 2
  /// followed by [_phantomCells] off-tape cells, so the offset depends only
  /// on the head index — never on the viewport width.
  double _headOffset() {
    final target =
        (_phantomCells + widget.tapeState.headPosition) * _cellExtent;
    if (!_horizontalScrollController.hasClients) {
      return target;
    }
    final position = _horizontalScrollController.position;
    return target
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
  }

  void _scrollToHead() {
    // Slide the tape so the head lands under the fixed center frame.
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.animateTo(
        _headOffset(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scheduleCenterJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_needsCenterJump ||
          !_horizontalScrollController.hasClients) {
        return;
      }
      _needsCenterJump = false;
      _horizontalScrollController.jumpTo(_headOffset());
    });
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
        title: Text(
          appLocalizationsOf(context).editCell(cellIndex),
          style: theme.textTheme.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick selection buttons for tape alphabet
            if (widget.tapeAlphabet.isNotEmpty) ...[
              Text(
                appLocalizationsOf(context).tapeAlphabetLabel,
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
                labelText: appLocalizationsOf(context).symbolLabel,
                hintText: appLocalizationsOf(context).enterASymbol,
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
              style: const TextStyle(
                  fontSize: 20,
                  fontFamilyFallback: kMonospaceFontFamilyFallback),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(appLocalizationsOf(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.isEmpty
                  ? widget.tapeState.blankSymbol
                  : controller.text;
              Navigator.of(context).pop(value);
            },
            child: Text(appLocalizationsOf(context).ok),
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
          style: const TextStyle(
              fontSize: 18, fontFamilyFallback: kMonospaceFontFamilyFallback),
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
                  Expanded(
                    child: Text(
                      appLocalizationsOf(context)
                          .tapeHead(widget.tapeState.headPosition),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                        child: Text(
                          appLocalizationsOf(context).clear,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 12),

            // Tape Visual
            SizedBox(
              height: widget.tapeState.isEmpty ? 60 : 72,
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
          appLocalizationsOf(context).emptyTape(widget.tapeState.blankSymbol),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final tapeState = widget.tapeState;
    final head = tapeState.headPosition;
    // Cover the head even when it sits on a blank beyond the written tape.
    final renderLength = math.max(tapeState.cells.length, head + 1);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    _scheduleCenterJump();

    return Column(
      children: [
        // Fixed head marker: the frame below never moves — the tape does.
        SizedBox(
          height: 14,
          child: Icon(
            Icons.arrow_downward,
            size: 12,
            color: theme.colorScheme.primary,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sideSpacer =
                  math.max(0.0, (constraints.maxWidth - _cellExtent) / 2);
              return Stack(
                fit: StackFit.expand,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _horizontalScrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: [
                        SizedBox(width: sideSpacer),
                        for (var i = 0; i < _phantomCells; i++)
                          _buildPhantomCell(theme),
                        for (var i = 0; i < renderLength; i++)
                          _buildIndexedTapeCell(i, renderLength, theme),
                        for (var i = 0; i < _phantomCells; i++)
                          _buildPhantomCell(theme),
                        SizedBox(width: sideSpacer),
                      ],
                    ),
                  ),
                  // Fixed selection frame the tape slides underneath.
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: _cellExtent,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.06),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.18),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Edge fades hint that the tape continues off-screen.
                  for (final alignLeft in const [true, false])
                    Positioned(
                      left: alignLeft ? 0 : null,
                      right: alignLeft ? null : 0,
                      top: 0,
                      bottom: 0,
                      width: 24,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: alignLeft
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              end: alignLeft
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              colors: [
                                cardColor,
                                cardColor.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndexedTapeCell(int index, int renderLength, ThemeData theme) {
    final tapeState = widget.tapeState;
    final symbol = index < tapeState.cells.length
        ? tapeState.cells[index]
        : tapeState.blankSymbol;
    final isHead = index == tapeState.headPosition;

    return _buildTapeCell(
      symbol,
      index,
      isHead,
      isHead && tapeState.wasRead,
      isHead && tapeState.wasWritten,
      tapeState.highlightedCellIndices.contains(index),
      theme,
      isNewCell: _isExpanding && (index == 0 || index == renderLength - 1),
      slideFromLeft: index == 0,
    );
  }

  Widget _buildPhantomCell(ThemeData theme) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(8),
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
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isHighlighted ? 2.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
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
          Center(
            child: AnimatedBuilder(
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
                  fontSize: 18,
                  fontWeight: isHead ? FontWeight.bold : FontWeight.normal,
                  fontFamilyFallback: kMonospaceFontFamilyFallback,
                  color: isHead
                      ? theme.colorScheme.primary
                      : symbol == widget.tapeState.blankSymbol
                          ? theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.45)
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // Cell index
          Positioned(
            bottom: 1,
            left: 0,
            right: 0,
            child: Text(
              '$cellIndex',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
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
      borderRadius: BorderRadius.circular(8),
      child: boundedResult,
    );
  }
}
