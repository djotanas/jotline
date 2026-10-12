import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/ids/id_generator.dart';

import '../../helpers/lib_scan.dart';

void main() {
  test('ID-01: ids are lowercase hyphenated UUID v7 strings', () {
    final id = UuidV7Generator().newId();

    expect(id, hasLength(36));
    expect(
      id,
      matches(
        RegExp(
          '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}'
          r'-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('ID-02: 10,000 ids in a row are distinct', () {
    final generator = UuidV7Generator();

    final ids = {for (var i = 0; i < 10000; i++) generator.newId()};

    expect(ids, hasLength(10000));
  });

  test('RNF-04: idGeneratorProvider defaults to UuidV7Generator', () {
    final container = ProviderContainer.test();

    expect(container.read(idGeneratorProvider), isA<UuidV7Generator>());
  });

  test('ID-04: only id_generator.dart references Uuid', () {
    final offenders = [
      for (final (file, source) in libSources(
        exclude: {'lib/core/ids/id_generator.dart'},
      ))
        if (RegExp(r'\bUuid\b').hasMatch(source)) file.path,
    ];

    expect(offenders, isEmpty);
  });
}
