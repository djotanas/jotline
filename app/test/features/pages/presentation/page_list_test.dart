import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/dragging_page_row.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/pages/data/page_providers.dart';
import 'package:jotline/features/pages/presentation/page_list.dart';

import '../../../helpers/pump_jot.dart';
import '../../../helpers/test_app.dart';

late TestApp _app;
late String _notebookId;
late List<String> _ids;
final List<String> _opened = [];

class _Host extends ConsumerWidget {
  const new({required this.reordering});

  final bool reordering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(pagesProvider(_notebookId)).value ?? [];
    return Scaffold(
      body: PageList(
        pages: pages,
        reordering: reordering,
        onOpen: (page) => _opened.add(page.id),
      ),
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(
  WidgetTester tester, {
  bool reordering = false,
  List<String> titles = const ['A', 'B', 'C'],
  DateTime? now,
  Future<void> Function()? seed,
}) async {
  _app = TestApp(now: now);
  _opened.clear();
  await tester.runAsync(() async {
    _notebookId = await _app.notebooks.create(
      title: 'Caderno',
      cover: CoverPattern.lisa,
      color: NotebookColor.azulTinta,
    );
    _ids = [
      for (final title in titles)
        await _app.pages.create(_notebookId, title: title),
    ];
    await seed?.call();
  });
  await tester.pumpJot(
    _Host(reordering: reordering),
    overrides: _app.overrides,
  );
  await _settle(tester);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.runAsync(_app.db.close);
}

Future<String> _block(String pageId, BlockType type, String text) => _app.blocks
    .create(pageId, type: type.id, contentJson: BlockContent(text).toJson());

List<String?> _texts(WidgetTester tester, Set<String> among) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .where(among.contains)
    .toList();

Finder get _handles => find.byWidgetPredicate(
  (w) => w is JotIcon && w.glyph == JotIconGlyph.dragHandle,
);

Future<Map<String, String>> _positions(WidgetTester tester) async {
  final rows = await tester.runAsync(() => _app.db.select(_app.db.pages).get());
  return {for (final row in rows!) row.id: row.position};
}

void main() {
  testWidgets('REORDER-01: drag handles show only in reorder mode', (
    tester,
  ) async {
    await _open(tester);
    expect(_handles, findsNothing);
    await _close(tester);

    await _open(tester, reordering: true);
    expect(_handles, findsNWidgets(3));
    await _close(tester);
  });

  testWidgets('REORDER-01: each handle is labeled "Mover <title>"', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, reordering: true);

    expect(find.bySemanticsLabel('Mover A'), findsOneWidget);
    expect(find.bySemanticsLabel('Mover C'), findsOneWidget);
    semantics.dispose();
    await _close(tester);
  });

  testWidgets('PGLIST-02: an empty title reads "Sem título"', (tester) async {
    await _open(tester, titles: ['', 'B']);

    expect(find.text('Sem título'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('PGLIST-02: rows show the relative updated_at and no excerpt', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('hoje'), findsNWidgets(3));
    expect(find.byType(Text), findsNWidgets(6));
    await _close(tester);
  });

  testWidgets('PGLIST-06: tapping a row calls onOpen with that page', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('B'));

    expect(_opened, [_ids[1]]);
    await _close(tester);
  });

