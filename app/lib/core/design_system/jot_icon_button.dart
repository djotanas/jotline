import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// An icon-only button. It has no disabled state: hide it instead.
class JotIconButton extends StatefulWidget {
  const new({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final JotIconGlyph icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  State<JotIconButton> createState() => _JotIconButtonState();
}

class _JotIconButtonState extends State<JotIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: SizedBox.square(
          dimension: JotSpace.space11,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _pressed ? colors.bgTrilho : null,
              borderRadius: BorderRadius.circular(JotRadius.rPilula),
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(color: colors.ink1),
                child: JotIcon(widget.icon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
