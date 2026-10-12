import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_flutter_quill/block_mapper.dart';
import 'package:spike_flutter_quill/block_row.dart';
import 'package:spike_flutter_quill/block_sync.dart';

void main() {
  BlockRow row(String id, String type, BlockContent content) =>
      BlockRow(id: id, type: type, contentJson: content.toJson(), position: id);

  final roundTripRows = [
    row('1', BlockType.heading, const BlockContent('Manhã em Belém')),
    row(
      '2',
      BlockType.text,
      const BlockContent(
        'Ação, coração e pão 🇧🇷 com café',
        marks: [
          Mark(0, 4, MarkType.bold),
          Mark(2, 14, MarkType.italic),
          Mark(20, 24, MarkType.bold),
        ],
      ),
    ),
    row(
      '3',
      BlockType.bulletedListItem,
      const BlockContent('Pastéis', marks: [Mark(0, 7, MarkType.italic)]),
    ),
    row(
      '4',
      BlockType.checklistItem,
      const BlockContent('Feito', checked: true),
    ),
    row(
      '5',
      BlockType.checklistItem,
      const BlockContent('Pendente', checked: false),
    ),
    row('6', BlockType.text, const BlockContent('')),
    row(
      '7',
      BlockType.heading,
      const BlockContent('Título', marks: [Mark(0, 6, MarkType.bold)]),
    ),
  ];

  test('SPIKE-04: every row round-trips through lines without loss', () {
    final document = Document.fromDelta(BlockMapper.toDelta(roundTripRows));
    final lines = linesOf(document);
    expect(lines, hasLength(roundTripRows.length));
    for (final (index, line) in lines.indexed) {
      final (type, contentJson) = BlockMapper.fromLine(line);
      expect(type, roundTripRows[index].type);
      expect(BlockContent.fromJson(contentJson), roundTripRows[index].content);
    }
  });

  group('identity through the controller', () {
    late InMemoryBlockStore store;
    late QuillController controller;
    late BlockSync sync;

    setUp(() {
      store = InMemoryBlockStore([
        row('a', BlockType.text, const BlockContent('Olá mundo')),
        row('b', BlockType.text, const BlockContent('Segundo')),
        row('c', BlockType.bulletedListItem, const BlockContent('Item')),
        row(
          'd',
          BlockType.checklistItem,
          const BlockContent('Tarefa', checked: false),
        ),
      ]);
      final rows = store.visible;
      controller = QuillController(
        document: Document.fromDelta(BlockMapper.toDelta(rows)),
        selection: const TextSelection.collapsed(offset: 0),
      );
      sync = BlockSync(
        controller.document,
        store,
        loadedIds: [for (final r in rows) r.id],
      );
    });

    tearDown(() => sync.dispose());

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    int offsetOf(String blockId) {
      final line = linesOf(
        controller.document,
      ).firstWhere((l) => sync.blockIdOf(l) == blockId);
      return line.documentOffset;
    }

    Future<void> type(int at, String text) async {
      controller.replaceText(
        at,
        0,
        text,
        TextSelection.collapsed(offset: at + text.length),
      );
      await settle();
    }

    Future<void> backspace(int at) async {
      controller.replaceText(
        at - 1,
        1,
        '',
        TextSelection.collapsed(offset: at - 1),
      );
      await settle();
    }

    List<(String, String)> rows() => [
      for (final r in store.visible) (r.type, r.content.text),
    ];

    test(
      'SPIKE-02/03: typing keeps the id and touches only that line',
      () async {
        await type(offsetOf('a') + 3, ' grande');
        expect(sync.pendingBlockIds, {'a'});
        sync.flush();
        expect(store.byId('a')!.content.text, 'Olá grande mundo');
        expect(store.writes, [const BlockWrite('update', 'a')]);
      },
    );

    test('SPIKE-02: Enter in the middle keeps the upper id', () async {
      await type(offsetOf('a') + 4, '\n');
      sync.flush();
      expect(rows().take(3), [
        (BlockType.text, 'Olá '),
        (BlockType.text, 'mundo'),
        (BlockType.text, 'Segundo'),
      ]);
      expect(store.visible.first.id, 'a');
      expect(store.writes.where((w) => w.kind == 'insert'), hasLength(1));
    });

    test(
      'SPIKE-02: Backspace at the start merges and keeps the upper id',
      () async {
        await backspace(offsetOf('b'));
        sync.flush();
        expect(store.byId('a')!.content.text, 'Olá mundoSegundo');
        expect(store.byId('b')!.deleted, isTrue);
      },
    );

    test('BAR-05: changing the type keeps the line object', () async {
      controller.formatText(offsetOf('a'), 0, Attribute.h1);
      await settle();
      sync.flush();
      expect(store.byId('a')!.type, BlockType.heading);
      controller.formatText(offsetOf('a'), 0, Attribute.ul);
      await settle();
      sync.flush();
      expect(store.byId('a')!.type, BlockType.bulletedListItem);
      expect(store.writes.map((w) => w.id).toSet(), {'a'});
    });

    test('CHECK-02: toggling checked changes only that row', () async {
      controller.formatText(offsetOf('d'), 0, Attribute.checked);
      await settle();
      sync.flush();
      expect(store.writes, [const BlockWrite('update', 'd')]);
      expect(store.byId('d')!.content.checked, isTrue);
    });

    test(
      'GAP CHECK-04: Enter after a checked item creates a checked item',
      () async {
        controller.formatText(offsetOf('d'), 0, Attribute.checked);
        await type(offsetOf('d') + 6, '\n');
        await type(offsetOf('d') + 7, 'Nova');
        sync.flush();
        expect(store.visible.last.type, BlockType.checklistItem);
        expect(store.visible.last.content.checked, isTrue);
      },
    );

    test('CHECK-06: Enter on an empty list item turns it into text', () async {
      await type(offsetOf('c') + 4, '\n');
      await type(offsetOf('c') + 5, '\n');
      final lines = linesOf(controller.document);
      expect(BlockMapper.fromLine(lines[3]).$1, BlockType.text);
    });

    test(
      'GAP CHECK-07: Backspace at the start of a list item merges',
      () async {
        await backspace(offsetOf('c'));
        sync.flush();
        expect(store.byId('c')!.deleted, isTrue);
        expect(store.byId('b')!.content.text, 'SegundoItem');
      },
    );

    test('BAR-07: bold on a range writes a bold mark', () async {
      controller.formatText(offsetOf('a'), 3, Attribute.bold);
      await settle();
      sync.flush();
      expect(store.byId('a')!.content.marks, [const Mark(0, 3, MarkType.bold)]);
    });

    test(
      'SPIKE-02 risk: replacing the document drops every identity',
      () async {
        controller.document = Document.fromDelta(controller.document.toDelta());
        expect(
          linesOf(controller.document).map(sync.blockIdOf),
          everyElement(isNull),
        );
      },
    );
  });
}
