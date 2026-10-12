const _digits =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const _heads = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
final _smallestInteger = 'A${'0' * 26}';

/// Text keys that sort between two other keys, compared byte-wise.
///
/// Port of rocicorp/fractional-indexing (CC0-1.0) with base-62 digits.
abstract final class FractionalIndex {
  /// Returns a key `k` with `a < k < b`. A null bound means the list edge.
  ///
  /// Throws [ArgumentError] when `a >= b` or when a key is malformed.
  static String keyBetween(String? a, String? b) {
    if (a != null) _validateKey(a);
    if (b != null) _validateKey(b);
    if (a != null && b != null && a.compareTo(b) >= 0) {
      throw ArgumentError('$a >= $b');
    }

    if (a == null) {
      if (b == null) return 'a0';
      final ib = _integerPart(b);
      final fb = b.substring(ib.length);
      if (ib == _smallestInteger) return ib + _midpoint('', fb);
      if (ib.compareTo(b) < 0) return ib;
      final res = _decrementInteger(ib);
      if (res == null) throw ArgumentError('cannot decrement any more');
      return res;
    }

    if (b == null) {
      final ia = _integerPart(a);
      final fa = a.substring(ia.length);
      final next = _incrementInteger(ia);
      return next ?? ia + _midpoint(fa, null);
    }

    final ia = _integerPart(a);
    final fa = a.substring(ia.length);
    final ib = _integerPart(b);
    final fb = b.substring(ib.length);
    if (ia == ib) return ia + _midpoint(fa, fb);
    final next = _incrementInteger(ia);
    if (next == null) throw ArgumentError('cannot increment any more');
    if (next.compareTo(b) < 0) return next;
    return ia + _midpoint(fa, null);
  }

  static String _midpoint(String a, String? b) {
    if (b != null) {
      var n = 0;
      while ((n < a.length ? a[n] : '0') == (n < b.length ? b[n] : '')) {
        n++;
      }
      if (n > 0) {
        return b.substring(0, n) +
            _midpoint(n < a.length ? a.substring(n) : '', b.substring(n));
      }
    }
    final digitA = a.isEmpty ? 0 : _digits.indexOf(a[0]);
    final digitB = b == null || b.isEmpty
        ? _digits.length
        : _digits.indexOf(b[0]);
    if (digitB - digitA > 1) {
      final mid = (0.5 * (digitA + digitB)).round();
      return _digits[mid];
    }
    if (b != null && b.length > 1) return b.substring(0, 1);
    return _digits[digitA] + _midpoint(a.isEmpty ? '' : a.substring(1), null);
  }

  static int _integerLength(String head) {
    final index = _heads.indexOf(head);
    if (index < 0) throw ArgumentError('invalid order key head: $head');
    return index < 26 ? 27 - index : index - 24;
  }

  static String _integerPart(String key) {
    final length = _integerLength(key[0]);
    if (length > key.length) throw ArgumentError('invalid order key: $key');
    return key.substring(0, length);
  }

  static void _validateKey(String key) {
    if (key.isEmpty || key == _smallestInteger) {
      throw ArgumentError('invalid order key: $key');
    }
    final integer = _integerPart(key);
    final fraction = key.substring(integer.length);
    if (fraction.endsWith('0')) {
      throw ArgumentError('invalid order key: $key');
    }
    for (var i = 1; i < key.length; i++) {
      if (!_digits.contains(key[i])) {
        throw ArgumentError('invalid order key: $key');
      }
    }
  }

  static String? _incrementInteger(String x) {
    final head = x[0];
    final digits = x.substring(1).split('');
    var carry = true;
    for (var i = digits.length - 1; i >= 0 && carry; i--) {
      final d = _digits.indexOf(digits[i]) + 1;
      if (d == _digits.length) {
        digits[i] = '0';
      } else {
        digits[i] = _digits[d];
        carry = false;
      }
    }
    if (carry) {
      if (head == 'z') return null;
      final h = _heads[_heads.indexOf(head) + 1];
      if (head != 'Z') {
        if (head.compareTo('Z') < 0) {
          digits.removeLast();
        } else {
          digits.add('0');
        }
      }
      return h + digits.join();
    }
    return head + digits.join();
  }

  static String? _decrementInteger(String x) {
    final head = x[0];
    final digits = x.substring(1).split('');
    var borrow = true;
    for (var i = digits.length - 1; i >= 0 && borrow; i--) {
      final d = _digits.indexOf(digits[i]) - 1;
      if (d == -1) {
        digits[i] = _digits[_digits.length - 1];
      } else {
        digits[i] = _digits[d];
        borrow = false;
      }
    }
    if (borrow) {
      if (head == 'A') return null;
      final h = _heads[_heads.indexOf(head) - 1];
      if (head != 'a') {
        if (head.compareTo('Z') <= 0) {
          digits.add('z');
        } else {
          digits.removeLast();
        }
      }
      return h + digits.join();
    }
    return head + digits.join();
  }
}
