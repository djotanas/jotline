/// What the notebook screen reports to the screen underneath when it closes.
sealed class NotebookOutcome {
  const new(this.id);

  final String id;
}

/// The notebook was archived; [previous] is the `archived_at` it had before.
final class NotebookArchived extends NotebookOutcome {
  const new(super.id, {this.previous});

  final DateTime? previous;
}

/// The notebook was unarchived; [previous] is the `archived_at` it had.
final class NotebookUnarchived extends NotebookOutcome {
  const new(super.id, {required this.previous});

  final DateTime? previous;
}

/// The notebook was moved to the trash.
final class NotebookTrashed extends NotebookOutcome {
  const new(super.id);
}
