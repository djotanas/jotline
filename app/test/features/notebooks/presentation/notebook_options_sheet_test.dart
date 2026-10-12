import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/features/notebooks/presentation/notebook_options_sheet.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_jot.dart';

final DateTime _now = DateTime.utc(2026, 10, 12, 15);

NotebookSummary _summary({DateTime? archivedAt, int pageCount = 12}) =>
    NotebookSummary(
      notebook: Notebook(
        id: 'n1',
        title: 'Viagem a Lisboa',
        cover: CoverPattern.pautada,
        color: NotebookColor.azulTinta,
        createdBy: 'u1',
        createdAt: DateTime.utc(2026, 10, 1, 15),
      ),
      pageCount: pageCount,
      lastEditedAt: _now,
      archivedAt: archivedAt,
    );

class _Result {
  bool resolved = false;
  NotebookAction? action;
}

Future<_Result> _open(WidgetTester tester, NotebookSummary summary) async {
  final result = _Result();
  await tester.pumpJot(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () async {
              result
                ..action = await showNotebookOptionsSheet(context, summary)
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

void main() {
  testWidgets('NBOPT-01: an active notebook shows the header, "Arquivar" and '
      'its subtitle', (tester) async {
    await _open(tester, _summary());

    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    expect(find.text('12 páginas · criado em 1 out'), findsOneWidget);
    expect(find.byType(NotebookCover), findsOneWidget);
    expect(find.text('Renomear'), findsOneWidget);
    expect(find.text('Mudar capa e cor'), findsOneWidget);
    expect(find.text('Arquivar'), findsOneWidget);
    expect(find.text('Sai da lista principal; nada é apagado'), findsOneWidget);
    expect(find.text('Excluir caderno'), findsOneWidget);
    expect(find.text('Desarquivar'), findsNothing);
  });

  testWidgets('NBOPT-02: an archived notebook shows "Desarquivar" and the '
      '"arquivado" meta', (tester) async {
    await _open(tester, _summary(archivedAt: _now, pageCount: 1));

    expect(find.text('1 página · arquivado hoje'), findsOneWidget);
    expect(find.text('Desarquivar'), findsOneWidget);
    expect(find.text('Volta para a lista principal'), findsOneWidget);
    expect(find.text('Arquivar'), findsNothing);
  });

  for (final (label, action) in [
    ('Renomear', NotebookAction.rename),
    ('Mudar capa e cor', NotebookAction.cover),
    ('Arquivar', NotebookAction.archive),
    ('Excluir caderno', NotebookAction.delete),
  ]) {
    testWidgets('NBOPT-01: "$label" returns $action', (tester) async {
      final result = await _open(tester, _summary());

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(result.resolved, isTrue);
      expect(result.action, action);
    });
  }

  testWidgets('NBOPT-02: "Desarquivar" returns NotebookAction.unarchive', (
    tester,
  ) async {
    final result = await _open(tester, _summary(archivedAt: _now));

    await tester.tap(find.text('Desarquivar'));
    await tester.pumpAndSettle();

    expect(result.action, NotebookAction.unarchive);
  });
}
