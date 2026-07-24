# drawImage blit attribution (perf plan §5B O4) — measured 2026-07-24

**Question (O4, `docs/plans/runtime-performance-optimization-plan.md` §5B).** The 2026-07-09
post-occlusion re-profile put `_drawImageInternal` at 9.6% of the busy-drag frame, tentatively
labeled "back-buffer + glyph-atlas blits; if per-glyph blits dominate, a batched glyph-run blit
could help." O4's standing instruction: attribute the blits before committing to any fix. This
is that attribution.

## Method

- Scenario: `docs/profiling/prof-interactive.js` busy desktop (14 apps, 21 windows — the
  desktop now includes the frame-arc companion "… info" documents, so the workload is BIGGER
  than the 2026-07-09 §5B baseline; absolute ms are not comparable across that boundary,
  within-run percentages are), `--sw --wallpaper=plain`, default 140/80/180 frames.
- **Time attribution**: shadow-build `.cpuprofile` per phase (`mk-shadow-build.sh` + a shadow
  `index.html`), digested by the NEW **`docs/profiling/prof-attribute.js`** — aggregates one
  named function's sampled self time by caller chain (engine/framework boundary via
  `segments.json`; routes tagged `via drawTextFromAtlas`). Per the O1 methodology lesson,
  shadow percentages are an UPPER BOUND on minified reality.
- **Counts / falsification**: real minified build with the upgraded `--text` instrument
  (per-phase × per-class paints/rebuilds via `_createRefreshOrGetBackBuffer`, immutable-buffer
  LRU capacity/occupancy/evictions, per-phase per-string render tallies, sampled hot-string
  stacks) and `--cwc`.
- ⚠ **Harness rot fixed en route** (`prof-interactive.js` was silently broken by arcs landed
  after its last use): 3× `instanceof WindowWdgt` (class renamed to `FrameWdgt` 2026-07-19) →
  the polymorphic `isFrame?.()`; `world.changed()` (privatized by the invalidation-privacy arc)
  → `wallpaper.setPattern(...)` / dropped after `moveTo`; the `--text` hit/miss wrap targeted
  the deleted public `createRefreshOrGetBackBuffer` name → `_createRefreshOrGetBackBuffer`;
  the draw phase picked the "Drawings Maker **info**" document over the actual paint window
  (both match `/Drawing/i`; the info window opens later and won a bare `.pop()`).

## Results — where `_drawImageInternal` time goes (shadow %, drag = the felt workload)

Drag phase, `_drawImageInternal` self = **12.3% of busy** (3501 ms of 28459 ms busy; §5B said
9.6% on the smaller desktop — same ballpark):

| share | route |
|---|---|
| **73.2%** | glyph blits: `fillText → drawTextFromAtlas → #drawColoredTextBatched → drawImage` — **direct per-frame text rendering by custom painters**, NOT buffer rebuilds |
| 19.6% | back-buffer blits, normal paint pass (`paintIntoAreaOrBlitFromBackBuffer` under `fullPaint…`) |
| 6.9% | back-buffer blits, **shadow pass** (`…ContentPotentiallyAsShadow`) |

Draw phase: `_drawImageInternal` = 6.9% of busy, **~0% glyph route** — 71.6% normal-pass /
28.4% shadow-pass back-buffer blits. Covered phase: 6.3% of busy, same split (72.7/27.2).
The shadow pass is a steady **~27% of back-buffer blit time in every phase**.

## Who the 73% is — the spreadsheet's direct-fillText cells

The only direct-`fillText` painters in `src/` are `spreadsheet/SheetHeaderCellWdgt.coffee:90`
(column-letter / row-number headers) and `spreadsheet/CellWdgt.coffee:132` (scalar cell
values) — the F5 "the sheet paints nothing, cells paint everything" flip painted label text
straight to the context with no back buffer. (Plus the marginal
`icons/FizzygumLogoWithTextIconAppearance` — 40 renders per drag run.) Minified per-phase
per-string tallies:

- **drag**: 175× "D"/"E"/"F" in 146 frames — headers re-render on every frame the drag path
  damages the sheet's screen area.
- **draw**: every header ~2×/frame (~165–189× in 85 frames) — the ×2 is the unified shadow
  mechanism painting content once for the shadow silhouette and once normally.
- **covered**: 187× "B"/"C"/"D"/"E" in 183 **input-free** frames — the steady ambient damage
  corridor (clock animation) reaches the sheet's header row every single frame.

