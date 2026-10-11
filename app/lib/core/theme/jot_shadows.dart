import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_colors.dart';

/// Elevation tokens of the canvas design system.
class JotShadows extends ThemeExtension<JotShadows> {
  const new({
    required this.toque,
    required this.capa,
    required this.erguido,
    required this.fab,
  });

  /// Builds the canvas shadows with the given color tokens.
  factory from(JotColors colors) {
    const black = Color(0xFF000000);
    return JotShadows(
      toque: [
        BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 2,
          color: black.withValues(alpha: 0.08),
        ),
      ],
      capa: [
        BoxShadow(
          offset: const Offset(0, 1),
          color: black.withValues(alpha: 0.06),
        ),
        BoxShadow(
          offset: const Offset(0, 6),
          blurRadius: 14,
          color: colors.ink1.withValues(alpha: 0.12),
        ),
      ],
      erguido: [
        BoxShadow(
          offset: const Offset(0, 12),
          blurRadius: 28,
          color: colors.ink1.withValues(alpha: 0.18),
        ),
      ],
      fab: [
        BoxShadow(
          offset: const Offset(0, 8),
          blurRadius: 24,
          color: colors.accent.withValues(alpha: 0.28),
        ),
      ],
    );
  }

  static final light = JotShadows.from(JotColors.light);

  final List<BoxShadow> toque;
  final List<BoxShadow> capa;
  final List<BoxShadow> erguido;
  final List<BoxShadow> fab;

  @override
  JotShadows copyWith({
    List<BoxShadow>? toque,
    List<BoxShadow>? capa,
    List<BoxShadow>? erguido,
    List<BoxShadow>? fab,
  }) {
    return JotShadows(
      toque: toque ?? this.toque,
      capa: capa ?? this.capa,
      erguido: erguido ?? this.erguido,
      fab: fab ?? this.fab,
    );
  }

  @override
  JotShadows lerp(JotShadows? other, double t) {
    if (other == null) return this;
    return JotShadows(
      toque: BoxShadow.lerpList(toque, other.toque, t)!,
      capa: BoxShadow.lerpList(capa, other.capa, t)!,
      erguido: BoxShadow.lerpList(erguido, other.erguido, t)!,
      fab: BoxShadow.lerpList(fab, other.fab, t)!,
    );
  }
}
