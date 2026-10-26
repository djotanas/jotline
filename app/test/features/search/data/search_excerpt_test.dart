import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/features/search/data/search_excerpt.dart';

const _open = '';
const _close = '';
const _blockSeparator = ' ';

String _mark(String word) => '$_open$word$_close';

String _filler(int length) => 'a' * length;

void main() {
  group('title spans', () {
    test('SRCH-14: marked words become marked spans between plain ones', () {
      expect(HighlightSpan.parse('Onde comer em ${_mark('Belém')} cedo'), [
        const HighlightSpan('Onde comer em ', marked: false),
        const HighlightSpan('Belém', marked: true),
        const HighlightSpan(' cedo', marked: false),
      ]);
    });

    test('SRCH-14: every matched word is marked', () {
      expect(HighlightSpan.parse('${_mark('Belém')} e ${_mark('Santarém')}'), [
        const HighlightSpan('Belém', marked: true),
        const HighlightSpan(' e ', marked: false),
        const HighlightSpan('Santarém', marked: true),
      ]);
    });

    test('SRCH-14: a title with no marker is one plain span', () {
      expect(HighlightSpan.parse('Sem marca'), [
        const HighlightSpan('Sem marca', marked: false),
      ]);
    });

    test('SRCH-14: an empty title has no spans', () {
      expect(HighlightSpan.parse(''), isEmpty);
    });
  });

  group('excerpt', () {
    test('SRCH-13: no marker in the body gives no excerpt', () {
      expect(SearchExcerpt.from('um texto outro texto'), isNull);
    });

    test('SRCH-13: an empty body gives no excerpt', () {
      expect(SearchExcerpt.from(''), isNull);
    });

    test('SRCH-13: a match at the start of a block has no ellipsis', () {
      final excerpt = SearchExcerpt.from('${_mark('Belém')} cedo e quente')!;

      expect(excerpt.text, 'Belém cedo e quente');
      expect(excerpt.spans.first, const HighlightSpan('Belém', marked: true));
    });

    test('SRCH-13: a match in the middle of a short block has no ellipsis', () {
      final excerpt = SearchExcerpt.from('chegar em ${_mark('Belém')} cedo')!;

      expect(excerpt.text, 'chegar em Belém cedo');
    });

    test('EDGE-04: a match at the end of a short block has no ellipsis', () {
      final excerpt = SearchExcerpt.from('chegar em ${_mark('Belém')}')!;

      expect(excerpt.text, 'chegar em Belém');
    });

    test(
      'SRCH-13: a match exactly 40 characters in does not cut the start',
      () {
        final before = '${_filler(39)} ';
        final excerpt = SearchExcerpt.from('$before${_mark('Belém')} fim')!;

        expect(excerpt.text, '${_filler(39)} Belém fim');
      },
    );

    test(
      'SRCH-13: a match 41 characters in cuts the start with an ellipsis',
      () {
        final before = 'x ${_filler(38)} ';
        expect(before.length, 41);
        final excerpt = SearchExcerpt.from('$before${_mark('Belém')} fim')!;

        expect(excerpt.text, '…${_filler(38)} Belém fim');
      },
    );

    test('SRCH-13: the cut falls on a word boundary, not inside a word', () {
      final before = '${_filler(10)}${'b' * 40} ';
      final excerpt = SearchExcerpt.from('$before${_mark('Belém')} fim')!;

      expect(excerpt.text, '…Belém fim');
    });

    test('SRCH-13: a long block with the match at the end has no trailing '
        'ellipsis', () {
      final before = '${List.filled(30, 'palavra').join(' ')} ';
      final excerpt = SearchExcerpt.from('$before${_mark('Belém')}')!;

      expect(excerpt.text.startsWith('…'), isTrue);
      expect(excerpt.text.endsWith('Belém'), isTrue);
      expect(excerpt.text.endsWith('…'), isFalse);
    });

    test('SRCH-13: the window keeps the text after the match up to the end of '
        'the block', () {
      final after = ' ${List.filled(60, 'depois').join(' ')}';
      final excerpt = SearchExcerpt.from('${_mark('Belém')}$after')!;

      expect(excerpt.text, 'Belém$after');
    });

    test('SRCH-14: every matched word of the excerpt is marked', () {
      final excerpt = SearchExcerpt.from(
        '${_mark('Belém')} e ${_mark('Santarém')} juntas',
      )!;

      expect(excerpt.spans, [
        const HighlightSpan('Belém', marked: true),
        const HighlightSpan(' e ', marked: false),
        const HighlightSpan('Santarém', marked: true),
        const HighlightSpan(' juntas', marked: false),
      ]);
    });

    test('SRCH-13: a match only in the second block uses the second block', () {
      final excerpt = SearchExcerpt.from(
        'primeiro bloco$_blockSeparator'
        'segundo ${_mark('Belém')}',
      )!;

      expect(excerpt.text, 'segundo Belém');
    });

    test('SRCH-13: with matches in two blocks the first block is used', () {
      final excerpt = SearchExcerpt.from(
        '${_mark('Belém')} um$_blockSeparator'
        '${_mark('Belém')} dois',
      )!;

      expect(excerpt.text, 'Belém um');
    });

    test('EDGE-03: the excerpt is plain text with only the highlight', () {
      final excerpt = SearchExcerpt.from('veja ${_mark('Belém')} hoje')!;

      expect(excerpt.spans.map((span) => span.marked), [false, true, false]);
      expect(excerpt.spans.map((span) => span.text).join(), 'veja Belém hoje');
    });
  });
}
