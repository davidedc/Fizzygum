# Ratchet audit — standing status of the known cases, and the delta after 2026-11-16 22:00 UTC

Written 2026-11-21 (read-only audit; nothing in any repo was edited, built or committed). Tree read at
Fizzygum `b6b2f60f`, Fizzygum-tests `e06b7c26a`, both clean.

**Conventions.** VERIFIED = I read the code, the commit or the transcript line myself. INFERRED = concluded from
adjacent evidence. Transcript citations are `<session>[/a-<agent>] L<line> <UTC time>`, where `<session>` is the
8-character prefix of a file in `/Users/davidedellacasa/.claude/projects/-Users-davidedellacasa-code-Fizzygum-all/`
and `/a-<agent>` is `<session-id>/subagents/agent-<agent>.jsonl`. `.scratch/` is
`/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/`. Source paths are under
`/Users/davidedellacasa/code/Fizzygum-all/Fizzygum/` unless they start with `Fizzygum-tests/`.

**The numbers today (VERIFIED by running the two read-only gates, 2026-11-21).** Every ratchet sits exactly at its
count: `Widget` 394/394, `WorldWdgt` 129/129, `ActivePointerWdgt` 74/74, `FrameWdgt` 167/167; 94 functions above
complexity 15, all recorded (90 src + 4 harness), none under its record; `instanceof-type-test` 64/64;
`comment-narration` 80/80. The one exception is the instruction-file ceilings: `Fizzygum/CLAUDE.md` is 35047 bytes
against 35421 and `Fizzygum-tests/CLAUDE.md` 65867 against 67015 (374 and 1148 bytes of unbanked headroom).

---

## 1. Job 1 — the known cases, as they stand

| # | Case | State today | My verdict on merit | Undo needed? |
|---|---|---|---|---|
| a | `WorldWdgt` R8 (door, climb, notification) | Reverted contortion; the clean shape is in the tree, ceilings raised with reasons | Right shape | No |
| b | `@root().noteEditModeChanged?()` inline at 4 flip sites | Still inline (the argument went on 11-18) | Borderline, acceptable; a helper is a small gain | Optional |
| c | `window.aTestIsPlaying` boot function | Unchanged | Fine on merit, arguably the better home | No; close the re-judge as "keep" |
| d | `WorldWdgt.loadWorldSnapshot` at complexity 67; `WorldInventory#takeInventory` at 129 | Unchanged, both still recorded | Worse than the natural shape: the ratchet still blocks the refactor | Yes (d1); d2 waits on a gate change |
| e | `instanceof TransformFrameWdgt` removed from `Widget._dropPolicyProxy` | Unchanged | Fine on merit | No |
| f | Two `Fizzygum/CLAUDE.md` wording squeezes | The sentence is accurate; the file now has 374 bytes of headroom | Fine (terse, true) | Optional, no raise |

### (a) The WorldWdgt R8 shape — VERIFIED, nothing to undo

- The public door: `src/WorldWdgt.coffee:1923` `editableEditorFocus: (hostWindow) ->`.
- The intent-named notification: `src/WorldWdgt.coffee:1899-1901`
  `noteEditModeChanged: ->` / `@dataflow?.markNonValueChange @`.
- The climb is not a `WorldWdgt` member any more. At 23:21 on 11-16 it moved to `Widget` as the question a second
  reader (a text's own menu) also asks: `src/basic-widgets/Widget.coffee:798` `sitsInViewModeContent: ->`. So the
  committed raise was `WorldWdgt` 126 → 128 and `Widget` 391 → 392 (commit `fa5f3417`), not the 129 the first audit
  recorded while the work was uncommitted. `buildSystem/check-complexity-ratchets.js:49-50,59-61` carry both reasons.
  The move was decided on merit; the orchestrator's note reads "moves the 'sit in view-mode content' check onto
  Widget so both the world and the text can use it … Ratchets net to zero" (fd5c9317 L2521, 11-16T23:21): the count
  is stated as a consequence, and both ceilings were raised anyway.
- Later changes, both with a dated reason: `WorldWdgt` 128 → 129 for `_keepEditingOnScreenNoSettle`
  (`src/WorldWdgt.coffee:1967`, commit `bbe570c5`); `noteEditModeChanged` lost its argument and its "only above the
  focus" filter (commit `4f2f4b6f`, 11-18) because a second reader, a pinned text menu's rows, hangs on flips
  anywhere. That is the same event with a filter removed, not a notification stretched over a different event.

### (b) The Widget inline — VERIFIED standing, borderline

Four sites, each one line:
- `src/basic-widgets/Widget.coffee:5408` and `:5458`: `@root().noteEditModeChanged?()`
- `src/basic-widgets/ViewportWdgt.coffee:1544` and `:1558`: `@root().noteEditModeChanged?()`

Origin (VERIFIED, fd5c9317/a-a2d73c7311d0f70eb L399, 11-16T22:19): "`Widget` had the same problem (a helper method
took it to 392 against 391). I fixed that by writing the call inline as `@root().noteEditModeChanged? @` at each
flip site". The orchestrator re-judged it the same evening and kept it: "each site is one line … and a helper would
only rename it" (fd5c9317 L2059).

