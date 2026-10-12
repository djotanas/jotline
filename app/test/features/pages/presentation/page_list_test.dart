import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/dragging_page_row.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
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
}) async {
  _app = TestApp();
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
}
