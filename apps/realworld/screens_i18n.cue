// The language picker, once: every screen instantiates it with its own route
// name and the :params that route's pattern takes, the same pattern
// screens_pills.cue uses for the favorite/save arms. It re-addresses the SAME
// screen under a chosen locale — data-locale is the binder's own hook for
// exactly this (interpreter/screen.js: "data-locale is how a language switcher
// links to the page it is on in another language").
//
// It is app markup and not chrome because the strip above it is the terminal's
// own: interpreter/shell.js builds that <nav> from each route's nav.label and
// appends the identity to it, and it takes no app element. So the picker takes
// the nearest surface this app does own — the first row of its own screen,
// pinned to the inline end, which is where an app-wide setting belongs and is
// where the reader's eye already goes for the identity above it.
package realworld

import "strings"

// Endonym, not the English name: each language names itself, in its own
// script. The message key beside it carries the identical string in every
// locale's catalogue — the name of German does not change because the
// reader is Japanese — which is also what lets checkPseudoLocale (every
// catalogue-derived string must render decorated) grade it like any other
// piece of copy instead of flagging it as unlocalized prose.
#Locale: {
	tag:  string
	key:  string
	name: string

	// A name in a right-to-left script carries dir on the NAME alone, isolated
	// in CSS, so the script runs in its own direction inside a row shaped like
	// every other row — the whole row turning around is the layout bug this
	// replaces. The thirteen left-to-right names carry no attribute at all
	// rather than a spelled-out "ltr" that would say nothing.
	dir:  *"" | "rtl"
	attr: string
	if dir == "" {
		attr: ""
	}
	if dir != "" {
		attr: #" dir="\#(dir)""#
	}
}

// Latin endonyms A→Z, then the remaining scripts in Unicode code-point order —
// a rule a reader can re-derive from the list, so an added language has one
// place to go. Which entry the reader is currently in is not decided here: the
// interpreter marks that row and the menu pins it, because it is a property of
// the address, not of this table.
_LOCALES: [...#Locale] & [
	{tag: "id", key: "lang_id", name: "Bahasa Indonesia"},
	{tag: "de", key: "lang_de", name: "Deutsch"},
	{tag: "en", key: "lang_en", name: "English"},
	{tag: "es", key: "lang_es", name: "Español"},
	{tag: "fr", key: "lang_fr", name: "Français"},
	{tag: "sw", key: "lang_sw", name: "Kiswahili"},
	{tag: "pt", key: "lang_pt", name: "Português"},
	{tag: "tr", key: "lang_tr", name: "Türkçe"},
	{tag: "ru", key: "lang_ru", name: "Русский"},
	{tag: "ur", key: "lang_ur", name: "اردو", dir: "rtl"},
	{tag: "ar", key: "lang_ar", name: "العربية", dir: "rtl"},
	{tag: "hi", key: "lang_hi", name: "हिन्दी"},
	{tag: "bn", key: "lang_bn", name: "বাংলা"},
	{tag: "zh", key: "lang_zh", name: "中文"},
	{tag: "ja", key: "lang_ja", name: "日本語"},
]

_langPicker: P={
	// This screen's own route name, so data-route addresses the page the
	// reader is already on rather than sending them elsewhere.
	route: string
	// Pre-formatted `data-param-<hole>="{...}"` attributes this route's
	// pattern needs, own leading space included; empty for a route with no
	// :param.
	params: *"" | string

	// The trigger says which of the fifteen the reader is in. All fifteen
	// endonyms ride the markup and system.css shows the one the screen's
	// [data-locale] names — the technique apps/truco spends on its flags,
	// spent here on a word, and it costs no handler and no new message key.
	// The fourteen it hides go by `display: none`, which takes them out of the
	// accessibility tree as well as the page, so the control can be read aloud
	// as the setting and its value without hiding the value by hand.
	_current: [for l in _LOCALES {
		#"<i data-t="\#(l.tag)"\#(l.attr) data-text="{msg.\#(l.key)}">\#(l.name)</i>"#
	}]

	// data-locale-current is what the interpreter reads to stamp aria-current
	// on the one row naming the locale the page is in, re-run on every switch;
	// the menu ticks and pins that row off it.
	_items: [for l in _LOCALES {
		#"      <a class="lang-item role-meta-sm" data-route="\#(P.route)"\#(P.params) data-locale="\#(l.tag)" data-locale-current="page" lang="\#(l.tag)" hreflang="\#(l.tag)"><span class="lang-name"\#(l.attr) data-text="{msg.\#(l.key)}">\#(l.name)</span></a>"#
	}]

	markup: """
		  <details class="lang-picker">
		    <summary class="lang-summary role-meta-sm">
		      <span class="sr-only" data-text="{msg.language_picker_label}">Language</span>
		      <span class="lang-globe" aria-hidden="true">🌐</span>
		      <span class="lang-current">\(strings.Join(_current, ""))</span>
		    </summary>
		    <nav class="lang-menu" aria-label="{msg.language_picker_label}">
		\(strings.Join(_items, "\n"))
		    </nav>
		  </details>
		"""
}