My judgment: acceptable, with one thing a helper would add. The non-obvious rule is which world is asked ("the root
I stand under, never the global one … a root that is no world answers nothing"), stated once in a seven-line comment
at `Widget.coffee:5401-5407` and pointed back to from the other three sites. Since 11-19 both `Widget` cores also
follow the tell with `@_fullChanged()` (`:5412`, `:5459`), so in `Widget` the pair is two lines written twice.
- **The undo, if wanted:** a private `Widget._noteMyEditModeFlipped` holding the tell, its comment, and (for the two
  `Widget` cores) the whole repaint; `ViewportWdgt` inherits it (`ViewportWdgt extends ScrollIndicatorHostWdgt
  extends ClippingWdgt extends Widget`).
- **Ratchet:** `Widget` 394 → 395.
- **Reach:** 4 call sites in 2 files, no test names the spelling.
- **Pixels:** a new `Widget` member shifts inspector member lists, so a benign recapture of the inspector churn set
  (`Fizzygum-tests/scripts/inspector-churn-set.json`) is plausible. That cost is the honest reason not to do this
  one alone; fold it into the next change that adds a `Widget` member.

### (c) `window.aTestIsPlaying` — VERIFIED standing, fine on merit

`src/boot/globalFunctions.coffee:177-178`:
```
window.aTestIsPlaying = ->
  Automator? and Automator.state == Automator.PLAYING
```
18 call lines in 12 src files (the hand, the caret blinker, the clock and plot appearances, the tooltip, …) plus
one harness comment. The ratchet did pick the home (`.scratch/cleanups-loop-2/LEDGER.md:571-573`: "the build refused
it, `WorldWdgt` is at its method ceiling (126→127), and a unit never raises a ratchet → RULING: a boot function"),
and commit `324f6d64` states only the after-the-fact reason.

On merit the boot function is the better of the two homes: the fact belongs to the page's one `Automator`, which
outlives every world; a `WorldWdgt` static would make twelve unrelated classes name `WorldWdgt` for a fact the world
does not own; and boot already holds the page-level questions (`classNamed`, `hashOfString`, `superclassOf`). The
one argument for the static is that its sibling facts, `WorldWdgt.timeOfEventBeingProcessed` and
`dateOfCurrentCycleStart`, are statics there.
- **The undo, if the owner prefers the static:** `@aTestIsPlaying:` on `WorldWdgt`, 129 → 130, 18 call lines, three
  docs (`docs/architecture/input-and-gestures.md`, `viewports-and-planes.md`, `src/macros/MACRO-PATTERNS.md`). No
  pixel moves. I recommend not doing it and closing the backlog's "re-judge case 3" as "keep".

### (d) `loadWorldSnapshot` unsplit — VERIFIED standing, the ratchet still blocks the refactor

`src/WorldWdgt.coffee:2780-2981`, recorded at `buildSystem/check-complexity-ratchets.js:185`
(`'WorldWdgt#loadWorldSnapshot': 67`). No commit since `9966b424` touches its shape. The method is about 200 lines
whose own comments number its phases: the guards, then `# 0.` what the file needs, `# 1.` teardown, `# 2.` id
counters, `# 2b.` class-edit replay, `# 3.` deserialize, `# 4.` preferences, `# 5.` world scalars and users,
`# 6.` storage and app windows, `# 7.` attach the children, `# 8.` colour and wallpaper, `# 9.` registry and
repaint. It is exactly the "phase after phase" function the split of `Deserializer.deserialize` was made for, and
the one reason it was left is in the commit: "its class sits at its method ceiling, and its locals cross a
try/catch/finally".

- **The right shape.** The public method keeps what must stay in it: the four guards with their
  `early-return-sanctioned` comment, step 0's re-entry with its `double-settle-sanctioned` comment, the two
  `_settleLayoutsAfter` calls, and the `try / catch / finally` that guarantees a bin and a shelf. The phase bodies
  become private cores it calls in order:
  - `_restoreIdCountersAndClassEdits section` (2 and 2b), returning the restored registry and the two counts;
  - `_sourceEditsNoticeFor unreplayedCount, stillEditedCount` (the notice text, pure);
  - `_applySnapshotWorldState section, resolve` (4 and 5: preferences, scalars, info-doc flags, naming counters,
    users);
  - `_installSnapshotStorageAndAppWindows section, resolve` (6);
  - `_attachSnapshotChildrenNoSettle section, resolve` (7's body).
- **Ratchet:** `WorldWdgt`'s method ceiling 129 → 134 (five members), dated; the complexity record 67 is lowered or
  deleted in the same change. The alternative home, a plain `WorldSnapshotLoader` collaborator in the
  `MacroToolkit` style, needs no raise, but it would exist to dodge the count: the phases read and write the world's
  own fields.
- **Reach:** one file; both serialization rigs (177 expectations and the file round trip) and
  `world.teardownHygiene.*` are the proof; `check-layering` and the settle gates re-read the sanction markers.
- **Pixels:** none expected. Inspector churn only where a churn-set test shows the world's own member list.
- **Risk:** medium. The order is the correctness argument (step 0 before any mutation, the `finally`), and three
  locals (`restoredRegistry`, `sourceEditsNotice`, `resolve`) are read after the `try`.

`WorldInventory#takeInventory` (`src/WorldInventory.coffee:113`, record 129 at ratchet line 174) is the second half
of this case and is blocked by a different rule: `WorldInventory` has no method ceiling, but the natural first cut
"would score 16 … would need a NEW record" and the gate cannot record a new function above 15
(`check-complexity-ratchets.js:251-255`). It stays until the backlog item's "let a split's child be recorded when
the split lowers a recorded parent" lands. The gate's footer is unchanged today (line 281: "split the function or
the class rather than raising a number here").

### (e) `_dropPolicyProxy` — VERIFIED standing, fine on merit

`src/basic-widgets/Widget.coffee:2186-2193`: `break if !figure._materializedBySugar`. The removed
`figure instanceof TransformFrameWdgt` was implied by the test that stayed: only `TransformFrameWdgt` declares the
field (`src/TransformFrameWdgt.coffee:31`), and the same field is the sugar test at `Widget.coffee:1952`, `:1995`,
`:2083`, `:2240`, `:2277` and `ActivePointerWdgt.coffee:842`. Four weeks later the plane-mapping protocol removed
ten more `instanceof TransformFrameWdgt` on merit (commit `056c8328`, 74 → 64). Undoing would mean writing a
redundant type test back and raising the stink 64 → 65: worse. Keep.

One neighbour worth knowing, not ratchet-driven as far as the evidence shows (INFERRED): `_enclosingSoleContentIsland`
(`Widget.coffee:2142`) tests the field's EXISTENCE (`!p?._materializedBySugar?`) as "the island test". That is a
duck-typed type test of the kind `widget-authoring-guidelines.md` §14 ranks below a capability query. It came with
`056c8328`, whose comment says so openly.

### (f) The two CLAUDE.md squeezes — VERIFIED, accurate today

`Fizzygum/CLAUDE.md:11`: "Prerequisites: `npm ci` here (`coffee`, `terser`, acorn, the complexity analyzer, all
pinned), a global `fswatch` (watch script only), Node 20 or later …". This is `2868c732`'s wording after its review
fix; `def42b0f`'s sentence ("the `coffee` and `terser` the build runs, pinned in `package.json`") was replaced by
it. It is true: it lists the four npm-pinned tools and no longer claims every tool is pinned. It is also thinner
than the umbrella file's version of the same fact (`/Users/davidedellacasa/code/Fizzygum-all/CLAUDE.md:91`, which
keeps "the build runs", "its gates load" and "the build refuses to run without them"). Since `4c377414` (11-19) the
file is 374 bytes under its ceiling, so the fuller sentence fits with no raise. Optional.

---

## 2. Job 2 — the delta, 2026-11-16 22:00 → 2026-11-21 22:00

Ordered by date. A legitimate case gets its row and nothing more; the cases that are not legitimate have a
paragraph after the table.

| # | Date (UTC) | Session / commit | Ratchet | What was done | Verdict |
|---|---|---|---|---|---|
| 1 | 11-16 23:25 | fd5c9317/a-af50aea86f038cc0f L223; fd5c9317 L2549; `fa5f3417` | complexity record `StringWdgt#_addTextMenuEntries` 18 | a guard took it to 19; the agent split out `_addAlignmentAndFittingMenuEntries` and refused "a split along the metric"; the record went | LEGITIMATE (VERIFIED). "That split was prompted by the ratchet, but it's sound on its own" |
| 2 | 11-17 08:17 | fd5c9317 L3545, L3591; `8e4393c6` | `FrameWdgt` 170 | raised to 171 with its reason | LEGITIMATE raise |
| 3 | 11-17 11:53 | fd5c9317 L4720 (P3 brief) | `WorldWdgt` 128 | "No new WorldWdgt method (… if you believe one is needed, STOP and report instead)" | LEGITIMATE: the stop-and-report form |
| 4 | 11-17 17:04 | fd5c9317/a-a926b8d02bd7d5950 L771; `24fc1e1b` | call-separation [U] effectful 0 | `actOn` made public because layering rule [A] forbids the `_` form; allowlisted with that reason | Out of ratchet scope (a non-ratchet gate chose the tier); the number was not touched |
| 5 | 11-17 20:53 | fd5c9317 L7061, L7736; `2b300652` | `Fizzygum/CLAUDE.md` bytes | ceiling 35294 → 35421 for the one link to `toolbars.md` | LEGITIMATE raise |
| 6 | 11-18 01:39 | c3e1441a L1661, L3891; `.scratch/overnight-toolbar-residue/LEDGER.md:75-76`; `bea22b69` | `WorldWdgt` 128 | U3 PARKED overnight: "A fix needs an announcement … `WorldWdgt` at its method ceiling (128) → PARK"; U7 parked behind it | RATCHET BLOCKED A UNIT, since undone (row 7) |
| 7 | 11-18 12:23 | c3e1441a L3922 (owner), L4327, L5136; `bbe570c5` | `WorldWdgt` 128 | owner: "figure out the most clean and elegant architectural / code solution"; `_keepEditingOnScreenNoSettle` landed, ceiling 128 → 129 | LEGITIMATE. No notification was stretched (lead (i), below) |
| 8 | 11-18 02:33, 03:28 | `23ec3a2f`, `197975e1` | `FrameWdgt` 171, 172 | two owner-granted raises (`smallestExtentKeepingMyBandsUsable`, `offersEditToggle`) | LEGITIMATE raises |
| 9 | 11-18 03:33 | c3e1441a L3246-3288; `cb8997b3` | call-separation [U] query 104 | the first cut's helper `MenuItemWdgt.disabledInkForMyParts` made `isDisabled` self-only (105); the helper was dropped and each part asks `@parent?.isDisabled?()` | BORDERLINE, still in tree |
| 10 | 11-18 18:35 | c3e1441a L7088; c3e1441a/a-a9e79df49913110c6 L675; `docs/archive/editing-residue-plan.md:566-567` | `Widget` 392 | a copied "Layout in stack" menu's bug was FILED, not fixed: "Fixing it needs new `Widget` methods, and `Widget` is at its method ceiling, so I'll file it" | RATCHET BLOCKED A FIX, since undone: `1de8a0ae` (11-20) fixed it with the raise 392 → 393 |
| 11 | 11-18 18:49 | c3e1441a/a-a53d672b7d14ed9d4 L707; 3aefc39e L6556; `5887cf90` | complexity ceiling 15 | `@_fullChanged()` in both mode cores, unconditional: "Complexity stays at the ceiling of 15; wrapping it in a condition would make it 16" | BORDERLINE in its stated reason, fine in its result (a whole repaint on a rare flip needs no condition) |
| 12 | 11-18 23:12 | 3aefc39e L2964, L2971, L3011; `ef925031` | records `boot` 30, `BrowserInputBridge#_initKeyboardEventListeners` 19 | "the brief allows only one raise per unit, so I'm restructuring instead": the family derivation moved to `User.keyboardFamilyOfThisPage`, `_keydownDefaultIsPrevented` was extracted; both records fell | LEGITIMATE (lead (ii), below) |
| 13 | 11-19 02:19 | 3aefc39e L5529; `9c5d1076` | complexity ceiling 15 | `Widget#_disableDragsDropsAndEditingNoSettle` recorded at 16: "keeping the guard in the core rather than splitting its rule across files just to hit the count" | LEGITIMATE raise (the record was deleted as stale on 11-20, `0cfa93dd`) |
| 14 | 11-19 05:08 | c3e1441a/a-ae592538060524bea L576; `445998cb` | `FrameWdgt` 173 | the titled strip's floor joined `smallestExtentKeepingMyControlsUsable` (renamed); the strip's own measure is a new `FrameBarWdgt` method; "no ceiling raise" | LEGITIMATE (VERIFIED, `src/FrameWdgt.coffee:1291-1308`: one question, one answer) |
| 15 | 11-19 10:48 | f6c026f1 L1543; `.scratch/editing-residue-followups/LEDGER.md:69-71`; `5de622d5` | record `swCanvasEnsureAtlasForFont` | "Rather than raising that limit, I'll merge the check into the function's existing guard chain of `and`s, which adds no complexity" | BORDERLINE, still in tree |
| 16 | 11-19 14:34-14:48 | f6c026f1 L3441, L3573, L3618; f6c026f1/a-a14a39267be71ce5f L229; `02891726` | record `CaretWdgt#processKeyDown` 27 | raised to 28, then the review found the rule too broad and the raise unneeded; one predicate `keystrokeMayType`; the record fell to 26 | LEGITIMATE |
| 17 | 11-19 16:36 | f17cfbf3/a-aac2be3defeac0ffb L333; `cbcbc96c` | `WorldWdgt` 129 | "A new WorldWdgt query … is blocked by the method ceiling … and the query would have one consumer"; the fix went to the sheet's `_keysAreMine` | LEGITIMATE: the ceiling was one reason of four, and a one-reader world query would not earn its place |
| 18 | 11-19 17:10 → 11-20 07:01 | f17cfbf3 L655 (G3); c465c3ed L393 (H3), L838 (H4a), L3033 (H3d); the four `IMPL-BRIEF.md` files | `Widget` 392 | implementation briefs carry a house rule: "`Widget` is at its method ceiling (392): add NO method to Widget" | PROCESS DRIVER. No code contortion in the four units' `Widget.coffee` hunks (VERIFIED: one to four natural lines each); other files INFERRED from the stats |
| 19 | 11-20 03:55 | c465c3ed/a-a2232c365d7d16f3f L331; c465c3ed L2181, L2220; `759d85b1` | record `InspectorWdgt#selectionFromList` 21 | review: re-clicking the same member "loses the Cmd+Z that used to bring back the unsaved typing … A guard would take the method to 22"; orchestrator: "A guard would need a ratchet raise; I'll reword instead" | **CONTORTION, still in tree** |
| 20 | 11-20 10:12, 12:32 | c465c3ed L3651; f4c213ac L1222; `1de8a0ae`, `1d8a851c` | `Widget` 392, 393; record `Serializer._buildObjectTable` 106 | three raises (393, 394, 109), each dated with its reason | LEGITIMATE raises |
| 21 | 11-19 21:44 | 853080ec L1303, L1345; `docs/archive/scroll-indicators-plan.md:300-315`; `.scratch/scroll-indicators-loop/BRIEF.md:66-71` | all four method ceilings; both CLAUDE.md ceilings | the plan's §2.7 is titled "Gate constraints that shape the edits" ("This plan ADDS NO METHOD to any of them"); the brief: "a unit that finds it must is a PARK, not a raise"; "Not granted … growing either `CLAUDE.md`" | PROCESS DRIVER: the pre-ruling rule, back in a plan written three days after the ruling |
| 22 | 11-20 16:16 | 5fae7abf/a-a80d04605e2fec6cd L457; `f3f9230f` | record `ViewportWdgt#_reLayoutScrollbars` 26 | "Writing that test inline takes [it] from 26 to 30 … A per-bar helper, `_indicatorEndInsetFor bar`, keeps it at 26" | LEGITIMATE: the gate asked for a named helper |
| 23 | 11-20 18:04, 18:43 | 5fae7abf L1457, L1597; `.scratch/scroll-indicators-loop/u3/PREP.md:17-18,64`; `b3d41643` | `Widget` 394 | "`Widget` is at its ceiling, so the answer is a `ViewportWdgt` member read through a soft probe": `boxPresentedToOverlays`, its fallback spelled at four readers | **CONTORTION, still in tree** (mild) |
| 24 | 11-20 20:02 | 5fae7abf/a-aff30415c82abc0bd L598; `d0043e4b` | record `SimpleSpreadsheetWdgt#_reconcileViewportNoSettle` 24 | "An unconditional mark keeps it at 24; any guard fails the ratchet" | LEGITIMATE as landed: the announcement lives in `_reDeriveViewNoSettle` and its comment gives a behaviour reason (`src/spreadsheet/SimpleSpreadsheetWdgt.coffee:482-484`: a guard "would leave a zoom menu showing the old level") |
| 25 | 11-21 00:43 → 15:51 | `343c1398`, `b3d41643`, `27e22e31` | `FrameWdgt` 173 | lowered to 170, 168, 167 as three refactors deleted hooks and overrides | LEGITIMATE (gains banked) |
| 26 | 11-21 09:35 | 5fae7abf L7107 (research brief for U4b/U4c) | all four method ceilings | "no method may be added to Widget (394/394) … : if your fix needs one there, say so and find another seat" | PROCESS DRIVER (verbatim "find another seat") |
| 27 | 11-21 13:16 | 5fae7abf/a-a525f3fe3f3a0657d L250; `.scratch/scroll-indicators-loop/u4c/PREP.md:27-28`, `REVIEW.md:70-88`; `71a656b1` | `Widget` 394 | D3: "no new method … (Widget is at 394/394 anyway)": the settle round `_pickOutRotatedFigureNoSettle` stays an inline thunk, and the layering doc's "shape 2" list was widened to hold it. D2 (no rename, because inspector recapture was not granted) was undone the same hour after the review | BORDERLINE, still in tree (D3). D2: recapture churn, not a ratchet, since undone |
| 28 | 11-21 14:47 | 5fae7abf/a-aefaf81c265d73c23 L465; `27e22e31` | call-separation [U] query 103 | "renaming it to `_clipThroughForChild` instead of raising the baseline" | LEGITIMATE: a hook only `@`-called is `_`-tier |
| 29 | 11-21 17:28 | 5fae7abf L14258-14320; Fizzygum-tests `34877ad9d` (message: "net-zero in bytes") | `Fizzygum-tests/CLAUDE.md` bytes | one sentence added, then five wordings trimmed until the file measured the same as HEAD: "That's 137 bytes over, so I'm trimming wording elsewhere in the same paragraph to bring it back to net zero" | **CONTORTION, still in tree** |
| 30 | 11-18 → 11-20 | c3e1441a L7011; c465c3ed L2925, L3423 | BACKLOG item 325 characters | lines rewritten "more tightly"; once the pointer "(measured: `.scratch/h5-dupcaret-probe.js`)" became "(measured)" | BORDERLINE as a class, mild: the ceiling is doing its job (an index line), but a breadcrumb was cut where a detail entry was the designed answer. That item is closed now |
| 31 | 11-19 22:10 | 0e4b5781 L520; `4c377414`, tests `0d3f60f60` | both CLAUDE.md byte ceilings | prompt audit: "The dead-link fix … adds 4 bytes, so take it with at least one trimming hunk" | LEGITIMATE: the trims were the audit's own findings (history, migration stories); both files ended well under |

### The two leads

**(i) Session c3e1441a, U3, "noteEditModeChanged generalised".** VERIFIED. The park paragraph offered "(a) … This
needs a `WorldWdgt` method-ceiling raise, or `noteEditModeChanged` generalised" (c3e1441a L3891, 11-18T04:54; the
plan's version at `docs/archive/toolbar-arc-residue-plan.md:311-315` names the generalisation: "one 'the focus's
door may have changed' announcement"). The owner answered "I don't accept C, figure out the most clean and elegant
architectural / code solution" (L3922, 12:23). What landed (`bbe570c5`, 15:28) is neither a hook on the close, hide
and collapse cores nor a stretched notification: a new once-per-cycle station, `WorldWdgt._keepEditingOnScreenNoSettle`
(`src/WorldWdgt.coffee:1967-1977`), which derives where the focus stands and announces a change, with the ceiling
raised 128 → 129 and the reason beside it (`check-complexity-ratchets.js:61-65`). `noteEditModeChanged` kept its
one event. The station also ends an edit whose text left the screen; that second half was the owner's choice
("Include it", L5671 summary), and the method's comment presents both as one job (the two editing registers follow
the screen). Verdict: LEGITIMATE. The ratchet's cost here was the eleven hours U3 and U7 sat parked.

