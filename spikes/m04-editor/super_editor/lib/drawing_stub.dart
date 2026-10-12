import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// Stand-in for the future drawing block (#25): a non-text custom node.
@immutable
class DrawingStubNode extends BlockNode {
  DrawingStubNode({required this.id, required this.payload, super.metadata}) {
    initAddToMetadata({
      NodeMetadata.blockType: const NamedAttribution(blockType),
    });
  }

  static const blockType = 'drawing';

  @override
  final String id;

  final String payload;

  @override
  String? copyContent(dynamic selection) => null;

  @override
  bool hasEquivalentContent(DocumentNode other) =>
      other is DrawingStubNode && other.payload == payload;

  @override
  DocumentNode copyWithAddedMetadata(Map<String, dynamic> newProperties) =>
      DrawingStubNode(
        id: id,
        payload: payload,
        metadata: {...metadata, ...newProperties},
      );

  @override
  DocumentNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) =>
      DrawingStubNode(id: id, payload: payload, metadata: newMetadata);

  DrawingStubNode copy() => DrawingStubNode(id: id, payload: payload);

  @override
  bool operator ==(Object other) =>
      other is DrawingStubNode && other.id == id && other.payload == payload;

  @override
  int get hashCode => Object.hash(id, payload);
}

class DrawingStubViewModel extends SingleColumnLayoutComponentViewModel
    with SelectionAwareViewModelMixin {
  DrawingStubViewModel({
    required super.nodeId,
    super.createdAt,
    super.padding = EdgeInsets.zero,
    DocumentNodeSelection? selection,
    Color selectionColor = Colors.transparent,
  }) {
    super.selection = selection;
    super.selectionColor = selectionColor;
  }

  @override
  DrawingStubViewModel copy() => DrawingStubViewModel(
    nodeId: nodeId,
    createdAt: createdAt,
    padding: padding,
    selection: selection,
    selectionColor: selectionColor,
  );
}

class DrawingStubComponentBuilder implements ComponentBuilder {
  const DrawingStubComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => node is DrawingStubNode ? DrawingStubViewModel(nodeId: node.id) : null;

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! DrawingStubViewModel) return null;
    return IgnorePointer(
      child: SelectableBox(
        selection:
            componentViewModel.selection?.nodeSelection
                as UpstreamDownstreamNodeSelection?,
        selectionColor: componentViewModel.selectionColor,
        child: BoxComponent(
          key: componentContext.componentKey,
          child: Container(
            key: const ValueKey('drawing-stub'),
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Desenho'),
          ),
        ),
      ),
    );
  }
}
