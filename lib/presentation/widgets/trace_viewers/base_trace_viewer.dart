//
//  base_trace_viewer.dart
//  Turing Lab
//
//  Provides the base widget reused by FA, PDA, and TM trace viewers,
//  handling collapse of long lists, step selection, and optional
//  SimulationHighlightService integration to sync canvas highlights.
//  Accepts a generic SimulationResult and a specialized row builder,
//  keeping consistent, accessible behavior for any algorithm that
//  produces step sequences.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';
import '../../../core/services/simulation_highlight_service.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../localization/locale_value_formatter.dart';
import '../common/simulation_speed_control.dart';
import '../common/timer_playback_controller.dart';
import 'timeline_scrubber.dart';

/// Base trace viewer with folding support used by FA/PDA/TM viewers.
class BaseTraceViewer extends StatefulWidget {
  final SimulationResult result;
  final String title;
  final Widget Function(SimulationStep step, int index) buildStepLine;
  final Widget? Function(BuildContext context, SimulationStep step, int index)?
  detailsBuilder;
  final SimulationHighlightService? highlightService;
  final double animationSpeed;
  final ValueChanged<int>? onStepChanged;
  final ValueChanged<double>? onSpeedChanged;
  final bool ensureSelectedStepVisible;

  const BaseTraceViewer({
    super.key,
    required this.result,
    required this.title,
    required this.buildStepLine,
    this.detailsBuilder,
    this.highlightService,
    this.animationSpeed = 1.0,
    this.onStepChanged,
    this.onSpeedChanged,
    this.ensureSelectedStepVisible = true,
  });

  @override
  State<BaseTraceViewer> createState() => _BaseTraceViewerState();
}

class _BaseTraceViewerState extends State<BaseTraceViewer> {
  static const int defaultFoldSize = 50;
  bool _folded = true;
  final int _foldSize = defaultFoldSize;
  int? _selectedIndex;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _selectedRowKey = GlobalKey();

  bool get _highlightEnabled =>
      widget.result.steps.isNotEmpty &&
      (widget.highlightService != null || widget.detailsBuilder != null);

  @override
  void initState() {
    super.initState();
    _selectedIndex = _highlightEnabled ? 0 : null;
    _scheduleSelectionSynchronization();
  }

