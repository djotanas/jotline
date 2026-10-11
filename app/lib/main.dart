import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/app.dart';
import 'package:jotline/core/preferences/open_preferences_store.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/theme/font_licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final preferences = await openPreferencesStore();
  runApp(
    ProviderScope(
      overrides: [preferencesStoreProvider.overrideWithValue(preferences)],
      child: const JotlineApp(),
    ),
  );
}
