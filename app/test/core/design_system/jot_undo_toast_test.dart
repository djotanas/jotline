import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_undo_toast.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;
const _message = 'Página movida para a lixeira';

class _Calls {
  int undo = 0;
  int timeout = 0;
}

Future<_Calls> _pump(WidgetTester tester, {double textScale = 1}) async {
  final calls = _Calls();
  await tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(JotSpace.space3),
            child: JotUndoToast(
              message: _message,
              onUndo: () => calls.undo++,
              onTimeout: () => calls.timeout++,
            ),
          ),
        ),
      ),
    ),
  );
  return calls;
}

void main() {
  testWidgets('TOAST-01: shows the message and the Desfazer button', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text(_message), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);
    final style = tester
        .renderObject<RenderParagraph>(find.text(_message))
        .text
        .style!;
    expect(style.color, _colors.bgPapel);
    expect(style.fontSize, 15);
    final action = tester
        .renderObject<RenderParagraph>(find.text('Desfazer'))
        .text
        .style!;
    expect(action.color, _colors.accentTraco);
    expect(action.fontWeight, FontWeight.w600);
    await tester.pump(JotUndoToast.duration);
  });

  testWidgets('TOAST-01: ink1 card with rCard radius and the erguido shadow', (
    tester,
  ) async {
    await _pump(tester);

    final box =
        tester
                .widgetList<DecoratedBox>(
                  find.descendant(
                    of: find.byType(JotUndoToast),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .first
                .decoration
            as BoxDecoration;
    expect(box.color, _colors.ink1);
    expect(box.borderRadius, BorderRadius.circular(JotRadius.rCard));
    expect(box.boxShadow, JotShadows.light.erguido);
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Desfazer'),
                  matching: find.byType(ConstrainedBox),
                )
                .first,
          )
          .height,
      greaterThanOrEqualTo(JotSpace.space11),
    );
    await tester.pump(JotUndoToast.duration);
  });

  testWidgets('TOAST-02: onTimeout fires after exactly 3 s, not at 2.9 s', (
    tester,
  ) async {
    final calls = await _pump(tester);

    await tester.pump(const Duration(milliseconds: 2900));
    expect(calls.timeout, 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(calls.timeout, 1);
    expect(calls.undo, 0);
  });

  testWidgets('TOAST-03: holding 5 s then releasing fires 3 s after release', (
    tester,
  ) async {
    final calls = await _pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text(_message)),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(calls.timeout, 0);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 2900));
    expect(calls.timeout, 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(calls.timeout, 1);
  });

  testWidgets('TOAST-03: a cancelled touch also restarts the 3 s countdown', (
    tester,
  ) async {
    final calls = await _pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text(_message)),
    );
    await tester.pump(const Duration(seconds: 4));
    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 2900));
    expect(calls.timeout, 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(calls.timeout, 1);
  });

  testWidgets('TOAST-02: tapping Desfazer calls onUndo and never onTimeout', (
    tester,
  ) async {
    final calls = await _pump(tester);

    await tester.tap(find.text('Desfazer'));
    await tester.pump(const Duration(seconds: 10));

    expect(calls.undo, 1);
    expect(calls.timeout, 0);
  });

  testWidgets('TOAST-04: dispose cancels the timer', (tester) async {
    final calls = await _pump(tester);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));

    expect(calls.timeout, 0);
    expect(calls.undo, 0);
  });

  testWidgets('TOAST-04: the toast is a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final node = tester.getSemantics(
      find
          .ancestor(of: find.text(_message), matching: find.byType(Semantics))
          .first,
    );
    expect(node.flagsCollection.isLiveRegion, isTrue);
    expect(node.label, contains(_message));

    handle.dispose();
    await tester.pump(JotUndoToast.duration);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    await tester.pump(JotUndoToast.duration);
  });
}
