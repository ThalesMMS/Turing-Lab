//
//  trace_persistence_service.dart
//  Turing Lab
//
//  Manages simulation history storage via SharedPreferences, preserving metadata, the current selection, and queries segmented by automaton or type.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/simulation_result.dart';
import '../../core/repositories/trace_repository.dart';

Object? _decodeJsonPayload(String payload) => jsonDecode(payload);

String _encodeJsonPayload(Object? value) => jsonEncode(value);

const int _jsonComputeThreshold = 16 * 1024;

Future<Object?> _decodeJson(String payload) {
  return payload.length < _jsonComputeThreshold
      ? Future<Object?>.value(_decodeJsonPayload(payload))
      : compute(_decodeJsonPayload, payload);
}

Future<String> _encodeJson(Object? value) {
  return _estimateJsonPayloadLength(value) < _jsonComputeThreshold
      ? Future<String>.value(_encodeJsonPayload(value))
      : compute(_encodeJsonPayload, value);
}

int _estimateJsonPayloadLength(Object? value) {
  if (value == null) return 4;
  if (value is String) return value.length + 2;
  if (value is num || value is bool) return value.toString().length;

  var length = 2;
  if (value is List) {
    for (final item in value) {
      length += _estimateJsonPayloadLength(item) + 1;
      if (length >= _jsonComputeThreshold) return length;
    }
    return length;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      length += entry.key.toString().length + 3;
      length += _estimateJsonPayloadLength(entry.value) + 1;
      if (length >= _jsonComputeThreshold) return length;
    }
  }
  return length;
}

/// Service for persisting and managing traces across different automaton types
class TracePersistenceService implements TraceRepository {
  static const String _traceHistoryKey = 'trace_history';
  static const String _currentTraceKey = 'current_trace';
  static const String _traceMetadataKey = 'trace_metadata';
  static const String _legacyTraceHistoryKey = 'simulation_trace_history';
  static const String _legacyCurrentTraceKey = 'current_simulation_trace';
  static const int _maxHistorySize = 50; // Limit trace history size

  final SharedPreferences _prefs;
  Future<void> _traceWriteQueue = Future<void>.value();
  List<Map<String, dynamic>>? _historyCache;
  String? _historyCachePayload;
  bool _historyCacheUsesLegacyPayload = false;
  Map<String, Map<String, dynamic>>? _metadataCache;
  String? _metadataCachePayload;
  int _lastTraceIdMicros = 0;

  TracePersistenceService(this._prefs);

  /// Save a trace to history
  @override
  Future<void> saveTraceToHistory(
    SimulationResult trace, {
    String? automatonType,
    String? automatonId,
  }) async {
    await _enqueueTraceWrite(() async {
      await _saveTraceToHistory(
        trace,
        automatonType: automatonType,
        automatonId: automatonId,
      );
    });
  }

  Future<void> _saveTraceToHistory(
    SimulationResult trace, {
    String? automatonType,
    String? automatonId,
  }) async {
    try {
      final traceData = {
        'id': _nextTraceId(),
        'timestamp': DateTime.now().toIso8601String(),
        'automatonType': automatonType ?? 'unknown',
        'automatonId': automatonId,
        'trace': trace.toJson(),
      };

      final history = await getTraceHistory();
      history.insert(0, traceData); // Add to beginning

      // Limit history size
      if (history.length > _maxHistorySize) {
        history.removeRange(_maxHistorySize, history.length);
      }

      await _writeTraceHistory(history);
    } catch (e) {
      // Silently fail - trace persistence is not critical
      if (kDebugMode) {
        debugPrint('Failed to save trace: $e');
      }
    }
  }

