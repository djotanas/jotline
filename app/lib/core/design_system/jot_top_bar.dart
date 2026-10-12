import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// The top navigation bar: back to the previous level, or a root title.
class JotTopBar extends StatelessWidget {
  const new back({
    required String this.previousLabel,
    required VoidCallback this.onBack,
    super.key,
    this.actions = const [],
  }) : title = null;

  const new root({
    required String this.title,
    super.key,
    this.actions = const [],
  }) : previousLabel = null,
       onBack = null;

  final String? previousLabel;
  final VoidCallback? onBack;
  final String? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final leading = switch ((previousLabel, title)) {
      (final String label, _) => _BackLink(label: label, onTap: onBack!),
      (_, final String title) => Text(
        title,
        style: context.textStyles.tituloTela,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      _ => const SizedBox.shrink(),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: JotSpace.space11),
      child: Row(
        children: [
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: leading),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: JotSpace.space11),
          child: Padding(
            padding: const EdgeInsets.only(right: JotSpace.space2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: JotSpace.space1,
              children: [
                IconTheme(
                  data: IconThemeData(color: colors.accent),
                  child: const JotIcon(JotIconGlyph.back),
                ),
                Flexible(
                  child: Text(
                    label,
                    style: context.textStyles.acao.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
