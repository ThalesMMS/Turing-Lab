import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/platform/canvas_context_menu_policy.dart';

void main() {
  test('keeps the menu disabled until the final canvas releases it', () async {
    final applied = <bool>[];
    final policy = CanvasContextMenuPolicy(
      setEnabled: (enabled) async => applied.add(enabled),
    );
    final firstCanvas = Object();
    final secondCanvas = Object();

    await policy.acquire(firstCanvas);
    await policy.acquire(secondCanvas);
    await policy.release(firstCanvas);

    expect(policy.ownerCount, 1);
    expect(applied, [false]);

    await policy.release(secondCanvas);

    expect(policy.ownerCount, 0);
    expect(applied, [false, true]);
  });

  test('coalesces ownership changes queued in the same event turn', () async {
    final applied = <bool>[];
    final policy = CanvasContextMenuPolicy(
      setEnabled: (enabled) async => applied.add(enabled),
    );
    final firstCanvas = Object();
    final secondCanvas = Object();

    policy.acquire(firstCanvas);
    policy.release(firstCanvas);
    policy.acquire(secondCanvas);
    await policy.settled;

    expect(policy.ownerCount, 1);
    expect(applied, [false]);

    await policy.release(secondCanvas);
    expect(applied, [false, true]);
  });
}
