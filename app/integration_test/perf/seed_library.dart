import 'dart:math';

import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/database/tables/member_role.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/ordering/fractional_index.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';

const _words = [
  'caderno',
  'viagem',
  'estrada',
  'manhã',
  'cidade',
  'jantar',
  'reunião',
  'projeto',
  'ideia',
  'leitura',
  'janela',
  'música',
  'amigo',
  'receita',
  'jardim',
  'planejar',
  'comprar',
  'lembrar',
  'escrever',
  'caminho',
  'praia',
  'trabalho',
  'família',
  'domingo',
  'história',
  'semana',
  'cozinha',
  'registro',
  'roteiro',
  'tarefa',
];

const _targetWord = 'belém';
const _bigNotebookPages = 10000;
const _smallNotebooks = 20;
const _smallNotebookPages = 100;
const _blocksPerPage = 20;
const _textLength = 200;

/// Fills [database] with the large library of LOAD-01: one notebook of
/// 10,000 pages and 20 notebooks of 100 pages, 20 text blocks per page,
/// the word "belém" once in every page.
Future<void> seedLibrary(
  AppDatabase database, {
  Random? random,
  IdGenerator? ids,
}) async {
  final rng = random ?? Random(1);
  final generator = ids ?? UuidV7Generator();
  final userId = await LocalUserRepository(database, generator).id();
  final base = DateTime.utc(2026);
  var tick = 0;
  DateTime nextInstant() => base.add(Duration(seconds: tick++));

  await database.transaction(() async {
    final sizes = [
      for (var i = 0; i < _smallNotebooks; i++) _smallNotebookPages,
      _bigNotebookPages,
    ];
    for (final (index, pageCount) in sizes.indexed) {
      final notebookId = generator.newId();
      await database
          .into(database.notebooks)
          .insert(
            NotebooksCompanion.insert(
              id: notebookId,
              title: pageCount == _bigNotebookPages
                  ? 'Biblioteca grande'
                  : 'Caderno ${index + 1}',
              cover: CoverPattern.lisa,
              color: NotebookColor.azulTinta,
              createdBy: userId,
              createdAt: nextInstant(),
            ),
          );
      await database
          .into(database.notebookMembers)
          .insert(
            NotebookMembersCompanion.insert(
              id: generator.newId(),
              notebookId: notebookId,
              userId: userId,
              role: MemberRole.owner,
              addedBy: userId,
              createdAt: nextInstant(),
            ),
          );
      String? previousPage;
      for (var start = 0; start < pageCount; start += 500) {
        final end = min(start + 500, pageCount);
        final pages = <PagesCompanion>[];
        final blocks = <BlocksCompanion>[];
        for (var number = start; number < end; number++) {
          final pageId = generator.newId();
          previousPage = FractionalIndex.keyBetween(previousPage, null);
          final instant = nextInstant();
          pages.add(
            PagesCompanion.insert(
              id: pageId,
              notebookId: notebookId,
              title: 'Página ${number + 1}',
              position: previousPage,
              updatedAt: instant,
              updatedBy: userId,
            ),
          );
          final targetBlock = rng.nextInt(_blocksPerPage);
          String? previousBlock;
          for (var b = 0; b < _blocksPerPage; b++) {
            previousBlock = FractionalIndex.keyBetween(previousBlock, null);
            blocks.add(
              BlocksCompanion.insert(
                id: generator.newId(),
                pageId: pageId,
                type: BlockType.text.id,
                contentJson: BlockContent(
                  _text(rng, withTarget: b == targetBlock),
                ).toJson(),
                position: previousBlock,
                updatedAt: instant,
                updatedBy: userId,
              ),
            );
          }
        }
        await database.batch((batch) {
          batch
            ..insertAll(database.pages, pages)
            ..insertAll(database.blocks, blocks);
        });
      }
    }
  });
}

String _text(Random rng, {required bool withTarget}) {
  final words = <String>[];
  var length = 0;
  while (length < _textLength) {
    final word = _words[rng.nextInt(_words.length)];
    words.add(word);
    length += word.length + 1;
  }
  if (withTarget) words[rng.nextInt(words.length)] = _targetWord;
  return words.join(' ');
}
