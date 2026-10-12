import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// What a screen shows in its [JotUndoToast]: the text and how to revert.
/// Each request is its own toast, so a new one replaces the visible one.
final class UndoToastRequest {
  const new({required this.message, required this.onUndo});

  final String message;
  final VoidCallback onUndo;
}

/// The canvas undo toast: a message and a "Desfazer" button.
///
/// [onTimeout] fires [duration] after the toast appears. A finger held on the
/// toast pauses the countdown; lifting it (or cancelling the touch) restarts
/// it from zero. Tapping "Desfazer" calls [onUndo] and never [onTimeout].
class JotUndoToast extends StatefulWidget {
  const new({
    required this.message,
    required this.onUndo,
    required this.onTimeout,
    super.key,
  });

  static const Duration duration = Duration(seconds: 3);

  final String message;
  final VoidCallback onUndo;
  final VoidCallback onTimeout;

  @override
  State<JotUndoToast> createState() => _JotUndoToastState();
}

class _JotUndoToastState extends State<JotUndoToast> {
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    if (_finished) return;
    _timer = Timer(JotUndoToast.duration, _timeout);
  }

  void _pause() => _timer?.cancel();

  void _timeout() {
    _finished = true;
    widget.onTimeout();
  }

  void _undo() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    widget.onUndo();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final label = styles.cardTitulo.copyWith(fontWeight: FontWeight.w400);
    return Listener(
      onPointerDown: (_) => _pause(),
      onPointerUp: (_) => _start(),
      onPointerCancel: (_) => _start(),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.ink1,
            borderRadius: BorderRadius.circular(JotRadius.rCard),
            boxShadow: context.shadows.erguido,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              JotSpace.space4,
              JotSpace.space2,
              JotSpace.space2,
              JotSpace.space2,
            ),
            child: Row(
              spacing: JotSpace.space3,
              children: [
                Expanded(
                  child: Text(
                    widget.message,
                    style: label.copyWith(color: colors.bgPapel),
                  ),
                ),
                Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _undo,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: JotSpace.space11,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: JotSpace.space4,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            AppLocalizations.of(context).undo,
                            style: styles.cardTitulo.copyWith(
                              color: colors.accentTraco,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
