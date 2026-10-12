import 'package:flutter_test/flutter_test.dart';
import 'package:spike_super_editor/block_mapper.dart';
import 'package:spike_super_editor/block_row.dart';

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
    final back = [
      for (final node in document) (node.id, BlockMapper.fromNode(node)),
    ];
    for (final (index, (id, (type, contentJson))) in back.indexed) {
      expect(id, rows[index].id);
      expect(type, rows[index].type);
      expect(BlockContent.fromJson(contentJson), rows[index].content);
    }
  });

  test('SPIKE-04: content_json is our shape, with checked only on items', () {
    final document = BlockMapper.toDocument(rows);
    final (_, text) = BlockMapper.fromNode(document.getNodeAt(1)!);
    final (_, task) = BlockMapper.fromNode(document.getNodeAt(3)!);
    expect(text, contains('"marks":[{"start":0,"end":4,"type":"bold"}'));
    expect(text, isNot(contains('checked')));
    expect(task, '{"text":"Feito","marks":[],"checked":true}');
  });

  test('SPIKE-02: node id is the block id for loaded rows', () {
    final document = BlockMapper.toDocument(rows);
    expect([for (final n in document) n.id], [for (final r in rows) r.id]);
  });

  test('keyBetween orders keys', () {
    expect(
      keyBetween(null, null).compareTo(keyBetween('5', null)),
      lessThan(0),
    );
    final mid = keyBetween('1', '2');
    expect('1'.compareTo(mid) < 0 && mid.compareTo('2') < 0, isTrue);
    final low = keyBetween(null, '1');
    expect(low.compareTo('1'), lessThan(0));
  });
}
