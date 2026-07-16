# Fractional widget `@bounds` — investigation + (maybe) enforcement plan

**Status:** ✅ RESOLVED 2026-07-15 (Option B — enforce integer placement everywhere, then hard-gate it).
Authored 2026-07-15 at the tail of the plot-uncollapse-crash arc (Fizzygum `cc4c01d4` mixin fix +
`Widget._assertBoundsFinite` guard; `fbc2a3a4` `debugIfFloats` removal). The original investigation body
(finding, probe, data, open questions, options) is preserved below for provenance; the outcome is here.

---

## RESOLUTION (2026-07-15)

**Q1 (adverse effects of the pre-existing fractional bounds): NONE** — byte-exact suite, no crash; the
blit path double-rounds and the back-buffer blit rounds, so fractional origins were invisible on screen.
**Q2 (deliberate?): YES** — the arrange-apply path was designed in 2015 to *trust pre-rounded input and
assert it* (via `debugIfFloats → debugger`); that assertion was silently stubbed to a no-op in 2018 and
deleted in 2026, so the invariant lapsed unenforced for ~8 years (git archaeology: `52998cc0`, `0148f87f`).
No prior session had audited the apply path; the invariant doc `integer-pixel-placement-and-sizing.md`
over-claimed enforcement it didn't have (now corrected).

**What shipped (Option B): round at each PRODUCER, then a permanent hard-gate.** Owner steer: fix each
container's arrange individually (NOT a blunt chokepoint in `_applyMoveByBase`); use the guard's stacks to
find producers, fix at the upmost sensible layer. Producers rounded:
- `AxisWdgt` — tick/label positions (`tickHeight` stays a fractional MEASURE; positions round).
- `SimpleVerticalStackPanelWdgt` — child `targetPos` (running `stackHeight` stays EXACT → no drift).
- `SliderButtonWdgt.nonFloatDragging` — plane-local target (inverse-island mapping is fractional).
- `Widget._reLayout` horizontal-stack distribution — round each child BOUNDARY, carry EXACT running position.
- `Widget._reLayout` corner-internal — round `minDim` (used for extent AND right/bottom-anchored position).
- `LabelButtonWdgt` / `MenuHeader` — round `@center()`-based label centring (odd-extent `.5`).
- `ConsoleWdgt` — round the shared `/2` button width.

**Guard:** `Widget._assertBoundsWellFormed` (renamed from `_assertBoundsFinite`, which checked finiteness
only) now also `console.error`s `NON_INTEGER_GEOMETRY` on a fractional applied `@bounds`, wired into BOTH
headless runners' fail-gate (like `NON_FINITE`). Suite-wide count: **0**.

**Verification:** full gauntlet GREEN — dpr1 / dpr2 / WebKit / apps / paint / tiernaming / settle / capstone
/ refs all PASS, `geometry-violations: 0`. **11 tests recaptured** (2 plots + 2 edit-mode + 5 horizontal-stack
churned at dpr1; + `macroLayoutBasicProportions` + `macroSampleSlideEditViewToggle` churned only at dpr2).

**⚠ CASE-LAW — the divider-drag reproportion is sub-pixel-sensitive.** Rounding the horizontal-stack cell
bounds is byte-identical for STATIC layouts but shifts `macroStackDividerReproportionsCells` by **37–57px**:
the reproportion applies micro-moves gated on a float-equality check (`prev == newone` in
`StackElementsSizeAdjustingWdgt.nonFloatDragging`), and rounding nudges the trajectory onto a *different but
still deterministic* path (WebKit + dpr2 confirm cross-engine determinism). This is the owner's "fractional
carries division precision" hypothesis, realized — but the owner chose integers-only + recapture over an
exception. If you touch the horizontal-stack arrange or the reproportion, expect this test to move and
recapture it; do NOT chase the ≤1px→large amplification as a bug.

---

## Orientation (cold start — skip if you already know Fizzygum)

- **Fizzygum** is a CoffeeScript GUI framework (a canvas "web OS", descended from Morphic.js). Source is
  ~470 `.coffee` files that ship as *text* and compile in-browser; there are **no imports** — every class
  is a global. Widgets form a tree; each has a `@bounds` (a `Rectangle` of two `Point`s, `origin`+`corner`).
