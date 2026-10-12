import 'package:characters/characters.dart';

const maxTitleLength = 50;

/// Trims a notebook title; it must be non-empty and at most
/// [maxTitleLength] grapheme clusters.
String notebookTitle(String raw) {
  final title = raw.trim();
  if (title.isEmpty) {
    throw ArgumentError.value(raw, 'raw', 'must not be empty');
  }
  _checkLength(raw, title);
  return title;
}

/// Trims a page title; it may be empty but at most [maxTitleLength]
/// grapheme clusters.
String pageTitle(String raw) {
  final title = raw.trim();
  _checkLength(raw, title);
  return title;
}

void _checkLength(String raw, String title) {
  if (title.characters.length > maxTitleLength) {
    throw ArgumentError.value(
      raw,
      'raw',
      'must have at most $maxTitleLength characters',
    );
  }
}
