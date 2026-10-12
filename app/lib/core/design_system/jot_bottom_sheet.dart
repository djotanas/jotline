import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// Opens a [JotBottomSheet] over `bgVeu`. "Cancelar" closes it with `null`.
Future<T?> showJotBottomSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  required String primaryLabel,
  required VoidCallback? onPrimary,
}) {
  return showJotSheet<T>(
    context,
    (context) => JotBottomSheet(
      title: title,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      child: child,
    ),
  );
}

/// Opens the canvas sheet frame over `bgVeu` around a [JotBottomSheet] that
/// [builder] creates, for sheets whose primary action depends on their state.
Future<T?> showJotSheet<T>(BuildContext context, WidgetBuilder builder) {
  final colors = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    barrierColor: colors.bgVeu,
    backgroundColor: colors.bgMesa,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(JotRadius.rSheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    isScrollControlled: true,
    useSafeArea: true,
    builder: builder,
  );
}

/// The content of the canvas bottom sheet: handle, "Cancelar", title, a
/// content slot and the primary action at the end.
class JotBottomSheet extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    super.key,
  });

  static const Key handleKey = ValueKey('jotBottomSheetHandle');
  static const Size handleSize = Size(40, 5);
  static const double headerTrailingWidth = 64;

  final String title;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        JotSpace.space5,
        JotSpace.space3,
        JotSpace.space5,
        JotSpace.space6 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: JotSpace.space5,
        children: [
          Center(
            child: SizedBox.fromSize(
              size: handleSize,
              child: DecoratedBox(
                key: handleKey,
                decoration: BoxDecoration(
                  color: colors.lineForte,
                  borderRadius: BorderRadius.circular(JotRadius.rEtiqueta),
                ),
              ),
            ),
          ),
          Row(
            children: [
              JotButton.text(
                label: AppLocalizations.of(context).cancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  title,
                  style: context.textStyles.tituloSheet,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: headerTrailingWidth),
            ],
          ),
          child,
          JotButton.primary(label: primaryLabel, onPressed: onPrimary),
        ],
      ),
    );
  }
}
