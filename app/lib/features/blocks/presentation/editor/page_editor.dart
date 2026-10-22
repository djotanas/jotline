import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:jotline/features/blocks/presentation/editor/block_mapper.dart';
import 'package:jotline/features/blocks/presentation/editor/block_sync.dart';
import 'package:super_editor/super_editor.dart';

const Map<MarkType, Attribution> _attributions = {
  MarkType.bold: boldAttribution,
  MarkType.italic: italicsAttribution,
};

/// The block editor of one open page, loaded once from its rows: the screen
/// drives it through this class and never sees the editor library.
///
/// Notifies its listeners on every edit; [changes] also covers the focus,
/// the selection and the styles for the next text.
class PageEditor with ChangeNotifier {
  new({
    required List<Block> rows,
    required String pageId,
    required BlockRepository repository,
  }) : _editor = createBlockEditor(BlockMapper.toDocument(rows)) {
    _sync = BlockSync(
      editor: _editor,
      pageId: pageId,
      repository: repository,
      loadedIds: rows.map((row) => row.id),
    );
    _editor.addListener(_editListener);
  }

  late final EditListener _editListener = FunctionalEditListener(
    (_) => notifyListeners(),
  );

  final Editor _editor;
  late final BlockSync _sync;
  final FocusNode focusNode = FocusNode();

  /// Fires when anything the block bar shows may have changed.
  late final Listenable changes = Listenable.merge([
    this,
    focusNode,
    _editor.composer.selectionNotifier,
    _editor.composer.preferences,
  ]);

  /// Whether a block has the caret: the editor has focus and a selection
  /// (BAR-01, BAR-02).
  bool get hasCaret => focusNode.hasFocus && _editor.composer.selection != null;

  /// The type of the block with the caret, or text with none.
  BlockType get caretType {
    final selection = _editor.composer.selection;
    final node = selection == null
        ? null
        : _editor.document.getNodeById(selection.extent.nodeId);
    return node == null ? BlockType.text : BlockMapper.fromNode(node).$1;
  }

  /// Whether every character of the selection has [type]; with a collapsed
  /// caret, whether the text typed next gets it (BAR-09).
  bool isMarkActive(MarkType type) {
    final attribution = _attributions[type]!;
    final selection = _editor.composer.selection;
    if (selection == null) return false;
    if (selection.isCollapsed) {
      return _editor.composer.preferences.currentAttributions.contains(
        attribution,
      );
    }
    final document = _editor.document;
    final range = selection.normalize(document);
    var checked = false;
    for (final node in document.getNodesInside(range.start, range.end)) {
      if (node is! TextNode) continue;
      final start = node.id == range.start.nodeId
          ? (range.start.nodePosition as TextNodePosition).offset
          : 0;
      final end = node.id == range.end.nodeId
          ? (range.end.nodePosition as TextNodePosition).offset
          : node.text.length;
      if (end <= start) continue;
      if (!node.text.hasAttributionsThroughout(
        attributions: {attribution},
        range: SpanRange(start, end - 1),
      )) {
        return false;
      }
      checked = true;
    }
    return checked;
  }

  /// Turns the block with the caret into [type], keeping its text, marks and
  /// id (BAR-05).
  void setType(BlockType type) {
    final nodeId = _editor.composer.selection?.extent.nodeId;
    if (nodeId == null) return;
    final node = _editor.document.getNodeById(nodeId);
    if (node is! TextNode) return;
    _editor.execute([
      if (node is TaskNode) ConvertTaskToParagraphRequest(nodeId: nodeId),
      if (node is ListItemNode)
        ConvertListItemToParagraphRequest(nodeId: nodeId),
      switch (type) {
        BlockType.text => ChangeParagraphBlockTypeRequest(
          nodeId: nodeId,
          blockType: paragraphAttribution,
        ),
        BlockType.heading => ChangeParagraphBlockTypeRequest(
          nodeId: nodeId,
          blockType: header1Attribution,
        ),
        BlockType.bulletedListItem => ConvertParagraphToListItemRequest(
          nodeId: nodeId,
          type: ListItemType.unordered,
        ),
        BlockType.checklistItem => ConvertParagraphToTaskRequest(
          nodeId: nodeId,
        ),
      },
    ]);
  }

  /// Toggles [type] on the selected text, or for the text typed next at a
  /// collapsed caret (BAR-07, BAR-08).
  void toggleMark(MarkType type) {
    final attribution = _attributions[type]!;
    final selection = _editor.composer.selection;
    if (selection == null) return;
    if (selection.isCollapsed) {
      _editor.composer.preferences.toggleStyle(attribution);
      return;
    }
    _editor.execute([
      ToggleTextAttributionsRequest(
        documentRange: selection,
        attributions: {attribution},
      ),
    ]);
  }

  /// Puts the caret at the start of the first block (EDIT-06).
  void focusStart() {
    final first = _editor.document.firstOrNull;
    if (first == null) return focusEnd();
    _focus(
      DocumentPosition(nodeId: first.id, nodePosition: first.beginningPosition),
    );
  }

  /// Puts the caret in an empty text block at the end of the page, reusing
  /// the last block when it already is one; nothing is saved until the
  /// first character (EDIT-04, EDIT-05).
  void focusEnd() {
    final document = _editor.document;
    final last = document.lastOrNull;
    if (last != null) {
      final (type, content) = BlockMapper.fromNode(last);
      if (type == BlockType.text && content.text.isEmpty) {
        return _focus(
          DocumentPosition(
            nodeId: last.id,
            nodePosition: last.beginningPosition,
          ),
        );
      }
    }
    final paragraph = ParagraphNode(
      id: Editor.createNodeId(),
      text: AttributedText(),
    );
    _editor.execute([
      InsertNodeAtIndexRequest(
        nodeIndex: document.nodeCount,
        newNode: paragraph,
      ),
    ]);
    _focus(
      DocumentPosition(
        nodeId: paragraph.id,
        nodePosition: paragraph.beginningPosition,
      ),
    );
  }

  void _focus(DocumentPosition position) {
    _editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(position: position),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      const ClearComposingRegionRequest(),
    ]);
    focusNode.requestFocus();
  }

  /// Writes the pending block changes now; never awaited on a frame path
  /// (SAVE-12).
  Future<void> flush() => _sync.flush();

  /// Fires a last flush, then releases the editor.
  @override
  void dispose() {
    unawaited(_sync.flush());
    _sync.dispose();
    _editor.removeListener(_editListener);
    focusNode.dispose();
    _editor.dispose();
    super.dispose();
  }
}

/// The page blocks as a sliver of the page's scroll view.
class PageEditorView extends StatelessWidget {
  const new({required this.pageEditor, super.key});

  final PageEditor pageEditor;

  @override
  Widget build(BuildContext context) =>
      BlockEditor(editor: pageEditor._editor, focusNode: pageEditor.focusNode);
}
