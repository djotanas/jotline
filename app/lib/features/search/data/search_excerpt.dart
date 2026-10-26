import 'package:flutter/foundation.dart';

const _markStart = '';
const _markEnd = '';
const _blockSeparator = ' ';
const _contextBeforeMatch = 40;
const _cutMark = '…';

/// A run of text that is either plain or highlighted as a search match.
@immutable
final class HighlightSpan {
  const new(this.text, {required this.marked});

  /// Splits text from SQLite `highlight()` into plain and marked spans.
  static List<HighlightSpan> parse(String highlighted) {
    final spans = <HighlightSpan>[];
    final buffer = StringBuffer();
    var marked = false;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(HighlightSpan(buffer.toString(), marked: marked));
      buffer.clear();
    }

    for (final rune in highlighted.runes) {
      final char = String.fromCharCode(rune);
      if (char == _markStart || char == _markEnd) {
        flush();
        marked = char == _markStart;
      } else {
        buffer.write(char);
      }
    }
    flush();
    return spans;
  }

  final String text;
  final bool marked;

  @override
  bool operator ==(Object other) =>
      other is HighlightSpan && other.text == text && other.marked == marked;

  @override
  int get hashCode => Object.hash(text, marked);

  @override
  String toString() => 'HighlightSpan(${marked ? '*' : ''}$text)';
}

/// The part of the first matching block shown under a result.
@immutable
final class SearchExcerpt {
  const new(this.spans);

  factory _cut(List<HighlightSpan> spans) {
    final text = spans.map((span) => span.text).join();
    final firstMark = spans
        .takeWhile((span) => !span.marked)
        .fold(0, (length, span) => length + span.text.length);

    var start = firstMark > _contextBeforeMatch
        ? firstMark - _contextBeforeMatch
        : 0;
    while (start > 0 && start < firstMark && text[start - 1] != ' ') {
      start++;
    }

    final cut = <HighlightSpan>[];
    var offset = 0;
    for (final span in spans) {
      final end = offset + span.text.length;
      if (end > start) {
        final from = start > offset ? start - offset : 0;
        cut.add(HighlightSpan(span.text.substring(from), marked: span.marked));
      }
      offset = end;
    }
    if (start > 0) {
      cut.first = HighlightSpan('$_cutMark${cut.first.text}', marked: false);
    }
    return SearchExcerpt(List.unmodifiable(cut));
  }

  /// Cuts the excerpt from the highlighted body, whose blocks are joined by
  /// U+2029. Returns `null` when no block has a match.
  static SearchExcerpt? from(String highlightedBody) {
    for (final block in highlightedBody.split(_blockSeparator)) {
      if (!block.contains(_markStart)) continue;
      return SearchExcerpt._cut(HighlightSpan.parse(block));
    }
    return null;
  }

  final List<HighlightSpan> spans;

  String get text => spans.map((span) => span.text).join();
}
