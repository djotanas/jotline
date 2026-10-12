import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/notebook_color_picker.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/design_system/notebook_cover_picker.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/features/notebooks/presentation/notebook_form_sheet.dart';

import '../../../helpers/pump_jot.dart';
import '../../../helpers/test_app.dart';

late TestApp _app;
Object? _result = 'not closed';
SemanticsHandle? _semantics;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _launch(
  WidgetTester tester,
  Future<Object?> Function(BuildContext) open,
) async {
  _result = 'not closed';
  _semantics = tester.ensureSemantics();
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpJot(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () async => _result = await open(context),
            child: const SizedBox.square(dimension: 44, child: Text('open')),
          ),
        ),
      ),
    ),
    overrides: _app.overrides,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _openNew(WidgetTester tester) {
  _app = TestApp();
  return _launch(tester, showNewNotebookSheet);
}

Future<NotebookSummary> _seedSummary(WidgetTester tester) async {
  _app = TestApp();
  return (await tester.runAsync(() async {
    final id = await _app.notebooks.create(
      title: 'Viagem a Lisboa',
      cover: CoverPattern.pautada,
      color: NotebookColor.azulTinta,
    );
    return NotebookSummary(
      notebook: await _app.notebook(id),
      pageCount: 0,
      lastEditedAt: DateTime.utc(2026, 10, 12),
    );
  }))!;
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.runAsync(_app.db.close);
  _semantics?.dispose();
}

NotebookCover get _preview =>
    find.byType(NotebookCover).evaluate().first.widget as NotebookCover;

JotButton _primary(WidgetTester tester, String label) =>
    tester.widget<JotButton>(find.widgetWithText(JotButton, label));

Future<List<Notebook>> _notebooks(WidgetTester tester) async =>
    (await tester.runAsync(() => _app.db.select(_app.db.notebooks).get()))!;

void main() {
  testWidgets('NBNEW-01: opens with an empty name, "Azul tinta" and "Lisa" '
      'selected and the preview labeled "Nome do caderno"', (tester) async {
    await _openNew(tester);

    expect(find.text('Novo caderno'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(
      tester
          .widget<NotebookColorPicker>(find.byType(NotebookColorPicker))
          .selected,
      NotebookColor.azulTinta,
    );
    expect(
      tester
          .widget<NotebookCoverPicker>(find.byType(NotebookCoverPicker))
          .selected,
      CoverPattern.lisa,
    );
    expect(_preview.label, 'Nome do caderno');
    expect(_preview.labelMuted, isTrue);
    expect(_preview.color, NotebookColor.azulTinta);
    expect(_preview.pattern, CoverPattern.lisa);
    await _close(tester);
  });

  testWidgets('NBNEW-02: the preview follows the name, the color and the '
      'cover', (tester) async {
    await _openNew(tester);

    await tester.enterText(find.byType(TextField), 'Receitas');
    await tester.tap(find.bySemanticsLabel('Musgo'));
    await tester.tap(find.text('Grade'));
    await tester.pump();

    expect(_preview.label, 'Receitas');
    expect(_preview.labelMuted, isFalse);
    expect(_preview.color, NotebookColor.musgo);
    expect(_preview.pattern, CoverPattern.quadriculada);
    await _close(tester);
  });

  testWidgets('NBNEW-03: "Criar caderno" is disabled while the trimmed name '
      'is empty', (tester) async {
    await _openNew(tester);
    expect(_primary(tester, 'Criar caderno').onPressed, isNull);

    await tester.enterText(find.byType(TextField), '    ');
    await tester.pump();
    expect(_primary(tester, 'Criar caderno').onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'A');
    await tester.pump();
    expect(_primary(tester, 'Criar caderno').onPressed, isNotNull);
    await _close(tester);
  });

  testWidgets('NBNEW-05: the counter shows from 40 characters', (tester) async {
    await _openNew(tester);

    await tester.enterText(find.byType(TextField), 'a' * 39);
    await tester.pump();
    expect(find.text('39/50'), findsNothing);

    await tester.enterText(find.byType(TextField), 'a' * 40);
    await tester.pump();
    expect(find.text('40/50'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBNEW-06: creating writes one notebook and one owner row with '
      'the trimmed name, and returns the id', (tester) async {
    await _openNew(tester);

    await tester.enterText(find.byType(TextField), '  Receitas  ');
    await tester.tap(find.bySemanticsLabel('Terracota'));
    await tester.tap(find.text('Pontos'));
    await tester.pump();
    await tester.tap(find.text('Criar caderno'));
    await _settle(tester);
    await tester.pumpAndSettle();

    final notebooks = await _notebooks(tester);
    expect(notebooks, hasLength(1));
    expect(notebooks.single.title, 'Receitas');
    expect(notebooks.single.color, NotebookColor.terracota);
    expect(notebooks.single.cover, CoverPattern.pontilhada);
    final members = await tester.runAsync(
      () => _app.db.select(_app.db.notebookMembers).get(),
    );
    expect(members, hasLength(1));
    expect(members!.single.role.name, 'owner');
    expect(_result, notebooks.single.id);
    await _close(tester);
  });

  testWidgets('NBNEW-07: "Cancelar" closes the sheet and writes nothing', (
    tester,
  ) async {
    await _openNew(tester);

    await tester.enterText(find.byType(TextField), 'Receitas');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(_result, isNull);
    expect(await _notebooks(tester), isEmpty);
    await _close(tester);
  });

  testWidgets('NBOPT-07: "Capa e cor" has no name field, preselects the '
      'current values and offers "Salvar"', (tester) async {
    final summary = await _seedSummary(tester);
    await _launch(tester, (context) => showCoverSheet(context, summary));

    expect(find.text('Capa e cor'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      tester
          .widget<NotebookColorPicker>(find.byType(NotebookColorPicker))
          .selected,
      NotebookColor.azulTinta,
    );
    expect(
      tester
          .widget<NotebookCoverPicker>(find.byType(NotebookCoverPicker))
          .selected,
      CoverPattern.pautada,
    );
    expect(_preview.label, 'Viagem a Lisboa');
    expect(_primary(tester, 'Salvar').onPressed, isNotNull);
    await _close(tester);
  });

  testWidgets('NBOPT-08: "Salvar" writes the chosen color and cover and '
      'returns true', (tester) async {
    final summary = await _seedSummary(tester);
    await _launch(tester, (context) => showCoverSheet(context, summary));

    await tester.tap(find.bySemanticsLabel('Musgo'));
    await tester.tap(find.text('Grade'));
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await _settle(tester);
    await tester.pumpAndSettle();

    final stored = await tester.runAsync(
      () => _app.notebook(summary.notebook.id),
    );
    expect(stored!.color, NotebookColor.musgo);
    expect(stored.cover, CoverPattern.quadriculada);
    expect(stored.title, 'Viagem a Lisboa');
    expect(_result, isTrue);
    await _close(tester);
  });

  testWidgets('NBOPT-09: "Cancelar" in "Capa e cor" writes nothing and '
      'returns false', (tester) async {
    final summary = await _seedSummary(tester);
    await _launch(tester, (context) => showCoverSheet(context, summary));

    await tester.tap(find.bySemanticsLabel('Musgo'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    final stored = await tester.runAsync(
      () => _app.notebook(summary.notebook.id),
    );
    expect(stored!.color, NotebookColor.azulTinta);
    expect(_result, isFalse);
    await _close(tester);
  });
}
