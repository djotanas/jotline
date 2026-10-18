import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/drawing/drawing_painter.dart';
import 'package:jotline/l10n/app_localizations.dart';
import 'package:super_editor/super_editor.dart';

/// A drawing as an editor block; keys never delete it (DRAW-13, DRAW-15).
class DrawingNode extends BlockNode {
  new({required this.id, required this.content, super.metadata}) {
    initAddToMetadata({NodeMetadata.isDeletable: false});
  }

  @override
  final String id;

  final DrawingContent content;

  @override
  String? copyContent(dynamic selection) => null;

  @override
  bool hasEquivalentContent(DocumentNode other) =>
      other is DrawingNode && other.content == content;

  @override
  DocumentNode copyWithAddedMetadata(Map<String, dynamic> newProperties) =>
      DrawingNode(
        id: id,
        content: content,
        metadata: {...metadata, ...newProperties},
      );

  @override
  DocumentNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) =>
      DrawingNode(id: id, content: content, metadata: newMetadata);

  DrawingNode copy() => DrawingNode(id: id, content: content);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingNode && other.id == id && other.content == content;

  @override
  int get hashCode => Object.hash(id, content);
}

class DrawingComponentViewModel extends SingleColumnLayoutComponentViewModel
    with SelectionAwareViewModelMixin {
  new({
    required super.nodeId,
    required this.content,
    super.createdAt,
    super.maxWidth,
    super.padding = EdgeInsets.zero,
    super.opacity = 1.0,
    DocumentNodeSelection? selection,
  }) {
    super.selection = selection;
  }

  final DrawingContent content;

  @override
  DrawingComponentViewModel copy() => DrawingComponentViewModel(
    nodeId: nodeId,
    content: content,
    createdAt: createdAt,
    maxWidth: maxWidth,
    padding: padding,
    opacity: opacity,
    selection: selection,
  );
}

/// Builds the drawing card for a [DrawingNode]; a tap calls [onOpen] with
/// the node id (DRAW-13).
class DrawingComponentBuilder implements ComponentBuilder {
  const new({required this.onOpen});

  final void Function(String nodeId) onOpen;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    if (node is! DrawingNode) return null;
    return DrawingComponentViewModel(
      nodeId: node.id,
      content: node.content,
      createdAt: node.metadata[NodeMetadata.createdAt] as DateTime?,
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! DrawingComponentViewModel) return null;
    return BoxComponent(
      key: componentContext.componentKey,
      opacity: componentViewModel.opacity,
      child: DrawingCard(
        nodeId: componentViewModel.nodeId,
        content: componentViewModel.content,
        onOpen: onOpen,
      ),
    );
  }
}

/// The drawing on the page: the whole drawing area scaled to the page
/// width, on a card (DRAW-12).
class DrawingCard extends StatelessWidget {
  const new({
    required this.nodeId,
    required this.content,
    required this.onOpen,
    super.key,
  });

  final String nodeId;
  final DrawingContent content;
  final void Function(String nodeId) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(JotRadius.rCard);
    return Semantics(
      label: AppLocalizations.of(context).drawingCardLabel,
      button: true,
      excludeSemantics: true,
      onTap: () => onOpen(nodeId),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onOpen(nodeId),
        child: AspectRatio(
          aspectRatio:
              DrawingContent.logicalSize.width /
              DrawingContent.logicalSize.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.bgFolha,
              border: Border.all(color: colors.bgTrilho),
              borderRadius: radius,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: LayoutBuilder(
                builder: (context, constraints) => CustomPaint(
                  size: constraints.biggest,
                  painter: DrawingPainter(
                    content: content,
                    scale:
                        constraints.maxWidth / DrawingContent.logicalSize.width,
                    colors: colors,
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