**(ii) Session 3aefc39e, "at most one ratchet raise per unit … by the smallest amount".** VERIFIED. The cap bent
one unit's shape, for the better: U3 of the editing residue (row 12). It was never the binding constraint in a bad
outcome. Row 19's unit (H2) had its one raise unused when the orchestrator declined a guard "because a guard would
raise a complexity ratchet"; the habit decided, not the cap. Where the cap's wording did harm is the sentence the
later briefs grew around it (rows 18, 21, 26).

### The cases that are not legitimate

**Row 19 — the inspector's undo history (CONTORTION, still in tree; VERIFIED).**
`src/meta-tools/InspectorWdgt.coffee:601-603`:
```
    # every load of a member's source starts the pane's history afresh, the same member's reload included
    # (it replaces unsaved typing with the saved source): no undo or redo brings back a text from before it
    cnts.forgetUndoHistory()
```
The unit's own rule was "another subject starts a fresh history". The review (c465c3ed/a-a2232c365d7d16f3f L331,
11-20T03:55) found that a re-click on the SAME member now forgets too: "That breaks the stated 'another subject'
rule and loses the Cmd+Z that used to bring back the unsaved typing. A guard would take the method to 22, over its
record of 21, so it needs either a dated ceiling raise or reworded comments." The orchestrator chose the comments:
"I'm only correcting the comments here, not adding a guard, because a guard would raise a complexity ratchet. It's
on your second-look list" (c465c3ed L2220). So a behaviour a person can lose work through was kept, and the comment
was rewritten to describe it as the rule. The owner was told (`.scratch/editing-residue-followups-3/LEDGER.md:91`),
so it is not hidden; it is undecided.

