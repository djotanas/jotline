import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// A page row lifted while it is being reordered.
class DraggingPageRow extends StatelessWidget {
  const new({required this.title, super.key});

  static const double handleIconSize = 18;
  static const double tiltDegrees = -0.6;

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Transform.rotate(
      angle: tiltDegrees * math.pi / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgFolha,
          border: Border.all(color: colors.lineBase),
          borderRadius: BorderRadius.circular(JotRadius.rCard),
          boxShadow: context.shadows.erguido,
        ),
        child: Row(
          children: [
            Semantics(
              label: AppLocalizations.of(context).moveItem(title),
              child: SizedBox.square(
                dimension: JotSpace.space11,
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(color: colors.ink2),
                    child: const JotIcon(
                      JotIconGlyph.dragHandle,
                      size: handleIconSize,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  JotSpace.space4,
                  JotSpace.space3,
                  JotSpace.space4,
                ),
                child: Text(
                  title,
                  style: context.textStyles.itemTitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
