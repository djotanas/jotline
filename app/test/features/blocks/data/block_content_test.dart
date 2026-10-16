import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/features/blocks/data/block_content.dart';

void main() {
  group('BlockContent JSON', () {
    test('SAVE-10: writes exactly text, marks and checked, in that shape', () {
      const content = BlockContent(
        'Belém cedo',
        marks: [Mark(0, 5, MarkType.bold)],
        checked: false,
      );

      expect(
        content.toJson(),
        jsonEncode({
          'text': 'Belém cedo',
          'marks': [
            {'start': 0, 'end': 5, 'type': 'bold'},
          ],
          'checked': false,
        }),
      );
    });

    test('SAVE-10: round trip keeps overlapping bold and italic, accents and '
        'a flag emoji', () {
      const content = BlockContent(
        'Ação 🇧🇷 já',
        marks: [Mark(0, 4, MarkType.bold), Mark(2, 9, MarkType.italic)],
      );

      final read = BlockContent.fromJson(content.toJson());

      expect(read.text, 'Ação 🇧🇷 já');
      expect(read.marks, const [
        Mark(0, 4, MarkType.bold),
        Mark(2, 9, MarkType.italic),
      ]);
      expect(read.checked, isNull);
      expect(read, content);
    });

    test('SAVE-10: empty text round trips with no marks', () {
      const content = BlockContent('');

      expect(content.toJson(), '{"text":"","marks":[]}');
      expect(BlockContent.fromJson(content.toJson()), content);
    });

    test('EDGE-07: leading and trailing spaces are stored as typed', () {
      const content = BlockContent('  Belém  ');

      final json = jsonDecode(content.toJson()) as Map<String, Object?>;

      expect(json['text'], '  Belém  ');
      expect(BlockContent.fromJson(content.toJson()).text, '  Belém  ');
    });

    test('SAVE-10: checked is written only when non-null', () {
      final withChecked = jsonDecode(
        const BlockContent('a', checked: true).toJson(),
      ) as Map<String, Object?>;
      final none =
          jsonDecode(const BlockContent('a').toJson()) as Map<String, Object?>;

      expect(withChecked['checked'], isTrue);
      expect(none.containsKey('checked'), isFalse);
    });

    test('SAVE-10: an unknown mark type is ignored on read', () {
      final read = BlockContent.fromJson(
        '{"text":"abc","marks":[{"start":0,"end":2,"type":"underline"},'
        '{"start":1,"end":3,"type":"italic"}]}',
      );

      expect(read.marks, const [Mark(1, 3, MarkType.italic)]);
    });

    test('SAVE-10: content_json that does not parse reads as empty text', () {
      final read = BlockContent.fromJson('not json');

      expect(read, const BlockContent(''));
    });
  });

  group('mark normalization', () {
    test('SAVE-10: unsorted marks are written sorted by start', () {
      const content = BlockContent(
        'abcdefgh',
        marks: [Mark(5, 7, MarkType.bold), Mark(0, 2, MarkType.bold)],
      );

      expect(BlockContent.fromJson(content.toJson()).marks, const [
        Mark(0, 2, MarkType.bold),
        Mark(5, 7, MarkType.bold),
      ]);
    });

    test('SAVE-10: overlapping ranges of the same type merge', () {
      expect(
        normalizeMarks(const [
          Mark(0, 4, MarkType.bold),
          Mark(2, 6, MarkType.bold),
          Mark(3, 5, MarkType.bold),
        ]),
        const [Mark(0, 6, MarkType.bold)],
      );
    });

    test('SAVE-10: adjacent ranges of the same type merge', () {
      expect(
        normalizeMarks(const [
          Mark(3, 6, MarkType.italic),
          Mark(0, 3, MarkType.italic),
        ]),
        const [Mark(0, 6, MarkType.italic)],
      );
    });

    test('SAVE-10: ranges of different types do not merge', () {
      expect(
        normalizeMarks(const [
          Mark(0, 3, MarkType.italic),
          Mark(0, 3, MarkType.bold),
        ]),
        const [Mark(0, 3, MarkType.bold), Mark(0, 3, MarkType.italic)],
      );
    });

    test('SAVE-10: empty ranges are dropped', () {
      const content = BlockContent(
        'abc',
        marks: [Mark(1, 1, MarkType.bold), Mark(2, 1, MarkType.italic)],
      );

      expect(content.toJson(), '{"text":"abc","marks":[]}');
    });

    test('SAVE-10: marks read from JSON are normalized', () {
      final read = BlockContent.fromJson(
        '{"text":"abcdef","marks":[{"start":2,"end":4,"type":"bold"},'
        '{"start":0,"end":2,"type":"bold"},{"start":5,"end":5,"type":"bold"}]}',
      );

      expect(read.marks, const [Mark(0, 4, MarkType.bold)]);
    });
  });

  group('BlockContent.forType', () {
    test('BAR-06: drops checked off a checklist item', () {
      const content = BlockContent(
        'a',
        marks: [Mark(0, 1, MarkType.bold)],
        checked: true,
      );

      for (final type in [
        BlockType.text,
        BlockType.heading,
        BlockType.bulletedListItem,
      ]) {
        expect(
          content.forType(type),
          const BlockContent('a', marks: [Mark(0, 1, MarkType.bold)]),
        );
      }
    });

    test('BAR-06: defaults checked to false on a checklist item', () {
      expect(
        const BlockContent('a').forType(BlockType.checklistItem).checked,
        isFalse,
      );
      expect(
        const BlockContent(
          'a',
          checked: true,
        ).forType(BlockType.checklistItem).checked,
        isTrue,
      );
    });
  });

  group('BlockType', () {
    test('SAVE-10: the four persisted ids', () {
      expect(BlockType.values.map((type) => type.id), [
        'text',
        'heading',
        'bulleted_list_item',
        'checklist_item',
      ]);
      for (final type in BlockType.values) {
        expect(BlockType.fromId(type.id), type);
      }
    });

    test('SAVE-10: an unknown type id reads as text', () {
      expect(BlockType.fromId('drawing'), BlockType.text);
    });
  });
}
