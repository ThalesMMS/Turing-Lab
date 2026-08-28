import 'package:flutter/material.dart';

import '../../core/formal_systems/formal_systems.dart';

final class RegisteredFileOperation {
  factory RegisteredFileOperation({
    required DocumentFormatId format,
    required DocumentFormatDirection direction,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'Must not be empty');
    }
    return RegisteredFileOperation._(
      format: format,
      direction: direction,
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }

  const RegisteredFileOperation._({
    required this.format,
    required this.direction,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final DocumentFormatId format;
  final DocumentFormatDirection direction;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}
