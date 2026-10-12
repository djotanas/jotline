import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

void main() {
  test('THEME-03: spacing tokens match the shape table', () {
    expect(JotSpace.space1, 4);
    expect(JotSpace.space2, 8);
    expect(JotSpace.space3, 12);
    expect(JotSpace.space4, 16);
    expect(JotSpace.space5, 20);
    expect(JotSpace.space6, 24);
    expect(JotSpace.space8, 32);
    expect(JotSpace.space11, 44);
    expect(JotSpace.space14, 56);
  });

  test('THEME-03: radius tokens match the shape table', () {
    expect(JotRadius.rEtiqueta, 3);
    expect(JotRadius.rBloco, 10);
    expect(JotRadius.rCampo, 12);
    expect(JotRadius.rCard, 14);
    expect(JotRadius.rBotao, 16);
    expect(JotRadius.rFab, 18);
    expect(JotRadius.rPilula, 22);
    expect(JotRadius.rSheet, 24);
  });

  test('THEME-03: rCapa is 4 on the spine side and 12 on the open side', () {
    expect(
      JotRadius.rCapa,
      const BorderRadius.only(
        topLeft: Radius.circular(4),
        bottomLeft: Radius.circular(4),
        topRight: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
    );
  });
}
