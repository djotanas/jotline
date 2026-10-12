import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// A small state label, such as "Arquivado".
class JotBadge extends StatelessWidget {
  const new(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.bgTrilho,
        borderRadius: BorderRadius.circular(JotRadius.rSelo),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: JotSpace.space2,
          vertical: JotSpace.space1 / 2,
        ),
        child: Text(label, style: context.textStyles.selo),
      ),
    );
  }
}
