> **ARCHIVED — COMPLETE (executed 2026-08-05, same day as authoring).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Census as-built extension — the truth re-lay sweep runs BEFORE the resize battery too

**STATUS: ✅ EXECUTED IN FULL — 2026-08-05, same day as authoring, single session. P1 root cause
was sharper than every §4 candidate: `ScrollPanelWdgt.scrollTo` was the ONE unclamped scroll path
in the class, and the sample slide's pin request was calibrated (July 2026, D4 fix `126e9999`)
from a state itself over-scrolled by the 27px edit→view container shift — the fix routes scrollTo
through the clamped `scrollX`/`scrollY` + the standard re-fit pair. P2 landed the two-sweep census
(as-built 1616 / post-resize 1719 targets, the latter byte-equal to the old single sweep) with
separate `asBuiltMovers`/`postResizeMovers` attribution, PROVEN non-vacuous by re-planting the
defect. Gates: full gauntlet 14/14 (264s; census leg still ~9s) + `fg homepage`; ONE gated
recapture (macroSampleSlideEditViewToggle, both dprs, COMPLETE). The §8 execution ledger is the
authoritative record.**

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-05; every citation verified against Fizzygum `d7234fce` / Fizzygum-tests
`54a7f4a7b` (both pushed, all gates green) — and the plan's central unknown was CONVERTED TO DATA
before authoring: the as-built mover set on today's build is EXACTLY ONE widget (§1, probe result
embedded). ⚠ Line numbers drift — quoted method/class names are authoritative; re-grep before
trusting a line.