**Row 23 — `boxPresentedToOverlays` (CONTORTION, still in tree, mild; VERIFIED).**
The answer is defined on one class, `src/basic-widgets/ViewportWdgt.coffee:422-424`, and every reader spells the
base case itself:
- `src/HighlighterWdgt.coffee:105`: `box = aTarget.boxPresentedToOverlays?() ? aTarget.clippedThroughBounds()`
- `src/WorldWdgt.coffee:1798`: `badgeTarget.mapRectToScreen (badgeTarget.boxPresentedToOverlays?() ? badgeTarget.clippedThroughBounds())`
- `src/dev-tools/PinoutsOverlay.coffee:57` and `:77`: the same expression twice more.

The definition's own comment describes a base case that no class defines: "asked through ?() of the overlay's
target, which answers clippedThroughBounds when it answers nothing". The preparation notes give the reason in so
many words: "⚠ `Widget` and `WorldWdgt` sit at their method ceilings: the answer lives on `ViewportWdgt`, read
through a soft probe" (`u3/PREP.md:17-18`) and "`Widget` is at its ceiling, so the answer is a `ViewportWdgt` member
read through a soft probe" (`:64`; 5fae7abf L1597, 11-20T18:43).
In fairness: a soft probe is the house placement for a capability QUERY that replaces a type test
(`docs/architecture/widget-authoring-guidelines.md:1005-1006`, "Do not add a `-> false` default on `Widget`"), and
the sibling answers added by the same unit (`resolvesEditorSelectionToContent?()`, `hostsSelectionRingOf?`) follow
it properly. This one is different in kind: it is a box every widget has, with a real default, and the default is
written four times.

