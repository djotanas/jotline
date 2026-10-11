import 'package:flutter/painting.dart';

/// Spacing tokens of the canvas design system.
abstract final class JotSpace {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space11 = 44;
  static const double space14 = 56;
}

/// Radius tokens of the canvas design system.
abstract final class JotRadius {
  static const double rEtiqueta = 3;
  static const double rBloco = 10;
  static const double rCampo = 12;
  static const double rCard = 14;
  static const double rBotao = 16;
  static const double rFab = 18;
  static const double rPilula = 22;
  static const double rSheet = 24;

  /// Notebook cover: spine on the left, open side on the right.
  static const BorderRadius rCapa = BorderRadius.horizontal(
    left: Radius.circular(4),
    right: Radius.circular(12),
  );
}
