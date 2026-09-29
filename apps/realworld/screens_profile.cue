package realworld

code: surface: screens: "profile": markup: #"""
<!-- profile — ir: #profile. The terminal owns the nav strip, the
     "<handle> · sign out" row and the back stack; this fragment draws only
     the screen. Two top-level regions — the person and their writing — so the
     screen state cannot say which one is empty and each carries its own
     sentence. -->
<section class="screen" data-screen="profile">
\#((_langPicker & {route: "profile", params: " data-param-handle=\"{param.handle}\""}).markup)
  <header class="topline">
    <a class="back role-meta-sm" data-route="home" data-text="{msg.back_community}">← Community</a>
    <form class="search" data-form="search" data-action="navigate" data-route="search" data-param-q="{q}">
      <input class="role-body-md" name="q" required placeholder="{msg.search_placeholder}" aria-label="{msg.search_placeholder}">
      <button class="outline role-body-md" type="submit" data-text="{msg.search_button}">Search</button>
      <p class="invalid role-meta-sm" hidden data-text="{msg.search_invalid}">Type a word to look for.</p>
    </form>
  </header>

  <p class="offline role-meta-sm" data-text="{msg.offline}">Conduit isn't answering. It keeps trying — this will fill in when it does.</p>

  <div class="skeleton" aria-hidden="true">
    <div class="skel-head">
      <div class="skel-portrait"></div>
      <div class="skel-name"></div>
    </div>
    <div class="skel-bio"></div>
    <div class="skel-button"></div>
  </div>

  <!-- The header is a one-row list region and not a singleton: the two probes
       below live inside it, and a region nested under a singleton is hydrated
       by nobody (ir decision-one-row-list). -->
  <div class="person" data-live="app_user" data-filter="handle=eq.{param.handle}"
       data-empty="{msg.profile_not_found}">
    <template data-item>
      <div class="person-row">
        <img class="portrait" src="{image_url}" alt="">
        <div class="ident">
          <h1 class="person-name role-display-md" dir="auto" data-text="{display_name}"></h1>
          <p class="person-handle role-meta-sm" dir="auto" data-text="{handle}"></p>
        </div>
        <p class="person-bio role-prose" data-text="{bio}"></p>
        <!-- Three arms and two probes, all SIBLINGS of one another: an arm
             nested inside a probe would bind against the probe's own row and
             would be swept away as stale chrome on the first refresh. The me
             probe keys on {param.handle} — the one place it does not key on an
             author id — and its :empty state swaps the whole follow control for
             a link into settings, so a Follow is never drawn on one's own page
             (ir accept-no-self-follow). -->
        <span class="follow-arms">
          <!-- A probe carries NO whitespace inside it. The refresh sweep removes
               stale ELEMENT children only, so a newline around the <template>
               survives as a text node and the region is never :empty again —
               the arms would then read "following" and "mine" forever. -->
          <span class="mine-probe" data-live="me" data-filter="handle=eq.{param.handle}"><template data-item><i></i></template></span>
          <span class="follows-probe" data-live="follow" data-filter="followed_id=eq.{id}"><template data-item><i></i></template></span>
          <a class="own-arm role-body-md" data-route="settings" data-text="{msg.edit_profile_cta}">Edit your profile →</a>
          <form class="follow-arm" data-form="follow" data-entity="follow" data-action="create">
            <input type="hidden" name="followed_id" data-value="{id}">
            <button class="role-body-md" type="submit"><span data-text="{msg.follow_button}">Follow</span> <bdi class="follow-handle" data-text="{handle}"></bdi></button>
            <p class="invalid role-meta-sm" hidden data-text="{msg.follow_failed}">That follow didn't take — try again.</p>
            <p class="store-error role-meta-sm" hidden data-text="{msg.follow_failed}">That follow didn't take — try again.</p>
          </form>
          <!-- The retraction carries the filter: a bare delete would call
               remove("follow", <app_user id>) and delete nothing. Under the
               filter it goes through removeWhere, which RLS narrows to my own
               row (ir decision-probe-empty). -->
          <form class="following-arm" data-form="unfollow" data-entity="follow" data-action="delete"
                data-filter="followed_id=eq.{id}">
            <button class="outline role-body-md" type="submit" data-text="{msg.following_button}">Following</button>
            <p class="invalid role-meta-sm" hidden data-text="{msg.follow_failed}">That follow didn't take — try again.</p>
            <p class="store-error role-meta-sm" hidden data-text="{msg.follow_failed}">That follow didn't take — try again.</p>
          </form>
        </span>
      </div>
    </template>
  </div>

  <nav class="tabs">
    <span class="tab current role-meta-sm" data-text="{msg.their_writing}">Their writing</span>
    <a class="tab role-meta-sm" data-route="profile-favorites" data-param-handle="{param.handle}" data-text="{msg.favorited_label}">Favorited</a>
  </nav>

  <div class="skeleton-cards" aria-hidden="true">
    <div class="skel-card"></div>
    <div class="skel-card tall"></div>
  </div>

  <div class="list" data-live="article"
       data-select="*,author:app_user!inner(handle,display_name,image_url)"
       data-filter="author.handle=eq.{param.handle}&amp;limit=20"
       data-order="created_at.desc,id.desc"
       data-empty="{msg.no_writing_yet}">
    <template data-item>
      <!-- shared preview fragment — ir decision-preview-one-component. Byte
           identical on home, feed, feed-older, older, tag, search, profile and
           profile-favorites; card width is the only permitted variant. The
           ceiling line at the end is this screen's own: profile caps at the
           newest twenty instead of paging (ir decision-paging-keyset). -->
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
        <p class="ceiling role-meta-sm" data-text="{msg.ceiling_search}">Showing the 20 newest. Search to find an older piece.</p>
      </article>
    </template>
  </div>
</section>

"""#
