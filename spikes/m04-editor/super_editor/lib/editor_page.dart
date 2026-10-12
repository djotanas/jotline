import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spike_super_editor/block_mapper.dart';
import 'package:spike_super_editor/block_row.dart';
import 'package:spike_super_editor/block_sync.dart';
import 'package:spike_super_editor/drawing_stub.dart';
import 'package:super_editor/super_editor.dart';

const _highlight = Color(0xFFF3EEDF);
const _struck = Color(0xFF9A948A);

/// Prototype page: one editor over the rows of [store].
class EditorPage extends StatefulWidget {
  const EditorPage({required this.store, super.key});

  final InMemoryBlockStore store;

  @override
  State<EditorPage> createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  late final Editor editor;
  late final BlockSync sync;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final rows = widget.store.visible;
    editor = createDefaultDocumentEditor(
      document: BlockMapper.toDocument(rows),
      composer: MutableDocumentComposer(),
    );
    sync = BlockSync(editor, widget.store, loadedIds: rows.map((r) => r.id));
    editor.addListener(FunctionalEditListener((_) => _schedule()));
    editor.composer.selectionNotifier.addListener(_onSelection);
    _componentBuilders = [
      const DrawingStubComponentBuilder(),
      ActiveBlockBuilder([
        MutedTaskComponentBuilder(editor),
        ...defaultComponentBuilders,
      ]),
    ];
  }

  late final List<ComponentBuilder> _componentBuilders;

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      sync.flush();
      debugPrint('ROWS ${BlockMapper.describe(widget.store.visible)}');
    });
  }

  void _onSelection() => setState(() {});

  @override
  void dispose() {
    _debounce?.cancel();
    sync.flush();
    editor.composer.selectionNotifier.removeListener(_onSelection);
    super.dispose();
  }

  String? get _caretNodeId => editor.composer.selection?.extent.nodeId;

  void setType(String type) {
    final nodeId = _caretNodeId;
    if (nodeId == null) return;
    final node = editor.document.getNodeById(nodeId);
    if (node is! TextNode) return;
    final requests = <EditRequest>[];
    if (node is TaskNode) {
      requests.add(ConvertTaskToParagraphRequest(nodeId: nodeId));
    } else if (node is ListItemNode) {
      requests.add(ConvertListItemToParagraphRequest(nodeId: nodeId));
    }
    switch (type) {
      case BlockType.heading:
        requests.add(
          ChangeParagraphBlockTypeRequest(
            nodeId: nodeId,
            blockType: header1Attribution,
          ),
        );
      case BlockType.bulletedListItem:
        requests.add(
          ConvertParagraphToListItemRequest(
            nodeId: nodeId,
            type: ListItemType.unordered,
          ),
        );
      case BlockType.checklistItem:
        requests.add(ConvertParagraphToTaskRequest(nodeId: nodeId));
      default:
        requests.add(
          ChangeParagraphBlockTypeRequest(
            nodeId: nodeId,
            blockType: paragraphAttribution,
          ),
        );
    }
    editor.execute(requests);
  }

  void toggleMark(Attribution attribution) {
    final selection = editor.composer.selection;
    if (selection == null) return;
    if (selection.isCollapsed) {
      editor.composer.preferences.toggleStyle(attribution);
    } else {
      editor.execute([
        ToggleTextAttributionsRequest(
          documentRange: selection,
          attributions: {attribution},
        ),
      ]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final caretNode = _caretNodeId == null
        ? null
        : editor.document.getNodeById(_caretNodeId!);
    return Scaffold(
      appBar: AppBar(title: const Text('super_editor')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SuperEditor(
                editor: editor,
                stylesheet: _stylesheet,
                componentBuilders: _componentBuilders,
              ),
            ),
            if (caretNode is TextNode)
              BlockBar(
                type: BlockMapper.fromNode(caretNode).$1,
                onType: setType,
                onBold: () => toggleMark(boldAttribution),
                onItalic: () => toggleMark(italicsAttribution),
              ),
          ],
        ),
      ),
    );
  }
}

