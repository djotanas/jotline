import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/integrity_log.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// The startup check of the local database (INTEG-01 to INTEG-08).
class IntegrityCheck {
  const new(this._database, this._clock, this._log, this._appVersion);

  final AppDatabase _database;
  final Clock _clock;
  final IntegrityLog _log;
  final String _appVersion;

  static const _invariants = {
    'notebook_without_owner':
        'SELECT n.id AS id FROM notebooks n WHERE n.deleted_at IS NULL '
        'AND NOT EXISTS (SELECT 1 FROM notebook_members m '
        "WHERE m.notebook_id = n.id AND m.role = 'owner')",
    'orphan_page':
        'SELECT p.id AS id FROM pages p WHERE NOT EXISTS '
        '(SELECT 1 FROM notebooks n WHERE n.id = p.notebook_id)',
    'orphan_block':
        'SELECT b.id AS id FROM blocks b WHERE NOT EXISTS '
        '(SELECT 1 FROM pages p WHERE p.id = b.page_id)',
    'duplicate_position':
        'SELECT x.id AS id FROM pages x WHERE x.deleted_at IS NULL '
        'AND (SELECT count(*) FROM pages y WHERE y.deleted_at IS NULL '
        'AND y.notebook_id = x.notebook_id '
        'AND y.position = x.position) > 1 '
        'UNION ALL '
        'SELECT x.id AS id FROM blocks x WHERE x.deleted_at IS NULL '
        'AND (SELECT count(*) FROM blocks y WHERE y.deleted_at IS NULL '
        'AND y.page_id = x.page_id '
        'AND y.position = x.position) > 1',
  };

  /// Runs `PRAGMA integrity_check` and the invariants, appends the outcome
  /// to the log and returns it. It only reads, and it never throws.
  Future<IntegrityReport> run() async {
    final failures = <IntegrityFailure>[];
    try {
      final pragma = await _database
          .customSelect('PRAGMA integrity_check')
          .get();
      final messages = [
        for (final row in pragma) row.data.values.first.toString(),
      ].where((message) => message != 'ok').toList();
      if (messages.isNotEmpty) {
        failures.add(IntegrityFailure('sqlite_integrity', messages));
      }
      for (final MapEntry(:key, :value) in _invariants.entries) {
        final rows = await _database.customSelect(value).get();
        final ids = [for (final row in rows) row.read<String>('id')]..sort();
        if (ids.isNotEmpty) failures.add(IntegrityFailure(key, ids));
      }
    } on Object catch (error) {
      failures.add(IntegrityFailure('check_error', ['${error.runtimeType}']));
    }
    final report = IntegrityReport(failures);
    await _log.append(report, appVersion: _appVersion, at: _clock.now());
    return report;
  }
}

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  } on Object catch (error) {
    developer.log(
      'app version unavailable',
      name: 'jotline.integrity',
      error: error,
    );
    return 'unknown';
  }
});

final integrityCheckProvider = FutureProvider<IntegrityCheck>((ref) async {
  final version = await ref.watch(appVersionProvider.future);
  return IntegrityCheck(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    IntegrityLog(() async {
      final directory = await getApplicationSupportDirectory();
      return File('${directory.path}/integrity.log');
    }),
    version,
  );
});
