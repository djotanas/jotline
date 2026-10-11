import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// Picks one of the four cover patterns, previewed in [color].
class NotebookCoverPicker extends StatelessWidget {
  const new({
    required this.color,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  static const Size swatchSize = Size(36, 46);
  static const double ringWidth = 2;

  final NotebookColor color;
  final CoverPattern selected;
  final ValueChanged<CoverPattern> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final label = context.textStyles.rotulo.copyWith(
      fontWeight: FontWeight.w500,
      color: colors.ink1,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: JotSpace.space3,
      children: [
        for (final pattern in CoverPattern.values)
          Expanded(
            child: Semantics(
              button: true,
              selected: pattern == selected,
              label: _name(l10n, pattern),
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(pattern),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: pattern == selected ? colors.bgFolha : null,
                      borderRadius: BorderRadius.circular(JotRadius.rCampo),
                      border: pattern == selected
                          ? Border.all(color: colors.ink1, width: ringWidth)
                          : Border.all(color: colors.lineForte),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: JotSpace.space3,
                        bottom: JotSpace.space2,
                      ),
                      child: Column(
                        spacing: JotSpace.space2,
                        children: [
                          SizedBox.fromSize(
                            size: swatchSize,
                            child: NotebookCover.mini(
                              color: color,
                              pattern: pattern,
                            ),
                          ),
                          Text(
                            _name(l10n, pattern),
                            style: label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  static String _name(AppLocalizations l10n, CoverPattern pattern) {
    return switch (pattern) {
      CoverPattern.lisa => l10n.coverPatternLisa,
      CoverPattern.pautada => l10n.coverPatternPautada,
      CoverPattern.pontilhada => l10n.coverPatternPontilhada,
      CoverPattern.quadriculada => l10n.coverPatternQuadriculada,
    };
  }
}
