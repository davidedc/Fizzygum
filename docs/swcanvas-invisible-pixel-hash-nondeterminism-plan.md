# SWCanvas invisible-pixel hash nondeterminism — problem + handling (DRAFT)

**Status:** DRAFT / parked (2026-07-06). Not scheduled. Written after the drag-embed Phase 3 arc surfaced a
concrete instance. This is a *diagnosis + options* draft, not a fully-designed solution — it deliberately leaves
the mechanism confirmation and the final choice open.

## §1 — The problem, precisely

The SystemTest suite matches SWCanvas renders by a **raw-pixel SHA-256** (`dataHash`), NOT by comparing the PNG
files. Two code paths compute it and MUST agree (`Fizzygum-tests/CLAUDE.md` records this sync constraint):

- **Live (in-browser, at run/capture time):** `AutomatorPlayer.coffee:180` —
  `liveHash = SHA256.hashRawPixels renderCanvas.width, renderCanvas.height, renderCanvas.data`. The input is the
  SWCanvas framebuffer `renderCanvas.data` — the raw, non-premultiplied RGBA byte array, **including every
  pixel's R,G,B even where A (alpha) is 0**.
- **Offline (Node, recompress/verify):** `scripts/recompress-swcanvas-references.js` `rawPixelHash()` — SHA-256
  of `[width u32 BE][height u32 BE][raw RGBA8 bytes]`, where the RGBA comes from decoding the stored `.png`.

A reference stores its `dataHash` in its filename; the loader matches `liveHash` against it. **The `.png` is
"same bytes, for browsing" — it is NOT the thing compared.**

**The failure we hit (drag-embed Phase 3, `macroDragEmbedCandidateChangeResets`):** a test's frame produced a
`dataHash` that *differed between the capture run and fresh suite runs*, yet the two exported **`.png` files were
byte-for-byte pixel-identical** (confirmed: PIL `ImageChops.difference` bbox = `None`, i.e. R,G,B,A all equal).
Fresh runs were internally STABLE (same hash 3/3) — so this is NOT run-to-run chaos; it is a **capture-env vs
run-env** difference in bytes that are **invisible** and that **do not survive to the PNG**. The trigger was a
charging-ring ephemeral declared then immediately torn down (a rapid move→release), whose transient render left
different byte content in pixels the composited/encoded image doesn't show.

So: **a byte-exactness test can FAIL with ZERO visible difference**, because the hash covers bytes (R,G,B under
A=0, or otherwise-invisible pixels) that the eye and the PNG both ignore. That is the whole bug class.

⚠ This is distinct from the *legitimate* determinism bugs `DETERMINISM.md` covers (real visible pixel divergence
at dpr2 under load). Diagnosis tell: **if the dumped `.png`s are pixel-identical but the hashes differ, it is
THIS bug, not a visible-render nondeterminism.** (Phase 3 side-stepped it in-test by asserting a mid-drag frame
instead of the post-teardown frame; that is a workaround, not a fix.)

## §2 — Mechanism (needs one confirmation step)

Working hypothesis: the SWCanvas framebuffer holds **nondeterministic R,G,B in pixels that contribute nothing to
the visible/encoded image** — most likely fully-transparent (A=0) pixels left behind when a region is "erased"
by writing alpha 0 without canonicalising R,G,B (an ephemeral's back-buffer region, a cleared overlay, an
anti-aliased/temporary composite). The PNG export flattens or normalises these away (hence identical PNGs); the
raw-buffer hash does not (hence different hashes).

**FIRST STEP before choosing a fix — confirm it:** dump `renderCanvas.data` (not the PNG) from two runs of the
repro (`macroDragEmbedCandidateChangeResets` post-drop frame is a ready-made repro, or re-add a tiny harness hook
to emit the raw buffer), diff byte-by-byte, and for each differing byte record its pixel's alpha. Expected: all
differing bytes are R/G/B of A=0 (or otherwise not-composited) pixels. If instead they are visible pixels, this
is a *different* bug (a real render nondeterminism) and belongs in `DETERMINISM.md`, not here.

## §2.5 — How to reproduce

