import 'package:flutter/services.dart';

Future<void> setCanvasContextMenuEnabled(bool enabled) async {
  if (BrowserContextMenu.enabled == enabled) {
    return;
  }
  if (enabled) {
    await BrowserContextMenu.enableContextMenu();
  } else {
    await BrowserContextMenu.disableContextMenu();
  }
}
