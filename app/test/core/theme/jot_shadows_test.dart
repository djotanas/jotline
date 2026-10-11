import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_shadows.dart';

void main() {
  void expectShadow(
    BoxShadow shadow, {
    required Offset offset,
    required double blur,
    required int rgb,
    required double alpha,
  }) {
    expect(shadow.offset, offset);
    expect(shadow.blurRadius, blur);
    expect(shadow.spreadRadius, 0);
    expect(shadow.color.withValues(alpha: 1).toARGB32(), 0xFF000000 | rgb);
    expect(shadow.color.a, closeTo(alpha, 1e-6));
  }

  final shadows = JotShadows.light;

  test('THEME-03: shadowToque is 0 1 2, black 8%', () {
    expect(shadows.toque, hasLength(1));
    expectShadow(
      shadows.toque.single,
      offset: const Offset(0, 1),
      blur: 2,
      rgb: 0x000000,
      alpha: 0.08,
    );
  });

  test('THEME-03: shadowCapa has two layers: 0 1 0 black 6% and '
      '0 6 14 #1B1A17 12%', () {
    expect(shadows.capa, hasLength(2));
    expectShadow(
      shadows.capa[0],
      offset: const Offset(0, 1),
      blur: 0,
      rgb: 0x000000,
      alpha: 0.06,
    );
    expectShadow(
      shadows.capa[1],
      offset: const Offset(0, 6),
      blur: 14,
      rgb: 0x1B1A17,
      alpha: 0.12,
    );
  });

  test('THEME-03: shadowErguido is 0 12 28, #1B1A17 18%', () {
    expect(shadows.erguido, hasLength(1));
    expectShadow(
      shadows.erguido.single,
      offset: const Offset(0, 12),
      blur: 28,
      rgb: 0x1B1A17,
      alpha: 0.18,
    );
  });

  test('THEME-03: shadowFab is 0 8 24, #2747C9 28%', () {
    expect(shadows.fab, hasLength(1));
    expectShadow(
      shadows.fab.single,
      offset: const Offset(0, 8),
      blur: 24,
      rgb: 0x2747C9,
      alpha: 0.28,
    );
  });
}
