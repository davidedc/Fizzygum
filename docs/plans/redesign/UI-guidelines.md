# Desktop UI guidelines (developer edition)

These guidelines are for a software-rendered desktop that is used by touch as well as mouse.
All values are in CSS pixels at 1×. Multiply by the device pixel ratio for the backing store.

The reference implementation is `desktop-canvas.html`. It draws the whole desktop with Canvas 2D and nothing else, and every number below can be found there.

---

## 1. Rendering rules

| Rule | Detail |
|---|---|
| Shapes | Filled rects, rounded rects (radius per corner), circles, and stroked paths with round caps and joins. |
| Not allowed | Blur, gradients, glows, **dashed strokes**, text effects, and transparency stacked several layers deep. |
| Shadow | A copy of the object's shape filled with solid black, offset **(+2, +2)**. Use **12%** alpha for everything on the desktop and **16%** for the focused window. Draw it before the object. |
| 1px rules | Draw dividers as one-pixel filled rectangles (`fillRect(x, y, w, 1)`), not as strokes. |
| Borders | Stroke inset, like a CSS border: for border width `b`, stroke the path at an inset of `b/2` with radius `r − b/2`. |
| Window frame | Stroke the 1px frame **last**, after the window's contents, so its edge lines up exactly with the title bar. |
| Pixel snapping | Round each edge of a box: `x0 = round(x)`, `x1 = round(x + w)`. Positions inside layouts can be fractional, but box edges are always whole pixels. |
| Icons | Store each icon as SVG geometry (a `d` string, rect or circle) and replay it at draw time through `Path2D`, using that element's own fill, stroke width, cap and join. Use a miter limit of 4, which is the SVG default. |
| High-DPI | Scale the backing store by the device pixel ratio and draw in CSS pixels. |
| Fonts | Wait for fonts to load before painting. Measure all text at runtime, never hard-code widths. |

### 1.1 Text baselines

Two rules cover every case. Use `A = round(ascent)` and `D = round(descent)` for the font.

- **Explicit line-height** (labels, list rows, code, paragraphs). The half-leading above the text rounds down:
  `baseline = top + floor((lineHeight − (A + D)) / 2) + A`
- **Line centred in a taller box** (buttons, flex rows, menu rows). The offset rounds to the nearest pixel:
  `baseline = round(top + (boxHeight − (A + D)) / 2) + A`

### 1.2 Corner radii

| Radius | Used for |
|---|---|
| 2px | Scrollbar thumb |
| 5px | Embedded toolbar strip: left corners only, `[5, 0, 0, 5]` |
| 6px | Controls: buttons, toggles, tool buttons, list rows, menu rows, paragraph items, embedded toolbar |
| 7px | Title bars: top corners only, `[7, 7, 0, 0]` (the 8px frame radius minus the 1px border) |
| 8px | Windows and label plates |
| 10px | Menus |
| 16px | Desktop icon tiles, and full pills (32px-tall chips) |

---

## 2. Colour tokens

| Token | Value | Use |
|---|---|---|
| `ink` | `#1E1E1C` | Text and icon strokes. Never used for large fills. |
| `chromeDark` | `#4A4A46` | Focused title bar, and the focused window's frame. |
| `chrome` | `#E2E2DE` | Background title bars, the embedded toolbar strip, 1px dividers inside windows, the disabled button outline. |
| `line` | `#C9C9C4` | Control and tile borders, the title bar's bottom rule, the strip divider. |
| `frame` | `#B9B9B4` | Frames of background windows and menus. |
| `chip` | `#D2D2CD` | Border of a chip that isn't selected. |
| `desk` | `#ECECE8` | Wallpaper, active tool button, highlighted menu row, pale fill inside icons. |
| `plate` | `#F4F4F1` | Icon label plates. |
| `item` | `#F0F0EC` | Background of a document paragraph item. |
| `panel` | `#FAFAF8` | Background of the Object Inspector window. |
| `paper` | `#FFFFFF` | Window content, tiles, menus, the clock face, buttons. |
| `muted` | `#6A6A66` | Background window title text and controls. |
| `muted2` | `#8A8A85` | Secondary labels: "Class", "fn", menu header. |
| `muted3` | `#A5A5A0` | Chevrons and breadcrumb separators. |
| `text2` | `#55554F` | Text on toggles and chips that are off, the strip's minimise glyph. |
| `code` | `#3A3A36` | Source code text. |
| `grip` | `#BDBDB8` | Resize grip strokes. |
| `disabledText` | `#B9B9B4` | Text of a disabled button. |
| `accent` | `#2F5BEA` | Focus, selection and "on" states only. |
| `accentTint` | `#2F5BEA1F` (12% accent) | Fill of an "on" or selected control. |
| `danger` | `#C4321C` | Destructive actions only. |
| `scrollbar` | `rgba(30, 30, 28, 0.35)` | Overlay scrollbar thumb. |