⚠ The committed `macroDragEmbedCandidateChangeResets` does **NOT** reproduce this any more — it was deliberately
RESTRUCTURED (Phase 3) to assert a mid-drag frame instead of the post-drop frame, precisely to dodge this bug. So
a repro must reconstruct the *original* "post-drop frame after a rapid drag-embed teardown" shape. Two ways:

### (a) Reconstruct the trigger macro (the historical repro)
Author a throwaway macro that captures the frame right after a rapid charging-ring teardown. Essential shape (all
distances/panels are just to place two receptive PanelWdgt candidates side by side; the key is *arm over one,
move onto the other, release AT ONCE, screenshot the post-drop frame*):

```
# two PanelWdgt candidates A (left) + B (right); an empty `new WindowWdgt nil,nil,nil` payload
payload.pickUp()
# ARM over A: carry to A's centre, `yield 600` (NON-SCALED), a 3px nudge to fire the arming event
@syntheticEventsMouseMove_InputEvents (@pointAtFractionOf panelA,[0.5,0.5]), "no button", 600
yield "waitNoInputsOngoing"
yield 600
@syntheticEventsMouseMove_InputEvents ((@pointAtFractionOf panelA,[0.5,0.5]).add new Point 3,0), "no button", 200
yield "waitNoInputsOngoing"
# move onto B and release AT ONCE (no linger) — B's charging ring is declared then torn down on the drop
@syntheticEventsMouseMove_InputEvents (@pointAtFractionOf panelB,[0.5,0.5]), "no button", 400
yield "waitNoInputsOngoing"
@syntheticEventsMouseClick_InputEvents()
yield "waitNoInputsOngoing"
takeScreenshot_InputEvents_Macro "SystemTest_<name>_image_0"   # <-- THE post-drop frame that flakes
```

Then, from `Fizzygum-tests/`, capture it at both densities and watch the capture's own verify leg:

```
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests
node scripts/capture-macro-test-references.js SystemTest_<name> --clean --dprs=1,2
# EXPECT: "verify dpr=2 did NOT pass — the just-captured ref did not re-match."  (dpr1 usually passes.)
```

That message — the capture bakes one raw buffer, the immediately-following verify run produces a *different* raw
buffer — is the bug surfacing. (It reads like the script's benign "pre-settle frame" note, but here it is stable,
not pre-settle: see (b).)

### (b) Confirm it IS this bug (the signature — works for ANY suspected instance)
The tell is **stable-but-invisible hash divergence**:

```
# 1) fresh runs are SELF-CONSISTENT (rules out ordinary run-to-run nondeterminism): same live hash every time
for i in 1 2 3; do node scripts/run-macro-test-headless.js SystemTest_<name> --dpr=2 --dump-failures 2>&1 \
  | grep -oE "dpr2/SystemTest_<name>_image_0-[^ ]*dataHash[a-f0-9]{16}"; done
#   → the SAME dataHash all three times, but DIFFERENT from the committed reference's hash.

# 2) the dumped live PNG and the committed reference PNG are PIXEL-IDENTICAL:
python3 -c "
from PIL import Image, ImageChops
ref  = Image.open('tests/SystemTest_<name>/automation-assets/.../ceilPixRatio_2/..._image_0-...png').convert('RGBA')
live = Image.open('.scratch/SystemTest_<name>/dpr2/..._image_0-...png').convert('RGBA')
print('diff bbox', ImageChops.difference(ref, live).getbbox())   # None == R,G,B,A all identical
"
```

If step 2 prints `diff bbox None` (identical pixels) while step 1 shows a stable-but-mismatched `dataHash`, it is
THIS bug — invisible bytes in the raw buffer, not a visible render difference. (If the PNGs DO differ, it is an
ordinary DETERMINISM.md render nondeterminism, not this.) The raw-buffer byte diff in §2 then localises exactly
which pixels/channels (and their alpha) carry the invisible residue.

Cheapest smallest-possible repro to try first: a single receptive panel + a window, charge the ring briefly, drop
AT ONCE, screenshot the post-drop frame at dpr2 — minimise everything else and see if the ring teardown alone is
enough (it isolates the charging-ring `DragChargingRingWdgt`/reconciler-teardown path as the suspected source).

