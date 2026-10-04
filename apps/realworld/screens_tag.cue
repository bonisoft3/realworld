package realworld

code: surface: screens: "tag": markup: #"""
<!-- tag — ir: #tag. The terminal owns the nav strip, the
     "<handle> · sign out" row and the back stack; this fragment draws only
     the screen. -->
<section class="screen" data-screen="tag">
\#((_langPicker & {route: "tag", params: " data-param-name=\"{param.name}\""}).markup)
  <header class="masthead">
    <a class="back role-meta-sm" data-route="home" data-text="{msg.back_community}">← Community</a>
    <!-- The heading is true before a single row arrives: {param.name} resolves
         in the screen-level pre-pass at mount, not from a read. The leading
         "#" is punctuation, not a word — it carries no locale of its own, so
         it stays outside any catalogue key. -->
    <h1 class="page-title role-body-md" data-text="#{param.name}"></h1>
  </header>

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

  <!-- The !inner embed drops every article that does not carry the word, and
       registers article_tag in the region's dependency set, so a retag moves a
       piece in or out of this list without a navigation. No data-empty: one
       top-level region, so the screen's own empty state speaks. -->
  <div class="list" data-live="article"
       data-select="*,author:app_user(handle,display_name,image_url),article_tag!inner(tag)"
       data-filter="article_tag.tag=eq.{param.name}&amp;limit=20"
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

  <div class="nothing">
    <!-- The tag name is deliberately not echoed back into this sentence: a
         catalogue value does not re-scan its own substitutions
         (interpreter/screen.js interpolate does one .replace pass), so a
         value written as "...under #{param.name} yet." would show the
         literal brace text in every locale but the one the string was typed
         in. A static sentence is what stays true in all fifteen. -->
    <p class="nothing-line role-body-md" data-text="{msg.tag_nothing}">Nothing is filed under this tag yet.</p>
    <p class="nothing-sub role-meta-sm" data-text="{msg.tag_nothing_sub}">A tag exists because an article carries it — the first piece to wear this one starts the list.</p>
    <a class="nothing-out role-body-md" data-route="home" data-text="{msg.read_community_cta}">Read the community →</a>
  </div>
</section>

"""#