final _stylesheet = defaultStylesheet.copyWith(
  documentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
  addRulesAfter: [
    StyleRule(
      BlockSelector.all,
      (doc, node) => {
        Styles.padding: const CascadingPadding.symmetric(horizontal: 12),
        Styles.textStyle: const TextStyle(
          fontSize: 17,
          height: 1.55,
          color: Color(0xFF2B2722),
        ),
      },
    ),
    StyleRule(
      const BlockSelector('header1'),
      (doc, node) => {
        Styles.textStyle: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      },
    ),
  ],
  inlineTextStyler: (attributions, style) {
    var result = defaultInlineTextStyler(attributions, style);
    if (attributions.contains(boldAttribution)) {
      result = result.copyWith(fontWeight: FontWeight.w600);
    }
    return result;
  },
);

/// Paints the canvas in-edit background (radius 10, 12 px bleed via the block
/// padding) and a drag handle on the block that holds the caret.
class ActiveBlockBuilder implements ComponentBuilder {
  const ActiveBlockBuilder(this.inner);

  final List<ComponentBuilder> inner;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    for (final builder in inner) {
      final viewModel = builder.createViewModel(document, node);
      if (viewModel != null) return viewModel;
    }
    return null;
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    for (final builder in inner) {
      final component = builder.createComponent(
        componentContext,
        componentViewModel,
      );
      if (component == null) continue;
      final active =
          componentViewModel is TextComponentViewModel &&
          componentViewModel.selection != null;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: -12,
            right: -12,
            child: IgnorePointer(
              child: DecoratedBox(
                key: active ? const ValueKey('active-block') : null,
                decoration: BoxDecoration(
                  color: active ? _highlight : null,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          component,
          if (active)
            Positioned(
              left: -24,
              top: 0,
              child: Semantics(
                label: 'Mover bloco',
                child: Icon(Icons.drag_indicator, size: 16),
              ),
            ),
        ],
      );
    }
    return null;
  }
}

/// The built-in task component with checked items drawn muted.
class MutedTaskComponentBuilder extends TaskComponentBuilder {
  MutedTaskComponentBuilder(super.editor);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! TaskComponentViewModel) return null;
    final viewModel = componentViewModel.copy();
    if (viewModel.isComplete) {
      final base = viewModel.textStyleBuilder;
      viewModel.textStyleBuilder = (attributions) =>
          base(attributions).copyWith(color: _struck);
    }
    return TaskComponent(
      key: componentContext.componentKey,
      viewModel: viewModel,
    );
  }
}

/// The canvas block bar, without "Desenho".
class BlockBar extends StatelessWidget {
  const BlockBar({
    required this.type,
    required this.onType,
    required this.onBold,
    required this.onItalic,
    super.key,
  });

  final String type;
  final ValueChanged<String> onType;
  final VoidCallback onBold;
  final VoidCallback onItalic;

  @override
  Widget build(BuildContext context) {
    Widget typeButton(String value, String label, IconData icon) => IconButton(
      tooltip: label,
      isSelected: type == value,
      icon: Icon(icon),
      onPressed: () => onType(value),
    );
    return Material(
      elevation: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          typeButton(BlockType.text, 'Texto', Icons.notes),
          typeButton(BlockType.heading, 'Título', Icons.title),
          typeButton(
            BlockType.bulletedListItem,
            'Lista',
            Icons.format_list_bulleted,
          ),
          typeButton(BlockType.checklistItem, 'Checklist', Icons.checklist),
          IconButton(
            tooltip: 'Negrito',
            icon: const Icon(Icons.format_bold),
            onPressed: onBold,
          ),
          IconButton(
            tooltip: 'Itálico',
            icon: const Icon(Icons.format_italic),
            onPressed: onItalic,
          ),
        ],
      ),
    );
  }
}
