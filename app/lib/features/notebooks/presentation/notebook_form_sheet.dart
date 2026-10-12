import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/design_system/jot_bottom_sheet.dart';
import 'package:jotline/core/design_system/jot_text_field.dart';
import 'package:jotline/core/design_system/notebook_color_picker.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/design_system/notebook_cover_picker.dart';
import 'package:jotline/core/text/title_rules.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// Opens the "Novo caderno" sheet. Resolves to the id of the notebook it
/// created, or `null` when the sheet is cancelled.
Future<String?> showNewNotebookSheet(BuildContext context) {
  return showJotSheet<String>(
    context,
    (context) => const NotebookFormSheet.create(),
  );
}

/// Opens the "Capa e cor" sheet for [summary]. Resolves to `true` once the
/// color and cover were saved, and to `false` when it is cancelled.
Future<bool> showCoverSheet(
  BuildContext context,
  NotebookSummary summary,
) async {
  final saved = await showJotSheet<bool>(
    context,
    (context) => NotebookFormSheet.edit(summary),
  );
  return saved ?? false;
}

/// The canvas "Novo caderno" sheet, also used as "Capa e cor" without the
/// name field.
class NotebookFormSheet extends ConsumerStatefulWidget {
  const new create({super.key}) : editing = null;

  const new edit(NotebookSummary this.editing, {super.key});

  /// Length from which the name shows its "N/50" counter.
  static const int counterFrom = 40;

  static const Size previewSize = Size(150, 196);

  final NotebookSummary? editing;

  @override
  ConsumerState<NotebookFormSheet> createState() => _NotebookFormSheetState();
}

class _NotebookFormSheetState extends ConsumerState<NotebookFormSheet> {
  final TextEditingController _name = TextEditingController();
  late NotebookColor _color =
      widget.editing?.notebook.color ?? NotebookColor.azulTinta;
  late CoverPattern _cover =
      widget.editing?.notebook.cover ?? CoverPattern.lisa;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving && (widget.editing != null || _name.text.trim().isNotEmpty);

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = ref.read(notebookRepositoryProvider);
    final editing = widget.editing;
    if (editing == null) {
      final id = await repository.create(
        title: _name.text,
        cover: _cover,
        color: _color,
      );
      if (mounted) Navigator.of(context).pop(id);
    } else {
      await repository.update(
        editing.notebook.id,
        cover: _cover,
        color: _color,
      );
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.textStyles;
    final editing = widget.editing;
    final typed = _name.text.trim();
    final label =
        editing?.notebook.title ??
        (typed.isEmpty ? l10n.notebookNameHint : _name.text);
    return JotBottomSheet(
      title: editing == null ? l10n.newNotebookTitle : l10n.coverSheetTitle,
      primaryLabel: editing == null ? l10n.createNotebook : l10n.save,
      onPrimary: _canSave ? _save : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: JotSpace.space6,
        children: [
          Center(
            child: SizedBox.fromSize(
              size: NotebookFormSheet.previewSize,
              child: NotebookCover(
                color: _color,
                pattern: _cover,
                label: label,
                labelMuted: editing == null && typed.isEmpty,
              ),
            ),
          ),
          if (editing == null)
            JotTextField(
              label: l10n.nameLabel,
              controller: _name,
              maxLength: maxTitleLength,
              counterFrom: NotebookFormSheet.counterFrom,
              hintText: l10n.notebookNameHint,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: JotSpace.space3,
            children: [
              Text(l10n.colorLabel, style: styles.rotulo),
              NotebookColorPicker(
                selected: _color,
                onChanged: (color) => setState(() => _color = color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: JotSpace.space3,
            children: [
              Text(l10n.coverLabel, style: styles.rotulo),
              NotebookCoverPicker(
                color: _color,
                selected: _cover,
                onChanged: (cover) => setState(() => _cover = cover),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
