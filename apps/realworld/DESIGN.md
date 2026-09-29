---
colors:
  primary: "#16181A"
  secondary: "#6B7076"
  accent: "#1D6A4F"
  danger: "#A93226"
  neutral: "#FBFAF7"
  surface: "#FFFFFF"
  border: "#E4E1D9"
  surface-muted: "#EFEDE6"
dark:
  primary: "#E9E7E2"
  secondary: "#9AA0A6"
  accent: "#63BE95"
  danger: "#E2705F"
  neutral: "#131414"
  surface: "#1C1E1F"
  border: "#2E3133"
  surface-muted: "#24272A"
rounded:
  sm: "4px"
  md: "8px"
  full: "999px"
spacing:
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "40px"
motion: {}
shell:
  bg: "neutral"
  fg: "secondary"
  rule: "border"
---

# Press

Identity for Conduit — an editorial ground where the writing is the
interface. Serif for what was written, sans for what the app says about
it. Chosen by three-direction comparison (verdicts below); the token names
are a schema contract, the hex values remain the designer's to evolve.

## Overview

Conduit is a place people read, so the writing is the interface and the
app is the frame around it. Warm paper ground, near-black ink, and one
deep pine accent that appears only where something is created or
committed. The dark appearance is a twin, not an afterthought — every
token has a dark value and every screen must read correctly in both.

The identity's one structural move is the **type duality**: everything a
person *wrote* — article titles, descriptions, bodies, comments — is
set in serif; everything the *app* says about it — handles, dates,
counts, tags, buttons, nav — is set in sans. A reader can tell authored
text from chrome without reading a word of it, which is what makes a
list of previews scan.

## Comparison

Three directions were drawn against the brief's home list, article, and
profile, and judged; verdicts recorded per the charter — an identity is
never a single pass.

1. **Press** (warm paper, serif authored text, sans chrome, one pine
   accent) — **chosen.** The type duality does the work a second color
   would otherwise have to do, so the palette can stay quiet across a
   long scroll of previews; the reading measure on the article screen
   is native to the identity rather than a special case; and the dark
   twin keeps its warmth by lowering value, not shifting hue.
2. **Conduit classic** (the RealWorld reference look: white ground,
   bright #5CB85C green, all-sans) — **rejected.** It is the identity
   this exercise exists to beat. The green is loud enough to compete
   with every preview title, and an all-sans setting makes an article
   body read like a form field.
3. **Terminal** (near-black ground in both appearances, monospace
   metadata, high-contrast rules) — **rejected.** It flatters short
   chrome and punishes long prose: a 1,500-word body on a dark ground
   at reading measure is the app's most important surface and the one
   this direction serves worst. A dark-only ground would also make the
   light appearance a retrofit — the twin must be native.

**Contract:** the token *names* above are the schema contract (the
program reads `colors`, `dark`, `rounded`, `spacing`, `motion` and
`shell` from this file's frontmatter and restates none of them); the
comparison and any later evolution vary only the values, so the
identity can move without a migration. Both appearances carry the same
token names — appearance is a token resolution, never a state
(accept-dual-appearance) — and the dark twin lowers value rather than
shifting hue (ir decision-design-identity).

## Colors

- **Primary / Secondary:** ink and metadata, both appearances.
  **Secondary lives only on neutral or surface grounds**, and never on
  authored text — a description set in secondary reads as chrome and
  stops selling its article.
- **Accent:** creation and commitment only — publish, leave a comment,
  follow, favorite-when-set. Navigation chrome (nav row, back-links,
  tab labels) is secondary or primary, never accent. An accent that
  appears in the nav has spent the one signal the reader needs on the
  page.
- **Danger:** destruction and refusal only — delete article, remove
  comment, validation messages, unfollow is **not** danger (it is a
  reversal, not a destruction, and reads as an outline button).
- **Border:** the one hairline — inputs, chips, dividers, card outlines,
  the rule under the masthead — in both appearances.
- **Surface-muted:** skeletons, quiet fills, and tag chips, both
  appearances; loading frames draw nothing else. The storyboards'
  hairlines and skeleton fills are these two tokens verbatim.

## Type

The duality is two families and one scale. Authored text is serif —
`ui-serif, Georgia, "Times New Roman", serif` — at three sizes: an
article title displays at 2.5rem (weight 600, leading 1.15), a preview
title at 1.375rem (weight 600, leading 1.25), and the prose itself reads
at 1.0625rem on a 1.7 leading, the loosest in the app because a body is
its longest surface. Everything the app says about it is sans —
`system-ui, sans-serif` — at two: body chrome at 1rem (leading 1.5) and
metadata at 0.8125rem (leading 1.4). The frontmatter names no `type` of
its own, so the purposes and leadings the terminal publishes are the
`press` preset's; the families are the identity's, worn by the screens.

## Geometry

Three radii and four gaps. `rounded.sm` is a control's corner — buttons,
inputs — `rounded.md` a preview card's, and `rounded.full` the pill: tag
chips and avatars. `spacing` climbs through its four steps;
a card pads `spacing.lg`, an outline button or a chip `spacing.sm`, and a
primary button or an input an inset of its own that no step names.

## Motion

The block names no motion of its own: "don't animate longer than 300ms"
is a terminal property verified once, not restated as a token (ir
decision-terminal-chrome).

## Chrome

The terminal's own chrome resolves to `neutral` for its ground, `border`
for its rule, and `secondary` for its text: nav reads at --secondary,
which becomes body's default colour (ir decision-design-identity).

## Components

How the tokens land on the recurring boxes; each names only tokens
declared above.

- **Preview card:** fill `surface`, text `primary`, `rounded.md`, padded
  `spacing.lg`.
- **Primary button:** fill `accent`, text `neutral`, `rounded.sm`, padded
  12px.
- **Outline button:** fill `surface`, text `secondary`, `rounded.sm`,
  padded `spacing.sm`.
- **Tag chip:** fill `surface-muted`, text `secondary`, `rounded.full`,
  padded `spacing.sm`.
- **Text input:** fill `surface`, text `primary`, `rounded.sm`, padded
  12px.
- **Avatar:** `rounded.full`.
- **Delete row:** text `danger`.

## Do's and Don'ts

- Do hold the article body to a reading measure (60–70 characters);
  it is the app's most important surface.
- Do keep every preview identical wherever it appears — home, tag,
  search, profile — so the list is one component and reads as one.
- Do give every storyboard frame a dark twin in review, even where only
  the light frame is drawn.
- Do let a favorite count be a control that looks pressable, and show
  its set state by fill rather than by a second color.
- Don't set authored text in sans or chrome in serif; the duality is
  the identity and a single crossing breaks the scan.
- Don't tint a preview card; the cards are the same, the writing is not.
- Don't animate longer than 300ms.
