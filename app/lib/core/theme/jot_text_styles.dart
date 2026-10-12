import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_colors.dart';

/// Typography tokens of the canvas design system.
class JotTextStyles extends ThemeExtension<JotTextStyles> {
  const new({
    required this.tituloTela,
    required this.tituloPagina,
    required this.blocoTitulo,
    required this.tituloSheet,
    required this.blocoTexto,
    required this.acao,
    required this.itemTitulo,
    required this.cardTitulo,
    required this.itemTrecho,
    required this.apoio,
    required this.rotulo,
    required this.meta,
    required this.selo,
  });

  /// Builds the canvas text styles with the given color tokens.
  factory from(JotColors colors) {
    return JotTextStyles(
      tituloTela: TextStyle(
        fontFamily: fontUi,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 34,
        color: colors.ink1,
      ),
      tituloPagina: TextStyle(
        fontFamily: fontUi,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 28,
        color: colors.ink1,
      ),
      blocoTitulo: TextStyle(
        fontFamily: fontUi,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colors.ink1,
      ),
      tituloSheet: TextStyle(
        fontFamily: fontUi,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colors.ink1,
      ),
      blocoTexto: TextStyle(
        fontFamily: fontTexto,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.55,
        color: colors.ink1,
        fontVariations: const [FontVariation.opticalSize(17)],
      ),
      acao: TextStyle(
        fontFamily: fontUi,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colors.ink1,
      ),
      itemTitulo: TextStyle(
        fontFamily: fontUi,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colors.ink1,
      ),
      cardTitulo: TextStyle(
        fontFamily: fontUi,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colors.ink1,
      ),
      itemTrecho: TextStyle(
        fontFamily: fontTexto,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.4,
        color: colors.ink2,
        fontVariations: const [FontVariation.opticalSize(14)],
      ),
      apoio: TextStyle(
        fontFamily: fontUi,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
        color: colors.ink2,
      ),
      rotulo: TextStyle(
        fontFamily: fontUi,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colors.ink2,
      ),
      meta: TextStyle(
        fontFamily: fontMeta,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colors.ink2,
      ),
      selo: TextStyle(
        fontFamily: fontUi,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colors.inkCorpo,
      ),
    );
  }

  static const fontUi = 'Schibsted Grotesk';
  static const fontTexto = 'Literata';
  static const fontMeta = 'IBM Plex Mono';

  final TextStyle tituloTela;
  final TextStyle tituloPagina;
  final TextStyle blocoTitulo;
  final TextStyle tituloSheet;
  final TextStyle blocoTexto;
  final TextStyle acao;
  final TextStyle itemTitulo;
  final TextStyle cardTitulo;
  final TextStyle itemTrecho;
  final TextStyle apoio;
  final TextStyle rotulo;
  final TextStyle meta;
  final TextStyle selo;

  @override
  JotTextStyles copyWith({
    TextStyle? tituloTela,
    TextStyle? tituloPagina,
    TextStyle? blocoTitulo,
    TextStyle? tituloSheet,
    TextStyle? blocoTexto,
    TextStyle? acao,
    TextStyle? itemTitulo,
    TextStyle? cardTitulo,
    TextStyle? itemTrecho,
    TextStyle? apoio,
    TextStyle? rotulo,
    TextStyle? meta,
    TextStyle? selo,
  }) {
    return JotTextStyles(
      tituloTela: tituloTela ?? this.tituloTela,
      tituloPagina: tituloPagina ?? this.tituloPagina,
      blocoTitulo: blocoTitulo ?? this.blocoTitulo,
      tituloSheet: tituloSheet ?? this.tituloSheet,
      blocoTexto: blocoTexto ?? this.blocoTexto,
      acao: acao ?? this.acao,
      itemTitulo: itemTitulo ?? this.itemTitulo,
      cardTitulo: cardTitulo ?? this.cardTitulo,
      itemTrecho: itemTrecho ?? this.itemTrecho,
      apoio: apoio ?? this.apoio,
      rotulo: rotulo ?? this.rotulo,
      meta: meta ?? this.meta,
      selo: selo ?? this.selo,
    );
  }

  @override
  JotTextStyles lerp(JotTextStyles? other, double t) {
    if (other == null) return this;
    return JotTextStyles(
      tituloTela: TextStyle.lerp(tituloTela, other.tituloTela, t)!,
      tituloPagina: TextStyle.lerp(tituloPagina, other.tituloPagina, t)!,
      blocoTitulo: TextStyle.lerp(blocoTitulo, other.blocoTitulo, t)!,
      tituloSheet: TextStyle.lerp(tituloSheet, other.tituloSheet, t)!,
      blocoTexto: TextStyle.lerp(blocoTexto, other.blocoTexto, t)!,
      acao: TextStyle.lerp(acao, other.acao, t)!,
      itemTitulo: TextStyle.lerp(itemTitulo, other.itemTitulo, t)!,
      cardTitulo: TextStyle.lerp(cardTitulo, other.cardTitulo, t)!,
      itemTrecho: TextStyle.lerp(itemTrecho, other.itemTrecho, t)!,
      apoio: TextStyle.lerp(apoio, other.apoio, t)!,
      rotulo: TextStyle.lerp(rotulo, other.rotulo, t)!,
      meta: TextStyle.lerp(meta, other.meta, t)!,
      selo: TextStyle.lerp(selo, other.selo, t)!,
    );
  }
}