- **Umbrella layout** (the umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is NOT a git repo; it holds
  three sibling git repos): **`Fizzygum/`** = framework source (edit here) · **`Fizzygum-tests/`** =
  the SystemTest suite + harness · **`Fizzygum-builds/`** = generated build output (never hand-edit).
- **Read these first:** `/Users/davidedellacasa/code/Fizzygum-all/CLAUDE.md` (umbrella router),
  `Fizzygum/CLAUDE.md` (build/architecture), `Fizzygum-tests/CLAUDE.md` (tests), and this issue's anchor
  **`Fizzygum/docs/integer-pixel-placement-and-sizing.md`** (the invariant under investigation).
- **Build/test commands** (the `fg` wrapper is path-correct from any cwd — always call it by absolute path):
  - Build: `/Users/davidedellacasa/code/Fizzygum-all/fg build` (output → `Fizzygum-builds/latest/`).
  - Full regression gate (~5 min, native + SWCanvas + WebKit, all densities + gates):
    `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` — launch in the BACKGROUND, read
    `/tmp/fg-gauntlet.verdict` when done; NEVER foreground-poll.
  - Single-shot suite: `cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests && node scripts/run-all-headless.js --dpr=1`.
- **Backends:** the world renders to native HTML5 canvas by default, or a deterministic **SWCanvas**
  software backend under **`?sw=1`** (what the owner profiles with, and what the SystemTest suite runs —
  it is byte-exact). Tests match SWCanvas screenshots by raw-pixel hash.
- **Owner working rules that apply here:** never commit/push autonomously — present a summary + message and
  wait for explicit approval (push always needs a separate OK); a plan file must be runnable cold (this
  one); state nothing as "safe/byte-identical" before a gate actually passed.

---

## TL;DR

While adding the always-on **non-finite** `@bounds` guard (`Widget._assertBoundsFinite`, called from the
~6 bounds-commit leaves), the owner asked: widgets shouldn't be *placed/sized* in fractional pixels — are
we already good? A one-off **integer** check bolted onto the same guard says: **No.** Widgets DO get
committed with fractional `@bounds` at ~24 distinct sites across **9 classes / 9 tests** — but the **full
suite still PASSES** (paint rounds the pixels), so the pixels are correct today; the *internal* geometry
just violates the documented integer-placement invariant. We **reverted** the exploratory check (kept only
the non-finite guard) and deferred the real investigation here.

The invariant itself is documented in **`docs/integer-pixel-placement-and-sizing.md`** — read it first; it
explains WHY integer placement matters (notably the back-buffer byte-identity caveat) and what is
*legitimately* fractional (internal content rendering: rotated strokes, sub-pixel vector, charts).

---

## What was found (concrete, dpr-1 full-suite sweep, 2026-07-15)

