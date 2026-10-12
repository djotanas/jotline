import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:jotline/core/database/app_database.dart';

AppDatabase createTestDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);
