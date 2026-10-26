import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotline/core/design_system/block_bar.dart';
import 'package:jotline/core/design_system/jot_fab.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/presentation/editor/components/checklist_item.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import 'helpers/flows.dart';
import 'helpers/no_network.dart';

Future<void> _bar(WidgetTester tester, String label) => tapAndSettle(
  tester,
  find.byWidgetPredicate((w) => w is JotBlockBarButton && w.label == label),
);

List<DocumentNode> get _nodes => SuperEditorInspector.findDocument()!.toList();

/// Sets the selection over [word] as a keyboard does, with a selection-only
/// delta to the editor's IME client.
Future<void> _selectThroughIme(
  WidgetTester tester,
  String word, {
  bool collapseAtEnd = false,
}) async {
  final client = imeClientGetter();
  final value = client.currentTextEditingValue!;
  final start = value.text.indexOf(word);
  final end = start + word.length;
  client.updateEditingValueWithDeltas([
    TextEditingDeltaNonTextUpdate(
      oldText: value.text,
      selection: collapseAtEnd
          ? TextSelection.collapsed(offset: end)
          : TextSelection(baseOffset: start, extentOffset: end),
      composing: TextRange.empty,
    ),
  ]);
  await settle(tester);
}

String _text(DocumentNode node) => (node as TextNode).text.toPlainText();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    forbidNetwork();
    BlinkController.indeterminateAnimationsEnabled = false;
    addTearDown(() => BlinkController.indeterminateAnimationsEnabled = true);
  });

  testWidgets('RF-03, RF-04: write a heading, a paragraph with bold and '
      'italic, a list and a checklist, tick an item, leave and reopen the '
      'page with the same content, with no network', (tester) async {
    final db = await pumpJotlineWithoutNetwork(tester);
    await createNotebook(tester, 'Diário');
    await tapAndSettle(tester, find.widgetWithText(JotFab, 'Nova página'));
    await tester.enterText(
      find.descendant(
        of: find.byType(PageScreen),
        matching: find.byType(TextField),
      ),
      'Lisboa',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await settle(tester);

    await tester.typeImeText('Manhã');
    await _bar(tester, 'Título');
    await tester.typeImeText('\n');
    await tester.typeImeText('Belém com calma');
    await _selectThroughIme(tester, 'calma');
    await _bar(tester, 'Negrito');
    await _bar(tester, 'Itálico');
    await _selectThroughIme(tester, 'calma', collapseAtEnd: true);
    await tester.typeImeText('\n');
    await _bar(tester, 'Lista');
    await tester.typeImeText('Torre');
    await tester.typeImeText('\n');
    await tester.typeImeText('MAAT');
    await tester.typeImeText('\n');
    await tester.typeImeText('\n');
    await _bar(tester, 'Checklist');
    await tester.typeImeText('Viva Viagem');
    await tester.typeImeText('\n');
    await tester.typeImeText('Jantar');
    await tapAndSettle(
      tester,
      find
          .descendant(
            of: find.byType(ChecklistItemComponent).first,
            matching: find.byType(GestureDetector),
          )
          .first,
    );

    await backFromPage(tester, 'Diário');
    await tapAndSettle(tester, find.text('Lisboa'));

    final nodes = _nodes;
    expect(nodes.map(_text), [
      'Manhã',
      'Belém com calma',
      'Torre',
      'MAAT',
      'Viva Viagem',
      'Jantar',
    ]);
    expect(
      (nodes[0] as ParagraphNode).getMetadataValue(NodeMetadata.blockType),
      header1Attribution,
    );
    expect(nodes[1], isA<ParagraphNode>());
    final text = (nodes[1] as TextNode).text;
    for (final attribution in [boldAttribution, italicsAttribution]) {
      expect(
        text.getAttributionSpans({attribution}).single,
        AttributionSpan(attribution: attribution, start: 10, end: 14),
      );
    }
    expect(nodes[2], isA<ListItemNode>());
    expect(nodes[3], isA<ListItemNode>());
    expect((nodes[4] as TaskNode).isComplete, isTrue);
    expect((nodes[5] as TaskNode).isComplete, isFalse);

    final rows =
        await (db.select(db.blocks)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    expect(rows.map((r) => r.type), [
      BlockType.heading.id,
      BlockType.text.id,
      BlockType.bulletedListItem.id,
      BlockType.bulletedListItem.id,
      BlockType.checklistItem.id,
      BlockType.checklistItem.id,
    ]);
    expect(
      BlockContent.fromJson(rows[1].contentJson),
      const BlockContent(
        'Belém com calma',
        marks: [Mark(10, 15, MarkType.bold), Mark(10, 15, MarkType.italic)],
      ),
    );
    expect(BlockContent.fromJson(rows[4].contentJson).checked, isTrue);
    expect(BlockContent.fromJson(rows[5].contentJson).checked, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