**Row 29 — `Fizzygum-tests/CLAUDE.md`, net-zero by byte count (CONTORTION, still in tree; VERIFIED).**
The file was 1148 bytes UNDER its ceiling when this happened, so no gate asked for anything. The pressure was the
loop brief's "Not granted … growing either `CLAUDE.md`" and the plan's stale "both `CLAUDE.md` files sit at their
byte ceilings". To add the rule about `expectsCaughtErrors`, the session measured the file against HEAD and cut
until the sizes matched. What the cuts removed from the macro-tests paragraph (`Fizzygum-tests/CLAUDE.md:63`,
`git show 34877ad9d -- CLAUDE.md`):
- a true fact: "(there is no backend axis: the harness page IS the SWCanvas page)";
- a true reason: "SWCanvas + the event queue are deterministic and" matching is "not on anything else in the
  filename";
- a meaning: a verify failure "is a real disagreement about the pixels, not a staleness artifact" became "a real
  pixel disagreement, not a stale name", which names a different thing (the old text ruled out a stale BUILD);
- three greppable tokens: "`PAINT_ERROR`/`STEP_ERROR`/`INPUT_ERROR`" became "paint/step/input tokens", in the very
  sentence that introduces them.
This is the first audit's case 2 again, five days after the ruling, without even a ceiling in the way.

