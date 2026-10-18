import 'package:jotline/core/database/app_database.dart';

/// A page with what its row in the list shows.
final class PageSummary {
  const new({
    required this.page,
    required this.lastEditedAt,
    required this.excerpt,
  });

  final NotebookPage page;

  /// The latest of the page's `updated_at` and the `updated_at` and
  /// `deleted_at` of all its blocks, deleted ones included (EDITED-01).
  final DateTime lastEditedAt;

  /// The trimmed text of the first block not deleted, of type text, list item
  /// or checklist item, whose trimmed text is not empty; `null` with none
  /// (EXCERPT-01, EXCERPT-03).
  final String? excerpt;
}
