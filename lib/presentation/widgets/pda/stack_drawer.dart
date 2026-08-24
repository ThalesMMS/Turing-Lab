//
//  stack_drawer.dart
//  Turing Lab
//
//  Bottom drawer for PDA stack visualization, available during editing
//  and simulation. Supports compact mode on mobile and expanded on desktop.
//
//  Created for Phase 1 improvements - November 2025
//

import 'package:flutter/material.dart';

/// Kind of operation performed on the stack
enum StackOperationType { none, push, pop, replace }

/// Stack state at a specific moment
class StackState {
  final List<String> symbols;
  final String? lastOperation;
  final StackOperationType operationType;
  final int maxStackSize;
  final bool hasOverflow;
  final bool hasUnderflow;

  const StackState({
    required this.symbols,
    this.lastOperation,
    this.operationType = StackOperationType.none,
    this.maxStackSize = 100,
    this.hasOverflow = false,
    this.hasUnderflow = false,
  });

  /// Empty stack
  const StackState.empty()
      : symbols = const [],
        lastOperation = null,
        operationType = StackOperationType.none,
        maxStackSize = 100,
        hasOverflow = false,
        hasUnderflow = false;

  bool get isEmpty => symbols.isEmpty;
  String? get top => symbols.isEmpty ? null : symbols.last;
  int get size => symbols.length;

  /// True if the stack has reached or exceeded the maximum size
  bool get isAtCapacity => symbols.length >= maxStackSize;

  /// True if a pop was attempted on an empty stack
  bool get attemptedUnderflow => hasUnderflow;

  /// True if the stack exceeded its limit
  bool get exceededCapacity => hasOverflow;

  /// Returns a copy after a push
  StackState push(String symbol) {
    final newSymbols = [...symbols, symbol];
    final willOverflow = newSymbols.length > maxStackSize;

    return StackState(
      symbols: newSymbols,
      lastOperation: 'push $symbol',
      operationType: StackOperationType.push,
      maxStackSize: maxStackSize,
      hasOverflow: willOverflow,
      hasUnderflow: false,
    );
  }

  /// Returns a copy after a pop
  StackState pop() {
    if (symbols.isEmpty) {
      // Attempting to pop from empty stack - underflow
      return StackState(
        symbols: symbols,
        lastOperation: 'pop (underflow)',
        operationType: StackOperationType.pop,
        maxStackSize: maxStackSize,
        hasOverflow: false,
        hasUnderflow: true,
      );
    }
    final popped = symbols.last;
    return StackState(
      symbols: symbols.sublist(0, symbols.length - 1),
      lastOperation: 'pop $popped',
      operationType: StackOperationType.pop,
      maxStackSize: maxStackSize,
      hasOverflow: false,
      hasUnderflow: false,
    );
  }

  /// Returns a copy with the top symbol replaced
  StackState replace(String newSymbol) {
    if (symbols.isEmpty) return push(newSymbol);
    final newSymbols = [...symbols];
    newSymbols[newSymbols.length - 1] = newSymbol;
    return StackState(
      symbols: newSymbols,
      lastOperation: 'replace with $newSymbol',
      operationType: StackOperationType.replace,
      maxStackSize: maxStackSize,
      hasOverflow: false,
      hasUnderflow: false,
    );
  }
}

/// Floating panel for stack visualization
class PDAStackPanel extends StatefulWidget {
  final StackState stackState;
  final String initialStackSymbol;
  final Set<String> stackAlphabet;
  final bool isSimulating;
  final int? highlightedIndex;
  final VoidCallback? onClear;

  const PDAStackPanel({
    super.key,
    required this.stackState,
    required this.initialStackSymbol,
    required this.stackAlphabet,
    this.isSimulating = false,
    this.highlightedIndex,
    this.onClear,
  });

  @override
  State<PDAStackPanel> createState() => _PDAStackPanelState();
}

