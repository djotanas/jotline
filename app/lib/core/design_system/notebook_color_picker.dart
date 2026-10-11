import 'package:flutter/material.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// Picks one of the six notebook colors.
class NotebookColorPicker extends StatelessWidget {
  const new({required this.selected, required this.onChanged, super.key});

  static const double optionSize = 48;
  static const double swatchSize = 36;
  static const double ringWidth = 2;

  final NotebookColor selected;
  final ValueChanged<NotebookColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink1 = context.colors.ink1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final color in NotebookColor.values)
          Semantics(
            button: true,
            selected: color == selected,
            label: _name(l10n, color),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(color),
              child: SizedBox.square(
                dimension: optionSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: color == selected
                        ? Border.all(color: ink1, width: ringWidth)
                        : null,
                  ),
                  child: Center(
                    child: SizedBox.square(
                      dimension: swatchSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _name(AppLocalizations l10n, NotebookColor color) {
    return switch (color) {
      NotebookColor.azulTinta => l10n.notebookColorAzulTinta,
      NotebookColor.terracota => l10n.notebookColorTerracota,
      NotebookColor.musgo => l10n.notebookColorMusgo,
      NotebookColor.mostarda => l10n.notebookColorMostarda,
      NotebookColor.ameixa => l10n.notebookColorAmeixa,
      NotebookColor.grafite => l10n.notebookColorGrafite,
    };
  }
}
