import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// An icon-only button. A `null` [onPressed] renders the disabled style
/// (DRAW-09).
class JotIconButton extends StatefulWidget {
  const new({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final JotIconGlyph icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  State<JotIconButton> createState() => _JotIconButtonState();
}

class _JotIconButtonState extends State<JotIconButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        child: SizedBox.square(
          dimension: JotSpace.space11,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _enabled && _pressed ? colors.bgTrilho : null,
              borderRadius: BorderRadius.circular(JotRadius.rPilula),
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  color: _enabled ? colors.ink1 : colors.inkDeco,
                ),
                child: JotIcon(widget.icon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