**Row 9 — the dropped `disabledInkForMyParts` (BORDERLINE; VERIFIED).** Today
`src/basic-widgets/menu-system/InertIconHolderWdgt.coffee:75` and `MenuRowIndicatorWdgt.coffee:39` each read
`WorldWdgt.theme.menuRowDisabledText  if @parent?.isDisabled?()`, and `MenuItemWdgt.coffee:249` names the same role
a third time. The first cut had the row hand its parts their ink through one member; it went because the [U] query
count read 105 against 104. The orchestrator called the result "research D's shape", which is true, and it is two
one-liners. But the gate's other answer was the honest one here: `isDisabled` is read by tests as public API
(`src/macros/MACRO-PATTERNS.md:503`), so an allowlist line with that reason would have kept the helper.

**Row 15 — the folded guard (BORDERLINE, mild; VERIFIED).**
`src/boot/extensions/SWCanvasElement-extensions.coffee:246`:
`return unless coreFont? and coreFont.fontFamily? and window.SWCanvas? and not swCanvasBelowTheAtlases coreFont`.
It reads acceptably because the predicate has a name and a comment of its own (`:239-243`). A separate
`return if swCanvasBelowTheAtlases coreFont` with its one-line why would read a little better. Not worth a change
on its own.

**Row 27 — U4c's inline settle (BORDERLINE; VERIFIED).** `src/basic-widgets/Widget.coffee:2276`:
`figure ?= @_settleLayoutsAfter => @_pickOutRotatedFigureNoSettle()`. The research rejected the canonical thin wrap
as "a NEW Widget method (394/394) for one call site" (`u4c/RESEARCH.md:261-263`), and the unit's review named the
reason for what it was: "which is the ratchet-dictates-design shape. On the merits the outcome is fine: a settle
over a non-twin self core is common (25 sites by scan)" (`u4c/REVIEW.md:80-82`). I agree with the review on the
code. The residue is in the doc: `docs/architecture/layering-naming-convention.md:124-133` defines shape 2 as the
dispatcher round a counterparty's hook, where "there is no self-core to name", and then lists this site, which
settles round a self-core, with a clause explaining why it still counts.

**Rows 18, 21, 26 — the briefs (PROCESS DRIVERS; VERIFIED).** The P2-P4 briefs of 11-17 carried the ruling
correctly ("never inline a helper, fold two concepts or pick a home to stay under a number", fd5c9317 L2967). From
the first overnight loop on, the paperwork drifted back:
- `.scratch/overnight-toolbar-residue/BRIEF.md:154`: "any other ratchet or ceiling raise, or allowlist growth
  (needed ⇒ PARK)". Row 6 is its direct result.
- `.scratch/editing-residue-followups-2/BRIEF.md:31-33`: "Fold a new condition into an existing `and` chain or a
  predicate rather than adding a branch, when that is the natural shape anyway".
- `.scratch/editing-residue-followups-2/g3/IMPL-BRIEF.md:7`, `editing-residue-followups-3/h3d/IMPL-BRIEF.md:7`,
  `h4a/IMPL-BRIEF.md:7`, and H3's (c465c3ed L393): "add NO method to Widget".
- `.scratch/scroll-indicators-loop/BRIEF.md:67-69`: "a unit that finds it must is a PARK, not a raise"; `:71`:
  "Not granted … growing either `CLAUDE.md`".
- 5fae7abf L7107: "if your fix needs one there, say so and find another seat".
The owner's grants were narrower than the ruling by the owner's own choice (one dated raise per unit), and that is
his to set. What the briefs added on top is the reflex the ruling was meant to end: the shape is decided after the
count is read. Rows 23, 27 and 29 are what that produced in the one loop whose plan put "Gate constraints that
shape the edits" in a heading.

---

## 3. Every ratchet number that changed since 2026-11-16, with its stated reason (VERIFIED from `git log -p`)

**`buildSystem/check-complexity-ratchets.js`, method ceilings**

| Commit | Date | Change | Reason recorded beside the number |
|---|---|---|---|
| `fa5f3417` | 11-17 00:41 | `Widget` 391 → 392 | `sitsInViewModeContent`, "the one question 'do I sit in content in view mode'" (owner-approved) |
| `fa5f3417` | 11-17 00:41 | `WorldWdgt` 126 → 128 | the public door `editableEditorFocus` and the notification `noteEditModeChanged` (owner-approved) |
| `8e4393c6` | 11-17 11:24 | `FrameWdgt` 170 → 171 | a window holds a paint tool and offers `dockedPayloads` and `dockHost`; the `paintingOverlay` chain and `_dockedToolbar` went |
| `23ec3a2f` | 11-18 02:33 | `FrameWdgt` 171 → 172 | `smallestExtentKeepingMyBandsUsable` (owner-granted, toolbar residue U4) |
| `197975e1` | 11-18 03:28 | `FrameWdgt` 172 → 173 | `offersEditToggle`, the one definition of a window's pencil (owner-granted, U5) |
| `bbe570c5` | 11-18 15:28 | `WorldWdgt` 128 → 129 | `_keepEditingOnScreenNoSettle`, "on the owner's request for the clean shape" |
| `445998cb` | 11-19 05:46 | (comment only) | the floor method renamed `…ControlsUsable`: "the same count, one question" |
| `1de8a0ae` | 11-20 11:40 | `Widget` 392 → 393 | `actOnLayoutKnobFromMenu`, the one door for a layout spec's menu rows (the unit's one granted raise) |
| `1d8a851c` | 11-20 14:29 | `Widget` 393 → 394 | `isLeftOutOfCopiesAndSaves`, the one question both walkers ask (standing ruling) |
| `343c1398` | 11-21 00:43 | `FrameWdgt` 173 → 170 | LOWERED: one seat `_reactToChildRemoved` replaced three per-verb hooks |
| `b3d41643` | 11-21 09:47 | `FrameWdgt` 170 → 168 | LOWERED: `_visibleBoxOnMyPage`'s climb and `_pageSelectionRingReach` went |
| `27e22e31` | 11-21 15:51 | `FrameWdgt` 168 → 167 | LOWERED: the window's two child-paint overrides went to `ClippingWdgt` |

