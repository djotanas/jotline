import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/blocks/presentation/editor/components/active_block_builder.dart';
import 'package:jotline/features/blocks/presentation/editor/plain_paste.dart';
import 'package:super_editor/super_editor.dart';

/// The page editor: plain paste ahead of the default requests, and only the
/// reaction that keeps the composer styles in sync (BAR-08).
///
/// The default conversions are left out: they fetch pasted image URLs over
/// the network (RNF-01) and create node types a block cannot store.
Editor createBlockEditor(MutableDocument document) => Editor(
  editables: {
    Editor.documentKey: document,
    Editor.composerKey: MutableDocumentComposer(),
  },
  requestHandlers: [
    plainPasteHandler,
    ...defaultRequestHandlers.cast<EditRequestHandler>(),
  ],
  reactionPipeline: [UpdateComposerTextStylesReaction()],
);

const Set<SuperEditorKeyboardAction> _indentActions = {
  tabToIndentTask,
  shiftTabToUnIndentTask,
  tabToIndentParagraph,
  shiftTabToUnIndentParagraph,
};

/// The default IME keyboard actions without Tab indent: nested lists are out
/// of scope.
final List<SuperEditorKeyboardAction> blockKeyboardActions = [
  for (final action in defaultImeKeyboardActions)
    if (!_indentActions.contains(action)) action,
];

/// The page blocks as a sliver of the page's scroll view.
class BlockEditor extends StatelessWidget {
  const new({required this.editor, required this.focusNode, super.key});

  final Editor editor;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final caretColor = context.colors.accent;
    return SuperEditor(
      editor: editor,
      focusNode: focusNode,
      stylesheet: blockStylesheet(context),
      componentBuilders: [
        ActiveBlockBuilder([
          const _BulletedListItemBuilder(),
          TaskComponentBuilder(editor),
          ...defaultComponentBuilders,
        ]),
      ],
      contentTapDelegateFactories: const [],
      keyboardActions: blockKeyboardActions,
      documentOverlayBuilders: [
        const SuperEditorIosToolbarFocalPointDocumentLayerBuilder(),
        SuperEditorIosHandlesDocumentLayerBuilder(
          handleColor: caretColor,
          caretWidth: _caretWidth,
        ),
        const SuperEditorAndroidToolbarFocalPointDocumentLayerBuilder(),
        SuperEditorAndroidHandlesDocumentLayerBuilder(caretColor: caretColor),
        DefaultCaretOverlayBuilder(caretStyle: CaretStyle(color: caretColor)),
      ],
    );
  }
}

const double _caretWidth = 2;

/// Block styles from the canvas "Editor de blocos" artboard.
Stylesheet blockStylesheet(BuildContext context) {
  final textStyles = context.textStyles;
  return Stylesheet(
    documentPadding: EdgeInsets.zero,
    rules: [
      StyleRule(
        BlockSelector.all,
        (document, node) => {
          Styles.padding: const CascadingPadding.only(
            left: 0,
            right: 0,
            top: JotSpace.space4,
            bottom: 0,
          ),
        },
      ),
      for (final blockType in const ['paragraph', 'listItem', 'task'])
        StyleRule(
          BlockSelector(blockType),
          (document, node) => {Styles.textStyle: textStyles.blocoTexto},
        ),
      StyleRule(
        BlockSelector.all.first(),
        (document, node) => {
          Styles.padding: const CascadingPadding.only(top: 0),
        },
      ),
      StyleRule(
        const BlockSelector('header1'),
        (document, node) => {
          Styles.padding: const CascadingPadding.only(
            top: JotSpace.space4 + JotSpace.space2,
          ),
          Styles.textStyle: textStyles.blocoTitulo,
        },
      ),
      StyleRule(
        const BlockSelector('header1').first(),
        (document, node) => {
          Styles.padding: const CascadingPadding.only(top: JotSpace.space2),
        },
      ),
      StyleRule(
        const BlockSelector('listItem').after('listItem'),
        (document, node) => {
          Styles.padding: const CascadingPadding.only(top: JotSpace.space1),
        },
      ),
      StyleRule(
        const BlockSelector('task').after('task'),
        (document, node) => {
          Styles.padding: const CascadingPadding.only(top: 0),
        },
      ),
    ],
    inlineTextStyler: _inlineTextStyler,
  );
}

TextStyle _inlineTextStyler(Set<Attribution> attributions, TextStyle style) {
  var result = style;
  if (attributions.contains(boldAttribution)) {
    result = result.copyWith(fontWeight: FontWeight.w600);
  }
  if (attributions.contains(italicsAttribution)) {
    result = result.copyWith(fontStyle: FontStyle.italic);
  }
  return result;
}

/// Bulleted list items with the canvas 24 px indent (BAR-11).
class _BulletedListItemBuilder extends ListItemComponentBuilder {
  const new();

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! UnorderedListItemComponentViewModel) {
      return null;
    }
    return UnorderedListItemComponent(
      componentKey: componentContext.componentKey,
      text: componentViewModel.text,
      styleBuilder: componentViewModel.textStyleBuilder,
      dotStyle: componentViewModel.dotStyle,
      textSelection: componentViewModel.selection,
      textDirection: componentViewModel.textDirection,
      textAlignment: componentViewModel.textAlignment,
      selectionColor: componentViewModel.selectionColor,
      highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
      underlines: componentViewModel.createUnderlines(),
      inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      indentCalculator: (textStyle, indent) => JotSpace.space6,
    );
  }
}
