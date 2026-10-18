import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:jotline/features/blocks/presentation/editor/components/checklist_item.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../../../helpers/pump_jot.dart';

void main() {
  const colors = JotColors.light;
  late Editor editor;

  Future<void> pumpEditor(WidgetTester tester) async {
    editor = createBlockEditor(
      MutableDocument(
        nodes: [
          ParagraphNode(id: 'a', text: AttributedText('Antes de sair')),
          TaskNode(id: 'k1', text: AttributedText('Bilhete'), isComplete: true),
          TaskNode(id: 'k2', text: AttributedText('Jantar'), isComplete: false),
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

  Finder itemOf(String nodeId) => find.byWidget(
    SuperEditorInspector.findDocumentLayout()
        .getComponentByNodeId(nodeId)!
        .widget,
  );

  Finder checkboxOf(String nodeId) => find.descendant(
    of: itemOf(nodeId),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox &&
          widget.width == 22 &&
          widget.height == 22 &&
          widget.child is DecoratedBox,
    ),
  );

  bool isComplete(String nodeId) =>
      (editor.document.getNodeById(nodeId)! as TaskNode).isComplete;

  TextStyle textStyleOf(String nodeId) =>
      SuperEditorInspector.findParagraphStyle(nodeId)!;

  testWidgets('CHECK-01: a checklist item is a row at least 44 tall with a '
      '22 x 22 checkbox 12 px before its text', (tester) async {
    await pumpEditor(tester);

    expect(find.byType(ChecklistItemComponent), findsNWidgets(2));
    expect(tester.getSize(itemOf('k2')).height, greaterThanOrEqualTo(44));
    final checkbox = tester.getRect(checkboxOf('k2'));
    expect(checkbox.size, const Size(22, 22));
    final text = tester.getRect(
      find.descendant(of: itemOf('k2'), matching: find.byType(TextComponent)),
    );
    expect(text.left - checkbox.right, 12);
  });

  testWidgets('CHECK-01: an unchecked box has a 1.5 px lineForte border, '
      'radius 3, on bgFolha', (tester) async {
    await pumpEditor(tester);

    final decoration = _decoration(tester, checkboxOf('k2'));

    expect(decoration.color, colors.bgFolha);
    expect(decoration.border, Border.all(color: colors.lineForte, width: 1.5));
    expect(decoration.borderRadius, BorderRadius.circular(3));
    expect(
      find.descendant(of: checkboxOf('k2'), matching: find.byType(JotIcon)),
      findsNothing,
    );
  });

  testWidgets('CHECK-01: a checked box is accent with the check glyph in '
      'bgFolha', (tester) async {
    await pumpEditor(tester);

    final decoration = _decoration(tester, checkboxOf('k1'));
    final icon = find.descendant(
      of: checkboxOf('k1'),
      matching: find.byType(JotIcon),
    );

    expect(decoration.color, colors.accent);
    expect(decoration.border, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(3));
    expect(tester.widget<JotIcon>(icon).glyph, JotIconGlyph.check);
    expect(
      tester
          .widget<IconTheme>(
            find.ancestor(of: icon, matching: find.byType(IconTheme)).first,
          )
          .data
          .color,
      colors.bgFolha,
    );
  });

  testWidgets('CHECK-02: tapping the checkbox toggles the item without moving '
      'the caret', (tester) async {
    await pumpEditor(tester);
    await tester.placeCaretInParagraph('a', 5);
    final caret = editor.composer.selection;

    await tester.tap(checkboxOf('k2'));
    await tester.pump(kTapTimeout);
    await tester.pumpAndSettle();

    expect(isComplete('k2'), isTrue);
    expect(isComplete('k1'), isTrue);
    expect(editor.composer.selection, caret);

    await tester.tap(checkboxOf('k1'));
    await tester.pump(kTapTimeout);
    await tester.pumpAndSettle();

    expect(isComplete('k1'), isFalse);
    expect(editor.composer.selection, caret);
  });

  testWidgets('CHECK-03: checked text is inkFeito with a strikethrough; '
      'unchecked text is not', (tester) async {
    await pumpEditor(tester);

    expect(textStyleOf('k1').color, colors.inkFeito);
    expect(textStyleOf('k1').decoration, TextDecoration.lineThrough);
    expect(textStyleOf('k2').color, colors.ink1);
    expect(textStyleOf('k2').decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('CHECK-08: each checkbox exposes its item text and checked '
      'state', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester);

    expect(
      tester.getSemantics(
        find
            .descendant(of: itemOf('k1'), matching: find.byType(Semantics))
            .first,
      ),
      matchesSemantics(
        label: 'Bilhete',
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(
        find
            .descendant(of: itemOf('k2'), matching: find.byType(Semantics))
            .first,
      ),
      matchesSemantics(
        label: 'Jantar',
        hasCheckedState: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });
}

BoxDecoration _decoration(WidgetTester tester, Finder checkbox) =>
    (tester.widget<SizedBox>(checkbox).child! as DecoratedBox).decoration
        as BoxDecoration;
