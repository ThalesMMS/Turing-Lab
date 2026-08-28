import 'package:flutter/material.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/models/asset_example.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../content/example_suggested_simulations.dart';
import '../widgets/example_suggested_simulations_text.dart';

typedef TransducerExampleTextResolver =
    ({String name, String description}) Function(
      BuildContext context,
      AssetExample<Object> example,
    );

final class TransducerExamplesPanel<TDocument extends Object>
    extends StatefulWidget {
  const TransducerExamplesPanel({
    super.key,
    required this.catalog,
    required this.onLoad,
    this.textResolver,
    this.payloadFilter,
  });

  final ExampleCatalogCapability<TDocument>? catalog;
  final ValueChanged<TDocument> onLoad;
  final TransducerExampleTextResolver? textResolver;
  final bool Function(Object payload)? payloadFilter;

  @override
  State<TransducerExamplesPanel<TDocument>> createState() =>
      _TransducerExamplesPanelState<TDocument>();
}

final class _TransducerExamplesPanelState<TDocument extends Object>
    extends State<TransducerExamplesPanel<TDocument>> {
  Future<List<AssetExample<TDocument>>>? _examples;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TransducerExamplesPanel<TDocument> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.catalog, widget.catalog)) _load();
  }

  void _load() {
    _examples = widget.catalog?.loadExamples();
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final source = widget.catalog;
    if (source == null) {
      return Center(child: Text(l10n.transducerExamplesUnavailable));
    }
    return FutureBuilder<List<AssetExample<TDocument>>>(
      future: _examples,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.transducerExamplesLoadFailed),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _retry, child: Text(l10n.retry)),
              ],
            ),
          );
        }
        final examples = snapshot.data
            ?.where(
              (example) => widget.payloadFilter?.call(example.payload) ?? true,
            )
            .toList(growable: false);
        if (examples == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (examples.isEmpty) {
          return Center(child: Text(l10n.transducerExamplesEmpty));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: examples.length,
          itemBuilder: (context, index) {
            final example = examples[index];
            final resolved = widget.textResolver?.call(
              context,
              example as AssetExample<Object>,
            );
            final name =
                resolved?.name ??
                (example.nameMessage == null
                    ? example.name
                    : l10n.resolveStructuredMessage(example.nameMessage!));
            final description =
                resolved?.description ??
                (example.descriptionMessage == null
                    ? example.description
                    : l10n.resolveStructuredMessage(
                        example.descriptionMessage!,
                      ));
            final suggestions = ExampleSuggestedSimulations.resolve(example.id);
            return Card(
              key: ValueKey('transducer-example-${example.id}'),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final action = FilledButton.tonal(
                    onPressed: () => widget.onLoad(example.payload),
                    child: Text(l10n.transducerLoadExample),
                  );
                  final stacked =
                      constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20;
                  if (!stacked) {
                    return ListTile(
                      minTileHeight: 48,
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(description),
                          const SizedBox(height: 8),
                          ExampleSuggestedSimulationsText(
                            suggestions: suggestions,
                          ),
                        ],
                      ),
                      trailing: action,
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(description),
                        const SizedBox(height: 8),
                        ExampleSuggestedSimulationsText(
                          suggestions: suggestions,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: action,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
