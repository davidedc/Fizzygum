# Arc 3 · Phase 7 — the ONE menu topology (owner-ratified 2026-07-29)

**STATUS: PHASE 7 COMPLETE, ALL GATES GREEN (2026-07-30) — awaiting owner commit approval.**
Final pass, over both owner follow-ups (scrollbar spacing; keep BOTH duplication verbs):
`fg build` OK · `fg recapture --auto` ✅ COMPLETE both rounds (18 tests recaptured at dpr 1 AND 2) ·
`fg gauntlet` EXIT=0, all 13 legs, zero load-flake retries, capstone clean across 269 tests ·
`fg homepage` EXIT=0. (The two `call-separation` NOTEs in the build log — `unTouch`,
`QUERY: 132 < baseline 143` — are PRE-EXISTING: byte-identical in the phase-5 build log, so they are
the call-separation arc's ledger, not this one's.)
(The two `call-separation` NOTEs in the build log — `unTouch`, `QUERY: 132 < baseline 143` — are
PRE-EXISTING: byte-identical in the phase-5 build log, so they are the call-separation arc's ledger,
not this one's.) The three design calls below were
made by the owner with the code in view. This file is the authority for what to build. Owning arc:
`build-arc-3-world-harmonization-plan.md` (H-D6 / H-R4 — "menu unification is owner-led, comes LAST").

## §0 STATE ON DISK — read this first (session handoff 2026-07-29)

**Committed:** phases 1–4 only — `Fizzygum faea99a6`, `Fizzygum-tests 8da2d08ba`. Not pushed.
**Uncommitted in the working tree:** phases 5, 6 and the src half of 7.

Region markers: **63 → 0.** All three build.py region regexes are DELETED and
`check-region-markers.js` holds every kind at baseline 0 (a hard rule, no longer a ratchet).

Landed and gated green: phase 5 (`fg gauntlet` EXIT=0, all 13 legs). Phase 6's build and
`fg homepage` are green; its gauntlet run was INVALID because src was edited mid-run (the
STALE BUILD guard aborted wave B) — **it needs re-running, it was never a real failure.**

### Phase 7 src changes — DONE
- `Widget.buildBaseWidgetClassContextMenu`: the `isIndexPage` fork is gone, replaced by the D1
  union; dev tail (`hide`, `dev ➜`, `test menu ➜`, `destroy`) gated on `world.isDevMode` /
  `DemoMenus?`. All eight menu actions verified to exist unconditionally on `Widget`.
- `duplicate` → `duplicateMenuAction` everywhere (D2).
- `WorldWdgt.popUpDemoMenu`: two forks merged into one catalogue; the window-wrapped palettes kept
  as explicitly-labelled items rather than silently dropped.
- `BoxyAppearance` "pick inset…" row deleted — that was the last region site.

### Phase 7 test rewrites — DONE (2026-07-30)
`fg suite` reported **20 stale tests**: 13 pure menu churn (item set + order changed — recapture
only) and **7**, not the 4 first recorded here, needing AUTHORING because D2 changed what
"duplicate" DOES. ⚠⚠ The three extras named the changed method NOWHERE — they broke on
*consequences*, so scope this kind of work from the suite's failing list, never from a grep.

| test | what D2 broke | resolution |
|---|---|---|
| `…SimpleWidgetPaintsCleanly` | — | renamed from `…RidesHand` + rewritten earlier |
| `…ComplexWidgetRidesHand` → **`…PaintsCleanly`** | copy no longer rides the hand | renamed; helper generalised to `windowedWidgetMenuAction_InputEvents_Macro(win, item)`; window moved to (15,16) so the pair stands side by side; refs recaptured |
| `…DuplicatePreservesTransform` | ditto | rewritten; **reference byte-identical** |
| `…EmbeddedDuplicateButtonReduplicates` | 3 generations each relied on hand-carry | new test-local verb `duplicateViaEmbeddedButtonAndCarryTo_InputEvents_Macro(panel, dest)`; **all 4 refs byte-identical** |
| `…DuplicatedCollapsedWindowKeepsStateAndContent` | locator `m.left() > 400` → nil → crash | copy identified by object identity; carried via `pick up` |
| `…DuplicatedInspectorDrivesCopiedTargetOnly` | carry-drop now a no-op | 2 lines removed (it already `moveTo`s the copy); only image_1 changed — a copy that is never *dropped* has no cyan just-dropped outline |
| `…DuplicatedMenuAutoPinsOnDesktop` | carried a copy that no longer moves | the copy stands where born (the original menu is already dismissed), foil re-opened on the right |
| `…MenuItemDuplicatesToStandaloneWidget` | ditto | copy is standalone at birth; rectangle drop moved to (720,150) for clearance |

`…DuplicatedInspectorsCloseIndependently` and `…SpreadsheetDuplicate` were NOT in the failing list —
the former places both windows by API after the copy exists, so it washed the change out; only its
stale prose needed fixing.

**The idiom now taught by `src/macros/MACRO-PATTERNS.md`:** duplicate → find the copy by the
deterministic +10,+10 offset or by diffing the population across the click (**never** by child
order) → assert that offset → carry it via its own "pick up" item → shoot it separated.

**Owner legibility requirement — met.** Every test ends on a clearly-separated shot. The deliberate
exception is the two `PaintsCleanly` tests' `image_1`: it is the zero-movement birth-frame check, so
separating it would delete the assertion. Because the copy is added last it draws ON TOP, so that
shot IS the copy — a blank or half-painted birth frame is still caught. The product's +10,+10 offset
was left alone, as the owner directed.

**BOTH duplication verbs are kept in the public API; only the plain one is in the menu**
(owner, 2026-07-30). `duplicateMenuActionAndPickItUp` was briefly deleted as dead accretion when D2
left it with no user-reachable path — the owner then decided the framework should keep both verbs,
so it is reinstated under an honest name, **`duplicateAndPickItUp`** (it is no longer any menu's
action, and a name claiming otherwise would be a lie). NEW test
`macroDuplicateAndPickItUpRidesHand` covers it, so it is not untested API: the copy lands on the
HAND (a hand child centred on the pointer) rather than in the world, and on a tilted widget it is
the ISLAND that rides — which is also the only coverage anywhere of the pinned-anchor normalisation
the verb performs before handing the figure to `pickUp`. The direct call is the sanctioned
escape-hatch form (rule 2 exempts behaviour whose UI trigger is genuinely absent); everything after
it — carry, drop — is still driven as real input.
Also updated: `Fizzygum-tests/scripts/classify-diff.js`'s `INSPECTOR_CHURN_SET` (live code, held the
old test name) and four `MACRO-PATTERNS.md` entries.

