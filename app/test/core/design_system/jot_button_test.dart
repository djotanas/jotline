import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

Future<void> _pump(WidgetTester tester, Widget button) {
  return tester.pumpJot(
    Center(
      child: SizedBox(width: 320, child: Center(child: button)),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(JotButton),
      matching: find.byType(DecoratedBox),
    ),
  );
  return box.decoration as BoxDecoration;
}

TextStyle _labelStyle(WidgetTester tester, String label) {
  return tester.renderObject<RenderParagraph>(find.text(label)).text.style!;
}

void main() {
  group('COMP-01', () {
    testWidgets('COMP-01: primary uses accent, bgFolha label and rBotao', (
      tester,
    ) async {
      await _pump(tester, JotButton.primary(label: 'Criar', onPressed: () {}));

      final size = tester.getSize(find.byType(JotButton));
      expect(size.height, greaterThanOrEqualTo(56));
      expect(size.width, greaterThanOrEqualTo(44));
      final decoration = _decoration(tester);
      expect(decoration.color, _colors.accent);
      expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rBotao));
      final style = _labelStyle(tester, 'Criar');
      expect(style.color, _colors.bgFolha);
      expect(style.fontSize, 17);
      expect(style.fontWeight, FontWeight.w600);
    });

    testWidgets('COMP-01: destructive uses danger with bgFolha label', (
      tester,
    ) async {
      await _pump(
        tester,
        JotButton.destructive(label: 'Mover', onPressed: () {}),
      );

      expect(
        tester.getSize(find.byType(JotButton)).height,
        greaterThanOrEqualTo(56),
      );
      expect(_decoration(tester).color, _colors.danger);
      expect(_labelStyle(tester, 'Mover').color, _colors.bgFolha);
    });

    testWidgets('COMP-01: pill uses bgMesa, lineBase border and rPilula', (
      tester,
    ) async {
      await _pump(tester, JotButton.pill(label: 'Restaurar', onPressed: () {}));

      final size = tester.getSize(find.byType(JotButton));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
      final decoration = _decoration(tester);
      expect(decoration.color, _colors.bgMesa);
      expect(decoration.border, Border.all(color: _colors.lineBase));
      expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rPilula));
      final style = _labelStyle(tester, 'Restaurar');
      expect(style.color, _colors.ink1);
      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w500);
    });

    testWidgets('COMP-01: text uses the acao style in accent', (tester) async {
      await _pump(tester, JotButton.text(label: 'Ok', onPressed: () {}));

      final size = tester.getSize(find.byType(JotButton));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
      final style = _labelStyle(tester, 'Ok');
      expect(style.color, _colors.accent);
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w600);
    });

    testWidgets('COMP-01: tapping an enabled button calls back', (
      tester,
    ) async {
      for (final build in <JotButton Function(VoidCallback)>[
        (cb) => JotButton.primary(label: 'Tap', onPressed: cb),
        (cb) => JotButton.destructive(label: 'Tap', onPressed: cb),
        (cb) => JotButton.pill(label: 'Tap', onPressed: cb),
        (cb) => JotButton.text(label: 'Tap', onPressed: cb),
      ]) {
        var taps = 0;
        await _pump(tester, build(() => taps++));
        await tester.tap(find.byType(JotButton));
        expect(taps, 1);
      }
    });
  });

  group('COMP-02', () {
    testWidgets('COMP-02: disabled primary uses bgTrilho and inkFeito', (
      tester,
    ) async {
      await _pump(tester, const JotButton.primary(label: 'Criar'));

      expect(_decoration(tester).color, _colors.bgTrilho);
      expect(_labelStyle(tester, 'Criar').color, _colors.inkFeito);
    });

    testWidgets('COMP-02: disabled pill uses bgTrilho border and inkFeito', (
      tester,
    ) async {
      await _pump(tester, const JotButton.pill(label: 'Restaurar'));

      expect(_decoration(tester).color, _colors.bgMesa);
      expect(_decoration(tester).border, Border.all(color: _colors.bgTrilho));
      expect(_labelStyle(tester, 'Restaurar').color, _colors.inkFeito);
    });

    testWidgets('COMP-02: disabled text uses inkFeito', (tester) async {
      await _pump(tester, const JotButton.text(label: 'Ok'));

      expect(_labelStyle(tester, 'Ok').color, _colors.inkFeito);
    });

    testWidgets('COMP-02: disabled buttons are not enabled and ignore taps', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final button in const [
        JotButton.primary(label: 'Off'),
        JotButton.pill(label: 'Off'),
        JotButton.text(label: 'Off'),
      ]) {
        await _pump(tester, button);
        expect(
          tester.getSemantics(find.byType(JotButton)),
          matchesSemantics(label: 'Off', isButton: true, hasEnabledState: true),
        );
        await tester.tap(find.byType(JotButton), warnIfMissed: false);
        await tester.pump();
        expect(_labelStyle(tester, 'Off').color, _colors.inkFeito);
      }
      handle.dispose();
    });

    testWidgets('COMP-02: enabled buttons expose an enabled tap action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, JotButton.primary(label: 'On', onPressed: () {}));

      expect(
        tester.getSemantics(find.byType(JotButton)),
        matchesSemantics(
          label: 'On',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  testWidgets('text scale 2.0 renders every variant without overflow', (
    tester,
  ) async {
    await tester.pumpJot(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                JotButton.primary(label: 'Criar caderno', onPressed: () {}),
                JotButton.destructive(
                  label: 'Mover para a lixeira',
                  onPressed: () {},
                ),
                JotButton.pill(label: 'Desarquivar', onPressed: () {}),
                JotButton.text(label: 'Reordenar', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