  @override
  void dispose() {
    _cancelPlaybackTimer();
    _isPlaying = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BaseTraceViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.result, oldWidget.result) ||
        widget.highlightService != oldWidget.highlightService) {
      _cancelPlaybackTimer();
      setState(() {
        _selectedIndex = _highlightEnabled ? 0 : null;
        _isPlaying = false;
      });
      _scheduleSelectionSynchronization();
    }
  }

  void _handleStepTap(int index) {
    if (!_highlightEnabled) return;
    _updateSelectedIndex(index);
  }

  void _previousStep() {
    if (!_highlightEnabled) return;
    final current = _selectedIndex ?? 0;
    if (current > 0) {
      _updateSelectedIndex(current - 1);
    }
  }

  void _nextStep() {
    if (!_highlightEnabled) return;
    final current = _selectedIndex ?? 0;
    if (current < widget.result.steps.length - 1) {
      _updateSelectedIndex(current + 1);
    }
  }

  void _playSteps() {
    if (!_highlightEnabled) return;
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
    });
    _playStepAnimation();
  }

  void _pauseSteps() {
    _cancelPlaybackTimer();
    setState(() {
      _isPlaying = false;
    });
  }

  void _playStepAnimation() {
    _playbackTimer = schedulePlaybackStep(
      currentTimer: _playbackTimer,
      isPlaying: () => _isPlaying,
      isMounted: () => mounted,
      canAdvance: () => (_selectedIndex ?? 0) < widget.result.steps.length - 1,
      delay: Duration(milliseconds: (1000 / widget.animationSpeed).round()),
      clearTimer: () => _playbackTimer = null,
      advance: () {
        _updateSelectedIndex((_selectedIndex ?? 0) + 1, fromPlayback: true);
      },
      stop: () {
        setState(() {
          _isPlaying = false;
        });
      },
      scheduleNext: _playStepAnimation,
    );
  }

  void _resetSteps() {
    if (!_highlightEnabled) {
      widget.highlightService?.clear();
      return;
    }
    _updateSelectedIndex(0);
  }

  void _updateSelectedIndex(
    int index, {
    bool emitHighlight = true,
    bool fromPlayback = false,
  }) {
    if (!fromPlayback) {
      _cancelPlaybackTimer();
    }
    setState(() {
      _selectedIndex = index;
      if (!fromPlayback) {
        _isPlaying = false;
      }
    });
    if (emitHighlight) {
      widget.highlightService?.emitFromSteps(widget.result.steps, index);
    }
    widget.onStepChanged?.call(index);
    _scheduleSelectedRowVisibility();
    if (!fromPlayback) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        appLocalizationsOf(
          context,
        ).stepOf(index + 1, widget.result.steps.length),
        Directionality.of(context),
      );
    }
  }

  void _cancelPlaybackTimer() {
    _playbackTimer = cancelPlaybackTimer(_playbackTimer);
  }

  void _scheduleSelectionSynchronization() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = _selectedIndex;
      if (index == null || index >= widget.result.steps.length) {
        widget.highlightService?.clear();
        return;
      }
      widget.highlightService?.emitFromSteps(widget.result.steps, index);
      widget.onStepChanged?.call(index);
      _scheduleSelectedRowVisibility();
    });
  }

  void _scheduleSelectedRowVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_folded) {
        _scrollController.jumpTo(0);
      } else {
        final index = _selectedIndex ?? 0;
        final approximateOffset = index * 48.0;
        _scrollController.jumpTo(
          approximateOffset.clamp(
            0,
            _scrollController.position.maxScrollExtent,
          ),
        );
      }
      if (!widget.ensureSelectedStepVisible) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final selectedContext = _selectedRowKey.currentContext;
        if (!mounted || selectedContext == null) return;
        Scrollable.ensureVisible(
          selectedContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
        );
      });
    });
  }

  void _toggleFolded() {
    setState(() => _folded = !_folded);
    _scheduleSelectedRowVisibility();
  }

  Widget _buildNavigationControls(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final current = _selectedIndex ?? 0;
    final maxIndex = widget.result.steps.length - 1;
    final previousButton = IconButton(
      onPressed: current > 0 ? _previousStep : null,
      icon: const Icon(Icons.skip_previous),
      tooltip: l10n.previousStep,
      iconSize: 20,
    );
    final playButton = IconButton(
      onPressed: _isPlaying ? _pauseSteps : _playSteps,
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      tooltip: _isPlaying ? l10n.pause : l10n.play,
      iconSize: 20,
    );
    final nextButton = IconButton(
      onPressed: current < maxIndex ? _nextStep : null,
      icon: const Icon(Icons.skip_next),
      tooltip: l10n.nextStep,
      iconSize: 20,
    );
    final stepCounter = Text(
      '${formatter.integer(current + 1)} / '
      '${formatter.integer(widget.result.steps.length)}',
      style: Theme.of(context).textTheme.bodySmall,
    );
    final resetButton = IconButton(
      onPressed: _resetSteps,
      icon: const Icon(Icons.refresh),
      tooltip: l10n.reset,
      iconSize: 20,
    );
    final leadingControls = <Widget>[
      previousButton,
      playButton,
      nextButton,
      const SizedBox(width: 8),
      stepCounter,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TimelineScrubber(
            currentStep: current,
            totalSteps: widget.result.steps.length,
            onStepChanged: _updateSelectedIndex,
            enabled: _highlightEnabled,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 280) {
                return Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [...leadingControls, resetButton],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [...leadingControls, const Spacer(), resetButton],
              );
            },
          ),
          if (widget.onSpeedChanged != null) ...[
            const SizedBox(height: 8),
            SimulationSpeedControl(
              currentSpeed: widget.animationSpeed,
              onSpeedChanged: widget.onSpeedChanged!,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final steps = widget.result.steps;
    final isAccepted = widget.result.accepted;
    final color = isAccepted ? Colors.green : Colors.red;
    final selectedIndex = _selectedIndex ?? 0;
    final visibleStart = _folded && selectedIndex > 0 ? selectedIndex : 0;
    final visibleCount = _folded
        ? (steps.length - visibleStart).clamp(0, _foldSize)
        : steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isAccepted ? Icons.check_circle : Icons.cancel,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (steps.length > defaultFoldSize)
              TextButton.icon(
                onPressed: _toggleFolded,
                icon: Icon(_folded ? Icons.unfold_more : Icons.unfold_less),
                label: Text(_folded ? l10n.expand : l10n.collapse),
              ),
          ],
        ),
        if (_highlightEnabled) _buildNavigationControls(context),
        const SizedBox(height: 8),
        if (steps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.noStepsRecorded,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: visibleCount,
              itemBuilder: (context, visibleIndex) {
                final index = visibleStart + visibleIndex;
                final step = steps[index];
                final isSelected = _highlightEnabled && _selectedIndex == index;
                return Semantics(
                  key: isSelected ? _selectedRowKey : null,
                  selected: isSelected,
                  label: isSelected
                      ? formatter.integersInLocalizedText(
                          l10n.activeStepOf(index + 1, steps.length),
                          [index + 1, steps.length],
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: _highlightEnabled
                          ? () => _handleStepTap(index)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: isSelected
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 1.2,
                                  ),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.08),
                                )
                              : const BoxDecoration(),
                          child: widget.buildStepLine(step, index),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_folded && steps.length > visibleCount)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              formatter.integersInLocalizedText(
                l10n.hiddenStepsSummary(
                  visibleStart,
                  steps.length - visibleStart - visibleCount,
                ),
                [visibleStart, steps.length - visibleStart - visibleCount],
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        if (_highlightEnabled && widget.detailsBuilder != null) ...[
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final index = (_selectedIndex ?? 0).clamp(0, steps.length - 1);
              final step = steps[index];
              return widget.detailsBuilder!(context, step, index) ??
                  const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }
}