## §3 — Options for handling

### Option A — Make the hash perceptual (canonicalise invisible pixels before hashing) + BACKFILL
Change BOTH hashers to zero (or otherwise canonicalise) the R,G,B of pixels that can't affect the visible image —
minimally `if A == 0: R=G=B=0` — before feeding bytes to SHA-256. The hash then reflects only what is seen.
- **Backfill required:** every stored reference's `dataHash` changes, so all references must be re-hashed and
  renamed (the hash is in the filename). Mechanical and scriptable (decode PNG → canonicalise → re-hash → rename;
  the recompress script already has a from-scratch PNG decoder to build on). ~all SWCanvas refs across the suite.
- **Sync constraint:** `SHA256.coffee` (`hashRawPixels`) and `recompress-swcanvas-references.js` (`rawPixelHash`)
  must apply the IDENTICAL canonicalisation, forever (they already must produce identical digests).
- **Pro:** robust — invisible differences can NEVER fail a test again, whatever the render leaves behind. Aligns
  the contract with intent ("test what's visible").
- **Con:** one-time mass backfill; widens the hashing contract; a subtle rule both hashers must keep in lockstep.
- **Care:** canonicalise ONLY genuinely-invisible pixels. A=0 over an opaque desktop is safe (own R,G,B never
  shows). Partial alpha (1..254) IS visible (composited) — its R,G,B must still be hashed. Confirm in §2 that the
  residue is A=0 (or define "invisible" precisely) before picking the predicate.

### Option B — Never erase via alpha alone: canonicalise transparent pixels in the render/clear path
Fix the source: wherever the framework/SWCanvas clears or tears down a region by dropping alpha, also write a
canonical R,G,B (e.g. clear to `rgba(0,0,0,0)` rather than leaving stale colour under A=0). Then the raw buffer is
deterministic and the existing hashing needs no change, no backfill.
- **Pro:** targeted; no hashing-contract change; no backfill; keeps the hash a faithful raw-buffer check.
- **Con:** must FIND every erase/teardown path that can leave stale colour (ephemeral back-buffers, overlay
  clears, `changed()`/repaint of a destroyed widget's region, any SWCanvas clearRect that only touches alpha).
  Whack-a-mole risk — a future new erase path reintroduces the flake, silently, until a test happens to catch it.
- **Likely locus:** the ephemeral reconciler teardown + `DragChargingRingWdgt`/`*Appearance` region clearing, and
  whatever SWCanvas primitive backs "clear to transparent". Start there (that is what the Phase-3 repro exercised).

### (Option C — do nothing / workaround per-test) 
Keep asserting only settled/visible frames and avoid capturing right after a rapid ephemeral teardown (what
Phase 3 did). Cheap, but leaves a latent trap for every future author and every ephemeral-heavy frame. Not
recommended as the end state; fine as the interim.

## §4 — Recommendation lean (not final)

Lean **Option A** (perceptual hash + backfill): it kills the entire class rather than one instance, and the
backfill — while broad — is mechanical and one-time. Option B is cleaner in spirit (the raw buffer *should* be
deterministic) but is open-ended (no guarantee all erase paths are found, and new ones will regress silently).
A pragmatic combo is possible: do A for the guarantee, AND fix the specific egregious erase path from §2 so the
raw buffer is also cleaner. Decide after the §2 confirmation.

## §5 — Open questions
- Confirm the residue is exactly A=0 pixels (or characterise precisely what's invisible-yet-hashed) — §2.
- Does the PNG export flatten over an opaque background, or store RGBA and just happen to match? (Affects whether
  "invisible" == "A==0" or something broader.) Inspect the capture/export path in the harness.
- Backfill blast radius: count SWCanvas refs; confirm the rename+manifest update is fully scriptable and that a
  `--check-only` re-verify passes suite-wide after.
- Cross-engine: the same canonicalisation must hold on V8 (Chrome) and JSC (WebKit) — the shim already makes trig
  identical; verify the transparent-pixel residue (if render-side) is also engine-identical, or Option A moots it.