### ⚠⚠ A RECAPTURE CAN BAKE IN DAMAGE — `macroInspectorScrollbarUnplugged` (owner-caught, 2026-07-30)

I classified this test as "pure menu churn" and let the gated recapture rewrite its references. It is
not menu churn: it DUPLICATES the unplugged scrollbar and then carried the copy 80px clear, so D2
left the two scrollbars sitting 10px apart. The test still PASSED and the gate still said COMPLETE —
a recapture gate proves the suite is self-consistent, **not** that the new pixels are the ones you
want. Only a human looking at the images caught it.

The evidence was already on disk and I did not read it: of the four images, `image_1`/`image_2` had
the SAME `dataHash` before and after (only the unused `systemInfoHash` in the filename moved), while
`image_3`/`image_4` — the two shots after the duplication — genuinely changed. A test where only the
post-duplication shots move is a D2 casualty, not menu churn. **Diff the dataHashes per image before
accepting a recapture**; the ones that changed tell you what the change actually did.

Fixed by carrying the copy via its own "pick up" (the same idiom as the rest), which restored
`image_3`/`image_4` **byte-identical to the pre-arc references** — proof the recapture had baked in
damage rather than recording a legitimate change. Images 3 and 4 exist to COMPARE two knob positions,
so the two scrollbars must read separately or the test communicates nothing.

### The capstone gate caught a real bug the fork had been HIDING (2026-07-30)