**`buildSystem/check-complexity-ratchets.js`, complexity records**

| Commit | Date | Change | Reason |
|---|---|---|---|
| `fa5f3417` | 11-17 | `StringWdgt#_addTextMenuEntries` 18 deleted | split (row 1) |
| `ef925031` | 11-18 | `BrowserInputBridge#_initKeyboardEventListeners` 19 deleted; `CaretWdgt#processKeyDown` 30 → 27 | restructured instead of raised (row 12) |
| `9c5d1076` | 11-19 | `Widget#_disableDragsDropsAndEditingNoSettle` 16 ADDED | a new record, owner-granted: "a mode held fixed … stays on in the core that writes it off" |
| `02891726` | 11-19 | `CaretWdgt#processKeyDown` 27 → 26 | one predicate `keystrokeMayType` (row 16) |
| `0cfa93dd` | 11-20 | `Widget#_disableDragsDropsAndEditingNoSettle` 16 deleted | the core fell to 11 |
| `2875523c` | 11-20 | `DataflowEngine#_processNode` 18 deleted | a helper took it to 11 |
| `1d8a851c` | 11-20 | `Serializer._buildObjectTable` 106 → 109 RAISED; `Serializer.serializeWorld` 37 → 35 | "a widget's children are encoded as a save carries them, one line in encodeOwnProps" (standing ruling) |
| `54140890` | 11-20 | `Widget#clipThrough` 20 → 17 | fell with the plane-margin change |
| `68cedf94` | 11-21 | `ViewportWdgt#_reLayoutScrollbars` 26 deleted | lifted to the new base and split per bar |
| `71a656b1` | 11-21 | key renamed to `Widget#_resolveStandingFigureNoSettle` (21) | the method's rename |
| `27e22e31` | 11-21 | `Widget#clipThrough` 17 deleted | fell to 7 |
| `18d5149b` | 11-21 | `MacroToolkit#_widgetAPressMeets` 20 deleted | fell to 4 |

**Other files**

| File | Commit | Change | Reason |
|---|---|---|---|
| `check-stinks.js` | `fa5f3417`, `68cedf94`, `a2015c07` | `comment-narration` 83 → 82 → 81 → 80 | each a rewritten comment, dated in the trailing note; all tightenings |
| `check-stinks.js` | — | `instanceof-type-test` 64, unchanged | no `instanceof` line was added or removed in `src/` since 11-16 (VERIFIED by diff) |
| `check-call-separation.js` | `3220143b` | `BASELINE_U_QUERY` 104 → 103 | a new test reads `searchLongestFittingTextByMultiCroppingIt` from outside; a tightening |
| `check-doc-narration-baseline.json` | `2b300652` | `Fizzygum/CLAUDE.md` 35294 → 35421 | RAISED: the link to `toolbars.md`, 127 bytes |
| `check-doc-narration-baseline.json` | — | `Fizzygum-tests/CLAUDE.md` 67015, `backlogItemChars` 325, unchanged | — |
| `check-plane-discipline.js`, `check-hand-lists.js`, `census-widget-conformance.js` | — | 30; 4 and 0; 0, 0 and 8: unchanged | — |

Totals: 8 method-ceiling raises, 1 new complexity record, 1 complexity record raised and 1 byte ceiling raised, all
with a dated reason; 3 method-ceiling lowerings, 7 records deleted and 4 lowered, 4 baselines tightened.

---

## 4. Standing contortions — the actionable list

Ordered by value for effort. S = one or two files and a targeted check; M = one subsystem and its rigs.

| # | Location | Right shape | Ratchet raise | Blast | Risks |
|---|---|---|---|---|---|
| 1 | `Fizzygum-tests/CLAUDE.md:63` (commit `34877ad9d`) | Put back what the byte count removed: the "no backend axis" parenthesis, the determinism clause, "not a staleness artifact", and the three token names in the `expectsCaughtErrors` sentence | None: about +300 bytes into 1148 of headroom | S | The `refs` leg re-reads the file; nothing else |
| 2 | `src/meta-tools/InspectorWdgt.coffee:562-610` (commit `759d85b1`) | Decide the behaviour first (owner second-look pending). If a re-click on the same member should keep its history: move the member-to-text derivation (`:565-597`) into a helper such as `_shownTextOfMember selected`, then guard `forgetUndoHistory` on a changed member, and restore the "another subject" comment | None by the split (the record 21 falls and is lowered or deleted); or 21 → 22 with the bare guard | S | Needs a test assertion (re-click, type, Cmd+Z); `InspectorWdgt` has no method ceiling; member-list churn only where an inspector inspects an inspector |
| 3 | `ViewportWdgt.coffee:422` plus `HighlighterWdgt.coffee:105`, `WorldWdgt.coffee:1798`, `dev-tools/PinoutsOverlay.coffee:57,77` (commit `b3d41643`) | `Widget.boxPresentedToOverlays: -> @clippedThroughBounds()` as the base answer, `ViewportWdgt`'s as the override, four readers asking unconditionally | `Widget` 394 → 395 | S | A new public `Widget` member shifts inspector member lists: a benign recapture of the churn set is likely. `check-dead-methods` and the resolution map re-read it |
| 4 | `src/WorldWdgt.coffee:2780-2981` (left by `9966b424`) | The phase split of §1 (d): five private cores, the guards, the settles and the `try/finally` staying in the public method | `WorldWdgt` 129 → 134; the record 67 lowered or deleted | M | Order is the correctness argument; three locals cross the `try`; both serialization rigs and teardown hygiene must stay green |
| 5 | `src/basic-widgets/Widget.coffee:2276` and `docs/architecture/layering-naming-convention.md:124-133` (commit `71a656b1`) | Either the thin wrap `_pickOutRotatedFigure` (shape 1) with the doc's shape 2 back to its definition, or keep the inline and give the doc a third named shape ("a settle round a non-twin self core": the review counted 25 such sites). The second costs nothing and is the honest one | `Widget` 394 → 395 for the wrap; none for the doc route | S | Doc route: none. Wrap: inspector churn as in item 3 |
| 6 | `menu-system/InertIconHolderWdgt.coffee:75`, `MenuRowIndicatorWdgt.coffee:39`, `MenuItemWdgt.coffee:249` (commit `cb8997b3`) | One member on the row for "the ink my parts wear while I am disabled", read by both parts; `isDisabled` allowlisted in `buildSystem/public-api-allowlist.txt` as test-read API | None ([U] stays at 103 through the allowlist line) | S | Low value; do it only when the menu-row classes are next touched |
| 7 | `Widget.coffee:5408,5458`, `ViewportWdgt.coffee:1544,1558` | `Widget._noteMyEditModeFlipped` (§1 b) | `Widget` 394 → 395 | S | Inspector churn; ride along with item 3 or 5 if either adds a `Widget` member |
| 8 | `src/WorldInventory.coffee:113` (record 129) | A real split of the walk | None on a class; needs the gate to record a split's child | M | Blocked until the backlog item's gate change lands |

