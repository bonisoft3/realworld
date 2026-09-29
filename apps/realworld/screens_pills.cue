// The preview pill pair, once: every list screen's favorite and save arms
// share this markup, interpolated into the screens_*.cue markup at the depth
// each screen authors. The arms wrapper and the save-arm design note stay in
// each screen's own markup — this file owns only the probe-and-form pairs.
//
// Hand-authored rather than an instance of omnishell--toggle-flag
// (plugins/omnishell/components/toggle-flag.cue): that component writes its
// `label`/`aria`/`words` strings as literal DOM text with no data-text (or,
// for `words`, no binding at all) to carry a {msg.*} reference — an
// attribute carrying `{...}` is interpolated by the binder on ANY attribute
// name (interpreter/screen.js bindElementAttributes), but a text NODE is
// only ever interpolated where the element wears data-text
// (interpreter/screen.js bindTexts). label and words are neither: they are
// the button's and the refusal paragraph's own child text, so a value like
// "{msg.save_label_off}" placed there renders as that literal brace string,
// which is worse than the English it replaced. Reproducing the component's
// exact classes, form ids, filters and retraction algebra by hand — with
// each text-bearing node wrapped in its own data-text span, and each
// accessible-name string moved into an aria-label attribute instead of
// sr-only text where the direction has no visible face — is what lets the
// pill speak fifteen languages without touching plugins/. The component could
// own this instead — it would have to emit a data-text span per text node and
// an aria-label where a direction has no visible face — and until it does, the
// cost of the copy is that a defect fixed there is not fixed here.
package realworld

_favPill: {
	indent: *"            " | string
	markup: "\(indent)<span class=\"fav-probe\" data-live=\"favorite\" data-filter=\"article_id=eq.{id}&deleted_at=is.null\">\n" +
		"\(indent)  <template data-item><i></i></template>\n" +
		"\(indent)</span>\n" +
		"\(indent)<form class=\"when-unset\" data-form=\"favorite\" data-entity=\"favorite\" data-action=\"upsert\">\n" +
		"\(indent)  <input type=\"hidden\" name=\"article_id\" data-value=\"{id}\">\n" +
		"\(indent)  <input type=\"hidden\" name=\"deleted_at\" data-value=\"null\">\n" +
		"\(indent)  <button class=\"pill role-meta-sm\" type=\"submit\"><span class=\"sr-only\" data-text=\"{msg.favorite_aria_off}\"></span><span class=\"sr-only\"> — </span>♡\n" +
		"\(indent)    <span class=\"count\" data-live=\"article_stats\" data-filter=\"article_id=eq.{id}\" data-empty-row='{\"favorite_count\":0}' data-text=\"{favorite_count}\">0</span>\n" +
		"\(indent)  </button>\n" +
		"\(indent)  <p class=\"invalid role-meta-sm\" hidden data-text=\"{msg.favorite_failed}\">That favourite didn't go through — try again.</p>\n" +
		"\(indent)  <p class=\"store-error role-meta-sm\" hidden data-text=\"{msg.favorite_failed}\">That favourite didn't go through — try again.</p>\n" +
		"\(indent)</form>\n" +
		"\(indent)<form class=\"when-set\" data-form=\"unfavorite\" data-entity=\"favorite\" data-action=\"upsert\">\n" +
		"\(indent)  <input type=\"hidden\" name=\"article_id\" data-value=\"{id}\">\n" +
		"\(indent)  <input type=\"hidden\" name=\"deleted_at\" data-value=\"{now}\">\n" +
		"\(indent)  <button class=\"pill set role-meta-sm\" type=\"submit\"><span class=\"sr-only\" data-text=\"{msg.favorite_aria_on}\"></span><span class=\"sr-only\"> — </span>♥\n" +
		"\(indent)    <span class=\"count\" data-live=\"article_stats\" data-filter=\"article_id=eq.{id}\" data-empty-row='{\"favorite_count\":0}' data-text=\"{favorite_count}\">0</span>\n" +
		"\(indent)  </button>\n" +
		"\(indent)  <p class=\"invalid role-meta-sm\" hidden data-text=\"{msg.retract_failed}\">That didn't come back — try again.</p>\n" +
		"\(indent)  <p class=\"store-error role-meta-sm\" hidden data-text=\"{msg.retract_failed}\">That didn't come back — try again.</p>\n" +
		"\(indent)</form>"
}

_savePill: {
	indent: *"            " | string
	markup: "\(indent)<span class=\"save-probe\" data-live=\"bookmark\" data-filter=\"article_id=eq.{id}\">\n" +
		"\(indent)  <template data-item><i></i></template>\n" +
		"\(indent)</span>\n" +
		"\(indent)<form class=\"when-unsaved\" data-form=\"save\" data-entity=\"bookmark\" data-action=\"create\">\n" +
		"\(indent)  <input type=\"hidden\" name=\"article_id\" data-value=\"{id}\">\n" +
		"\(indent)  <button class=\"mark role-meta-sm\" type=\"submit\" aria-label=\"{msg.save_aria_off}\"><span data-text=\"{msg.save_label_off}\">Save</span></button>\n" +
		"\(indent)  <p class=\"invalid role-meta-sm\" hidden data-text=\"{msg.save_failed}\">That save didn't take — try again.</p>\n" +
		"\(indent)  <p class=\"store-error role-meta-sm\" hidden data-text=\"{msg.save_failed}\">That save didn't take — try again.</p>\n" +
		"\(indent)</form>\n" +
		"\(indent)<form class=\"when-saved\" data-form=\"unsave\" data-entity=\"bookmark\" data-action=\"delete\" data-filter=\"article_id=eq.{id}\">\n" +
		"\(indent)  <button class=\"mark set role-meta-sm\" type=\"submit\" aria-label=\"{msg.save_aria_on}\"><span data-text=\"{msg.save_label_on}\">Saved</span></button>\n" +
		"\(indent)  <p class=\"invalid role-meta-sm\" hidden data-text=\"{msg.retract_failed}\">That didn't come back — try again.</p>\n" +
		"\(indent)  <p class=\"store-error role-meta-sm\" hidden data-text=\"{msg.retract_failed}\">That didn't come back — try again.</p>\n" +
		"\(indent)</form>"
}

// profile-favorites nests its previews one region deeper.
_favPillDeep: _favPill & {indent: "                  "}
_savePillDeep: _savePill & {indent: "                  "}
