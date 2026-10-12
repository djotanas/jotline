import 'package:flutter/material.dart';
import 'package:spike_super_editor/block_row.dart';
import 'package:spike_super_editor/editor_page.dart';

void main() => runApp(const SpikeApp());

/// Sample page used for manual checks on a device.
List<BlockRow> sampleRows() {
  BlockRow row(String type, BlockContent content, String position) => BlockRow(
    id: newBlockId(),
    type: type,
    contentJson: content.toJson(),
    position: position,
  );
  return [
    row(BlockType.heading, const BlockContent('Manhã'), '1'),
    row(
      BlockType.text,
      const BlockContent(
        'Belém cedo, depois o mosteiro.',
        marks: [Mark(0, 5, MarkType.bold), Mark(7, 11, MarkType.italic)],
      ),
      '2',
    ),
    row(BlockType.bulletedListItem, const BlockContent('Pastéis'), '3'),
    row(
      BlockType.checklistItem,
      const BlockContent('Comprar bilhete', checked: true),
      '4',
    ),
    row(
      BlockType.checklistItem,
      const BlockContent('Levar protetor', checked: false),
      '5',
    ),
    const BlockRow(
      id: 'drawing-1',
      type: 'drawing',
      contentJson: '{"strokes":[]}',
      position: '6',
    ),
  ];
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  static final store = InMemoryBlockStore(sampleRows());

  @override
  Widget build(BuildContext context) =>
      MaterialApp(home: EditorPage(store: store));
}