Not on the list because they are fine as they stand: `window.aTestIsPlaying`, `_dropPolicyProxy`,
`Fizzygum/CLAUDE.md:11`, the unconditional `@_fullChanged()` of the mode cores, the folded atlas guard, the sheet's
unguarded announcement.

**The process side, which keeps producing the code side.** None of this is a repo edit I made; it is what the
evidence says to change.
- The gates still print the old advice. `check-complexity-ratchets.js:281` reads "split the function or the class
  rather than raising a number here", and `check-call-separation.js:90` "never raise the baseline to ship". Both
  backlog items of 2026-11-16 are open (`docs/BACKLOG.md:326-327`); `buildSystem/lib/ratchet-advice.js` does not
  exist.
- Every loop brief since 11-17 restates a narrower rule than the ruling (the five quotes under "the briefs"). The
  next brief template should say "STOP and report the right shape and the raise it needs", which is what the P3
  brief of 11-17 said and what worked.
- A memory note still teaches homing by the count:
  `/Users/davidedellacasa/.claude/projects/-Users-davidedellacasa-code-Fizzygum-all/memory/cleanups-loop-2.md:56-57`,
  "a new member on a class at its method ceiling is refused — check `check-complexity-ratchets.js` METHOD_CEILINGS
  before choosing a home."
- Zero headroom everywhere makes every new member a gate failure. The four method ceilings are banked to the exact
  count after each change, so the first run of any shape that adds a member fails the build, and the session meets
  the old advice at that moment.
- The scroll-indicators plan and brief said both `CLAUDE.md` files sat at their byte ceilings one day after the
  prompt audit had left them 374 and 1147 bytes under. Item 1 above came from that stale sentence.

---

## 5. What I could not check, and what I scanned

**Scanned.**
- Transcripts: 147 `.jsonl` files, 558 MB: the 13 top-level sessions named in the task (fd5c9317 after
  2026-11-16T22:00, c3e1441a, 3aefc39e, f6c026f1, 0e4b5781, f17cfbf3, c465c3ed, f4c213ac, c42374a6, 1d0246d2,
  853080ec, 5fae7abf, 47698129) and their 134 subagent transcripts. A streaming scan over every assistant text,
  thinking block, tool input, tool result and user message found 2456 windows on 50 spellings (the task's list plus
  "method count", "complexity record", "ratchet raise", "ceiling raise", "offsetting", "contort", …); gate firings
  were matched by their real output lines, so a read of a gate's source did not count. I read every one of the 87
  gate-firing results by header, every assistant and thinking block that matched (about 190 after grouping), a
  second pass of 64 causal phrasings ("… ceiling, so …", "instead of raising …"), and the brief and prompt text
  that constrains ratchets.
- `c42374a6` and `1d0246d2` have NO content after the cutoff: their last timestamped lines are 2026-11-16T00:46 and
  2026-11-07T14:49; only session metadata was appended later. `47698129` is nine lines.
- Loop paperwork: `BRIEF.md` and `LEDGER.md` of all six loops, and the unit files a lead pointed into
  (`overnight-toolbar-residue/u3`, `editing-residue-followups-2/g1,g3`, `editing-residue-followups-3/h2,h3d,h4a`,
  `scroll-indicators-loop/u1b,u3,u4c`).
- Git: all 69 Fizzygum and 58 Fizzygum-tests commits since 2026-11-16 22:00 by message; every diff to the seven
  ratchet files and the baseline json; the `CLAUDE.md` diffs of both repos; the `Widget.coffee` hunks of the four
  units briefed "add NO method to Widget".
- Plans: `docs/archive/{scroll-indicators,editing-residue,toolbar-arc-residue,docked-and-floating-toolbars}-plan.md`
  for their ceiling and ratchet lines.

**Not checked, or checked only in part.**
- I did not read the 69 commits' diffs line by line. A contortion that no transcript, ledger, plan or commit message
  mentions (a helper quietly inlined with no word about the count) would not be found by this audit. The search for
  one structural signature of it, a new soft probe with an inline fallback, found row 23 and nothing else; the
  other new `?() ?` sites (`childrenCarriedByCopiesAndSaves`, `_clipThroughForChild`, `dockedPayloads`) have a
  receiver that may not be a widget or follow the base-calls-`@hook?()` rule.
- Thinking blocks in these transcripts are short summaries, so the reasoning between a gate firing and the next
  edit is often absent. Row 7's design (why one station and not two members) is INFERRED from the result, the
  ledger and the owner's recorded choice.
- The current session (`0a7dcd74`) and its subagents were not scanned: they are this audit and its siblings.
- Rows 9, 14 and 18 rest on the transcript plus a read of the resulting lines, not on a replay of the alternative.
  For row 19 I did not run the inspector to confirm the lost Cmd+Z; it is the review's finding, consistent with the
  code at `InspectorWdgt.coffee:600-603`.
- No build, suite or `fg` command was run. The only programs run were two read-only gates
  (`check-complexity-ratchets.js`, `check-stinks.js`) to read today's counts.
- The non-ratchet gates (part edges, unresolved sends, dead methods, layering, tier rules) are the sibling audit's
  subject; row 4 is the one such case I met and left there.
