import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// A text field with its label above it.
///
/// With [maxLength] the input stops at that many grapheme clusters and an
/// "N/max" counter sits right of the label once the text reaches
/// [counterFrom]; it turns `danger` at the limit.
class JotTextField extends StatefulWidget {
  const new({
    required this.label,
    super.key,
    this.controller,
    this.onChanged,
    this.maxLength,
    this.counterFrom = 0,
    this.hintText,
    this.helperText,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final int counterFrom;
  final String? hintText;
  final String? helperText;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<JotTextField> createState() => _JotTextFieldState();
}

class _JotTextFieldState extends State<JotTextField> {
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void didUpdateWidget(JotTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null) {
      _ownController?.dispose();
      _ownController = null;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final maxLength = widget.maxLength;
    final helperText = widget.helperText;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(JotRadius.rCampo),
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: JotSpace.space2,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: styles.rotulo),
            if (maxLength != null)
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final length = _controller.text.characters.length;
                  if (length < widget.counterFrom) {
                    return const SizedBox.shrink();
                  }
                  final atLimit = length >= maxLength;
                  final counter = '$length/$maxLength';
                  return Semantics(
                    liveRegion: true,
                    child: Text(
                      counter,
                      style: atLimit
                          ? styles.meta.copyWith(
                              color: colors.danger,
                              fontWeight: FontWeight.w500,
                            )
                          : styles.meta,
                    ),
                  );
                },
              ),
          ],
        ),
        TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => null,
          style: styles.tituloSheet.copyWith(fontWeight: FontWeight.w400),
          cursorColor: colors.accent,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.bgFolha,
            hintText: widget.hintText,
            hintStyle: styles.tituloSheet.copyWith(
              fontWeight: FontWeight.w400,
              color: colors.inkDeco,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: JotSpace.space4,
              vertical: JotSpace.space3,
            ),
            enabledBorder: border(colors.lineForte, 1),
            focusedBorder: border(colors.accent, 2),
          ),
        ),
        if (helperText != null) Text(helperText, style: styles.apoio),
      ],
    );
  }
}
