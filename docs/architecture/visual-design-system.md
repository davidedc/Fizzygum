# The visual design system — where the look is decided, and the rules it follows

Fizzygum has ONE visual design system. Every colour a piece of chrome paints with, every chrome font,
every chrome dimension and every shadow is decided in one class, `src/Theme.coffee`, under a name that
says what it is FOR. This doc says what those names are, the rules a widget's look follows, how the
design maps onto the widget tree, and how a new widget picks its look.

The design itself — its tokens, its drawing rules and a reference drawing — lives with the redesign
plan that brings the system to it: [`../plans/redesign/UI-guidelines.md`](../plans/redesign/UI-guidelines.md)
(the rules and tokens), `desktop-canvas.html` (a flat Canvas-2D drawing of the target) and
[`../plans/redesign/redesign-plan.md`](../plans/redesign/redesign-plan.md) (which surfaces wear the
design so far, and the decisions behind each rule below).

---

## 1. One place decides the look: `Theme`

A world builds its theme as it is constructed: `WorldWdgt.theme`, a sibling of
`WorldWdgt.preferencesAndSettings`. The split between the two is the whole point:

- **`Theme` is the LOOK** — anything that changes only what the world looks like.
- **`PreferencesAndSettings` is BEHAVIOUR** — input, timing, thresholds (wheel scaling, drag and dwell
  thresholds, press-and-hold time, title-ellipsis rules).

A snapshot never saves or restores the theme: a look is not user state, so a restored world wears the
look of the page that loads it. A reader copies a theme value where it needs it (a constructor taking
its fill, a layout reading a metric); nothing holds the theme object itself.

`Theme` has five sections, all assigned in its constructor (a class-level declaration may not reference
another class, and most values are `Color`s):

| Section | What it holds |
|---|---|
| **PALETTE** | The design's named colours (§2), at the design's values. A palette colour paints nothing by itself. |
| **ROLES** | What each SURFACE paints with — `windowBarFill`, `menuRowText`, `tooltipStroke`, `seamRule`, … One role per surface: two surfaces that paint the same colour still hold two roles, so one can be restyled without moving the other. A role's value is either a palette colour (the surface wears the design: `@seamRule = @chrome`) or the exact value the surface painted with before it adopted the design. |
| **FONT ROLES** | `@fonts`: plain `{family, size, bold}` objects — `menuRow`, `menuHeader`, `windowTitle`, `buttonLabel`, `defaultText`, `tooltip`, `speechBubble`, `prompt`, `desktopCaption`. |
| **METRICS** | Chrome geometry: the bar button's box (`barIconSize`) and the glyphs inside it (`barControlGlyphSize` for × − +, `barActionGlyphSize` for the pencil / eye), a menu row's glyph box (`menuRowGlyphSize`), the frame's border width, the strip's rule and the body margin (`frameBorderWidth`, `barRuleWidth`, `frameBodyMargin`), the window and card corner radii, the menu row height, a plain handle's side (`handleSize`) and the frame grip's side and inset (`frameGripSize`, `frameGripInset`), the toolbar grid's cells, the scroll indicator's resting and hovered widths, chrome corner radii. |
| **SHADOWS** | The ONE shadow every desktop object casts at rest (windows, menus, prompts, tooltips, icons, the clock) and the drag lift a carried widget takes (offset + alpha each), and `shadowColor`, the one colour every shadow silhouette is filled with. |

**The ratchet.** A colour literal in a chrome file is a look decided outside this system — a restyle
edits `Theme` and cannot reach it. The `raw-chrome-color` stink (`buildSystem/check-stinks.js`; table in
[`lint-and-static-checks.md`](lint-and-static-checks.md)) counts them outside content, icon art and the
colour plumbing, and only ever goes down. Its tolerated tail is listed there.

## 2. The palette

