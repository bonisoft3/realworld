// The machine rung: hand-compiled hop 2 from ir.html (pinned below). Nobody
// reviews this file; review happens at brief.md and ir.html. Every object's
// `ir` field back-references the ir.html element id it realizes.
//
// This is the link map: derived structure lives here; the application's
// assembly (shell/screens/*, pipelines/*.blobl, pipelines/*.browser.js,
// services/database/sql/*) lives in its own files, referenced below and
// embedded only where a consumer needs inline content.
@extern(embed)

package realworld

import "bonisoft.org/plugins/pronto"

// Both appearances carry the same token names — appearance is a token resolution, never a state
// (accept-dual-appearance) — which #Design's closed dark twin guarantees
// (ir decision-design-identity).
_designMd: _ @embed(file="DESIGN.md", type=text)
_catalogues: _ @embed(glob="messages/*.json")

code: pronto.#App & {
	meta: name:        "realworld"
	meta: description: "A community writing space — read pieces, follow their authors, and keep the ones that matter."
	meta: ir: sha256: "57e2636133f0a85c5a871a303f4d81a9f89140dc1905514a3942f83eaa5a4107"
	// The browser tier is declared unsupported rather than quietly broken
	// (ir decision-browser-tier-unsupported).
	meta: targets: []
	// Fifteen most-spoken languages, en unprefixed as the default. Every tag
	// is checked canonical against Intl.getCanonicalLocales before being
	// written here — none of the fifteen carries a region subtag, so each
	// path segment is the bare language tag, lowercased.
	meta: i18n: {
		default: "en"
		locales: {
			en: path: "en"
			zh: path: "zh"
			hi: path: "hi"
			es: path: "es"
			fr: path: "fr"
			ar: path: "ar"
			bn: path: "bn"
			pt: path: "pt"
			ru: path: "ru"
			ur: path: "ur"
			id: path: "id"
			de: path: "de"
			ja: path: "ja"
			sw: path: "sw"
			tr: path: "tr"
		}
		catalogues: _catalogues
	}
	// Passed to shell.yaml verbatim; presence also switches the cluster's auth
	// plane on (auth service, roles, auth_uid(), service token). The gate is
	// binary and Conduit gates every screen (ir decision-auth-deviation).
	// `self` is what the strip needs to name a reader and lead somewhere: their
	// own public page, and the column their chosen name lives in
	// (ir decision-identity-chrome).
	capabilities: auth: {
		required: true
		service:  "/auth"
		self: {
			route: "profile"
			name: {table: "app_user", column: "display_name"}
		}
	}
	// The picture is a link, so the cluster drops rclone-s3 and imgproxy
	// (ir decision-terminal-chrome).
	capabilities: blobs: false

	// The app is served to a native host as well as a browser, so every route
	// owes its web affordances a native peer and check-parity holds it to that.
	capabilities: native: true

	// Assembly SQL beyond the schema vocabulary: the three composite uniques
	// the per-field flag cannot express, the additive owner-write policies and
	// the app_user column grant, the me read-only narrowing, and the two
	// SECURITY DEFINER triggers (ir decision-composite-uniques,
	// decision-public-read-owner-writes, decision-me-row,
	// decision-article-tag-trigger).
	state: rawMigrations: [
		{name: "011_owner_writes.sql", src: "services/database/sql/011_owner_writes.sql"},
		{name: "012_me_readonly.sql", src: "services/database/sql/012_me_readonly.sql"},
		{name: "013_article_tag_sync.sql", src: "services/database/sql/013_article_tag_sync.sql"},
		{name: "014_me_provision.sql", src: "services/database/sql/014_me_provision.sql"},
		{name: "015_default_privileges.sql", src: "services/database/sql/015_default_privileges.sql"},
	]

	surface: design: (pronto.#DesignMd & {text: _designMd}).design

	state: entities: {
		AppUser: {
			id: "0xffeeef2f0457cd0c"
			table: "app_user"
			durability: "server"
			// Content reads public; writes are the additive 011 policies, never a
			// declared `owned` widened in SQL (ir decision-public-read-owner-writes).
			access: {scope: "public"}
			fields: [
				// No default: the auth service supplies the id.
				{ordinal: 1, name: "id", type: "uuid", pk: true},
				// Server-generated, never typed; 011's column grant excludes it, so
				// the UPDATE arm cannot reach it (ir test-handle-not-writable).
				{ordinal: 2, name: "handle", type: "string", unique: true, cel: "this.size() > 0"},
				// NULL until set; the byline falls back to the handle with no
				// conditional (ir decision-preview-one-component).
				{ordinal: 3, name: "display_name", type: "string", required: false, cel: "this.size() <= 60"},
				{ordinal: 4, name: "bio", type: "string", required: false, cel: "this.size() <= 300"},
				// A link the person supplies; no uploads (capabilities.blobs is off).
				{ordinal: 5, name: "image_url", type: "string", required: false, cel: "this.size() <= 2048"},
				{ordinal: 6, name: "created_at", type: "timestamp", default: "now()"},
			]
		}
		Me: {
			id: "0xa590918c3d7bc870"
			table: "me"
			durability: "live"
			// The non-forms arm of the two-value vocabulary; the actual writer is
			// the 014 trigger, so a guest's row exists on the first paint
			// (ir decision-me-row).
			writers: "pipeline"
			// A row RLS-scoped to auth_uid() whose mere visibility answers "is this
			// mine": the interpreter has no session binding, so the probe's :empty
			// state is the only mechanism (ir decision-me-row, decision-probe-empty).
			access: {scope: "private", owner: "id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, ref: "app_user"},
				// Copied at provisioning; it cannot drift because 011's column grant
				// excludes handle and 012 drops me's write arms.
				{ordinal: 2, name: "handle", type: "string", cel: "this.size() > 0"},
			]
		}
		Article: {
			id: "0x899a3c66fba1e59d"
			table: "article"
			durability: "server"
			access: {scope: "public"}
			fields: [
				// The shell mints ids client-side; the default is the backstop.
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				// Stamped from the JWT by the column default, never in a form.
				{ordinal: 2, name: "author_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 3, name: "title", type: "string", cel: "this.trim().size() > 0 && this.size() <= 200"},
				{ordinal: 4, name: "description", type: "string", required: false, cel: "this.size() <= 300"},
				// Markdown source, rendered by the article screen's data-text-format
				// (ir decision-markdown-capability).
				{ordinal: 5, name: "body", type: "string", cel: "this.trim().size() > 0"},
				// The words as typed; projected into ArticleTag by the 013 trigger.
				{ordinal: 6, name: "tags", type: "string", required: false, cel: "this.size() <= 200"},
				// A link the writer supplies, exactly as app_user.image_url is; no
				// uploads (capabilities.blobs is off), so there is nothing to store
				// and nothing to resize (ir decision-cover-link).
				{ordinal: 7, name: "cover_url", type: "string", required: false, cel: "this.size() <= 2048"},
				// Who the picture belongs to. Nullable and short: a credit line is
				// a courtesy the writer may not have, and a cover with no credit
				// draws no caption rather than an empty one
				// (ir decision-cover-credit).
				{ordinal: 8, name: "cover_credit", type: "string", required: false, cel: "this.size() <= 120"},
				// Slugified title plus the first hex group of the row's own uuid;
				// generated columns take IMMUTABLE expressions only, so there is no
				// uniquifying loop (ir decision-slug).
				{ordinal: 9, name: "slug", type: "string", unique: true, cel: "this.size() > 0", generated: "coalesce(nullif(btrim(left(regexp_replace(lower(title), '[^a-z0-9]+', '-', 'g'), 80), '-'), ''), 'article') || '-' || left(id::text, 8)"},
				{ordinal: 10, name: "created_at", type: "timestamp", default: "now()"},
				// Restamped by the revise form's hidden {now}: a column default fires
				// only on INSERT (ir decision-updated-at-hidden-now).
				{ordinal: 11, name: "updated_at", type: "timestamp", default: "now()"},
				{ordinal: 12, name: "search", type: "tsvector", generated: "to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(description,'') || ' ' || coalesce(body,''))"},
				// Words over 220 a minute, rounded up, never zero — a stored
				// generated column so the number is the body's and cannot drift
				// from it (ir decision-reading-time).
				{ordinal: 13, name: "reading_minutes", type: "int32", generated: "greatest(1, ceil(coalesce(array_length(regexp_split_to_array(btrim(body), '\\s+'), 1), 0) / 220.0)::int)"},
			]
			indexes: [{on: "created_at"}, {on: "author_id"}, {on: "search", using: "gin"}]
		}
		ArticleTag: {
			id: "0xed76a04d0fffe5e4"
			uniques: [{name: "uq_article_tag_pair", cols: ["article_id", "tag"]}]
			table: "article_tag"
			durability: "server"
			access: {scope: "public"}
			fields: [
				// Present so the chip region can key its rows.
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				// Cascaded DELETEs are what drive tag-recount to zero.
				{ordinal: 2, name: "article_id", type: "uuid", ref: "article"},
				// Lower-cased and punctuation-stripped by the 013 trigger; no write
				// arm exists at all, so every row is the trigger's
				// (ir decision-article-tag-trigger).
				{ordinal: 3, name: "tag", type: "string", cel: "this.size() > 0 && this.size() <= 40"},
			]
			indexes: [{on: "tag"}]
		}
		Comment: {
			id: "0xc11aa0c88f8ccab7"
			table: "comment"
			durability: "server"
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "article_id", type: "uuid", ref: "article"},
				{ordinal: 3, name: "author_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				// Plain text, not markdown: a markdown reply is a formatting surface
				// the brief scopes out (ir decision-comment-plain-text).
				{ordinal: 4, name: "body", type: "string", cel: "this.trim().size() > 0 && this.size() <= 2000"},
				{ordinal: 5, name: "created_at", type: "timestamp", default: "now()"},
			]
			indexes: [{on: "article_id"}]
		}
		Favorite: {
			id: "0x98c341a47aacae19"
			uniques: [{name: "uq_favorite_pair", cols: ["user_id", "article_id"]}]
			table: "favorite"
			durability: "server"
			// Private, so the per-card probe is local and optimistic; the two public
			// faces are derived (ir decision-favorite-private-derived).
			access: {scope: "private", owner: "user_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "user_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 3, name: "article_id", type: "uuid", ref: "article"},
				// Orders the profile's favorited list through favorite-index.
				{ordinal: 4, name: "created_at", type: "timestamp", default: "now()"},
				// Un-favouriting SETS this rather than removing the row, so a
				// retraction is evidence the reader can see rather than an absence
				// they must remember (ir decision-optimistic-fold). The pair stays
				// unique, so it is one row per reader per piece forever: the table
				// cannot grow by toggling and needs no reaper.
				{ordinal: 5, name: "deleted_at", type: "timestamp", required: false},
			]
			indexes: [{on: "article_id"}]
			// The article's author is one reference away, which CEL cannot
			// reach: a reader may not favorite what they wrote.
			validations: "own-article": {
				src:  "shell/validations/own-article.js"
				via:  ["article_id"]
				note: "a reader cannot favorite what they wrote"
			}
		}
		Bookmark: {
			id: "0x9f9da42612642009"
			uniques: [{name: "uq_bookmark_pair", cols: ["user_id", "article_id"]}]
			table: "bookmark"
			durability: "server"
			// Owned like Favorite, and unlike Favorite it stays that way all the
			// way down: a saved piece has no public face, so there is no count to
			// derive and no sink to feed (ir decision-bookmark-no-public-face).
			access: {scope: "private", owner: "user_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "user_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				{ordinal: 3, name: "article_id", type: "uuid", ref: "article"},
				// Orders the reading list newest-first, directly — no sink stands
				// between the row and the list that reads it.
				{ordinal: 4, name: "created_at", type: "timestamp", default: "now()"},
			]
			indexes: [{on: "article_id"}]
		}
		Follow: {
			id: "0xd0b18b1f685bdf9c"
			uniques: [{name: "uq_follow_pair", cols: ["follower_id", "followed_id"]}]
			table: "follow"
			durability: "server"
			access: {scope: "private", owner: "follower_id"}
			fields: [
				{ordinal: 1, name: "id", type: "uuid", pk: true, default: "gen_random_uuid()"},
				{ordinal: 2, name: "follower_id", type: "uuid", ref: "app_user", default: "auth_uid()"},
				// Both FK columns point at app_user; the feed read disambiguates with
				// the column-name hint follow!followed_id!inner(...)
				// (ir decision-follow-single-fk).
				{ordinal: 3, name: "followed_id", type: "uuid", ref: "app_user"},
				{ordinal: 4, name: "created_at", type: "timestamp", default: "now()"},
			]
			invariant: {cel: "this.follower_id != this.followed_id"}
		}
		FavoriteCount: {
			id: "0xa8012732a778199b"
			table:   "favorite_count"
			durability: "live"
			writers: "pipeline"
			// Private to its reader: a reader may know whether the count
			// included THEM, and nothing about anyone else.
			access: {scope: "private", owner: "user_id"}
			uniques: [{name: "uq_favorite_count_pair", cols: ["user_id", "article_id"]}]
			fields: [
				// "<user>:<article>", so a repeated read upserts rather than
				// accumulating (ir decision-sink-keys).
				{ordinal: 1, name: "id", type: "string", pk: true},
				{ordinal: 2, name: "user_id", type: "uuid", required: true},
				// UUID and no ref, on the same reasoning as ArticleStats
				// (ir decision-sink-no-fk).
				{ordinal: 3, name: "article_id", type: "uuid", required: true},
				{ordinal: 4, name: "mine_counted", type: "int32", cel: "this >= 0 && this <= 1"},
				{ordinal: 5, name: "total_at_read", type: "int32", cel: "this >= 0"},
				// The version of the reader's own row this pair speaks for.
				{ordinal: 6, name: "as_of_txid", type: "int64", required: false},
			]
		}
		ArticleStats: {
			id: "0x9a91dc318d94d5ee"
			table:   "article_stats"
			durability: "live"
			writers: "pipeline"
			access: {scope: "public"}
			// No seed: the row appears with the article's first favorite, and the
			// reading regions carry data-empty-row {"favorite_count":0}
			// (ir decision-sink-keys).
			fields: [
				// The article UUID without a ref: a cascaded favorite
				// DELETE makes the pipeline emit a final row naming a dead article,
				// which an FK would reject and wedge on (ir decision-sink-no-fk).
				{ordinal: 1, name: "article_id", type: "uuid", pk: true},
				// Absolute, never a delta (ir decision-absolute-recount).
				{ordinal: 2, name: "favorite_count", type: "int32", cel: "this >= 0"},
				// Read watermark: the newest favorite.txid this count includes.
				// Distinct from the row's own txid, which is stamped when this
				// row is WRITTEN — after the read, so it appears to cover
				// favorites it never counted (ir decision-optimistic-fold).
				{ordinal: 3, name: "counted_txid", type: "int64", cel: "this >= 0"},
			]
		}
		TagCount: {
			id: "0x86d7de1cf29fee6f"
			table:   "tag_count"
			durability: "live"
			writers: "pipeline"
			access: {scope: "public"}
			fields: [
				// Read as a list, and a list region keys nodes on String(row.id), so
				// the tag word itself is the pk (ir decision-sink-keys).
				{ordinal: 1, name: "id", type: "string", pk: true, cel: "this.size() > 0"},
				{ordinal: 2, name: "article_count", type: "int32", cel: "this >= 0"},
			]
		}
		FavoriteIndex: {
			id: "0x9826a4461b100e6d"
			table:   "favorite_index"
			durability: "live"
			writers: "pipeline"
			access: {scope: "public"}
			fields: [
				{ordinal: 1, name: "id", type: "string", pk: true, cel: "this.size() > 0"},
				// The one FK on a sink, safe because no flow deletes a person; it is
				// what lets profile-favorites filter by handle through !inner
				// (ir decision-sink-no-fk).
				{ordinal: 2, name: "user_id", type: "uuid", ref: "app_user"},
				{ordinal: 3, name: "article_id", type: "uuid"},
				// false is how an upsert-only sink retracts.
				{ordinal: 4, name: "active", type: "bool"},
				{ordinal: 5, name: "favorited_at", type: "timestamp"},
			]
		}
	}
	// Parents before children: a `ref` emits REFERENCES and Postgres needs the
	// target table first; the three sinks last.
	state: entityOrder: ["AppUser", "Me", "Article", "ArticleTag", "Comment", "Favorite", "Bookmark", "Follow", "FavoriteCount", "ArticleStats", "TagCount", "FavoriteIndex"]

	state: pipelines: {
		// All three read absolutely (the CDC event triggers, never carries a
		// delta), union the event row's own key into the emitted set, and drop a
		// foreign message with root = deleted() rather than reasserting — because
		// merge-duplicates fires the txid restamp and would fan the whole sink out
		// on any unrelated crud event (ir decision-absolute-recount).
		"favorite-recount": {
			from:  "Favorite"
			to:    "ArticleStats"
			group: "realworld-favorite-recount"
			key:   "article_id"
			transform: {
				// txid rides along: the mapping emits the newest one it counted
				// as the sink's read watermark.
				aggregate: "select=article_id,txid,deleted_at"
				bloblang:  _favoriteRecountBlobl
			}
			// Browser tier + optimistic projection. The container keeps the
			// bloblang above; see #Pipeline.fold for why the two are not merged.
			fold: {
				projects:  "favorite_count"
				watermark: "counted_txid"
				dedupe: ["user_id", "article_id"]
				retracted: "deleted_at"
				pair: {
					table:   "favorite_count"
					counted: "mine_counted"
					total:   "total_at_read"
					asOf:    "as_of_txid"
				}
			}
		}
		"favorite-count": {
			from:  "Favorite"
			to:    "FavoriteCount"
			group: "realworld-favorite-count"
			// The pair is keyed on (reader, article) and carries `id`, so a
			// repeated read upserts the same row.
			key: "id"
			transform: {
				aggregate: "select=user_id,article_id,txid,deleted_at"
				bloblang:  _favoriteCountBlobl
			}
		}
		"favorite-index": {
			from:  "Favorite"
			to:    "FavoriteIndex"
			group: "realworld-favorite-index"
			// The grouping is by the (user_id, article_id) pair, which no single
			// source column names; `key` exists to switch the transform to array
			// mode and conflict on the sink pk, and the emitted rows carry `id`.
			key: "id"
			transform: {
				aggregate: "select=user_id,article_id,created_at,deleted_at"
				bloblang:  _favoriteIndexBlobl
			}
		}
		"tag-recount": {
			from:  "ArticleTag"
			to:    "TagCount"
			group: "realworld-tag-recount"
			key:   "tag"
			transform: {
				// Counted by set cardinality of distinct article_id, not row count.
				aggregate: "select=article_id,tag"
				bloblang:  _tagRecountBlobl
			}
		}
	}

	// Zero handlers: the only handler event source is drag and nothing here
	// reorders, so there is no SES compartment at all
	// (ir decision-escape-hatches). Every screen's files.handlers stays [].
	surface: handlers: {}

	surface: screens: {
		"home": {
			title: "Community"
			label: "nav_home"
			route: "/"
			ssr:   "ssr"
			forms: [
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					// No user_id (defaults auth_uid()), no id (client-minted), no
					// created_at (defaults now()).
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					// The retraction is a SIBLING of the probe carrying the filter: a
					// bare sibling deletes nothing (ir decision-probe-empty).
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
				// The search box is a navigate form (markup only):
				// data-form="search" data-action="navigate"
				// data-route="search" data-param-q="{q}" — flow search-articles.
			]
			states: ["loading", "empty", "populated", "favorited", "validation-error", "network-error", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			paths: {
				first_load: {states: ["loading", "populated"], accepts: ["accept-community-list", "accept-signin-handle", "accept-preview-complete"]}
				nothing_yet: {states: ["loading", "empty"], accepts: []}
				favorite: {states: ["populated", "favorited", "favorited"], accepts: ["accept-favorite-toggles"]}
				unfavorite: {states: ["favorited", "populated"], accepts: ["accept-favorite-toggles"]}
				double_press: {states: ["favorited", "validation-error"], accepts: ["accept-favorite-once"]}
				gateway_down: {states: ["loading", "network-error"], accepts: []}
				another_reader: {states: ["populated", "populated"], accepts: ["accept-favorite-live"]}
				popular_tags: {states: ["populated", "populated"], accepts: ["accept-tagcount-true"]}
				second_person: {states: ["loading", "populated"], accepts: ["accept-second-person"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"feed": {
			title: "Your Feed"
			label: "nav_feed"
			route: "/feed"
			ssr:   "spa"
			forms: [
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
			]
			states: ["loading", "empty", "populated", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			paths: {
				no_follows: {states: ["loading", "empty"], accepts: ["accept-feed-follows-only"]}
				follow_fills: {states: ["empty", "populated"], accepts: ["accept-follow-fills-feed"]}
				visit: {states: ["loading", "populated"], accepts: ["accept-feed-follows-only"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"reading-list": {
			// The strip's word is the control's word: you press Save, you find it
			// under Saved. It is also the short one, and the strip has to fit at
			// 400px (shell/shared/chrome.css).
			title: "Saved"
			label: "nav_reading_list"
			route: "/reading-list"
			ssr:   "spa"
			forms: [
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
			]
			states: ["loading", "empty", "populated", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			paths: {
				first_visit: {states: ["loading", "populated"], accepts: ["accept-reading-list", "accept-preview-complete"]}
				nothing_saved: {states: ["loading", "empty"], accepts: ["accept-reading-list-empty"]}
				unsave_here: {states: ["populated", "populated"], accepts: ["accept-save-toggles"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"editor": {
			title: "New Article"
			label: "nav_editor"
			route: "/editor"
			ssr:   "spa"
			forms: [
				{
					// Screen-level, outside every region. No author field, no slug
					// field, no date fields.
					id:     "publish"
					entity: "Article"
					action: "create"
					flow:   "publish-article"
					fields: [
						{name: "title", control: "text", required: true, maxLength: 200, placeholder: "Title", invalidMessage: "Give it a title."},
						{name: "description", control: "text", maxLength: 300, placeholder: "A one-line standfirst"},
						{name: "body", control: "textarea", required: true, placeholder: "Write your piece. Markdown works: # headings, **bold**, > quotes, `code`, - lists.", invalidMessage: "An article needs a body."},
						{name: "tags", control: "text", maxLength: 200, placeholder: "Tags, separated by spaces"},
						{name: "cover_url", control: "text", maxLength: 2048, placeholder: "Paste a link to a cover image"},
						{name: "cover_credit", control: "text", maxLength: 120, placeholder: "Who the picture belongs to (optional)"},
					]
				},
			]
			states: ["loading", "populated", "validation-error", "success", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			// The blank sheet is the point, so the screen rebuilds on every visit.
			keep: 0
			paths: {
				blank_sheet: {states: ["loading", "populated"], accepts: []}
				publish: {states: ["populated", "success"], accepts: ["accept-publish-lands"]}
				blank_refused: {states: ["populated", "validation-error"], accepts: ["accept-article-blank-refused"]}
				tags_file: {states: ["populated", "success"], accepts: ["accept-tags-file"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"settings": {
			title: "Settings"
			route: "/settings"
			ssr:   "spa"
			// Off the strip: it is reached from one's own page, which the strip
			// already leads to (ir decision-identity-chrome).
			strip: false
			forms: [
				{
					// No handle field, no id field, no sign-out button, no upload
					// control — the terminal owns that chrome
					// (ir decision-terminal-chrome).
					id:     "edit-profile"
					entity: "AppUser"
					action: "update"
					flow:   "edit-profile"
					fields: [
						{name: "display_name", control: "text", maxLength: 60, placeholder: "Your name"},
						{name: "bio", control: "textarea", maxLength: 300, placeholder: "A line about you"},
						{name: "image_url", control: "text", maxLength: 2048, placeholder: "https://… a link to your picture"},
					]
				},
			]
			states: ["loading", "populated", "success", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			paths: {
				open: {states: ["loading", "populated"], accepts: []}
				save: {states: ["populated", "success"], accepts: ["accept-profile-propagates"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"older": {
			title: "Older writing"
			route: "/older/:when"
			ssr:   "ssr"
			forms: [
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
			]
			states: ["loading", "populated", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			// A parametrized route otherwise accumulates one held screen per cursor
			// ever visited; three is the reader's plausible back-stack.
			keep: 3
			paths: {
				first_page: {states: ["loading", "populated"], accepts: ["accept-list-paged"]}
				beginning: {states: ["loading", "empty"], accepts: []}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"feed-older": {
			title: "Older in your feed"
			route: "/feed/older/:when"
			ssr:   "spa"
			forms: [
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
			]
			states: ["loading", "populated", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			keep: 3
			paths: {
				first_page: {states: ["loading", "populated"], accepts: ["accept-list-paged", "accept-feed-follows-only"]}
				beginning: {states: ["loading", "empty"], accepts: []}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"article": {
			title: "Article"
			route: "/article/:slug"
			ssr:   "ssr"
			forms: [
				{
					id:     "leave-comment"
					entity: "Comment"
					action: "create"
					flow:   "leave-comment"
					fields: [
						{name: "body", control: "textarea", required: true, maxLength: 2000, placeholder: "Say something about this piece.", invalidMessage: "Write something first."},
						// The form sits inside the article row and outside the comment
						// region, so {id} is the article's.
						{name: "article_id", control: "hidden", value: "{id}"},
					]
				},
				{
					// Row-scoped, so no filter: a plain sibling of the comment row's Me
					// probe (ir decision-probe-empty).
					id:     "remove-comment"
					entity: "Comment"
					action: "delete"
					flow:   "remove-comment"
					fields: []
				},
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
				{
					id:     "follow"
					entity: "Follow"
					action: "create"
					flow:   "follow-writer"
					fields: [{name: "followed_id", control: "hidden", value: "{author_id}"}]
				},
				{
					// Rendered as an outline "Following", never danger.
					id:     "unfollow"
					entity: "Follow"
					action: "delete"
					filter: "followed_id=eq.{author_id}"
					flow:   "unfollow-writer"
					fields: []
				},
				{
					// Row-scoped and armed by <details class="danger">: the second step
					// is markup, not a state.
					id:     "delete-article"
					entity: "Article"
					action: "delete"
					flow:   "delete-article"
					fields: []
				},
			]
			states: ["loading", "populated", "validation-error", "owner", "delete-armed", "no-comments", "gone", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			paths: {
				read: {states: ["loading", "populated"], accepts: ["accept-body-markdown"]}
				own_piece: {states: ["loading", "owner"], accepts: ["accept-author-only-controls"]}
				quiet_piece: {states: ["loading", "no-comments"], accepts: ["accept-comment-empty"]}
				first_comment: {states: ["no-comments", "populated"], accepts: ["accept-comment-add", "accept-comment-empty"]}
				blank_comment: {states: ["populated", "validation-error"], accepts: ["accept-comment-add"]}
				remove_comment: {states: ["populated", "populated"], accepts: ["accept-comment-remove"]}
				follow_from_byline: {states: ["populated", "populated"], accepts: ["accept-follow-state-true"]}
				confirm_delete: {states: ["owner", "delete-armed"], accepts: ["accept-delete-cascades"]}
				delete: {states: ["delete-armed", "gone"], accepts: ["accept-delete-cascades"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
			// The one screen that renders a body, and so the only one that
			// carries the markdown module (ir decision-markdown-capability).
			files: renderers: ["shell/renderers/markdown.js"]
		}
		"edit-article": {
			title: "Edit Article"
			route: "/editor/:id"
			ssr:   "spa"
			forms: [
				{
					id:     "revise"
					entity: "Article"
					action: "update"
					flow:   "revise-article"
					fields: [
						{name: "title", control: "text", required: true, maxLength: 200, placeholder: "Title", invalidMessage: "Give it a title."},
						{name: "description", control: "text", maxLength: 300, placeholder: "A one-line standfirst"},
						{name: "body", control: "textarea", required: true, placeholder: "Write your piece.", invalidMessage: "An article needs a body."},
						// Always submitted, even unchanged: the 013 trigger fires AFTER
						// UPDATE OF tags and guards on IS NOT DISTINCT FROM
						// (ir decision-article-tag-trigger).
						{name: "tags", control: "text", maxLength: 200, placeholder: "Tags, separated by spaces"},
						{name: "cover_url", control: "text", maxLength: 2048, placeholder: "Paste a link to a cover image"},
						{name: "cover_credit", control: "text", maxLength: 120, placeholder: "Who the picture belongs to (optional)"},
						{name: "updated_at", control: "hidden", value: "{now}"},
					]
				},
			]
			states: ["loading", "populated", "validation-error", "success", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			// The route renders for anyone who types it and the save is refused out
			// loud (ir decision-show-and-refuse); rebuilt on every visit so the
			// bound fields are the row's, never a held screen's.
			keep: 0
			paths: {
				open: {states: ["loading", "populated"], accepts: []}
				save: {states: ["populated", "success"], accepts: ["accept-edit-propagates"]}
				not_yours: {states: ["populated", "validation-error"], accepts: ["accept-author-only-controls"]}
				// The delete gesture lives on the article screen, so an open editor
				// learns of it the way any other session would: its one row leaves
				// the collection.
				piece_deleted: {states: ["populated", "empty"], accepts: []}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"profile": {
			title: "Profile"
			route: "/profile/:handle"
			ssr:   "ssr"
			forms: [
				{
					// Inherits Follow's row invariant, so one's own page refuses
					// (ir test-no-self-follow).
					id:     "follow"
					entity: "Follow"
					action: "create"
					flow:   "follow-writer"
					fields: [{name: "followed_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfollow"
					entity: "Follow"
					action: "delete"
					filter: "followed_id=eq.{id}"
					flow:   "unfollow-writer"
					fields: []
				},
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
			]
			states: ["loading", "populated", "following", "own-profile", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			keep: 2
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-profile-page"]}
				follow: {states: ["populated", "following"], accepts: ["accept-follow-fills-feed", "accept-follow-state-true"]}
				revisit_following: {states: ["loading", "following"], accepts: ["accept-follow-state-true"]}
				own_page: {states: ["loading", "own-profile"], accepts: ["accept-no-self-follow"]}
				unknown_handle: {states: ["loading", "empty"], accepts: []}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"profile-favorites": {
			title: "Favorited"
			route: "/profile/:handle/favorites"
			ssr:   "ssr"
			forms: [
				{
					id:     "follow"
					entity: "Follow"
					action: "create"
					flow:   "follow-writer"
					fields: [{name: "followed_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfollow"
					entity: "Follow"
					action: "delete"
					filter: "followed_id=eq.{id}"
					flow:   "unfollow-writer"
					fields: []
				},
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
			]
			states: ["loading", "populated", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-profile-page"]}
				none_yet: {states: ["loading", "empty"], accepts: []}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"tag": {
			title: "Tag"
			route: "/tag/:name"
			ssr:   "ssr"
			forms: [
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
			]
			states: ["loading", "populated", "empty", "populated-dark"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			keep: 3
			paths: {
				visit: {states: ["loading", "populated"], accepts: ["accept-tags-file"]}
				empty_tag: {states: ["loading", "empty"], accepts: ["accept-tag-empty"]}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
		"search": {
			title: "Search"
			route: "/search/:q"
			ssr:   "ssr"
			forms: [
				{
					id:     "favorite"
					entity: "Favorite"
					action: "create"
					flow:   "favorite-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unfavorite"
					entity: "Favorite"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unfavorite-article"
					fields: []
				},
				{
					id:     "save"
					entity: "Bookmark"
					action: "create"
					flow:   "save-article"
					fields: [{name: "article_id", control: "hidden", value: "{id}"}]
				},
				{
					id:     "unsave"
					entity: "Bookmark"
					action: "delete"
					filter: "article_id=eq.{id}"
					flow:   "unsave-article"
					fields: []
				},
			]
			states: ["loading", "populated", "empty", "populated-dark", "network-error"]
			files: shared: ["shell/shared/chrome.css", "shell/shared/system.css"]
			paths: {
				hit: {states: ["loading", "populated"], accepts: ["accept-search-finds"]}
				no_match: {states: ["loading", "empty"], accepts: ["accept-search-empty"]}
				gateway_down: {states: ["loading", "network-error"], accepts: []}
				appearance: {states: ["populated", "populated-dark"], accepts: ["accept-dual-appearance"]}
			}
		}
	}

	surface: flows: {
		// data-of "auth" in the ir: anchors the auth section, not a screen — the
		// door is terminal chrome. Ends in a read: home's Article list under the
		// fresh token.
		"sign-in": {of: "auth", entity: "Article", action: "navigate"}
		"publish-article": {of: "editor", entity: "Article", action: "create"}
		"revise-article": {of: "edit-article", entity: "Article", action: "update"}
		"delete-article": {of: "article", entity: "Article", action: "delete"}
		// The pill also rides feed, older, feed-older, article, tag, search,
		// profile and profile-favorites; home is the ir's data-of.
		"favorite-article": {of: "home", entity: "Favorite", action: "create"}
		"unfavorite-article": {of: "home", entity: "Favorite", action: "delete"}
		// The star rides every screen the pill does, and reading-list besides —
		// which is the ir's data-of, because it is the screen the flow exists for.
		"save-article": {of: "reading-list", entity: "Bookmark", action: "create"}
		"unsave-article": {of: "reading-list", entity: "Bookmark", action: "delete"}
		// The follow control also rides article and profile-favorites.
		"follow-writer": {of: "profile", entity: "Follow", action: "create"}
		"unfollow-writer": {of: "profile", entity: "Follow", action: "delete"}
		"leave-comment": {of: "article", entity: "Comment", action: "create"}
		"remove-comment": {of: "article", entity: "Comment", action: "delete"}
		"edit-profile": {of: "settings", entity: "AppUser", action: "update"}
		"search-articles": {of: "search", entity: "Article", action: "navigate"}
		"browse-tag": {of: "tag", entity: "Article", action: "navigate"}
		"read-older": {of: "older", entity: "Article", action: "navigate"}
	}

	meta: tests: {
		"test-signin-handle": {
			of: "auth"
			says: "One tap on the passkey, or one click on guest, yields a token whose bearer the community can name; the auth service inserts AppUser (id, handle) and the 014 trigger provisions Me in the same transaction, so the ownership probe answers on the first paint rather than after a CDC round trip."
			given: {gesture: "passkey"}
			when:  "signin"
			then:  "output.handle.size() > 0 && output.role == 'app_user' && output.sub == output.user_id && output.me.id == output.user_id"
		}
		"test-signout-return": {
			of: "auth"
			says: "Signing out clears the token and a store request made afterwards is refused rather than answered; signing back in re-issues the same sub, and because every article, follow and favorite is a Postgres row scoped by auth_uid() and nothing is client-local, the first loads return the state exactly as it was left."
			given: {token: null}
			when:  "signout"
			then:  "error.kind == 'unauthorized' && output == null"
		}
		"test-profile-propagates": {
			of: "AppUser"
			says: "Setting a display name, an about line and a picture writes one row and changes nothing else; because every byline, preview and comment embeds the author, the new name reaches every surface without a reload."
			given: {id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", handle: "velvet-crow-4", display_name: "Ana Vega", bio: "Writes about dragons and deadlines.", image_url: "https://example.org/ana.jpg"}
			when:  "update"
			then:  "output.display_name == input.display_name && output.bio == input.bio && output.image_url == input.image_url && output.handle == input.handle && output.id == input.id"
		}
		"test-handle-not-writable": {
			of: "AppUser"
			says: "A PATCH naming handle is refused even on one's own row — the 011 column grant excludes it — and the other three columns are unchanged; a PATCH against somebody else's row is refused by the policy. Both arms fail independently, so neither masks the other."
			given: {id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", handle: "velvet-crow-4", display_name: "Ana Vega", submitted_handle: "ana"}
			when:  "update"
			then:  "error.kind == 'rls_denied' && output.handle == input.handle && output.display_name == input.display_name"
		}
		"test-me-scoped": {
			of: "Me"
			says: "The me read returns exactly one row under its own token and nothing under anybody else's, which is what makes an empty probe region mean 'not mine'; every write against it is refused, because 012 drops the arms that owned emits."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38"}
			when:  "query"
			then:  "output.size() == 1 && output[0].id == input.user_id"
		}
		"test-publish-lands": {
			of: "Article"
			says: "Publishing stamps both clocks, takes the author from the token, and generates a readable address; the piece is at the head of the community list at once, and the editor's own local read carries the landing link as soon as the row settles."
			given: {title: "On writing", body: "# hi", tags: "craft"}
			when:  "create"
			then:  "output.created_at == input.now && output.updated_at == input.now && output.author_id == input.user_id && output.slug.size() > 0"
		}
		"test-article-blank-refused": {
			of: "Article"
			says: "A title-less or body-less piece is refused at the column CHECK and nothing is saved; whitespace is refused identically because the SQL mirrors over btrim, while a missing description and missing tags publish cleanly."
			given: {title: "", body: "words"}
			when:  "create"
			then:  "error.kind == 'check_violation' && error.field == 'title' && output == null"
		}
		"test-slug-readable": {
			of: "Article"
			says: "The address is the slugified title plus the first hex group of the row's own uuid, so two same-titled pieces get different addresses and a title with no letters still yields a readable stem; the unique index is the backstop."
			given: {title: "How to Train Your Dragon!"}
			when:  "create"
			then:  "output.slug.matches('^[a-z0-9]+(-[a-z0-9]+)*-[0-9a-f]{8}$') && output.slug.startsWith('how-to-train-your-dragon-')"
		}
		"test-retitle-readdresses": {
			of: "Article"
			says: "Retitling changes the address and the update stamp and nothing else; the piece keeps its id and its creation time, every list re-renders the new title, and the old address finds nothing — which is why the edit route is keyed on the id."
			given: {id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13", slug: "market-run-9d2f6c81", created_at: "2026-07-30T10:00:00Z", title: "Market run, revisited"}
			when:  "update"
			then:  "output.id == input.id && output.slug != input.slug && output.created_at == input.created_at && output.updated_at == input.now"
		}
		"test-author-only-writes": {
			of: "Article"
			says: "The author's save lands; anybody else's is refused by the 011 policy and the row is untouched — title, body and update stamp all as they were. Delete behaves the same way, which is what makes the hand-typed edit route safe to render."
			given: {id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13", title_before: "Market run", body_before: "Saturday, before ten.", updated_at_before: "2026-07-30T10:00:00Z"}
			when:  "update"
			then:  "error.kind == 'rls_denied' && output.row.title == input.title_before && output.row.body == input.body_before && output.row.updated_at == input.updated_at_before"
		}
		"test-delete-cascades": {
			of: "Article"
			says: "Deleting a piece takes its comments, favorites and tag pairs with it by FK cascade, and it leaves the community list, the feed, its tag pages, its author's profile and search together; the sinks carry no FK, so the final zero rows they receive name a dead article without wedging the stream."
			given: {id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "delete"
			then:  "output.comments == [] && output.favorites == [] && output.article_tags == [] && output.community.all(a, a.id != input.id)"
		}
		"test-tags-file": {
			of: "ArticleTag"
			says: "The typed line splits on runs of non-tag characters, lower-cases, keeps intra-word hyphens and drops empties and duplicates, so three words in are three pairs out; each pair puts the piece on that tag's page."
			given: {tags: "dragons  Training,, how-to"}
			when:  "create"
			then:  "output.size() == 3 && output.exists(t, t.tag == 'dragons') && output.exists(t, t.tag == 'training') && output.exists(t, t.tag == 'how-to') && output.all(t, output.filter(u, u.tag == t.tag).size() == 1)"
		}
		"test-retag-exact": {
			of: "ArticleTag"
			says: "Retagging leaves exactly the pairs the new line names — the 013 trigger deletes and reinserts inside the article's own transaction — while a title-only save leaves the pairs untouched, because the trigger guards on IS NOT DISTINCT FROM and the revise form always submits tags."
			given: {tags_before: "dragons training how-to", tags: "dragons how-to"}
			when:  "update"
			then:  "output.size() == 2 && output.all(t, t.tag in ['dragons', 'how-to'])"
		}
		"test-comment-add": {
			of: "Comment"
			says: "A comment takes its article from the hidden field, its author from the token and its time from the clock; it appears at the end of the oldest-first list at once, for the writer and for everyone else reading the piece."
			given: {article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13", body: "This is the piece I needed today.", id: "c1a4e7b2-5d38-4f60-9c11-2e8a7b3d4f05"}
			when:  "create"
			then:  "output.article_id == input.article_id && output.author_id == input.user_id && output.created_at == input.now && output.body == input.body"
		}
		"test-comment-blank-refused": {
			of: "Comment"
			says: "An empty or whitespace-only comment is refused at the column CHECK, which mirrors over btrim, and nothing is saved; the screen says so in the validation frame."
			given: {body: "   "}
			when:  "create"
			then:  "error.kind == 'check_violation' && error.field == 'body' && output == null"
		}
		"test-comment-remove": {
			of: "Comment"
			says: "The writer's × removes the comment and the list closes over it; anybody else's delete is refused and the comment stays. There is no UPDATE arm at all, so a comment can be withdrawn but never quietly rewritten."
			given: {id: "c1a4e7b2-5d38-4f60-9c11-2e8a7b3d4f05"}
			when:  "delete"
			then:  "error == null && output.comments.all(c, c.id != input.id)"
		}
		"test-comment-order-empty": {
			of: "article"
			says: "Comments read oldest-first over every adjacent pair, so a conversation reads down the page; a piece nobody has answered resolves to the empty collection without erroring and the region draws its own invitation."
			given: {article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "query"
			then:  "range(output.size() - 1).all(i, output[i].created_at <= output[i + 1].created_at)"
		}
		"test-favorite-toggles": {
			of: "Favorite"
			says: "A favorite is one private row taking its owner from the token; the per-card probe fills at once and the pill flips to its set arm, and retracting empties the probe again — the article row itself is never touched."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "create"
			then:  "output.user_id == input.user_id && output.article_id == input.article_id && output.created_at == input.now && output.probe.size() == 1"
		}
		"test-favorite-once": {
			of: "Favorite"
			says: "A second favorite for the same pair inside the optimistic window is refused by the composite unique index, and one row remains afterwards; the refusal is reachable because Caddy's injected ignore-duplicates targets the primary key, which a client-minted uuid never collides on."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "create"
			then:  "error.kind == 'unique_violation' && error.field == 'uq_favorite_pair'"
		}
		"test-save-toggles": {
			of: "Bookmark"
			says: "A save inserts one owned row and the star fills on the press rather than after the write lands, because the per-card probe is a local read over rows RLS has already narrowed to mine; pressing again deletes through the same filter and the star empties. Nothing else on the card moves — a save has no count, so no other reader's screen changes."
			given: {article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "create"
			then:  "output.user_id == input.auth_uid && output.article_id == input.article_id && output.created_at != null"
		}
		"test-save-once": {
			of: "Bookmark"
			says: "A second save for the same pair is refused by uq_bookmark_pair and one row remains, on the same path a repeated favorite takes: Caddy's injected ignore-duplicates targets the primary key, which a client-minted uuid never collides on, so the composite index is what answers."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "create"
			then:  "error.kind == 'unique_violation' && error.field == 'uq_bookmark_pair'"
		}
		"test-reading-list-private": {
			of: "Bookmark"
			says: "A reading list read that names no reader still returns exactly one reader's saves: bookmark is owned on user_id, so the SELECT policy is the filter and a second person's list is a different list under the identical request. There is no derived face to leak through either — unlike a favorite, a save feeds no sink and no count."
			given: {as: "second_person"}
			when:  "read"
			then:  "output.all(r, r.user_id == input.auth_uid)"
		}
		"test-favorite-private": {
			of: "Favorite"
			says: "Every favorite row a person can read is their own — absent from the result, not filtered client-side — which is what makes the per-card probe answer 'have I favorited it' rather than 'has anyone'."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", other_favorite_id: "f4b7a9e0-1d13-4c20-8e57-5f9d2f6c8103"}
			when:  "query"
			then:  "output.all(f, f.user_id == input.user_id) && output.all(f, f.id != input.other_favorite_id)"
		}
		"test-no-self-follow": {
			of: "Follow"
			says: "Following oneself is refused at the table CHECK, so the control on one's own profile cannot produce a row even if it is reached; the own-page frame hides it in the first place, on the strength of the Me probe."
			given: {follower_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", followed_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38"}
			when:  "create"
			then:  "error.kind == 'check_violation' && output == null"
		}
		"test-follow-state-true": {
			of: "Follow"
			says: "The follow probe is RLS-narrowed to one's own rows and answers one or zero, so the byline and the profile header show the same state on a fresh visit as they did right after the tap; a duplicate follow is refused by the composite unique index."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", follows_them: true}
			when:  "query"
			then:  "output.all(f, f.follower_id == input.user_id) && output.size() == (input.follows_them ? 1 : 0)"
		}
		"test-follow-fills-feed": {
			of: "feed"
			says: "The feed read names no reader and still returns exactly the pieces by people one follows: !inner drops parents with empty child sets and RLS narrows follow to the reader's own rows. Following a third writer fills the feed with their pieces, unfollowing empties it again, and no follows at all resolves to the empty collection without erroring."
			given: {b_id: "7a4c5e0b-1d38-4f21-8f52-3c1f7a529b0e", b_articles: [{title: "Market run"}, {title: "On writing"}]}
			when:  "query"
			then:  "output.size() == input.b_articles.size() && output.all(a, a.author_id == input.b_id)"
		}
		"test-favorite-recount-groups": {
			of: "favorite-recount"
			says: "The transform emits one absolute row per article, identical on any duplicate delivery; the live path carries the new count to every surface the article appears on, without a reload."
			given: {favorites: [
				{article_id: "A", user_id: "u1"},
				{article_id: "A", user_id: "u2"},
				{article_id: "B", user_id: "u1"},
			]}
			when: "recount"
			then: "output.exists(r, r.article_id == 'A' && r.favorite_count == 2) && output.exists(r, r.article_id == 'B' && r.favorite_count == 1)"
		}
		"test-favorite-recount-splits": {
			of: "favorite-recount"
			says: "The monoid law the optimistic projection rests on: folding a set whole equals folding two halves and combining them, which is what lets the screen show a total the sink has never held."
			given: {favorites: [
				{article_id: "A", user_id: "u1"},
				{article_id: "A", user_id: "u2"},
				{article_id: "A", user_id: "u3"},
			]}
			when: "recount"
			then: "output.exists(r, r.article_id == 'A' && r.favorite_count == 3)"
		}
		"test-favorite-recount-zero": {
			of: "favorite-recount"
			says: "Delete-to-zero boundary: the last favorite's delete event carries its article_id, the union makes the transform emit the zero row anyway, overwriting the stale final count; replaying the delete emits the identical zero row."
			given: {favorites: [], event: {article_id: "A", user_id: "u1"}}
			when:  "recount"
			then:  "output.exists(r, r.article_id == 'A' && r.favorite_count == 0)"
		}
		"test-favorite-index-cross-user": {
			of: "favorite-index"
			says: "A private favorite becomes a public index row keyed on the pair, carrying the time it happened so the favorited list can order by it; every emitted object carries the same five keys, because PostgREST rejects a bulk insert whose objects disagree on their key set."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13", created_at: "2026-08-01T09:00:00Z"}
			when:  "recount"
			then:  "output.exists(r, r.id == input.user_id + ':' + input.article_id && r.active == true && r.favorited_at == input.created_at) && output.all(r, has(r.id) && has(r.user_id) && has(r.article_id) && has(r.active) && has(r.favorited_at))"
		}
		"test-favorite-index-retracts": {
			of: "favorite-index"
			says: "An upsert-only sink retracts by writing active false for the pair the triggering event named, repeating that pair's own columns rather than patching; the favorited list filters on active, so the preview leaves at once."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "recount"
			then:  "output.exists(r, r.id == input.user_id + ':' + input.article_id && r.active == false)"
		}
		"test-tag-recount-distinct": {
			of: "tag-recount"
			says: "The transform counts by set cardinality of distinct article ids wearing each tag, not by row count, so the popular-tags rail states how many pieces a word is on rather than how many pairs exist."
			given: {article_tags: [
				{article_id: "A", tag: "dragons"},
				{article_id: "B", tag: "dragons"},
				{article_id: "A", tag: "training"},
			]}
			when: "recount"
			then: "output.exists(r, r.id == 'dragons' && r.article_count == 2) && output.exists(r, r.id == 'training' && r.article_count == 1)"
		}
		"test-tag-recount-zero": {
			of: "tag-recount"
			says: "The last piece to shed a tag drives its count to zero through the union of the triggering event's own tag, and the rail's article_count=gt.0 filter drops the word from the panel rather than showing a zero."
			given: {article_tags: [], event: {article_id: "A", tag: "dragons"}}
			when:  "recount"
			then:  "output.exists(r, r.id == 'dragons' && r.article_count == 0) && output.panel.all(r, r.article_count > 0)"
		}
		"test-stats-shared-and-zero": {
			of: "ArticleStats"
			says: "The count is public and shared: two readers see the same number for the same piece, an article with no sink row yet renders zero from the region's data-empty-row, and both arms of the pill carry the same value because both are siblings of the Favorite probe."
			given: {article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "query"
			then:  "output.a.favorite_count == output.b.favorite_count && output.rendered.set_arm.favorite_count == output.rendered.unset_arm.favorite_count && output.rendered.set_arm.favorite_count == output.a.favorite_count"
		}
		"test-community-newest-first": {
			of: "home"
			says: "The community list is everything anyone has published, newest first over every adjacent pair and independent of who one follows; an empty community resolves to the empty collection without erroring and the screen draws its invitation."
			given: {articles: [{title: "On writing"}, {title: "Market run"}, {title: "Dragons"}], follows: []}
			when:  "query"
			then:  "output.size() == 3 && range(output.size() - 1).all(i, output[i].created_at >= output[i + 1].created_at)"
		}
		"test-preview-complete": {
			of: "home"
			says: "Every preview carries a byline, a date, a title, its tags and its count — the one shared fragment on eight screens; a writer with no display name and no picture falls back to the handle with no conditional, because the empty name element hides itself."
			given: {author: {handle: "velvet-crow-4", display_name: null, image_url: null}}
			when:  "query"
			then:  "output.all(a, has(a.author.handle) && a.author.handle.size() > 0 && has(a.created_at) && a.title.size() > 0 && has(a.tags) && has(a.favorite_count))"
		}
		"test-second-person": {
			of: "home"
			says: "Two people see the same community list and different private state: the feed is narrowed by one's own follows and the favorite probes by one's own favorites, all in the store rather than in the screen."
			given: {a_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", b_id: "7a4c5e0b-1d38-4f21-8f52-3c1f7a529b0e"}
			when:  "query"
			then:  "output.b.community == output.a.community && output.b.feed.all(a, output.b.follows.exists(f, f.followed_id == a.author_id)) && output.a.favorites.all(f, f.user_id == input.a_id)"
		}
		"test-dual-appearance": {
			of: "home"
			says: "Every Press token carries a light and a dark value under the same name, and no screen stylesheet writes a hex or binds a font outside a role class, so switching the device appearance re-resolves tokens with no state change and no reload."
			given: {
				tokens: [
					{name: "neutral", light: "#FBFAF7", dark: "#131414"},
					{name: "accent", light: "#1D6A4F", dark: "#63BE95"},
				]
				screen_css: ["background: var(--surface);", ".role-display-md { font-family: var(--font-display-md); }"]
			}
			when: "query"
			then: "input.tokens.all(t, t.light != '' && t.dark != '') && input.screen_css.all(r, !r.matches('#[0-9a-fA-F]{3,8}'))"
		}
		"test-list-paged": {
			of: "older"
			says: "A long list stops at twenty and the twentieth card carries the cursor; the next page holds the remainder, strictly older than the cursor and disjoint from the first, still newest-first over every adjacent pair, and the beginning of the archive resolves empty without erroring."
			given: {articles_total: 25, when: "2026-07-30T10:00:00Z"}
			when:  "query"
			then:  "output.size() == 20 && range(output.size() - 1).all(i, output[i].created_at >= output[i + 1].created_at)"
		}
		"test-body-markdown": {
			of: "article"
			says: "An article body authored in markdown renders as elements — headings, emphasis, links, lists, quotes and code — through the app's own renderer module, set at a reading measure of sixty to seventy characters."
			given: {body: "## Heading\n\n**bold** and *italic*, a [link](https://example.org), \n\n- one\n- two\n\n> quoted\n\n```\ncode\n```\n"}
			when:  "query"
			then:  "output.elements.exists(e, e.tag == 'h2') && output.elements.exists(e, e.tag == 'strong') && output.elements.exists(e, e.tag == 'em') && output.elements.exists(e, e.tag == 'a') && output.elements.exists(e, e.tag == 'ul') && output.elements.exists(e, e.tag == 'blockquote') && output.elements.exists(e, e.tag == 'pre') && output.measure_ch >= 60 && output.measure_ch <= 70"
		}
		"test-body-safe": {
			of: "article"
			says: "The stored body is byte-identical to what was typed and markup in it renders as text, because the renderer builds nodes with createElement and textContent and never innerHTML; a link whose scheme is outside the allowlist renders as text too, while an https link becomes an anchor."
			given: {body: "<script>alert(1)</script> <b>bold?</b>"}
			when:  "query"
			then:  "output.body == input.body && output.text.contains('<script>') && output.elements.all(e, e.tag != 'script' && e.tag != 'b')"
		}
		"test-owner-controls-contrast": {
			of: "article"
			says: "One's own piece offers edit, delete and the count; somebody else's offers follow and favorite. Both offer the favorite pill — an author may favorite their own piece — and delete is armed in two steps before it can fire."
			given: {article_id: "9d2f6c81-1b3a-4e57-8c20-5f4b7a9e0d13"}
			when:  "query"
			then:  "output.owner.controls == ['edit', 'delete', 'count'] && output.reader.controls == ['follow', 'favorite'] && output.owner.delete_requires_arming == true"
		}
		"test-editor-blank-sheet": {
			of: "editor"
			says: "The editor rebuilds on every visit, so the sheet is always blank — no held screen carrying the last draft; the writing-as line reads from the one-row Me region beside it."
			given: {keep: 0}
			when:  "query"
			then:  "input.keep == 0 && output.fields.all(f, f.value == '')"
		}
		"test-settings-own-row": {
			of: "settings"
			says: "The settings form is bound to the signed-in person's own app_user row, reached through the Me region, so the fields open carrying what is already there rather than empty."
			given: {user_id: "3c1f7a52-9b0e-4d6a-8f21-7a4c5e0b1d38", display_name: "Ana Vega"}
			when:  "query"
			then:  "output.form_row.id == input.user_id && output.display_name_value == input.display_name"
		}
		"test-profile-page": {
			of: "profile"
			says: "A profile is one person's header plus exactly their writing, newest first; the favorited tab is the index sink filtered by handle through an inner embed and ordered by the moment of favoriting, each row's preview read live so a retitled piece reads correctly there too."
			given: {handle: "velvet-crow-4"}
			when:  "query"
			then:  "output.header.size() == 1 && output.header[0].handle == input.handle && output.articles.all(a, a.author.handle == input.handle) && output.favorited.all(r, r.user.handle == input.handle && r.active == true)"
		}
		"test-tag-list-exact": {
			of: "tag"
			says: "A tag page returns exactly the pieces wearing that word and nothing else, reached through an inner embed on the pair table; the heading is the word itself with its hash."
			given: {name: "dragons", tags: {A: ["dragons", "training"], B: ["dragons"]}}
			when:  "query"
			then:  "output.size() == 2 && output.all(a, input.tags[a.id].exists(t, t == 'dragons'))"
		}
		"test-tag-empty": {
			of: "tag"
			says: "A tag page nothing is filed under resolves to the empty collection without erroring and draws its own designed frame — never a blank, never network-error — which is the state a tag reaches when the last piece wearing it is retagged or deleted."
			given: {name: "dragons", article_tags: []}
			when:  "query"
			then:  "output == [] && error == null"
		}
		"test-search-finds": {
			of: "search"
			says: "Title, description or body is enough — the generated tsvector concatenates all three — and multi-word input is taken as plain words through plfts, never tsquery syntax, so a two-word query finds the piece instead of erroring into network-error."
			given: {q: "market run", articles: [{title: "Market run"}, {description: "a market day"}, {body: "the market at dawn"}]}
			when:  "search"
			then:  "output.exists(a, a.title == 'Market run')"
		}
		"test-search-empty": {
			of: "search"
			says: "A query matching nothing returns the empty collection without erroring and the screen says so plainly — a designed empty frame, not a blank and not network-error."
			given: {q: "attic keys", articles: []}
			when:  "search"
			then:  "output == [] && error == null"
		}
	}

	meta: decisions: {
		"decision-auth-deviation": {}
		"decision-public-read-owner-writes": {}
		"decision-me-row": {}
		"decision-probe-empty": {}
		"decision-show-and-refuse": {}
		"decision-favorite-private-derived": {}
		"decision-feed-read": {}
		"decision-follow-single-fk": {}
		"decision-slug": {}
		"decision-article-tag-trigger": {}
		"decision-absolute-recount": {}
		"decision-sink-keys": {}
		"decision-sink-no-fk": {}
		"decision-composite-uniques": {}
		"decision-updated-at-hidden-now": {}
		"decision-cover-link": {}
		"decision-publish-checklist": {}
		"decision-earlier-strip": {}
		"decision-reading-time": {}
		"decision-author-card": {}
		"decision-markdown-capability": {}
		"decision-comment-plain-text": {}
		"decision-feed-route": {}
		"decision-one-row-list": {}
		"decision-paging-keyset": {}
		"decision-publish-lands-one-tap": {}
		"decision-edit-route-by-id": {}
		"decision-preview-one-component": {}
		"decision-terminal-chrome": {}
		"decision-browser-tier-unsupported": {}
		"decision-optimistic-fold": {}
		"decision-design-identity": {}
		"decision-identity-chrome": {}
		"decision-escape-hatches": {}
		"decision-bookmark-no-public-face": {}
		"decision-cover-credit": {}
		"decision-narrow-recount": {}
		"decision-optimistic-count": {}
		"decision-reading-progress": {}
	}
}

// Inlined because rpk's bloblang processor cannot reference a file; @embed is
// legal only within the package's own directory subtree.
_favoriteRecountBlobl: _ @embed(file="pipelines/favorite-recount.blobl", type=text)
_favoriteCountBlobl:   _ @embed(file="pipelines/favorite-count.blobl", type=text)
_favoriteIndexBlobl:  _ @embed(file="pipelines/favorite-index.blobl", type=text)
_tagRecountBlobl:     _ @embed(file="pipelines/tag-recount.blobl", type=text)

// The app package's components: code above, the runtime pair, the loop —
// defaulted; no hatch unifies onto the cluster (ir decision-escape-hatches),
// so bayt.cue's redeclaration is the untouched human override seam.
terminal: (pronto.#DefaultTerminal & {"code": code}).out
// The markdown module is the app's own code, so the app is what puts it on
// the terminal's serving surface — the same unification a hatch uses onto the
// cluster. The compiler never learns the word.
terminal: surface: renderers: ["shell/renderers/markdown.js"]
cluster: (pronto.#DefaultCluster & {"code": code, statics: terminal.surface.statics}).out

loop: (pronto.#DefaultLoop & {"code": code, "cluster": cluster, "terminal": terminal}).out

// The article screen mounted whole on a clock the test steps. It is the app's
// only parametrized route with a subject, and the visual battery fills route
// params with slugs no fixture row carries — so every value this screen derives
// from a row, and every region that interpolates {id} or {created_at} out of
// it, is invisible above this tier.
loop: surface: checks: "article": {
	verb: "test"
	cmds: [
		"deno test --config tests/deno.json --no-lock --no-check --allow-env --allow-read tests/article.test.ts",
	]
	note: "the slug's own piece: nested regions, the earlier cursor, the markdown renderer, gone against empty"
}

// The stream mounted whole. A photograph cannot say whether the element in it
// is the same object it was before a row arrived, which is the whole question
// keyed reconciliation answers.
loop: surface: checks: "home": {
	verb: "test"
	cmds: [
		"deno test --config tests/deno.json --no-lock --no-check --allow-env --allow-read tests/home.test.ts",
	]
	note: "the capped, tie-broken stream, per-row sub-regions, and node identity across an arrival"
}

// No other rung writes a row and reads back what the pipelines made of it,
// and both of their watermarks are int64 carriers.
loop: surface: checks: "favorites": {
	verb: "integrate"
	priority: 1
	cmds: [
		"deno run --config tests/deno.json --no-lock --allow-env --allow-read --allow-run --allow-net --unsafely-ignore-certificate-errors=localhost tests/favorites.ts .",
	]
	note: "a favourite is counted and paired by the two pipelines with int64 watermarks, and its retraction moves the count's watermark forward"
}

loop: surface: checks: "editor": {
	verb: "test"
	cmds: [
		"deno test --config tests/deno.json --no-lock --no-check --allow-env --allow-read tests/editor.test.ts",
	]
	note: "the blank sheet: author from me region, form validation, and article publish create mutation"
}

build: (pronto.#DefaultBuild & {"code": code, "loop": loop, "cluster": cluster}).out

out: pronto.#emit & {"code": code, "cluster": cluster, "terminal": terminal, "loop": loop, "build": build}
