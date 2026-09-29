# Acceptance

What "done" looks like, one check per line. Each id below is cited by the
invariants in [ir.html](ir.html) that realize it; coverage is a lint, not a hope.

- Coming in takes one gesture — a passkey tap or a guest click — and leaves the person's handle on screen, next to sign out, until they sign out. {#accept-signin-handle}
- Signing out returns to the door; signing back in with the same passkey finds every article, follow and favorite exactly where it was left. {#accept-signout-return}
- Someone who has just come in and follows nobody still sees the whole community's writing, newest first — never a blank page. {#accept-community-list}
- Your feed shows the articles of the people you follow and nothing else; with no follows yet it says how to fill it rather than showing an empty list. {#accept-feed-follows-only}
- Every article reads as the same preview wherever it is listed: writer's picture and handle, date, title, description, tags, and favorite count. {#accept-preview-complete}
- A long list gives a screenful and a plain way to more, rather than dumping everything at once. {#accept-list-paged}
- Publishing an article lands the writer on the finished piece, and it is on the community list for everyone immediately. {#accept-publish-lands}
- An article with no title or no body is refused with a visible message, and nothing is saved. {#accept-article-blank-refused}
- An article's address is readable and derived from its title, and two articles that share a title still have addresses that tell them apart. {#accept-slug-readable}
- An article's body renders as the markdown it was written in — headings, emphasis, links, lists, quotes and code all read as formatting — at a comfortable reading measure rather than the full width of the window. {#accept-body-markdown}
- A body containing HTML, or a link whose address is not a web address, renders as the characters the writer typed — never as working markup and never as a working link. {#accept-body-safe}
- Editing an article changes it everywhere it appears — the community list, its tags, its author's profile — without a reload. {#accept-edit-propagates}
- Only an article's author is offered edit and delete on it; another person's article offers follow and favorite instead. {#accept-author-only-controls}
- Deleting an article removes it from every list, tag, feed and profile it appeared in, and takes its comments and favorites with it. {#accept-delete-cascades}
- The tags typed on an article file it under each of them at once, and it appears on each tag's list. {#accept-tags-file}
- The popular tags panel counts only live articles, and its counts stay honest as articles are published, retagged and deleted. {#accept-tagcount-true}
- A tag with nothing live under it says so plainly rather than showing an empty list. {#accept-tag-empty}
- Searching words from an article's title, description or body finds it from anywhere. {#accept-search-finds}
- A search matching nothing says so plainly. {#accept-search-empty}
- Favoriting an article moves its count on the spot, everywhere that article shows; pressing again takes it back. {#accept-favorite-toggles}
- One person's favorite of an article shows in another person's count without a reload, and the count is the same number for everyone. {#accept-favorite-live}
- A person may favorite an article at most once, however many times they press. {#accept-favorite-once}
- Following someone puts their writing in your feed immediately; unfollowing takes it out. {#accept-follow-fills-feed}
- Saving a piece puts it on your reading list on the spot, from wherever you pressed; pressing again takes it off, and no count anywhere moves either way. {#accept-save-toggles}
- A person may save a piece at most once, however many times they press. {#accept-save-once}
- Your reading list shows what you saved, newest save first, as the same preview every other list shows — and it is yours alone: nobody is told what you have put aside. {#accept-reading-list}
- A reading list with nothing on it says so, and says where the control that fills it lives. {#accept-reading-list-empty}
- A follow button reads its true state on every screen it appears on, including on a fresh visit after signing back in. {#accept-follow-state-true}
- Nobody can follow themselves; their own profile offers edit your profile instead of a follow button. {#accept-no-self-follow}
- Leaving a comment shows it under the article at once and clears the form; an empty comment is refused. {#accept-comment-add}
- Only a comment's own writer is offered its removal, and removing it takes it away on the spot. {#accept-comment-remove}
- An article with no comments yet says so and invites the first, rather than showing a bare form. {#accept-comment-empty}
- A person's profile shows their picture, handle, display name and about, with their articles and the ones they have favorited each in their own list. {#accept-profile-page}
- Editing a display name, about or picture changes how that person reads everywhere they appear — every byline, every comment, every preview — not just on their own page. {#accept-profile-propagates}
- A second person signing in sees the same community writing, and their own feed, favorites and profile are their own. {#accept-second-person}
- Every screen reads correctly in both the device's light and dark appearance. {#accept-dual-appearance}
