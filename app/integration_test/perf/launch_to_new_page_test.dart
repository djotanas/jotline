import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotline/app.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/design_system/jot_fab.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';

Future<void> _pumpUntil(WidgetTester tester, Finder finder) =>
    _pumpUntilTrue(tester, () => finder.evaluate().isNotEmpty, '$finder');

Future<void> _pumpUntilTrue(
  WidgetTester tester,
  bool Function() condition,
  String description,
) async {
  final limit = Stopwatch()..start();
  while (!condition()) {
    if (limit.elapsedMilliseconds > 10000) {
      fail('Timed out waiting for $description');
    }
    await tester.pump(const Duration(milliseconds: 8));
  }
}

bool _editorReadyWithTitleFocused() {
  final editor = find.byType(BlockEditor).evaluate();
  if (editor.isEmpty) return false;
  final laidOut = switch (editor.single.renderObject) {
    final RenderSliver sliver => sliver.geometry != null,
    final RenderBox box => box.hasSize,
    _ => false,
  };
  if (!laidOut) return false;
  final title = find
      .descendant(
        of: find.byType(PageScreen),
        matching: find.byType(EditableText),
      )
      .evaluate();
  return title.isNotEmpty &&
      (title.first.widget as EditableText).focusNode.hasFocus;
}

List<Override> _overrides(AppDatabase db) => [
  databaseProvider.overrideWithValue(db),
  preferencesStoreProvider.overrideWithValue(UnavailablePreferencesStore()),
];

/// Measures PERF-01 without human pauses: the notebook is seeded through the
/// repository, then the test builds the app, opens the notebook and taps
/// "Nova página", and the clock stops at the first frame where `BlockEditor`
/// is laid out and the title has focus.
/// Run it in profile mode, one process per measurement:
/// `fvm flutter drive --driver=test_driver/perf_driver.dart
/// --target=integration_test/perf/launch_to_new_page_test.dart --profile -d DEVICE_ID`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PERF-01: launch to a new page with the editor rendered and '
      'the title focused', (tester) async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    final seed = ProviderContainer(overrides: _overrides(db));
    await seed
        .read(notebookRepositoryProvider)
        .create(
          title: 'Medicao',
          cover: CoverPattern.lisa,
          color: NotebookColor.terracota,
        );
    seed.dispose();

    final total = Stopwatch()..start();
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(db), child: const JotlineApp()),
    );
    await _pumpUntil(tester, find.text('Medicao'));
    final toList = total.elapsedMilliseconds;

    await tester.tap(find.text('Medicao').first);
    await _pumpUntil(tester, find.widgetWithText(JotFab, 'Nova página'));
    final toNotebook = total.elapsedMilliseconds;

    await tester.tap(find.widgetWithText(JotFab, 'Nova página'));
    await _pumpUntil(tester, find.byType(PageScreen));
    final toPage = total.elapsedMilliseconds;

    await _pumpUntilTrue(
      tester,
      _editorReadyWithTitleFocused,
      'BlockEditor laid out with the title focused',
    );
    final toEditor = total.elapsedMilliseconds;

    binding.reportData = {
      'toListMs': toList,
      'toNotebookMs': toNotebook,
      'toPageMs': toPage,
      'toEditorMs': toEditor,
    };

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
