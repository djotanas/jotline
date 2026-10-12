import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/app.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/l10n/app_localizations.dart';

import 'helpers/lib_scan.dart';

void main() {
  testWidgets('PREF-06: root Scaffold still renders with an unavailable '
      'preferences store', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(
            UnavailablePreferencesStore(),
          ),
        ],
        child: const JotlineApp(),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('STRUCT-05: root Scaffold renders with no text or child widget', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JotlineApp()));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('STRUCT-05: root Scaffold background is bgMesa', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: JotlineApp()));

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(material.color?.toARGB32(), 0xFFF3F2EE);
  });

  testWidgets('THEME-07: app uses the Jotline light theme and no dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JotlineApp()));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.theme?.extension<JotColors>(), JotColors.light);
    expect(materialApp.darkTheme, isNull);
  });

  testWidgets(
    'THEME-08: a system text scale of 2.0 reaches the home unclamped',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(const ProviderScope(child: JotlineApp()));

      final context = tester.element(find.byType(Scaffold));

      expect(MediaQuery.textScalerOf(context).scale(17), 34);
      expect(MediaQuery.textScalerOf(context).scale(34), 68);
    },
  );

  testWidgets('RVP-02: root widget is wrapped in a ProviderScope', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JotlineApp()));

    expect(find.byType(ProviderScope), findsOneWidget);
  });

  testWidgets('STRUCT-06: pt_BR is the only supported locale', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: JotlineApp()));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(
      materialApp.supportedLocales,
      equals(AppLocalizations.supportedLocales),
    );
    expect(materialApp.supportedLocales, hasLength(1));
    expect(materialApp.supportedLocales.single.languageCode, 'pt');
  });

  test('STRUCT-01: lib/ top level contains only allowed entries', () {
    const allowed = {'main.dart', 'app.dart', 'core', 'features', 'l10n'};
    final entries = Directory('lib')
        .listSync()
        .map(
          (entity) => entity.uri.pathSegments.where((s) => s.isNotEmpty).last,
        )
        .toSet();

    expect(entries.difference(allowed), isEmpty);
  });

  test('STRUCT-03: every test file has a matching lib/ source file', () {
    final testFiles = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))
        .where((f) => !f.path.startsWith('test${Platform.pathSeparator}drift'));

    for (final file in testFiles) {
      final relative = file.path
          .replaceFirst('test${Platform.pathSeparator}', '')
          .replaceFirst('_test.dart', '.dart');

      expect(
        File('lib/$relative').existsSync(),
        isTrue,
        reason: 'missing lib/$relative for ${file.path}',
      );
    }
  });

  test('NET-01: no file under lib/ imports a network client', () {
    final forbidden = RegExp(r'package:(http|dio)/|\bHttpClient\b');

    final offenders = [
      for (final (file, source) in libSources())
        if (forbidden.hasMatch(source)) file.path,
    ];

    expect(offenders, isEmpty);
  });

  test(
    'NET-02: pubspec.yaml lists neither http nor dio under dependencies',
    () {
      final keys = <String>[];
      var inDependencies = false;
      for (final line in File('pubspec.yaml').readAsLinesSync()) {
        if (RegExp(r'^\S').hasMatch(line)) {
          inDependencies = line.trimRight() == 'dependencies:';
          continue;
        }
        final key = RegExp('^  ([A-Za-z0-9_]+):').firstMatch(line)?.group(1);
        if (inDependencies && key != null) keys.add(key);
      }

      expect(keys, contains('flutter_riverpod'));
      expect(keys, isNot(contains('http')));
      expect(keys, isNot(contains('dio')));
    },
  );
}