  /// Get all trace history
  @override
  Future<List<Map<String, dynamic>>> getTraceHistory() async {
    final currentPayload = _prefs.getString(_traceHistoryKey);
    final usesLegacyPayload = currentPayload == null;
    final payload = currentPayload ?? _prefs.getString(_legacyTraceHistoryKey);
    final cached = _historyCache;
    if (cached != null &&
        payload == _historyCachePayload &&
        usesLegacyPayload == _historyCacheUsesLegacyPayload) {
      return _copyTraceHistory(cached);
    }

    try {
      final history = payload == null
          ? <Map<String, dynamic>>[]
          : usesLegacyPayload
              ? _sanitizeLegacyTraceList(
                  await _decodeJson(payload),
                )
              : _sanitizeTraceList(
                  await _decodeJson(payload),
                );
      _cacheTraceHistory(
        history,
        payload: payload,
        usesLegacyPayload: usesLegacyPayload,
      );
      return _copyTraceHistory(history);
    } catch (e) {
      _cacheTraceHistory(
        const [],
        payload: payload,
        usesLegacyPayload: usesLegacyPayload,
      );
      return [];
    }
  }

  /// Get traces for a specific automaton type
  Future<List<Map<String, dynamic>>> getTracesForType(
    String automatonType,
  ) async {
    final history = await getTraceHistory();
    return history
        .where((trace) => trace['automatonType'] == automatonType)
        .toList();
  }

  /// Get traces for a specific automaton
  Future<List<Map<String, dynamic>>> getTracesForAutomaton(
    String automatonId,
  ) async {
    final history = await getTraceHistory();
    return history
        .where((trace) => trace['automatonId'] == automatonId)
        .toList();
  }

