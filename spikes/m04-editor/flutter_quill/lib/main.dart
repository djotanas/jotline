import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:spike_flutter_quill/block_mapper.dart';
import 'package:spike_flutter_quill/block_row.dart';
import 'package:spike_flutter_quill/block_sync.dart';

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
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    home: EditorPage(store: store),
  );
}

class EditorPage extends StatefulWidget {
  const EditorPage({required this.store, super.key});

  final InMemoryBlockStore store;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final QuillController controller;
  late final BlockSync sync;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final rows = widget.store.visible;
    controller = QuillController(
      document: Document.fromDelta(BlockMapper.toDelta(rows)),
      selection: const TextSelection.collapsed(offset: 0),
    );
    sync = BlockSync(
      controller.document,
      widget.store,
      loadedIds: [for (final r in rows) r.id],
    );
    controller.document.changes.listen((_) {
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

  void format(Attribute<dynamic> attribute) {
    controller.formatSelection(attribute);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('flutter_quill')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: QuillEditor.basic(
              controller: controller,
              config: const QuillEditorConfig(
                padding: EdgeInsets.all(16),
                embedBuilders: [DrawingStubBuilder()],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Texto',
                icon: const Icon(Icons.notes),
                onPressed: () => controller
                  ..formatSelection(Attribute.clone(Attribute.header, null))
                  ..formatSelection(Attribute.clone(Attribute.list, null)),
              ),
              IconButton(
                tooltip: 'Título',
                icon: const Icon(Icons.title),
                onPressed: () => format(Attribute.h1),
              ),
              IconButton(
                tooltip: 'Lista',
                icon: const Icon(Icons.format_list_bulleted),
                onPressed: () => format(Attribute.ul),
              ),
              IconButton(
                tooltip: 'Checklist',
                icon: const Icon(Icons.checklist),
                onPressed: () => format(Attribute.unchecked),
              ),
              IconButton(
                tooltip: 'Negrito',
                icon: const Icon(Icons.format_bold),
                onPressed: () => format(Attribute.bold),
              ),
              IconButton(
                tooltip: 'Itálico',
                icon: const Icon(Icons.format_italic),
                onPressed: () => format(Attribute.italic),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Stand-in for the future drawing block (#25).
class DrawingStubBuilder extends EmbedBuilder {
  const DrawingStubBuilder();

  @override
  String get key => drawingType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) => Container(
    height: 120,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text('Desenho'),
  );
}