| Token | Value | Use |
|---|---|---|
| `ink` | `#1E1E1C` | Text and icon strokes; never large fills |
| `chromeDark` | `#4A4A46` | Reserved for a focused window (no focus state exists yet) |
| `chrome` | `#E2E2DE` | Title bars, the embedded toolbar strip, 1 px rules inside windows (`seamRule`), the disabled button outline |
| `line` | `#C9C9C4` | Control and tile borders, the title bar's bottom rule, the strip divider |
| `frame` | `#B9B9B4` | Frames of windows and menus |
| `chip` | `#D2D2CD` | Border of a chip that is not selected |
| `desk` | `#ECECE8` | Wallpaper, active tool button, highlighted menu row, pale fill inside icons |
| `plate` | `#F4F4F1` | Desktop icon label plates |
| `item` | `#F0F0EC` | A document paragraph item |
| `panel` | `#FAFAF8` | The Object Inspector's body |
| `paper` | `#FFFFFF` | Window content, tiles, menus, the clock face, buttons |
| `muted` | `#6A6A66` | Window title text and bar controls |
| `muted2` | `#8A8A85` | Secondary labels: "Class", `fn`, a menu header |
| `muted3` | `#A5A5A0` | Chevrons and breadcrumb separators |
| `text2` | `#55554F` | Text on toggles and chips that are off; a toolbar strip's glyph |
| `code` | `#3A3A36` | Source code text |
| `grip` | `#BDBDB8` | The resize grip's strokes |
| `disabledText` | `#B9B9B4` | Text of a disabled button |
| `accent` | `#2F5BEA` | Focused, selected and "on" ONLY (the clock's second hand is the one exception: it is live) |
| `accentTint` | `#2F5BEA` at 12% | The fill of an "on" or selected control |
| `danger` | `#C4321C` | Destructive actions only |
| `scrollbar` | `rgba(30,30,28,0.35)` | The overlay scrollbar thumb |

## 3. Fonts

A text widget takes its font as a ROLE: `new StringWdgt text, fontRole: WorldWdgt.theme.fonts.windowTitle`
gives family, size and bold at once. An explicit `fontName` / `fontSize` / `bold` wins over the role's
member, so a caller can take a role and override one member. A text built without a role takes
`fonts.defaultText`. `StringWdgt` and everything built on it read the role; `LabelButtonWdgt` (menu and
list rows — default `menuRow`), `MenuItemWdgt` and `StringFieldWdgt` forward it.

The families are the three the SWCanvas glyph atlases cover — **Arial** (sans), **Courier New** (mono,
through `StringWdgt.monoFontStack`), **Times** (serif) — at normal or bold, normal or italic, sizes
9–96. A design weight maps onto them: **600 → bold, 500 → regular**. There is no letter-spacing.
Both backends use the same families.

## 4. Rules

### 4.1 One line between panes: the CONTAINER owns the seam
A 1 px line between two sibling panes belongs to their container, never to either pane. The container
places its panes exactly 1 px apart and answers those gaps from `_seamRects()` (widget-local
rectangles; `Widget` answers none); its appearance (`Appearance._paintSeamRules`, called by
`RectangularAppearance` and `BoxyAppearance`) fills them with `seamRule` after its own fill and before
its children. A seam is a gap, so no child ever paints over it, every pixel has exactly one owner, and
a pane reused elsewhere carries no stray line.
- A BAND paints its OWN edge rule (a title bar's bottom rule, a menu header's rule): the line is part
  of the band's look whatever sits next to it. Mechanism: three fields on the band's `BoxyAppearance`
  (`ruledEdge`, `ruleColor`, `ruleWidth`), painted after the fill and under the stroke; a frame's strip
  draws the `barRule` role along its content-facing edge.
- Overlapping two panes' borders so they coincide is rejected: double ownership, double paint under
  anti-aliasing, and it must be re-established at every resize.
- Resizing a split stays a halo affordance: a target of at least 44 cannot hide inside a 1 px line.

### 4.2 The 44 rule binds CHROME
Every chrome target is at least 44×44: bar buttons, menu rows, toolbar cells, buttons, handles. A
smaller visible control sits in a row at least 44 tall. Content widgets (spreadsheet cells, patch pins,
a slider inside content) keep their own sizes. A target never extends beyond the widget that owns it:
a target that must be big is drawn big.

### 4.3 A bordered rounded rectangle means "press me"
Anything pressable has a border and rounded corners; anything that is not drops the border and changes
shape (the clock: a round face, no border). A disabled control keeps its shape and loses contrast: no
fill, a `chrome` outline, `disabledText` text — never a dashed outline or a grey fill.

### 4.4 Shadows are solid
A shadow is a copy of the object's shape filled with `shadowColor` (solid black) at the shadow's alpha,
offset — no blur, no gradient. Every object on the desktop casts the ONE shared desktop shadow,
transient pop-ups included; only a dragged object has its own (the lift). The shadow pass paints a widget's SILHOUETTE
(its per-pixel coverage), so an icon or a rounded box casts its own shape.

### 4.5 Symbols: an ICON or a GLYPH, decided by MEANING
A symbol that stands on its own — a control's face, or an indicator of state or behaviour (× − +, a
submenu chevron ›, an overflow », a tick ✓, the resize grip) — is an ICON: a drawn, size-aware icon,
never a character typed into a string. A character that is part of a label's own wording ("…" in
"Save world snapshot…", "—" in a title) is a GLYPH: it renders from a font atlas, and where an atlas
lacks it, it is ADDED to an atlas — the font's own for a typographic character, `BitmapTextInvariant`
for a font-independent symbol — never swapped for an icon. Fonts are not a vector format: no icon fonts.
On SWCanvas a character missing from every atlas paints a placeholder box; the atlases cover a
character at every family, size and density alike or not at all.

