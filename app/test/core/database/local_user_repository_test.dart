import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ids/id_generator.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_database.dart';

class _FixedIdGenerator implements IdGenerator {
  new(this._id);

  final String _id;

  @override
  String newId() => _id;
}

void main() {
  late AppDatabase database;

  setUp(() => database = createTestDatabase());
  tearDown(() => database.close());

  Future<List<LocalUserData>> rows(AppDatabase db) {
    return db.select(db.localUser).get();
  }

  test('USER-02: an empty table gets the generator id, stored in the '
      'table', () async {
    final repository = LocalUserRepository(database, SequentialIdGenerator());

    final id = await repository.id();

    expect(id, SequentialIdGenerator().newId());
    final stored = await rows(database);
    expect(stored.single.slot, 1);
    expect(stored.single.id, id);
  });

  test('USER-02: a later request returns the stored id without generating '
      'another', () async {
    final first = LocalUserRepository(database, _FixedIdGenerator('first'));
    final second = LocalUserRepository(database, _FixedIdGenerator('second'));

    await first.id();

    expect(await second.id(), 'first');
    expect(await first.id(), 'first');
  });

  test('USER-03: the same id comes back after closing and reopening the '
      'database file', () async {
    final directory = Directory.systemTemp.createTempSync('jotline_user_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/db.sqlite');

    final firstRun = createFileTestDatabase(file);
    final firstId = await LocalUserRepository(
      firstRun,
      SequentialIdGenerator(),
    ).id();
    await firstRun.close();

    final secondRun = createFileTestDatabase(file);
    addTearDown(secondRun.close);
    final secondId = await LocalUserRepository(
      secondRun,
      _FixedIdGenerator('other'),
    ).id();

    expect(secondId, firstId);
    expect(await rows(secondRun), hasLength(1));
  });

  test('USER-04: two concurrent requests on separate instances leave one '
      'row and return the same id', () async {
    final a = LocalUserRepository(database, _FixedIdGenerator('a'));
    final b = LocalUserRepository(database, _FixedIdGenerator('b'));

    final ids = await Future.wait([a.id(), b.id()]);

    expect(ids[0], ids[1]);
    final stored = await rows(database);
    expect(stored, hasLength(1));
    expect(stored.single.id, ids[0]);
  });

  test('USER-01: repeated requests never leave more than one row', () async {
    final generator = SequentialIdGenerator();

    for (var i = 0; i < 3; i++) {
      await LocalUserRepository(database, generator).id();
      await LocalUserRepository(database, generator).id();
    }

    expect(await rows(database), hasLength(1));
  });

  test('USER-02: the provider builds the repository from the database and '
      'id generator overrides', () async {
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        idGeneratorProvider.overrideWithValue(_FixedIdGenerator('wired')),
      ],
    );

    final id = await container.read(localUserRepositoryProvider).id();

    expect(id, 'wired');
    expect((await rows(database)).single.id, 'wired');
  });
}
