import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:jotline/core/database/app_database.dart';
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
