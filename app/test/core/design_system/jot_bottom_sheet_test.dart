import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_bottom_sheet.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;
const _content = 'Criação e opções abrem de baixo, sobre o Véu.';

Future<void> _open(
  WidgetTester tester, {
  VoidCallback? onPrimary,
  void Function(Object?)? onClosed,
}) async {
  await tester.pumpJot(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () async {
              final result = await showJotBottomSheet<Object>(
                context,
                title: 'Novo caderno',
                primaryLabel: 'Salvar',
                onPrimary: onPrimary,
                child: const Text(_content),
              );
              onClosed?.call(result);
            },
            child: const SizedBox.square(dimension: 44, child: Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder get _sheet => find.byType(BottomSheet);

void main() {
  testWidgets('NBNEW-03: showJotSheet frames a sheet whose primary action '
      'follows its own state', (tester) async {
    await tester.pumpJot(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: GestureDetector(
              onTap: () =>
                  showJotSheet<void>(context, (context) => const _Stateful()),
              child: const SizedBox.square(dimension: 44, child: Text('open')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sheet = tester.widget<BottomSheet>(_sheet);
    expect(sheet.backgroundColor, _colors.bgMesa);
    final button = find.widgetWithText(JotButton, 'Criar');
    expect(tester.widget<JotButton>(button).onPressed, isNull);

    await tester.tap(find.text('toggle'));
    await tester.pump();

    expect(tester.widget<JotButton>(button).onPressed, isNotNull);
  });

  testWidgets('COMP-10: sheet is shown over bgVeu', (tester) async {
    await _open(tester);

    expect(_sheet, findsOneWidget);
    final barrier = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(barrier.color, _colors.bgVeu);
  });

  testWidgets('COMP-10: sheet has bgMesa and top radius 24', (tester) async {
    await _open(tester);

    final sheet = tester.widget<BottomSheet>(_sheet);
    expect(sheet.backgroundColor, _colors.bgMesa);
    expect(
      sheet.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(JotRadius.rSheet),
        ),
      ),
    );
  });

  testWidgets('COMP-10: handle is 40 x 5 in lineForte', (tester) async {
    await _open(tester);

    final handle = find.byKey(JotBottomSheet.handleKey);
    expect(tester.getSize(handle), const Size(40, 5));
    final decoration =
        tester.widget<DecoratedBox>(handle).decoration as BoxDecoration;
    expect(decoration.color, _colors.lineForte);
  });

  testWidgets('COMP-10: title uses tituloSheet and the child is rendered', (
    tester,
  ) async {
    await _open(tester);

    final style = tester
        .renderObject<RenderParagraph>(find.text('Novo caderno'))
        .text
        .style!;
    expect(style.fontSize, 17);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, _colors.ink1);
    expect(
      find.descendant(of: _sheet, matching: find.text(_content)),
      findsOneWidget,
    );
  });

  testWidgets('COMP-10: "Cancelar" from l10n is a text action that closes '
      'the sheet', (tester) async {
    final results = <Object?>['not closed'];
    await _open(tester, onClosed: (r) => results[0] = r);

    final cancel = find.descendant(
      of: find.byType(JotButton),
      matching: find.text('Cancelar'),
    );
    expect(cancel, findsOneWidget);
    final style = tester.renderObject<RenderParagraph>(cancel).text.style!;
    expect(style.color, _colors.accent);

    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(_sheet, findsNothing);
    expect(results.single, isNull);
  });

  testWidgets('COMP-10: primary action is last and calls onPrimary', (
    tester,
  ) async {
    var taps = 0;
    await _open(tester, onPrimary: () => taps++);

    final primary = find.ancestor(
      of: find.text('Salvar'),
      matching: find.byType(JotButton),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: primary, matching: find.byType(DecoratedBox)),
    );
    expect((box.decoration as BoxDecoration).color, _colors.accent);
    expect(
      tester.getTopLeft(primary).dy,
      greaterThan(tester.getBottomLeft(find.text(_content)).dy),
    );

    await tester.tap(primary);
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('COMP-10: primary action is disabled without onPrimary', (
    tester,
  ) async {
    await _open(tester);

    final primary = find.ancestor(
      of: find.text('Salvar'),
      matching: find.byType(JotButton),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: primary, matching: find.byType(DecoratedBox)),
    );
    expect((box.decoration as BoxDecoration).color, _colors.bgTrilho);
  });

  testWidgets('edge case: long title ellipsizes', (tester) async {
    await tester.pumpJot(
      const Scaffold(
        body: JotBottomSheet(
          title: 'Um título de sheet comprido demais para caber no topo',
          primaryLabel: 'Salvar',
          onPrimary: null,
          child: SizedBox.shrink(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Um título de sheet comprido demais para caber no topo'),
    );
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.didExceedMaxLines, isTrue);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester);

    expect(
      MediaQuery.textScalerOf(tester.element(find.text('Novo caderno')))
          .scale(10),
      20,
    );
    expect(tester.takeException(), isNull);
  });
}

class _Stateful extends StatefulWidget {
  const new();

  @override
  State<_Stateful> createState() => _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return JotBottomSheet(
      title: 'Novo caderno',
      primaryLabel: 'Criar',
      onPrimary: _on ? () {} : null,
      child: GestureDetector(
        onTap: () => setState(() => _on = true),
        child: const Text('toggle'),
      ),
    );
  }
}
