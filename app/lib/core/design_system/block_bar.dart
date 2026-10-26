import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// The block types the bar offers; mirrors the persisted block types so the
/// design system does not import a feature.
enum BlockBarType { text, heading, bulletedListItem, checklistItem }

/// The "Barra de blocos": the type of the block with the cursor, then bold
/// and italic. Has no "Desenho" button (BAR-03).
class BlockBar extends StatelessWidget {
  const new({
    required this.type,
    required this.bold,
    required this.italic,
    required this.onType,
    required this.onBold,
    required this.onItalic,
    super.key,
  });

  /// The letters drawn on "Negrito" and "Itálico", as in the canvas.
  static const String boldGlyph = 'B';
  static const String italicGlyph = 'I';

  final BlockBarType type;
  final bool bold;
  final bool italic;
  final ValueChanged<BlockBarType> onType;
  final VoidCallback onBold;
  final VoidCallback onItalic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final styles = context.textStyles;
    JotBlockBarButton typeButton(
      BlockBarType value,
      String label,
      JotIconGlyph glyph,
    ) => JotBlockBarButton(
      label: label,
      active: type == value,
      onPressed: () => onType(value),
      glyph: (color) => IconTheme(
        data: IconThemeData(color: color),
        child: JotIcon(glyph),
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.blockBarLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgMesa,
          border: Border(top: BorderSide(color: colors.bgTrilho)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(JotSpace.space2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              typeButton(
                BlockBarType.text,
                l10n.blockTypeText,
                JotIconGlyph.text,
              ),
              typeButton(
                BlockBarType.heading,
                l10n.blockTypeHeading,
                JotIconGlyph.heading,
              ),
              typeButton(
                BlockBarType.bulletedListItem,
                l10n.blockTypeList,
                JotIconGlyph.list,
              ),
              typeButton(
                BlockBarType.checklistItem,
                l10n.blockTypeChecklist,
                JotIconGlyph.checklist,
              ),
              JotBlockBarButton(
                label: l10n.markBold,
                active: bold,
                onPressed: onBold,
                glyph: (color) => Text(
                  boldGlyph,
                  style: styles.barNegrito.copyWith(color: color),
                ),
              ),
              JotBlockBarButton(
                label: l10n.markItalic,
                active: italic,
                onPressed: onItalic,
                glyph: (color) => Text(
                  italicGlyph,
                  style: styles.barItalico.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 48 × 48 button of the [BlockBar]. Active: `accentSoft` background with
/// the glyph in `accentPress`, exposed as toggled (BAR-04, BAR-09).
class JotBlockBarButton extends StatelessWidget {
  const new({
    required this.label,
    required this.active,
    required this.onPressed,
    required this.glyph,
    super.key,
  });

  static const double size = 48;

  final String label;
  final bool active;
  final VoidCallback onPressed;

  /// Builds the icon or letter in the given color.
  final Widget Function(Color color) glyph;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      toggled: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: active ? colors.accentSoft : null,
              borderRadius: BorderRadius.circular(JotRadius.rCampo),
            ),
            child: Center(
              child: ExcludeSemantics(
                child: glyph(active ? colors.accentPress : colors.ink1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
