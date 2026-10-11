import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('THEME-05: font manifest bundles the three families with the spec '
      'weights and styles, without google_fonts', () async {
    final manifest = jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;

    Set<String> variantsOf(String family) {
      final entry =
          manifest.cast<Map<String, dynamic>>().singleWhere(
                (e) => e['family'] == family,
              )['fonts']
              as List<dynamic>;
      return entry
          .cast<Map<String, dynamic>>()
          .map((f) => '${f['weight'] ?? 400}-${f['style'] ?? 'normal'}')
          .toSet();
    }

    expect(variantsOf('Schibsted Grotesk'), {
      '400-normal',
      '500-normal',
      '600-normal',
      '700-normal',
    });
    expect(variantsOf('Literata'), {'400-normal', '400-italic', '500-normal'});
    expect(variantsOf('IBM Plex Mono'), {'400-normal', '500-normal'});

    for (final family in ['Schibsted Grotesk', 'Literata', 'IBM Plex Mono']) {
      final fonts =
          manifest.cast<Map<String, dynamic>>().singleWhere(
                (e) => e['family'] == family,
              )['fonts']
              as List<dynamic>;
      for (final font in fonts.cast<Map<String, dynamic>>()) {
        final data = await rootBundle.load(
          Uri.decodeFull(font['asset'] as String),
        );
        expect(data.lengthInBytes, greaterThan(0), reason: '${font['asset']}');
      }
    }

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('google_fonts')));
  });

  test(
    'THEME-06: registerFontLicenses adds one OFL entry per family',
    () async {
      LicenseRegistry.reset();
      addTearDown(LicenseRegistry.reset);

      registerFontLicenses();

      final entries = await LicenseRegistry.licenses.toList();
      final byPackage = {
        for (final entry in entries) entry.packages.single: entry,
      };

      expect(entries, hasLength(3));
      expect(byPackage.keys.toSet(), {
        'Schibsted Grotesk',
        'Literata',
        'IBM Plex Mono',
      });

      String textOf(String family) =>
          byPackage[family]!.paragraphs.map((p) => p.text).join('\n');

      for (final family in byPackage.keys) {
        expect(textOf(family), contains('SIL OPEN FONT LICENSE'));
      }
      expect(
        textOf('Schibsted Grotesk'),
        contains('The Schibsted-Grotesk Project Authors'),
      );
      expect(textOf('Literata'), contains('The Literata Project Authors'));
      expect(textOf('IBM Plex Mono'), contains('IBM Corp.'));
    },
  );
}
