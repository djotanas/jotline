import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/app.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';

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

/// Pumps [JotlineApp] on an in-memory database and the unavailable
/// preferences store, and returns the database for assertions. It registers
/// the test text input, which is not registered in profile mode, so
/// `enterText` works there. Passing the [reopen] database of an earlier
/// call starts the app again on the same data.
Future<AppDatabase> pumpJotlineWithoutNetwork(
  WidgetTester tester, {
  AppDatabase? reopen,
}) async {
  tester.testTextInput.register();
  final db =
      reopen ??
      AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
  if (reopen == null) {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
  } else {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferencesStoreProvider.overrideWithValue(
          UnavailablePreferencesStore(),
        ),
      ],
      child: const JotlineApp(),
    ),
  );
  await settle(tester);
  return db;
}

/// Lets the database streams deliver and the animations finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}
