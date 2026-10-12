import 'dart:io';

Iterable<(File, String)> libSources({Set<String> exclude = const {}}) sync* {
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final path = file.path.replaceAll(r'\', '/');
    final name = path.split('/').last;
    if (name.endsWith('.g.dart') || name.endsWith('.steps.dart')) continue;
    if (path.startsWith('lib/l10n/app_localizations')) continue;
    if (exclude.contains(path)) continue;
    yield (file, file.readAsStringSync());
  }
}
