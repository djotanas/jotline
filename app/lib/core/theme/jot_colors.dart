import 'package:flutter/material.dart';

/// Color tokens of the canvas design system.
class JotColors extends ThemeExtension<JotColors> {
  const new({
    required this.bgMesa,
    required this.bgPapel,
    required this.bgFolha,
    required this.bgTrilho,
    required this.lineBase,
    required this.lineForte,
    required this.inkDeco,
    required this.inkFeito,
    required this.ink2,
    required this.inkCorpo,
    required this.ink1,
    required this.bgVeu,
    required this.accent,
    required this.accentPress,
    required this.accentSoft,
    required this.accentWash,
    required this.accentTraco,
    required this.danger,
    required this.dangerBg,
    required this.accentBusca,
  });

  static const light = JotColors(
    bgMesa: Color(0xFFF3F2EE),
    bgPapel: Color(0xFFFBFAF7),
    bgFolha: Color(0xFFFFFFFF),
    bgTrilho: Color(0xFFE6E4DE),
    lineBase: Color(0xFFDAD7CF),
    lineForte: Color(0xFFCFCCC4),
    inkDeco: Color(0xFF8A877F),
    inkFeito: Color(0xFF6E6B64),
    ink2: Color(0xFF5E5B54),
    inkCorpo: Color(0xFF3A3833),
    ink1: Color(0xFF1B1A17),
    bgVeu: Color(0xFF8E8C86),
    accent: Color(0xFF2747C9),
    accentPress: Color(0xFF1A3399),
    accentSoft: Color(0xFFDCE2F8),
    accentWash: Color(0xFFEEF1FC),
    accentTraco: Color(0xFFB9C3EA),
    danger: Color(0xFFA4402A),
    dangerBg: Color(0xFFFBEDE8),
    accentBusca: Color(0xFFF3E2A9),
  );

  final Color bgMesa;
  final Color bgPapel;
  final Color bgFolha;
  final Color bgTrilho;
  final Color lineBase;
  final Color lineForte;
  final Color inkDeco;
  final Color inkFeito;
  final Color ink2;
  final Color inkCorpo;
  final Color ink1;
  final Color bgVeu;
  final Color accent;
  final Color accentPress;
  final Color accentSoft;
  final Color accentWash;
  final Color accentTraco;
  final Color danger;
  final Color dangerBg;
  final Color accentBusca;

  @override
  JotColors copyWith({
    Color? bgMesa,
    Color? bgPapel,
    Color? bgFolha,
    Color? bgTrilho,
    Color? lineBase,
    Color? lineForte,
    Color? inkDeco,
    Color? inkFeito,
    Color? ink2,
    Color? inkCorpo,
    Color? ink1,
    Color? bgVeu,
    Color? accent,
    Color? accentPress,
    Color? accentSoft,
    Color? accentWash,
    Color? accentTraco,
    Color? danger,
    Color? dangerBg,
    Color? accentBusca,
  }) {
    return JotColors(
      bgMesa: bgMesa ?? this.bgMesa,
      bgPapel: bgPapel ?? this.bgPapel,
      bgFolha: bgFolha ?? this.bgFolha,
      bgTrilho: bgTrilho ?? this.bgTrilho,
      lineBase: lineBase ?? this.lineBase,
      lineForte: lineForte ?? this.lineForte,
      inkDeco: inkDeco ?? this.inkDeco,
      inkFeito: inkFeito ?? this.inkFeito,
      ink2: ink2 ?? this.ink2,
      inkCorpo: inkCorpo ?? this.inkCorpo,
      ink1: ink1 ?? this.ink1,
      bgVeu: bgVeu ?? this.bgVeu,
      accent: accent ?? this.accent,
      accentPress: accentPress ?? this.accentPress,
      accentSoft: accentSoft ?? this.accentSoft,
      accentWash: accentWash ?? this.accentWash,
      accentTraco: accentTraco ?? this.accentTraco,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      accentBusca: accentBusca ?? this.accentBusca,
    );
  }

  @override
  JotColors lerp(JotColors? other, double t) {
    if (other == null) return this;
    return JotColors(
      bgMesa: Color.lerp(bgMesa, other.bgMesa, t)!,
      bgPapel: Color.lerp(bgPapel, other.bgPapel, t)!,
      bgFolha: Color.lerp(bgFolha, other.bgFolha, t)!,
      bgTrilho: Color.lerp(bgTrilho, other.bgTrilho, t)!,
      lineBase: Color.lerp(lineBase, other.lineBase, t)!,
      lineForte: Color.lerp(lineForte, other.lineForte, t)!,
      inkDeco: Color.lerp(inkDeco, other.inkDeco, t)!,
      inkFeito: Color.lerp(inkFeito, other.inkFeito, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      inkCorpo: Color.lerp(inkCorpo, other.inkCorpo, t)!,
      ink1: Color.lerp(ink1, other.ink1, t)!,
      bgVeu: Color.lerp(bgVeu, other.bgVeu, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPress: Color.lerp(accentPress, other.accentPress, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentWash: Color.lerp(accentWash, other.accentWash, t)!,
      accentTraco: Color.lerp(accentTraco, other.accentTraco, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      accentBusca: Color.lerp(accentBusca, other.accentBusca, t)!,
    );
  }
}
