import 'dart:async';
import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:spike_appflowy_editor/block_mapper.dart';
import 'package:spike_appflowy_editor/block_row.dart';
import 'package:spike_appflowy_editor/block_sync.dart';

void main() => runApp(const SpikeApp());

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
    const BlockRow(
      id: 'drawing-1',
      type: drawingType,
      contentJson: '{"strokes":[]}',
      position: '5',
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

class EditorPage extends StatefulWidget {
  const EditorPage({required this.store, super.key});

  final InMemoryBlockStore store;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final EditorState editorState;
  late final BlockSync sync;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final rows = widget.store.visible;
    editorState = EditorState(document: BlockMapper.toDocument(rows));
    sync = BlockSync(
      editorState,
      widget.store,
      loadedIds: rows.map((r) => r.id),
    );
    editorState.transactionStream.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        sync.flush();
        debugPrint(
          'ROWS ${jsonEncode([
            for (final r in widget.store.visible) {'type': r.type, 'content': jsonDecode(r.contentJson)},
          ])}',
        );
      });
    });
  }

  void setType(String type, Map<String, dynamic> extra) {
    editorState.formatNode(
      editorState.selection,
      (node) => node.copyWith(
        type: type,
        attributes: {
          ParagraphBlockKeys.delta: node.attributes[ParagraphBlockKeys.delta],
          ...extra,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('appflowy_editor')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: AppFlowyEditor(
              editorState: editorState,
              editorStyle: const EditorStyle.mobile(),
              blockComponentBuilders: {
                ...standardBlockComponentBuilderMap,
                drawingType: DividerBlockComponentBuilder(
                  wrapper: (context, node, child) => Container(
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Desenho'),
                  ),
                ),
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Texto',
                icon: const Icon(Icons.notes),
                onPressed: () => setType(ParagraphBlockKeys.type, {}),
              ),
              IconButton(
                tooltip: 'Título',
                icon: const Icon(Icons.title),
                onPressed: () =>
                    setType(HeadingBlockKeys.type, {HeadingBlockKeys.level: 1}),
              ),
              IconButton(
                tooltip: 'Lista',
                icon: const Icon(Icons.format_list_bulleted),
                onPressed: () => setType(BulletedListBlockKeys.type, {}),
              ),
              IconButton(
                tooltip: 'Checklist',
                icon: const Icon(Icons.checklist),
                onPressed: () => setType(TodoListBlockKeys.type, {
                  TodoListBlockKeys.checked: false,
                }),
              ),
              IconButton(
                tooltip: 'Negrito',
                icon: const Icon(Icons.format_bold),
                onPressed: () =>
                    editorState.toggleAttribute(AppFlowyRichTextKeys.bold),
              ),
              IconButton(
                tooltip: 'Itálico',
                icon: const Icon(Icons.format_italic),
                onPressed: () =>
                    editorState.toggleAttribute(AppFlowyRichTextKeys.italic),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
