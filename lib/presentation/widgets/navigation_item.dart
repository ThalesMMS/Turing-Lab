//
//  navigation_item.dart
//  Turing Lab
//
//  Shared presentation data for workspace navigation controls.
//

import 'package:flutter/material.dart';

/// Localized label, icon, and description for a workspace destination.
class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.description,
  });

  final String label;
  final IconData icon;
  final String description;
}
