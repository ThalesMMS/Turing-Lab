import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/grammar/teaching/grammar_teaching_session_store.dart';
import 'package:turing_lab/injection/data_providers.dart';

void main() {
  test('provider exposes the core teaching-session store contract', () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(grammarTeachingSessionStoreProvider),
      isA<GrammarTeachingSessionStore>(),
    );
  });
}
