import 'package:flutter/foundation.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/search/data/search_excerpt.dart';

/// A page found by the search, with what its result row needs before the
/// highlights are loaded.
@immutable
final class SearchHit {
  const new({
    required this.pageId,
    required this.title,
    required this.notebookTitle,
    required this.notebookColor,
    required this.lastEditedAt,
  });

  final String pageId;
  final String title;
  final String notebookTitle;
  final NotebookColor notebookColor;
  final DateTime lastEditedAt;
}

/// The highlighted title and excerpt of one hit.
@immutable
final class SearchSnippet {
  const new({required this.title, required this.excerpt});

  final List<HighlightSpan> title;

  /// `null` when no block of the page matched.
  final SearchExcerpt? excerpt;
}
