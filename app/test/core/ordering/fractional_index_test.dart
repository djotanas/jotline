import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/ordering/fractional_index.dart';

int _byteCompare(String a, String b) {
  final x = utf8.encode(a);
  final y = utf8.encode(b);
  for (var i = 0; i < x.length && i < y.length; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return x.length.compareTo(y.length);
}

void _expectSameOrder(String a, String b) {
  expect(a.compareTo(b).sign, _byteCompare(a, b).sign, reason: '$a vs $b');
}

void main() {
  group('POS-02: no neighbors', () {
    test('POS-02: returns a non-empty key', () {
      expect(FractionalIndex.keyBetween(null, null), isNotEmpty);
    });

    test('POS-02: rocicorp vector (null, null) -> a0', () {
      expect(FractionalIndex.keyBetween(null, null), 'a0');
    });
  });

  group('POS-03: after a key', () {
    test('POS-03: new key is greater than a', () {
      final key = FractionalIndex.keyBetween('a0', null);

      expect(key.compareTo('a0'), greaterThan(0));
    });

    test('POS-03: rocicorp vector (a0, null) -> a1', () {
      expect(FractionalIndex.keyBetween('a0', null), 'a1');
    });
  });

  group('POS-04: before a key', () {
    test('POS-04: new key is less than b', () {
      final key = FractionalIndex.keyBetween(null, 'a0');

      expect(key.compareTo('a0'), lessThan(0));
    });

    test('POS-04: rocicorp vector (null, a0) -> Zz', () {
      expect(FractionalIndex.keyBetween(null, 'a0'), 'Zz');
    });
  });

  group('POS-05: between two keys', () {
    test('POS-05: a < key < b', () {
      final key = FractionalIndex.keyBetween('a1', 'a2');

      expect(key.compareTo('a1'), greaterThan(0));
      expect(key.compareTo('a2'), lessThan(0));
    });

    test('POS-05: rocicorp vector (a1, a2) -> a1V', () {
      expect(FractionalIndex.keyBetween('a1', 'a2'), 'a1V');
    });

    test('POS-05: rocicorp vectors across integer and fraction parts', () {
      expect(FractionalIndex.keyBetween('a0', 'a1'), 'a0V');
      expect(FractionalIndex.keyBetween('a0V', 'a1'), 'a0l');
      expect(FractionalIndex.keyBetween('Zz', 'a0'), 'ZzV');
      expect(FractionalIndex.keyBetween('Zz', 'a1'), 'a0');
      expect(FractionalIndex.keyBetween('a0', 'a0V'), 'a0G');
      expect(FractionalIndex.keyBetween('a0', 'a0G'), 'a08');
      expect(FractionalIndex.keyBetween('bzz', null), 'c000');
    });

    test('POS-05: keys between neighbors with a long common prefix', () {
      final key = FractionalIndex.keyBetween('a0V', 'a0W');

      expect(key.compareTo('a0V'), greaterThan(0));
      expect(key.compareTo('a0W'), lessThan(0));
    });
  });

  test('POS-06: 1,000 keys inserted before the previous one stay ordered', () {
    final first = FractionalIndex.keyBetween(null, null);
    final keys = <String>[];
    var right = FractionalIndex.keyBetween(first, null);
    for (var i = 0; i < 1000; i++) {
      final key = FractionalIndex.keyBetween(first, right);
      keys.add(key);
      right = key;
    }

    expect(keys.toSet(), hasLength(1000));
    final sorted = [...keys]..sort();
    expect(sorted, keys.reversed.toList());
  });

  test('POS-07: 1,000 keys appended in a row stay ordered', () {
    final keys = <String>[];
    String? last;
    for (var i = 0; i < 1000; i++) {
      last = FractionalIndex.keyBetween(last, null);
      keys.add(last);
    }

    expect(keys.toSet(), hasLength(1000));
    final sorted = [...keys]..sort();
    expect(sorted, keys);
  });

  group('POS-08: invalid input', () {
    test('POS-08: a > b throws ArgumentError', () {
      expect(() => FractionalIndex.keyBetween('a2', 'a1'), throwsArgumentError);
    });

    test('POS-08: a == b throws ArgumentError', () {
      expect(() => FractionalIndex.keyBetween('a1', 'a1'), throwsArgumentError);
    });

    test('POS-08: malformed keys throw ArgumentError', () {
      expect(() => FractionalIndex.keyBetween('', null), throwsArgumentError);
      expect(
        () => FractionalIndex.keyBetween('a10', null),
        throwsArgumentError,
      );
      expect(() => FractionalIndex.keyBetween('!1', null), throwsArgumentError);
      expect(() => FractionalIndex.keyBetween('a', null), throwsArgumentError);
      expect(
        () => FractionalIndex.keyBetween(null, 'a0_'),
        throwsArgumentError,
      );
    });
  });

  test('POS-01: generated keys compare the same as strings and as bytes', () {
    final keys = <String>[];
    String? last;
    for (var i = 0; i < 300; i++) {
      last = FractionalIndex.keyBetween(last, null);
      keys.add(last);
    }
    String? first;
    for (var i = 0; i < 300; i++) {
      first = FractionalIndex.keyBetween(null, first ?? keys.first);
      keys.add(first);
    }
    keys.sort();
    for (var i = 0; i < 300; i++) {
      keys.add(FractionalIndex.keyBetween(keys[i], keys[i + 1]));
    }

    for (final a in keys) {
      for (final b in keys) {
        _expectSameOrder(a, b);
      }
    }
  });
}
