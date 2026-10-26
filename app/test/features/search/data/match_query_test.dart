import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/features/search/data/match_query.dart';

void main() {
  String all(String term) => MatchQuery.parse(term).expression(SearchScope.all);

  test('SRCH-04: one word becomes a quoted word prefix', () {
    expect(all('bele'), '"bele"*');
  });

  test('SRCH-04: accents are kept in the expression for the tokenizer to '
      'fold', () {
    expect(MatchQuery.parse('Belém').words, ['Belém']);
    expect(all('Belém'), '"Belém"*');
  });

  test('SRCH-04: case is kept in the expression for the tokenizer to fold', () {
    expect(all('BELEM'), '"BELEM"*');
  });

  test('SRCH-05: several words are joined with AND', () {
    expect(all('tacacá almoço'), '"tacacá"* AND "almoço"*');
  });

  test('SRCH-05: extra spaces between words do not create empty words', () {
    expect(MatchQuery.parse('  a   b  ').words, ['a', 'b']);
    expect(all('  a   b  '), '"a"* AND "b"*');
  });

  test('SRCH-06: the titles scope restricts the expression to the title '
      'column', () {
    expect(
      MatchQuery.parse('bele').expression(SearchScope.titles),
      '{title} : ("bele"*)',
    );
  });

  test('SRCH-07: the content scope restricts the expression to the body '
      'column', () {
    expect(
      MatchQuery.parse('bele').expression(SearchScope.content),
      '{body} : ("bele"*)',
    );
  });

  test('SRCH-08: the all scope has no column filter', () {
    expect(MatchQuery.parse('bele').expression(SearchScope.all), '"bele"*');
  });

  test('SRCH-05: a scope with several words filters the whole conjunction', () {
    expect(
      MatchQuery.parse('a b').expression(SearchScope.titles),
      '{title} : ("a"* AND "b"*)',
    );
    expect(
      MatchQuery.parse('a b').expression(SearchScope.content),
      '{body} : ("a"* AND "b"*)',
    );
  });

  test('EDGE-01: punctuation between words splits them', () {
    expect(MatchQuery.parse('belém,cedo.hoje!').words, [
      'belém',
      'cedo',
      'hoje',
    ]);
  });

  test('EDGE-01: a term with only punctuation is empty', () {
    final query = MatchQuery.parse('?!...,;');

    expect(query.isEmpty, isTrue);
    expect(query.words, isEmpty);
  });

  test('EDGE-01: a term with only spaces is empty', () {
    expect(MatchQuery.parse('    ').isEmpty, isTrue);
    expect(MatchQuery.parse('').isEmpty, isTrue);
  });

  test('EDGE-01: a term with words is not empty', () {
    expect(MatchQuery.parse(' a ').isEmpty, isFalse);
  });

  test('EDGE-02: a double quote is plain text and never reaches the '
      'expression', () {
    expect(MatchQuery.parse('"bele"').words, ['bele']);
    expect(all('"bele'), '"bele"*');
  });

  test('EDGE-02: an asterisk is plain text', () {
    expect(all('bele*'), '"bele"*');
    expect(MatchQuery.parse('*').isEmpty, isTrue);
  });

  test('EDGE-02: a minus sign is plain text', () {
    expect(all('-bele'), '"bele"*');
    expect(all('a-b'), '"a"* AND "b"*');
  });

  test('EDGE-02: OR is a plain word, not an operator', () {
    expect(all('a OR b'), '"a"* AND "OR"* AND "b"*');
  });

  test('EDGE-02: NEAR is a plain word, not an operator', () {
    expect(all('NEAR(a b)'), '"NEAR"* AND "a"* AND "b"*');
  });

  test('EDGE-02: AND and NOT typed by the user are plain words', () {
    expect(all('a NOT b'), '"a"* AND "NOT"* AND "b"*');
  });

  test('EDGE-01: an emoji is dropped like punctuation', () {
    expect(MatchQuery.parse('🙂').isEmpty, isTrue);
    expect(all('café ☕ hoje'), '"café"* AND "hoje"*');
  });

  test('SRCH-04: digits are word characters', () {
    expect(all('2026 q3'), '"2026"* AND "q3"*');
  });

  test('SRCH-03: queries from the same words are equal and share a hash', () {
    final first = MatchQuery.parse('Belém  cedo');
    final second = MatchQuery.parse('Belém, cedo!');

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('SRCH-03: queries from different words are not equal', () {
    expect(MatchQuery.parse('belém'), isNot(MatchQuery.parse('bele')));
    expect(MatchQuery.parse('a b'), isNot(MatchQuery.parse('b a')));
  });
}
