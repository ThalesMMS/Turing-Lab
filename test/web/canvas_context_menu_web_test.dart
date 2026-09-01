import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/platform/canvas_context_menu_policy.dart';

void main() {
  test(
    'browser driver disables and restores the native context menu',
    () async {
      final owner = Object();
      final policy = CanvasContextMenuPolicy();

      expect(BrowserContextMenu.enabled, isTrue);
      await policy.acquire(owner);
      expect(BrowserContextMenu.enabled, isFalse);
      await policy.release(owner);
      expect(BrowserContextMenu.enabled, isTrue);
    },
    skip: !kIsWeb,
  );
}
