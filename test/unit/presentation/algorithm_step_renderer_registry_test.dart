import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/cyk_step.dart';
import 'package:turing_lab/core/models/dfa_minimization_step.dart';
import 'package:turing_lab/core/models/nfa_to_dfa_step.dart';
import 'package:turing_lab/core/models/regex_to_nfa_step.dart';
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

    test('withDefaults registers known specialized step adapters', () {
      final registry = AlgorithmStepRendererRegistry.withDefaults();

      expect(registry.hasRenderer(CYKStep), true);
      expect(registry.hasRenderer(NFAToDFAStep), true);
      expect(registry.hasRenderer(DFAMinimizationStep), true);
      expect(registry.hasRenderer(RegexToNFAStep), true);
    });
  });
}

Widget _testRenderer(
  BuildContext context,
  AlgorithmStep step,
  Object payload,
) {
  return const SizedBox.shrink();
}
