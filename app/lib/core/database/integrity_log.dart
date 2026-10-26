import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

/// One invariant that failed and the ids of the rows involved.
@immutable
final class IntegrityFailure {
  const new(this.invariant, this.ids);

  final String invariant;
  final List<String> ids;
}

/// The outcome of one integrity check.
@immutable
final class IntegrityReport {
  const new(this.failures);

  final List<IntegrityFailure> failures;

  bool get passed => failures.isEmpty;
}

/// Appends one line per integrity check to a local file (INTEG-06).
class IntegrityLog {
  const new(this._file);

  final Future<File> Function() _file;

  /// Writes `<UTC date> <appVersion> pass` or `... fail <invariant>=<ids>...`.
  /// The file is created when missing; an error is logged, never thrown.
  Future<void> append(
    IntegrityReport report, {
    required String appVersion,
    required DateTime at,
  }) async {
    try {
      final date = '${at.toUtc().toIso8601String().split('.').first}Z';
      final failures = [
        for (final f in report.failures) '${f.invariant}=${f.ids.join(',')}',
      ];
      final outcome = report.passed ? 'pass' : 'fail ${failures.join(' ')}';
      final file = await _file();
      await file.writeAsString(
        '$date $appVersion $outcome\n',
        mode: FileMode.append,
      );
    } on Object catch (error) {
      developer.log(
        'integrity log not written',
        name: 'jotline.integrity',
        error: error,
      );
    }
  }
}
