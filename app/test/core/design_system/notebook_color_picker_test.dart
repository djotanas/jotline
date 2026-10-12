import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/notebook_color_picker.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

const Map<NotebookColor, String> _names = {
  NotebookColor.azulTinta: 'Azul tinta',
  NotebookColor.terracota: 'Terracota',
  NotebookColor.musgo: 'Musgo',
  NotebookColor.mostarda: 'Mostarda',
  NotebookColor.ameixa: 'Ameixa',
  NotebookColor.grafite: 'Grafite',
};

Future<void> _pump(
  WidgetTester tester, {
  NotebookColor selected = NotebookColor.musgo,
  ValueChanged<NotebookColor>? onChanged,
  double textScale = 1,
  double width = 360,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(
        child: SizedBox(
          width: width,
          child: NotebookColorPicker(
            selected: selected,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _ring(WidgetTester tester, String name) {
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

BoxDecoration _dot(WidgetTester tester, String name) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.bySemanticsLabel(name),
          matching: find.byType(DecoratedBox),
        )
        .last,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  testWidgets('COMP-08: six options labeled with the canvas names, in order', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final xs = <double>[];
    for (final entry in _names.entries) {
      final option = find.bySemanticsLabel(entry.value);
      expect(option, findsOneWidget);
      expect(_dot(tester, entry.value).color, entry.key.color);
      xs.add(tester.getCenter(option).dx);
    }
    expect(xs, orderedEquals([...xs]..sort()));
    handle.dispose();
  });

  testWidgets('COMP-08: selected option has a 2 px ink1 ring and '
      'selected: true', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final ring = _ring(tester, 'Musgo');
    expect(ring.border, Border.all(color: _colors.ink1, width: 2));
    expect(ring.shape, BoxShape.circle);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Musgo')),
      isSemantics(
        label: 'Musgo',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );

    for (final name in _names.values.where((n) => n != 'Musgo')) {
      expect(_ring(tester, name).border, isNull);
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

  testWidgets('COMP-08: options are 48 px with a 36 px swatch', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(
      tester.getSize(find.bySemanticsLabel('Terracota')),
      const Size(48, 48),
    );
    final dot = find
        .descendant(
          of: find.bySemanticsLabel('Terracota'),
          matching: find.byType(DecoratedBox),
        )
        .last;
    expect(tester.getSize(dot), const Size(36, 36));
    handle.dispose();
  });

  testWidgets('COMP-08: tapping an option calls onChanged with its color', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = <NotebookColor>[];
    await _pump(tester, onChanged: changes.add);

    await tester.tap(find.bySemanticsLabel('Ameixa'));

    expect(changes, [NotebookColor.ameixa]);
    handle.dispose();
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });

  testWidgets('COMP-08: 280 px width fits all six options without overflow', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = <NotebookColor>[];
    await _pump(tester, width: 280, onChanged: changes.add);

    expect(tester.takeException(), isNull);
    for (final name in _names.values) {
      final size = tester.getSize(find.bySemanticsLabel(name));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      await tester.tap(find.bySemanticsLabel(name));
    }
    expect(changes, NotebookColor.values);
    expect(
      _ring(tester, 'Musgo').border,
      Border.all(color: _colors.ink1, width: 2),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Musgo')),
      isSemantics(
        label: 'Musgo',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    handle.dispose();
  });
}
