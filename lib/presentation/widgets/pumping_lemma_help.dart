//
//  pumping_lemma_help.dart
//  Turing Lab
//
//  Constrói o painel de apoio teórico exibido ao lado do jogo do Lema do
//  Bombeamento, reunindo conteúdos de teoria, passos guiados e exemplos em uma
//  navegação por abas controlada localmente.
//  Fornece referências pedagógicas em português e inglês com estilo Material,
//  permitindo que estudantes alternem rapidamente entre explicações sem depender
//  de estado global ou serviços adicionais.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Help panel for the Pumping Lemma Game
class PumpingLemmaHelp extends ConsumerStatefulWidget {
  const PumpingLemmaHelp({super.key});

  @override
  ConsumerState<PumpingLemmaHelp> createState() => _PumpingLemmaHelpState();
}

class _PumpingLemmaHelpState extends ConsumerState<PumpingLemmaHelp> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          _buildTabBar(context),
          _buildTabContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Pumping Lemma Help',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab(context, 'Theory', 0),
          _buildTab(context, 'Steps', 1),
          _buildTab(context, 'Examples', 2),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, int index) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return _buildTheoryTab(context);
      case 1:
        return _buildStepsTab(context);
      case 2:
        return _buildExamplesTab(context);
      default:
        return _buildTheoryTab(context);
    }
  }

  Widget _buildTheoryTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            title: 'What is the Pumping Lemma?',
            content:
                'The Pumping Lemma is a fundamental theorem in formal language theory that provides a necessary condition for a language to be regular. It helps us prove that certain languages are not regular.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'The Theorem',
            content:
                'For any regular language L, there exists a constant p (called the pumping length) such that any string s in L with |s| ≥ p can be written as s = xyz where:\n\n• |xy| ≤ p\n• |y| > 0\n• xyᵏz ∈ L for all k ≥ 0',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'How to Use It',
            content:
                'To prove a language L is not regular:\n\n1. Assume L is regular\n2. Let p be the pumping length\n3. Choose a string s ∈ L with |s| ≥ p\n4. Show that for any decomposition s = xyz satisfying the conditions, there exists k ≥ 0 such that xyᵏz ∉ L\n5. This contradicts the pumping lemma, so L is not regular',
          ),
        ],
      ),
    );
  }

  Widget _buildStepsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStep(
            context,
            step: 1,
            title: 'Identify the Language',
            description:
                'Look at the given language and understand what strings it contains.',
            example:
                'L = {aⁿbⁿ | n ≥ 0} contains strings like ε, ab, aabb, aaabbb, etc.',
          ),
          const SizedBox(height: 16),
          _buildStep(
            context,
            step: 2,
            title: 'Assume Regularity',
            description:
                'Assume the language is regular and let p be the pumping length.',
            example: 'Assume L is regular with pumping length p.',
          ),
          const SizedBox(height: 16),
          _buildStep(
            context,
            step: 3,
            title: 'Choose a String',
            description:
                'Select a string s ∈ L with |s| ≥ p that will be hard to pump.',
            example: 'Choose s = aᵖbᵖ. This string has length 2p ≥ p.',
          ),
          const SizedBox(height: 16),
          _buildStep(
            context,
            step: 4,
            title: 'Consider Decompositions',
            description:
                'For any decomposition s = xyz with |xy| ≤ p and |y| > 0, analyze what happens when you pump.',
            example:
                'Since |xy| ≤ p, y consists only of a\'s. Pumping y gives more a\'s than b\'s.',
          ),
          const SizedBox(height: 16),
          _buildStep(
            context,
            step: 5,
            title: 'Find Contradiction',
            description:
                'Show that pumping leads to a string not in the language.',
            example:
                'xy²z = aᵖ⁺|y|bᵖ has more a\'s than b\'s, so it\'s not in L.',
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExample(
            context,
            title: 'Regular Language: L = {aⁿ | n ≥ 0}',
            description:
                'This language is regular because it can be recognized by a simple automaton.',
            proof:
                'For any string aᵖ, we can decompose it as x = ε, y = a, z = aᵖ⁻¹. Then xyᵏz = aᵏaᵖ⁻¹ = aᵖ⁺ᵏ⁻¹, which is always in L.',
            result: 'REGULAR',
            isRegular: true,
          ),
          const SizedBox(height: 16),
          _buildExample(
            context,
            title: 'Non-Regular Language: L = {aⁿbⁿ | n ≥ 0}',
            description:
                'This language is not regular because it requires counting.',
            proof:
                'Assume L is regular with pumping length p. Choose s = aᵖbᵖ. For any decomposition s = xyz with |xy| ≤ p, y consists only of a\'s. Pumping y gives xy²z = aᵖ⁺|y|bᵖ, which has more a\'s than b\'s and is not in L.',
            result: 'NOT REGULAR',
            isRegular: false,
          ),
          const SizedBox(height: 16),
          _buildExample(
            context,
            title: 'Non-Regular Language: L = {ww | w ∈ {a,b}*}',
            description:
                'This language contains strings that are concatenations of a word with itself.',
            proof:
                'Assume L is regular with pumping length p. Choose s = aᵖbaᵖb. For any decomposition s = xyz with |xy| ≤ p, y consists only of a\'s from the first part. Pumping y breaks the symmetry required for the string to be in L.',
            result: 'NOT REGULAR',
            isRegular: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int step,
    required String title,
    required String description,
    required String example,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '$step',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Example: $example',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(
    BuildContext context, {
    required String title,
    required String description,
    required String proof,
    required String result,
    required bool isRegular,
  }) {
    final color = isRegular ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'Proof:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(proof, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              result,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
