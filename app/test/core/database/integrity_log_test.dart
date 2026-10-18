import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/integrity_log.dart';

void main() {
  late Directory directory;
  late File file;
  late IntegrityLog log;
  final at = DateTime.utc(2026, 10, 17, 12);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('integrity_log_test');
    file = File('${directory.path}/integrity.log');
    log = IntegrityLog(() async => file);
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test('INTEG-06: a passing check writes date, version and pass', () async {
    await log.append(const IntegrityReport([]), appVersion: '1.0.0+1', at: at);

    expect(file.readAsStringSync(), '2026-10-17T12:00:00Z 1.0.0+1 pass\n');
  });

  test('INTEG-06: a failing check lists each invariant with its ids', () async {
    await log.append(
      const IntegrityReport([
        IntegrityFailure('orphan_page', ['p1', 'p2']),
        IntegrityFailure('duplicate_position', ['b1']),
      ]),
      appVersion: '1.0.0+1',
      at: at,
    );

    expect(
      file.readAsStringSync(),
      '2026-10-17T12:00:00Z 1.0.0+1 fail orphan_page=p1,p2 '
      'duplicate_position=b1\n',
    );
  });

  test('EDGE-08: the log file is created when it does not exist', () async {
    expect(file.existsSync(), isFalse);

    await log.append(const IntegrityReport([]), appVersion: '1.0.0+1', at: at);

    expect(file.existsSync(), isTrue);
  });

  test('INTEG-06: lines are appended, not replaced', () async {
    await log.append(const IntegrityReport([]), appVersion: '1.0.0+1', at: at);
    await log.append(
      const IntegrityReport([
        IntegrityFailure('orphan_block', ['b1']),
      ]),
      appVersion: '1.0.0+1',
      at: at.add(const Duration(days: 1)),
    );

    expect(file.readAsLinesSync(), [
      '2026-10-17T12:00:00Z 1.0.0+1 pass',
      '2026-10-18T12:00:00Z 1.0.0+1 fail orphan_block=b1',
    ]);
  });

  test('INTEG-06: a write error does not throw', () async {
    final blocked = File('${directory.path}/missing/integrity.log');
    final failing = IntegrityLog(() async => blocked);

    await expectLater(
      failing.append(const IntegrityReport([]), appVersion: '1.0.0+1', at: at),
      completes,
    );
    expect(blocked.existsSync(), isFalse);
  });
}