class _PDAStackPanelState extends State<PDAStackPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _isPushAnimation = false;
  int _numPushedSymbols = 0; // Track how many symbols were pushed
  bool _isPopAnimation = false;
  List<String> _poppedSymbols = []; // Track symbols being popped for animation
  int? _highlightedIndex;

  // Swipe gesture tracking
  int? _swipingItemIndex;
  double _swipeOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _highlightedIndex = widget.highlightedIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(PDAStackPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.highlightedIndex != widget.highlightedIndex) {
      setState(() {
        _highlightedIndex = widget.highlightedIndex;
      });
    }

    if (oldWidget.stackState.symbols != widget.stackState.symbols) {
      // Detect push or pop operation
      final stackGrowth = widget.stackState.size - oldWidget.stackState.size;

      if (stackGrowth > 0) {
        // Push operation (stack grew)
        _isPushAnimation = true;
        _isPopAnimation = false;
        _numPushedSymbols = stackGrowth;
        _poppedSymbols = [];
      } else if (stackGrowth < 0) {
        // Pop operation (stack shrunk)
        _isPushAnimation = false;
        _isPopAnimation = true;
        _numPushedSymbols = 0;
        // Store the popped symbols for animation
        final numPopped = -stackGrowth;
        _poppedSymbols = oldWidget.stackState.symbols.sublist(
          oldWidget.stackState.symbols.length - numPopped,
        );
      } else {
        // Replace operation (size unchanged)
        _isPushAnimation = false;
        _isPopAnimation = false;
        _numPushedSymbols = 0;
        _poppedSymbols = [];
      }

      _animationController.forward(from: 0).then((_) {
        // Clear popped symbols after animation completes
        if (mounted) {
          setState(() {
            _poppedSymbols = [];
            _isPopAnimation = false;
          });
        }
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    // Auto-scroll to keep the stack top visible
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleItemTap(int index) {
    setState(() {
      // Toggle highlight: if tapping the same item, deselect; otherwise select
      _highlightedIndex = _highlightedIndex == index ? null : index;
    });
  }

  void _handleHorizontalDragStart(int index, DragStartDetails details) {
    setState(() {
      _swipingItemIndex = index;
      _swipeOffset = 0.0;
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffset += details.delta.dx;
      // Clamp to reasonable range (-80 to 80 pixels)
      _swipeOffset = _swipeOffset.clamp(-80.0, 80.0);
    });
  }

  void _handleHorizontalDragEnd(int index, DragEndDetails details) {
    // Detect swipe direction and velocity
    final velocity = details.primaryVelocity ?? 0;
    const threshold = 30.0; // Minimum swipe distance in pixels

    setState(() {
      if (_swipeOffset.abs() > threshold || velocity.abs() > 300) {
        // Swipe detected - determine direction
        if (_swipeOffset > 0 || velocity > 300) {
          // Swipe right - highlight item
          _highlightedIndex = index;
        } else if (_swipeOffset < 0 || velocity < -300) {
          // Swipe left - unhighlight if this item is highlighted
          if (_highlightedIndex == index) {
            _highlightedIndex = null;
          }
        }
      }
      // Reset swipe state
      _swipingItemIndex = null;
      _swipeOffset = 0.0;
    });
  }

  void _handleHorizontalDragCancel(int index) {
    setState(() {
      _swipingItemIndex = null;
      _swipeOffset = 0.0;
    });
  }

  /// Returns the staggered animation interval for a newly pushed item
  /// Items are staggered with 80ms delay between each
  Interval _getStaggeredInterval(int pushIndex) {
    const delayPerItem =
        0.08; // 80ms delay between items (relative to 300ms total)
    final begin = pushIndex * delayPerItem;
    final end = begin + (1.0 - (_numPushedSymbols - 1) * delayPerItem);
    return Interval(
      begin.clamp(0.0, 1.0),
      end.clamp(begin, 1.0),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 145, // Compact width for mobile
        constraints: const BoxConstraints(maxHeight: 200), // Reduced height
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.layers, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6), // Reduced spacing
                Expanded(
                  child: Text(
                    'Stack (${widget.stackState.size})',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13, // Compact font size
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isSimulating)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Divider(height: 10), // Reduced divider height
            // Warning Indicators
            if (widget.stackState.hasOverflow || widget.stackState.hasUnderflow)
              _buildWarningBanner(theme),
            // Stack Info Panel
            _buildStackInfo(theme),
            const Divider(height: 10), // Reduced divider height
            // Content
            Flexible(
              child: widget.stackState.isEmpty
                  ? Center(
                      child: Text(
                        'Empty\n(Z₀: ${widget.initialStackSymbol})',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11, // Compact font size
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      itemCount: widget.stackState.symbols.length +
                          (_isPopAnimation ? _poppedSymbols.length : 0),
                      itemBuilder: (context, index) {
                        // During pop animation, show popped items at the top
                        final bool isBeingPopped =
                            _isPopAnimation && index < _poppedSymbols.length;

                        final String symbol;
                        final bool isTop;
                        final int reversedIndex;

                        if (isBeingPopped) {
                          // Show popped symbols (from top of the list)
                          symbol =
                              _poppedSymbols[_poppedSymbols.length - 1 - index];
                          isTop = index == 0;
                          reversedIndex = -1; // Not in actual stack
                        } else {
                          // Show current stack symbols
                          final adjustedIndex = index -
                              (_isPopAnimation ? _poppedSymbols.length : 0);
                          reversedIndex = widget.stackState.symbols.length -
                              1 -
                              adjustedIndex;
                          symbol = widget.stackState.symbols[reversedIndex];
                          isTop = !_isPopAnimation && adjustedIndex == 0;
                        }

                        final isHighlighted = _highlightedIndex == index;
                        final isSwiping = _swipingItemIndex == index;

                        final cellPosition = index + 1;
                        final stackSize = widget.stackState.symbols.length +
                            (_isPopAnimation ? _poppedSymbols.length : 0);
                        final semanticsLabel = [
                          'Stack cell $cellPosition of $stackSize',
                          'symbol $symbol',
                          if (isTop) 'top of stack',
                          if (isHighlighted) 'highlighted',
                          if (isBeingPopped) 'being removed',
                        ].join(', ');
                        final semanticsHint = isHighlighted
                            ? 'Double tap to clear the highlight. Swipe left to unhighlight this stack cell.'
                            : 'Double tap to highlight this stack cell. Swipe right to highlight it.';

                        Widget itemWidget = Semantics(
                          label: semanticsLabel,
                          hint: semanticsHint,
                          button: true,
                          enabled: true,
                          selected: isHighlighted,
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _handleItemTap(index),
                            // Add swipe gesture detection
                            onHorizontalDragStart: (details) =>
                                _handleHorizontalDragStart(index, details),
                            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                            onHorizontalDragEnd: (details) =>
                                _handleHorizontalDragEnd(index, details),
                            onHorizontalDragCancel: () =>
                                _handleHorizontalDragCancel(index),
                            child: Transform.translate(
                              // Apply swipe offset for visual feedback
                              offset: Offset(
                                isSwiping ? _swipeOffset : 0.0,
                                0.0,
                              ),
                              child: Container(
                                // Keep each stack cell at Apple's 44pt minimum
                                // while preserving the swipe gesture behavior.
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                  minWidth: 44,
                                ),
                                margin: const EdgeInsets.only(
                                  bottom: 3,
                                ), // Reduced
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, // Reduced
                                        vertical: 8, // Reduced
                                      ),
                                      decoration: BoxDecoration(
                                        color: isHighlighted
                                            ? theme
                                                .colorScheme.secondaryContainer
                                            : isTop
                                                ? theme.colorScheme
                                                    .primaryContainer
                                                : theme.colorScheme
                                                    .surfaceContainerHighest,
                                        border: isHighlighted
                                            ? Border.all(
                                                color:
                                                    theme.colorScheme.secondary,
                                                width: 2,
                                              )
                                            : null,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Main content
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isTop) ...[
                                                Icon(
                                                  Icons.arrow_right,
                                                  size: 11,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                const SizedBox(width: 3),
                                              ],
                                              Flexible(
                                                child: Text(
                                                  symbol,
                                                  style: TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontWeight:
                                                        isTop || isHighlighted
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                    fontSize: 11,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_isPushAnimation &&
                                              index < _numPushedSymbols)
                                            Positioned(
                                              top: -4,
                                              left: -4,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme.secondary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_upward,
                                                  size: 8,
                                                  color: theme
                                                      .colorScheme.onSecondary,
                                                ),
                                              ),
                                            ),
                                          if (isBeingPopped)
                                            Positioned(
                                              top: -4,
                                              right: -4,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme.tertiary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_downward,
                                                  size: 8,
                                                  color: theme
                                                      .colorScheme.onTertiary,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isTop &&
                                        !_isPushAnimation &&
                                        !isBeingPopped)
                                      Positioned(
                                        top: -5,
                                        right: -5,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'TOP',
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (isSwiping) ...[
                                      if (_swipeOffset < -10)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme.errorContainer
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              alignment: Alignment.centerRight,
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Icon(
                                                Icons.highlight_remove,
                                                size: 16,
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_swipeOffset > 10)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme
                                                    .primaryContainer
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Icon(
                                                Icons.highlight,
                                                size: 16,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        // Apply staggered animations to newly pushed items
                        if (_isPushAnimation && index < _numPushedSymbols) {
                          // This item is one of the newly pushed symbols
                          // Calculate reverse push index (top item gets index 0, next gets 1, etc.)
                          final pushIndex = _numPushedSymbols - 1 - index;

                          // Create staggered animation interval
                          final interval = _getStaggeredInterval(pushIndex);

                          // Create staggered slide animation
                          final staggeredSlideAnimation = Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: interval,
                            ),
                          );

                          // Create staggered fade animation
                          final staggeredFadeAnimation = CurvedAnimation(
                            parent: _animationController,
                            curve: interval,
                          );

                          itemWidget = SlideTransition(
                            position: staggeredSlideAnimation,
                            child: FadeTransition(
                              opacity: staggeredFadeAnimation,
                              child: itemWidget,
                            ),
                          );

                          return itemWidget;
                        }

                        // Apply fade-out and scale animations to popped items
                        if (isBeingPopped) {
                          // Create fade-out animation (1.0 -> 0.0)
                          final fadeOutAnimation =
                              Tween<double>(begin: 1.0, end: 0.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeIn,
                            ),
                          );

                          // Create scale animation (1.0 -> 0.8)
                          final scaleAnimation =
                              Tween<double>(begin: 1.0, end: 0.8).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeIn,
                            ),
                          );

                          itemWidget = FadeTransition(
                            opacity: fadeOutAnimation,
                            child: ScaleTransition(
                              scale: scaleAnimation,
                              child: itemWidget,
                            ),
                          );

                          return itemWidget;
                        }

                        // No animation for items that weren't just pushed or popped
                        return itemWidget;
                      },
                    ),
            ),

            if (widget.onClear != null) ...[
              const Divider(height: 10), // Reduced
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 72,
                  minHeight: 44,
                ),
                child: TextButton(
                  onPressed: widget.onClear,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(72, 44),
                    padding: EdgeInsets.zero,
                    foregroundColor: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Semantics(
                    label: 'Clear stack',
                    hint: 'Removes every symbol from the stack view.',
                    button: true,
                    enabled: true,
                    excludeSemantics: true,
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds warning banner for overflow/underflow conditions
  Widget _buildWarningBanner(ThemeData theme) {
    final isOverflow = widget.stackState.hasOverflow;
    final isUnderflow = widget.stackState.hasUnderflow;

    if (!isOverflow && !isUnderflow) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.error, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverflow ? Icons.error_outline : Icons.warning_amber_rounded,
            size: 14,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isOverflow
                  ? 'Overflow!\nMax: ${widget.stackState.maxStackSize}'
                  : 'Underflow!\nPop on empty',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds compact info panel showing top symbol, size, and last operation
  Widget _buildStackInfo(ThemeData theme) {
    final topSymbol = widget.stackState.top ?? '(empty)';
    final size = widget.stackState.size;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ), // More compact
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Top: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10, // Smaller for mobile
                ),
              ),
              Flexible(
                child: Text(
                  topSymbol,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11, // Slightly reduced
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1), // Reduced spacing
          Text(
            'Size: $size',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10, // Smaller for mobile
            ),
          ),
          if (widget.stackState.lastOperation != null) ...[
            const SizedBox(height: 1), // Reduced spacing
            Text(
              'Op: ${widget.stackState.lastOperation}', // Shortened label
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9, // Smaller for mobile
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
