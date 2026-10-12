import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';

final blockRepositoryProvider = Provider<BlockRepository>(
  (ref) => BlockRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(localUserRepositoryProvider),
  ),
);

final StreamProviderFamily<List<Block>, String> blocksProvider = StreamProvider
    .autoDispose
    .family<List<Block>, String>(
      (ref, pageId) => ref.watch(blockRepositoryProvider).watchByPage(pageId),
      retry: (_, _) => null,
    );
