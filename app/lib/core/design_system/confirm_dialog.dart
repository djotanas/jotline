import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// Asks for confirmation of a destructive action. Resolves to `true` only
/// when [confirmLabel] is tapped.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: context.colors.bgVeu,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    ),
  );
  return confirmed ?? false;
}

/// The canvas confirmation dialog, exposed as an alert dialog.
class ConfirmDialog extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.confirmLabel,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JotSpace.space5),
          child: Semantics(
            role: SemanticsRole.alertDialog,
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
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
                    spacing: JotSpace.space3,
                    children: [
                      Text(
                        title,
                        style: styles.blocoTitulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: JotSpace.space3),
                        child: Text(
                          message,
                          style: styles.apoio.copyWith(
                            fontSize: styles.cardTitulo.fontSize,
                            color: colors.inkCorpo,
                          ),
                        ),
                      ),
                      JotButton.destructive(
                        label: confirmLabel,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                      JotButton.text(
                        label: AppLocalizations.of(context).cancel,
                        onPressed: () => Navigator.of(context).pop(false),
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
