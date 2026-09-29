// A reader may not favorite what they wrote. `state.rows.article` is the one
// referenced article, or empty where the reference dangles and the FK will
// refuse after this does.
(state, event) => state.rows.article.every((a) => a.author_id !== event.row.user_id);
