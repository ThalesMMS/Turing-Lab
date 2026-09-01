import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/utils/epsilon_utils.dart';
import 'package:turing_lab/presentation/empty_string_notation.dart';
import 'package:turing_lab/presentation/providers/empty_string_symbol_provider.dart';

void main() {
  group('empty-string preference migration', () {
    test(
      'keeps a valid current value and removes the stale legacy key',
      () async {
        final store = _FakeEmptyStringSymbolStore({
          kEmptyStringSymbolPreferenceKey: kLambdaSymbol,
          kLegacyEpsilonSymbolPreferenceKey: kEpsilonSymbol,
        });

        final result = await migrateEmptyStringSymbolPreferences(store);

        expect(result, kLambdaSymbol);
        expect(store.values[kEmptyStringSymbolPreferenceKey], kLambdaSymbol);
        expect(
          store.values,
          isNot(contains(kLegacyEpsilonSymbolPreferenceKey)),
        );
      },
    );

    test('stores a valid legacy value before removing its key', () async {
      final store = _FakeEmptyStringSymbolStore({
        kLegacyEpsilonSymbolPreferenceKey: kLambdaSymbol,
      });

      final result = await migrateEmptyStringSymbolPreferences(store);

      expect(result, kLambdaSymbol);
      expect(store.operations, [
        'set:$kEmptyStringSymbolPreferenceKey=$kLambdaSymbol',
        'remove:$kLegacyEpsilonSymbolPreferenceKey',
      ]);
    });

    test(
      'does not remove a valid legacy value when migration write fails',
      () async {
        final store = _FakeEmptyStringSymbolStore({
          kLegacyEpsilonSymbolPreferenceKey: kLambdaSymbol,
        }, failWrites: true);

        final result = await migrateEmptyStringSymbolPreferences(store);

        expect(result, kLambdaSymbol);
        expect(store.values[kLegacyEpsilonSymbolPreferenceKey], kLambdaSymbol);
        expect(store.values, isNot(contains(kEmptyStringSymbolPreferenceKey)));
      },
    );

    test(
      'repairs malformed values to the documented epsilon default',
      () async {
        final store = _FakeEmptyStringSymbolStore({
          kEmptyStringSymbolPreferenceKey: 'broken',
          kLegacyEpsilonSymbolPreferenceKey: 'also-broken',
        });

        final result = await migrateEmptyStringSymbolPreferences(store);

        expect(result, kEpsilonSymbol);
        expect(store.values[kEmptyStringSymbolPreferenceKey], kEpsilonSymbol);
        expect(
          store.values,
          isNot(contains(kLegacyEpsilonSymbolPreferenceKey)),
        );
      },
    );
  });

  group('EmptyStringSymbolNotifier', () {
    test('publishes a new value only after persistence succeeds', () async {
      final store = _FakeEmptyStringSymbolStore({
        kEmptyStringSymbolPreferenceKey: kEpsilonSymbol,
      });
      final notifier = EmptyStringSymbolNotifier(store);
      addTearDown(notifier.dispose);

      await notifier.setSymbol(kLambdaSymbol);

      expect(notifier.state, kLambdaSymbol);
      expect(store.values[kEmptyStringSymbolPreferenceKey], kLambdaSymbol);
    });

    test('keeps the previous value when persistence fails', () async {
      final store = _FakeEmptyStringSymbolStore({
        kEmptyStringSymbolPreferenceKey: kEpsilonSymbol,
      }, failWrites: true);
      final notifier = EmptyStringSymbolNotifier(store);
      addTearDown(notifier.dispose);

      await expectLater(
        notifier.setSymbol(kLambdaSymbol),
        throwsA(isA<StateError>()),
      );

      expect(notifier.state, kEpsilonSymbol);
      expect(store.values[kEmptyStringSymbolPreferenceKey], kEpsilonSymbol);
    });
  });
}

class _FakeEmptyStringSymbolStore implements EmptyStringSymbolStore {
  _FakeEmptyStringSymbolStore(
    Map<String, String> initialValues, {
    this.failWrites = false,
  }) : values = Map.of(initialValues);

  final Map<String, String> values;
  final bool failWrites;
  final List<String> operations = [];

  @override
  String? getString(String key) => values[key];

  @override
  Future<bool> remove(String key) async {
    operations.add('remove:$key');
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    operations.add('set:$key=$value');
    if (failWrites) return false;
    values[key] = value;
    return true;
  }
}
