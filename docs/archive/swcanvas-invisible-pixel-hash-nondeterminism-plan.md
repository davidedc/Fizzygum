> **ARCHIVED — PARKED (2026-07-17 restructure).** PARKED/NOT-ACTIONABLE as of 2026-07-08 — A=0-residue hypothesis CONTRADICTED, no reproducing bug
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# SWCanvas invisible-pixel hash nondeterminism — problem + handling (DRAFT)

**Status:** ⛔ PARKED / NOT-ACTIONABLE (as of 2026-07-08 confirmation). DRAFT written 2026-07-06 after the
drag-embed Phase 3 arc. **Facts re-verified + confirmations RUN 2026-07-08:**
- **§2 mechanism confirmation → the A=0-residue hypothesis is CONTRADICTED** (the hashed whole-desktop buffer is
  always fully opaque; Option A would be a no-op). The §1 flake does not reproduce by the single-run raw-vs-PNG
  form NOR by the faithful §2.5(a) capture→verify path (a reconstructed post-drop test captured + re-verified,
  dpr1+dpr2 both PASSED). See the **§2 CONFIRMATION RESULTS** box. Recommendation (§4) superseded → park until a
  fresh repro exists.
- **§2.7 H1 secure-context probe → ✅ GREEN** (`crypto.subtle` available + correct over `file://` on Chrome AND
  WebKit). H1 (perf) is INDEPENDENT of this plan and unaffected by the parking.
Line refs refreshed in §1; §2.7 added on the H1 interaction + the cross-engine hash-identity invariant.

## §1 — The problem, precisely

The SystemTest suite matches SWCanvas renders by a **raw-pixel SHA-256** (`dataHash`), NOT by comparing the PNG
files. Two code paths compute it and MUST agree (`Fizzygum-tests/CLAUDE.md` records this sync constraint):

- **Live (in-browser, at run/capture time):** `AutomatorPlayer.compareScreenshots` (`AutomatorPlayer.coffee:248`
  as of 2026-07-08 — the old ":180" is stale; the audit code below shifted it) —
  `liveHash = SHA256.hashRawPixels renderCanvas.width, renderCanvas.height, renderCanvas.data`. The input is the
  SWCanvas framebuffer `renderCanvas.data` — the raw, non-premultiplied RGBA byte array, **including every
  pixel's R,G,B even where A (alpha) is 0**. (`renderCanvas` = `world.fullRenderCanvasAsItAppearsOnScreen()`,
  `Widget.coffee:2286` — a **fresh** disposable canvas per call, drawn from the pristine SWCanvas software surface;
  relevant below because a canonicalisation pass can mutate it in place.) The **same** `hashRawPixels` runs at TWO
  more sites: `AutomatorPlayer.coffee:62` (`liveCanvasFingerprintNow`, the paint-truthfulness audit/capstone) and
  the `SystemTestsReferenceImage` **constructor** (`SystemTestsReferenceImage.coffee:28`, capture + failure-dump
  paths only — not per-frame). All three must stay in sync with the offline hasher; H1 (below) may split them.
- **Offline (Node, recompress/verify):** `scripts/recompress-swcanvas-references.js` `rawPixelHash()`
  (`:86-94`) — Node `crypto.createHash('sha256')` over `[width u32 BE][height u32 BE][raw RGBA8 bytes]`, where the
  RGBA comes from decoding the stored `.png`.

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

### ⚠ §2 CONFIRMATION RESULTS — 2026-07-08: the A=0 hypothesis is CONTRADICTED by direct measurement

