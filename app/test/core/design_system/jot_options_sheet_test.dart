import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_options_sheet.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

class _Result {
  bool resolved = false;
  String? value;
}

Future<_Result> _open(
  WidgetTester tester, {
  List<List<JotOptionRow<String>>>? groups,
  Widget? footer,
}) async {
  final result = _Result();
  await tester.pumpJot(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () async {
              result
                ..value = await showJotOptionsSheet<String>(
                  context,
                  header: const Text('Viagem a Lisboa'),
                  footer: footer,
                  groups:
                      groups ??
                      const [
                        [
                          JotOptionRow(
                            icon: JotIconGlyph.edit,
                            label: 'Renomear',
                            value: 'rename',
                          ),
                          JotOptionRow(
                            icon: JotIconGlyph.archive,
                            label: 'Arquivar',
                            subtitle: 'Sai da lista principal; nada é apagado',
                            value: 'archive',
                          ),
                        ],
                        [
                          JotOptionRow(
                            icon: JotIconGlyph.trash,
                            label: 'Excluir caderno',
                            value: 'delete',
                            destructive: true,
                          ),
                        ],
                      ],
                )
                ..resolved = true;
            },
            child: const SizedBox.square(dimension: 44, child: Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

TextStyle _style(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  testWidgets('NBOPT-01: groups render as white cards with dividers', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    final cards = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((box) {
          final decoration = box.decoration;
          return decoration is BoxDecoration &&
              decoration.color == _colors.bgFolha &&
              decoration.borderRadius == BorderRadius.circular(JotRadius.rCard);
        });
    expect(cards, hasLength(2));
    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(JotIcon), findsNWidgets(3));
    expect(find.text('Sai da lista principal; nada é apagado'), findsOneWidget);
  });

  testWidgets('SORT-01: a footer is drawn under the last group', (
    tester,
  ) async {
    await _open(tester, footer: const Text('Vale para Ativos e Arquivados'));

    final footer = tester.getTopLeft(
      find.text('Vale para Ativos e Arquivados'),
    );
    final lastRow = tester.getBottomLeft(find.text('Excluir caderno'));
    expect(footer.dy, greaterThan(lastRow.dy));
  });

  testWidgets('NBOPT-02: a destructive row uses the danger color', (
    tester,
  ) async {
    await _open(tester);

    expect(_style(tester, 'Excluir caderno').color, _colors.danger);
    expect(_style(tester, 'Renomear').color, _colors.ink1);
    final theme = tester.widget<IconTheme>(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (widget) =>
                  widget is JotIcon && widget.glyph == JotIconGlyph.trash,
            ),
            matching: find.byType(IconTheme),
          )
          .first,
    );
    expect(theme.data.color, _colors.danger);
  });

  testWidgets('SORT-01: a checked row shows the check glyph and is selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(
      tester,
      groups: const [
        [
          JotOptionRow(
            label: 'Editados recentemente',
            value: 'recent',
            checked: true,
          ),
          JotOptionRow(label: 'Nome (A–Z)', value: 'name'),
          JotOptionRow(label: 'Data de criação', value: 'created'),
        ],
      ],
    );

    final glyphs = tester
        .widgetList<JotIcon>(find.byType(JotIcon))
        .map((icon) => icon.glyph);
    expect(glyphs, [JotIconGlyph.check]);
    expect(_style(tester, 'Editados recentemente').fontWeight, FontWeight.w600);
    final flags = tester
        .getSemantics(find.text('Editados recentemente'))
        .flagsCollection;
    expect(flags.isSelected, Tristate.isTrue);
    expect(flags.isButton, isTrue);
    expect(flags.isInMutuallyExclusiveGroup, isTrue);
    expect(
      tester.getSemantics(find.text('Nome (A–Z)')).flagsCollection.isSelected,
      isNot(Tristate.isTrue),
    );
    handle.dispose();
  });

  testWidgets('NBOPT-01: tapping a row resolves the future with its value', (
    tester,
  ) async {
    final result = await _open(tester);

    await tester.tap(find.text('Arquivar'));
    await tester.pumpAndSettle();

    expect(result.resolved, isTrue);
    expect(result.value, 'archive');
    expect(find.byType(JotOptionsSheet<String>), findsNothing);
  });

  testWidgets('NBOPT-02: tapping the barrier resolves null', (tester) async {
    final result = await _open(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result.resolved, isTrue);
    expect(result.value, isNull);
    expect(find.byType(JotOptionsSheet<String>), findsNothing);
  });

  testWidgets('PGOPT-01: the sheet shows the handle from JotBottomSheet', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byKey(const ValueKey('jotBottomSheetHandle')), findsOneWidget);
  });

  testWidgets('NBOPT-01: the sheet pads its end by the navigation bar', (
    tester,
  ) async {
    tester.view.viewPadding = const FakeViewPadding(bottom: 144);
    tester.view.padding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.reset);
    await _open(tester);

    final scroll = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(JotOptionsSheet<String>),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(
      (scroll.padding! as EdgeInsets).bottom,
      JotSpace.space6 + JotSpace.space3 + 48,
    );
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await _open(tester);

    expect(tester.takeException(), isNull);
  });
}
