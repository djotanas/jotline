import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// A search field with the search glyph and a placeholder.
class JotSearchField extends StatelessWidget {
  const new({
    required this.placeholder,
    super.key,
    this.controller,
    this.onChanged,
  });

  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final input = context.textStyles.acao.copyWith(fontWeight: FontWeight.w400);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgTrilho,
        borderRadius: BorderRadius.circular(JotRadius.rCampo),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: JotSpace.space4,
          vertical: JotSpace.space3,
        ),
        child: Row(
          spacing: JotSpace.space3,
          children: [
            IconTheme(
              data: IconThemeData(color: colors.ink2),
              child: const JotIcon(JotIconGlyph.search, size: JotSpace.space5),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: input,
                cursorColor: colors.accent,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration.collapsed(
                  hintText: placeholder,
                  hintStyle: input.copyWith(color: colors.ink2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
