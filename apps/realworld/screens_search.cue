package realworld

code: surface: screens: "search": markup: #"""
<!-- search — ir: #search. The terminal owns the nav strip, the
     "<handle> · sign out" row and the back stack; this fragment draws only
     the screen. -->
<section class="screen" data-screen="search">
\#((_langPicker & {route: "search", params: " data-param-q=\"{param.q}\""}).markup)
  <header class="masthead">
    <a class="back role-meta-sm" data-route="home" data-text="{msg.back_community}">← Community</a>
    <!-- The reader sees their own words back before a single row arrives:
         {param.q} resolves in the screen-level pre-pass at mount, not from a
         read, and it arrives URI-decoded from the hash the box wrote. The
         curly quotes are punctuation, not a word, and carry no locale. -->
    <h1 class="page-title role-body-md" dir="auto" data-text="“{param.q}”"></h1>
  </header>

  <!-- Searching again from a results page is the same navigate form and the
       same flow; it is live immediately, so a second search never waits on the
       first. -->
  <form class="search" data-form="search" data-action="navigate" data-route="search" data-param-q="{q}">
    <input class="role-body-md" name="q" required placeholder="{msg.search_placeholder}" aria-label="{msg.search_placeholder}">
    <button class="outline role-body-md" type="submit" data-text="{msg.search_button}">Search</button>
    <p class="invalid role-meta-sm" hidden data-text="{msg.search_invalid}">Type a word to look for.</p>
  </form>

  <p class="offline role-meta-sm" data-text="{msg.offline}">Conduit isn't answering. It keeps trying — this will fill in when it does.</p>

  <div class="skeleton" aria-hidden="true">
    <div class="skel-card"></div>
    <div class="skel-card"></div>
    <div class="skel-card tall"></div>
  </div>

  <!-- One full-text match against the generated tsvector over title,
       description and body — one column and one operator rather than three
       predicates, naming the configuration the column was built with. The read
       re-runs whenever article changes, so a piece published a second ago is
       findable without a reload. Newest first rather than by rank: ranking a
       live list would reorder it under the reader. No data-empty: one top-level
       region, so the screen's own empty state speaks. -->
  <div class="list" data-live="article"
       data-select="*,author:app_user(handle,display_name,image_url)"
       data-filter="search=plfts(simple).{param.q}&amp;limit=20"
       data-order="created_at.desc">
    <template data-item>
      <!-- shared preview fragment — ir decision-preview-one-component. Byte
           identical on home, feed, feed-older, older, tag, search, profile and
           profile-favorites; card width is the only permitted variant. The
           ceiling line at the end is this screen's own: the list is capped,
           not paged (ir decision-paging-keyset). -->
      <article class="preview">
        <div class="preview-head">
          <a class="byline role-meta-sm" data-route="profile" data-param-handle="{author.handle}">
            <img class="avatar" src="{author.image_url}" alt="">
            <bdi class="name" data-text="{author.display_name}"></bdi>
            <bdi class="handle" data-text="{author.handle}"></bdi>
          </a>
          <time class="date role-meta-sm" datetime="{created_at}" data-text="{created_at}" data-text-format="datetime"></time>
          <span class="read role-meta-sm" data-text="{msg.reading_time}"></span>
        </div>
        <div class="preview-open">
          <span class="thumb" data-live="article" data-filter="id=eq.{id}&cover_url=not.is.null&cover_url=neq.">
            <template data-item>
              <img class="thumb-img" src="{cover_url}" alt="" width="320" height="200">
            </template>
          </span>
          <a class="card-open" data-route="article" data-param-slug="{slug}" aria-label="{msg.open_piece_aria}"></a>
          <span class="preview-title role-display-md" data-text="{title}"></span>
          <span class="preview-desc role-prose" data-text="{description}"></span>
        </div>
        <div class="preview-foot">
          <ul class="chips" data-live="article_tag" data-filter="article_id=eq.{id}" data-order="tag.asc">
            <template data-item>
              <li><a class="chip role-meta-sm" data-route="tag" data-param-name="{tag}" data-text="{tag}"></a></li>
            </template>
          </ul>
          <span class="arms">
\#(_favPill.markup)
            <!-- The save arm. Sibling of its own probe like the pill's two arms, and
                 deliberately not accent: DESIGN.md spends accent on creation and
                 commitment, and saving is neither — it is a note to yourself. The set
                 state is a fill and a changed word, no second colour
                 (ir decision-bookmark-no-public-face). -->
\#(_savePill.markup)
          </span>
        </div>
        <!-- end shared preview fragment -->
        <p class="ceiling role-meta-sm" data-text="{msg.ceiling_narrow}">Showing the 20 newest. Narrow with a search or another tag.</p>
      </article>
    </template>
  </div>

  <!-- The words that failed, said back rather than "no results": the heading is
       chrome the eye skips, this sentence is the answer. Both ways out are
       already on the page — the box above is the narrower gesture, the link
       goes to home's popular-tags rail where a word that certainly exists can
       be picked instead. The query is not echoed back into this sentence, for
       the same reason it is not echoed into tag's — a catalogue value does not
       re-scan its own substitutions. -->
  <div class="nothing">
    <p class="nothing-line role-body-md" data-text="{msg.search_nothing}">Nothing matches your search.</p>
    <p class="nothing-sub role-meta-sm" data-text="{msg.search_nothing_sub}">Try fewer words, or a tag.</p>
    <a class="nothing-out role-body-md" data-route="home" data-text="{msg.popular_tags_cta}">Popular tags →</a>
  </div>
</section>

"""#
