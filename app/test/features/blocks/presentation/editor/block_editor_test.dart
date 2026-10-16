import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:jotline/features/blocks/presentation/editor/block_mapper.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../../helpers/editor_ime.dart';
import '../../../../helpers/pump_jot.dart';

class _CountingHttpOverrides extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('E2E-02: the editor attempted a network call');
  }
}

void main() {
  final textStyles = JotTextStyles.from(JotColors.light);

  Future<Editor> pumpEditor(
    WidgetTester tester,
    List<DocumentNode> nodes,
  ) async {
    final editor = createBlockEditor(MutableDocument(nodes: nodes));
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpJot(
      Scaffold(
        body: CustomScrollView(
          slivers: [BlockEditor(editor: editor, focusNode: focusNode)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return editor;
  }

  ParagraphNode paragraph(String id, String text) =>
      ParagraphNode(id: id, text: AttributedText(text));

  Rect rectAt(String nodeId, int offset) =>
      SuperEditorInspector.findDocumentLayout().getRectForPosition(
        DocumentPosition(
          nodeId: nodeId,
          nodePosition: TextNodePosition(offset: offset),
        ),
      )!;

  Rect componentRect(String nodeId) {
    final topLeft = SuperEditorInspector.findComponentOffset(
      nodeId,
      Alignment.topLeft,
    );
    return topLeft & SuperEditorInspector.findComponentSize(nodeId);
  }

  testWidgets('EDIT-03: a text block uses blocoTexto and a heading uses '
      'blocoTitulo', (tester) async {
    await pumpEditor(tester, [
      ParagraphNode(
        id: 'h',
        text: AttributedText('Manhã'),
        metadata: const {NodeMetadata.blockType: header1Attribution},
      ),
      paragraph('t', 'Belém cedo'),
    ]);

    expect(SuperEditorInspector.findParagraphStyle('t'), textStyles.blocoTexto);
    expect(
      SuperEditorInspector.findParagraphStyle('h'),
      textStyles.blocoTitulo,
    );
  });

  testWidgets('BAR-10: bold text is drawn in weight 600 and italic text in '
      'the italic face', (tester) async {
    final text = AttributedText('Pastéis com calma')
      ..addAttribution(boldAttribution, const SpanRange(0, 6))
      ..addAttribution(italicsAttribution, const SpanRange(12, 16));
    await pumpEditor(tester, [ParagraphNode(id: 't', text: text)]);

    final spans = <TextSpan>[];
    SuperEditorInspector.findRichTextInParagraph('t').visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    final bold = spans.singleWhere((s) => s.text == 'Pastéis');
    final italic = spans.singleWhere((s) => s.text == 'calma');
    final plain = spans.singleWhere((s) => s.text == ' com ');

    expect(bold.style!.fontWeight, FontWeight.w600);
    expect(bold.style!.fontStyle, isNot(FontStyle.italic));
    expect(italic.style!.fontStyle, FontStyle.italic);
    expect(italic.style!.fontWeight, FontWeight.w400);
    expect(plain.style!.fontWeight, FontWeight.w400);
    expect(plain.style!.fontStyle, isNot(FontStyle.italic));
  });

  testWidgets('BAR-11: a list item is indented 24 px with a bullet, and '
      'consecutive items are 4 px apart', (tester) async {
    await pumpEditor(tester, [
      paragraph('t', 'Belém'),
      ListItemNode.unordered(id: 'l1', text: AttributedText('Torre')),
      ListItemNode.unordered(id: 'l2', text: AttributedText('MAAT')),
    ]);

    expect(rectAt('l1', 0).left - rectAt('t', 0).left, 24);
    expect(componentRect('l2').top - componentRect('l1').bottom, 4);
    expect(componentRect('l1').top - componentRect('t').bottom, 16);
    final bullet = find.descendant(
      of: find.byType(UnorderedListItemComponent).first,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    expect(bullet, findsOneWidget);
  });

  testWidgets('EDIT-03: "# " and "- " typed at the start of a block stay '
      'text', (tester) async {
    final editor = await pumpEditor(tester, [
      paragraph('a', ''),
      paragraph('b', ''),
    ]);

    await tester.placeCaretInParagraph('a', 0);
    await tester.typeImeText('# Manhã');
    await tester.placeCaretInParagraph('b', 0);
    await tester.typeImeText('- Torre');

    final a = editor.document.getNodeById('a')!;
    final b = editor.document.getNodeById('b')!;
    expect(a, isA<ParagraphNode>());
    expect(b, isA<ParagraphNode>());
    expect(a.getMetadataValue(NodeMetadata.blockType), paragraphAttribution);
    expect((a as ParagraphNode).text.toPlainText(), '# Manhã');
    expect((b as ParagraphNode).text.toPlainText(), '- Torre');
    expect(editor.document.nodeCount, 2);
  });

  testWidgets('EDIT-02: the caret is 2 px wide in accent', (tester) async {
    await pumpEditor(tester, [paragraph('t', 'Belém')]);

    await tester.placeCaretInParagraph('t', 2);

    final caret = SuperEditorInspector.findMobileCaret();
    final box = tester.widget<ColoredBox>(caret);
    expect(box.color.withValues(alpha: 1), JotColors.light.accent);
    expect(tester.getSize(caret).width, 2);
  });

  testWidgets('E2E-02: a pasted image URL followed by Enter creates no image '
      'node and makes no HTTP call', (tester) async {
    final previous = HttpOverrides.current;
    final http = _CountingHttpOverrides();
    HttpOverrides.global = http;
    addTearDown(() => HttpOverrides.global = previous);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, Object?>{'text': 'https://jotline.app/foto.png'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final editor = await pumpEditor(tester, [paragraph('a', '')]);
    await tester.placeCaretInParagraph('a', 0);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.typeImeText('\n');
    await tester.pumpAndSettle();

    expect(
      (editor.document.first as ParagraphNode).text.toPlainText(),
      'https://jotline.app/foto.png',
    );
    expect(editor.document.whereType<ImageNode>(), isEmpty);
    expect(
      (editor.document.first as ParagraphNode).text.getAttributionSpansByFilter(
        (_) => true,
      ),
      isEmpty,
    );
    expect(http.attempts, 0);
  });

  group('editing rules', () {
    late Editor editor;

    Future<void> pumpBlocks(
      WidgetTester tester,
      List<(String, BlockType, BlockContent)> blocks,
    ) async {
      editor = createBlockEditor(
        MutableDocument(
          nodes: [
            for (final (id, type, content) in blocks)
              BlockMapper.toNode(type, content.forType(type), id: id),
          ],
        ),
      );
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpJot(
        Scaffold(
          body: CustomScrollView(
            slivers: [BlockEditor(editor: editor, focusNode: focusNode)],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    List<(BlockType, String)> blocks() => [
      for (final node in editor.document)
        switch (BlockMapper.fromNode(node)) {
          (final type, final content) => (type, content.text),
        },
    ];

    bool? checkedAt(int index) =>
        BlockMapper.fromNode(editor.document.getNodeAt(index)!).$2.checked;

    DocumentSelection caretAt(String nodeId, int offset) =>
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: nodeId,
            nodePosition: TextNodePosition(offset: offset),
          ),
        );

    String idAt(int index) => editor.document.getNodeAt(index)!.id;

    Future<void> enter(WidgetTester tester) => tester.typeImeText('\n');

    const text = BlockType.text;
    const heading = BlockType.heading;
    const list = BlockType.bulletedListItem;
    const checklist = BlockType.checklistItem;

    testWidgets('EDIT-07: Enter at the end of a text block creates a text '
        'block below with the caret in it', (tester) async {
      await pumpBlocks(tester, [
        ('a', text, const BlockContent('Belém')),
        ('b', text, const BlockContent('Fim')),
      ]);

      await tester.placeCaretInParagraph('a', 5);
      await enter(tester);
      await tester.typeImeText('x');

      expect(blocks(), [(text, 'Belém'), (text, 'x'), (text, 'Fim')]);
      expect(idAt(0), 'a');
      expect(editor.composer.selection, caretAt(idAt(1), 1));
    });

    testWidgets('EDIT-07: Enter at the end of a heading creates a text block '
        'below with the caret in it', (tester) async {
      await pumpBlocks(tester, [('h', heading, const BlockContent('Manhã'))]);

      await tester.placeCaretInParagraph('h', 5);
      await enter(tester);

      expect(blocks(), [(heading, 'Manhã'), (text, '')]);
      expect(editor.composer.selection, caretAt(idAt(1), 0));
    });

    testWidgets('EDIT-08: Enter in the middle of a text block splits it into '
        'two text blocks', (tester) async {
      await pumpBlocks(tester, [('a', text, const BlockContent('Belém cedo'))]);

      await tester.placeCaretInParagraph('a', 5);
      await enter(tester);

      expect(blocks(), [(text, 'Belém'), (text, ' cedo')]);
      expect(idAt(0), 'a');
      expect(editor.composer.selection, caretAt(idAt(1), 0));
    });

    testWidgets('EDIT-08: Enter in the middle of a heading splits it into two '
        'headings', (tester) async {
      await pumpBlocks(tester, [
        ('h', heading, const BlockContent('Manhã cedo')),
      ]);

      await tester.placeCaretInParagraph('h', 5);
      await enter(tester);

      expect(blocks(), [(heading, 'Manhã'), (heading, ' cedo')]);
      expect(idAt(0), 'h');
    });

    testWidgets(
      'EDIT-08: Enter in the middle of a list item and of a checklist '
      'item keeps their type',
      (tester) async {
        await pumpBlocks(tester, [
          ('l', list, const BlockContent('Torre de Belém')),
          ('k', checklist, const BlockContent('Reservar jantar')),
        ]);

        await tester.placeCaretInParagraph('l', 5);
        await enter(tester);
        await tester.placeCaretInParagraph('k', 8);
        await enter(tester);

        expect(blocks(), [
          (list, 'Torre'),
          (list, ' de Belém'),
          (checklist, 'Reservar'),
          (checklist, ' jantar'),
        ]);
      },
    );

    testWidgets('EDIT-09: Backspace at the start of a text block merges it '
        'into the block above, caret at the junction', (tester) async {
      await pumpBlocks(tester, [
        ('a', text, const BlockContent('Belém')),
        ('b', text, const BlockContent(' cedo')),
      ]);

      await tester.placeCaretInParagraph('b', 0);
      await tester.imeBackspace();

      expect(blocks(), [(text, 'Belém cedo')]);
      expect(idAt(0), 'a');
      expect(editor.composer.selection, caretAt('a', 5));
    });

    testWidgets('EDIT-09: Backspace at the start of a text block below a list '
        'item merges it into the list item', (tester) async {
      await pumpBlocks(tester, [
        ('l', list, const BlockContent('Torre')),
        ('b', text, const BlockContent(' de Belém')),
      ]);

      await tester.placeCaretInParagraph('b', 0);
      await tester.imeBackspace();

      expect(blocks(), [(list, 'Torre de Belém')]);
      expect(idAt(0), 'l');
      expect(editor.composer.selection, caretAt('l', 5));
    });

    testWidgets('EDIT-10: Backspace at the start of the first block changes '
        'nothing', (tester) async {
      await pumpBlocks(tester, [
        ('a', text, const BlockContent('Belém')),
        ('b', text, const BlockContent('Fim')),
      ]);

      await tester.placeCaretInParagraph('a', 0);
      await tester.imeBackspace();

      expect(blocks(), [(text, 'Belém'), (text, 'Fim')]);
      expect(editor.composer.selection, caretAt('a', 0));
    });

    testWidgets('CHECK-04: Enter at the end of a checked checklist item '
        'creates an unchecked checklist item below', (tester) async {
      await pumpBlocks(tester, [
        ('k', checklist, const BlockContent('Bilhete', checked: true)),
      ]);

      await tester.placeCaretInParagraph('k', 7);
      await enter(tester);
      await tester.typeImeText('Mapa');

      expect(blocks(), [(checklist, 'Bilhete'), (checklist, 'Mapa')]);
      expect(checkedAt(0), isTrue);
      expect(checkedAt(1), isFalse);
      expect(editor.composer.selection, caretAt(idAt(1), 4));
    });

    testWidgets('CHECK-05: Enter at the end of a list item creates a list item '
        'below', (tester) async {
      await pumpBlocks(tester, [('l', list, const BlockContent('Torre'))]);

      await tester.placeCaretInParagraph('l', 5);
      await enter(tester);
      await tester.typeImeText('MAAT');

      expect(blocks(), [(list, 'Torre'), (list, 'MAAT')]);
      expect(editor.composer.selection, caretAt(idAt(1), 4));
    });

    testWidgets('CHECK-06: Enter on an empty list item turns it into text', (
      tester,
    ) async {
      await pumpBlocks(tester, [
        ('l', list, const BlockContent('Torre')),
        ('e', list, const BlockContent('')),
      ]);

      await tester.placeCaretInParagraph('e', 0);
      await enter(tester);

      expect(blocks(), [(list, 'Torre'), (text, '')]);
      expect(idAt(1), 'e');
      expect(editor.composer.selection, caretAt('e', 0));
    });

    testWidgets('CHECK-06: Enter on an empty checklist item turns it into '
        'text', (tester) async {
      await pumpBlocks(tester, [
        ('k', checklist, const BlockContent('Bilhete')),
        ('e', checklist, const BlockContent('')),
      ]);

      await tester.placeCaretInParagraph('e', 0);
      await enter(tester);

      expect(blocks(), [(checklist, 'Bilhete'), (text, '')]);
      expect(idAt(1), 'e');
      expect(checkedAt(1), isNull);
    });

    testWidgets('CHECK-06: Backspace on an empty list item turns it into '
        'text', (tester) async {
      await pumpBlocks(tester, [
        ('l', list, const BlockContent('Torre')),
        ('e', list, const BlockContent('')),
      ]);

      await tester.placeCaretInParagraph('e', 0);
      await tester.imeBackspace();

      expect(blocks(), [(list, 'Torre'), (text, '')]);
      expect(idAt(1), 'e');
    });

    testWidgets('CHECK-06: Backspace on an empty checklist item turns it into '
        'text', (tester) async {
      await pumpBlocks(tester, [
        ('k', checklist, const BlockContent('Bilhete')),
        ('e', checklist, const BlockContent('')),
      ]);

      await tester.placeCaretInParagraph('e', 0);
      await tester.imeBackspace();

      expect(blocks(), [(checklist, 'Bilhete'), (text, '')]);
      expect(idAt(1), 'e');
    });

    testWidgets('CHECK-07: Backspace at the start of a list item turns it into '
        'text, keeping its text', (tester) async {
      await pumpBlocks(tester, [
        ('a', text, const BlockContent('Roteiro')),
        ('l', list, const BlockContent('Torre')),
      ]);

      await tester.placeCaretInParagraph('l', 0);
      await tester.imeBackspace();

      expect(blocks(), [(text, 'Roteiro'), (text, 'Torre')]);
      expect(idAt(1), 'l');
      expect(editor.composer.selection, caretAt('l', 0));
    });

    testWidgets('CHECK-07: Backspace at the start of a checklist item turns it '
        'into text, keeping its text', (tester) async {
      await pumpBlocks(tester, [
        ('a', text, const BlockContent('Roteiro')),
        ('k', checklist, const BlockContent('Bilhete', checked: true)),
      ]);

      await tester.placeCaretInParagraph('k', 0);
      await tester.imeBackspace();

      expect(blocks(), [(text, 'Roteiro'), (text, 'Bilhete')]);
      expect(idAt(1), 'k');
      expect(checkedAt(1), isNull);
    });

    testWidgets('CHECK-07: Backspace at the start of a heading turns it into '
        'text, keeping its text', (tester) async {
      await pumpBlocks(tester, [
        ('a', text, const BlockContent('Roteiro')),
        ('h', heading, const BlockContent('Manhã')),
      ]);

      await tester.placeCaretInParagraph('h', 0);
      await tester.imeBackspace();

      expect(blocks(), [(text, 'Roteiro'), (text, 'Manhã')]);
      expect(idAt(1), 'h');
    });

    testWidgets(
      'EDGE-03: Enter right after a flag emoji splits after the whole '
      'emoji',
      (tester) async {
        await pumpBlocks(tester, [
          ('a', text, const BlockContent('Oi 🇧🇷 já')),
        ]);

        await tester.placeCaretInParagraph('a', 7);
        await enter(tester);

        expect(blocks(), [(text, 'Oi 🇧🇷'), (text, ' já')]);
      },
    );
  });
}
