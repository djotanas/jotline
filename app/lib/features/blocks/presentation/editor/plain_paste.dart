import 'package:super_editor/super_editor.dart';

final _lineBreak = RegExp(r'\r\n|\r|\n');

/// Runs every [PasteEditorRequest] as a [PlainPasteCommand] (EDIT-11).
EditCommand? plainPasteHandler(Editor editor, EditRequest request) =>
    request is PasteEditorRequest
    ? PlainPasteCommand(
        content: request.content,
        pastePosition: request.pastePosition,
      )
    : null;

/// Pastes text with no formatting: the first line goes into the block at
/// [pastePosition], every other line becomes a new paragraph, and the text
/// after the caret follows the last line.
///
/// The default paste deletes an expanded selection before this runs.
class PlainPasteCommand extends EditCommand {
  new({required this.content, required this.pastePosition});

  final String content;
  final DocumentPosition pastePosition;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  String describe() => 'Paste plain text at $pastePosition';

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(pastePosition.nodeId);
    if (node is! TextNode) return;
    final offset = (pastePosition.nodePosition as TextNodePosition).offset;
    final lines = content.split(_lineBreak);
    final tail = node.text.copyText(offset);

    if (lines.length > 1 && tail.length > 0) {
      executor.executeCommand(
        DeleteContentCommand(
          documentRange: DocumentRange(
            start: pastePosition,
            end: DocumentPosition(
              nodeId: node.id,
              nodePosition: node.endPosition,
            ),
          ),
        ),
      );
    }
    executor.executeCommand(
      InsertTextCommand(
        documentPosition: pastePosition,
        textToInsert: lines.first,
        attributions: const {},
      ),
    );
    if (lines.length == 1) return;

    var previousId = node.id;
    for (final (index, line) in lines.indexed.skip(1)) {
      final isLast = index == lines.length - 1;
      final paragraph = ParagraphNode(
        id: Editor.createNodeId(),
        text: isLast
            ? AttributedText(line).copyAndAppend(tail)
            : AttributedText(line),
      );
      executor.executeCommand(
        InsertNodeAfterNodeCommand(
          existingNodeId: previousId,
          newNode: paragraph,
        ),
      );
      previousId = paragraph.id;
    }
    executor.executeCommand(
      ChangeSelectionCommand(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: previousId,
            nodePosition: TextNodePosition(offset: lines.last.length),
          ),
        ),
        SelectionChangeType.insertContent,
        SelectionReason.userInteraction,
      ),
    );
  }
}
