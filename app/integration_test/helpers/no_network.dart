import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/app.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';

import '../../test/helpers/test_app.dart';

class _ForbiddenHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('E2E-02: the app attempted a network call');
  }
}

/// Makes any `HttpClient()` created while the flow runs throw, so a network
/// attempt fails the test (E2E-02). Call it from `setUp`.
void forbidNetwork() {
  HttpOverrides.global = _ForbiddenHttpOverrides();
  addTearDown(() => HttpOverrides.global = null);
}

/// Pumps [JotlineApp] on a [TestApp] (in-memory database, fixed clock and
/// sequential ids) and the unavailable preferences store, and returns the
/// [TestApp] for seeding and assertions. It registers the test text input,
/// which is not registered in profile mode, so `enterText` works there.
Future<TestApp> pumpJotlineWithoutNetwork(
  WidgetTester tester, {
  DateTime? now,
}) async {
  tester.testTextInput.register();
  final app = TestApp(now: now);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await app.db.close();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...app.overrides,
        preferencesStoreProvider.overrideWithValue(
          UnavailablePreferencesStore(),
        ),
      ],
      child: const JotlineApp(),
    ),
  );
  await settle(tester);
  return app;
}

/// Lets the database streams deliver and the animations finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}
