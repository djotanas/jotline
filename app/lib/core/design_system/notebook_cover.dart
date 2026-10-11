import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// A notebook cover that fills the size given by its parent.
class NotebookCover extends StatelessWidget {
  const new({required this.color, required this.pattern, super.key, this.label})
    : _mini = false;

  /// A small swatch of the cover: color and pattern only, as in the cover
  /// picker and the archived notebook row.
  const new mini({required this.color, required this.pattern, super.key})
    : label = null,
      _mini = true;

  final NotebookColor color;
  final CoverPattern pattern;
  final String? label;
  final bool _mini;

  @override
  Widget build(BuildContext context) {
    if (_mini) {
      return ClipRRect(
        borderRadius: JotRadius.rCapa * 0.5,
        child: CustomPaint(
          painter: NotebookCoverPainter(
            color: color,
            pattern: pattern,
            binding: false,
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    final colors = context.colors;
    final label = this.label;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: JotRadius.rCapa,
        boxShadow: context.shadows.capa,
      ),
      child: ClipRRect(
        borderRadius: JotRadius.rCapa,
        child: CustomPaint(
          painter: NotebookCoverPainter(color: color, pattern: pattern),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              JotSpace.space6,
              JotSpace.space6,
              JotSpace.space8,
              0,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: label == null
                  ? const SizedBox.expand()
                  : SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.bgPapel,
                          borderRadius: BorderRadius.circular(
                            JotRadius.rEtiqueta,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: JotSpace.space3,
                            vertical: JotSpace.space2,
                          ),
                          child: Text(
                            label,
                            style: context.textStyles.apoio.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: colors.ink1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the cover color, its pattern and, when [binding] is set, the spine
/// and the elastic.
class NotebookCoverPainter extends CustomPainter {
  const new({required this.color, required this.pattern, this.binding = true});

  final NotebookColor color;
  final CoverPattern pattern;
  final bool binding;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color.color);

    switch (pattern) {
      case CoverPattern.lisa:
        break;
      case CoverPattern.pautada:
        final line = Paint()..color = NotebookCoverPaint.ruledColor;
        for (
          var y =
              NotebookCoverPaint.ruledSpacing -
              NotebookCoverPaint.ruledLineWidth;
          y < size.height;
          y += NotebookCoverPaint.ruledSpacing
        ) {
          canvas.drawRect(
            Rect.fromLTWH(0, y, size.width, NotebookCoverPaint.ruledLineWidth),
            line,
          );
        }
      case CoverPattern.pontilhada:
        final dot = Paint()..color = NotebookCoverPaint.dotColor;
        const half = NotebookCoverPaint.dotSpacing / 2;
        for (var x = half; x < size.width; x += NotebookCoverPaint.dotSpacing) {
          for (
            var y = half;
            y < size.height;
            y += NotebookCoverPaint.dotSpacing
          ) {
            canvas.drawCircle(Offset(x, y), NotebookCoverPaint.dotRadius, dot);
          }
        }
      case CoverPattern.quadriculada:
        final line = Paint()..color = NotebookCoverPaint.gridColor;
        for (
          var y = 0.0;
          y < size.height;
          y += NotebookCoverPaint.gridSpacing
        ) {
          canvas.drawRect(
            Rect.fromLTWH(0, y, size.width, NotebookCoverPaint.gridLineWidth),
            line,
          );
        }
        for (var x = 0.0; x < size.width; x += NotebookCoverPaint.gridSpacing) {
          canvas.drawRect(
            Rect.fromLTWH(x, 0, NotebookCoverPaint.gridLineWidth, size.height),
            line,
          );
        }
    }

    if (!binding) return;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, NotebookCoverPaint.spineWidth, size.height),
        Paint()..color = NotebookCoverPaint.spineColor,
      )
      ..drawRect(
        Rect.fromLTWH(
          size.width -
              NotebookCoverPaint.elasticInset -
              NotebookCoverPaint.elasticWidth,
          0,
          NotebookCoverPaint.elasticWidth,
          size.height,
        ),
        Paint()..color = NotebookCoverPaint.elasticColor,
      );
  }

  @override
  bool shouldRepaint(NotebookCoverPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.pattern != pattern ||
        oldDelegate.binding != binding;
  }
}
