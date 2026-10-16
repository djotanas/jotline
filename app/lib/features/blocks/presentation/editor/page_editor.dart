import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:jotline/features/blocks/presentation/editor/block_mapper.dart';
import 'package:jotline/features/blocks/presentation/editor/block_sync.dart';
import 'package:super_editor/super_editor.dart';

/// The block editor of one open page, loaded once from its rows: the screen
/// drives it through this class and never sees the editor library.
class PageEditor {
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
  }

  final Editor _editor;
  late final BlockSync _sync;
  final FocusNode focusNode = FocusNode();

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
    ]);
    focusNode.requestFocus();
  }

  /// Writes the pending block changes now; never awaited on a frame path
  /// (SAVE-12).
  Future<void> flush() => _sync.flush();

  /// Fires a last flush, then releases the editor.
  void dispose() {
    unawaited(_sync.flush());
    _sync.dispose();
    focusNode.dispose();
    _editor.dispose();
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