### 4.6 Icons are size-aware integer geometry
An icon computes integer device-pixel geometry from the size it actually paints at
(`SizeAwareIconAppearance`: `_paintSizeAware ctx, x0, y0, wDev, hDev`), so the non-anti-aliased
backend renders it crisply at every size. A widget with a `glyphSize` (a chrome button sized to its
whole target) gets its icon painted as a `glyphSize` square centred in its box. An appearance is named
for its SHAPE (`CrossIconAppearance`, `ChevronRightIconAppearance`, `GripIconAppearance`, …); the
button that wears it carries the MEANING (`CloseIconButtonWdgt`). The method — probe ladder, preview,
owner review — is the `convert-icon-size-aware` skill. SWCanvas has no `Path2D`: a design's SVG path is
hand-translated into drawing calls.

### 4.7 Corners and outlines
- A rounded box's radius is one number, or per corner — a 4-array `[topLeft, topRight, bottomRight,
  bottomLeft]` in `cornerRadius` (HTML5 `roundRect()` semantics), e.g. `[7, 7, 0, 0]` for a title bar
  inside a radius-8 window. `BoxyAppearance` fills, strokes and hit-tests by it.
- A frame's strip rounds exactly the corners it shares with the body's outline, at the body radius less
  the border: `[r, r, 0, 0]` for a strip across the top, `[r, 0, 0, r]` for a strip down the side, all
  four when the frame is collapsed (the strip IS the frame). It is set at every arrange of the strip
  (`FrameBarWdgt._shapeTitlebarBackground`), because collapsing and re-siding a dock change it without a
  re-derivation of the look. `FrameWdgt._deriveAndSetSkin` re-derives the body and the strip as one act,
  and a transform island re-homed with a frame as its sole content re-derives that frame
  (`TransformFrameWdgt._reactToBeingAdded`), so a tilted window dropped into a panel wears the card look.
- The hit shape of a rounded box is its FILLED pixels: a logical pixel belongs to it iff its pixel
  centre is inside the outline, the same in all four corners. A rounded corner's notch is pointer-through.
- A 1 px outline is stroked inset half a pixel with the same radius as the fill (the house crisp
  spelling, `strokeRoundRect 0.5, 0.5, w − 1, h − 1, r`).
- A clipping widget whose outline must be painted OVER its content sets `strokesOverChildren` on its
  `BoxyAppearance`: the outline is then stroked once, after the children, instead of with the fill.
- A frame clips its children to its RECTANGLE, so content laid flush against a rounded corner shows its
  own pixels outside the curve unless something stops it. Two mechanisms exist: a flush child can take
  the host's corner radii on its own background (per-corner fill — enough only for content whose corner
  pixels are its background), and `FrameWdgt` can clip its children to its rounded outline
  (its body appearance's `clipsChildrenToOutline` knob, which `_frameLook` turns on for every persistent
  frame — a window, a card, a docked band — and off for a transient pop-up).
  - A repaint whose damage reaches one of the frame's corner squares paints the children under ONE
    rounded clip, through `BoxyAppearance.clipToOutline`. Any other repaint paints them under the
    rectangle, as before.
  - A press in the notch falls through to whatever is behind.
  - The design adopts the clip (redesign plan §3a, and §4 F S1c for the measurements). It costs under
    2 % of suite time on SWCanvas, whose clip is an optional mask AND a rect: a child's rectangle clip
    under the rounded one never builds a mask.

### 4.8 Colour use
The accent says "focused", "selected" or "on" — nothing else. Selected and "on" controls use the
`accentTint` fill with an `accent` border and text, never a solid dark fill. `danger` marks destructive
actions only.

## 5. The design on the widget tree
The design paints flat; Fizzygum paints a tree (parent, then children), so every pixel of the design has
exactly one owning widget:

| Design element | Owner |
|---|---|
| Window shadow, fill, 1 px frame | `FrameWdgt`'s body appearance (`BoxyAppearance`); the shadow is its `ShadowInfo` |
| Title bar fill and its bottom rule | `FrameBarWdgt`'s `titlebarBackground` (the rule is the band's own edge, §4.1) |
| × / − in 44×44 targets | `CloseIconButtonWdgt`, `CollapseIconButtonWdgt` (in a `SwitchButtonWdgt`), children of `FrameBarWdgt` |
| Window title | `FrameBarWdgt`'s label `StringWdgt` (`fonts.windowTitle`) |
| Pencil / eye | `EditIconButtonWdgt` |
| Resize grip | `FrameGripWdgt` (a `HandleWdgt`, child of the frame, bottom-right, `frameGripInset` in from the content area) and `GripIconAppearance`; its hit area is its whole `frameGripSize` square. A halo's and a naked inspector's resizers stay plain `HandleWdgt`s, on `HandleAppearance`'s triangle |
| Embedded toolbar with its title strip | a docked `FrameWdgt` (a card under an `EdgeDockLayoutSpec`) holding a toolbar; its bar runs vertically |
| Document paragraph items | `SimpleTextWdgt` paragraphs in `DocumentViewportWdgt` |
| Menu container, header, rows, group rules | `MenuWdgt` (a transient `FrameWdgt`) → bar (header) → `PopUpRowsViewportWdgt` → `CommandPanelWdgt` → `MenuItemWdgt` rows + `DividerWdgt` |
| Inspector bands and the list \| code line | `InspectorWdgt`'s children; the lines are container-owned seams (§4.1) |
| Desktop icon tile, glyph and label plate | `WidgetHolderWithCaptionWdgt` (icon band + caption band) |
| Clock | `AnalogClockWdgt` + `AnalogClockAppearance` |

Menus, windows, cards and docked bands are ONE class, `FrameWdgt`; which skin a frame wears is derived
from its lifetime and its parentage ([`regularity-principles.md`](regularity-principles.md), "The frame
model"). **`FrameWdgt._frameLook()` is the one place a frame's look is decided**: a pure query answering
one record — the manifestation (menu, window, card), the body's appearance, fill, stroke and rounding,
the strip background's appearance, colours and rounding, the title's ink and background, and the shadow
it casts at rest — from the frame's lifetime and parentage (and, for a menu, whether it has a title to
round). The body (`_deriveAndSetBodyAppearance`), the strip (`FrameBarWdgt`) and the shadow (`addShadow`)
all READ it; none decides a look of its own. A focus state, when one exists, enters
there and nowhere else. Collapsed and docked are not inputs: a collapsed frame wears its expanded look,
and a docked band is the card its parentage makes it; only the strip's corners follow the collapse and
the strip's axis, set at every arrange (§4.7). The whole skin is applied on EVERY derivation, as one act
(`FrameWdgt._deriveAndSetSkin`): the body (appearance, colours, rounding, and the stroke-last and
rounded-clip knobs) and the strip (its background's appearance, fill and rule, its title's ink, and
its glyphs' ink: `muted` in a window's strip, `text2` in a card's, `ink` while a glyph is hovered or
pressed — the glyph recolours in place, with no plate behind it). A
derivation is construction, re-parenting, lifetime change, and the re-homing of a transform island the
frame rides in as its sole content. So a pinned menu wears the window's skin, a window nested into a
panel wears the card's, and a corner radius set by hand lasts until the frame next changes parent or
lifetime.

## 6. How a new widget picks its look

1. **Chrome or content?** Content (a shape the user draws, a plot series, a document's text) keeps its
   own colours and sizes. Chrome — anything that frames, controls or annotates content — takes its look
   from `Theme`.
2. **Colours:** read the role named for your surface (`WorldWdgt.theme.<role>`); if your surface has
   none, add one to `Theme`'s ROLES section, named for the surface, at the value it paints with.
   Never a colour literal in a chrome file (§1, the ratchet).
3. **Text:** `fontRole: WorldWdgt.theme.fonts.<role>`.
4. **Sizes:** chrome dimensions are `Theme` metrics; a chrome target is at least 44 (§4.2).
5. **Shape:** pressable ⇒ bordered and rounded (§4.3); per-corner radii where it sits inside a rounded
   host (§4.7).
6. **Symbols:** drawn size-aware icons, named for their shape (§4.5, §4.6).
7. **Lines between your panes:** seams you own (`_seamRects`, §4.1), not pane borders.
8. **Shadow:** nothing to do — an object on the desktop casts the shared shadow.

See also [`widget-authoring-guidelines.md`](widget-authoring-guidelines.md) §15 and
[`appearance-paint-convention.md`](appearance-paint-convention.md) (how an appearance paints).
