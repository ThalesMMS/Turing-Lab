import 'dart:developer' as developer;

import '../models/simulation_highlight.dart';

typedef HighlightDispatcher = void Function(SimulationHighlight highlight);

typedef HighlightChannelFactory<TChannel extends HighlightChannel> = TChannel
    Function(HighlightDispatcher dispatcher);

/// Destination that consumes highlight payloads.
abstract class HighlightChannel {
  void send(SimulationHighlight highlight);

  void clear();
}

/// Adapter that forwards highlights to a callback.
class FunctionHighlightChannel implements HighlightChannel {
  FunctionHighlightChannel(this._dispatcher);

  final HighlightDispatcher _dispatcher;

  @override
  void clear() {
    _dispatcher(SimulationHighlight.empty);
  }

  @override
  void send(SimulationHighlight highlight) {
    _dispatcher(highlight);
  }
}

/// Runs [beforeActivity] before forwarding highlight activity to [delegate].
class InterceptingHighlightChannel implements HighlightChannel {
  InterceptingHighlightChannel({
    required this.delegate,
    required this.beforeActivity,
  });

  final HighlightChannel delegate;
  final void Function() beforeActivity;

  @override
  void clear() {
    beforeActivity();
    delegate.clear();
  }

  @override
  void send(SimulationHighlight highlight) {
    beforeActivity();
    delegate.send(highlight);
  }
}

/// Shared channel, counter, last-highlight, and logging plumbing.
class HighlightDispatchController<TChannel extends HighlightChannel> {
  HighlightDispatchController({
    required this.debugLabel,
    TChannel? channel,
    HighlightDispatcher? dispatcher,
    required HighlightChannelFactory<TChannel> channelFromDispatcher,
  })  : assert(
          channel == null || dispatcher == null,
          'Pass either a channel or a dispatcher, not both.',
        ),
        channel = channel ?? _channelFrom(dispatcher, channelFromDispatcher);

  final String debugLabel;
  TChannel? channel;
  int _dispatchCount = 0;
  SimulationHighlight? _lastHighlight;

  int get dispatchCount => _dispatchCount;

  SimulationHighlight? get lastHighlight => _lastHighlight;

  void log(String message) {
    logHighlightEvent(debugLabel, message);
  }

  void dispatch(SimulationHighlight highlight) {
    _dispatchCount++;
    _lastHighlight = highlight;
    log(
      'Dispatch #$_dispatchCount (states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    channel?.send(highlight);
  }

  void clear() {
    if (_dispatchCount > 0 || _lastHighlight != null) {
      log('Clearing highlight after $_dispatchCount dispatches');
    }
    _lastHighlight = null;
    channel?.clear();
  }

  static TChannel? _channelFrom<TChannel extends HighlightChannel>(
    HighlightDispatcher? dispatcher,
    HighlightChannelFactory<TChannel> channelFromDispatcher,
  ) {
    if (dispatcher == null) {
      return null;
    }
    return channelFromDispatcher(dispatcher);
  }
}

void logHighlightEvent(String source, String message) {
  assert(() {
    developer.log(message, name: source);
    return true;
  }());
}