The first closing gauntlet came back 12/13 with `capstone` failing twice (parallel AND serial retry —
a hard fail by `fg`'s design, never a flake): *1 careless end-of-cycle push,
`SystemTest_macroMenuPinnedInScrollPanel`, 1 FrameWdgt*. The suite itself was 268/268 — this gate is
about HOW a settle happened, not what it painted.

`eoc-production-probe.js` named it outright rather than by guesswork:

```
WidgetFactory.createNewColorPaletteWdgtInWindow
  → _applyBounds → _applyExtent → _scheduleRelayoutRespectingPhase → _invalidateLayout   [careless]
```

Both `createNew{Gray,Color}PaletteWdgtInWindow` frame the palette **after** `world.add`, so the window
is already live and painted when it is sized — a public mutation, which must SELF-SETTLE. The raw
`_applyBounds` left the relayout on the end-of-cycle work list. Fixed by using the public one-shot
`setBounds` (both methods; the gate only caught the one a test happens to click). Verified: careless
pushes 1 → 0, test still passes, so pixel-neutral.

⚖ **This is the arc's own thesis landing on itself.** Phase 7 did not break this — it EXPOSED it.
These two items lived behind `popUpDemoMenu`'s index-page-only branch, so the harness page could never
reach them and **no gate had ever run this code**. Eight years of a fork meant a real
settle-discipline violation sat in shipping product code, invisible, because the tests were looking at
a different menu. Merging the catalogues is what made it findable.

### Closed (2026-07-30)
`fg recapture --auto` → ✅ **RECAPTURE COMPLETE**: 17 references recaptured at dpr 1 and 2 (13 pure
menu churn from the D1 union + 4 from the rewrites), full suite green at every recaptured density.
22 generated `visualisation.html` pages regenerated (they embed the hashed reference filenames and
still carried pre-arc-2 `?sw=1` launch links). Then `fg gauntlet` EXIT=0 (13/13) and `fg homepage`
EXIT=0 — which also discharges phase 6's gauntlet, whose only failure had been a stale-build error
of my own making.

### Traps this arc paid for — do not re-learn them
- **A running long op OWNS its inputs.** Editing src during a gauntlet trips the STALE BUILD guard
  and aborts wave B. It cost one full invalid run here.
- **Grep `tests/` as well as `src/` before any rename or move.** A macro reads core internals
  directly (`world.pinouts.currentPinoutingWidgets`), so a member can have zero `src` references
  and still break a test. That cost one red gauntlet in phase 5.
- **`rc=1` twice on a leg — parallel AND serial retry — is a hard fail by `fg`'s design, never a
  flake.** The evidence is in the preserved `/tmp/fg-<leg>.parallel-fail.log`; read it before
  reaching for a machine-load explanation. `serialization` and `refs` legitimately come back
  `PASS-serial-only` (the known atlas-warmth flake).
- **Read the suite's `=== RESULT ===` block, not interim `FAIL` lines** — the latter include
  retries that passed.

## Why this phase exists

The homepage/dev split was born when the OLD test system recognised widgets by string/ID, so
menus could only ever grow additively. Macros killed that constraint — they interrogate the
live world — so reorganising a menu now costs a mechanical recapture wave, not test rewrites.
Phases 1–6 re-homed the code; this phase converges what the user SEES.

## The fork being removed (measured 2026-07-29)

`Widget.buildBaseWidgetClassContextMenu` branches on `world.isIndexPage` — true for
`index.html` / `index-sw.html`, false ONLY for `worldWithSystemTestHarness.html`. So the
harness page has been showing a different widget menu from the product page:

| Item | index page | harness page |
|---|---|---|
| color… · transparency… · resize/move… · create shortcut · pick up | ✓ | ✓ |
| duplicate | `duplicateMenuAction` (in place) | `duplicateMenuActionAndPickItUp` |
| save to file… | ✓ | — |
| attach… · inspect · test menu ➜ | — | ✓ |
| hide | — | ✓ |
| dev ➜ | ✓ (or while a macro runs) | — |
| destroy | — | ✓ |

`WorldWdgt.popUpDemoMenu` forks the same way: "parts bin" (index) vs "make a widget" (harness).

## D1 — one widget context menu: the UNION

Everything either branch offers today becomes standard; the genuinely dev/test-only entries are
CONTRIBUTED by their family, so they appear only where that family ships. The product page gains
`attach…` and `inspect`; the harness page gains `save to file…`.

```
  color...
  transparency...
  resize/move...
  ---
  duplicate
  save to file…
  create shortcut
  pick up
  attach...
  inspect
  ---
  lock/unlock to desktop|panel      (already conditional on parent.childrenCanLockToMe)
  close | delete                    (already conditional on isFrame)
  ---
  [test menu ➜]  contributed when the harness ships
  [dev ➜]        contributed when DemoMenus ships
  [destroy]      dev-gated
```

## D2 — `duplicate` means COPY IN PLACE

The two pages disagreed on behaviour, and unifying forces one answer. `duplicateMenuAction`
(copy appears offset from the original, nothing rides the pointer) becomes standard everywhere:
less surprising for an end user. The pick-up variant may stay reachable as its own separate item
("duplicate & pick up") if wanted, but it is not the default.

## D3 — `isDevMode` KEPT, default ON

No behaviour change from today: boot continues to set `isDevMode = true` on both entry pages, and
it stays a user-flippable switch. It now gates a smaller set, because Phase 5 already promoted the
six product-worthy items of the old world-menu block unconditionally (owner census split):

- **unconditional:** inspect · fit whole page · color… · wallpapers ➜ · input-mode toggle ·
  new folder · about
- **isDevMode-gated:** delete all · move all inside · plus whatever the families contribute

## What Phase 7 must also do

1. **Unify `popUpDemoMenu`'s two branches** into one catalogue (it is one design now).
2. **Delete `BoxyAppearance`'s "pick inset…" row** — the LAST `»>>` region in src. Its action
   method `doNothingInsetsFunctionalityHasBeenRemoved` does not exist (clicking it throws), but
   the row still RENDERS, so removing it shortens every Box-family context menu. Phase 3
   deliberately left it here rather than churn six menu tests in a phase declared pixel-neutral.
3. **Introduce the contribution point** (`menuContributors`, H-R3). Phase 5 used per-item
   existence guards instead, because the world-menu items INTERLEAVE (demo before `inspect`,
   test menu after it) and a single append point cannot reproduce that order — order fidelity is
   what made Phase 5 pixel-neutral. Phase 7 is reordering anyway, so the hook lands here.
4. **Close with ONE recapture wave:** `fg recapture --auto` gated COMPLETE, then a full
   `fg gauntlet`. Expect substantial churn — every test that opens a widget or world menu.

## Verification

`fg recapture --auto` printing COMPLETE, then `fg gauntlet` green, then `fg homepage` green.
The region-marker gate's homepage baseline goes to **0** when item 2 lands, at which point
build.py's last region regex is deleted (Phase 6 removes the other two).
