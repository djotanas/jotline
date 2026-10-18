import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/integrity_check.dart';
import 'package:jotline/core/database/integrity_log.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_providers.dart';
import 'package:jotline/features/blocks/presentation/editor/block_mapper.dart';
import 'package:jotline/features/blocks/presentation/editor/page_editor.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/pages/data/page_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_editor/super_editor.dart';

import 'kill_verify.dart';

const maxKillBlocks = 30;
const _title = 'Kill test';
const _words = ['alfa', 'beta', 'gama', 'delta', 'ômega', 'sigma', 'lambda'];

List<BlockSnapshot> snapshotOfRows(List<Block> rows) => [
  for (final row in rows) BlockSnapshot(row.type, row.contentJson),
];

/// The blocks the editor will have saved after a flush: text nodes with text
/// (an empty new node is not saved until its first character).
List<BlockSnapshot> snapshotOfDocument(Document document) => [
  for (final node in document)
    if (node is TextNode && node.text.toPlainText().isNotEmpty)
      () {
        final (type, content as BlockContent) = BlockMapper.fromNode(node);
        return BlockSnapshot(type.id, content.forType(type).toJson());
      }(),
];

/// One seeded edit: type a word, split a paragraph, toggle a heading or drop
/// the first block as soon as the page is long.
void applyKillOperation(Editor editor, Random random) {
  final nodes = editor.document.toList();
  final paragraphs = nodes.whereType<ParagraphNode>().toList();
  final choice = random.nextInt(10);
  if (nodes.length > maxKillBlocks) {
    editor.execute([DeleteNodeRequest(nodeId: nodes.first.id)]);
    return;
  }
  final node = nodes[random.nextInt(nodes.length)];
  if (choice >= 8 && paragraphs.isNotEmpty) {
    final target = paragraphs[random.nextInt(paragraphs.length)];
    final heading =
        target.getMetadataValue(NodeMetadata.blockType) == header1Attribution;
    editor.execute([
      ChangeParagraphBlockTypeRequest(
        nodeId: target.id,
        blockType: heading ? paragraphAttribution : header1Attribution,
      ),
    ]);
    return;
  }
  if (choice >= 6 && node is ParagraphNode && node.text.length >= 2) {
    editor.execute([
      SplitParagraphRequest(
        nodeId: node.id,
        splitPosition: TextPosition(offset: node.text.length ~/ 2),
        newNodeId: Editor.createNodeId(),
        replicateExistingMetadata: true,
      ),
    ]);
    return;
  }
  if (node is! TextNode) return;
  editor.execute([
    InsertTextRequest(
      documentPosition: DocumentPosition(
        nodeId: node.id,
        nodePosition: TextNodePosition(offset: node.text.length),
      ),
      textToInsert: '${_words[random.nextInt(_words.length)]} ',
      attributions: const {},
    ),
  ]);
}

void _append(File file, Map<String, Object?> line) =>
    file.writeAsStringSync('${jsonEncode(line)}\n', mode: FileMode.append);

List<Map<String, Object>> _json(List<BlockSnapshot> snapshot) => [
  for (final block in snapshot) block.toJson(),
];

Future<String> _pageId(ProviderContainer container) async {
  final db = container.read(databaseProvider);
  final existing = await (db.select(
    db.pages,
  )..where((t) => t.title.equals(_title) & t.deletedAt.isNull())).get();
  if (existing.isNotEmpty) return existing.first.id;
  final notebookId = await container
      .read(notebookRepositoryProvider)
      .create(
        title: _title,
        cover: CoverPattern.lisa,
        color: NotebookColor.azulTinta,
      );
  return await container
      .read(pageRepositoryProvider)
      .create(notebookId, title: _title);
}

/// The instrumented build of the kill test (KILL-01): on every start it
/// verifies the page against `kill/acks.jsonl`, then types seeded edits
/// forever, writing `pending` before and `ack` after each flush, until the
/// script force-stops it. Results go to `kill/results.jsonl`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('kill test'))),
    ),
  );
  final container = ProviderContainer();
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/kill')
    ..createSync(recursive: true);
  final acksFile = File('${directory.path}/acks.jsonl');
  final resultsFile = File('${directory.path}/results.jsonl');
  final pageId = await _pageId(container);
  final blocks = container.read(blockRepositoryProvider);
  final iteration = resultsFile.existsSync()
      ? resultsFile.readAsLinesSync().length + 1
      : 1;

  final actual = snapshotOfRows(await blocks.loadPage(pageId));
  if (acksFile.existsSync()) {
    final integrity = await IntegrityCheck(
      container.read(databaseProvider),
      const SystemClock(),
      IntegrityLog(() async => File('${directory.path}/integrity.log')),
      'kill',
    ).run();
    final verdict = verifyKill(
      actual: actual,
      acks: KillAcks.parse(acksFile.readAsLinesSync()),
      integrity: integrity,
    );
    _append(resultsFile, {
      'iteration': iteration,
      'passed': verdict.passed,
      'reason': verdict.reason,
      'expected': _json(verdict.expected),
      'actual': _json(verdict.actual),
    });
  }
  _append(acksFile, {'ack': _json(actual)});

  final editor = PageEditor(
    rows: await blocks.loadPage(pageId),
    pageId: pageId,
    repository: blocks,
  );
  final random = Random(iteration);
  while (true) {
    applyKillOperation(editor.editor, random);
    final snapshot = snapshotOfDocument(editor.editor.document);
    _append(acksFile, {'pending': _json(snapshot)});
    await editor.flush();
    _append(acksFile, {'ack': _json(snapshot)});
    await Future<void>.delayed(Duration(milliseconds: 5 + random.nextInt(35)));
  }
}