Colored cell/header text takes SWCanvas's `#drawColoredTextBatched` path; header strings are
1–2 glyphs, so the per-`drawImage`-call setup dominates — exactly the per-glyph-blit shape O4
hypothesized, but concentrated in ONE widget family rather than spread across all text.

## Falsified hypotheses (recorded so they are not re-chased)

- **LRU thrash**: `cacheForImmutableBackBuffers` capacity 1000, occupancy 23→175 over the whole
  run, **0 evictions**; drag-phase rebuilds ≈ 0 (2 total, "view-only"). The immutable-buffer
  cache is healthy with >5× headroom on the busy desktop.
- **Ordinary labels re-rendering text**: `StringWdgt`/`TextWdgt`/`SimpleTextWdgt` rasterize
  text only on a REBUILD; steady-state they blit whole cached buffers (the 19.6% + 6.9%
  routes). The ~1,030 idle-phase rebuilds are the boot glyph-atlas warm-up epoch bumps
  (`immutableBackBufferGeneration`) — a one-time cost, not a per-frame one.
- **Colored-glyph canvas-wide compositing** (the 2026-07-08 finding): `--cwc` now counts **0**
  calls — the batched colored-text path no longer triggers it.

## Fix directions (ranked; NOTHING implemented — O4 stays investigate-first)

