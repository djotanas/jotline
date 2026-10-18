import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';

import '../../helpers/test_database.dart';

const _at = '2026-10-11T12:00:00.123Z';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = createTestDatabase();
    await database.customStatement(
      'INSERT INTO notebooks (id, title, cover, color, created_by, '
      "created_at) VALUES ('n1', 'Nb', 'lisa', 'azulTinta', 'u1', '$_at')",
    );
  });
  tearDown(() => database.close());

  Future<void> insertPage(String id, {String title = ''}) {
    return database.customStatement(
      'INSERT INTO pages (id, notebook_id, title, position, updated_at, '
      'updated_by) VALUES (?, ?, ?, ?, ?, ?)',
      [id, 'n1', title, 'a$id', _at, 'u1'],
    );
  }

  Future<void> insertBlock(
    String id,
    String pageId,
    String text, {
    String type = 'text',
    String position = 'a0',
  }) {
    final json = type == 'drawing'
        ? '{"strokes":[],"label":"$text"}'
        : '{"text":"$text"}';
    return database.customStatement(
      'INSERT INTO blocks (id, page_id, type, content_json, position, '
      'updated_at, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, pageId, type, json, position, _at, 'u1'],
    );
  }

  Future<List<String>> find(String column, String word) async {
    final rows = await database
        .customSelect(
          'SELECT p.id AS id FROM page_search '
          'JOIN pages p ON p.rowid = page_search.rowid '
          'WHERE page_search MATCH ? ORDER BY p.id',
          variables: [Variable<String>('{$column} : "$word"*')],
        )
        .get();
    return [for (final row in rows) row.read<String>('id')];
  }

  Future<String> bodyOf(String pageId) async {
    final row = await database
        .customSelect(
          'SELECT page_search.body AS body FROM page_search '
          'JOIN pages p ON p.rowid = page_search.rowid WHERE p.id = ?',
          variables: [Variable<String>(pageId)],
        )
        .getSingle();
    return row.read<String>('body');
  }

  test('SRCH-18: inserting a page indexes its title', () async {
    await insertPage('p1', title: 'Roteiro de Belém');

    expect(await find('title', 'bele'), ['p1']);
  });

  test('SRCH-18: inserting a block indexes its text in the page', () async {
    await insertPage('p1');
    await insertBlock('b1', 'p1', 'Tacacá no almoço');

    expect(await find('body', 'tacaca'), ['p1']);
  });

  test('SRCH-18: updating a block finds the new text and not the removed '
      'one', () async {
    await insertPage('p1');
    await insertBlock('b1', 'p1', 'Tacacá no almoço');

    await database.customStatement(
      'UPDATE blocks SET content_json = ? WHERE id = ?',
      ['{"text":"Açaí no jantar"}', 'b1'],
    );

    expect(await find('body', 'acai'), ['p1']);
    expect(await find('body', 'tacaca'), isEmpty);
  });

  test(
    'SRCH-18: soft deleting a block removes its text from the index',
    () async {
      await insertPage('p1');
      await insertBlock('b1', 'p1', 'Tacacá no almoço');

      await database.customStatement(
        'UPDATE blocks SET deleted_at = ? WHERE id = ?',
        [_at, 'b1'],
      );

      expect(await find('body', 'tacaca'), isEmpty);
      expect(await bodyOf('p1'), '');
    },
  );

  test('SRCH-18: physically deleting a block removes its text from the '
      'index', () async {
    await insertPage('p1');
    await insertBlock('b1', 'p1', 'Tacacá no almoço');

    await database.customStatement('DELETE FROM blocks WHERE id = ?', ['b1']);

    expect(await find('body', 'tacaca'), isEmpty);
  });

  test('SRCH-18: changing a block type to drawing removes its text from the '
      'index', () async {
    await insertPage('p1');
    await insertBlock('b1', 'p1', 'Tacacá no almoço');

    await database.customStatement('UPDATE blocks SET type = ? WHERE id = ?', [
      'drawing',
      'b1',
    ]);

    expect(await find('body', 'tacaca'), isEmpty);
  });

  test('SRCH-18: changing a block type from drawing to text adds its text to '
      'the index', () async {
    await insertPage('p1');
    await insertBlock('b1', 'p1', 'x', type: 'drawing');

    await database.customStatement(
      'UPDATE blocks SET type = ?, content_json = ? WHERE id = ?',
      ['heading', '{"text":"Tacacá"}', 'b1'],
    );

    expect(await find('body', 'tacaca'), ['p1']);
  });

  test('SRCH-09: a drawing block never enters the body', () async {
    await insertPage('p1');
    await insertBlock('b1', 'p1', 'rabisco', type: 'drawing');
    await insertBlock('b2', 'p1', 'Texto', position: 'a1');

    expect(await find('body', 'rabisco'), isEmpty);
    expect(await bodyOf('p1'), 'Texto');
  });

  test('SRCH-18: renaming a page indexes the new title and drops the old '
      'one', () async {
    await insertPage('p1', title: 'Roteiro');

    await database.customStatement('UPDATE pages SET title = ? WHERE id = ?', [
      'Passagens',
      'p1',
    ]);

    expect(await find('title', 'passagens'), ['p1']);
    expect(await find('title', 'roteiro'), isEmpty);
  });

  test('SRCH-18: renaming a page keeps its block text in the index', () async {
    await insertPage('p1', title: 'Roteiro');
    await insertBlock('b1', 'p1', 'Tacacá no almoço');

    await database.customStatement('UPDATE pages SET title = ? WHERE id = ?', [
      'Passagens',
      'p1',
    ]);

    expect(await find('body', 'tacaca'), ['p1']);
  });

  test('SRCH-18: a page with no blocks has an empty body', () async {
    await insertPage('p1', title: 'Vazia');

    expect(await bodyOf('p1'), '');
  });

  test(
    'SRCH-18: block bodies are joined in position order with U+2029',
    () async {
      await insertPage('p1');
      await insertBlock('b2', 'p1', 'segundo', position: 'a1');
      await insertBlock('b1', 'p1', 'primeiro');

      expect(await bodyOf('p1'), 'primeiro segundo');
    },
  );

  test('SRCH-18: a block change re-indexes only its own page', () async {
    await insertPage('p1');
    await insertPage('p2');
    await insertBlock('b1', 'p1', 'Tacacá');
    await insertBlock('b2', 'p2', 'Açaí');

    await database.customStatement(
      'UPDATE blocks SET content_json = ? WHERE id = ?',
      ['{"text":"Cupuaçu"}', 'b1'],
    );

    expect(await find('body', 'cupuacu'), ['p1']);
    expect(await find('body', 'acai'), ['p2']);
  });

  test('SRCH-18: a block with malformed content_json is saved and not '
      'indexed', () async {
    await insertPage('p1');
    await database.customStatement(
      'INSERT INTO blocks (id, page_id, type, content_json, position, '
      "updated_at, updated_by) VALUES ('b1', 'p1', 'text', 'not json', 'a0', "
      "'$_at', 'u1')",
    );

    expect(await bodyOf('p1'), '');
  });
}
