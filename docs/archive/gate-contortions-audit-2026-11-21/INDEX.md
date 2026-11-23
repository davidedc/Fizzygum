# Gate contortions — the consolidated investigation (2026-11-21)

Read against Fizzygum `b6b2f60f` / Fizzygum-tests `e06b7c26a`. Nothing was edited, built or run. Four reports sit
beside this file; this one is the index a loop plan starts from.

| Report | Covers |
|---|---|
| `gate-severity-classification.md` | every build gate, runtime token and gauntlet leg sorted into invariant / convention at zero / budget |
| `ratchet-audit.md` | the six cases of the 2026-11-16 audit as they stand today + everything since (147 transcripts, six loops' paperwork, both repos' history) |
| `static-gates-audit.md` | quiet fixes of the build gates (never audited before) + the sanction and allowlist census |
| `runtime-gates-audit.md` | quiet fixes of the runtime tokens, the gauntlet legs and the macro-test discipline |

The earlier investigation: `Fizzygum/docs/archive/backlog-open-items-detail.md` lines 9–124 (BACKLOG § "Gate audit
2026-11-16", both items still open).

Ids: R = ratchet audit, C = static-gates audit (its own C1–C11), S = runtime audit (its own S1–S13). "Checked" = the
orchestrator read the cited lines itself after the worker reported.

## A. Loop-ready: small, the right shape is not in question

| Id | Where | What stands | The undo | Ratchet / pixels |
|---|---|---|---|---|
| R1 | `Fizzygum-tests/CLAUDE.md:63` (`34877ad9d`) | four facts cut to stay "net-zero in bytes" with 1148 B of headroom (checked: 65867 / 67015) | restore them | none |
| R3 | `boxPresentedToOverlays`, `ViewportWdgt.coffee:422` + 4 readers spelling `?() ? x.clippedThroughBounds()` (checked) | a soft probe because "`Widget` is at its ceiling" | a base default on `Widget` | Widget 394 → 395; inspector churn likely |
| C2 | `Widget.coffee:1759` / `:1875` (checked: same body) | a public twin that exists "because macros cannot call `_` members" | one name | Widget −1 |
| C3 | `ShortcutWdgt.coffee:93` `isDesktopShortcut` (checked: rigs only) | a type-named predicate no product code calls | rigs ask `isShortcutTo`; delete | none |
| C4 | `new (window["X"])`, 11 sites | a spelling that hides the name from part-edges | the bare name under its await, or `classNamed` | none |
| C8 | three tests' prose (tests `466109712`) | stopped naming `catchesPointerAt` to quiet [U] | name it again | none |
| C9 | `Duplicator.coffee:155`, `SerializationError.coffee:84`, `Deserializer.coffee:646`, `Class.coffee:156` | platform calls respelled to quiet unresolved-sends | add the four names to `BUILTINS`, write the plain call | none; the Duplicator one restores a hardening |
| C10 | `scripts/serialization-roundtrip-headless.js:1265` | the rig's expected list is read from the rule it judges | the literal list, asserted both ways, sanctioned | none |
| S3 | `SystemTest_macroPointerCancelEndsNonFloatDrag.js:13` (checked) | mouse-only for one hover assertion of nine | `unless @fingerMode()` round that line | finger refs captured |
| S9 | `SystemTest_macroThumbHighlightOnlyUnderAPointer` | compares a field with a method that reads that field | read the painted thumb | none |
| S11 | `BouncerWdgt.coffee:23` (checked) | `return unless @parent?` to quiet the menu sweep | the world steps only attached widgets (BACKLOG:227) | none expected |
| S12 | `menu-click-sweep-headless.js:181` (checked) | two `KNOWN` entries for rows that throw clicked cold | the rows `inform`; delete the entries | none |
| S13 | `SystemTest_macroInspectorOpensAClassInItsClassInspector` | the example class swapped so its row shows | bring the row into view before the press | maybe 1 shot |
| S10 | `CaretWdgt.coffee:468` + BACKLOG:163 | the caret's last column sits under the border; the test was recaptured | the border joins `scrollCaretIntoView`'s margin | 1 test recaptured |

## B. Medium: the shape needs research inside rules that already exist

| Id | Where | What stands | The undo |
|---|---|---|---|
| R2 | `InspectorWdgt.coffee:601` (checked) | re-clicking a member forgets its undo history; a comment was reworded to call that the rule, because the guard needed a complexity raise | split the member-to-text derivation, add the guard (the record FALLS) |
| R4 | `WorldWdgt.loadWorldSnapshot`, complexity 67 | unsplit since `9966b424`: a split adds methods to a class at its ceiling | five phase cores; WorldWdgt 129 → 134; both serialization rigs prove it |
| C1 | `public-api-allowlist.txt:27–37` (checked) | 11 internal methods kept public because "[A]/[G]/[S] forbids the _-form" — one gate vetoing another | six take `_name` + the existing marker; five need NoSettle cores or a new [A] marker |
| C5 | `InertIconHolderWdgt.coffee:48` (checked) | a `setExtent` sits in the constructor "because rule [A] keeps it out of `_` methods" | the caller sizes the copy, or the [A] marker of C1 |
| C6, C7, C11 | `Widget.coffee:1035`, `:2142`; `isDivider`, `isGlassBoxWrapper`, `isGlassBoxLid`, `isLayoutChrome` | soaks and type-named predicates standing for `instanceof` | move the behaviour, name the capability, or an honest type test with a stink raise |
| S4 | `capture-macro-test-references.js:247` (checked) | a verify mismatch is recaptured up to twice, then reported verified | a mismatch is UNSTABLE, non-zero exit |
| S5 | `MacroToolkit.coffee:2476` | drag, then nudges, then wheel: three mechanisms kept to avoid a recapture | one wheel-by-content-pixels mechanism; inspector tests recaptured |
| S2 | two SimpleDocument / SimpleText tests | declared mouse-only after a finger capture landed 19 px short | find the undershoot; a clamp-landing verb; finger refs |
| S1 | `MacroToolkit.coffee:1944` | row locators scroll an over-tall pop-up outside the input queue | locators stay pure; an explicit scroll verb. Plant a throw first to count dependants |

## C. An owner ruling comes first

- **Product forks on "a test is playing"** (checked): S7 the scroll glide is suppressed (`ViewportWdgt.coffee:1311`), S8
  pressed moves are event-only (`ActivePointerWdgt.coffee:1974`), S6 edge auto-scroll runs on `Date.now()` and its test
  polls up to 20 s. Each is the product behaving differently under test; each undo is an event-time redesign with a
  recapture.
- **The type-named predicates with many sites:** `isFrame` (19), `isLayoutAdderOrDroplet`, the five layout-spec ones.
- **The runtime audit's "doubtful" list:** `_stopEditingNoSettle` inside a declaration window; 13 doubled waits (12
  written on 11-21); the gauntlet's serial retry turning an in-wave failure into `OK(warn)` (four such were real bugs);
  retries on any failure in `lib/shards.js:61` and `recapture.js:250`.