Ran the confirmation (headless Chrome, SWCanvas, dpr2, against the build from that morning). Instead of the
two-process capture-vs-run byte diff, used the equivalent single-run form — on a chosen frame, compare the raw
buffer hash against (a) a copy canonicalised `A==0 → RGB=0` (Option A's predicate) and (b) the frame's OWN PNG
round-trip decoded by the actual offline decoder (`recompress-swcanvas-references.js`). Scenes measured:

1. fresh booted world; 2. the "cheapest repro" (one panel + window, brief charge, drop AT ONCE); 3. the **exact
committed `macroDragEmbedCandidateChangeResets` scene** (two panels, arm over A, move onto B, release AT ONCE),
**fast-sampled 15×** at 30 ms through the release + the settled post-drop frame; 4. a widget deliberately
positioned to **overflow** the desktop's right edge.

**Every frame — 20+ samples across all four scenes — was 100 % opaque:** `A==255` on every pixel, ZERO `A==0`,
ZERO partial-alpha, ZERO residue. And in every case `rawHash == canonHash == pngHash` (the PNG round-trip is
byte-lossless for these buffers). The overflow scene still produced the plain `960×440`-logical desktop rectangle
(`fullRenderCanvasAsItAppearsOnScreen()` on `world` yields the opaque desktop; the child did not add A=0 margin).

**What this means:**
- The buffer the suite actually hashes — `world.fullRenderCanvasAsItAppearsOnScreen().data`, whole-desktop only
  (`AutomatorPlayer.coffee:240` comment) — is a **fully-opaque rectangle**. There are **no A=0 pixels** in it to
  carry invisible residue, so **Option A's `if A==0 → RGB=0` predicate never fires: Option A is a NO-OP** and
  cannot fix anything as specified. Option B (canonicalise the render/clear path) likewise has no A=0 target here.
- **No raw-vs-PNG divergence reproduced** in a single run, and the original §1 capture-vs-run divergence did **not**
  reproduce. Given full opacity it also **could not** have been A=0 residue: any RGB difference would be in a
  *visible* (A=255) pixel and the PNGs would then differ — but §1 recorded them as pixel-identical. So the §1
  diagnosis (this doc's own leading hypothesis) is **either wrong or no longer triggerable in the current tree**
  (several arcs landed 2026-07-06 → 07-08, incl. the paint-truthfulness capstone/audit and layout/paint-gate work,
  any of which could have removed the transient).

**Consequence for this plan:** do **NOT** implement Option A or B now — there is no reproducing bug and the
diagnosed mechanism is contradicted. **H1 (perf) is independent and unaffected** — it changes only the hash
*function* (§2.7), not the input, and stands on its own.

**Extra-mile follow-up (2026-07-08) — the faithful §2.5(a) capture→verify path also does NOT reproduce it.**
Not content with the single-run form, reconstructed the *original* abandoned shape as a throwaway test
(`SystemTest_zzPostDropResidueProbe`: the committed 2-panel scene + a trailing **post-drop** screenshot — exactly
the frame the committed test dropped), full-built to register it, and ran the real
`capture-macro-test-references.js --dprs=1,2` (the same `--capture-ref` capture then fresh verify legs that
ORIGINALLY surfaced the flake). Result: **capture baked dpr2 `dataHash 0d167205fc1a4886…`; the fresh verify leg
re-matched it — dpr2 AND dpr1 both `TEST PASSED`, `failedTests: []`.** So the capture-env and run-env buffers
produce the IDENTICAL hash — the §1 capture-vs-run divergence is GONE in the current tree. (Cross-check: that dpr2
`dataHash` is byte-identical to what the single-run in-page probe computed across 3 separate processes — the probe
measured the right frame.) The throwaway test was deleted and both repos left clean afterwards.

**Net:** the flake does not reproduce by EITHER method (single-run raw-vs-PNG, or the faithful capture→verify), and
the hashed buffer is structurally always-opaque. The plan is **parked as not-actionable**. If it ever recurs,
re-run the §2.5(a) capture→verify to catch it live, then byte-diff the two real divergent buffers and classify the
differing bytes by alpha BEFORE choosing any fix; if the differing bytes are *visible* (A>0), it is a
`DETERMINISM.md` render-nondeterminism, not this bug.

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

## §2.7 — Cross-engine hash identity + interaction with the H1 perf change (crypto.subtle)

This plan and **H1** in `runtime-performance-optimization-plan.md` (SHA-256 → `crypto.subtle.digest`) touch the
SAME hashing path, so decide them together. Verified 2026-07-08 against the live source.

**They act on ORTHOGONAL axes:**
- **H1 changes the hash FUNCTION** (hand-rolled JS SHA-256 loop → native `crypto.subtle.digest('SHA-256', …)`).
  Same algorithm ⇒ **byte-identical digest for identical input ⇒ zero reference churn.**
- **This plan (Option A) changes the hash INPUT** (canonicalise invisible pixels before hashing). Different input
  ⇒ every stored `dataHash` changes ⇒ **mass backfill** (re-hash + rename).

They **compose cleanly**: canonicalise the input bytes, *then* digest. Order of operations is independent of which
engine computes the digest.

**The cross-browser / cross-platform identity requirement is FREE for the hash function — because SHA-256 is a
bit-exact spec (FIPS 180-4), not an implementation detail.** Given identical input bytes, the hand-rolled JS
SHA-256, `crypto.subtle`'s SHA-256, and Node's `crypto.createHash('sha256')` ALL emit the identical 64-hex digest,
on V8 (Chrome), JSC (WebKit), and Node alike — no floating point, no platform variance. The suite ALREADY leans on
this (Chrome-captured live hash == WebKit-verify live hash == Node recompress hash today). The `"abc"` NIST vector
self-test in `SHA256.coffee:22` is the conformance proof. Consequences:
- **H1's engine swap cannot break cross-engine identity.** ✓
- **Option A's canonicalisation must ALSO be cross-engine identical** — trivially satisfied *iff* it is a plain
  integer byte op (`if A==0 → R=G=B=0`), no float. Keep it that way. ✓
- **The real cross-platform risk is the INPUT bytes, not the hash** — i.e. the framebuffer residue, which is
  exactly this bug. Option A moots it (canonicalises it away); Option B tries to make the raw buffer deterministic
  on both engines (and must be *proven* engine-identical — see §5).

**Load-bearing question for H1's *preferred* path — ✅ RESOLVED empirically 2026-07-08.** `SHA256.coffee:11-12`
asserts *"SubtleCrypto is async and unavailable over `file://`"*, which **contradicted** H1's claim that "`file://`
pages in Chrome ARE a secure context, so `crypto.subtle` is available." Probed both engines via the real
`headless-driver.js` launch config (Chrome `--allow-file-access-from-files`; WebKit `bypassCSP`), over a `file://`
page, and actually PERFORMED a digest:

| engine | `location.protocol` | `isSecureContext` | `typeof crypto.subtle.digest` | `digest('SHA-256','abc')` | pageErrors |
|---|---|---|---|---|---|
| Chrome (Puppeteer) | `file:` | `true` | `function` | `ba7816bf…20015ad` ✓ vector | none |
| WebKit (Playwright) | `file:` | `true` | `function` | `ba7816bf…20015ad` ✓ vector | none |

So `crypto.subtle.digest('SHA-256', …)` **is available and correct over `file://` on BOTH engines**, and returns
the SAME digest — matching the JS impl's own `"abc"` self-test vector. The `SHA256.coffee:11-12` comment is
**outdated** (correct it during execution). H1's crypto.subtle path is viable on both legs — no `http://` fallback
needed. (`window.isSecureContext` for `file:` is scheme-based, so the minimal probe page is representative of the
real harness's `file://` origin.) A sync JS fallback is therefore optional, not forced — but see the async-ripple
note below for why the cold `SystemTestsReferenceImage` constructor path keeps it anyway.

**Copy-count caveat (why H1 alone can't reach zero copies):** WebCrypto `crypto.subtle.digest` is **one-shot** —
it takes a single contiguous `BufferSource`; there is NO streaming `.update()` (unlike Node's `createHash`). So the
crypto.subtle path MUST still concatenate `[8-byte header][RGBA]` into one buffer = **one** copy. Today's code does
**two** (`SHA256.coffee:53` builds `[8+len]`, then `:84` builds the padded SHA block); crypto.subtle removes the
*second* (native internal padding) but not the *first*. H1's "drop BOTH copies" applies only to its *synchronous
fallback* (a hand-rolled, streamable loop). — This matters for Option A: since `renderCanvas` is a fresh disposable
canvas (§1), Option A's canonicalisation can run **in place** on `renderCanvas.data` (a write pass, no new alloc),
then the one header-concat copy, then the digest. So Option A + H1 = one in-place write pass + one copy + native
digest — still strictly cheaper than today's two copies + slow JS loop; Option A does NOT double memory traffic.

**Async ripple (H1) is wider than "compareScreenshots + callers":** the `SystemTestsReferenceImage` constructor
(`:28`) also hashes, and a constructor cannot `await`. That path is capture/failure-only (cold), so the clean split
is: crypto.subtle (async) on the hot compare/fingerprint path; **keep** the synchronous JS `SHA256` for the
constructor/capture path (identical digest by spec). **Implication for Option A:** if H1 keeps a sync fallback, the
canonicalisation predicate must be applied in **three** lockstep sites — the crypto.subtle hot path, the retained
JS sync path, AND Node's `rawPixelHash` — not two. Weigh that against Option A's "one subtle rule, forever" con.

**Sequencing / synergy:** if Option A is chosen, **fold H1 into its backfill.** Option A already forces a one-time
re-hash + rename of every SWCanvas reference; that is the natural moment to also adopt crypto.subtle (Node backfill
uses `crypto`, browser live uses `crypto.subtle` — same digest), so the reference set is disrupted ONCE, with one
cross-engine re-verify, instead of twice. Conversely, if H1 ships FIRST and alone, its selling point is precisely
**zero churn** (references untouched) — a later Option A is then a separate, second backfill. (Breadcrumb added to
the H1 section noting that Option A voids H1's zero-churn premise.)

## §3 — Options for handling

### Option A — Make the hash perceptual (canonicalise invisible pixels before hashing) + BACKFILL
Change BOTH hashers to zero (or otherwise canonicalise) the R,G,B of pixels that can't affect the visible image —
minimally `if A == 0: R=G=B=0` — before feeding bytes to SHA-256. The hash then reflects only what is seen.
- **Backfill required:** every stored reference's `dataHash` changes, so all references must be re-hashed and
  renamed (the hash is in the filename). Mechanical and scriptable (decode PNG → canonicalise → re-hash → rename;
  the recompress script already has a from-scratch PNG decoder to build on). ~all SWCanvas refs across the suite.
- **Sync constraint:** `SHA256.coffee` (`hashRawPixels`) and `recompress-swcanvas-references.js` (`rawPixelHash`)
  must apply the IDENTICAL canonicalisation, forever (they already must produce identical digests). **If H1 lands
  a crypto.subtle hot path + a retained sync fallback, that becomes THREE lockstep sites (see §2.7).**
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

## §4 — Recommendation lean

**SUPERSEDED by the §2 confirmation (2026-07-08).** The original lean was **Option A** (perceptual hash +
backfill). The §2 measurement shows the hashed buffer is always fully opaque, so **Option A is a no-op and is no
longer recommended**; Option B has no A=0 target either. **Current recommendation: park the plan** (no reproducing
bug; diagnosed mechanism contradicted) and, if the flake recurs, first capture the two real divergent raw buffers
(§2.5(a)) and characterise the differing bytes' alpha before choosing ANY fix. Do not backfill references or widen
the hashing contract on the strength of the (now-contradicted) A=0 hypothesis.

--- *original lean, retained for history:* ---
Lean **Option A** (perceptual hash + backfill): it kills the entire class rather than one instance, and the
backfill — while broad — is mechanical and one-time. Option B is cleaner in spirit (the raw buffer *should* be
deterministic) but is open-ended (no guarantee all erase paths are found, and new ones will regress silently).
A pragmatic combo is possible: do A for the guarantee, AND fix the specific egregious erase path from §2 so the
raw buffer is also cleaner. Decide after the §2 confirmation.

## §5 — Open questions
- ~~Confirm the residue is exactly A=0 pixels~~ — ✅ RESOLVED 2026-07-08 (§2 CONFIRMATION RESULTS): there is NO
  A=0 residue; the hashed whole-desktop buffer is fully opaque, so the A=0 hypothesis is CONTRADICTED. Plan parked.
- Does the PNG export flatten over an opaque background, or store RGBA and just happen to match? (Affects whether
  "invisible" == "A==0" or something broader.) Inspect the capture/export path in the harness.
- Backfill blast radius: count SWCanvas refs; confirm the rename+manifest update is fully scriptable and that a
  `--check-only` re-verify passes suite-wide after.
- Cross-engine: the same canonicalisation must hold on V8 (Chrome) and JSC (WebKit) — the shim already makes trig
  identical; verify the transparent-pixel residue (if render-side) is also engine-identical, or Option A moots it.
- H1 conjunction (§2.7): ✅ `crypto.subtle.digest` availability over `file://` CONFIRMED on both engines
  (2026-07-08) — H1's preferred path is viable; correct the stale `SHA256.coffee:11-12` comment during execution.
  Still to decide: sequencing — fold H1 into Option A's backfill, or ship H1 first (zero-churn) and Option A as a
  separate later backfill.
