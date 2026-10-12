/// Where a page or block goes among its siblings, without exposing keys.
sealed class Placement {
  const new();
}

final class AtStart extends Placement {
  const new();
}

final class AtEnd extends Placement {
  const new();
}

/// Right after the sibling with [id].
final class After extends Placement {
  const new(this.id);

  final String id;
}