  testWidgets('REORDER-03: dragging the last of three to the top changes only '
      'that row position', (tester) async {
    await _open(tester, reordering: true);
    final before = await _positions(tester);

    final gesture = await tester.startGesture(tester.getCenter(_handles.last));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(DraggingPageRow), findsOneWidget);
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await _settle(tester);

    final after = await _positions(tester);
    expect(after[_ids[0]], before[_ids[0]]);
    expect(after[_ids[1]], before[_ids[1]]);
    expect(after[_ids[2]], isNot(before[_ids[2]]));
    final order = ([..._ids]..sort((a, b) => after[a]!.compareTo(after[b]!)));
    expect(order, [_ids[2], _ids[0], _ids[1]]);
    await _close(tester);
  });

  testWidgets('REORDER-04: dropping a page where it started writes nothing', (
    tester,
  ) async {
    await _open(tester, reordering: true);
    final before = await _positions(tester);

    final gesture = await tester.startGesture(tester.getCenter(_handles.at(1)));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 5));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await _settle(tester);

    expect(await _positions(tester), before);
    await _close(tester);
  });

  testWidgets('REORDER-06: rebuilt from the database, the list reads in the '
      'order left by the last move', (tester) async {
    await _open(tester, reordering: true);
    await tester.runAsync(() => _app.pages.move(_ids[2], const AtStart()));
    await _settle(tester);

    final titles = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((t) => t == 'A' || t == 'B' || t == 'C')
        .toList();
    expect(titles, ['C', 'A', 'B']);
    await _close(tester);
  });

  testWidgets('EXCERPT-01: heading "Manhã" then text "Belém cedo" shows the '
      'excerpt "Belém cedo"', (tester) async {
    await _open(
      tester,
      titles: ['Roteiro'],
      seed: () async {
        await _block(_ids[0], BlockType.heading, 'Manhã');
        await _block(_ids[0], BlockType.text, 'Belém cedo');
      },
    );

    expect(find.text('Belém cedo'), findsOneWidget);
    expect(find.text('Manhã'), findsNothing);
    await _close(tester);
  });

  testWidgets('EXCERPT-03: a page with only a heading has no excerpt line', (
    tester,
  ) async {
    await _open(
      tester,
      titles: ['Roteiro'],
      seed: () => _block(_ids[0], BlockType.heading, 'Manhã'),
    );

    expect(find.text('Manhã'), findsNothing);
    expect(tester.widgetList<Text>(find.byType(Text)).map((t) => t.data), [
      'Roteiro',
      'hoje',
    ]);
    await _close(tester);
  });

  testWidgets('EDITED-04: a block saved today on a page from yesterday shows '
      '"hoje" without leaving the list', (tester) async {
    final today = DateTime.utc(2026, 10, 12, 15);
    await _open(
      tester,
      titles: ['Roteiro'],
      now: today.subtract(const Duration(days: 1)),
      seed: () async => _app.clock.current = today,
    );
    expect(find.text('ontem'), findsOneWidget);

    await tester.runAsync(() => _block(_ids[0], BlockType.text, 'Belém'));
    await _settle(tester);

    expect(find.text('hoje'), findsOneWidget);
    expect(find.text('ontem'), findsNothing);
    await _close(tester);
  });

  testWidgets('EXCERPT-05: editing the first qualifying block updates the '
      'excerpt in place', (tester) async {
    late String blockId;
    await _open(
      tester,
      titles: ['Roteiro'],
      seed: () async =>
          blockId = await _block(_ids[0], BlockType.text, 'Belém cedo'),
    );
    expect(find.text('Belém cedo'), findsOneWidget);

    await tester.runAsync(
      () => _app.blocks.applyChanges(_ids[0], [
        Update(blockId, BlockType.text, const BlockContent('Belém à tarde')),
      ]),
    );
    await _settle(tester);

    expect(find.text('Belém à tarde'), findsOneWidget);
    expect(find.text('Belém cedo'), findsNothing);
    await _close(tester);
  });

  testWidgets('EXCERPT-02: the excerpt is one line in itemTrecho, cut with an '
      'ellipsis', (tester) async {
    const long =
        'Belém de manhã, pastéis antes da fila. Tarde no LX Factory e '
        'depois o pôr do sol no miradouro.';
    await _open(
      tester,
      titles: ['Roteiro'],
      seed: () => _block(_ids[0], BlockType.text, long),
    );

    final excerpt = tester.widget<Text>(find.text(long));
    final styles = tester.element(find.text(long)).textStyles;
    expect(excerpt.style, styles.itemTrecho);
    expect(excerpt.maxLines, 1);
    expect(excerpt.overflow, TextOverflow.ellipsis);
    await _close(tester);
  });

  testWidgets('EXCERPT-01: reordering a page moves its excerpt with it and '
      'changes only that row position', (tester) async {
    await _open(
      tester,
      reordering: true,
      seed: () async {
        await _block(_ids[0], BlockType.text, 'a1');
        await _block(_ids[1], BlockType.text, 'b1');
        await _block(_ids[2], BlockType.text, 'c1');
      },
    );
    final before = await _positions(tester);

    final gesture = await tester.startGesture(tester.getCenter(_handles.last));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(_texts(tester, {'a1', 'b1', 'c1'}), ['c1', 'a1', 'b1']);
    await _settle(tester);

    final after = await _positions(tester);
    expect(after[_ids[0]], before[_ids[0]]);
    expect(after[_ids[1]], before[_ids[1]]);
    expect(after[_ids[2]], isNot(before[_ids[2]]));
    expect(_texts(tester, {'a1', 'b1', 'c1'}), ['c1', 'a1', 'b1']);
    await _close(tester);
  });
}
