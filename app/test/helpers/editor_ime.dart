import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor_test.dart';

extension EditorIme on WidgetTester {
  /// Sends the deletion delta a software keyboard sends for Backspace, to
  /// the editor's IME client.
  Future<void> imeBackspace() async {
    final client = imeClientGetter();
    final value = client.currentTextEditingValue!;
    final selection = value.selection;
    if (selection.isCollapsed && selection.extentOffset == 0) return;
    client.updateEditingValueWithDeltas([
      TextEditingDeltaDeletion(
        oldText: value.text,
        deletedRange: selection.isCollapsed
            ? TextRange(start: selection.start - 1, end: selection.start)
            : selection,
        selection: TextSelection.collapsed(
          offset: selection.isCollapsed ? selection.start - 1 : selection.start,
        ),
        composing: TextRange.empty,
      ),
    ]);
    await pumpAndSettle();
  }
}

extension EditorImeInsert on WidgetTester {
  /// Sends [text] as one insertion delta at the IME selection, then pumps a
  /// single frame, so no time passes while typing.
  Future<void> imeInsert(String text) async {
    final client = imeClientGetter();
    final value = client.currentTextEditingValue!;
    final offset = value.selection.extentOffset;
    client.updateEditingValueWithDeltas([
      TextEditingDeltaInsertion(
        oldText: value.text,
        textInserted: text,
        insertionOffset: offset,
        selection: TextSelection.collapsed(offset: offset + text.length),
        composing: TextRange.empty,
      ),
    ]);
    await pump();
  }
}
