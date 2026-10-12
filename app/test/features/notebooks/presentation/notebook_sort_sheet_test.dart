import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/features/notebooks/data/notebook_sort_provider.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/features/notebooks/presentation/notebook_sort_sheet.dart';

import '../../../helpers/pump_jot.dart';

Future<void> _open(
  WidgetTester tester, {
  NotebookSort current = NotebookSort.lastEdited,
}) async {
  await tester.pumpJot(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () => showNotebookSortSheet(context, current),
            child: const SizedBox.square(dimension: 44, child: Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.text('open')));

void main() {
  testWidgets('SORT-01: the sheet lists the three options and the current one '
      'is checked', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, current: NotebookSort.name);

    expect(find.text('Ordenar por'), findsOneWidget);
    expect(find.text('Editados recentemente'), findsOneWidget);
    expect(find.text('Nome (A–Z)'), findsOneWidget);
    expect(find.text('Data de criação'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Nome (A–Z)')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.text('Editados recentemente'))
          .flagsCollection
          .isSelected,
      isNot(Tristate.isTrue),
    );
    semantics.dispose();
  });

  testWidgets('SORT-01: the note is shown', (tester) async {
    await _open(tester);

    expect(
      find.text('Vale para Ativos e Arquivados, e fica salvo neste aparelho.'),
      findsOneWidget,
    );
  });

  testWidgets('SORT-02: picking "Nome (A–Z)" updates the provider and closes '
      'the sheet', (tester) async {
    await _open(tester);
    expect(
      _container(tester).read(notebookSortProvider),
      NotebookSort.lastEdited,
    );

    await tester.tap(find.text('Nome (A–Z)'));
    await tester.pumpAndSettle();

    expect(_container(tester).read(notebookSortProvider), NotebookSort.name);
    expect(find.text('Ordenar por'), findsNothing);
  });

  testWidgets('SORT-02: dismissing the sheet keeps the sort', (tester) async {
    await _open(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(
      _container(tester).read(notebookSortProvider),
      NotebookSort.lastEdited,
    );
  });
}
