/// What the page screen reports to the screen underneath when it closes.
sealed class PageOutcome {
  const new();
}

/// The page was moved to the trash from its own options.
final class PageTrashed extends PageOutcome {
  const new(this.id);

  final String id;
}
