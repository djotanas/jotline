/// SQL expression for a page's "last edited" instant, on the alias `p` of
/// `pages`. Shared by the page lists and the search ordering (SRCH-10).
const lastEditedSql =
    'max(p.updated_at, '
    'COALESCE((SELECT max(b.updated_at) FROM blocks b '
    'WHERE b.page_id = p.id), p.updated_at), '
    'COALESCE((SELECT max(b.deleted_at) FROM blocks b '
    'WHERE b.page_id = p.id), p.updated_at))';
