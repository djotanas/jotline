import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/editor/block_mapper.dart';
import 'package:jotline/features/blocks/presentation/editor/components/drawing_block.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  Block row(String id, BlockType type, StoredContent content) => Block(
    id: id,
    pageId: 'page',
    type: type.id,
    contentJson: content.toJson(),
    position: id,
    version: 0,
    updatedAt: DateTime.utc(2026, 10, 11),
    updatedBy: 'user',
  );

  final rows = [
    row(
      'h',
      BlockType.heading,
      const BlockContent(
        'Manhã em Belém',
        marks: [Mark(0, 5, MarkType.bold), Mark(9, 14, MarkType.italic)],
      ),
    ),
    row(
      't',
      BlockType.text,
      const BlockContent(
        'Ação e pão',
        marks: [Mark(0, 4, MarkType.bold), Mark(2, 10, MarkType.italic)],
      ),
    ),
    row(
      'l',
      BlockType.bulletedListItem,
      const BlockContent('Pastéis', marks: [Mark(0, 7, MarkType.italic)]),
    ),
    row(
      'k',
      BlockType.checklistItem,
      const BlockContent(
        'Bilhete',
        marks: [Mark(0, 3, MarkType.bold)],
        checked: true,
      ),
    ),
  ];

  group('BlockMapper', () {
    test('SAVE-11: each of the four types round-trips with text, bold, '
        'italic and checked', () {
      final document = BlockMapper.toDocument(rows);

      final back = [for (final node in document) BlockMapper.fromNode(node)];

      expect(back, [
        for (final r in rows)
          (BlockType.fromId(r.type), BlockContent.fromJson(r.contentJson)),
      ]);
      expect((back[3].$2 as BlockContent).checked, isTrue);
      expect((back[1].$2 as BlockContent).checked, isNull);
    });

    test('SAVE-11: each type maps to its editor node', () {
      final document = BlockMapper.toDocument(rows);

      final heading = document.getNodeById('h')! as ParagraphNode;
      expect(
        heading.getMetadataValue(NodeMetadata.blockType),
        header1Attribution,
      );
      final text = document.getNodeById('t')! as ParagraphNode;
      expect(
        text.getMetadataValue(NodeMetadata.blockType),
        paragraphAttribution,
      );
      final item = document.getNodeById('l')! as ListItemNode;
      expect(item.type, ListItemType.unordered);
      final task = document.getNodeById('k')! as TaskNode;
      expect(task.isComplete, isTrue);
      expect(task.text.toPlainText(), 'Bilhete');
    });

    test('SAVE-11: a loaded node id is the block id, in row order', () {
      final document = BlockMapper.toDocument(rows);

      expect([for (final node in document) node.id], ['h', 't', 'l', 'k']);
    });

    test('EDIT-04: an empty row list gives one empty paragraph', () {
      final document = BlockMapper.toDocument(const []);

      expect(document.nodeCount, 1);
      final node = document.first as ParagraphNode;
      expect(node.text.toPlainText(), '');
      expect(
        node.getMetadataValue(NodeMetadata.blockType),
        paragraphAttribution,
      );
    });

    test('EDIT-05: the empty paragraph id is not a block id', () {
      final first = BlockMapper.toDocument(const []).first.id;
      final second = BlockMapper.toDocument(const []).first.id;

      expect(first, isNotEmpty);
      expect(first, isNot(second));
      expect([for (final r in rows) r.id], isNot(contains(first)));
    });

    test('SAVE-10: marks at the text edges map inclusive spans to an '
        'exclusive end', () {
      const content = BlockContent(
        'abc',
        marks: [Mark(0, 1, MarkType.bold), Mark(2, 3, MarkType.italic)],
      );

      final node =
          BlockMapper.toNode(BlockType.text, content, id: 'n') as TextNode;

      expect(
        node.text.getAttributionSpans({boldAttribution}).single,
        const AttributionSpan(attribution: boldAttribution, start: 0, end: 0),
      );
      expect(
        node.text.getAttributionSpans({italicsAttribution}).single,
        const AttributionSpan(
          attribution: italicsAttribution,
          start: 2,
          end: 2,
        ),
      );

      final whole = AttributedText('abc')
        ..addAttribution(boldAttribution, const SpanRange(0, 2));
      final (_, read as BlockContent) = BlockMapper.fromNode(
        ParagraphNode(id: 'w', text: whole),
      );
      expect(read.marks, const [Mark(0, 3, MarkType.bold)]);
    });

    test('EDGE-03: a flag emoji with marks around it keeps UTF-16 '
        'offsets', () {
      const content = BlockContent(
        'Oi 🇧🇷 já',
        marks: [Mark(0, 2, MarkType.bold), Mark(3, 7, MarkType.italic)],
      );

      final node = BlockMapper.toNode(BlockType.text, content, id: 'n');
      final (type, back as BlockContent) = BlockMapper.fromNode(node);

      expect(type, BlockType.text);
      expect(back.text, 'Oi 🇧🇷 já');
      expect(back.marks, const [
        Mark(0, 2, MarkType.bold),
        Mark(3, 7, MarkType.italic),
      ]);
    });

    test('SAVE-10: list and task indent is dropped', () {
      final item = ListItemNode.unordered(
        id: 'l',
        text: AttributedText('Item'),
        indent: 2,
      );
      final task = TaskNode(
        id: 'k',
        text: AttributedText('Task'),
        isComplete: false,
        indent: 1,
      );

      final (itemType, itemContent) = BlockMapper.fromNode(item);
      final (taskType, taskContent) = BlockMapper.fromNode(task);
      final itemBack =
          BlockMapper.toNode(itemType, itemContent, id: 'l') as ListItemNode;
      final taskBack =
          BlockMapper.toNode(taskType, taskContent, id: 'k') as TaskNode;

      expect(itemType, BlockType.bulletedListItem);
      expect(taskType, BlockType.checklistItem);
      expect(itemBack.indent, 0);
      expect(taskBack.indent, 0);
    });

    test('SAVE-10: a link attribution is dropped, bold kept', () {
      final text = AttributedText('ver site')
        ..addAttribution(
          const LinkAttribution('https://a.b'),
          const SpanRange(4, 7),
        )
        ..addAttribution(boldAttribution, const SpanRange(0, 2));

      final (type, content as BlockContent) = BlockMapper.fromNode(
        ParagraphNode(id: 'p', text: text),
      );

      expect(type, BlockType.text);
      expect(content.text, 'ver site');
      expect(content.marks, const [Mark(0, 3, MarkType.bold)]);
    });

    test('SAVE-10: an unknown node maps to an empty text block', () {
      final (type, content) = BlockMapper.fromNode(
        HorizontalRuleNode(id: 'hr'),
      );

      expect(type, BlockType.text);
      expect(content, const BlockContent(''));
    });

    test('SAVE-10: a paragraph of another block type maps to text', () {
      final node = ParagraphNode(
        id: 'q',
        text: AttributedText('Citação'),
        metadata: const {NodeMetadata.blockType: blockquoteAttribution},
      );

      final (type, content as BlockContent) = BlockMapper.fromNode(node);

      expect(type, BlockType.text);
      expect(content.text, 'Citação');
    });

    test('SAVE-10: an ordered list item maps to a bulleted list item', () {
      final (type, _) = BlockMapper.fromNode(
        ListItemNode.ordered(id: 'o', text: AttributedText('Um')),
      );

      expect(type, BlockType.bulletedListItem);
    });

    group('drawing', () {
      const drawing = DrawingContent([
        Stroke(
          tool: DrawingTool.highlighter,
          color: DrawingColor.accent,
          width: 6,
          points: [StrokePoint(60, 470, 0.5), StrokePoint(100.4, 440, 0.62)],
        ),
      ]);

      test('DRAW-19: a drawing row maps to a DrawingNode and back to its '
          'type and content', () {
        final document = BlockMapper.toDocument([
          row('d', BlockType.drawing, drawing),
        ]);

        final node = document.getNodeById('d');
        expect(node, isA<DrawingNode>());
        expect(BlockMapper.fromNode(node!), (BlockType.drawing, drawing));
      });

      test('DRAW-10: a drawing node keeps its place among the text nodes', () {
        final document = BlockMapper.toDocument([
          rows[0],
          row('d', BlockType.drawing, drawing),
          rows[1],
        ]);

        expect([for (final node in document) node.id], ['h', 'd', 't']);
        expect(document.getNodeById('h'), isA<ParagraphNode>());
        expect(document.getNodeById('t'), isA<ParagraphNode>());
      });

      test('DRAW-13: the drawing node is not deletable', () {
        final node = BlockMapper.toNode(BlockType.drawing, drawing, id: 'd');

        expect(node.isDeletable, isFalse);
      });
    });
  });
}
