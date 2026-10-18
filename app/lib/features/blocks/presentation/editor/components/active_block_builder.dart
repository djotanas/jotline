import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/blocks/presentation/editor/block_drag_controller.dart';
import 'package:jotline/l10n/app_localizations.dart';
import 'package:super_editor/super_editor.dart';

/// Wraps the component of every block with the block's 24 px side padding,
/// and draws the block in edit: the canvas in-edit box behind the text and
/// the drag handle at its left (EDIT-02, BMOVE-01).
class ActiveBlockBuilder implements ComponentBuilder {
  const new(this.inner, {this.dragController});

  final List<ComponentBuilder> inner;

  /// Starts a drag from the handle; without one the handle is static.
  final BlockDragController? dragController;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) {
    for (final builder in inner) {
      final viewModel = builder.createViewModel(document, node);
      if (viewModel != null) return viewModel;
    }
    return null;
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    for (final builder in inner) {
      final component = builder.createComponent(
        componentContext,
        componentViewModel,
      );
      if (component == null) continue;
      return ActiveBlock(
        active:
            componentViewModel is TextComponentViewModel &&
            componentViewModel.selection != null,
        nodeId: componentViewModel.nodeId,
        dragController: dragController,
        child: component,
      );
    }
    return null;
  }
}

/// A block's component with its side padding and, while [active], the
/// in-edit box and the drag handle.
class ActiveBlock extends StatelessWidget {
  const new({
    required this.active,
    required this.child,
    this.nodeId,
    this.dragController,
    super.key,
  });

  final bool active;
  final Widget child;
  final String? nodeId;
  final BlockDragController? dragController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (active)
          Positioned.fill(
            left: JotSpace.space3,
            right: JotSpace.space3,
            top: -JotSpace.space2,
            bottom: -JotSpace.space2,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.accentWash,
                  borderRadius: BorderRadius.circular(JotRadius.rBloco),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: JotSpace.space6),
          child: child,
        ),
        if (active)
          Positioned(
            left: 0,
            top: 0,
            child: BlockDragHandle(nodeId: nodeId, controller: dragController),
          ),
      ],
    );
  }
}

/// The drag handle of the block in edit, in `inkDeco` (BMOVE-01). A long
/// press on it drags the block through [controller] (BMOVE-02).
class BlockDragHandle extends StatelessWidget {
  const new({this.nodeId, this.controller, super.key});

  final String? nodeId;
  final BlockDragController? controller;

  @override
  Widget build(BuildContext context) {
    final glyph = Transform.translate(
      offset: const Offset(-JotSpace.space1, 0),
      child: IconTheme(
        data: IconThemeData(color: context.colors.inkDeco),
        child: const JotIcon(JotIconGlyph.dragHandle),
      ),
    );
    final controller = this.controller;
    final nodeId = this.nodeId;
    return Semantics(
      label: AppLocalizations.of(context).moveBlock,
      child: controller == null || nodeId == null
          ? glyph
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPressStart: (details) =>
                  controller.start(context, nodeId, details.globalPosition),
              onLongPressMoveUpdate: (details) =>
                  controller.update(details.globalPosition),
              onLongPressEnd: (_) => controller.end(),
              onLongPressCancel: controller.cancel,
              child: glyph,
            ),
    );
  }
}
