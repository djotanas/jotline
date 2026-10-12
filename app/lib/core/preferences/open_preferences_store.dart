import 'dart:developer';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:jotline/core/preferences/hive_preferences_store.dart';
import 'package:jotline/core/preferences/preferences_store.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';

Future<PreferencesStore> openPreferencesStore({
  Future<Box<String>> Function()? openBox,
}) async {
  final open = openBox ?? _defaultOpenBox;
  try {
    return HivePreferencesStore(await open());
  } on Object catch (error, stackTrace) {
    log(
      'Failed to open the preferences box',
      error: error,
      stackTrace: stackTrace,
      name: 'jotline.preferences',
    );
    return UnavailablePreferencesStore();
  }
}

Future<Box<String>> _defaultOpenBox() async {
  await Hive.initFlutter();
  return await Hive.openBox<String>('preferences');
}
