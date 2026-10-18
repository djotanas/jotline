/// Which fields of a page the search looks at.
enum SearchScope { all, titles, content }

/// The typed term, turned into words that are safe to put in an FTS5 `MATCH`.
final class MatchQuery {
  const new(this.words);

  /// Splits [term] on every character that is not a letter or a digit.
  factory parse(String term) => MatchQuery(
    List<String>.unmodifiable(
      _wordPattern.allMatches(term).map((match) => match.group(0)!),
    ),
  );

  static final _wordPattern = RegExp(r'[\p{L}\p{N}]+', unicode: true);

  final List<String> words;

  bool get isEmpty => words.isEmpty;

  /// The `MATCH` expression: every word is a quoted prefix and all must match
  /// within [scope]'s columns.
  String expression(SearchScope scope) {
    final body = words
        .map((word) => '"${word.replaceAll('"', '""')}"*')
        .join(' AND ');
    return switch (scope) {
      SearchScope.all => body,
      SearchScope.titles => '{title} : ($body)',
      SearchScope.content => '{body} : ($body)',
    };
  }
}
