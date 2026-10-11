import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';

void main() {
  test('PREF-02: an override returns the fake preferences store', () {
    final fake = UnavailablePreferencesStore();
    final container = ProviderContainer.test(
      overrides: [preferencesStoreProvider.overrideWithValue(fake)],
    );

    expect(container.read(preferencesStoreProvider), same(fake));
  });

  test('reading preferencesStoreProvider without an override throws '
      'UnimplementedError', () {
    final container = ProviderContainer.test();

    expect(
      () => container.read(preferencesStoreProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<UnimplementedError>(),
        ),
      ),
    );
  });
}
