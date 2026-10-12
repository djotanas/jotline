import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';
import 'package:jotline/core/theme/jot_theme.dart';

final _themeLiteral = RegExp(
  r'\bColor(\.(from|fromARGB|fromRGBO))?\(|\bColors\.|\bfontFamily\s*:',
);
final _textLiteral = RegExp(r'''\bText\(\s*['"]''');

bool _isGenerated(String relative) =>
    relative.endsWith('.g.dart') ||
    RegExp(r'^l10n/app_localizations.*\.dart$').hasMatch(relative);

List<String> _scan(
  Directory root,
  RegExp pattern, {
  bool Function(String relative) skip = _skipNothing,
}) {
  final hits = <String>[];
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    final relative = file.path
        .substring(root.path.length + 1)
        .replaceAll(Platform.pathSeparator, '/');
    if (skip(relative)) continue;
    final lines = file.readAsLinesSync();
    final source = lines.join('\n');
    for (final match in pattern.allMatches(source)) {
      final line = '\n'.allMatches(source.substring(0, match.start)).length;
      hits.add('$relative:${line + 1}');
    }
  }
  return hits;
}

bool _skipNothing(String relative) => false;

bool _skipThemeAndGenerated(String relative) =>
    relative.startsWith('core/theme/') || _isGenerated(relative);

List<String> _themeLiteralsIn(Directory root) =>
    _scan(root, _themeLiteral, skip: _skipThemeAndGenerated);

List<String> _textLiteralsIn(Directory root) =>
    _scan(root, _textLiteral, skip: _isGenerated);

void main() {
  group('THEME-07', () {
    final theme = buildJotTheme();

    test('THEME-07: theme is Material 3 and light', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('THEME-07: scaffold background is bgMesa', () {
      expect(theme.scaffoldBackgroundColor.toARGB32(), 0xFFF3F2EE);
    });

    test('THEME-07: colorScheme.primary is accent', () {
      expect(theme.colorScheme.primary.toARGB32(), 0xFF2747C9);
    });

    test('THEME-07: theme carries the three token extensions', () {
      expect(theme.extension<JotColors>(), JotColors.light);
      expect(theme.extension<JotTextStyles>(), isNotNull);
      expect(theme.extension<JotTextStyles>()!.tituloTela.fontSize, 34);
      expect(theme.extension<JotShadows>(), isNotNull);
      expect(theme.extension<JotShadows>()!.capa, hasLength(2));
    });
  });

  group('THEME-09', () {
    late Directory fixture;

    setUp(() => fixture = Directory.systemTemp.createTempSync('scan_'));
    tearDown(() => fixture.deleteSync(recursive: true));

    void write(String relative, String content) {
      File('${fixture.path}/$relative')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    test('THEME-09: scan flags color and font literals outside the theme '
        'folder and ignores the theme folder and generated files', () {
      write('features/a.dart', 'final a = Color(0xFF000000);\n');
      write('features/b.dart', 'final b = Colors.red;\n');
      write('features/c.dart', "const c = TextStyle(fontFamily: 'X');\n");
      write('features/d.dart', 'final d = JotColors.light.ink1;\n');
      write('core/theme/e.dart', 'final e = Color(0xFF000000);\n');
      write('features/f.g.dart', 'final f = Color(0xFF000000);\n');

      expect(
        _themeLiteralsIn(fixture),
        unorderedEquals([
          'features/a.dart:1',
          'features/b.dart:1',
          'features/c.dart:1',
        ]),
      );
    });

    test('THEME-09: lib/ has no color or font literal outside the theme '
        'folder', () {
      expect(_themeLiteralsIn(Directory('lib')), isEmpty);
    });
  });

  group('STRUCT-07', () {
    late Directory fixture;

    setUp(() => fixture = Directory.systemTemp.createTempSync('scan_'));
    tearDown(() => fixture.deleteSync(recursive: true));

    test('STRUCT-07: scan flags Text string literals', () {
      File('${fixture.path}/a.dart').writeAsStringSync("Text('Olá');\n");
      File('${fixture.path}/b.dart').writeAsStringSync('Text(\n  "Olá",\n);\n');
      File('${fixture.path}/c.dart').writeAsStringSync('Text(title);\n');

      expect(
        _textLiteralsIn(fixture),
        unorderedEquals(['a.dart:1', 'b.dart:1']),
      );
    });

    test('STRUCT-07: lib/ has no Text string literal', () {
      expect(_textLiteralsIn(Directory('lib')), isEmpty);
    });
  });
}
