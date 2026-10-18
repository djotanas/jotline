import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotline/app.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:jotline/features/pages/presentation/page_list.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';
import 'package:jotline/features/search/presentation/search_result_row.dart';
import 'package:jotline/features/search/presentation/search_screen.dart';
import 'package:path_provider/path_provider.dart';

import '../helpers/flows.dart';
import 'frame_stats.dart';
import 'seed_library.dart';

const _bigNotebook = 'Biblioteca grande';
const _scrollTarget = 'Página 2000';

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  final limit = Stopwatch()..start();
  while (!condition()) {
    if (limit.elapsedMilliseconds > 30000) fail('Timed out waiting');
    await tester.pump(const Duration(milliseconds: 8));
  }
}

bool _editorLaidOut() {
  final editor = find.byType(BlockEditor).evaluate();
  if (editor.isEmpty) return false;
  return switch (editor.single.renderObject) {
    final RenderSliver sliver => sliver.geometry != null,
    final RenderBox box => box.hasSize,
    _ => false,
  };
}

/// Measures LOAD-02 to LOAD-06 on a seeded file database (LOAD-01), without
/// human pauses. Run it in profile mode:
/// `fvm flutter drive --driver=test_driver/perf_driver.dart
/// --target=integration_test/perf/large_library_test.dart --profile -d DEVICE_ID`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LOAD-02..LOAD-06: list, notebook, scroll, page and search '
      'with 10,000 pages', (tester) async {
    tester.testTextInput.register();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/large_library.sqlite');
    if (file.existsSync()) file.deleteSync();
    final db = AppDatabase(
      DatabaseConnection(NativeDatabase(file), closeStreamsSynchronously: true),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
      if (file.existsSync()) file.deleteSync();
    });
    final seeding = Stopwatch()..start();
    await seedLibrary(db);
    final seedMs = seeding.elapsedMilliseconds;

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
    final list = Stopwatch()..start();
    await _pumpUntil(
      tester,
      () => find.text(_bigNotebook).evaluate().isNotEmpty,
    );
    final listMs = list.elapsedMilliseconds;

    await tester.tap(find.text(_bigNotebook).first);
    final notebook = Stopwatch()..start();
    await _pumpUntil(tester, () => find.text('Página 1').evaluate().isNotEmpty);
    final notebookMs = notebook.elapsedMilliseconds;

    final scrollable = find
        .descendant(
          of: find.byType(PageList),
          matching: find.byType(Scrollable),
        )
        .first;
    final frames = FrameCollector()..start();
    await tester.scrollUntilVisible(
      find.text(_scrollTarget),
      800,
      scrollable: scrollable,
      maxScrolls: 1000,
    );
    final scroll = await frames.stop();

    await tester.tap(find.text(_scrollTarget).first);
    final page = Stopwatch()..start();
    await _pumpUntil(tester, _editorLaidOut);
    final pageMs = page.elapsedMilliseconds;
    expect(find.byType(PageScreen), findsOneWidget);

    await backFromPage(tester, _bigNotebook);
    await backFromNotebook(tester);
    await tapAndSettle(tester, iconButton('Buscar'));
    await tester.enterText(
      find.descendant(
        of: find.byType(SearchScreen),
        matching: find.byType(TextField),
      ),
      'belém',
    );
    await tester.pump(SearchScreen.debounce);
    final search = Stopwatch()..start();
    await _pumpUntil(
      tester,
      () => find.byType(SearchResultRow).evaluate().isNotEmpty,
    );
    final searchMs = search.elapsedMilliseconds;

    binding.reportData = {
      ...?binding.reportData,
      'outputName': 'large_library',
      'seedMs': seedMs,
      'load04Scroll': scroll,
      'load02ListMs': listMs,
      'load03NotebookMs': notebookMs,
      'load05PageMs': pageMs,
      'load06SearchMs': searchMs,
    };

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
