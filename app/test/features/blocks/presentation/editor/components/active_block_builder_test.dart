import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:jotline/features/blocks/presentation/editor/components/active_block_builder.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../../../helpers/pump_jot.dart';

void main() {
  late Editor editor;

  Future<void> pumpEditor(WidgetTester tester) async {
    editor = createBlockEditor(
      MutableDocument(
        nodes: [
          ParagraphNode(id: 'a', text: AttributedText('Belém cedo')),
          ParagraphNode(id: 'b', text: AttributedText('Pastéis na fábrica')),
        ],
      ),
    );
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpJot(
      Scaffold(
        body: CustomScrollView(
          slivers: [BlockEditor(editor: editor, focusNode: focusNode)],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder blockOf(String nodeId) => find.ancestor(
    of: find.byWidget(
      SuperEditorInspector.findDocumentLayout()
          .getComponentByNodeId(nodeId)!
          .widget,
    ),
    matching: find.byType(ActiveBlock),
  );

  Finder inEditBox(Finder block) => find.descendant(
    of: block,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          (widget.decoration as BoxDecoration).color ==
              JotColors.light.accentWash,
    ),
  );

  Finder handleIn(Finder block) =>
      find.descendant(of: block, matching: find.byType(BlockDragHandle));

  Rect textRect(String nodeId) =>
      SuperEditorInspector.findComponentOffset(nodeId, Alignment.topLeft) &
      SuperEditorInspector.findComponentSize(nodeId);

  testWidgets('EDIT-02: only the block with the caret has the in-edit box, '
      'radius 10, bleeding 12 px past the text', (tester) async {
    await pumpEditor(tester);

    expect(inEditBox(find.byType(ActiveBlock)), findsNothing);

    await tester.placeCaretInParagraph('b', 3);

    expect(inEditBox(blockOf('a')), findsNothing);
    final box = inEditBox(blockOf('b'));
    expect(box, findsOneWidget);
    final decoration =
        tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(10));
    final boxRect = tester.getRect(box);
    final text = textRect('b');
    expect(boxRect.left, text.left - 12);
    expect(boxRect.right, text.right + 12);
    expect(text.left, 24);
  });

  testWidgets('EDIT-02: the in-edit box follows the caret to another '
      'block', (tester) async {
    await pumpEditor(tester);

    await tester.placeCaretInParagraph('a', 0);
    await tester.placeCaretInParagraph('b', 10);

    expect(editor.composer.selection!.extent.nodeId, 'b');

    expect(inEditBox(blockOf('a')), findsNothing);
    expect(inEditBox(blockOf('b')), findsOneWidget);
  });

  testWidgets('EDIT-02: a tap on the in-edit box places the caret', (
    tester,
  ) async {
    await pumpEditor(tester);
    await tester.placeCaretInParagraph('b', 10);

    final text = textRect('b');
    await tester.tapAt(Offset(text.left - 6, text.top + 5));
    await tester.pump(kTapTimeout);
    await tester.pumpAndSettle();

    expect(
      editor.composer.selection,
      const DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: 'b',
          nodePosition: TextNodePosition(offset: 0),
        ),
      ),
    );
  });

  testWidgets('BMOVE-01: the drag handle shows only on the block with the '
      'caret, labeled "Mover bloco", in inkDeco at the block start', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester);

    expect(find.byType(BlockDragHandle), findsNothing);

    await tester.placeCaretInParagraph('a', 2);

    expect(handleIn(blockOf('b')), findsNothing);
    final handle = handleIn(blockOf('a'));
    expect(handle, findsOneWidget);
    expect(find.bySemanticsLabel('Mover bloco'), findsOneWidget);
    final theme = tester.widget<IconTheme>(
      find
          .ancestor(
            of: find.descendant(of: handle, matching: find.byType(JotIcon)),
            matching: find.byType(IconTheme),
          )
          .first,
    );
    expect(theme.data.color, JotColors.light.inkDeco);
    expect(
      tester.getRect(
        find.descendant(of: handle, matching: find.byType(JotIcon)),
      ),
      Rect.fromLTWH(-4, textRect('a').top, 22, 22),
    );
    semantics.dispose();
  });
}
