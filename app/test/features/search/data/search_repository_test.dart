import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';
import 'package:jotline/features/search/data/match_query.dart';
import 'package:jotline/features/search/data/search_excerpt.dart';
import 'package:jotline/features/search/data/search_hit.dart';
import 'package:jotline/features/search/data/search_repository.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/stream_recorder.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late LocalUserRepository localUser;
  late NotebookRepository notebooks;
  late PageRepository pages;
  late BlockRepository blocks;
  late SearchRepository repository;

  setUp(() {
    db = createTestDatabase();
    clock = FakeClock(DateTime.utc(2026, 10, 11, 8));
    final ids = SequentialIdGenerator();
    localUser = LocalUserRepository(db, ids);
    notebooks = NotebookRepository(db, clock, ids, localUser);
    pages = PageRepository(db, clock, ids, localUser);
    blocks = BlockRepository(db, clock, ids, localUser);
    repository = SearchRepository(db, localUser);
  });
  tearDown(() => db.close());

  Future<String> notebook(
    String title, {
    NotebookColor color = NotebookColor.azulTinta,
  }) => notebooks.create(title: title, cover: CoverPattern.lisa, color: color);

  Future<String> write(String pageId, String text) async {
    final inserted = await blocks.applyChanges(pageId, [
      Insert('k', BlockType.text, BlockContent(text), const AtEnd()),
    ]);
    return inserted['k']!;
  }

  Future<String> page(String notebookId, String title, [String? text]) async {
    final id = await pages.create(notebookId, title: title);
    if (text != null) await write(id, text);
    return id;
  }

  Future<List<SearchHit>> hits(
    String term, [
    SearchScope scope = SearchScope.all,
  ]) async {
    final recorder = StreamRecorder(
      repository.watchHits(MatchQuery.parse(term), scope),
    );
    final emissions = await recorder.settle();
    await recorder.cancel();
    return emissions.last;
  }

  Future<List<String>> titles(
    String term, [
    SearchScope scope = SearchScope.all,
  ]) async => [for (final hit in await hits(term, scope)) hit.title];

  Future<
    ({String titlePage, String blockPage, String archivedPage, String trashed})
  >
  seedIndependentTest() async {
    final main = await notebook('Viagens', color: NotebookColor.musgo);
    final archived = await notebook('Arquivo');
    final titlePage = await page(main, 'Onde comer em Belém');
    clock.current = DateTime.utc(2026, 10, 11, 9);
    final blockPage = await page(main, 'Roteiro');
    final archivedPage = await page(archived, 'Voo');
    clock.current = DateTime.utc(2026, 10, 11, 9, 30);
    await write(archivedPage, 'passagem para Belém');
    clock.current = DateTime.utc(2026, 10, 11, 10);
    await write(blockPage, 'Belém cedo');
    clock.current = DateTime.utc(2026, 10, 11, 11);
    final trashed = await page(main, 'Belém velha');
    await pages.moveToTrash(trashed);
    await notebooks.archive(archived);
    return (
      titlePage: titlePage,
      blockPage: blockPage,
      archivedPage: archivedPage,
      trashed: trashed,
    );
  }

  group('watchHits', () {
    test('SRCH-04, SRCH-10: "bele" returns the 3 pages, most recently '
        'edited first', () async {
      final seeded = await seedIndependentTest();

      final found = await hits('bele');

      expect(
        [for (final hit in found) hit.pageId],
        [seeded.blockPage, seeded.archivedPage, seeded.titlePage],
      );
    });

    test(
      'SRCH-06: "Títulos" returns only the page whose title matches',
      () async {
        final seeded = await seedIndependentTest();

        final found = await hits('bele', SearchScope.titles);

        expect([for (final hit in found) hit.pageId], [seeded.titlePage]);
      },
    );

    test(
      'SRCH-07: "Conteúdo" returns only pages whose block text matches',
      () async {
        final seeded = await seedIndependentTest();

        final found = await hits('bele', SearchScope.content);

        expect(
          [for (final hit in found) hit.pageId],
          [seeded.blockPage, seeded.archivedPage],
        );
      },
    );

    test('SRCH-04: case and diacritics are ignored', () async {
      await seedIndependentTest();

      expect(await titles('BELEM'), hasLength(3));
      expect(await titles('belém'), hasLength(3));
    });

    test(
      'SRCH-04: the term matches the start of a word, not its middle',
      () async {
        await seedIndependentTest();

        expect(await titles('lém'), isEmpty);
      },
    );

    test('SRCH-05: every word must match', () async {
      final seeded = await seedIndependentTest();

      final found = await hits('belem cedo');

      expect([for (final hit in found) hit.pageId], [seeded.blockPage]);
    });

    test('SRCH-08: "Tudo" matches the title and the block text of a page '
        'together', () async {
      final seeded = await seedIndependentTest();

      final found = await hits('roteiro belem');

      expect([for (final hit in found) hit.pageId], [seeded.blockPage]);
      expect(await titles('roteiro belem', SearchScope.titles), isEmpty);
      expect(await titles('roteiro belem', SearchScope.content), isEmpty);
    });

    test('SRCH-09: trashed pages are never returned', () async {
      final seeded = await seedIndependentTest();

      final ids = [for (final hit in await hits('bele')) hit.pageId];

      expect(ids, isNot(contains(seeded.trashed)));
    });

    test('SRCH-09: pages of trashed notebooks are never returned', () async {
      final seeded = await seedIndependentTest();
      final row = await (db.select(
        db.pages,
      )..where((t) => t.id.equals(seeded.blockPage))).getSingle();
      await notebooks.moveToTrash(row.notebookId);

      final ids = [for (final hit in await hits('bele')) hit.pageId];

      expect(ids, [seeded.archivedPage]);
    });

    test('SRCH-09: deleted blocks are never searched', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Roteiro');
      final blockId = await write(pageId, 'Belém cedo');
      await blocks.applyChanges(pageId, [Trash(blockId)]);

      expect(await titles('belem'), isEmpty);
    });

    test('SRCH-09: drawing blocks are never searched', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Roteiro');
      await blocks.create(
        pageId,
        type: 'drawing',
        contentJson: '{"text":"Belém","strokes":[]}',
      );

      expect(await titles('belem'), isEmpty);
    });

    test('SRCH-09: pages of archived notebooks are returned', () async {
      final seeded = await seedIndependentTest();

      final ids = [for (final hit in await hits('passagem')) hit.pageId];

      expect(ids, [seeded.archivedPage]);
    });

    test(
      'SRCH-10: pages edited at the same instant are ordered by id',
      () async {
        final notebookId = await notebook('Viagens');
        final first = await page(notebookId, 'Belém um');
        final second = await page(notebookId, 'Belém dois');
        final third = await page(notebookId, 'Belém três');

        final ids = [for (final hit in await hits('belem')) hit.pageId];

        expect(ids, [first, second, third]);
      },
    );

    test('SRCH-11: a hit carries the page title, notebook title and color, and '
        'the last edited instant', () async {
      final seeded = await seedIndependentTest();

      final hit = (await hits('bele'))
          .firstWhere((hit) => hit.pageId == seeded.blockPage);

      expect(hit.title, 'Roteiro');
      expect(hit.notebookTitle, 'Viagens');
      expect(hit.notebookColor, NotebookColor.musgo);
      expect(hit.lastEditedAt, DateTime.utc(2026, 10, 11, 10));
    });

    test('SRCH-18: a block saved after the first emission is found by its new '
        'text and not by the removed text', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Roteiro');
      final blockId = await write(pageId, 'Belém cedo');

      await blocks.applyChanges(pageId, [
        Update(blockId, BlockType.text, const BlockContent('Santarém tarde')),
      ]);

      expect(await titles('santarem'), ['Roteiro']);
      expect(await titles('belem'), isEmpty);
    });

    test('SRCH-18, SRCH-20: the stream re-emits after a block save', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Roteiro');
      final recorder = StreamRecorder(
        repository.watchHits(MatchQuery.parse('belem'), SearchScope.all),
      );
      await recorder.settle();
      expect(recorder.emissions.last, isEmpty);

      await write(pageId, 'Belém cedo');
      await recorder.settle();

      expect([for (final hit in recorder.emissions.last) hit.pageId], [pageId]);
      await recorder.cancel();
    });

    test('SRCH-18, SRCH-20: the stream re-emits after a rename', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Roteiro');
      final recorder = StreamRecorder(
        repository.watchHits(MatchQuery.parse('belem'), SearchScope.titles),
      );
      await recorder.settle();
      expect(recorder.emissions.last, isEmpty);

      await pages.rename(pageId, 'Belém');
      await recorder.settle();

      expect([for (final hit in recorder.emissions.last) hit.title], ['Belém']);
      await recorder.cancel();
    });

    test('SRCH-20: the stream re-emits when the page is trashed', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Belém');
      final recorder = StreamRecorder(
        repository.watchHits(MatchQuery.parse('belem'), SearchScope.all),
      );
      await recorder.settle();
      expect(recorder.emissions.last, hasLength(1));

      await pages.moveToTrash(pageId);
      await recorder.settle();

      expect(recorder.emissions.last, isEmpty);
      await recorder.cancel();
    });

    test('EDGE-01: an empty query emits an empty list', () async {
      await seedIndependentTest();

      expect(await hits('  ?! '), isEmpty);
    });

    test('EDGE-02: FTS5 operators typed by the user do not throw', () async {
      await seedIndependentTest();

      for (final term in ['"', 'a OR', 'NEAR(', '-belem', 'bele*', 'AND']) {
        final recorder = StreamRecorder(
          repository.watchHits(MatchQuery.parse(term), SearchScope.all),
        );
        await recorder.settle();
        expect(recorder.errors, isEmpty, reason: term);
        await recorder.cancel();
      }
    });
  });

  group('snippet', () {
    test(
      'SRCH-13, SRCH-14: returns the marked title and the excerpt',
      () async {
        final notebookId = await notebook('Viagens');
        final pageId = await page(notebookId, 'Onde comer em Belém');
        await write(pageId, 'Sem relação');
        await write(pageId, 'Chegar em Belém cedo');

        final snippet = await repository.snippet(
          pageId,
          MatchQuery.parse('bele'),
          SearchScope.all,
        );

        expect(snippet.title, [
          const HighlightSpan('Onde comer em ', marked: false),
          const HighlightSpan('Belém', marked: true),
        ]);
        expect(snippet.excerpt!.spans, [
          const HighlightSpan('Chegar em ', marked: false),
          const HighlightSpan('Belém', marked: true),
          const HighlightSpan(' cedo', marked: false),
        ]);
      },
    );

    test('SRCH-06: the "Títulos" scope returns no excerpt', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Belém', 'Belém cedo');

      final snippet = await repository.snippet(
        pageId,
        MatchQuery.parse('bele'),
        SearchScope.titles,
      );

      expect(snippet.title, [const HighlightSpan('Belém', marked: true)]);
      expect(snippet.excerpt, isNull);
    });

    test('SRCH-07: the "Conteúdo" scope marks nothing in the title', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Belém', 'Belém cedo');

      final snippet = await repository.snippet(
        pageId,
        MatchQuery.parse('bele'),
        SearchScope.content,
      );

      expect(snippet.title, [const HighlightSpan('Belém', marked: false)]);
      expect(snippet.excerpt!.text, 'Belém cedo');
    });

    test('SRCH-14: every matched word is marked', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(
        notebookId,
        'Belém e Santarém',
        'Belém e Santarém juntas',
      );

      final snippet = await repository.snippet(
        pageId,
        MatchQuery.parse('belem santarem'),
        SearchScope.all,
      );

      expect(snippet.title.where((span) => span.marked).map((s) => s.text), [
        'Belém',
        'Santarém',
      ]);
      expect(snippet.excerpt!.spans.where((s) => s.marked).map((s) => s.text), [
        'Belém',
        'Santarém',
      ]);
    });

    test('SRCH-13: a page with no block match has no excerpt', () async {
      final notebookId = await notebook('Viagens');
      final pageId = await page(notebookId, 'Belém', 'Outro assunto');

      final snippet = await repository.snippet(
        pageId,
        MatchQuery.parse('bele'),
        SearchScope.all,
      );

      expect(snippet.excerpt, isNull);
    });

    test('SRCH-13: an unknown page has an empty snippet', () async {
      final snippet = await repository.snippet(
        'missing',
        MatchQuery.parse('bele'),
        SearchScope.all,
      );

      expect(snippet.title, isEmpty);
      expect(snippet.excerpt, isNull);
    });
  });
}
