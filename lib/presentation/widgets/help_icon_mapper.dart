//
//  help_icon_mapper.dart
//  Turing Lab
//
//  Centralized icon mapping for help content identifiers to Material icons.
//
//  Thales Matheus Mendonça Santos - February 2026
//
import 'package:flutter/material.dart';

IconData helpIconData(String icon) {
  final iconKey = icon.trim().toLowerCase();
  switch (iconKey) {
    case 'help':
      return Icons.help_outline;
    case 'info':
      return Icons.info_outline;
    case 'keyboard':
      return Icons.keyboard;
    case 'lightbulb':
      return Icons.lightbulb_outline;
    case 'school':
      return Icons.school_outlined;
    case 'tips_and_updates':
      return Icons.tips_and_updates_outlined;
    case 'touch_app':
      return Icons.touch_app;
    case 'mouse':
      return Icons.mouse;
    case 'gesture':
      return Icons.gesture;
    case 'pan_tool':
      return Icons.pan_tool_outlined;
    case 'account_tree':
      return Icons.account_tree;
    case 'all_inclusive':
      return Icons.all_inclusive;
    case 'auto_awesome':
      return Icons.auto_awesome;
    case 'call_split':
      return Icons.call_split;
    case 'circle':
      return Icons.circle;
    case 'code':
      return Icons.code;
    case 'compress':
      return Icons.compress;
    case 'delete':
      return Icons.delete;
    case 'linear_scale':
      return Icons.linear_scale;
    case 'more_horiz':
      return Icons.more_horiz;
    case 'save':
      return Icons.save;
    case 'storage':
      return Icons.storage;
    case 'sync_alt':
      return Icons.sync_alt;
    case 'text_fields':
      return Icons.text_fields;
    case 'transform':
      return Icons.transform;
    case 'view_agenda':
      return Icons.view_agenda;
    case 'view_headline':
      return Icons.view_headline;
    case 'pattern':
      return Icons.pattern;
    case 'undo':
      return Icons.undo;
    case 'redo':
      return Icons.redo;
    case 'fit_screen':
      return Icons.fit_screen;
    case 'center_focus_strong':
      return Icons.center_focus_strong;
    case 'clear':
      return Icons.clear_all;
    case 'add_circle':
      return Icons.add_circle_outline;
    case 'arrow_forward':
      return Icons.arrow_forward;
    case 'play_arrow':
      return Icons.play_arrow;
    case 'build':
      return Icons.build_outlined;
    default:
      return Icons.help_outline;
  }
}
