//
//  determinism_badge.dart
//  Turing Lab
//
//  Badge visual indicando tipo de autômato finito (DFA/NFA/ε-NFA) com
//  informações detalhadas sobre determinismo e transições epsilon.
//
//  Created for Phase 1 improvements - November 2025
//

import 'package:flutter/material.dart';
import '../../../core/models/fsa.dart';

/// Informações sobre determinismo do autômato
class DeterminismInfo {
  final bool isDeterministic;
  final bool hasEpsilonTransitions;
  final List<String> nonDeterministicStates;
  final List<String> nonDeterministicSymbols;

  const DeterminismInfo({
    required this.isDeterministic,
    required this.hasEpsilonTransitions,
    this.nonDeterministicStates = const [],
    this.nonDeterministicSymbols = const [],
  });

  /// Tipo do autômato
  String get type {
    if (isDeterministic && !hasEpsilonTransitions) return 'DFA';
    if (hasEpsilonTransitions) return 'ε-NFA';
    return 'NFA';
  }

  /// Cor do badge
  Color get badgeColor {
    if (isDeterministic) return Colors.green;
    if (hasEpsilonTransitions) return Colors.purple;
    return Colors.blue;
  }

  /// Mensagem de ajuda
  String get helpMessage {
    if (isDeterministic) {
      return 'Deterministic Finite Automaton - each state has at most one transition per symbol';
    } else if (hasEpsilonTransitions) {
      return 'Nondeterministic Finite Automaton with ε-transitions';
    } else {
      return 'Nondeterministic Finite Automaton - some states have multiple transitions for the same symbol';
    }
  }

  /// Cria informações a partir de um FSA
  factory DeterminismInfo.fromFSA(FSA fsa) {
    return DeterminismInfo(
      isDeterministic: fsa.isDeterministic,
      hasEpsilonTransitions: fsa.hasEpsilonTransitions,
      nonDeterministicStates: _findNonDeterministicStates(fsa),
      nonDeterministicSymbols: _findNonDeterministicSymbols(fsa),
    );
  }

  static List<String> _findNonDeterministicStates(FSA fsa) {
    final result = <String>[];
    for (final state in fsa.states) {
      final transitions =
          fsa.fsaTransitions.where((t) => t.fromState.id == state.id).toList();

      final symbolGroups = <String, int>{};
      for (final transition in transitions) {
        for (final symbol in transition.inputSymbols) {
          symbolGroups[symbol] = (symbolGroups[symbol] ?? 0) + 1;
        }
      }

      if (symbolGroups.values.any((count) => count > 1)) {
        result.add(state.label);
      }
    }
    return result;
  }

  static List<String> _findNonDeterministicSymbols(FSA fsa) {
    final symbols = <String>{};
    for (final state in fsa.states) {
      final transitions =
          fsa.fsaTransitions.where((t) => t.fromState.id == state.id).toList();

      final symbolCounts = <String, int>{};
      for (final transition in transitions) {
        for (final symbol in transition.inputSymbols) {
          symbolCounts[symbol] = (symbolCounts[symbol] ?? 0) + 1;
        }
      }

      symbols.addAll(
        symbolCounts.entries.where((e) => e.value > 1).map((e) => e.key),
      );
    }
    return symbols.toList()..sort();
  }
}

/// Badge mostrando tipo de FSA (DFA/NFA/ε-NFA)
class FsaTypeBadge extends StatelessWidget {
  final DeterminismInfo info;
  final VoidCallback? onTap;
  final bool compact;

  const FsaTypeBadge({
    super.key,
    required this.info,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile || compact ? 8 : 12,
          vertical: isMobile || compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: info.badgeColor,
          borderRadius: BorderRadius.circular(isMobile || compact ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              info.isDeterministic ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: isMobile || compact ? 14 : 16,
            ),
            SizedBox(width: isMobile || compact ? 4 : 6),
            Text(
              info.type,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile || compact ? 12 : 14,
              ),
            ),
            if (onTap != null && !isMobile && !compact) ...[
              const SizedBox(width: 4),
              const Icon(Icons.help_outline, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Painel detalhado sobre determinismo
class NonDeterminismPanel extends StatelessWidget {
  final DeterminismInfo info;
  final VoidCallback? onClose;

  const NonDeterminismPanel({super.key, required this.info, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: info.badgeColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  info.isDeterministic ? Icons.check_circle : Icons.info,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Determinism Analysis',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type
                Row(
                  children: [
                    const Text(
                      'Type: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(info.type),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  info.helpMessage,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),

                // Features
                if (info.hasEpsilonTransitions) ...[
                  _buildFeature(
                    icon: Icons.call_split,
                    label: 'Has ε (epsilon) transitions',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 8),
                ],

                if (!info.isDeterministic &&
                    info.nonDeterministicStates.isNotEmpty) ...[
                  _buildFeature(
                    icon: Icons.warning,
                    label: 'Nondeterministic states:',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: info.nonDeterministicStates.map((state) {
                        return Chip(
                          label: Text(state),
                          backgroundColor: Colors.orange[100],
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (!info.isDeterministic &&
                    info.nonDeterministicSymbols.isNotEmpty) ...[
                  _buildFeature(
                    icon: Icons.content_copy,
                    label: 'Symbols with multiple transitions:',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: info.nonDeterministicSymbols.map((symbol) {
                        return Chip(
                          label: Text(symbol),
                          backgroundColor: Colors.blue[100],
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ),
                ],

                if (info.isDeterministic) ...[
                  _buildFeature(
                    icon: Icons.check_circle,
                    label: 'All transitions are deterministic',
                    color: Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    );
  }
}

/// Overlay do badge no canvas
class FSADeterminismOverlay extends StatefulWidget {
  final FSA? automaton;

  const FSADeterminismOverlay({super.key, required this.automaton});

  @override
  State<FSADeterminismOverlay> createState() => _FSADeterminismOverlayState();
}

class _FSADeterminismOverlayState extends State<FSADeterminismOverlay> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    if (widget.automaton == null) return const SizedBox.shrink();

    final info = DeterminismInfo.fromFSA(widget.automaton!);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Stack(
      children: [
        // Badge
        Positioned(
          top: isMobile ? 60 : 16,
          right: 16,
          child: FsaTypeBadge(
            info: info,
            onTap: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
          ),
        ),

        // Details panel
        if (_showDetails)
          Positioned(
            top: isMobile ? 100 : 60,
            right: 16,
            left: isMobile ? 16 : null,
            child: NonDeterminismPanel(
              info: info,
              onClose: () {
                setState(() {
                  _showDetails = false;
                });
              },
            ),
          ),
      ],
    );
  }
}
