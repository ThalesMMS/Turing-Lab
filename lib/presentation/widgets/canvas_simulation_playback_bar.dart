import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../empty_string_notation.dart';
import 'automaton_workspace_scaffold.dart';
import '../../core/constants/monospace_typography.dart';

bool supportsCanvasSimulationPlayback(BuildContext context) {
  // Compact layouts on every platform offer the on-canvas playback; wide
  // layouts keep the side-panel trace as their primary simulation surface.
  return MediaQuery.sizeOf(context).width <
      AutomatonWorkspaceScaffold.mobileBreakpoint;
}

/// How one symbol of the simulated input word relates to the current step.
enum CanvasWordSymbolStatus { consumed, current, pending }

/// One symbol of the input word annotated for playback rendering.
class CanvasSimulationWordSymbol {
  const CanvasSimulationWordSymbol(this.symbol, this.status);

  final String symbol;
  final CanvasWordSymbolStatus status;
}

/// The input word annotated for a single playback step.
typedef CanvasSimulationWord = List<CanvasSimulationWordSymbol>;

class CanvasSimulationPlaybackBar extends StatefulWidget {
  const CanvasSimulationPlaybackBar({
    super.key,
    required this.stepCount,
    required this.onStepChanged,
    required this.onClose,
    this.initialStep = 0,
    this.stepDuration = const Duration(seconds: 1),
    this.words,
  }) : assert(stepCount > 0),
       assert(initialStep >= 0 && initialStep < stepCount),
       assert(words == null || words.length == stepCount);

  final int stepCount;
  final int initialStep;
  final Duration stepDuration;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onClose;

  /// Per-step annotated input word shown above the controls, when provided.
  final List<CanvasSimulationWord>? words;

  @override
  State<CanvasSimulationPlaybackBar> createState() =>
      _CanvasSimulationPlaybackBarState();
}

class _CanvasSimulationPlaybackBarState
    extends State<CanvasSimulationPlaybackBar> {
  late int _currentIndex;
  bool _isPlaying = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialStep;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onStepChanged(_currentIndex);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectStep(int index) {
    if (index < 0 || index >= widget.stepCount || index == _currentIndex) {
      return;
    }
    setState(() => _currentIndex = index);
    widget.onStepChanged(index);
  }

  void _stopPlaying() {
    _timer?.cancel();
    _timer = null;
    if (_isPlaying && mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlaying() {
    if (_isPlaying) {
      _stopPlaying();
      return;
    }
    if (_currentIndex == widget.stepCount - 1) {
      _selectStep(0);
    }
    setState(() => _isPlaying = true);
    _timer = Timer.periodic(widget.stepDuration, (_) {
      if (_currentIndex >= widget.stepCount - 1) {
        _stopPlaying();
        return;
      }
      _selectStep(_currentIndex + 1);
      if (_currentIndex == widget.stepCount - 1) {
        _stopPlaying();
      }
    });
  }

  Widget _buildWordStrip(BuildContext context, CanvasSimulationWord word) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontFamilyFallback: kMonospaceFontFamilyFallback,
      letterSpacing: 2,
    );
    if (word.isEmpty) {
      return Text(
        EmptyStringNotation.symbolOf(context),
        style: baseStyle?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.45),
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text.rich(
          TextSpan(
            children: [
              for (final symbol in word)
                TextSpan(
                  text: symbol.symbol,
                  style: switch (symbol.status) {
                    CanvasWordSymbolStatus.consumed => baseStyle?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: colorScheme.onSurface.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    CanvasWordSymbolStatus.current => baseStyle?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: colorScheme.primary,
                    ),
                    CanvasWordSymbolStatus.pending => baseStyle?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  },
                ),
            ],
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final canGoPrevious = _currentIndex > 0;
    final canGoNext = _currentIndex < widget.stepCount - 1;
    final word = widget.words == null ? null : widget.words![_currentIndex];

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.previousStep,
          onPressed: canGoPrevious
              ? () {
                  _stopPlaying();
                  _selectStep(_currentIndex - 1);
                }
              : null,
          icon: const Icon(Icons.skip_previous),
        ),
        IconButton(
          tooltip: _isPlaying ? l10n.pause : l10n.play,
          onPressed: widget.stepCount > 1 ? _togglePlaying : null,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        IconButton(
          tooltip: l10n.nextStep,
          onPressed: canGoNext
              ? () {
                  _stopPlaying();
                  _selectStep(_currentIndex + 1);
                }
              : null,
          icon: const Icon(Icons.skip_next),
        ),
        Expanded(
          child: Text(
            l10n.stepOf(_currentIndex + 1, widget.stepCount),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          tooltip: l10n.close,
          onPressed: () {
            _stopPlaying();
            widget.onClose();
          },
          icon: const Icon(Icons.close),
        ),
      ],
    );

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: word == null
            ? controls
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                    child: _buildWordStrip(context, word),
                  ),
                  controls,
                ],
              ),
      ),
    );
  }
}