**MANDATE.** Close the census oracle's as-built blind spot COMPLETELY: the arrange-idempotence
gate must certify the tree twice — exactly as the app flows BUILD it, and again after the resize
battery — with zero movers in both, and the one known as-built defect (the sample slide's
scroll-panel contents sitting one scrollbar-width short) fixed at its PRODUCER, never allowlisted
or baselined (the ratchet case law: factor deeper, don't baseline-bump).

---

## §0 Orientation

**Fizzygum** — CoffeeScript canvas GUI framework, ~505 classes, no modules; build/test via the
`fg` wrapper from the umbrella root (`fg build` / `fg presuite` ~2 min / `fg gauntlet` ~5 min,
launched ONCE in background with a log; peek via `cat /tmp/fg-<cmd>.verdict`; never edit src/tests
while a run is live). Read `Fizzygum/CLAUDE.md` + `Fizzygum-tests/CLAUDE.md` first.

**The oracle this plan extends:** `Fizzygum-tests/scripts/staleness-census.js` (run as `fg census`;
also the gauntlet's ~10s `census` leg). Since the ordered down-walk ungated the settle engine, the
engine re-lays widgets freely with no per-class declaration — sound ONLY while every arrange is
IDEMPOTENT at its fixpoint. The census is that invariant's oracle: it boots `index.html`, preloads
every lazy part (a coverage oracle must exercise everything), opens a battery of app windows + the
bin + eleven window-host flows, RESIZES every window narrow-then-wide via the public `setExtent`,
then sweeps the whole tree post-order — snapshot a widget's subtree geometry, force
`w._reLayout(w.bounds)` (a truth re-lay at its CURRENT frame), diff; any subtree that MOVES was
stale or non-idempotent. PASS = zero movers AND zero errors AND zero battery skips AND zero
storage findings.

**The blind spot (BACKLOG "census blind spot" line, filed at the Frame-model B closeout):** the
resize battery runs BEFORE the sweep, so the oracle only ever certifies the POST-RESIZE state. A
window laid out wrong AS BUILT — converging only when a resize forces a re-arrange — passes. The
frame-model B4 phase briefly EXPOSED this by accident: citizen windows escaped the battery's old
`/FrameWdgt/` name regex, went into the sweep un-resized, and one FAILED; the `isFrame()` fix
re-masked the defect by resizing them again (the script's own battery comment records this).

**CRITICAL REFRAME:** this is NOT "add a mode to a script". It is a GATE-STRENGTHENING arc with a
known red finding: the extension turns a documented, currently-invisible product defect into a
hard gauntlet failure, so the defect fix and the extension MUST land together (fix first, then the
gate that pins it — a gate is never landed red).

## §1 Current state (verified 2026-08-05 at `d7234fce`/`54a7f4a7b` — probe results EMBEDDED)

- **The as-built mover set is EXACTLY ONE widget.** Probe
  `Fizzygum-tests/.scratch/probe-census-asbuilt-movers.js` (kept on disk; a copy of
  staleness-census.js with the two moveTo/resize loops removed, everything else identical) run
  twice with identical output:
  - battery complete (22 flows opened, 0 skips), 1616 sweep targets, 0 storage findings, 0 errors;
  - ONE mover: `ScrollPanelWdgt[153,163,471,400]`, owner chain
    `ScrollPanelWdgt < FrameWdgt < StretchablePanelWdgt < StretchableWidgetContainerWdgt < SlideWdgt`
    (the SAMPLE SLIDE's photo panel, inside an internal window on the slide), whose contents
    `PanelWdgt[-1364,-157,444,958]` re-lays to `[-1364,-157,471,958]` — the contents' right edge
    sits 27px short of the viewport's as-built and the truth re-lay widens it. 27 = the
    scrollbar/handle-region deduction the build path applied and never revisited (the exact
    constant is for Phase 1 to pin — `WorldWdgt.preferencesAndSettings.scrollBarsThickness` and
    the panel paddings are the candidates).
- **Where the fixture comes from:** the census battery's `SampleSlideApp` entry (`APPS` list in
  the script). The slide (`SlideWdgt`, a §5.B framed citizen) hosts a
  `StretchableWidgetContainerWdgt` → `StretchablePanelWdgt` → an INTERNAL `FrameWdgt` whose
  content is the mover `ScrollPanelWdgt`. Grep `SampleSlide` / the slide factory for where that
  scroll panel is constructed and sized.
- **The sweep/battery/verdict structure** of `staleness-census.js` (~234 lines): boot + lazy-part
  preload + settle slack → `APPS` battery (opens via `new K().buildWindow()`) → moveTo + two
  setExtent per window → bin open → `EXTRAS` window-host flows → moveTo + two setExtent per extra
  → the post-order sweep (`geo`/`snap`/`targets` + the mover diff) → the storage-invariant sweep →
  JSON report → verdict (any of movers/skips/errors/storageFindings/zero-targets ⇒ exit 1).
- **Known relevant case law** (both already encoded in comments/fixes elsewhere):
  - The base scroll-panel re-fit is MEASURE-THEN-COMMIT — it reads the items' APPLIED bounds,
    commits the contents frame, only then re-places — so a re-fit converges one pass late; the
    §5.C C2 fix made `ToolbarWdgt._positionAndResizeChildren` re-place at the applied viewport
    FIRST (one-pass fixed point). The as-built defect here is likely the same family: the build
    path fits the contents while the scrollbar state (or the viewport width) differs from the
    final one, and nothing re-fits after.
  - `adjustContentsBounds`/`adjustScrollBars` ordering traps are documented in
    `Fizzygum-tests`' MACRO-PATTERNS scroll entries and the ScrollPanelWdgt comments.
- The census gate is wired: `fg census` runs the script standalone; the gauntlet's `census` leg
  runs it in wave B. No `fg` change is needed for this plan (`fg` is uncommitted umbrella tooling).

## §2 Why it is shaped this way

The census was born to catch REGRESSIONS in arrange idempotence while arcs were actively
rewriting arranges — the resize battery was the cheapest way to force every wrap/re-arrange path
before sweeping, and post-resize certification was the property those arcs needed. Nobody chose
"ignore as-built"; the battery simply preceded the sweep, and the blind spot went unnoticed until
B4's regex accident exposed it. The as-built state IS product truth — it is what a user sees when
they open an app and touch nothing — so certifying only the post-resize tree certifies the wrong
thing first.

## §3 The distilled argument

The oracle already does everything needed — the sweep is a pure function of the tree, and running
it twice costs a few seconds on the cheapest gauntlet leg. The only reason it was never run
pre-resize is that it would have failed, and now we know it fails on EXACTLY ONE widget with a
well-understood defect family (fit-before-scrollbar-state-final, the measure-then-commit lineage)
and a proven fix idiom (re-place at the applied frame first / re-fit after the state that changes
the fit). Fix the one producer, then land the two-sweep gate green in the same arc: the blind spot
closes structurally and every future as-built defect fails the gauntlet the day it is written.

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — expect Fizzygum at/past `d7234fce`,
   tests at/past `54a7f4a7b`, both clean, 278 SystemTests. If src moved, re-run the probe (step 3)
   before trusting §1's mover set.
2. Read this plan in full, then `Fizzygum-tests/scripts/staleness-census.js` in full (~234 lines —
   the whole oracle fits in one read), then `Fizzygum/CLAUDE.md`'s "Long ops & shell discipline".
3. Re-run the probe to confirm the baseline:
   `cd Fizzygum-tests && node .scratch/probe-census-asbuilt-movers.js` (needs a FRESH build:
   `/Users/davidedellacasa/code/Fizzygum-all/fg build` first if `fg status` says STALE; the probe
   refuses stale builds). Expect: battery complete, 1616±drift targets, the ONE ScrollPanelWdgt
   mover. If the mover set differs from §1, STOP and re-scope Phase 1 to the actual list before
   any code.
4. Execute phases in order (P1 → P2 → P3). Per batch: `fg presuite` (background + log + verdict);
   phase close: `fg gauntlet`. No recaptures are expected ANYWHERE in this arc (no test pixels
   change; the census is a Node gate) — treat any suite churn as a regression to investigate, not
   to recapture. ⚠ Never edit src/tests while a run is live. Two falsified fix shapes on one
   problem = stop and re-frame.
5. Commits: present messages at the end (`git commit -F <file>`), never commit/push without the
   owner's word.

## §4 Phases

### P1 — root-cause and fix the ONE as-built mover (the sample slide's scroll panel)
1. Reproduce in isolation: boot the harness page headless (crib any `.scratch/probe-*.js` boot
   boilerplate), build JUST the sample-slide flow (`new SampleSlideApp().buildWindow()` — confirm
   the class name from the census `APPS` list), settle, and dump the mover chain's geometry
   (viewport vs contents right edges). Confirm the 27px shortfall reproduces standalone.
2. Root-cause by reading the BUILD path: where is the NYC/photo `ScrollPanelWdgt` constructed and
   who sizes its contents? Candidate mechanisms, in likelihood order: (a) the contents were fitted
   while a vertical scrollbar was (or was assumed) present, and the final state has none on that
   axis (or vice versa) with no re-fit after the scrollbar state settled; (b) the internal
   FrameWdgt's content-width negotiation handed the panel one width and the panel fitted its
   contents to an earlier/other width (measure-then-commit, one pass late); (c) an explicit
   build-time `setExtent`/fit call ran before the window's first placement finalized the viewport.
   Diagnose with an instrumented probe (log the panel's viewport + contents widths at each
   arrange), not by source-reading alone.
3. Fix AT THE PRODUCER (the build/arrange path that commits the stale fit) — the §5.C C2
   one-pass-fixed-point idiom is the proven shape. ⛔ Do NOT fix by resizing the window in the
   battery, by re-laying in the census, or by any allowlist/baseline — the census doctrine is
   that movers are bugs in that widget's arrange.
4. Verify: the probe reports ZERO movers; the standalone reproduction shows contents flush; the
   full suite is byte-green (`fg presuite` — the sample slide IS screenshotted by suite tests, so
   an as-built geometry change CAN legitimately alter pixels: if any macroSampleSlide*/slide test
   churns, diffpage + eyeball — the ONLY acceptable delta is the panel's contents/scrollbar
   region becoming correct; anything else is a wrong fix. If churn is confirmed-benign-and-correct
   it is recapture-eligible (gated, `fg recapture <names…>`), and the plan pre-authorizes ONLY
   that shape).
5. While in there, check the SIBLING sites cheaply (grep for other constructions of scroll panels
   inside internal windows on slides/docs — the sample DOC app is the nearest cousin): the probe
   already proves they don't MOVE today, so this is a read-only pattern check for the ledger, not
   a speculative sweep.

### P2 — the two-sweep census (the actual extension)
1. Refactor `staleness-census.js` minimally: extract the sweep body (`geo`/`snap`/target
   collection/mover diff) into a function usable twice; run it ONCE right after the battery opens
   (before ANY moveTo/setExtent — the probe's exact semantics: as-built means untouched), and
   ONCE after the existing resize loops, keeping the storage sweep at the end. Report
   `asBuiltMovers` and `postResizeMovers` SEPARATELY (a failure must say which certification
   broke); the verdict fails on either being non-empty, same as today's single list.
2. Keep the battery/lazy-preload/verdict semantics byte-identical otherwise — the gate's other
   four failure axes (skips/errors/storage/zero-targets) are untouched. Update the header comment
   to describe the two certifications and WHY (the B4 accident + this plan).
3. Verify: `node scripts/staleness-census.js` green standalone (both sweeps zero); then
   `fg gauntlet` — the census leg picks the script up with no fg change. Also deliberately verify
   the gate is NON-VACUOUS: temporarily revert the P1 fix in the working tree (or plant an
   equivalent one-line stale-fit), confirm the census FAILS with the mover attributed to
   `asBuiltMovers`, then restore. (The fault-injector lesson: a gate must be proven able to fail.)
4. Retire the probe? NO — keep `.scratch/probe-census-asbuilt-movers.js` (gitignored) as the
   quick isolation tool; the census itself is the gate.

### P3 — docs + close
- BACKLOG: close the "census blind spot" line (point here + the fix commit).
- `staleness-census.js` header is the living doc for the oracle — P2 step 2 covers it; no
  architecture-doc change is needed (the census is test tooling).
- This plan → `docs/archive/` + stamp + INDEX line; memory note updated
  (`layout-spec-family-followups-arc` carries the residuals thread — add the closure there or a
  small standalone note if the P1 root cause is case-law-worthy); ONE end-of-arc review; commit
  messages presented (never commit/push without the owner's word).

## §5 Rejected / do-not-re-attempt

- **Allowlisting/baselining the mover** (ratchet case law: factor deeper, don't baseline-bump;
  census findings are questions, never a backlog).
- **Resizing windows before the as-built sweep** — that IS the blind spot.
- **"Fixing" by adding a settle/re-lay inside the census** — the oracle must observe, never heal;
  a heal would certify a tree no user ever sees.
- **A separate second script** instead of the two-sweep refactor — two boots double the leg's
  cost and let the two certifications drift; the sweep is already a pure function.
- **Sweeping mid-battery (after each open)** — tempting for attribution, but it multiplies sweep
  cost by battery size and the post-order full-tree sweep already attributes movers precisely.

## §6 Verification protocol

Per batch: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` (background, wait for the
notification). Phase close: `fg gauntlet` (background, caffeinate if the machine may sleep:
`caffeinate -i fg gauntlet`). The census alone: `cd Fizzygum-tests && node scripts/staleness-census.js`
(needs a fresh build). Expected suite churn: ZERO except the P1-step-4 case (sample-slide tests
whose pixels become CORRECT — diffpage + eyeball before any recapture, and only that shape is
pre-authorized). `fg homepage` is NOT required (no menu/parts/production-reachability change) but
is cheap if the P1 fix touches core scroll-panel code — run it at the arc close if it did.

## §7 References

`Fizzygum-tests/scripts/staleness-census.js` (the oracle + its history header) ·
`Fizzygum-tests/.scratch/probe-census-asbuilt-movers.js` (the baseline probe, §1) ·
`Fizzygum/docs/BACKLOG.md` "census blind spot" line (under the onion-plan section) ·
`docs/plans/onion-widget-composition-plan.md` §5.C C2 census case law (the one-pass-fixed-point
idiom + the chrome-drive lesson) · `Fizzygum/docs/architecture/layout.md` §8 (the rulebook: obey
the tiers, arranges idempotent) · memory: `layout-spec-family-followups-arc` (the residuals
thread), `stop-iterating-fix-shapes-after-two-falsifications`, `ask-before-commit-push`.

## §8 Execution ledger (append per phase; empty at authoring)

### P1 — DONE 2026-08-05
- Baseline probe re-run pre-code: identical to §1 (22 flows, 0 skips, 1616 targets, the ONE
  ScrollPanelWdgt mover, contents 444→471). Scope held.
- ROOT CAUSE (instrumented standalone probe `.scratch/probe-sample-slide-scroll.js`, mechanism
  (c)-adjacent but sharper than any §4 candidate): `ScrollPanelWdgt.scrollTo` was the ONE
  unclamped scroll path in the class — a raw `_moveLeftSideTo/_moveTopSideTo` with no clamp and
  no re-fit, where every other path (wheel/drag/glide/auto-scroll/bars) clamps at the content
  edge and re-fits. SampleSlideApp's pin-at-(89,23) request asks for a 1517px horizontal scroll
  when only 1490 exists (map 1808 − viewport 318): the (89,23) was calibrated in July 2026 from
  a state that was ITSELF over-scrolled by the 27px edit→view container shift (D4 fix 126e9999
  measured it off the broken pre-orphan-settledness anchor). The committed over-scroll leaves
  the contents frame 27px short of covering the viewport — violating the arrange's own
  contents ⊇ viewport fit rule — so the truth re-lay widens it: the census mover. VISIBLE
  product defect: the NYC map ended 27px short of its window edge (pale strip, scrollbar
  floating over the gap).
- FIX at the producer (§5.C C2 one-pass-fixed-point family): `scrollTo` now expresses the
  request as deltas through the CLAMPED `scrollX`/`scrollY` primitives + the standard
  post-scroll `_positionAndResizeChildren()`/`_reLayoutScrollbars()` pair. The builder's request
  clamps to 1490 → map flush right, pin lands at (116,23); SampleSlideApp comment trued up.
- Verified: standalone probe overScrollX 0, truth-relay moved []; full census probe 0 movers /
  1616 targets; presuite paint:PASS, suite churn EXACTLY ONE test (macroSampleSlideEditViewToggle);
  diffpage eyeballed at both dprs — the only delta is the scrolled contents shifting 27px so the
  map/traffic-window fill the viewport (the pre-authorized shape); gated recapture COMPLETE
  (suite green at dpr1+dpr2, 12 refs).
- Sibling check (read-only): the only other `FrameWdgt(new ScrollPanelWdgt)` construction is
  `WindowWithScrollPanelCreatorButtonWdgt` (empty panel, no scripted scroll — no over-scroll
  possible); no other code raw-moves scroll contents. `scrollTo` was the single unclamped
  producer, now clamped for every future caller.

### P2 — DONE 2026-08-05
- `staleness-census.js` refactored per §4 P2: sweep body extracted into `sweepInto(movers)`
  (returns target count), ALL battery opens (apps + bin + extras) grouped first, certification 1
  (as-built) runs before ANY moveTo/setExtent, then the two resize loops, then certification 2
  (post-resize), storage sweep unchanged at the end. Report carries `asBuiltMovers` /
  `postResizeMovers` + `nTargetsAsBuilt` / `nTargetsPostResize`; verdict fails on either list
  non-empty or either sweep empty of targets; header rewritten (two certifications + the B4
  accident + this plan). fg needed no change (gates on exit code + the CENSUS OK/FAILED lines).
- Semantics preserved MEASURED, not assumed: post-resize sweep = 1719 targets, byte-equal to the
  old single-sweep census's 1719 (last committed gauntlet census log); as-built sweep = 1616,
  equal to the §1 probe. 22 flows, 0 skips, 0 storage findings.
- NON-VACUITY PROVEN: P1 fix reverted in the working tree (file back to HEAD), rebuild → census
  FAILED exit 1 with `asBuiltMovers=1` (the exact ScrollPanelWdgt[153,163,471,400] signature),
  `postResizeMovers=0` — attributed to the as-built certification, the axis the old oracle could
  not see. Fix restored, rebuild → green again (0/0 movers, 1616/1719 targets).
- Phase close: full `fg gauntlet` (caffeinated) — **14/14 GREEN, total 264s** (dpr1 113s /
  dpr2 118s / webkit 129s / apps 91s / parts 45s / paint 99s / tiernaming 118s / settle 118s /
  capstone 119s / refs 33s / revisits 118s / census 9s / serialization 56s / storage 118s):
  the two-sweep census leg costs the same ~9s as the old single sweep.

### P3 — DONE 2026-08-05
- `fg homepage` run at arc close (the P1 fix touches core scroll-panel code, §6) — EXIT=0 OK
  (production boot + whole-world snapshot round-trip clean, dev build restored).
- BACKLOG "census blind spot" line closed (points here + the fix); plan archived
  (`docs/archive/census-as-built-extension-plan.md`) + INDEX line; memory note
  `census-as-built-extension-arc` written; end-of-arc review run; commits presented for the
  owner's word.
