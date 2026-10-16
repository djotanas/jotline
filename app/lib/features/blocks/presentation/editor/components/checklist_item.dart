import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:super_editor/super_editor.dart';

/// Builds a [ChecklistItemComponent] for every [TaskNode] (CHECK-01).
class ChecklistItemBuilder implements ComponentBuilder {
  new(Editor editor) : _tasks = TaskComponentBuilder(editor);

  final TaskComponentBuilder _tasks;

  @override
  TaskComponentViewModel? createViewModel(
    Document document,
    DocumentNode node,
  ) => _tasks.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! TaskComponentViewModel) return null;
    return ChecklistItemComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
    );
  }
}

/// A checklist item from the canvas: a 22 × 22 checkbox, a 12 gap and the
/// text, in a row at least 44 tall; checked text in `inkFeito`, struck
/// through (CHECK-01, CHECK-03).
class ChecklistItemComponent extends StatefulWidget {
  const new({required this.viewModel, super.key});

  static const double checkboxSize = 22;
  static const double checkboxBorderWidth = 1.5;

  final TaskComponentViewModel viewModel;

  @override
  State<ChecklistItemComponent> createState() => _ChecklistItemComponentState();
}

class _ChecklistItemComponentState extends State<ChecklistItemComponent>
    with ProxyDocumentComponent<ChecklistItemComponent>, ProxyTextComposable {
  final GlobalKey _textKey = GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable =>
      childDocumentComponentKey.currentState! as TextComposable;

  TextStyle _style(Set<Attribution> attributions) {
    final style = widget.viewModel.textStyleBuilder(attributions);
    if (!widget.viewModel.isComplete) return style;
    return style.copyWith(
      color: context.colors.inkFeito,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Directionality(
      textDirection: viewModel.textDirection,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: JotSpace.space11),
        child: Row(
          children: [
            Semantics(
              container: true,
              checked: viewModel.isComplete,
              label: viewModel.text.toPlainText(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => viewModel.setComplete?.call(!viewModel.isComplete),
                child: SizedBox(
                  width: ChecklistItemComponent.checkboxSize,
                  height: JotSpace.space11,
                  child: Center(
                    child: _Checkbox(checked: viewModel.isComplete),
                  ),
                ),
              ),
            ),
            const SizedBox(width: JotSpace.space3),
            Expanded(
              child: TextComponent(
                key: _textKey,
                text: viewModel.text,
                textDirection: viewModel.textDirection,
                textAlign: viewModel.textAlignment,
                maxLines: viewModel.maxLines,
                overflow: viewModel.overflow,
                textStyleBuilder: _style,
                inlineWidgetBuilders: viewModel.inlineWidgetBuilders,
                textSelection: viewModel.selection,
                selectionColor: viewModel.selectionColor,
                highlightWhenEmpty: viewModel.highlightWhenEmpty,
                underlines: viewModel.createUnderlines(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The checkbox as decided on design review (Q3): `lineForte` border on
/// `bgFolha`, or `accent` filled with the check glyph in `bgFolha`.
class _Checkbox extends StatelessWidget {
  const new({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: ChecklistItemComponent.checkboxSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: checked ? colors.accent : colors.bgFolha,
          border: checked
              ? null
              : Border.all(
                  color: colors.lineForte,
                  width: ChecklistItemComponent.checkboxBorderWidth,
                ),
          borderRadius: BorderRadius.circular(JotRadius.rEtiqueta),
        ),
        child: checked
            ? IconTheme(
                data: IconThemeData(color: colors.bgFolha),
                child: const JotIcon(JotIconGlyph.check),
              )
            : null,
      ),
    );
  }
}
