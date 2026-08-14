//
//  direction_icon.dart
//  Turing Lab
//
//  Ícones visuais para direções de movimento da Máquina de Turing (L/R/S)
//  com cores diferenciadas e tooltips.
//
//  Created for Phase 1 improvements - November 2025
//

import 'package:flutter/material.dart';
import '../../../core/models/tm_transition.dart';

/// Helper para ícones e cores de direção
class TMDirectionHelper {
  const TMDirectionHelper._();

  /// Retorna ícone para uma direção
  static IconData getIcon(TapeDirection direction) {
    switch (direction) {
      case TapeDirection.left:
        return Icons.arrow_back;
      case TapeDirection.right:
        return Icons.arrow_forward;
      case TapeDirection.stay:
        return Icons.radio_button_checked;
    }
  }

  /// Retorna cor para uma direção
  static Color getColor(TapeDirection direction) {
    switch (direction) {
      case TapeDirection.left:
        return Colors.blue;
      case TapeDirection.right:
        return Colors.green;
      case TapeDirection.stay:
        return Colors.grey;
    }
  }

  /// Retorna tooltip/label para uma direção
  static String getLabel(TapeDirection direction) {
    switch (direction) {
      case TapeDirection.left:
        return 'Left (L)';
      case TapeDirection.right:
        return 'Right (R)';
      case TapeDirection.stay:
        return 'Stay (S)';
    }
  }

  /// Retorna símbolo de texto simples
  static String getSymbol(TapeDirection direction) {
    switch (direction) {
      case TapeDirection.left:
        return '←';
      case TapeDirection.right:
        return '→';
      case TapeDirection.stay:
        return '⊙';
    }
  }
}

/// Widget de ícone de direção
class TMDirectionIcon extends StatelessWidget {
  final TapeDirection direction;
  final double size;
  final bool showLabel;
  final bool compact;

  const TMDirectionIcon({
    super.key,
    required this.direction,
    this.size = 16,
    this.showLabel = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = TMDirectionHelper.getColor(direction);
    final icon = TMDirectionHelper.getIcon(direction);
    final label = TMDirectionHelper.getLabel(direction);

    if (compact) {
      return Icon(icon, size: size, color: color);
    }

    if (!showLabel) {
      return Tooltip(
        message: label,
        child: Icon(icon, size: size, color: color),
      );
    }

    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 4),
          Text(
            direction.name.toUpperCase()[0], // L, R, ou S
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de indicador de direção com texto e ícone
class TMDirectionIndicator extends StatelessWidget {
  final TapeDirection direction;
  final bool showIcon;
  final bool showText;
  final double iconSize;
  final double fontSize;

  const TMDirectionIndicator({
    super.key,
    required this.direction,
    this.showIcon = true,
    this.showText = true,
    this.iconSize = 16,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final color = TMDirectionHelper.getColor(direction);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon)
          Icon(
            TMDirectionHelper.getIcon(direction),
            size: iconSize,
            color: color,
          ),
        if (showIcon && showText) const SizedBox(width: 4),
        if (showText)
          Text(
            TMDirectionHelper.getLabel(direction),
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

/// Chip de direção para uso em listas/grids
class TMDirectionChip extends StatelessWidget {
  final TapeDirection direction;
  final VoidCallback? onTap;
  final bool selected;

  const TMDirectionChip({
    super.key,
    required this.direction,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = TMDirectionHelper.getColor(direction);
    final symbol = TMDirectionHelper.getSymbol(direction);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              direction.name.toUpperCase()[0],
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seletor de direção com as 3 opções
class TMDirectionSelector extends StatelessWidget {
  final TapeDirection selected;
  final ValueChanged<TapeDirection> onChanged;
  final bool compact;

  const TMDirectionSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSelector(context);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TapeDirection.values.map((direction) {
        return TMDirectionChip(
          direction: direction,
          selected: selected == direction,
          onTap: () => onChanged(direction),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSelector(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TapeDirection.values.map((direction) {
        final isSelected = selected == direction;
        final color = TMDirectionHelper.getColor(direction);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: IconButton(
            icon: Icon(TMDirectionHelper.getIcon(direction)),
            color: color,
            iconSize: 20,
            style: IconButton.styleFrom(
              backgroundColor: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.transparent,
              side: isSelected ? BorderSide(color: color, width: 2) : null,
            ),
            onPressed: () => onChanged(direction),
          ),
        );
      }).toList(),
    );
  }
}
