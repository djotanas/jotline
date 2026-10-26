import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_segmented_control.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';

import '../../helpers/pump_jot.dart';

enum _Filter { active, archived }

const JotColors _colors = JotColors.light;

Future<void> _pump(
  WidgetTester tester, {
  _Filter selected = _Filter.active,
  ValueChanged<_Filter>? onChanged,
  double textScale = 1,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(
        child: SizedBox(
          width: 360,
          child: JotSegmentedControl<_Filter>(
            segments: const [
              JotSegment(value: _Filter.active, label: 'Ativos', count: 6),
              JotSegment(
                value: _Filter.archived,
                label: 'Arquivados',
                count: 2,
              ),
            ],
            selected: selected,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _segmentDecoration(WidgetTester tester, String text) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text(text), matching: find.byType(DecoratedBox))
        .first,
  );
  return box.decoration as BoxDecoration;
}

TextStyle _style(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  testWidgets('COMP-05: renders each option as "label · count"', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Ativos · 6'), findsOneWidget);
    expect(find.text('Arquivados · 2'), findsOneWidget);
  });

  testWidgets('COMP-05: exactly one segment is selected in semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, selected: _Filter.archived);

    expect(
      tester.getSemantics(find.text('Arquivados · 2')),
      isSemantics(
        label: 'Arquivados · 2',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Ativos · 6')),
      isSemantics(
        label: 'Ativos · 6',
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('COMP-05: tapping another segment calls onChanged with its '
      'value', (tester) async {
    final changes = <_Filter>[];
    await _pump(tester, onChanged: changes.add);

    await tester.tap(find.text('Arquivados · 2'));

    expect(changes, [_Filter.archived]);
  });

  testWidgets('COMP-05: selected segment uses bgFolha, ink1 and shadowToque; '
      'others ink2 on bgTrilho', (tester) async {
    await _pump(tester);

    final selected = _segmentDecoration(tester, 'Ativos · 6');
    expect(selected.color, _colors.bgFolha);
    expect(selected.boxShadow, JotShadows.light.toque);
    expect(_style(tester, 'Ativos · 6').color, _colors.ink1);
    expect(_style(tester, 'Ativos · 6').fontWeight, FontWeight.w600);

    final other = _segmentDecoration(tester, 'Arquivados · 2');
    expect(other.color, isNull);
    expect(other.boxShadow, isNull);
    expect(_style(tester, 'Arquivados · 2').color, _colors.ink2);
    expect(_style(tester, 'Arquivados · 2').fontWeight, FontWeight.w500);

    final track =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(JotSegmentedControl<_Filter>),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(track.color, _colors.bgTrilho);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
