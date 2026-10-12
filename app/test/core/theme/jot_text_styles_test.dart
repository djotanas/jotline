import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';

void main() {
  const ui = 'Schibsted Grotesk';
  const texto = 'Literata';
  const meta = 'IBM Plex Mono';
  const colors = JotColors.light;

  test('THEME-02: family constants name the bundled fonts', () {
    expect(JotTextStyles.fontUi, ui);
    expect(JotTextStyles.fontTexto, texto);
    expect(JotTextStyles.fontMeta, meta);
  });

  test('THEME-02: every text style matches the typography table', () {
    final s = JotTextStyles.from(colors);
    final rows =
        <String, (TextStyle, String, double, int, double, double?, Color)>{
          'tituloTela': (s.tituloTela, ui, 34, 700, -0.68, null, colors.ink1),
          'tituloPagina': (
            s.tituloPagina,
            ui,
            28,
            700,
            -0.56,
            null,
            colors.ink1,
          ),
          'blocoTitulo': (s.blocoTitulo, ui, 19, 600, 0, null, colors.ink1),
          'tituloSheet': (s.tituloSheet, ui, 17, 600, 0, null, colors.ink1),
          'blocoTexto': (s.blocoTexto, texto, 17, 400, 0, 1.55, colors.ink1),
          'acao': (s.acao, ui, 16, 600, 0, null, colors.ink1),
          'itemTitulo': (s.itemTitulo, ui, 16, 600, 0, null, colors.ink1),
          'cardTitulo': (s.cardTitulo, ui, 15, 600, 0, null, colors.ink1),
          'itemTrecho': (s.itemTrecho, texto, 14, 400, 0, 1.4, colors.ink2),
          'apoio': (s.apoio, ui, 14, 400, 0, 1.45, colors.ink2),
          'rotulo': (s.rotulo, ui, 13, 600, 0, null, colors.ink2),
          'meta': (s.meta, meta, 12, 400, 0, null, colors.ink2),
          'selo': (s.selo, ui, 12, 500, 0, null, colors.inkCorpo),
        };

    expect(rows, hasLength(13));
    for (final MapEntry(
          key: name,
          value: (style, family, size, weight, spacing, height, color),
        )
        in rows.entries) {
      expect(style.fontFamily, family, reason: name);
      expect(style.fontSize, size, reason: name);
      expect(style.fontWeight, FontWeight(weight), reason: name);
      expect(style.letterSpacing, closeTo(spacing, 1e-9), reason: name);
      expect(style.height, height, reason: name);
      expect(style.color, color, reason: name);
    }
  });

  test('THEME-02: Literata styles set the optical size to the font size', () {
    final s = JotTextStyles.from(colors);

    expect(s.blocoTexto.fontVariations, [const FontVariation.opticalSize(17)]);
    expect(s.itemTrecho.fontVariations, [const FontVariation.opticalSize(14)]);
  });
}
