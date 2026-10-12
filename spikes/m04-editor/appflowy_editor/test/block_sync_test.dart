import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_appflowy_editor/block_mapper.dart';
import 'package:spike_appflowy_editor/block_row.dart';
import 'package:spike_appflowy_editor/block_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BlockRow row(String id, String type, BlockContent content) =>
      BlockRow(id: id, type: type, contentJson: content.toJson(), position: id);

  late InMemoryBlockStore store;
  late EditorState editorState;
  late BlockSync sync;

  setUp(() {
    store = InMemoryBlockStore([
      row('1', BlockType.heading, const BlockContent('Manhã cedo')),
      row('2', BlockType.text, const BlockContent('Olá mundo')),
      row('3', BlockType.text, const BlockContent('Segundo')),
      row('4', BlockType.bulletedListItem, const BlockContent('Item')),
      row(
        '5',
        BlockType.checklistItem,
        const BlockContent('Tarefa', checked: true),
      ),
    ]);
    final rows = store.visible;
    editorState = EditorState(document: BlockMapper.toDocument(rows));
    sync = BlockSync(editorState, store, loadedIds: rows.map((r) => r.id));
  });

  tearDown(() => sync.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void caret(String nodeId, int offset) {
    final node = editorState.document.root.children.firstWhere(
      (n) => n.id == nodeId,
    );
    editorState.selection = Selection.collapsed(
      Position(path: node.path, offset: offset),
    );
  }

  Future<void> pressEnter() async {
    for (final event in standardCharacterShortcutEvents) {
      if (event.character == '\n' && await event.handler(editorState)) break;
    }
    await settle();
  }

  Future<void> pressBackspace() async {
    for (final event in standardCommandShortcutEvents) {
      if (event.command.split(',').contains('backspace') &&
          event.handler(editorState) == KeyEventResult.handled) {
        break;
      }
    }
    await settle();
  }

  List<(String, String)> rows() => [
    for (final r in store.visible) (r.type, r.content.text),
  ];

  test(
    'SPIKE-02/03: typing keeps the id and touches only that block',
    () async {
      final node = editorState.getNodeAtPath([1])!;
      await editorState.apply(
        editorState.transaction..insertText(node, 3, ' grande'),
      );
      await settle();
      expect(sync.pendingNodeIds, {'2'});
      sync.flush();
      expect(store.byId('2')!.content.text, 'Olá grande mundo');
      expect(store.writes, [const BlockWrite('update', '2')]);
    },
  );

  test(
    'SPIKE-02: Enter in the middle splits; the lower block is new',
    () async {
      caret('2', 4);
      await pressEnter();
      sync.flush();
      expect(rows().sublist(1, 3), [
        (BlockType.text, 'Olá '),
        (BlockType.text, 'mundo'),
      ]);
      expect(store.visible[1].id, '2');
      expect(store.writes, contains(const BlockWrite('update', '2')));
      expect(store.writes.map((w) => w.kind).toSet(), {'update', 'insert'});
    },
  );

  test(
    'SPIKE-02: Backspace at the start merges into the upper block',
    () async {
      caret('3', 0);
      await pressBackspace();
      sync.flush();
      expect(store.byId('2')!.content.text, 'Olá mundoSegundo');
      expect(store.byId('3')!.deleted, isTrue);
    },
  );

  test('BAR-05: type change replaces the node and its library id', () async {
    caret('2', 1);
    await editorState.formatNode(
      editorState.selection,
      (node) => node.copyWith(
        type: HeadingBlockKeys.type,
        attributes: {...node.attributes, HeadingBlockKeys.level: 1},
      ),
    );
    await settle();
    final newNodeId = editorState.getNodeAtPath([1])!.id;
    expect(newNodeId, isNot('2'), reason: 'Node.copyWith assigns nanoid(6)');
    sync.flush();
    expect(sync.blockIdOf(newNodeId), '2');
    expect(store.byId('2')!.type, BlockType.heading);
    expect(store.writes, [const BlockWrite('update', '2')]);
  });

  test('CHECK-07: Backspace at the start of a list item makes text', () async {
    caret('4', 0);
    await pressBackspace();
    sync.flush();
    expect(store.byId('4')!.type, BlockType.text);
    expect(store.byId('4')!.deleted, isFalse);
    expect(store.byId('4')!.content.text, 'Item');
  });

  test('CHECK-07: Backspace at the start of a heading makes text', () async {
    caret('1', 0);
    await pressBackspace();
    sync.flush();
    expect(store.byId('1')!.type, BlockType.text);
  });

  test(
    'CHECK-04: Enter at the end of a checked item adds an unchecked one',
    () async {
      caret('5', 6);
      await pressEnter();
      final last = editorState.document.root.children.last;
      await editorState.apply(
        editorState.transaction..insertText(last, 0, 'Nova'),
      );
      await settle();
      sync.flush();
      expect(store.visible.last.type, BlockType.checklistItem);
      expect(store.visible.last.content.checked, isFalse);
    },
  );

  test('CHECK-06: Enter on an empty list item turns it into text', () async {
    caret('4', 4);
    await pressEnter();
    await pressEnter();
    expect(editorState.getNodeAtPath([4])!.type, ParagraphBlockKeys.type);
  });

  test('EDIT-07: Enter at the end of a heading creates a text block', () async {
    caret('1', 10);
    await pressEnter();
    expect(editorState.getNodeAtPath([1])!.type, ParagraphBlockKeys.type);
  });

  test('GAP EDIT-08: splitting a heading gives a paragraph below', () async {
    caret('1', 5);
    await pressEnter();
    expect(editorState.getNodeAtPath([1])!.type, ParagraphBlockKeys.type);
  });

  test('CHECK-02: toggling checked changes only that row', () async {
    final node = editorState.getNodeAtPath([4])!;
    await editorState.apply(
      editorState.transaction
        ..updateNode(node, {TodoListBlockKeys.checked: false}),
    );
    await settle();
    sync.flush();
    expect(store.writes, [const BlockWrite('update', '5')]);
    expect(store.byId('5')!.content.checked, isFalse);
  });

  test('BAR-07: bold on a selection writes a bold mark', () async {
    final node = editorState.getNodeAtPath([1])!;
    editorState.selection = Selection(
      start: Position(path: node.path),
      end: Position(path: node.path, offset: 3),
    );
    await editorState.toggleAttribute(AppFlowyRichTextKeys.bold);
    await settle();
    sync.flush();
    expect(store.byId('2')!.content.marks, [const Mark(0, 3, MarkType.bold)]);
  });
}
