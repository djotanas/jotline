import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// One option of a [JotSegmentedControl], shown as "label · count".
class JotSegment<T> {
  const new({required this.value, required this.label, required this.count});

  final T value;
  final String label;
  final int count;
}

/// A segmented filter with exactly one selected option.
class JotSegmentedControl<T> extends StatelessWidget {
  const new({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<JotSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.textStyles.apoio;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgTrilho,
        borderRadius: BorderRadius.circular(JotRadius.rCampo),
      ),
      child: Padding(
        padding: const EdgeInsets.all(JotSpace.space1),
        child: Row(
          spacing: JotSpace.space1,
          children: [
            for (final segment in segments)
              Expanded(
                child: _Segment(
                  text: '${segment.label} · ${segment.count}',
                  isSelected: segment.value == selected,
                  onTap: () => onChanged(segment.value),
                  decoration: segment.value == selected
                      ? BoxDecoration(
                          color: colors.bgFolha,
                          borderRadius: BorderRadius.circular(JotRadius.rBloco),
                          boxShadow: context.shadows.toque,
                        )
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(JotRadius.rBloco),
                        ),
                  style: segment.value == selected
                      ? base.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.ink1,
                        )
                      : base.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.ink2,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const new({
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.decoration,
    required this.style,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final BoxDecoration decoration;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: JotSpace.space11 - JotSpace.space1,
          ),
          child: DecoratedBox(
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: JotSpace.space2),
              child: Center(
                child: Text(
                  text,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
