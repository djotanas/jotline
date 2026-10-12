import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_colors.dart';

void main() {
  test('THEME-01: every color token has the exact canvas hex', () {
    const c = JotColors.light;
    final expected = <String, (Color, int)>{
      'bgMesa': (c.bgMesa, 0xFFF3F2EE),
      'bgPapel': (c.bgPapel, 0xFFFBFAF7),
      'bgFolha': (c.bgFolha, 0xFFFFFFFF),
      'bgTrilho': (c.bgTrilho, 0xFFE6E4DE),
      'lineBase': (c.lineBase, 0xFFDAD7CF),
      'lineForte': (c.lineForte, 0xFFCFCCC4),
      'inkDeco': (c.inkDeco, 0xFF8A877F),
      'inkFeito': (c.inkFeito, 0xFF6E6B64),
      'ink2': (c.ink2, 0xFF5E5B54),
      'inkCorpo': (c.inkCorpo, 0xFF3A3833),
      'ink1': (c.ink1, 0xFF1B1A17),
      'bgVeu': (c.bgVeu, 0xFF8E8C86),
      'accent': (c.accent, 0xFF2747C9),
      'accentPress': (c.accentPress, 0xFF1A3399),
      'accentSoft': (c.accentSoft, 0xFFDCE2F8),
      'accentWash': (c.accentWash, 0xFFEEF1FC),
      'accentTraco': (c.accentTraco, 0xFFB9C3EA),
      'danger': (c.danger, 0xFFA4402A),
      'dangerBg': (c.dangerBg, 0xFFFBEDE8),
      'accentBusca': (c.accentBusca, 0xFFF3E2A9),
    };

    expect(expected, hasLength(20));
    for (final MapEntry(key: name, value: (color, hex)) in expected.entries) {
      expect(color.toARGB32(), hex, reason: name);
    }
  });
}