- **Borderline ratchet shapes:** U4c's inline settle thunk (`Widget.coffee:2276`, the doc was widened to hold it), the
  dropped `disabledInkForMyParts` helper, the `noteEditModeChanged` inline at 4 sites.
- **Static-audit "unsure" list:** `FooterBandLayout._arrange` renamed where its sibling took the marker; the toolbar
  tools' string-dispatched verb; `CaretWdgt.coffee:765` delete chords; `NativeValueKinds.rebuildsItself`.

## D. What keeps producing them (fix this first, or the loop refills the list)

1. `check-complexity-ratchets.js:281` prints "split … rather than raising a number here"; `check-call-separation.js:90`
   prints "never raise the baseline to ship". No gate prints its class or names its quiet fix as the wrong answer
   (BACKLOG item 1 of the 11-16 audit, open).
2. A split's child cannot be recorded, so `takeInventory` (129) and every partial split stay blocked.
3. The loop paperwork drifted back after the 11-17 arc: "needed ⇒ PARK", "add NO method to Widget" (four briefs), "a
   unit that finds it must is a PARK, not a raise", "find another seat", a plan heading "Gate constraints that shape
   the edits". R1, R3 and U4c's thunk all come from the one loop that carried those lines.
4. Gate against gate: [U] wants a member private, [A]/[G]/[S] forbid the `_` form (C1, C5); the method ceiling forbids
   the split the complexity ceiling asks for (R4).

## E. Gate gaps found on the way (not contortions)

- `ClippingWdgt._applyMoveBy` (`:257–261`) skips `_assertBoundsWellFormed`: `NON_INTEGER_GEOMETRY` cannot see a move of
  any clipping class. In no BACKLOG line.
- Four soaked sends have no implementor (`radioButtonWasSwitched?`, `drawAdditionalPartsOnBaseShape?`, `processKeyUp?`,
  `dataflowApply?`): a soak is invisible to unresolved-sends.
- The teardown-seat storage audit runs after the bin and shelf are destroyed, so two of its scans are inert there.
- Stale pointers: `WorldWdgt.coffee:2287` names an allowlist entry that is gone; `ViewportWdgt.coffee:753` carries a
  copied sanction reason on a method [F] does not judge.

## What the audits could not see

- Nothing was run: every "how many tests rely on it" and every pixel prediction is unmeasured.
- Transcripts begin about 2026-10-15 and were read through regex windows; a quiet fix never put into words is invisible.
- About 115 of 142 sanction/allowlist commit bodies and about 80 recapture commits were judged by message only.
