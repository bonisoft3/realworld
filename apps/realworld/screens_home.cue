package realworld

code: surface: screens: "home": markup: #"""
<!-- home — ir: #home. The terminal owns the nav strip, the "<handle> · sign out"
     row and the back stack; this fragment draws only the screen. -->
<section class="screen" data-screen="home">
\#((_langPicker & {route: "home"}).markup)
  <header class="masthead">
    <h1 class="role-display-md" data-text="{msg.brand_name}">Conduit</h1>
    <p class="tagline role-meta-sm" data-text="{msg.home_tagline}">A place to read and write, in public.</p>
  </header>

  <form data-form="search" data-action="navigate" data-route="search" data-param-q="{q}" class="search">
    <input class="role-body-md" name="q" required placeholder="{msg.search_placeholder}" aria-label="{msg.search_placeholder}">
    <button type="submit" class="role-body-md outline" data-text="{msg.search_button}">Search</button>
    <p class="invalid role-body-md" hidden data-text="{msg.search_invalid}">Type a word to look for.</p>
  </form>

  <p class="offline role-meta-sm" data-text="{msg.offline}">Conduit isn't answering. It keeps trying — this will fill in when it does.</p>

  <div class="columns">
    <div class="stream">
      <div class="skeleton" aria-hidden="true">
        <div class="skel-card"></div>
        <div class="skel-card"></div>
        <div class="skel-card tall"></div>
      </div>

      <div class="list" data-live="article"
           data-select="*,author:app_user(handle,display_name,image_url)"
           data-filter="limit=20"
           data-order="created_at.desc,id.desc"
           data-empty="{msg.home_list_empty}">
        <template data-item>
          <!-- preview — the one shared fragment (ir decision-preview-one-component).
               Only the continuation link at its foot is this screen's own. -->
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
        <a class="older role-meta-sm" data-route="older" data-param-when="{created_at}" data-text="{msg.older_writing_cta}">Older writing →</a>
      </article>
        </template>
      </div>
    </div>

    <aside class="rail">
      <span class="rail-label role-meta-sm" data-text="{msg.popular_tags_label}">Popular tags</span>
      <div class="skeleton-rail" aria-hidden="true">
        <div class="skel-chip"></div>
        <div class="skel-chip"></div>
        <div class="skel-chip"></div>
        <div class="skel-chip"></div>
      </div>
      <nav class="tags" data-live="tag_count" data-filter="article_count=gt.0" data-order="article_count.desc,id.asc"
           data-empty="{msg.tags_empty}">
        <template data-item>
          <a class="tag-chip role-meta-sm" data-route="tag" data-param-name="{id}">
            <span class="tag-name" data-text="{id}"></span>
            <span class="tag-tally" data-text="{article_count}"></span>
          </a>
        </template>
      </nav>
    </aside>
  </div>
</section>

"""#
