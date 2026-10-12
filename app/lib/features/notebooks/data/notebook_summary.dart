import 'package:jotline/core/database/app_database.dart';

/// What the notebook list, header and options sheet need about a notebook.
final class NotebookSummary {
  const new({
    required this.notebook,
    required this.pageCount,
    required this.lastEditedAt,
    this.archivedAt,
  });

  final Notebook notebook;

  /// Pages not in the trash.
  final int pageCount;

  /// Latest `updated_at` of the pages not in the trash, else `created_at`.
  final DateTime lastEditedAt;

  /// The local user's `archived_at` on the notebook membership.
  final DateTime? archivedAt;
}

enum NotebookSort { lastEdited, name, createdAt }

const _foldedLetters = {
  'a': 'àáâãäå',
  'c': 'ç',
  'e': 'èéêë',
  'i': 'ìíîï',
  'n': 'ñ',
  'o': 'òóôõö',
  'u': 'ùúûü',
  'y': 'ýÿ',
};

final Map<String, String> _foldMap = {
  for (final entry in _foldedLetters.entries)
    for (final letter in entry.value.split('')) letter: entry.key,
};

/// Lowercases [value] and strips Latin diacritics for name ordering.
String foldForSort(String value) {
  final buffer = StringBuffer();
  for (final letter in value.toLowerCase().split('')) {
    buffer.write(_foldMap[letter] ?? letter);
  }
  return buffer.toString();
}

/// Orders [summaries] by [sort], breaking ties by `id`.
List<NotebookSummary> sortNotebooks(
  Iterable<NotebookSummary> summaries,
  NotebookSort sort,
) {
  int Function(NotebookSummary, NotebookSummary) compare;
  switch (sort) {
    case NotebookSort.lastEdited:
      compare = (a, b) {
        final byDate = b.lastEditedAt.compareTo(a.lastEditedAt);
        return byDate != 0 ? byDate : b.notebook.id.compareTo(a.notebook.id);
      };
    case NotebookSort.name:
      compare = (a, b) {
        final byName = foldForSort(a.notebook.title)
            .compareTo(foldForSort(b.notebook.title));
        return byName != 0 ? byName : a.notebook.id.compareTo(b.notebook.id);
      };
    case NotebookSort.createdAt:
      compare = (a, b) {
        final byDate = b.notebook.createdAt.compareTo(a.notebook.createdAt);
        return byDate != 0 ? byDate : b.notebook.id.compareTo(a.notebook.id);
      };
  }
  return summaries.toList()..sort(compare);
}
