import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// The floating action button. It has no disabled state: hide it instead.
class JotFab extends StatefulWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final JotIconGlyph icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<JotFab> createState() => _JotFabState();
}

class _JotFabState extends State<JotFab> {
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: JotSpace.space11,
            minHeight: JotSpace.space14,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _pressed ? colors.accentPress : colors.accent,
              borderRadius: BorderRadius.circular(JotRadius.rFab),
              boxShadow: context.shadows.fab,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: JotSpace.space5,
                right: JotSpace.space6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(
                    data: IconThemeData(color: colors.bgFolha),
                    child: JotIcon(widget.icon),
                  ),
                  const SizedBox(width: JotSpace.space3),
                  Flexible(
                    child: Text(
                      widget.label,
                      style: context.textStyles.acao.copyWith(
                        color: colors.bgFolha,
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
      ),
    );
  }
}
