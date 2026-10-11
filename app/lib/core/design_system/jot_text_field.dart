import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// A text field with its label above it.
class JotTextField extends StatelessWidget {
  const new({required this.label, super.key, this.controller, this.onChanged});

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(JotRadius.rCampo),
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: JotSpace.space2,
      children: [
        Text(label, style: styles.rotulo),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: styles.tituloSheet.copyWith(fontWeight: FontWeight.w400),
          cursorColor: colors.accent,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.bgFolha,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: JotSpace.space4,
              vertical: JotSpace.space3,
            ),
            enabledBorder: border(colors.lineForte, 1),
            focusedBorder: border(colors.accent, 2),
          ),
        ),
      ],
    );
  }
}
