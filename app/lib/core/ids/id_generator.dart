import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Creates the ids of every row, on the device and without network.
abstract interface class IdGenerator {
  String newId();
}

final class UuidV7Generator implements IdGenerator {
  new();

  final Uuid _uuid = const Uuid();

  @override
  String newId() => _uuid.v7();
}

final idGeneratorProvider = Provider<IdGenerator>((ref) => UuidV7Generator());
