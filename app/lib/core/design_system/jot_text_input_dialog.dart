import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/jot_text_field.dart';
import 'package:jotline/core/text/title_rules.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// Asks for a short text. Resolves to the typed text when "Salvar" is tapped
/// and to `null` when the user cancels or dismisses the dialog.
///
/// "Salvar" is disabled while the text is blank unless [allowEmpty] is true.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  required bool allowEmpty,
  String initialValue = '',
  String? hintText,
  String? helperText,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: context.colors.bgVeu,
    builder: (context) => JotTextInputDialog(
      title: title,
      label: label,
      allowEmpty: allowEmpty,
      initialValue: initialValue,
      hintText: hintText,
      helperText: helperText,
    ),
  );
}

/// The canvas rename dialog: title, a limited text field and two actions.
class JotTextInputDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.label,
    required this.allowEmpty,
    super.key,
    this.initialValue = '',
    this.hintText,
    this.helperText,
  });

  /// Length from which the field shows its counter.
  static const int counterFrom = 40;

  final String title;
  final String label;
  final bool allowEmpty;
  final String initialValue;
  final String? hintText;
  final String? helperText;

  @override
  State<JotTextInputDialog> createState() => _JotTextInputDialogState();
}

class _JotTextInputDialogState extends State<JotTextInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave => widget.allowEmpty || _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            JotSpace.space5,
            JotSpace.space5,
            JotSpace.space5,
            JotSpace.space5 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Semantics(
            role: SemanticsRole.dialog,
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: widget.title,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.bgMesa,
                borderRadius: BorderRadius.circular(JotRadius.rSheet),
                boxShadow: context.shadows.erguido,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    JotSpace.space5,
                    JotSpace.space6,
                    JotSpace.space5,
                    JotSpace.space4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: JotSpace.space4,
                    children: [
                      Text(
                        widget.title,
                        style: context.textStyles.blocoTitulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      JotTextField(
                        label: widget.label,
                        controller: _controller,
                        autofocus: true,
                        maxLength: maxTitleLength,
                        counterFrom: JotTextInputDialog.counterFrom,
                        hintText: widget.hintText,
                        helperText: widget.helperText,
                        onChanged: (_) => setState(() {}),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: JotSpace.space2,
                        children: [
                          JotButton.text(
                            label: l10n.cancel,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          _SaveButton(
                            label: l10n.save,
                            onPressed: _canSave
                                ? () =>
                                      Navigator.of(context)
                                          .pop(_controller.text)
                                : null,
                          ),
                        ],
                      ),
                    ],
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

class _SaveButton extends StatelessWidget {
  const new({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: JotSpace.space11 + 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? colors.accent : colors.lineBase,
              borderRadius: BorderRadius.circular(JotRadius.rCard),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: JotSpace.space6),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: context.textStyles.acao.copyWith(
                    color: enabled ? colors.bgFolha : colors.inkFeito,
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
