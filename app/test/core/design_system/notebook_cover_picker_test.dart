import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/design_system/notebook_cover_picker.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

const Map<CoverPattern, String> _names = {
  CoverPattern.lisa: 'Lisa',
  CoverPattern.pautada: 'Pautada',
  CoverPattern.pontilhada: 'Pontos',
  CoverPattern.quadriculada: 'Grade',
};

Future<void> _pump(
  WidgetTester tester, {
  CoverPattern selected = CoverPattern.quadriculada,
  ValueChanged<CoverPattern>? onChanged,
  double textScale = 1,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(
        child: SizedBox(
          width: 340,
          child: NotebookCoverPicker(
            color: NotebookColor.musgo,
            selected: selected,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _card(WidgetTester tester, String name) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.bySemanticsLabel(name),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  testWidgets('COMP-08: four options labeled Lisa, Pautada, Pontos and '
      'Grade, in order', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final xs = <double>[];
    for (final name in _names.values) {
      final option = find.bySemanticsLabel(name);
      expect(option, findsOneWidget);
      expect(find.text(name), findsOneWidget);
      xs.add(tester.getCenter(option).dx);
    }
    expect(xs, orderedEquals([...xs]..sort()));
    handle.dispose();
  });

  testWidgets('COMP-08: each option shows its pattern in the current color', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    for (final entry in _names.entries) {
      final swatch = find.descendant(
        of: find.bySemanticsLabel(entry.value),
        matching: find.byType(NotebookCover),
      );
      final cover = tester.widget<NotebookCover>(swatch);
      expect(cover.color, NotebookColor.musgo);
      expect(cover.pattern, entry.key);
      expect(cover.label, isNull);
      expect(tester.getSize(swatch), const Size(36, 46));
    }
    handle.dispose();
  });

  testWidgets('COMP-08: selected option has a 2 px ink1 ring on bgFolha and '
      'selected: true', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final selected = _card(tester, 'Grade');
    expect(selected.color, _colors.bgFolha);
    expect(selected.border, Border.all(color: _colors.ink1, width: 2));
    expect(selected.borderRadius, BorderRadius.circular(JotRadius.rCampo));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Grade')),
      isSemantics(
        label: 'Grade',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );

    for (final name in ['Lisa', 'Pautada', 'Pontos']) {
      final card = _card(tester, name);
      expect(card.color, isNull);
      expect(card.border, Border.all(color: _colors.lineForte));
      expect(
        tester.getSemantics(find.bySemanticsLabel(name)),
        isSemantics(
          label: name,
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
    }
    handle.dispose();
  });

  testWidgets('COMP-08: option name is 13/500 in ink1', (tester) async {
    await _pump(tester);

    final style = tester
        .renderObject<RenderParagraph>(find.text('Pontos'))
        .text
        .style!;
    expect(style.fontSize, 13);
    expect(style.fontWeight, FontWeight.w500);
    expect(style.color, _colors.ink1);
  });

  testWidgets('COMP-08: tapping an option calls onChanged with its pattern', (
    tester,
  ) async {
    final changes = <CoverPattern>[];
    await _pump(tester, onChanged: changes.add);

    await tester.tap(find.text('Pautada'));

    expect(changes, [CoverPattern.pautada]);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
