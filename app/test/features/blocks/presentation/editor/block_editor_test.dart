import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

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
}
