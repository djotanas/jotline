import 'package:flutter/painting.dart';

/// The closed set of notebook colors from the canvas.
enum NotebookColor {
  azulTinta(Color(0xFF2747C9)),
  terracota(Color(0xFFB5532F)),
  musgo(Color(0xFF3F6B4A)),
  mostarda(Color(0xFFC99A2E)),
  ameixa(Color(0xFF6B3E6E)),
  grafite(Color(0xFF3B4651));

  new(this.color);

  final Color color;
}

/// The closed set of notebook cover patterns from the canvas.
enum CoverPattern { lisa, pautada, pontilhada, quadriculada }

/// Spine, elastic and pattern overlay values of the canvas notebook cover.
abstract final class NotebookCoverPaint {
  static const double spineWidth = 12;
  static const Color spineColor = Color.from(
    alpha: 0.18,
    red: 0,
    green: 0,
    blue: 0,
  );

  static const double elasticWidth = 6;
  static const double elasticInset = 18;
  static const Color elasticColor = Color.from(
    alpha: 0.28,
    red: 0,
    green: 0,
    blue: 0,
  );

  static const double ruledLineWidth = 1;
  static const double ruledSpacing = 14;
  static const Color ruledColor = Color.from(
    alpha: 0.16,
    red: 1,
    green: 1,
    blue: 1,
  );

  static const double dotRadius = 1.2;
  static const double dotSpacing = 12;
  static const Color dotColor = Color.from(
    alpha: 0.28,
    red: 1,
    green: 1,
    blue: 1,
  );

  static const double gridLineWidth = 1;
  static const double gridSpacing = 14;
  static const Color gridColor = Color.from(
    alpha: 0.14,
    red: 1,
    green: 1,
    blue: 1,
  );
}
