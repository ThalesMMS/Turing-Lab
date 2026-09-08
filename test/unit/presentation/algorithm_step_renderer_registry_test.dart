import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/cyk_step.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_renderer_registry.dart';

void main() {
  group('AlgorithmStepRendererRegistry', () {
    test('register stores a renderer by payload type', () {
      final registry = AlgorithmStepRendererRegistry();

      registry.register<String>(_testRenderer);

      expect(registry.lookup(String), isNotNull);
      expect(registry.hasRenderer(String), true);
    });

    test('lookup returns null for unregistered payload types', () {
      final registry = AlgorithmStepRendererRegistry();

      expect(registry.lookup(String), isNull);
      expect(registry.hasRenderer(String), false);
    });

    test('clear removes registered renderers', () {
      final registry = AlgorithmStepRendererRegistry()
        ..register<String>(_testRenderer);

      registry.clear();

      expect(registry.lookup(String), isNull);
      expect(registry.hasRenderer(String), false);
    });

    test('registerProperties stores a renderer by algorithm type', () {
      final registry = AlgorithmStepRendererRegistry();

      registry.registerProperties(AlgorithmType.nfaToDfa, _propertiesRenderer);

      expect(registry.lookupProperties(AlgorithmType.nfaToDfa), isNotNull);
      expect(registry.hasPropertiesRenderer(AlgorithmType.nfaToDfa), true);
      expect(registry.hasPropertiesRenderer(AlgorithmType.regexToNfa), false);

      registry.clear();

      expect(registry.hasPropertiesRenderer(AlgorithmType.nfaToDfa), false);
    });

    test('withDefaults registers the CYK adapter and the conversion '
        'property renderers', () {
      final registry = AlgorithmStepRendererRegistry.withDefaults();

      expect(registry.hasRenderer(CYKStep), true);
      expect(registry.hasPropertiesRenderer(AlgorithmType.nfaToDfa), true);
      expect(
        registry.hasPropertiesRenderer(AlgorithmType.dfaMinimization),
        true,
      );
      expect(registry.hasPropertiesRenderer(AlgorithmType.regexToNfa), true);
      expect(registry.hasPropertiesRenderer(AlgorithmType.faToRegex), false);
    });
  });
}

Widget? _propertiesRenderer(BuildContext context, AlgorithmStep step) {
  return const SizedBox.shrink();
}

Widget _testRenderer(BuildContext context, AlgorithmStep step, Object payload) {
  return const SizedBox.shrink();
}
