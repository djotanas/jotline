import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';
import 'package:jotline/core/theme/jot_theme.dart';

import 'package:jotline/l10n/app_localizations.dart';

extension PumpJot on WidgetTester {
  Future<void> pumpJot(Widget widget, {List<Override> overrides = const []}) {
    return pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(
            UnavailablePreferencesStore(),
          ),
          ...overrides,
        ],
        child: MaterialApp(
          theme: buildJotTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget,
        ),
      ),
    );
  }
}
