package realworld

code: surface: screens: "feed-older": markup: #"""
<!-- feed-older — ir: #feed-older. The terminal owns the nav strip, the
     "<handle> · sign out" row and the back stack; this fragment draws only
     the screen. -->
<section class="screen" data-screen="feed-older">
\#((_langPicker & {route: "feed-older", params: " data-param-when=\"{param.when}\""}).markup)
  <header class="masthead">
    <a class="back role-meta-sm" data-route="feed" data-text="{msg.back_feed}">← Your Feed</a>
    <h1 class="page-title role-body-md" data-text="{msg.feed_older_title}">Older in your feed</h1>
    <p class="gloss role-meta-sm" data-text="{msg.feed_older_gloss}">The writers you follow, before the piece you were reading</p>
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

  <div class="list" data-live="article"
       data-select="*,author:app_user!inner(handle,display_name,image_url,follow!followed_id!inner(follower_id))"
       data-filter="created_at=lt.{param.when}&amp;limit=20"
       data-order="created_at.desc,id.desc">
    <template data-item>
      <!-- shared preview fragment — ir decision-preview-one-component. Byte
           identical on home, feed, feed-older, older, tag, search, profile and
           profile-favorites; card width is the only permitted variant. The
           paging anchor at the end is this screen's own: feed pages to
           feed-older, never to older (ir decision-paging-keyset). -->
      <article class="preview">
        <div class="preview-head">
          <a class="byline role-meta-sm" data-route="profile" data-param-handle="{author.handle}">
            <img class="avatar" src="{author.image_url}" alt="">
            <bdi class="name" data-text="{author.display_name}"></bdi>
            <bdi class="handle" data-text="{author.handle}"></bdi>
          </a>
          <time class="date role-meta-sm" datetime="{created_at}" data-text="{created_at}" data-text-format="datetime"></time>
          <span class="read role-meta-sm" data-msg-plural="reading_minutes" data-text="{msg.reading_time}"></span>
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
        <a class="older role-meta-sm" data-route="feed-older" data-param-when="{created_at}" data-text="{msg.older_writing_cta}">Older writing →</a>
      </article>
    </template>
  </div>

  <div class="beginning">
    <p class="beginning-line role-body-md" data-text="{msg.feed_older_end_line}">You've reached the beginning of your feed.</p>
    <p class="beginning-sub role-meta-sm" data-text="{msg.feed_older_end_sub}">Nothing older from the writers you follow.</p>
    <a class="beginning-out role-body-md" data-route="feed" data-text="{msg.back_feed_cta}">Back to Your Feed →</a>
  </div>
</section>

"""#
