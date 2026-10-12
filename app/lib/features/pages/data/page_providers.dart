import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/features/pages/data/page_repository.dart';

final pageRepositoryProvider = Provider<PageRepository>(
  (ref) => PageRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(localUserRepositoryProvider),
  ),
);

final StreamProviderFamily<List<NotebookPage>, String> pagesProvider =
    StreamProvider.autoDispose.family<List<NotebookPage>, String>(
      (ref, notebookId) =>
          ref.watch(pageRepositoryProvider).watchByNotebook(notebookId),
      retry: (_, _) => null,
    );
