package realworld

code: surface: screens: "profile-favorites": markup: #"""
<!-- profile-favorites — ir: #profile-favorites. The terminal owns the nav strip,
     the "<handle> · sign out" row and the back stack; this fragment draws only
     the screen. The header is profile's, component for component: the two
     routes share one header and differ only in which list sits under the rail
     and which rail item is current. -->
<section class="screen" data-screen="profile-favorites">
\#((_langPicker & {route: "profile-favorites", params: " data-param-handle=\"{param.handle}\""}).markup)
  <header class="masthead">
    <a class="back role-meta-sm" data-route="home" data-text="{msg.back_community}">← Community</a>
  </header>

  <form class="search" data-form="search" data-action="navigate" data-route="search" data-param-q="{q}">
    <input class="role-body-md" name="q" required placeholder="{msg.search_placeholder}" aria-label="{msg.search_placeholder}">
    <button class="outline role-body-md" type="submit" data-text="{msg.search_button}">Search</button>
    <p class="invalid role-meta-sm" hidden data-text="{msg.search_invalid}">Type a word to look for.</p>
  </form>

  <p class="offline role-meta-sm" data-text="{msg.offline}">Conduit isn't answering. It keeps trying — this will fill in when it does.</p>

  <div class="skeleton" aria-hidden="true">
    <div class="skel-head">
      <div class="skel-portrait"></div>
      <div class="skel-id">
        <div class="skel-line name"></div>
        <div class="skel-line handle"></div>
      </div>
    </div>
    <div class="skel-line bio"></div>
    <div class="skel-line bio short"></div>
    <div class="skel-button"></div>
  </div>

  <!-- The person. A one-row LIST region, not a singleton: it contains nested
       regions and the singleton branch never recurses into them
       (ir decision-one-row-list). -->
  <div class="person" data-live="app_user" data-filter="handle=eq.{param.handle}"
       data-empty="{msg.profile_not_found}">
    <template data-item>
      <div class="person-card">
        <div class="person-head">
          <img class="portrait" src="{image_url}" alt="">
          <span class="person-id">
            <bdi class="person-name role-display-md" data-text="{display_name}"></bdi>
            <bdi class="person-handle role-meta-sm" data-text="{handle}"></bdi>
          </span>
        </div>
        <p class="about role-prose" data-text="{bio}"></p>

        <!-- "Is this my own page" — the one probe keyed on handle rather than on
             a user id. Its arms are SIBLINGS; a child would bind against the me
             row and be swept as stale chrome (ir decision-probe-empty). -->
        <span class="me-probe" data-live="me" data-filter="handle=eq.{param.handle}">
          <template data-item><i></i></template>
        </span>

        <span class="reader-arm">
          <span class="follow-probe" data-live="follow" data-filter="followed_id=eq.{id}">
            <template data-item><i></i></template>
          </span>
          <form class="when-unfollowed" data-form="follow" data-entity="follow" data-action="create">
            <input type="hidden" name="followed_id" data-value="{id}">
            <button class="follow role-body-md" type="submit"><span data-text="{msg.follow_button}">Follow</span>&nbsp;<span class="follow-who" data-text="{handle}"></span></button>
            <p class="invalid role-meta-sm" hidden data-text="{msg.follow_failed}">That follow didn't take — try again.</p>
            <p class="store-error role-meta-sm" hidden data-text="{msg.follow_failed}">That follow didn't take — try again.</p>
          </form>
          <!-- The retraction carries data-filter: a bare sibling delete would
               call remove("follow", <app_user id>) and delete nothing. RLS
               narrows the filtered delete to my own follow row. -->
          <form class="when-followed" data-form="unfollow" data-entity="follow" data-action="delete"
                data-filter="followed_id=eq.{id}">
            <button class="outline role-body-md" type="submit" data-text="{msg.following_button}">Following</button>
            <p class="invalid role-meta-sm" hidden data-text="{msg.retract_failed}">That didn't come back — try again.</p>
            <p class="store-error role-meta-sm" hidden data-text="{msg.retract_failed}">That didn't come back — try again.</p>
          </form>
        </span>

        <a class="own-arm role-body-md" data-route="settings" data-text="{msg.edit_profile_cta}">Edit your profile →</a>
      </div>
    </template>
  </div>

  <nav class="rail">
    <a class="rail-item role-meta-sm" data-route="profile" data-param-handle="{param.handle}" data-text="{msg.their_writing}">Their writing</a>
    <span class="rail-item current role-meta-sm" aria-current="page" data-text="{msg.favorited_label}">Favorited</span>
  </nav>

  <div class="skeleton-list" aria-hidden="true">
    <div class="skel-card"></div>
    <div class="skel-card"></div>
  </div>

  <!-- The pairs this person still holds. Favorite is private, so anybody's
       favorites are read from the derived index, which is a different root than
       article and cannot share a region with it
       (ir decision-favorite-private-derived). -->
  <div class="list" data-live="favorite_index"
       data-select="*,user:app_user!inner(handle)"
       data-filter="user.handle=eq.{param.handle}&amp;active=is.true&amp;limit=20"
       data-order="favorited_at.desc"
       data-empty="{msg.no_favorites_yet}">
    <template data-item>
      <div class="favorited">
        <!-- The index row contributes order and nothing else: the preview is a
             nested one-row list over the live article, so a retitled piece reads
             correctly here. ACCEPTED COST, named in the ir: parseSelect rejects
             an aliased embed, so this region is server-computed — one GET per
             favorited row, at most twenty. -->
        <div class="piece" data-live="article"
             data-select="*,author:app_user(handle,display_name,image_url)"
             data-filter="id=eq.{article_id}">
          <template data-item>
            <!-- shared preview fragment — ir decision-preview-one-component. Byte
                 identical on home, feed, feed-older, older, tag, search, profile and
                 profile-favorites; card width is the only permitted variant. -->
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
\#(_favPillDeep.markup)
                  <!-- The save arm. Sibling of its own probe like the pill's two arms, and
                       deliberately not accent: DESIGN.md spends accent on creation and
                       commitment, and saving is neither — it is a note to yourself. The set
                       state is a fill and a changed word, no second colour
                       (ir decision-bookmark-no-public-face). -->
\#(_savePillDeep.markup)
                </span>
              </div>
              <!-- end shared preview fragment -->
            </article>
          </template>
        </div>
        <p class="ceiling role-meta-sm" data-text="{msg.ceiling_search}">Showing the 20 newest. Search to find an older piece.</p>
      </div>
    </template>
  </div>
</section>

"""#
