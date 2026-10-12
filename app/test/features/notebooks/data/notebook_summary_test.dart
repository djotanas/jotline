import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';

void main() {
  NotebookSummary summary(
    String id, {
    String title = 'Notebook',
    DateTime? createdAt,
    DateTime? lastEditedAt,
  }) {
    final created = createdAt ?? DateTime.utc(2026, 10);
    return NotebookSummary(
      notebook: Notebook(
        id: id,
        title: title,
        cover: CoverPattern.lisa,
        color: NotebookColor.azulTinta,
        createdBy: 'u',
        createdAt: created,
      ),
      pageCount: 0,
      lastEditedAt: lastEditedAt ?? created,
    );
  }

  List<String> ids(List<NotebookSummary> list) => [
    for (final s in list) s.notebook.id,
  ];

  test('SORT-03: lastEdited orders by last edited date descending', () {
    final sorted = sortNotebooks([
      summary('a', lastEditedAt: DateTime.utc(2026, 10, 2)),
      summary('b', lastEditedAt: DateTime.utc(2026, 10, 4)),
      summary('c', lastEditedAt: DateTime.utc(2026, 10, 3)),
    ], NotebookSort.lastEdited);

    expect(ids(sorted), ['b', 'c', 'a']);
  });

  test('SORT-03: lastEdited breaks ties by id descending', () {
    final at = DateTime.utc(2026, 10, 2);
    final sorted = sortNotebooks([
      summary('a', lastEditedAt: at),
      summary('c', lastEditedAt: at),
      summary('b', lastEditedAt: at),
    ], NotebookSort.lastEdited);

    expect(ids(sorted), ['c', 'b', 'a']);
  });

  test('SORT-04: name orders "árvore" before "Bloco" before "Caderno"', () {
    final sorted = sortNotebooks([
      summary('1', title: 'Caderno'),
      summary('2', title: 'árvore'),
      summary('3', title: 'Bloco'),
    ], NotebookSort.name);

    expect(
      [for (final s in sorted) s.notebook.title],
      ['árvore', 'Bloco', 'Caderno'],
    );
  });

  test('SORT-04: name breaks ties by id ascending', () {
    final sorted = sortNotebooks([
      summary('b', title: 'Ação'),
      summary('c', title: 'acao'),
      summary('a', title: 'AÇÃO'),
    ], NotebookSort.name);

    expect(ids(sorted), ['a', 'b', 'c']);
  });

  test('SORT-04: foldForSort lowercases and strips diacritics', () {
    expect(foldForSort('ÁÇÃo'), 'acao');
    expect(foldForSort('Éíóú ñ ü'), 'eiou n u');
    expect(foldForSort('Plain 42-x'), 'plain 42-x');
  });

  test('SORT-05: createdAt orders by creation date descending', () {
    final sorted = sortNotebooks([
      summary('a', createdAt: DateTime.utc(2026, 10, 2)),
      summary('b', createdAt: DateTime.utc(2026, 10, 4)),
      summary('c', createdAt: DateTime.utc(2026, 10, 3)),
    ], NotebookSort.createdAt);

    expect(ids(sorted), ['b', 'c', 'a']);
  });

  test('SORT-05: createdAt breaks ties by id descending', () {
    final at = DateTime.utc(2026, 10, 2);
    final sorted = sortNotebooks([
      summary('a', createdAt: at),
      summary('b', createdAt: at),
    ], NotebookSort.createdAt);

    expect(ids(sorted), ['b', 'a']);
  });

  test('SORT-05: createdAt ignores the last edited date', () {
    final sorted = sortNotebooks([
      summary(
        'a',
        createdAt: DateTime.utc(2026, 10),
        lastEditedAt: DateTime.utc(2026, 10, 9),
      ),
      summary('b', createdAt: DateTime.utc(2026, 10, 2)),
    ], NotebookSort.createdAt);

    expect(ids(sorted), ['b', 'a']);
  });

  test('SORT-03: sorting does not mutate the input', () {
    final input = [
      summary('a', createdAt: DateTime.utc(2026, 10)),
      summary('b', createdAt: DateTime.utc(2026, 10, 2)),
    ];

    sortNotebooks(input, NotebookSort.createdAt);

    expect(ids(input), ['a', 'b']);
  });
}
