import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/l10n/app_localizations.dart';

void main() {
  void expectColor(Color color, {required int rgb, required double alpha}) {
    expect(color.withValues(alpha: 1).toARGB32(), 0xFF000000 | rgb);
    expect(color.a, closeTo(alpha, 1e-6));
  }

  test('THEME-04: notebook colors are a closed set in canvas order', () {
    expect(NotebookColor.values.map((c) => c.name), [
      'azulTinta',
      'terracota',
      'musgo',
      'mostarda',
      'ameixa',
      'grafite',
    ]);
  });

  test('THEME-04: notebook colors carry the canvas hex values', () {
    expect(NotebookColor.azulTinta.color.toARGB32(), 0xFF2747C9);
    expect(NotebookColor.terracota.color.toARGB32(), 0xFFB5532F);
    expect(NotebookColor.musgo.color.toARGB32(), 0xFF3F6B4A);
    expect(NotebookColor.mostarda.color.toARGB32(), 0xFFC99A2E);
    expect(NotebookColor.ameixa.color.toARGB32(), 0xFF6B3E6E);
    expect(NotebookColor.grafite.color.toARGB32(), 0xFF3B4651);
  });

  test('THEME-04: cover patterns are a closed set in canvas order', () {
    expect(CoverPattern.values.map((p) => p.name), [
      'lisa',
      'pautada',
      'pontilhada',
      'quadriculada',
    ]);
  });

  test('THEME-04: spine is 12 px of black 18%', () {
    expect(NotebookCoverPaint.spineWidth, 12);
    expectColor(NotebookCoverPaint.spineColor, rgb: 0x000000, alpha: 0.18);
  });

  test('THEME-04: elastic is 6 px of black 28%, 18 px from the open edge', () {
    expect(NotebookCoverPaint.elasticWidth, 6);
    expect(NotebookCoverPaint.elasticInset, 18);
    expectColor(NotebookCoverPaint.elasticColor, rgb: 0x000000, alpha: 0.28);
  });

  test('THEME-04: pautada draws white 16% lines, 1 px every 14 px', () {
    expect(NotebookCoverPaint.ruledLineWidth, 1);
    expect(NotebookCoverPaint.ruledSpacing, 14);
    expectColor(NotebookCoverPaint.ruledColor, rgb: 0xFFFFFF, alpha: 0.16);
  });

  test('THEME-04: pontilhada draws white 28% dots, radius 1.2, 12 px grid', () {
    expect(NotebookCoverPaint.dotRadius, 1.2);
    expect(NotebookCoverPaint.dotSpacing, 12);
    expectColor(NotebookCoverPaint.dotColor, rgb: 0xFFFFFF, alpha: 0.28);
  });

  test(
    'THEME-04: quadriculada draws white 14% grid lines, 1 px every 14 px',
    () {
      expect(NotebookCoverPaint.gridLineWidth, 1);
      expect(NotebookCoverPaint.gridSpacing, 14);
      expectColor(NotebookCoverPaint.gridColor, rgb: 0xFFFFFF, alpha: 0.14);
    },
  );

  test('THEME-04: l10n has the canvas name of every color and cover', () {
    final l10n = lookupAppLocalizations(const Locale('pt'));

    expect(l10n.notebookColorAzulTinta, 'Azul tinta');
    expect(l10n.notebookColorTerracota, 'Terracota');
    expect(l10n.notebookColorMusgo, 'Musgo');
    expect(l10n.notebookColorMostarda, 'Mostarda');
    expect(l10n.notebookColorAmeixa, 'Ameixa');
    expect(l10n.notebookColorGrafite, 'Grafite');
    expect(l10n.coverPatternLisa, 'Lisa');
    expect(l10n.coverPatternPautada, 'Pautada');
    expect(l10n.coverPatternPontilhada, 'Pontos');
    expect(l10n.coverPatternQuadriculada, 'Grade');
  });
}
