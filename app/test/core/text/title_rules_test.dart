import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/text/title_rules.dart';

void main() {
  final fiftyClusters = '👍🏽' * 50;
  final fiftyOneClusters = '👍🏽' * 51;

  final functions = <String, String Function(String)>{
    'notebookTitle': notebookTitle,
    'pageTitle': pageTitle,
  };

  for (final MapEntry(key: name, value: fn) in functions.entries) {
    group(name, () {
      test('TITLE-01: removes surrounding spaces, tabs and newlines', () {
        expect(fn(' \t\n Ideas \n\t '), 'Ideas');
      });

      test('TITLE-05: exactly 50 clusters are accepted', () {
        expect(fiftyClusters.length, greaterThan(50));
        expect(fn(fiftyClusters), fiftyClusters);
      });

      test('TITLE-03: 51 clusters are rejected', () {
        expect(() => fn(fiftyOneClusters), throwsArgumentError);
      });

      test(
        'TITLE-05: 50 clusters plus surrounding whitespace are accepted',
        () {
          expect(fn('  $fiftyClusters \n'), fiftyClusters);
        },
      );
    });
  }

  test('TITLE-02: notebook title that is empty is rejected', () {
    expect(() => notebookTitle(''), throwsArgumentError);
  });

  test('TITLE-02: notebook title with only whitespace is rejected', () {
    expect(() => notebookTitle(' \t\n '), throwsArgumentError);
  });

  test('TITLE-04: page title that is empty returns an empty string', () {
    expect(pageTitle(''), '');
  });

  test('TITLE-04: page title with only whitespace returns an empty string', () {
    expect(pageTitle(' \t\n '), '');
  });

  test('TITLE-03: maxTitleLength is 50', () {
    expect(maxTitleLength, 50);
  });
}
