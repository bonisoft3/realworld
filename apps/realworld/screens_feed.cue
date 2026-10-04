package realworld

code: surface: screens: "feed": markup: #"""
<!-- feed — ir: #feed. The terminal owns the nav strip, the handle · sign out
     row and the back stack; this fragment draws only the screen. The card is
     the shared preview fragment (decision-preview-one-component) — identical
     markup on home, feed, feed-older, older, tag, search, profile and
     profile-favorites, save for the paging tail, which is each screen's own
     continuation. -->
<section class="screen" data-screen="feed">
\#((_langPicker & {route: "feed"}).markup)
  <header class="head">
    <a class="back role-meta-sm" data-route="home" data-text="{msg.back_community}">← Community</a>
    <h1 class="role-body-md page-title" data-text="{msg.nav_feed}">Your Feed</h1>
  </header>

  <form class="search" data-form="search" data-action="navigate" data-route="search" data-param-q="{q}">
    <input class="role-body-md" name="q" required placeholder="{msg.search_placeholder}" aria-label="{msg.search_placeholder}">
    <button class="role-body-md outline" type="submit" data-text="{msg.search_button}">Search</button>
    <p class="invalid role-meta-sm" hidden data-text="{msg.search_invalid}">Type a word to look for.</p>
  </form>

  <p class="offline role-meta-sm" data-text="{msg.offline}">Conduit isn't answering. It keeps trying — this will fill in when it does.</p>

  <div class="skeleton" aria-hidden="true">
    <div class="skel-card"></div>
    <div class="skel-card"></div>
    <div class="skel-card"></div>
  </div>

  <div class="quiet">
    <p class="role-body-md lede" data-text="{msg.feed_quiet_lede}">Your feed is quiet.</p>
    <p class="role-body-md said" data-text="{msg.feed_quiet_body}">It fills with the writers you follow. Read the community, find someone worth hearing from, and press Follow on their page.</p>
    <a class="role-body-md go" data-route="home" data-text="{msg.read_community_cta}">Read the community →</a>
  </div>

  <div class="list" data-live="article" data-select="*,author:app_user!inner(handle,display_name,image_url,follow!followed_id!inner(follower_id))" data-filter="limit=20" data-order="created_at.desc,id.desc">
    <template data-item>
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
        <a class="older role-meta-sm" data-route="feed-older" data-param-when="{created_at}" data-text="{msg.older_writing_cta}">Older writing →</a>
      </article>
    </template>
  </div>
</section>

"""#