Root cause is ONE thing: **the move-APPLY path does not round the position.** `_moveToNoSettle` (the
*desired*-position setter) rounds (`aPoint = aPoint.round()`), and the extent commits
(`__commitExtent/Width/Height`) round the *extent* — but `_applyMoveTo → _applyMoveToBase → _applyMoveByBase`
(`@bounds.translateBy delta`) and `_applyBounds` (`@bounds.translateTo newBounds.origin`) commit the
position **verbatim**. So any layout/drag that computes a fractional position (proportions, `/n` divisions,
transform inverses) commits it. The `__commitExtent`/`_applyBounds` fractional hits are *downstream* — they
inherit an already-fractional origin (the extent is integer, the origin isn't).

Distinct `(class, via-site)` that committed a fractional `@bounds` (deduped; `via` = the commit leaf):

| class | via leaves seen |
|---|---|
| `StringWdgt` | `__commitExtent`, `_applyMoveByBase`, `_applyBounds` |
| `RectangleWdgt` | `_applyMoveByBase`, `__commitExtent` |
| `StackElementsSizeAdjustingWdgt` | `_applyMoveByBase`, `__commitExtent` |
| `SliderButtonWdgt` | `_applyMoveByBase` |
| `SimpleButtonWdgt` | `_applyBounds`, `__commitExtent` |
| `PencilIconWdgt` | `_applyMoveByBase`, `__commitExtent` |
| `LayoutSpacerWdgt` | `_applyMoveByBase`, `__commitExtent` |
| `HighlighterWdgt` | `_applyBounds`, `__commitExtent` |
| `EditableMarkWdgt` | `_applyMoveByBase` |

Tests that surfaced them (there are surely more — the suite dedupes per shard, and only tests that
exercise these layouts hit it): `macroDragEmbedWindowTransitNeverArms`,
`macroInspectorWorkAreaEvaluatesCoffeeScript`, `macroIslandBufferCacheByteIdentity`,
`macroLayoutBasicProportions`, `macroPlotUncollapseKeepsRendering`, `macroSampleDashboardPlots`,
`macroSliderDragTracksAxisInRotatedIsland`, `macroSpreadsheetSliderCell`,
`macroStringWdgtAndTextWdgtResizingInLayout`.

Representative stacks (the three source *shapes*):
- **Proportional layout:** `LayoutChromeWdgt._reLayout → _applyMoveTo(44.997500416597234, …) →
  _applyMoveByBase` → `StackElementsSizeAdjustingWdgt` bounds `44.9975…,0 -> 94.9975…,40`
  (test `macroLayoutBasicProportions`). Proportion math (`* fraction`) not rounded before the move.
- **Axis ticks (thirds):** `AxisWdgt`/plot `_reLayout → _applyMoveTo(1, 0.3333…) → _applyMoveByBase` →
  `RectangleWdgt` bounds `1,0.3333… -> 51,40.3333…` (test `macroSampleDashboardPlots`). Tick spacing
  `height/(numberOfTicks+1)` (a `/3`, `/6`, …) not rounded.
- **Slider drag through a rotated island:** `SliderButtonWdgt.nonFloatDragging → _applyMoveTo(621,
  211.76604444311897) → _applyMoveByBase` (test `macroSliderDragTracksAxisInRotatedIsland`). Pointer
  mapped through the inverse island rotation → fractional plane-local position.

**Key nuance:** the suite is byte-exact and it PASSES with these fractional bounds, because paint rounds:
`Widget.calculateKeyValues` does `area = clippingRectangle.intersect(@bounds).round()`, so the *drawn*
rectangle is integer regardless. So fractional `@bounds` is invisible on screen **today**. The open
question is whether it is invisible EVERYWHERE (see below).

---

## How to reproduce (the throwaway probe — re-add, build, sweep, then REVERT)

Add the `else` branch back to `Widget._assertBoundsFinite` (`src/basic-widgets/Widget.coffee`), right after
the existing non-finite `console.error`:

```coffee
    else unless Number.isInteger(o.x) and Number.isInteger(o.y) and Number.isInteger(c.x) and Number.isInteger(c.y)
      # EXPLORATORY: a widget's PLACED+SIZED @bounds should be integer pixels (fractional is fine for internal
      # content -- rotated strokes, sub-pixel vector -- but not for a widget's box). Dedupe by class+site so a
      # frequent offender logs once; message shows RAW coords (@bounds.toString rounds).
      window.__fractionalSeen ?= new Set()
      key = "#{@constructor.name}|#{where}"
      unless window.__fractionalSeen.has key
        window.__fractionalSeen.add key
        console.error "FRACTIONAL_GEOMETRY: #{@constructor.name} committed fractional @bounds #{o.x},#{o.y} -> #{c.x},#{c.y} via #{where}\n" + (new Error()).stack
```

Then (from the umbrella): `/Users/davidedellacasa/code/Fizzygum-all/fg build` then
`cd Fizzygum-tests && node scripts/run-all-headless.js --dpr=1 > /tmp/frac.log 2>&1`, and mine the log:
`grep -oh "FRACTIONAL_GEOMETRY: [A-Za-z0-9]* committed fractional @bounds [-0-9.,]* -> [-0-9.,]* via [A-Za-z_]*" /tmp/frac.log | sort -u`.
(Note: `FRACTIONAL_GEOMETRY` is NOT wired into the runners' fail gate — only `NON_FINITE_GEOMETRY` is — so
the suite still passes and you just read the log.) **Revert the branch when done** (do NOT ship it as-is:
it would flood logs / need the 9 sources rounded first). Consider a dpr-2 sweep too — HiDPI may expose more.

---

## OPEN QUESTIONS to answer BEFORE deciding to enforce

1. **Are there ANY adverse effects today, or is it purely cosmetic-internal?** Paint rounds, so screens are
   fine — but check the paths where integer placement is load-bearing per
   `docs/integer-pixel-placement-and-sizing.md`:
   - **Back-buffer byte-identity** (`BackBufferMixin`): a widget cached to an offscreen buffer and blitted
     must be byte-identical to a direct draw; the doc says integer placement is *necessary but not
     sufficient*. Does a fractional-bounds widget with a back buffer diverge? (`macroIslandBufferCacheByteIdentity`
     is in the offender list — suggestive; confirm it's benign.)
   - **Hit-testing / broken-rect** off-by-one at fractional edges.
   - **Affine islands** (`screenBounds`/`localPointToScreen`): the slider case is IN a rotated island —
     is the fractional plane-local position expected there, or should plane-local still be integer?
2. **Did a prior session (last ~2 weeks) already investigate this or an adjacent issue?** Very possibly —
   the geometry/layout area was heavily worked. CHECK before re-deriving:
   - `docs/integer-pixel-placement-and-sizing.md` (the invariant doc — does it already acknowledge these
     violations / say they're accepted?).
   - The memory index `~/.claude/projects/-Users-davidedellacasa-code-Fizzygum-all/memory/MEMORY.md` — the
     layout/affine/deferred-layout arcs (`layout-simplification-pass-and-followons`,
     `fizzygum-relayout-bounds-first-gate`, `affine-transforms-plan-authored`,
     `fizzygum-deferred-layout-plan`, the `perl-inline-edits-deindent-coffee` note mentions
     `debugIfFloats`), and any note about integer/rounding.
   - `git log` around `_applyMoveByBase` / `_applyMoveTo` / `_moveToNoSettle` for prior rounding decisions
     (why does the DESIRED path round but the APPLY path not? Was that deliberate — e.g. to preserve a
     fractional *desired* geometry that only rounds at final placement?).
   - The removed `debugIfFloats` hooks (gone in `fbc2a3a4`) were the ORIGINAL fractional-detector — git
     history of what they used to assert may show the original intent + why they were stubbed.

---

## Options (decide AFTER the questions above)

- **A — leave it (current state).** Accept fractional `@bounds` as a benign internal reality; the non-finite
  guard stays. Zero risk. (This is where we are.)
- **B — enforce: round the position on the APPLY path.** Round in `_applyMoveByBase` /
  `_applyMoveToBase` (and the `_applyBounds`/`_commitBounds` origin move) so every placement is integer.
  MIGHT be largely pixel-neutral (paint already rounds to the same integer), BUT rounding at commit vs at
  paint can differ at exact `.5` boundaries → possible screenshot churn → gauntlet + targeted recaptures.
  Watch: the DESIRED-vs-APPLIED split may be deliberate (a stretchable panel keeps *fractional desired*
  geometry and rounds only at placement — see `positionFractionalInHoldingPanel`); rounding the apply path
  must not destroy that fractional *memory*, only the committed *bounds*. Then the exploratory check can
  become a permanent HARD gate (wire `FRACTIONAL_GEOMETRY` into the runners like `NON_FINITE_GEOMETRY`).
- **C — warning-only tripwire.** Ship the check as a non-failing log (or a gate that fails only on NEW
  offenders vs a committed baseline list) to stop the set GROWING while leaving today's benign ones. Cheap;
  keeps the door open for B later.

**Recommendation:** answer Q1/Q2 first. If Q1 shows a real adverse effect (esp. back-buffer divergence),
do **B** for at least the offending path. If it's purely internal-cosmetic and a prior session already
concluded "accepted", **A** + a one-line note in `integer-pixel-placement-and-sizing.md` that the apply
path is deliberately un-rounded. **C** is the middle ground if we want to prevent regression without the
recapture cost now.

---

## Provenance

Found while wiring the geometry guard for the plot-uncollapse crash (see the `Widget._assertBoundsFinite`
doc-comment + the SystemTest `macroPlotUncollapseKeepsRendering`). The non-finite half shipped; this
fractional half is the deferred remainder. Owner's framing: "Points and Rects could be fractional for a
bunch of good reasons, but I don't think widgets can be located and sized in fractional terms for good
reasons, and I think we MIGHT be already good there" — the sweep showed we are NOT already good, but it is
benign so far.
