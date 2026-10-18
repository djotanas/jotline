import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/integrity_log.dart';

import '../../integration_test/kill/kill_verify.dart';

String _blocks(List<String> texts) => jsonEncode([
  for (final text in texts)
    {'type': 'text', 'content_json': '{"text":"$text","marks":[]}'},
]);

List<BlockSnapshot> _snapshot(List<String> texts) => [
  for (final text in texts)
    BlockSnapshot('text', '{"text":"$text","marks":[]}'),
];

void main() {
  const passed = IntegrityReport([]);

  KillAcks acks({List<String>? ack, List<List<String>> pending = const []}) =>
      KillAcks.parse([
        if (ack != null) '{"ack":${_blocks(ack)}}',
        for (final texts in pending) '{"pending":${_blocks(texts)}}',
      ]);

  test('KILL-02: blocks equal to the last ack pass', () {
    final verdict = verifyKill(
      actual: _snapshot(['a', 'b']),
      acks: acks(
        ack: ['a', 'b'],
        pending: [
          ['a', 'b', 'c'],
        ],
      ),
      integrity: passed,
    );

    expect(verdict.passed, isTrue);
  });

  test('KILL-02: blocks equal to the pending snapshot after the ack pass', () {
    final verdict = verifyKill(
      actual: _snapshot(['a', 'b', 'c']),
      acks: acks(
        ack: ['a', 'b'],
        pending: [
          ['a', 'b', 'c'],
        ],
      ),
      integrity: passed,
    );

    expect(verdict.passed, isTrue);
  });

  test(
    'KILL-02: a saved block that is missing fails with expected and actual',
    () {
      final verdict = verifyKill(
        actual: _snapshot(['a']),
        acks: acks(
          ack: ['a', 'b'],
          pending: [
            ['a', 'b', 'c'],
          ],
        ),
        integrity: passed,
      );

      expect(verdict.passed, isFalse);
      expect(verdict.reason, 'blocks');
      expect(verdict.expected, _snapshot(['a', 'b']));
      expect(verdict.actual, _snapshot(['a']));
    },
  );

  test('KILL-03: a failing integrity check fails the iteration', () {
    final verdict = verifyKill(
      actual: _snapshot(['a', 'b']),
      acks: acks(ack: ['a', 'b']),
      integrity: const IntegrityReport([
        IntegrityFailure('orphan_block', ['b1']),
      ]),
    );

    expect(verdict.passed, isFalse);
    expect(verdict.reason, 'integrity: orphan_block=b1');
  });
}
