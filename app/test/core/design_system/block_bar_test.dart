import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/block_bar.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;
const _labels = [
  'Texto',
  'Título',
  'Lista',
  'Checklist',
  'Desenho',
  'Negrito',
  'Itálico',
];
const Map<BlockBarType, String> _typeLabels = {
  BlockBarType.text: 'Texto',
  BlockBarType.heading: 'Título',
  BlockBarType.bulletedListItem: 'Lista',
  BlockBarType.checklistItem: 'Checklist',
};

final List<Object> _calls = [];

Future<void> _pump(
  WidgetTester tester, {
  BlockBarType type = BlockBarType.text,
  bool bold = false,
  bool italic = false,
}) {
  _calls.clear();
  return tester.pumpJot(
    Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: BlockBar(
          type: type,
          bold: bold,
          italic: italic,
          onType: _calls.add,
          onBold: () => _calls.add('bold'),
          onItalic: () => _calls.add('italic'),
          onDrawing: () => _calls.add('drawing'),
        ),
      ),
    ),
  );
}

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is JotBlockBarButton && w.label == label);

BoxDecoration _decoration(WidgetTester tester, String label) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: _button(label),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Color _glyphColor(WidgetTester tester, String label) {
  final text = find.descendant(of: _button(label), matching: find.byType(Text));
  if (text.evaluate().isNotEmpty) {
    return tester.widget<Text>(text).style!.color!;
  }
  final painter =
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: _button(label),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as JotIconPainter;
  return painter.color;
}

void _expectActive(WidgetTester tester, String label, {required bool active}) {
  final decoration = _decoration(tester, label);
  expect(decoration.color, active ? _colors.accentSoft : isNull, reason: label);
  expect(decoration.borderRadius, BorderRadius.circular(12), reason: label);
  expect(
    _glyphColor(tester, label),
    active ? _colors.accentPress : _colors.ink1,
    reason: label,
  );
  expect(
    tester.getSemantics(_button(label)),
    matchesSemantics(
      label: label,
      isButton: true,
      hasToggledState: true,
      isToggled: active,
      hasTapAction: true,
    ),
    reason: label,
  );
}

void main() {
  testWidgets(
    'BAR-01, DRAW-01: seven 48 x 48 buttons with their labels in canvas '
    'order',
    (tester) async {
      await _pump(tester);

      final buttons = tester
          .widgetList<JotBlockBarButton>(find.byType(JotBlockBarButton))
          .toList();
      expect(buttons.map((b) => b.label), _labels);
      final lefts = [
        for (final label in _labels) tester.getTopLeft(_button(label)).dx,
      ];
      expect(lefts, [...lefts]..sort());
      for (final label in _labels) {
        expect(
          tester.getSize(_button(label)),
          const Size(48, 48),
          reason: label,
        );
      }
    },
  );

  testWidgets('BAR-01: type buttons draw the canvas glyphs; bold and italic '
      'draw "B" and "I" in the bar tokens', (tester) async {
    await _pump(tester);
    final styles = JotTextStyles.from(_colors);

    final glyphs = tester
        .widgetList<JotIcon>(find.byType(JotIcon))
        .map((icon) => icon.glyph);
    expect(glyphs, [
      JotIconGlyph.text,
      JotIconGlyph.heading,
      JotIconGlyph.list,
      JotIconGlyph.checklist,
      JotIconGlyph.drawing,
    ]);
    final bold = tester.widget<Text>(find.text('B'));
    expect(bold.style!.fontFamily, styles.barNegrito.fontFamily);
    expect(bold.style!.fontSize, 18);
    expect(bold.style!.fontWeight, FontWeight.w700);
    final italic = tester.widget<Text>(find.text('I'));
    expect(italic.style!.fontFamily, styles.barItalico.fontFamily);
    expect(italic.style!.fontSize, 19);
    expect(italic.style!.fontStyle, FontStyle.italic);
  });

  for (final type in BlockBarType.values) {
    testWidgets('BAR-03, DRAW-01: "Desenho" comes right after "Checklist" and '
        'is never active, with type ${type.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, type: type, bold: true, italic: true);

      final labels = tester
          .widgetList<JotBlockBarButton>(find.byType(JotBlockBarButton))
          .map((b) => b.label)
          .toList();
      expect(labels.indexOf('Desenho'), labels.indexOf('Checklist') + 1);
      _expectActive(tester, 'Desenho', active: false);
      semantics.dispose();
    });
  }

  testWidgets('DRAW-01: tapping "Desenho" calls onDrawing only', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(_button('Desenho'));

    expect(_calls, ['drawing']);
  });

  for (final MapEntry(key: type, value: activeLabel) in _typeLabels.entries) {
    testWidgets('BAR-04: with type ${type.name}, only "$activeLabel" is '
        'active and toggled', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, type: type);

      for (final label in _typeLabels.values) {
        _expectActive(tester, label, active: label == activeLabel);
      }
      semantics.dispose();
    });
  }

  testWidgets('BAR-09: bold and italic buttons show their own active state '
      'and toggled', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, bold: true);
    _expectActive(tester, 'Negrito', active: true);
    _expectActive(tester, 'Itálico', active: false);

    await _pump(tester, italic: true);
    _expectActive(tester, 'Negrito', active: false);
    _expectActive(tester, 'Itálico', active: true);
    semantics.dispose();
  });

  testWidgets('BAR-05: each tap calls its callback with the right value', (
    tester,
  ) async {
    await _pump(tester, type: BlockBarType.heading);

    for (final label in _labels) {
      await tester.tap(_button(label));
    }

    expect(_calls, [
      BlockBarType.text,
      BlockBarType.heading,
      BlockBarType.bulletedListItem,
      BlockBarType.checklistItem,
      'drawing',
      'bold',
      'italic',
    ]);
  });

  testWidgets('BAR-01: the bar has a bgMesa background, a bgTrilho top '
      'border and the label "Tipo de bloco e formatação"', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(BlockBar),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, _colors.bgMesa);
    final border = decoration.border! as Border;
    expect(border.top, BorderSide(color: _colors.bgTrilho));
    expect(border.left, BorderSide.none);
    expect(border.right, BorderSide.none);
    expect(border.bottom, BorderSide.none);
    expect(find.bySemanticsLabel('Tipo de bloco e formatação'), findsOneWidget);
    semantics.dispose();
  });
}
