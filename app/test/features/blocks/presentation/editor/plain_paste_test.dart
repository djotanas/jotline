import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/features/blocks/presentation/editor/plain_paste.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Editor editorWith(List<DocumentNode> nodes) => Editor(
    editables: {
      Editor.documentKey: MutableDocument(nodes: nodes),
      Editor.composerKey: MutableDocumentComposer(),
    },
    requestHandlers: [
      plainPasteHandler,
      ...defaultRequestHandlers.cast<EditRequestHandler>(),
    ],
  );

  DocumentPosition at(String nodeId, int offset) => DocumentPosition(
    nodeId: nodeId,
    nodePosition: TextNodePosition(offset: offset),
  );

  void paste(Editor editor, String content, DocumentPosition position) => editor
      .execute([PasteEditorRequest(content: content, pastePosition: position)]);

  List<(Type, String)> nodes(Editor editor) => [
    for (final node in editor.document)
      (node.runtimeType, (node as TextNode).text.toPlainText()),
  ];

  bool hasAttributions(Editor editor) => editor.document.any(
    (node) => (node as TextNode).text
        .getAttributionSpansByFilter((_) => true)
        .isNotEmpty,
  );

  test('EDIT-11: three lines pasted into "Ab|c" give "Ab1", "2", "3c" as '
      'paragraphs with no marks', () {
    final editor = editorWith([
      ParagraphNode(id: 'a', text: AttributedText('Abc')),
    ]);

    paste(editor, '1\n2\n3', at('a', 2));

    expect(nodes(editor), [
      (ParagraphNode, 'Ab1'),
      (ParagraphNode, '2'),
      (ParagraphNode, '3c'),
    ]);
    expect(editor.document.first.id, 'a');
    expect(hasAttributions(editor), isFalse);
    expect(
      editor.composer.selection,
      DocumentSelection.collapsed(position: at(editor.document.last.id, 1)),
    );
  });

  test(r'EDIT-11: \r\n and \r also split lines', () {
    final editor = editorWith([
      ParagraphNode(id: 'a', text: AttributedText('Ab')),
    ]);

    paste(editor, '1\r\n2\r3', at('a', 2));

    expect(nodes(editor), [
      (ParagraphNode, 'Ab1'),
      (ParagraphNode, '2'),
      (ParagraphNode, '3'),
    ]);
  });

  test('EDIT-11: a pasted URL stays plain text, with no link '
      'attribution', () {
    final editor = editorWith([
      ParagraphNode(id: 'a', text: AttributedText('Ver ')),
    ]);

    paste(editor, 'https://jotline.app/a\nhttps://jotline.app/b', at('a', 4));

    expect(nodes(editor), [
      (ParagraphNode, 'Ver https://jotline.app/a'),
      (ParagraphNode, 'https://jotline.app/b'),
    ]);
    expect(hasAttributions(editor), isFalse);
  });

  testWidgets('SAVE-08: paste over a cross-block selection deletes it '
      'first', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, Object?>{'text': 'X\nY'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final editor =
        editorWith([
          ParagraphNode(id: 'a', text: AttributedText('Abc')),
          ParagraphNode(id: 'b', text: AttributedText('Def')),
          ParagraphNode(id: 'c', text: AttributedText('Ghi')),
        ])..execute([
          ChangeSelectionRequest(
            DocumentSelection(base: at('a', 1), extent: at('c', 2)),
            SelectionChangeType.expandSelection,
            SelectionReason.userInteraction,
          ),
        ]);

    CommonEditorOperations(
      document: editor.document,
      editor: editor,
      composer: editor.composer,
      documentLayoutResolver: () => throw UnimplementedError(),
    ).paste();
    await tester.pump();

    expect(nodes(editor), [(ParagraphNode, 'AX'), (ParagraphNode, 'Yi')]);
    expect(editor.document.first.id, 'a');
    expect(editor.document.getNodeById('b'), isNull);
    expect(editor.document.getNodeById('c'), isNull);
  });
}
