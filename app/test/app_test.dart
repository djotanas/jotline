import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/app.dart';
import 'package:jotline/l10n/app_localizations.dart';

void main() {
  testWidgets('STRUCT-05: root Scaffold renders with no text or child widget', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JotlineApp()));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

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
        .where((f) => f.path.endsWith('_test.dart'));

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
}
