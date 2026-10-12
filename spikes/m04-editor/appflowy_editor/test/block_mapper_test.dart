import 'package:flutter_test/flutter_test.dart';
import 'package:spike_appflowy_editor/block_mapper.dart';
import 'package:spike_appflowy_editor/block_row.dart';

void main() {
  BlockRow row(String id, String type, BlockContent content) =>
      BlockRow(id: id, type: type, contentJson: content.toJson(), position: id);

  final rows = [
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

  test('SPIKE-04: every row round-trips through nodes without loss', () {
    final document = BlockMapper.toDocument(rows);
    final nodes = document.root.children.toList();
    for (final (index, node) in nodes.indexed) {
      final (type, contentJson) = BlockMapper.fromNode(node);
      expect(node.id, rows[index].id);
      expect(type, rows[index].type);
      expect(BlockContent.fromJson(contentJson), rows[index].content);
    }
  });
}
