package realworld

code: surface: screens: "reading-list": markup: #"""
<!-- reading-list — ir: #reading-list. What this reader has put aside, newest
     save first. The root region is Bookmark rather than Article because the
     ordering a reader means by "my list" is save time, which only the bookmark
     row knows; each row then nests a one-row list over the live article, so a
     retitled or re-covered piece reads correctly here (ir
     decision-bookmark-no-public-face). The terminal owns the nav strip, the
     "<handle> · sign out" row and the back stack; this fragment draws only the
     screen. -->
<section class="screen" data-screen="reading-list">
\#((_langPicker & {route: "reading-list"}).markup)
  <header class="masthead">
    <a class="back role-meta-sm" data-route="home" data-text="{msg.back_community}">← Community</a>
    <h1 class="page-title role-body-md" data-text="{msg.nav_reading_list}">Saved</h1>
    <p class="lede role-meta-sm" data-text="{msg.reading_list_lede}">Yours alone. Saving is private — no count moves and nobody is told.</p>
  </header>

  <p class="offline role-meta-sm" data-text="{msg.offline}">Conduit isn't answering. It keeps trying — this will fill in when it does.</p>

  <div class="skeleton" aria-hidden="true">
    <div class="skel-card"></div>
    <div class="skel-card"></div>
  </div>

  <!-- No reader named anywhere in this read: bookmark is owned, so the SELECT
       policy is the filter and this returns exactly one person's saves. -->
  <div class="list" data-live="bookmark" data-filter="limit=20"
       data-order="created_at.desc,id.desc"
       data-empty="{msg.reading_list_empty}">
    <template data-item>
      <div class="saved">
        <!-- The bookmark row contributes order and nothing else. ACCEPTED COST,
             the same one profile-favorites names: parseSelect rejects an aliased
             embed, so this region is server-computed — one GET per saved row, at
             most twenty. A denormalised preview would be cheaper and would break
             accept-edit-propagates for this list alone. -->
        <div class="piece" data-live="article"
             data-select="*,author:app_user(handle,display_name,image_url)"
             data-filter="id=eq.{article_id}">
          <template data-item>
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
          </template>
        </div>
      </div>
    </template>
  </div>

  <p class="ceiling role-meta-sm" data-text="{msg.reading_list_ceiling}">Showing the 20 newest. Older saves are further down the list than a list should go.</p>
</section>

"""#
