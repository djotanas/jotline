import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jotline/core/database/integrity_log.dart';

/// The `type` and `content_json` of one block, in `position` order.
@immutable
final class BlockSnapshot {
  const new(this.type, this.contentJson);

  factory fromJson(Map<String, Object?> json) =>
      BlockSnapshot(json['type']! as String, json['content_json']! as String);

  final String type;
  final String contentJson;

  Map<String, Object> toJson() => {'type': type, 'content_json': contentJson};

  @override
  bool operator ==(Object other) =>
      other is BlockSnapshot &&
      other.type == type &&
      other.contentJson == contentJson;

  @override
  int get hashCode => Object.hash(type, contentJson);

  @override
  String toString() => '$type $contentJson';
}

/// The `acks.jsonl` lines: the last completed save and every save attempt
/// started after it.
final class KillAcks {
  const new({required this.ack, required this.pendings});

  factory parse(Iterable<String> lines) {
    List<BlockSnapshot>? ack;
    var pendings = <List<BlockSnapshot>>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final json = jsonDecode(line) as Map<String, Object?>;
      List<BlockSnapshot> read(String key) => [
        for (final block in json[key]! as List<Object?>)
          BlockSnapshot.fromJson(block! as Map<String, Object?>),
      ];
      if (json.containsKey('ack')) {
        ack = read('ack');
        pendings = [];
      } else {
        pendings.add(read('pending'));
      }
    }
    return KillAcks(ack: ack, pendings: pendings);
  }

  final List<BlockSnapshot>? ack;
  final List<List<BlockSnapshot>> pendings;
}

/// The outcome of one relaunch.
final class KillVerdict {
  const new({
    required this.passed,
    required this.reason,
    required this.expected,
    required this.actual,
  });

  final bool passed;
  final String reason;
  final List<BlockSnapshot> expected;
  final List<BlockSnapshot> actual;
}

/// Compares the page's blocks after a kill with what was saved before it
/// (KILL-02) and requires the integrity check to pass (KILL-03). A save can
/// commit just before the kill, so a pending snapshot is also accepted.
KillVerdict verifyKill({
  required List<BlockSnapshot> actual,
  required KillAcks acks,
  required IntegrityReport integrity,
}) {
  final expected = acks.ack ?? const <BlockSnapshot>[];
  if (!integrity.passed) {
    final failures = [
      for (final f in integrity.failures) '${f.invariant}=${f.ids.join(',')}',
    ];
    return KillVerdict(
      passed: false,
      reason: 'integrity: ${failures.join(' ')}',
      expected: expected,
      actual: actual,
    );
  }
  final accepted = [expected, ...acks.pendings];
  final matches = accepted.any((snapshot) => listEquals(snapshot, actual));
  return KillVerdict(
    passed: matches,
    reason: matches ? 'ok' : 'blocks',
    expected: expected,
    actual: actual,
  );
}
