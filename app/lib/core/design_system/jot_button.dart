import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

enum _JotButtonVariant { primary, destructive, pill, text }

/// The canvas buttons. A `null` [onPressed] renders the disabled style.
class JotButton extends StatefulWidget {
  const new primary({required this.label, super.key, this.onPressed})
    : _variant = _JotButtonVariant.primary;

  /// Has no disabled state in the canvas, so [onPressed] is required.
  const new destructive({
    required this.label,
    required VoidCallback this.onPressed,
    super.key,
  }) : _variant = _JotButtonVariant.destructive;

  const new pill({required this.label, super.key, this.onPressed})
    : _variant = _JotButtonVariant.pill;

  const new text({required this.label, super.key, this.onPressed})
    : _variant = _JotButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final _JotButtonVariant _variant;

  @override
  State<JotButton> createState() => _JotButtonState();
}

class _JotButtonState extends State<JotButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final pressed = _enabled && _pressed;

    final (
      Color? background,
      Border? border,
      double radius,
      TextStyle label,
      EdgeInsets padding,
      double minHeight,
    ) = switch (widget._variant) {
      _JotButtonVariant.primary => (
        !_enabled
            ? colors.bgTrilho
            : pressed
            ? colors.accentPress
            : colors.accent,
        null,
        JotRadius.rBotao,
        styles.tituloSheet.copyWith(
          color: _enabled ? colors.bgFolha : colors.inkFeito,
        ),
        const EdgeInsets.symmetric(horizontal: JotSpace.space5),
        JotSpace.space14,
      ),
      _JotButtonVariant.destructive => (
        colors.danger,
        null,
        JotRadius.rBotao,
        styles.tituloSheet.copyWith(color: colors.bgFolha),
        const EdgeInsets.symmetric(horizontal: JotSpace.space5),
        JotSpace.space14,
      ),
      _JotButtonVariant.pill => (
        pressed ? colors.bgTrilho : colors.bgMesa,
        Border.all(
          color: !_enabled
              ? colors.bgTrilho
              : pressed
              ? colors.lineForte
              : colors.lineBase,
        ),
        JotRadius.rPilula,
        styles.apoio.copyWith(
          fontWeight: FontWeight.w500,
          color: _enabled ? colors.ink1 : colors.inkFeito,
        ),
        const EdgeInsets.symmetric(horizontal: JotSpace.space4),
        JotSpace.space11,
      ),
      _JotButtonVariant.text => (
        pressed ? colors.accentWash : null,
        null,
        JotRadius.rBloco,
        styles.acao.copyWith(
          color: !_enabled
              ? colors.inkFeito
              : pressed
              ? colors.accentPress
              : colors.accent,
        ),
        const EdgeInsets.symmetric(horizontal: JotSpace.space3),
        JotSpace.space11,
      ),
    };

    final fullWidth =
        widget._variant == _JotButtonVariant.primary ||
        widget._variant == _JotButtonVariant.destructive;

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: fullWidth ? double.infinity : JotSpace.space11,
            minHeight: minHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              border: border,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Padding(
              padding: padding,
              child: Center(
                widthFactor: 1,
                child: Text(
                  widget.label,
                  style: label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
