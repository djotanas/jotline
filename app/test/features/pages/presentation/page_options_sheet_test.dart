import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/pages/data/page_summary.dart';
import 'package:jotline/features/pages/presentation/page_options_sheet.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_jot.dart';

final DateTime _now = DateTime.utc(2026, 10, 12, 15);

Notebook _notebook() => Notebook(
  id: 'n1',
  title: 'Viagem a Lisboa',
  cover: CoverPattern.lisa,
  color: NotebookColor.musgo,
  createdBy: 'u1',
  createdAt: DateTime.utc(2026, 10),
);

PageSummary _summary({
  String title = 'Roteiro — dia 2',
  DateTime? updatedAt,
  DateTime? lastEditedAt,
}) => PageSummary(
  page: NotebookPage(
    id: 'p1',
    notebookId: 'n1',
    title: title,
    position: 'a0',
    updatedAt: updatedAt ?? _now,
    updatedBy: 'u1',
  ),
  lastEditedAt: lastEditedAt ?? _now,
  excerpt: null,
);

class _Result {
  bool resolved = false;
  PageAction? action;
}

Future<_Result> _open(
  WidgetTester tester, {
  String title = 'Roteiro — dia 2',
  DateTime? updatedAt,
  DateTime? lastEditedAt,
}) async {
  final result = _Result();
  await tester.pumpJot(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () async {
              result
                ..action = await showPageOptionsSheet(
                  context,
                  _summary(
                    title: title,
                    updatedAt: updatedAt,
                    lastEditedAt: lastEditedAt,
                  ),
                  _notebook(),
                )
                ..resolved = true;
            },
            child: const SizedBox.square(dimension: 44, child: Text('open')),
          ),
        ),
      ),
    ),
    overrides: [clockProvider.overrideWithValue(FakeClock(_now))],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

String _editedLine([DateTime? at]) {
  final local = (at ?? _now).toLocal();
  final hours = local.hour.toString().padLeft(2, '0');
  final minutes = local.minute.toString().padLeft(2, '0');
  return 'editada hoje, $hours:$minutes';
}

void main() {
  testWidgets('PGOPT-01: the header shows the page title, the notebook '
      'color chip and title and the edited line', (tester) async {
    await _open(tester);

    expect(find.text('Roteiro — dia 2'), findsOneWidget);
    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    expect(find.text(_editedLine()), findsOneWidget);
    final chip = tester.widget<DecoratedBox>(
      find.byKey(PageOptionsHeader.chipKey),
    );
    expect((chip.decoration as BoxDecoration).color, NotebookColor.musgo.color);
  });

  testWidgets('EDITED-02: with a block saved after the page row, the edited '
      'line shows the block date', (tester) async {
    final blockSaved = DateTime.utc(2026, 10, 12, 14, 32);
    await _open(
      tester,
      updatedAt: DateTime.utc(2026, 10, 11, 9, 5),
      lastEditedAt: blockSaved,
    );

    expect(find.text(_editedLine(blockSaved)), findsOneWidget);
    expect(find.textContaining('ontem'), findsNothing);
  });

  testWidgets('PGOPT-01: an empty title reads "Sem título"', (tester) async {
    await _open(tester, title: '');

    expect(find.text('Sem título'), findsOneWidget);
  });

  testWidgets('PGOPT-01: the rows are "Renomear" and "Excluir página" with its '
      'subtitle', (tester) async {
    await _open(tester);

    expect(find.text('Renomear'), findsOneWidget);
    expect(find.text('Excluir página'), findsOneWidget);
    expect(find.text('Vai para a lixeira; dá para desfazer'), findsOneWidget);
  });

  testWidgets('PGOPT-02: tapping "Renomear" resolves PageAction.rename', (
    tester,
  ) async {
    final result = await _open(tester);

    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();

    expect(result.resolved, isTrue);
    expect(result.action, PageAction.rename);
  });

  testWidgets('PGOPT-04: tapping "Excluir página" resolves PageAction.delete', (
    tester,
  ) async {
    final result = await _open(tester);

    await tester.tap(find.text('Excluir página'));
    await tester.pumpAndSettle();

    expect(result.resolved, isTrue);
    expect(result.action, PageAction.delete);
  });

  testWidgets('PGOPT-01: tapping the barrier resolves null', (tester) async {
    final result = await _open(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result.resolved, isTrue);
    expect(result.action, isNull);
  });
}