  /// Save current trace (for step-by-step navigation)
  @override
  Future<void> saveCurrentTrace(
    SimulationResult trace,
    int currentStepIndex,
  ) async {
    await _enqueueTraceWrite(() async {
      try {
        final currentTraceData = {
          'trace': trace.toJson(),
          'currentStepIndex': currentStepIndex,
          'timestamp': DateTime.now().toIso8601String(),
        };

        final payload = await _encodeJson(currentTraceData);
        await _prefs.setString(_currentTraceKey, payload);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to save current trace: $e');
        }
      }
    });
  }

  /// Get current trace
  @override
  Future<Map<String, dynamic>?> getCurrentTrace() async {
    try {
      final currentTraceJson = _prefs.getString(_currentTraceKey);
      if (currentTraceJson == null) return _getLegacyCurrentTrace();

      final decoded = _asStringKeyedMap(
        await _decodeJson(currentTraceJson),
      );
      if (decoded == null) {
        return null;
      }

      final trace = _asStringKeyedMap(decoded['trace']);
      if (trace == null) {
        return null;
      }

      final rawStepIndex = decoded['currentStepIndex'];
      final currentStepIndex = rawStepIndex is int
          ? rawStepIndex
          : rawStepIndex is num
              ? rawStepIndex.toInt()
              : 0;

      return <String, dynamic>{
        ...decoded,
        'trace': trace,
        'currentStepIndex': currentStepIndex,
      };
    } catch (e) {
      return null;
    }
  }

  /// Clear current trace
  @override
  Future<void> clearCurrentTrace() async {
    await _enqueueTraceWrite(() async {
      await _prefs.remove(_currentTraceKey);
    });
  }

  /// Save trace metadata (for cross-simulator navigation)
  Future<void> saveTraceMetadata({
    required String traceId,
    required String automatonType,
    String? automatonId,
    String? inputString,
    bool? accepted,
    int? stepCount,
    Duration? executionTime,
  }) async {
    await _enqueueTraceWrite(() async {
      try {
        final metadata = {
          'traceId': traceId,
          'automatonType': automatonType,
          'automatonId': automatonId,
          'inputString': inputString,
          'accepted': accepted,
          'stepCount': stepCount,
          'executionTime': executionTime?.inMilliseconds,
          'timestamp': DateTime.now().toIso8601String(),
        };

        final existingMetadata = await getTraceMetadata();
        existingMetadata[traceId] = metadata;

        await _writeTraceMetadata(existingMetadata);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to save trace metadata: $e');
        }
      }
    });
  }

  /// Get trace metadata
  Future<Map<String, Map<String, dynamic>>> getTraceMetadata() async {
    final payload = _prefs.getString(_traceMetadataKey);
    final cached = _metadataCache;
    if (cached != null && payload == _metadataCachePayload) {
      return _copyTraceMetadata(cached);
    }

    try {
      final metadata = payload == null
          ? <String, Map<String, dynamic>>{}
          : _sanitizeMetadataMap(
              await _decodeJson(payload),
            );
      _metadataCache = _copyTraceMetadata(metadata);
      _metadataCachePayload = payload;
      return _copyTraceMetadata(metadata);
    } catch (e) {
      _metadataCache = <String, Map<String, dynamic>>{};
      _metadataCachePayload = payload;
      return {};
    }
  }

  /// Get trace by ID
  @override
  Future<Map<String, dynamic>?> getTraceById(String traceId) async {
    final history = await getTraceHistory();
    for (final trace in history) {
      if (trace['id'] == traceId) {
        return trace;
      }
    }
    return null;
  }

  /// Delete a trace from history
  Future<void> deleteTrace(String traceId) async {
    await _enqueueTraceWrite(() async {
      await _deleteTrace(traceId);
    });
  }

  Future<void> _deleteTrace(String traceId) async {
    try {
      final history = await getTraceHistory();
      history.removeWhere((trace) => trace['id'] == traceId);
      await _writeTraceHistory(history);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete trace: $e');
      }
    }
  }

  Future<void> _writeTraceHistory(
    List<Map<String, dynamic>> history,
  ) async {
    final payload = await _encodeJson(history);
    final succeeded = await _prefs.setString(_traceHistoryKey, payload);
    if (succeeded) {
      _cacheTraceHistory(
        history,
        payload: payload,
        usesLegacyPayload: false,
      );
    }
  }

  void _cacheTraceHistory(
    Iterable<Map<String, dynamic>> history, {
    required String? payload,
    required bool usesLegacyPayload,
  }) {
    _historyCache = _copyTraceHistory(history);
    _historyCachePayload = payload;
    _historyCacheUsesLegacyPayload = usesLegacyPayload;
  }

  List<Map<String, dynamic>> _copyTraceHistory(
    Iterable<Map<String, dynamic>> history,
  ) {
    return [
      for (final trace in history)
        {
          ...trace,
          if (trace['trace'] is Map)
            'trace': Map<String, dynamic>.from(trace['trace'] as Map),
        },
    ];
  }

  Future<void> _writeTraceMetadata(
    Map<String, Map<String, dynamic>> metadata,
  ) async {
    final payload = await _encodeJson(metadata);
    final succeeded = await _prefs.setString(_traceMetadataKey, payload);
    if (succeeded) {
      _metadataCache = _copyTraceMetadata(metadata);
      _metadataCachePayload = payload;
    }
  }

  Map<String, Map<String, dynamic>> _copyTraceMetadata(
    Map<String, Map<String, dynamic>> metadata,
  ) {
    return {
      for (final entry in metadata.entries) entry.key: Map.of(entry.value),
    };
  }

  Future<void> _enqueueTraceWrite(Future<void> Function() operation) {
    final queued = _traceWriteQueue.then((_) => operation());
    _traceWriteQueue = queued.catchError((_) {});
    return queued;
  }

  String _nextTraceId() {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    final nextMicros =
        nowMicros > _lastTraceIdMicros ? nowMicros : _lastTraceIdMicros + 1;
    _lastTraceIdMicros = nextMicros;
    return nextMicros.toString();
  }

  /// Clear all trace history
  @override
  Future<void> clearAllTraces() async {
    await _enqueueTraceWrite(() async {
      await _prefs.remove(_traceHistoryKey);
      await _prefs.remove(_currentTraceKey);
      await _prefs.remove(_traceMetadataKey);
      await _prefs.remove(_legacyTraceHistoryKey);
      await _prefs.remove(_legacyCurrentTraceKey);
      _cacheTraceHistory(
        const [],
        payload: null,
        usesLegacyPayload: true,
      );
      _metadataCache = <String, Map<String, dynamic>>{};
      _metadataCachePayload = null;
    });
  }

  /// Export trace history as JSON
  @override
  Future<String> exportTraceHistory() async {
    final history = await getTraceHistory();
    final metadata = await getTraceMetadata();

    return _encodeJson({
      'traces': history,
      'metadata': metadata,
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Import trace history from JSON
  @override
  Future<void> importTraceHistory(String jsonData) async {
    try {
      await _enqueueTraceWrite(() async {
        final decoded = await _decodeJson(jsonData);
        final data = (decoded as Map).cast<String, dynamic>();
        final traces = _sanitizeTraceList(data['traces'])
            .take(_maxHistorySize)
            .toList(growable: false);
        final metadata = _sanitizeMetadataMap(data['metadata']);

        await _writeTraceHistory(traces);
        await _writeTraceMetadata(metadata);
      });
    } catch (e) {
      throw Exception('Failed to import trace history: $e');
    }
  }

  /// Get trace statistics
  @override
  Future<Map<String, dynamic>> getTraceStatistics() async {
    final history = await getTraceHistory();
    final metadata = await getTraceMetadata();

    final typeCounts = <String, int>{};
    final totalTraces = history.length;
    final acceptedCount = history.where((trace) {
      final traceData = trace['trace'] as Map<String, dynamic>;
      return traceData['accepted'] == true;
    }).length;

    for (final trace in history) {
      final type = trace['automatonType'] as String;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }

    return {
      'totalTraces': totalTraces,
      'acceptedTraces': acceptedCount,
      'rejectedTraces': totalTraces - acceptedCount,
      'typeCounts': typeCounts,
      'metadataCount': metadata.length,
    };
  }

  List<Map<String, dynamic>> _sanitizeTraceList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    final traces = <Map<String, dynamic>>[];
    for (final entry in raw) {
      final map = _asStringKeyedMap(entry);
      if (map == null) {
        continue;
      }

      final nestedTrace = _asStringKeyedMap(map['trace']);
      if (nestedTrace == null) {
        continue;
      }

      traces.add(<String, dynamic>{
        ...map,
        'automatonType':
            map['automatonType'] is String ? map['automatonType'] : 'unknown',
        'trace': nestedTrace,
      });
    }
    return traces;
  }

  Map<String, dynamic>? _getLegacyCurrentTrace() {
    try {
      final currentTraceJson = _prefs.getString(_legacyCurrentTraceKey);
      if (currentTraceJson == null) {
        return null;
      }

      final trace = _asStringKeyedMap(jsonDecode(currentTraceJson));
      if (trace == null) {
        return null;
      }

      return <String, dynamic>{
        'trace': trace,
        'currentStepIndex': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> _sanitizeLegacyTraceList(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    final traces = <Map<String, dynamic>>[];
    for (final entry in raw) {
      final map = _asStringKeyedMap(entry);
      if (map == null) {
        continue;
      }

      final id = map['id'];
      final nestedTrace = _asStringKeyedMap(map['trace']);
      if (id is! String || nestedTrace == null) {
        continue;
      }

      traces.add(<String, dynamic>{
        ...map,
        'id': id,
        'automatonType': 'unknown',
        'automatonId': null,
        'trace': nestedTrace,
      });
    }
    return traces;
  }

  Map<String, Map<String, dynamic>> _sanitizeMetadataMap(dynamic raw) {
    if (raw is! Map) {
      return const {};
    }

    final metadata = <String, Map<String, dynamic>>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String) {
        continue;
      }

      final value = _asStringKeyedMap(entry.value);
      if (value != null) {
        metadata[key] = value;
      }
    }
    return metadata;
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        return null;
      }
      result[key] = entry.value;
    }
    return result;
  }
}
