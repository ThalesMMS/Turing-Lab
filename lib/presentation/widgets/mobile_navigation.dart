//
//  mobile_navigation.dart
//  Turing Lab
//
//  Fornece a barra inferior de navegação otimizada para dispositivos móveis,
//  apresentando itens configuráveis com ícones, rótulos e descrições para
//  suportar múltiplos módulos do aplicativo em telas compactas.
//  Aplica estética Material 3 com SafeArea, sombras sutis e destaque do item
//  ativo, garantindo acessibilidade e facilidade na expansão do menu.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../l10n/app_localizations_help.dart';

/// Mobile-optimized bottom navigation widget
class MobileNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;

  const MobileNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: IntrinsicHeight(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = currentIndex == index;

                  return Expanded(
                    child: _buildNavigationItem(
                      context,
                      item,
                      isSelected,
                      () => onTap(index),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    NavigationItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = jflapLocalizationsOf(context);
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.6);

    return Semantics(
      label: l10n.navigateTo(item.label),
      hint: item.description,
      button: true,
      enabled: true,
      selected: isSelected,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  item.icon,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class
class NavigationItem {
  final String label;
  final IconData icon;
  final String description;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.description,
  });
}