How colour is used:
- The accent appears only to say "focused", "selected" or "on". The clock's second hand is the one exception, because it's live.
- Selected and "on" controls use the **accentTint** fill with an accent border and accent text. Never use a solid dark fill for these.

---

## 3. Type

| Role | Font |
|---|---|
| Menu rows, document text | 15px sans |
| Menu chevrons | 16px sans |
| Window titles | 13px sans; weight 600 when focused, 500 when in the background |
| Labels, chips, toggles, buttons | 12px sans |
| Menu header | 11px sans, uppercase, letter-spacing 0.06em |
| Kind tags (`fn`, `var`) | 10px sans, weight 600 |
| Member names | 13px mono |
| Source code | 12px mono, line-height 18 |

- Sans is `'Helvetica Neue', Helvetica, sans-serif`. Mono is `Menlo, Consolas, monospace`. Serif is `Georgia, serif`, used for the Bold and Italic tool glyphs.
- Use sentence case and human names. Never show internal class names in the interface.
- Toggle labels never change: write "Methods", not "methods: on". The fill shows the state.

---

## 4. Interaction model

- **Every target is at least 44×44.** Smaller visible controls (32–36px) must sit in rows 44–52px tall with gaps of at least 8px.
- **A target never extends beyond the widget that owns it.** If a target needs to be big, draw it big.
- **A bordered rounded rectangle means "press me."** Anything that isn't pressable drops the border and changes shape. The clock is the model: a round face with no border.
- **Disabled controls keep their shape but lose contrast:** no fill, a faint `chrome` (#E2E2DE) outline and `disabledText` (#B9B9B4) text. Never use dashed outlines or grey fills for this.
- **Everything that sits on the desktop casts the shared shadow:** windows, menus, icon tiles, label plates and the clock.

---

## 5. Desktop

### 5.1 Icon grid
- The grid is placed at (16, 14). It has 2 columns of 96px each, with an 8px gap between columns and a 10px gap between rows.
- Each row is as tall as its tallest icon. Icons are aligned to the top of the row.
- An icon is centred in its cell. From top to bottom it's: 6px padding, the 64px tile, a 6px gap, the label plate, and 6px padding.

### 5.2 Tile
- **Size and fill:** 64×64, `paper` fill, radius 16, shared shadow.
- **Border:** 1px `line`. The selected icon's tile gets a **2px accent** border instead.
- **Glyph:** 40×40, centred, offset (12, 12). It's drawn on a 44-unit grid with 2px strokes, round caps and joins, and only light fills (`paper` or `desk`). Small ink dots are the only dark fills allowed.
- **Shared motifs:**
  - "Content / window / slide" is always the same 34×24 rounded rectangle (radius 4) at (5, 10) on the 44-unit grid.
  - A toolbar is always a narrow upright rounded rectangle with short button lines.

### 5.3 Label plate
- **Shape and padding:** `plate` fill, radius 8, padding 1px vertical and 7px horizontal, shared shadow.
- **Text:** 12px, line-height 16, centred.
- **Width:** the measured text width plus 14, at most the cell width.
- **Wrapping:** labels wrap word by word to fit the cell width minus 14. A wrapped label's plate spans the full cell width, as "Patch programming" does.
- **Selected:** accent fill with white text.
- **Testing:** check every change on a busy textured wallpaper as well as the plain one.

### 5.4 Bin
- A desktop icon centred in a 92px cell at (1203, 750).

### 5.5 Clock
- **Placement:** 88×88 at (1190, 14). It's drawn on a 120-unit grid.
- **Face:** `paper` circle, radius 58 units, **no border**, with the shared shadow as a circle.
- **Marks:** four 3-unit dots at 12, 3, 6 and 9, coloured `#9A9A95`.
- **Hands:**
  - Hour hand: 6 units wide, ink, round caps.
  - Minute hand: 4 units wide, ink, round caps.
  - Second hand: 2 units wide, accent.
  - Centre dot: 4 units, accent.

---

## 6. Windows

### 6.1 Frame
- **Size:** the CSS width and height are the content area. The 1px frame sits outside it.
- **Outer box:** radius 8, with the shadow drawn first.
- **Frame colour:**
  - **Focused:** `chromeDark`, with a 16% shadow.
  - **Background:** `frame`, with a 12% shadow.
- Stroke the frame last.

### 6.2 Title bar
- **Size and shape:** 44px tall, `roundRect(x, y, w, h, [7, 7, 0, 0])`.
- **Focused:** `chromeDark` fill, white text at weight 600.
- **Background:** `chrome` fill, `muted` text at weight 500, and a 1px `line` rule underneath.
- Focus is the **only** difference between the two.
- **Close and minimise:**
  - Plain × and − glyphs, 14px with 2px strokes.
  - Each glyph is centred in its own 44×44 target, starting at the left edge.
  - The window title is centred between 88px insets on both sides.
- **Right-hand actions:** 44×44 targets, such as the edit pencil (20px glyph, 1.6px stroke).

### 6.3 Resize grip
- **Shape:** three diagonal strokes on a 36-unit grid, 1.5px wide, `grip` colour.
- **Position:** 3px in from the bottom-right corner of the content area.
- **Hit area:** the grip's own 36×36 square, inside the frame. The grip is drawn large precisely because its hit area can't extend past the border.

### 6.4 Rows and dividers inside windows
- Divide sections with 1px `chrome` rules.
- Each band's height includes its rule. Content is centred in the band's height minus the rule.

### 6.5 Toolbars
- A toolbar **is a window**. Its title strip can be on any side, and it can be collapsed and moved. Never special-case how a toolbar looks.
- **Embedded toolbar:**
  - Inset 8px from the host window.
  - 56px content area, 1px `line` border, radius 6, `paper` fill.
- **Title strip:**
  - 44px wide plus a 1px `line` divider, `chrome` fill, radius `[5, 0, 0, 5]`.
  - It contains **only the controls the toolbar needs**, usually just minimise.
- **Tool buttons:** 44×44, radius 6, spread evenly (space-between) with 8px of side padding. The active tool gets a `desk` fill.
- **Font button:** a script A in Snell Roundhand, italic, about 23px. Ship the font with the system so it looks the same everywhere.

### 6.6 Documents
- **Each paragraph is an item that can be dragged and edited as a whole.**
- **Item block:**
  - `item` fill, radius 6.
  - As wide as the toolbar: 8px insets from the window.
  - Padding 6px vertical and 10px horizontal.
- **Text:** 15px, line-height 22, `ink`.
- **Cursor:** 2×18, accent, placed after the last character with 1px of space. Its bottom sits 3px below the baseline.

---

## 7. Controls

| Control | Height | Horizontal padding | Radius | Off / default | On / selected |
|---|---|---|---|---|---|
| Chip (breadcrumb) | 32 | 10 | 16 | No fill, `chip` border, `text2` text | `accentTint` fill, accent border and text |
| Toggle | 36 | 12 | 6 | No fill, `line` border, `text2` text | `accentTint` fill, accent border and text |
| Button | 36 | 14 | 6 | `paper` fill, `line` border, `ink` text | Pressed: `chrome` fill, darker border |
| Primary action (Save) | 36 | 18 | 6 | Disabled: no fill, `chrome` border, `disabledText` text | |
| Tool button | 44 | — | 6 | No fill | `desk` fill |

- Button width is the measured text width + 2 × padding + 2 (the border).
- Breadcrumbs: "Class" in `muted2`, then the chips with › separators in `muted3`, all 4px apart.

### 7.1 Lists
- **List padding and spacing:** 4px around the list, 2px gap between rows.
- **Rows:** 40px tall, radius 6. A selected row gets an `accentTint` fill.
- **Kind tag:** `fn`, 10px semibold in an 18px column, then an 8px gap, then the name in 13px mono.
- **Overlay scrollbar:**
  - A 4px-wide thumb, radius 2, `scrollbar` colour.
  - It floats near the list's right edge with no track.

---

## 8. Menus

- **Container:** `paper` fill, 1px `frame` border, radius 10, shared shadow. Inner padding is 4px on the left and right.
- **Header:**
  - 32px tall plus a 1px `chrome` rule.
  - 11px uppercase text with 0.06em letter-spacing, `muted2`.
  - Use a human name, or omit the header.
- **Groups:** 4px of padding above and below, with a 1px `chrome` rule between groups.
- **Rows:**
  - 44px tall, 10px side padding, radius 6, 15px text.
  - A highlighted row gets a `desk` fill.
- **Submenu chevron:** › in 16px `muted3`, right-aligned 10px from the edge.
- **Destructive items:**
  - go in their own last group
  - use `danger` text
  - end with "…"
  - always ask for confirmation

---

## 9. Draw order

1. Wallpaper.
2. Desktop objects in stacking order. Each one draws its shadow, then its fill, then its contents, then its border or frame.
3. Inside a window: frame shadow and fill, title bar and its rule, section rules, controls, list rows, then positioned overlays (scrollbar, grip), and the frame stroke last.

---

## 10. Principles behind these rules

- **Keep the original's structure and fix its surface.** Layout, sizes and behaviour stay; only what makes them noisy or inconsistent changes.
- **When something stands out, decide whether it should.** If not, make it match the system rather than adding a special case.
- **Make it big without making it loud.** Size serves touch; quiet colour and thin strokes keep big things calm.
- **Judge in context.** Check every change on the full desktop, and on a busy wallpaper, not as an isolated swatch.