1. **O4a — cache spreadsheet cell/header text pixels (Fizzygum-side, small).** Route
   `CellWdgt`/`SheetHeaderCellWdgt` label painting through the immutable back-buffer cache
   (StringWdgt's keying discipline; LRU headroom proven above). Kills ~73% of the drag
   `_drawImageInternal` cluster at the source, plus the span-fill/tint work above it in the
   same chains. Byte-identity gate applies; the F5 text relocation precedent proved cell-text
   placement byte-exact, which bodes well.
2. **O4b — SWCanvas glyph-RUN batching (engine-side, medium).** One `drawImage` per glyph run
   instead of per glyph — the per-call setup dominates for 1–2-glyph strings. Helps every
   direct-fillText consumer forever, but engine-side with byte-identity risk on the colored
   batched path. Only worth doing if direct text is still hot AFTER O4a.
3. **O4c — observation, banked**: the shadow pass is a steady ~27% of back-buffer blit time in
   all phases; any future shadow-blit caching/skip idea starts from that number.
4. **Composes with O3**: the covered-phase per-frame header repaints are ambient damage
   reaching widgets a per-widget occlusion pass would skip — O3 attacks the same cost from the
   damage side, O4a from the paint side; independent, both real.

Sanity anchor: minified drag median 27.9–29.2 ms across the three count runs ≈ the §5B-era
~28 ms despite the bigger desktop — no regression hiding under this analysis.

Raw artifacts: `/tmp/fizzygum-profiling/o4.plain.{drag,draw,covered}.cpuprofile` +
`o4-minified-counts*.log` (session-local; regenerate with the commands above).

---

## ⚠ CORRECTION + O4a results (same day, after landing the fix)

O4a went through TWO same-day shapes, both byte-identical, only the second committed:
first a cached-raster blit (a `cellTextBufferFor` helper on the sheet — its byte-identity
spike-proven at dpr1+dpr2 via `Fizzygum-tests/.scratch/probe-o4a-text-buffer.js`, whose one
dpr2 scare was the probe's own unbalanced save/restore: `useLogicalPixelsUntilRestore` does
NOT save, the caller must — then gauntlet-proven 13/13 with zero reference changes); then,
on the owner's uniformity decision ("scalar text is a StringWdgt child, period"), the FINAL
shape — see the section below — which deleted the raster helper again. The interim shape's
A/B FALSIFIED part of the attribution above — recorded here so the wrong number doesn't
propagate:

- **The headline "73% of drag `_drawImageInternal` = spreadsheet direct-fillText" conflated
  TWO phenomena sharing one chain shape.** After O4a, the minified per-phase render counts
  collapse exactly as predicted — **drag 964→42, draw 3209→48, covered 774→2** (the survivors
  are the desktop logo's fillText + 2 legitimate rebuilds) — yet the shadow drag profile
  STILL shows ~74% of `_drawImageInternal` under the fillText route, while draw/covered show
  ~0% in BOTH runs. The 73–74% shadow share is therefore dominated by the **one-time
  glyph-atlas warm-up rebuild storms** (each atlas arrival resets
  `cacheForImmutableBackBuffers`, rebuilding every visible text widget): on the ~3× slower
  shadow build the warm-up stretches into the FIRST profiled phase (drag). The real
  steady-state spreadsheet stream existed (the minified counts prove it) but is the smaller
  of the two contributions.
- **Corrected steady-state model:** `_drawImageInternal` ≈ 7% of busy in text-quiet phases,
  split ~72% normal-pass / ~28% shadow-pass back-buffer blits. The per-frame direct-text
  waste is now eliminated by construction; its dpr1 wall-clock value was **within run noise**
  (drag median 29.3 vs 27.9–29.2 before) — the O1 pattern again: a correct-form fix, not a
  big lever.
- **Consequences for the ranked directions:** **O4b (SWCanvas glyph-run batching) loses its
  urgency** — the steady-state glyph stream is now just the logo; do not build it on these
  numbers. **O4c (shadow pass ~27% of blit time, every phase) stands** as the remaining real
  observation. **NEW (banked observation): the boot/atlas-warm rebuild storm** (~1,030 text
  rebuilds per reset, one reset per atlas arrival, batched) is a BOOT-time cost, not a
  frame-time cost — only worth attention if boot feel ever matters.
- **Methodology lessons (add to O1's):** (1) on a shadow build, the first profiled phase
  inherits warm-up transients — warm up longer or profile a later phase before trusting it;
  (2) a caller-chain attribution whose middle frames are `(anonymous)` can conflate distinct
  phenomena — corroborate with per-phase counts on the minified build before naming a
  culprit.

O4a artifacts: `/tmp/fizzygum-profiling/o4a-after-counts.log`,
`o4a.plain.{drag,draw,covered}.cpuprofile` (session-local).

---

## Final shape (same day): scalar text is a StringWdgt child, period

Owner design decision on reviewing O4a: rather than a bespoke cached-raster paint, the
spreadsheet's text becomes REAL WIDGETS — completing the sheet's own F5 "everything visible
is a widget" north star. As landed:

- `CellWdgt` presents branch-3 scalar/error text as a passive `StringWdgt` child (the overlay
  editor's exact configuration: `isEditable` false, fontSize 12); `SheetHeaderCellWdgt` holds
  its label the same way, relabelled in place on scroll via `_setTextNoSettle`'s no-change
  guard from the sheet's chrome ensure. The interim `cellTextBufferFor` raster helper is
  DELETED — StringWdgt's standard immutable back buffers now provide the caching for free.
- **Byte-identical anyway — zero recaptures.** The first build shifted every label to
  StringWdgt's natural TOP/LEFT placement (measured off the failing screenshots: a pure
  (−4, −2) translation of pixel-identical glyph rasters — 18 spreadsheet tests red, every
  VALUE assertion green). A **(+4, +2) inset of the child's box** restores the exact
  pre-conversion text position: suite 265/265 ×3 engines, full gauntlet 13/13, no reference
  changed. (The overlay editor keeps its full-cell placement, as always shipped.)
- **One serialization-rig expectation updated** (`spreadsheet.roundtrip.midEditClean`): a
  restored scalar cell now legitimately owns ONE child — the check now asserts that child IS
  the scalar-text widget and no editor survived (stronger than the old zero-children form).
- **The perf outcome carries over unchanged**: per-frame direct-text renders drag 42 /
  draw 48 / covered 2 (vs 964/3209/774 before O4a — the survivors are the desktop logo),
  LRU at 189/1000 with 0 evictions, frame medians within run noise (drag 29.9 ms).

Artifact: `/tmp/fizzygum-profiling/stringwdgt-after-counts.log` (session-local).

**Edit-mode UX follow-up (owner-reported, same day):** two gaps surfaced on review — no
visual hint that an edit is in progress (the F2 buffer model deliberately mounts no
`CaretWdgt`: a live caret is a keyboard receiver, and the sheet must stay sole receiver),
and the editor's full-cell mount made text shift top-left vs resting. Fix: `StringWdgt`
gained a dormant **`showsEndOfTextBar`** flag — a steady 1px bar after the last glyph, drawn
into the back buffer (a pure function of the text: deterministic, never blinks, tracks every
buffer change through the normal cache-key miss) — and the cell's editor now mounts at the
**same (4,2) inset** as the resting child, so resting ≡ editing glyph positions exactly.
Blast radius: 3 benign StringWdgt-inspector member-list recaptures (the new prototype field)
+ NEW pinning test `SystemTest_macroSpreadsheetEditCaretBar` (mid-edit screenshot with the
bar + value-asserted position equality editor↔resting child). Suite 265→266; recapture gate
COMPLETE; closing gauntlet 13/13.
