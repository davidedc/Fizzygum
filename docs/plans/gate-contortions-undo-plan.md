# Gate contortions — the gates say what a finding means, and the shapes bent round them are undone

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
AUTHORED 2026-11-21 against Fizzygum master `b6b2f60f` and Fizzygum-tests master `e06b7c26a` (454 SystemTests, build
FRESH, last gauntlet 20/20). Line numbers drift: the member name and the quoted code are authoritative, so grep them
fresh before trusting a number.

**Mandate: elimination.** Every shape listed here that was chosen to quiet a gate is replaced by the shape its merits
ask for, and the gates are changed so that a firing gate stops recommending the quiet fix. Nothing is made easier to
live with and left standing. What this plan deliberately leaves is named in §7, with its reason, and filed.

## Status

| Unit | What | State |
|---|---|---|
| U1 | A firing ratchet says what its number holds back and when a raise is the answer | not started |
| U2 | Every other gate names its quiet fix as the wrong answer | not started |
| U3 | The words say what is true again | not started |
| U4 | Three spellings a gate's blind spot chose | not started |
| U5 | One answer on `Widget`, asked plainly | not started |
| U6 | Three checks get a witness of their own | not started |
| U7 | The world steps what is attached; a row with nothing to load says so | not started |
| U8 | The caret's margin includes the border | not started |
| U9 | A re-click keeps a member's undo history | not started |
| U10 | Six self-called helpers take their own tier | not started |
| U11 | `loadWorldSnapshot` is its phases | not started |
| U12 | `takeInventory` is its walks | not started |
| U13 | A type test says it is one, or the question names a capability | not started |
| U14 | A low-level method that sizes or drives another widget: [A] against [U] | not started |
| U15 | The list-row verb scrolls one way | not started |
| U16 | Two documents reach their clamp under a finger | not started |
| U17 | A menu row is found, not fetched | not started |
| U18 | A capture that does not verify is UNSTABLE | not started |
| U19 | Close | not started |

## 0. Orientation

**The project.** Fizzygum is a CoffeeScript GUI framework drawn on one canvas. Three sibling repos under
`/Users/davidedellacasa/code/Fizzygum-all`: `Fizzygum/` (source, the build and its static gates), `Fizzygum-tests/`
(the SystemTest suite, the harness, the headless rigs), `Fizzygum-builds/` (generated; never edited). Read
`Fizzygum-all/CLAUDE.md`, `Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` first. Every build runs about thirty
static gates (`Fizzygum/buildSystem/gates.js`; index `docs/architecture/lint-and-static-checks.md`); the suite's
runners fail on a list of runtime tokens (`Fizzygum-tests/scripts/lib/gate-tokens.js`); `fg gauntlet` runs twenty legs.

**What happened.** On 2026-11-16 the owner ruled: "if the right architectural shape needs a raise of the ratchet, go
ahead. Don't make the solution worse because of the ratchet." A first audit that day found six cases where a RATCHET (a
recorded count that may fall and may not rise) had bent a shape. On 2026-11-21 the owner asked for the rest: every
shape bent round ANY gate, and a statement of which gates are laws and which are budgets. Three read-only audits ran
that day (147 + ~570 transcript files, both repos' history, six loops' paperwork, the tree). Their reports are on this
machine, gitignored, under `Fizzygum-tests/.scratch/gate-contortions-audit/` (`INDEX.md`, `ratchet-audit.md`,
`static-gates-audit.md`, `runtime-gates-audit.md`, `gate-severity-classification.md`); each unit below carries what it
needs from them, and names the report section that holds the longer evidence.

**The critical reframe.** A gate finding does not mean one thing. It means one of three, and the answer differs:

| Class | A finding means | The acceptable answers | Never |
|---|---|---|---|
| **A. Invariant** | the product is wrong: a crash, a wrong pixel, a broken settle, a leak, a nondeterminism | fix the cause; if it cannot be fixed in scope, STOP and report | a raise, a new exemption, a flag that suppresses the check, a recapture that banks the wrong picture |
| **B. Convention at zero** | a house rule was broken; the code may still run correctly | comply honestly, or the gate's OWN sanction marker with a real reason | bending the design to avoid writing the sanction; a sanction with a boilerplate reason |
| **C. Budget** (a ratchet above zero) | something grew: look at it | classify the new occurrence; fix it if it is the smell, otherwise raise the number in the same change with a dated reason | inlining, folding, an odd home, an offsetting trade, wording by length: any shape chosen for the count |

Class A is every runtime token, every gauntlet leg and the soundness gates (syntax, shippable coverage, unresolved
sends, call arguments, part edges, `check-layering` [A][B][C][E][F][G][T], thin wraps, constructor build,
relayout-bounds-first, invalidation receivers, back-buffer memos, page-loaded elements, raw pointer reads,
plane-discipline A and C, the macro eval discipline, `check-refs`, the stinks `debugger-statement` and `nil-literal`,
undeclared fields). Class B is the conventions held at zero: call-separation [S] and [U]-effectful, `check-layering`
[D], dead methods, identical overrides, the tests half of hand lists, menu-action rule 3, the retired-mechanism gates,
whitespace, the comment-hygiene stinks at zero, doc narration, the macro discipline (`AIM MISSED`, `pointerKinds`).
Class C is the method ceilings (Widget 394, WorldWdgt 129, ActivePointerWdgt 74, FrameWdgt 167), cognitive complexity
(ceiling 15; 94 records, 16 to 129), the non-zero stinks (`instanceof-type-test` 64, `comment-narration` 80,
`null-literal` 6), `BASELINE_U_QUERY` 103, the prologue copies 8, the Fizzygum half of hand lists 4, the two CLAUDE.md
byte ceilings and the BACKLOG item length. Three class-C numbers carry a class-A question, so each new occurrence is
classified BEFORE any raise: the stinks `clock-read`, `timer` and `math-random` (does it reach render, layout or
input? then it is a determinism bug whatever the count) and plane-discipline B (cross-plane is a bug; same plane by
construction is a raise).

**A class-A gate has quiet fixes too** (an exemption entry, a suppression flag, a stub, a guard at the one leaf that
threw). Those hide a bug, which is worse than a class-C contortion. "Dead serious" means "fix the cause", never "go
quiet".

## 0.5 Cold-execution protocol

1. Read this plan whole, then `Fizzygum-tests/.scratch/gate-contortions-loop/BRIEF.md` (HOW the loop runs: the
   per-unit cycle, the pixel policy, parking, stopping, the grants). Where they disagree on process, the brief wins;
   where either disagrees with the code on a fact, the code wins: re-measure, then correct this plan in place.
2. Units run in the order of the status table. Each unit: precondition (two clean repos) → prepare (read-only; verify
   every fact below against the tree) → implement → the proof named in the unit → `fg presuite` → docs, plan and
   BACKLOG → an independent review → `fg gauntlet` → commit and push under the loop's grants → close.
3. A unit whose parts are marked INDEPENDENT may land without a part that fails: that part is parked alone (its
   paragraph says what was measured) and the rest goes on.
4. Verification commands are in §6. Nothing here is verified by reading alone.

## 1. Rulings (owner, 2026-11-16 and 2026-11-21; they bind every unit)

- **R1. The shape is chosen on its merits, before any count is read.** A plan, a brief or a session never states a
  ratchet as a constraint on a shape ("add no method to X", "find another seat", "net-zero").
- **R2. A class-C raise is authorised in the unit that needs it:** in the same change, with a dated reason beside the
  number in the house form (`raised 394 -> 395 on 2026-11-22 …: <the member and the one question it answers>`), named
  in the commit message and in the LEDGER. There is no cap per unit. A raise is never the first move: first ask
  whether the member is redundant or misplaced, and fix that if it is.
- **R3. A class-A finding is fixed at its cause, or the unit STOPS and reports.** No new exemption, allowlist entry,
  suppression flag or recapture answers one.
- **R4. A class-B finding is answered by complying, or by the gate's own marker with a reason a reviewer can check.**
- **R5. Recapture churn does not choose a design** (owner, standing). A unit that moves pixels predicts the set,
  looks at every diff, and recaptures under the brief's pixel policy.
- **R6. No backward compatibility is owed** to old snapshots, old references or old member names.
- **R7. Left out of this plan, by the owner's decision of 2026-11-21** (filed by U19, §7): the three product forks on
  "a test is playing" (the scroll glide, pressed moves, the edge auto-scroll's wall clock); the type-named predicates
  with many sites (`isFrame` and the layout-spec ones); the gauntlet's serial retry and the runners' retry-on-any-failure.

## 2. Current state (verified 2026-11-21; re-grep before trusting a line)

### 2.1 What the gates print today

- `buildSystem/check-complexity-ratchets.js:281` ends every failure with `A ratchet may fall and may not rise: split
  the function or the class rather than raising a number here.` Its header (lines 3–29) says a new function above the
  ceiling fails. Directly above, `METHOD_CEILINGS` (line 48) carries the dated reasons of the eight raises made since 2026-11-16,
  and `RECORDED` gained a new entry on 2026-11-19 (`9c5d1076`), so the mechanism already takes a raise and a new
  record: only the text forbids them.
- `buildSystem/check-call-separation.js:90`: `… mark the CALLER  # public-call-sanctioned: <why>); never raise the
  baseline to ship.`
- `buildSystem/check-stinks.js:316`: `Either fix the smell (preferred) or, if genuinely intentional, raise that
  stink's baseline … with a one-line reason.` It prints each stink's `why` (line 304).
- `check-plane-discipline.js` B states the legitimate raise outright; `census-widget-conformance.js` and
  `check-hand-lists.js` partly; `check-doc-narration.js` lets an instruction file's ceiling rise only for "a rule every
  reader must meet", not for a sentence that must grow to stay true.
- No gate prints its class, and none names its quiet fix as the wrong answer. The table of quiet fixes, gate by gate,
  is `docs/archive/backlog-open-items-detail.md`, heading "A firing gate says how to go quiet, never when the quiet fix
  is wrong" (17 rows).

### 2.2 What the loop paperwork said

The briefs of 2026-11-17 carried ruling R1. From the first overnight loop on, the paperwork (gitignored, under
`Fizzygum-tests/.scratch/`) drifted back: `overnight-toolbar-residue/BRIEF.md:154` "any other ratchet or ceiling
raise, or allowlist growth (needed ⇒ PARK)"; four implementation briefs "add NO method to Widget";
`scroll-indicators-loop/BRIEF.md:67–71` "a unit that finds it must is a PARK, not a raise" and "Not granted … growing
either `CLAUDE.md`"; the archived scroll-indicators plan has a section headed "Gate constraints that shape the
edits". U3's first item, U5's second and U3's layering-doc item all come from that one loop.

### 2.3 Gate against gate

- [U] (a public method only self-called must be `_`-tier) against [A]/[G]/[S] (a `_` method must not call a public
  setter / a settling wrapper / a public command): `buildSystem/public-api-allowlist.txt` lines 29–38 excuse eleven
  internal methods as public with the reason "forbids the _-form". [G] and [S] have a per-method marker
  (`# nosettle-sanctioned:`, `# public-call-sanctioned:`); [A] has none.
- The method ceiling against the complexity ceiling: `WorldWdgt#loadWorldSnapshot` stays at 67 because its split adds
  methods to a class at its ceiling (`9966b424`).

## 3. The distilled argument

The bent shapes are symptoms. Three causes produce them, and a loop that only undoes the shapes refills its own list
within a week (the 2026-11-16 ruling was followed for one day): the gates' own failure text recommends the quiet fix;
the briefs restate a narrower rule than the ruling; two gates contradict each other with no sanctioned way through.
So the order is fixed: U1 and U2 change what a firing gate says and where the policy is written; then the small undos
whose right shape is not in question (U3–U9); then the ones that need research inside existing rules (U10–U13); then
the ones that may need the owner (U14) or move many pixels (U15–U17); the capture tool last (U18), because it can
surface instability that would stall every recapture after it.

Why this time differs from 2026-11-16: that day's two BACKLOG items were filed and left; the ruling lived in a memory
note and in three briefs. Here the rule lands in the gates' output, in `lint-and-static-checks.md` and in
`Fizzygum/CLAUDE.md`, each proven by a self-test, so a session meets it at the moment a gate fires.

## 4. Units

Each unit names: what stands, why it is there (the evidence), the fix, the ratchets it moves, its proof, its predicted
pixel set, and when it parks. "Audit" names the report section under `Fizzygum-tests/.scratch/gate-contortions-audit/`.

### U1 — A firing ratchet says what its number holds back and when a raise is the answer

**Stands today.** §2.1. This is the ratchet half of BACKLOG item "A firing gate says how to go quiet, never when the
quiet fix is wrong" (section "Gate audit 2026-11-16"); its to-do list is in
`docs/archive/backlog-open-items-detail.md` and is the spec, with the corrections below.

**The fix.**
1. One shared advice module (suggested home `buildSystem/lib/gate-advice.js`; the name is yours) that every class-C
   rule prints beside its own line. For each ratchet it says: (a) what drift the number holds back; (b) the legitimate
   raises (the right shape needs it: a named helper, a public door, an intent-named notification, the natural home; a
   refactor one ratchet exists to drive crosses another; the gate's measurement widened; an instruction-file sentence
   must grow to stay true); (c) the forbidden answers (inlining a helper that deserves a name, folding two concepts
   into one, an odd home, an offsetting trade made for the count, a wording chosen by length, a true fact dropped);
   (d) how to raise (same change, dated reason beside the number in the trailing-comment form, named in the commit
   message). The ratchets: `check-complexity-ratchets.js` (all three rules), `check-stinks.js` (stinks whose baseline
   is above zero), `check-call-separation.js` (`BASELINE_U_QUERY`), `check-plane-discipline.js` B,
   `check-hand-lists.js` (Fizzygum half), `census-widget-conformance.js --gate` (prologue copies),
   `check-doc-narration.js` (`INSTRUCTION_FILE_OVER_CEILING`; `BACKLOG_ITEM_TOO_LONG` keeps its own right answer: the
   detail goes to the plan).
2. `clock-read`, `timer`, `math-random` and plane-discipline B print the class-A question first ("does it reach
   render, layout or input?" / "same plane by construction?") and the raise path only after it.
3. `check-complexity-ratchets.js`: the footer (line 281) and the header are rewritten to the policy. A function above
   15 may be RECORDED with a dated reason when it is born of a split that lowers a recorded parent, or when no real
   seam remains; the header says so. The rule ids do not change.
4. `check-call-separation.js:90`: [S] sits at zero with a per-site marker, so its text names the two honest answers
   (re-tier when the role is wrong; mark the caller with its reason) and the wrong one (re-tiering a member only so
   the line goes quiet). "never raise the baseline to ship" goes.
5. `docs/architecture/lint-and-static-checks.md` §3b gains the three classes of §0 as a subsection (what a finding
   means, the acceptable answers, the class of every gate and token in one table), and the sentence of R1: a plan, a
   brief or a session never states a ratchet as a constraint on a shape. Present tense; `check-doc-narration` passes.
6. `Fizzygum/CLAUDE.md` gains ONE rule in "Testing", pointing at §3b: a gate finding is answered by its class; an
   invariant is fixed at its cause; a budget may be raised with a dated reason; a shape is never bent to a count. This
   is a rule every reader must meet, so its byte ceiling rises by what the sentence needs, in the same commit
   (`check-doc-narration.js --write-baseline`).

**Ratchets.** `Fizzygum/CLAUDE.md`'s byte ceiling, for the rule. No other.
**Proof.** Each touched gate's `*-selftest.js` asserts that the advice is printed with each ratchet rule it fires
(the every-gate-bites way: `buildSystem/lib/prove-rules.js`), and the control prints none.
`node buildSystem/run-selftests.js` passes. A plant per gate is seen failing with its advice in the output.
**Predicted pixel set.** EMPTY (build tooling and docs).
**Park when.** A gate's self-test harness cannot assert printed text without a redesign of `prove-rules.js`: park
that gate's assertion alone, keep the text.

### U2 — Every other gate names its quiet fix as the wrong answer

**Stands today.** The second half of the same BACKLOG item: its 17-row table (gate → the quiet fix → the right
answer). Three rows are added by this plan's audits: `check-unresolved-sends` on a PLATFORM method ("respell the
code" is wrong; add the name to `BUILTINS`, keyed for a static like `Object.is`); `check-hand-lists` ("derive the
list from the rule the check judges" is wrong; assert the literal both ways and sanction it); a `KNOWN` / allowlist
entry of a rig for a row that throws (wrong unless the throw IS the row's behaviour; fix the row).

**The fix.** The same module of U1 carries one row per gate; each gate's failure output prints its row beside the
violation. The class-A gates' rows say "fix the cause"; the class-B rows name the marker and what a real reason looks
like. The runtime messages live in three places and each keeps its gate token at the start of the line
(`scripts/lib/gate-tokens-selftest.js` holds that): `WORLD_CONSTRUCTION_DRIFT`
(`Automator-and-test-harness-src/WorldTestSupport.coffee`), the macro `AIM MISSED` and the `pointerKinds` declaration
check (`AutomatorPlayer` / `MacroToolkit`), the revisit and settle gates (`Fizzygum-tests/scripts/revisit-gate.js`,
`notification-settle-audit/`).

**Ratchets.** None.
**Proof.** Each gate's self-test asserts its row is printed with each rule it fires. For the runtime messages, the
leg proofs (`*-selftest-headless.js`) already plant each rule: extend the judged line. Full `fg gauntlet` (its
`selftests` leg).
**Predicted pixel set.** EMPTY. A console line is not a pixel; if any test fails, it is a finding.
**Closes.** The BACKLOG item "A firing gate says how to go quiet…" moves to this plan's ledger here, and its detail
moves from `archive/backlog-open-items-detail.md` to this plan's `## BACKLOG ledger` section, verbatim.
**Park when.** A message is asserted verbatim by a test or a rig that cannot take the added text: park that message.

### U3 — The words say what is true again (parts INDEPENDENT)

1. **`Fizzygum-tests/CLAUDE.md`, the macro-tests paragraph (line 63).** Tests commit `34877ad9d` (2026-11-21) cut the
   paragraph until the file matched HEAD's size ("net-zero in bytes") while it sat 1148 bytes under its ceiling
   (65867 of 67015 today). Restore, from `git -C Fizzygum-tests show 34877ad9d -- CLAUDE.md`: the parenthesis "(there
   is no backend axis: the harness page IS the SWCanvas page)"; the determinism clause ("SWCanvas + the event queue
   are deterministic and" matching is on the raw-pixel hash, "not on anything else in the filename"); "a real
   disagreement about the pixels, not a staleness artifact" (today it reads "not a stale name", a different claim);
   the three token names `PAINT_ERROR` / `STEP_ERROR` / `INPUT_ERROR` in the `expectsCaughtErrors` sentence. The
   `expectsCaughtErrors` rule added by that commit stays. About +300 bytes: no raise.
2. **Three tests name `catchesPointerAt` again.** Tests commit `466109712` (2026-08-22) reworded "it declares
   catchesPointerAt over its whole box" to "it declares its whole box as its pointer surface" so a census would count
   the method; the census stopped reading prose on 2026-11-06 (`cd24c28d`). Sites:
   `SystemTest_macroHandleWdgtIsItselfResizable` and `SystemTest_macroHandleAttachedToNothing` (macro comments),
   `SystemTest_macroRoundedBoxCornerClickThrough` (`intent`). Name the method again. `visualisation.html` is generated.
3. **`docs/architecture/layering-naming-convention.md` §"shape 2" (about lines 124–133).** It defines shape 2 as the
   dispatcher round a counterparty's hook, "there is no self-core to name", then lists
   `Widget.coffee`'s `figure ?= @_settleLayoutsAfter => @_pickOutRotatedFigureNoSettle()` with a clause explaining why
   it still counts. The code is right (the unit's review counted 25 settles round a non-twin self core); the doc is
   bent. Give the doc a third named shape, "a settle round a non-twin self core", list that site under it, and put
   shape 2 back to its definition.
4. **Two stale pointers.** `src/WorldWdgt.coffee`, in `_showErrorsHappenedInRepaintingStepInPreviousCycle`:
   "createErrorConsole stays public ([A] forbids the _-form — see its public-api-allowlist entry)": no such entry
   exists; say what holds. `src/basic-widgets/ViewportWdgt.coffee`, `_showResizeAndMoveHandlesAndLayoutAdjustersNoSettle`
   carries a `layout-apply-sanctioned` reason copied onto a method [F] does not judge (audit: static §3): verify, then
   remove or correct it.

**Ratchets.** None. **Proof.** `check-doc-narration.js`, `fg build` (a `#` comment inside a method body is code),
the gauntlet. **Predicted pixel set.** EMPTY. **Audit.** ratchet §2 rows 27 and 29; static C8 and §3.

### U4 — Three spellings a gate's blind spot chose (parts INDEPENDENT)

1. **Platform calls respelled for `check-unresolved-sends`.** The gate fails a paren-call of a platform method
   missing from its in-file `BUILTINS`; four sessions rewrote the CODE instead (each quoted in audit static C9):
   - `src/duplication/Duplicator.coffee`, `_copyBuffer`: `Kind = original.constructor`, where the review had asked for
     `Object.getPrototypeOf(original).constructor` (a view carrying an own `constructor` property is copied by the
     wrong kind). This one changes behaviour.
   - `src/serialization/SerializationError.coffee` (about line 84): `if key is 0 and 1 / key < 0 then "-0"` for
     `Object.is(key, -0)`. `Serializer.coffee:76` writes the paren-less `Object.is n, value`: one call, two spellings.
   - `src/serialization/Deserializer.coffee` (about line 646): `/^data:image\//.test(record.data)` for `startsWith`.
   - `src/meta/Class.coffee` (about line 156): `.replace(/^\s+/, "")` for `.trimStart()` (`trimEnd` IS in `BUILTINS`,
     line 192).
   **Fix:** add `startsWith` and `trimStart` bare, `Object.is` and `Object.getPrototypeOf` keyed (the table's
   `Math.round` form), write the plain calls, restore the Duplicator hardening with a check that bites on it (a
   duplicated typed-array view carrying an own `constructor` property keeps its kind: the serialization rig's
   duplication section, or a value-only macro test).
2. **A class named as a string for `check-part-edges`, 11 sites** (verified): `src/demos/DemoMenus.coffee`
   417, 423, 429, 430, 436, 442, 448; `src/WorldWdgt.coffee` 3515, 3542; `src/basic-widgets/Widget.coffee` 4999, 5011,
   each `new (window["X"])`. The reason given at `Widget.coffee` (about 4977: "the correct guard for a lazy part does
   not exist -- so the gate's own sanctioned escape applies: name it as DATA") stopped being true on 2026-07-31, when
   the gate learned that an await is a guard (`510c1e74`): `src/dev-tools/WidgetFactory.coffee:127–128` writes
   `world.parts.whenAllLoaded ["demos"], ->` / `foo = new BouncerWdgt` and passes. **Fix:** the nine sites that sit
   lexically under their `whenAllLoaded` (DemoMenus ×7, WorldWdgt ×2) name the class bare. The two in `Widget`
   (`spawnInspector`, `createConsole`) build inside a closure defined above the await: move the construction under the
   `whenAllLoaded` line, or keep the name as data through boot's `classNamed "InspectorWdgt"` (the house rule since
   `d7e1bab3`: never `window[name]`). Rewrite the two comments, and the sentence in `check-part-edges.js`'s header that
   still calls the data spelling "the prescribed shape for a lazy part".
3. **`ShortcutWdgt.isDesktopShortcut`** (`src/ShortcutWdgt.coffee:93`): a type-named predicate with no caller in
   `src` or the harness (verified); nine lines in `Fizzygum-tests/scripts/graph-liveness-headless.js` and
   `serialization-roundtrip-headless.js` keep it alive, each `c.isDesktopShortcut && c.isDesktopShortcut() &&
   c.referencedWidget === doc`. **Fix:** the rigs ask `isShortcutTo(widget)` (one method above, which folds the
   referent check in); the one line that wants any shortcut reads `referencedWidget`; delete the method and its
   comment.

**Ratchets.** None expected (`check-dead-methods` re-reads part 3). **Proof.** `fg build`; `fg graph` and both
serialization rigs for part 3; `fg parts` and `fg menusweep` for part 2 (the doors still open their parts); part 1's
new check with a plant that restores `original.constructor`. **Predicted pixel set.** EMPTY for parts 1 and 2;
part 3 removes a `ShortcutWdgt` member: name the inspector-churn tests that show a shortcut's member list, if any.
**Audit.** static C3, C4, C9.

### U5 — One answer on `Widget`, asked plainly (parts INDEPENDENT)

1. **`isVisuallyTransformed` and `_isInsideNonIdentityIsland` are one method twice** (`src/basic-widgets/Widget.coffee`
   about 1759 and 1875, both `@_enclosingNonIdentityIsland()?`). The public one's comment: "the blessed public name
   for the private _isInsideNonIdentityIsland (macros cannot call `_`-prefixed members)". Product code calls the
   private one cross-object (`src/WorldWdgt.coffee:1820`, `bandHost._isInsideNonIdentityIsland()`); two tests call the
   public one. **Fix:** one name, the public one (it belongs to the public geometry vocabulary beside
   `rotationDegrees`, `scaleFactor`, `accumulatedScaleFactor`): `WorldWdgt` asks `isVisuallyTransformed()`, the
   private twin and the comment's last sentence go, the mention at `StackElementsSizeAdjustingWdgt.coffee:96` is
   reworded.
2. **`boxPresentedToOverlays` has its default written four times.** Defined only at
   `src/basic-widgets/ViewportWdgt.coffee:422`; read as `x.boxPresentedToOverlays?() ? x.clippedThroughBounds()` at
   `src/HighlighterWdgt.coffee:105`, `src/WorldWdgt.coffee:1798`, `src/dev-tools/PinoutsOverlay.coffee:57` and `:77`
   (verified). The preparation notes of the unit that wrote it: "`Widget` is at its ceiling, so the answer is a
   `ViewportWdgt` member read through a soft probe". A soft probe is the house form for a capability a class may
   lack; this is a box every widget has. **Fix:** `Widget.boxPresentedToOverlays: -> @clippedThroughBounds()` as the
   base answer, `ViewportWdgt`'s as the override, the four readers asking unconditionally, the comments saying so.

**Ratchets.** `Widget`'s method ceiling: −1 (part 1), +1 (part 2). Each change is recorded on its own merits with its
dated reason (R2); that they cancel is a coincidence and no reason for either.
**Proof.** `fg build`; the two tests of part 1; for part 2 the tests that show a highlight or a pinout over a
scrolled viewport (find them: grep the macros for `HighlighterWdgt`, `pinouts`, and the scroll-indicators plan's U3
tests). Pixel-neutral is a hypothesis until the suite says so.
**Predicted pixel set.** Inspector churn only: both parts change `Widget`'s member list. Name the churn-set tests at
Prepare (`scripts/inspector-churn-set.json`, `derive-inspector-churn-set.js`).
**Audit.** static C2; ratchet §2 row 23.

### U6 — Three checks get a witness of their own (parts INDEPENDENT)

The owner's rule from the dup-caret arc: a check must not ask the product's own rule for its expected value.

1. **The serialization rig's pane check.** `Fizzygum-tests/scripts/serialization-roundtrip-headless.js` about line
   1265: `const runtime = Array.from(Serializer.transientsForClass(FridgeMagnets3DCanvasWdgt)).filter((k) =>
   NativeValueKinds.rebuildsItself(pane[k]) && …)`. Until 2026-11-10 it was the literal
   `['transforms','meshCache','surface']`; the session: "The hand-lists gate rejects the rig's literal list … Deriving
   it instead". Now a field dropped from the transients shrinks the expectation instead of failing it. **Fix:** the
   literal list, asserted BOTH ways against what the pane declares (every listed name is a transient that rebuilds
   itself; every transient that rebuilds itself is listed), with `// hand-list-sanctioned:` naming this check
   (`paneRuntime.derivedInThePanesOwnFields`) as its guard. Prove it by a plant that drops one name from
   `@serializationTransients`.
2. **`SystemTest_macroThumbHighlightOnlyUnderAPointer`.** Its `thumbLook` reads `t._showsHover()`, which is
   `world.hand.restsOn(@) and not …` and `restsOn` reads `mouseOverList`; the assertions compare that with
   `world.hand.mouseOverList.has(thumb)`. Both sides read one field (since tests commit `225987eeb`). **Fix:** read the
   PAINTED thumb: a pixel probe of its fill on the bright-states fixture
   (`demoMenus.makeSlidersButtonsStatesBright`, as `SystemTest_macroSliderButtonStateColors` reads a knob's state off
   its pixels), compared with the hand's over-list. Prove it by a plant that makes `_showsHover` answer true always.
3. **`SystemTest_macroPointerCancelEndsNonFloatDrag` is mouse-only for one assertion of nine.** Its metadata declares
   `pointerKinds: ["mouse"]`; the one mouse-shaped line is the hover assertion ("and the pointer still rests on it, so
   it shows its HOVER look", about commands line 73). A cancel is above all a touch event, and the declaration leaves
   the non-float arm of `ActivePointerWdgt.processPointerCancel` with no finger coverage. **Fix:** `unless
   @fingerMode()` round that line with the finger's own expectation beside it (`"atRest"`), as
   `SystemTest_macroCollapsedBarGrip` does; reword image_1's claim per pointer; delete the declaration and its
   `mouseOnlyReason`; capture finger references (2 shots × 2 densities). If anything ELSE fails under a finger, that is
   a finding about the cancel path: park the part with the measurement.

**Ratchets.** None. **Proof.** Named per part; the new and changed tests' followers on both pointers
(`run-sequence-headless.js`), `fg serialization`. **Predicted pixel set.** No existing reference moves; part 3 adds
finger references for its own test; part 2 adds none (a pixel probe is a value). **Audit.** static C10; runtime S9, S3.

### U7 — The world steps what is attached; a row with nothing to load says so (parts INDEPENDENT)

1. **`src/demos/BouncerWdgt.coffee`, `step`:** `return unless @parent?`, added 2026-11-21 when the menu sweep
   detached a bouncer and its step threw `STEP_ERROR`. Its own comment names the cause: "a bouncer not attached yet,
   or taken off its holder, stays in the world's stepping set". The BACKLOG line (section "One line each" or nearby,
   grep "steps every registered stepper") files the cause. Every other `step` that reads its parent has the same hole
   and no guard. **Fix (research first):** the world steps only attached widgets, or a widget leaves
   `world.steppingWdgts` when it leaves the tree and rejoins when it returns: find where membership is written
   (`steppingWdgts`, `runChildrensStepFunction`), choose the seat that owns the fact, then delete the bouncer's guard.
   Prove it with a test that detaches a stepping widget and sees no `STEP_ERROR` and no step, and re-attaches it and
   sees it step; plant: the old membership. That BACKLOG line closes here.
2. **Two dev-menu rows throw when clicked cold.** `Fizzygum-tests/scripts/menu-click-sweep-headless.js`, `KNOWN`
   (about line 178): `'THREW:deserialiseFromMemoryAndAttachToWorld'` and `…AttachToHand`, reason "precondition, not
   wiring: nothing has been serialised yet, so JSON.parse("") fails". The rows (`src/demos/DemoMenus.coffee` about
   706–707) are offered before anything is serialised. **Fix:** in both members
   (`Automator-and-test-harness-src/WidgetTestSupport.coffee` about 95–101) answer with `world.inform "Nothing has been
   serialised to memory yet"` when there is nothing to load; delete the two `KNOWN` entries (`throwAnError` stays: the
   throw is that row's behaviour).

**Ratchets.** None expected. **Proof.** `fg menusweep` (a deleted entry that is still needed fails it; a stale one
fails as `STALE_ALLOWLIST_ENTRY`), the new test and its plant, `fg vmtruth` and the inventory tokens for part 1 (the
stepping set is a world collection). **Predicted pixel set.** EMPTY; a test that screenshots a detached-then-stepped
widget would be a finding. **Park when.** Part 1's research finds a product that RELIES on a detached widget stepping
(an animation that runs while its widget is off-tree): park with the list. **Audit.** runtime S11, S12.

### U8 — The caret's margin includes the border

**Stands today.** `src/basic-widgets/ViewportWdgt.coffee`, `scrollCaretIntoView`: `marginAroundCaret = @planeMargin +
(@extraPadding ? 0)` (about line 1421). A caret at the right edge of a padless scrolling viewport has its last column
under the 1 px border. The BACKLOG line (grep "last column under") files it; the references of
`SystemTest_macroEditingStringInScrollablePanelCaretAlwaysVisible` were recaptured with the defect in them on
2026-10-20, when a revisit-gate fix moved the caret there.
**The fix.** The margin includes the border the viewport paints over its edge (read it from where the viewport's
border width is declared; do not write a literal 1). Then recapture that test.
**Ratchets.** None. **Proof.** A value assertion in that test (or a sibling) that the caret's right edge is inside
the viewport's inner box at the right clamp; plant: the old margin.
**Predicted pixel set.** `SystemTest_macroEditingStringInScrollablePanelCaretAlwaysVisible`, both pointers, both
densities, plus any test whose caret sits at a bordered viewport's clamp: measure with the fix in and explain each.
That BACKLOG line closes here. **Audit.** runtime S10.

### U9 — A re-click keeps a member's undo history

**Stands today.** `src/meta-tools/InspectorWdgt.coffee`, `selectionFromList` (record 21 in
`check-complexity-ratchets.js`), about line 601: `cnts.forgetUndoHistory()` runs on every load, "the same member's
reload included". The unit that wrote it (`759d85b1`, 2026-11-20) had ruled "another subject starts a fresh history".
Its review: a re-click on the SAME member "loses the Cmd+Z that used to bring back the unsaved typing. A guard would
take the method to 22". The orchestrator: "I'm only correcting the comments here, not adding a guard, because a guard
would raise a complexity ratchet."
**The fix.** Move the member-to-text derivation (the `if / else if` chain that computes `txt`, about lines 565–597)
into a helper (`_shownTextOfMember selected` or the name research prefers); forget the history only when the selected
member CHANGED; restore the comment to the rule. The record falls: lower or delete it.
**Ratchets.** The complexity record of `InspectorWdgt#selectionFromList` falls. None rises.
**Proof.** A test step: select a member, type, re-click the same member (the pane reloads the saved source), Cmd+Z
brings the typing back; select another member, Cmd+Z brings nothing back. Plant: the unconditional forget.
**Predicted pixel set.** Inspector churn where a test's inspector inspects an inspector (a new `InspectorWdgt`
member): name them at Prepare; else EMPTY. **Audit.** ratchet §2 row 19.

### U10 — Six self-called helpers take their own tier

**Stands today.** `buildSystem/public-api-allowlist.txt` (verified) keeps public, with the reason "[S] / [G] forbid
the _-form": `autoScroll` and `startAutoScrolling` (`src/basic-widgets/ViewportWdgt.coffee` 1378, 1345),
`addHighlightingWidgets` (`src/WorldWdgt.coffee:1716`), `wrapContent` (`src/TransformFrameWdgt.coffee:199`),
`runAllSystemTestsAtSpeed` and `startTestPlayingWithSlideIntro`
(`Fizzygum-tests/Automator-and-test-harness-src/AutomatorPlayer.coffee` 727, 669). Each has only `@` self-calls. The
allowlist is for "deliberate end-user surface"; these are a drag step, a per-cycle reconciler, a constructor helper
and two harness steps, and each shows in an inspector's member list as API.
**The fix.** For each: rename to `_name`; put the rule's own per-method marker ON the method with the reason the
allowlist line gave (`# public-call-sanctioned: <why>` for [S], `# nosettle-sanctioned: <why>` for [G]); delete the
allowlist line. Find every caller, override and string mention in BOTH repos (`scrollX`/`scrollY` are allowlisted as
"siblings of macro-called verbs" while their only caller is `autoScroll`: re-judge those two lines in the same pass).
A member a macro or a rig calls by name is not self-only: leave it, and say so in the allowlist reason.
**Ratchets.** `BASELINE_U_QUERY` may fall: bank it. The markers are class-B exits, not raises.
**Proof.** `fg build` (call-separation and layering re-read every site); the suite.
**Predicted pixel set.** Inspector churn for the classes whose member lists a test shows (`ViewportWdgt` and its
subclasses, `WorldWdgt`, `TransformFrameWdgt`): name them at Prepare. **Audit.** static C1 (the [S] and [G] six).

### U11 — `loadWorldSnapshot` is its phases

**Stands today.** `src/WorldWdgt.coffee`, `loadWorldSnapshot` (line 2780, about 200 lines), recorded at 67. Its own
comments number its phases: the guards; `# 0.` what the file needs; `# 1.` teardown; `# 2.` id counters; `# 2b.`
class-edit replay; `# 3.` deserialize; `# 4.` preferences; `# 5.` world scalars and users; `# 6.` storage and app
windows; `# 7.` attach the children; `# 8.` colour and wallpaper; `# 9.` registry and repaint. The commit that left
it (`9966b424`): "its class sits at its method ceiling, and its locals cross a try/catch/finally".
**The fix.** The public method keeps what must stay in it: the four guards with their `early-return-sanctioned`
comment, step 0's re-entry with its `double-settle-sanctioned` comment, the two `_settleLayoutsAfter` calls, and the
`try / catch / finally` that guarantees a bin and a shelf. The phase bodies become private cores it calls in order.
A starting cut (research confirms or corrects it): `_restoreIdCountersAndClassEdits section` (2, 2b; returns the
restored registry and the two counts); `_sourceEditsNoticeFor unreplayedCount, stillEditedCount` (the notice text,
pure); `_applySnapshotWorldState section, resolve` (4, 5); `_installSnapshotStorageAndAppWindows section, resolve`
(6); `_attachSnapshotChildrenNoSettle section, resolve` (7). The order is the correctness argument (step 0 before any
mutation; the `finally`); three locals (`restoredRegistry`, `sourceEditsNotice`, `resolve`) are read after the `try`.
**Ratchets.** `WorldWdgt`'s method ceiling 129 → 129 + the cores added (five in the starting cut), dated, one reason
naming the split; the record 67 is lowered to the measured value or deleted. A plain `WorldSnapshotLoader`
collaborator would need no raise and is REJECTED (§7): the phases read and write the world's own fields.
**Proof.** Both serialization rigs (`fg serialization`), `world.teardownHygiene.*`, `fg vmtruth`, the production
smoke (`fg homepage`: the only gate that loads a snapshot on a production tree), the parts snapshot rig (`fg parts`).
A pure refactor: no behaviour test is added; one plant that swaps two phases must fail a rig.
**Predicted pixel set.** Inspector churn only where a churn-set test shows the WORLD's own member list; else EMPTY.
**Park when.** A phase cannot leave the `try` without changing what the `catch` restores. **Audit.** ratchet §1 (d).

### U12 — `takeInventory` is its walks (needs U1 CLOSED)

**Stands today.** `src/WorldInventory.coffee`, `takeInventory` (line 113), recorded at 129, the highest in the tree.
The cleanup loop that surveyed it: "Moved as one helper it would score 16 … would need a NEW record … So P3 stays."
U1 makes a split's child recordable; nothing else blocked it (`WorldInventory` has no method ceiling).
**The fix.** Research first: read the method and `docs/architecture/world-lifetime-and-inventory.md`, name its real
seams (the per-store walks, the classification, the report), and split along them. A child above 15 is recorded with
its dated reason; the parent's record falls or goes.
**Ratchets.** The record 129 falls; new records only for children above 15, each dated.
**Proof.** The object-lifetime tier end to end: `fg vmtruth`, the suite's `WORLD_INVENTORY_*` tokens, the two
self-tests that plant a leak (`heap-forensics-selftest-headless.js`, `vm-truth-gate-selftest-headless.js`, in
`fg selftests`), both serialization rigs. A pure refactor; a plant that drops one walk must fail the lifetime proofs.
**Predicted pixel set.** EMPTY.
**Park when.** No seam splits it without threading more than three values through each helper: park with the seam
map (a blind split is the quiet fix of the complexity ceiling). **Audit.** ratchet §1 (d), last paragraph.

### U13 — A type test says it is one, or the question names a capability (sites INDEPENDENT)

**The rule** (`docs/architecture/widget-authoring-guidelines.md` §14), in rank order: (1) the branch disappears, the
behaviour moves to the class that has it; (2) a query named for the CAPABILITY asked about, dispatched `?()`; (3) an
honest `instanceof` kept with its reason, and the `instanceof-type-test` stink raised by one with a dated reason (R2).
A type-named predicate (`isX: -> true` on class X) and an existence test on a member only one class has are type
tests in disguise: "only cosmetically better". Per site, take the FIRST rank that fits without inventing a mechanism.
"Any red test after such a swap is a faithfulness bug."

| Site | Stands today | Starting direction (research decides) |
|---|---|---|
| `Widget.coffee` about 1035 | `@firstChildSuchThat (m) -> m.updateVisibility?`, commented "exactly the old `m instanceof HandleWdgt`" | the TODO two lines above asks for handles to follow the parent's layout change: rank 1; else rank 3 |
| `Widget.coffee` about 2142 | `return undefined if !p?._materializedBySugar?`, "its presence is the island test" | a query on the island named for what is asked (transform plumbing round one figure); else rank 3 |
| `DividerWdgt.isDivider` (2 calls, both in `CommandPanelWdgt.removeConsecutiveLines`) | type-named | a row answers whether it merges with a like neighbour |
| `GlassBoxBottomWdgt.isGlassBoxWrapper` (1 call, `ToolPanelWdgt:85`) | type-named | "am I already wrapped" is asked of the child: name that |
| `GlassBoxTopWdgt.isGlassBoxLid` (1 call, `GlassBoxBottomWdgt:59`) | type-named; the wrapper searches its children by type | the wrapper holds its lid in a field |
| `LayoutChromeWdgt.isLayoutChrome` (1 call, `Widget:5219`) | type-named | the question is "do I offer the division-cell menu" |

**Ratchets.** `instanceof-type-test` (64) rises by one per rank-3 answer, each dated; `Widget`'s ceiling moves only
if a rank-1 or rank-2 answer adds or removes a `Widget` member.
**Proof.** Each conversion is faithful: the suite is green with no reference moved. One plant per site that inverts
the answer must fail a test that exists; a site no test reaches gets a value-only test first.
**Predicted pixel set.** Inspector churn for the classes that gain or lose a member; else EMPTY.
**Park when.** A site's rank-1 or rank-2 answer needs a mechanism the tree does not have: take rank 3 and say so.
**Out of scope (R7):** `isFrame`, `isLayoutAdderOrDroplet`, the five layout-spec predicates. **Audit.** static C6, C7,
C11.

### U14 — A low-level method that sizes or drives another widget: [A] against [U]

**Stands today.** Five allowlisted methods whose reason is "[A] forbids the _-form" (`buildSystem/public-api-allowlist.txt`):
`addText` (`ErrorsLogViewerWdgt`: drives the public `setText` of its text pane), `bringTextAndCaretToState`
(`CaretWdgt`: the public text setter and `gotoSlot`), `createWidgetToBeHandled` (the creator-button family, five
classes: public `addMany` / `setExtent`), `actOn` (the content-property tools: the subject's public setters),
`bringUpReferencedWidget` (`ShortcutWdgt`: public `show` / `spawnNextTo` / `setTitle` on other widgets). And
`src/basic-widgets/menu-system/InertIconHolderWdgt.coffee` (about line 48): `widgetToPicture.setExtent …` sits in the
CONSTRUCTOR, "because check-layering's rule [A] keeps it out of `_` methods", so sizing the subject lives apart from
`_takePictureOf`, and `OverflowChevronButtonWdgt.coffee` (about line 91) carries a `# nosettle-sanctioned` that has to
explain "The picture's constructor settles too". [A] is the one layering rule with no per-method marker ([F], [G],
[H], [T] and [S] each have one).
**The fix, in two steps.**
1. **Research (read-only), per method:** who calls it and when (event time, outside any pass? from inside a settle?);
   whether each public setter it drives has a `_…NoSettle` core the method could call instead, with its one caller
   settling (the canonical shape: `docs/architecture/layering-naming-convention.md`); whether a macro, a rig or the
   inspector calls it by name (then it IS public surface and its allowlist reason says that instead).
2. **Then:** where the canonical shape exists, take it (the method becomes `_name` or `_nameNoSettle`, the allowlist
   line goes). Where it does not (the callee is ANOTHER widget's public setter with no reachable core, or the widget
   driven is free-floating and the settle is the point), the unit does NOT invent a marker: it writes the options into
   this section (a per-method [A] marker with a required reason, in the form of [G]'s; or the member stays public with
   an allowlist reason that says what it is) with the evidence for each, and PARKS those members for the owner. A gate
   rule changes only by the owner.
**Ratchets.** None raised. **Proof.** `fg build`, the suite; for `InertIconHolderWdgt`, the toolbar overflow tests
(grep the macros for `OverflowChevron`). **Predicted pixel set.** Inspector churn for renamed members; the overflow
row's picture must not move (size, then shoot, in that order). **Audit.** static C1 (the [A] five), C5.

### U15 — The list-row verb scrolls one way

**Stands today.** `src/macros/MacroToolkit.coffee`, `bringInViewAndClickOnListItem_InputEvents_Macro` (about line
2476): a bar drag to a fraction, then `for attempt in [0..2]` one-pixel thumb nudges, then `for attempt in [0..2]`
wheel notches by content pixels (`wheelListTowardItem_InputEvents`). The wheel was added last (`fa5f3417`,
2026-11-17), "only once the nudges have failed, so every scroll the nudges already finish replays as it is". The wheel
delta is exact by construction (the delta that centres the row), so the drag and the nudges are redundant; they stay
so existing shots keep their offsets (R5 rules that out), and two bounded retry loops let a scroll that half-works end
green. Also `SystemTest_macroInspectorOpensAClassInItsClassInspector` (about commands lines 56–68): on 2026-11-12 an
`AIM MISSED` on a row below the visible list was answered by changing the example class to `PointerWdgt` so the rows
happen to show.
**The fix.** One mechanism: the wheel by content pixels, once, then the click (which already faults on a row it
cannot aim at). Delete the nudge loop and the fraction drag from this verb, and the nudge verb if nothing else calls
it (`scripts/aim-census.js` holds the verb tables both ways). Then the class-inspector test brings its rows into view
through the verb before each press, on the class its claim is about.
**Ratchets.** None. **Proof.** A plant that makes the wheel a no-op must fail every test of the family at the click
(no retry hides it). The followers of changed tests.
**Predicted pixel set.** The tests that call the family (17 by the audit's count: grep the verb in
`Fizzygum-tests/tests/*/*_automationCommands.js`), every shot taken after the verb, both pointers, both densities:
the list's resting offset differs. Each diff must be exactly that. This is the unit's own target, so the recapture is
under the pixel policy; the diff page stays for the owner.
**Park when.** A diff shows anything but the list's offset. **Audit.** runtime S5, S13.

### U16 — Two documents reach their clamp under a finger

**Stands today.** `SystemTest_macroSimpleDocumentAllReflowsCorrectlyAsIChangeFontSize` and
`SystemTest_macroSimpleTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent` declare
`pointerKinds: ["mouse"]`. Neither subject is a mouse mechanism (font-size reflow; the wrap toggle). Each wheels once
to OVER-scroll into a clamp (`@wheelOn_InputEvents doc, -2000`; `@wheelOn_InputEvents panel, 2000`) before
`assertScreenshotsIdentical`; under a finger the second end-scroll "lands 19 px short at 736" of the clamp at 755.
Both had finger references, deleted when the tests were declared (`15e723d7e`, 2026-08-27). A request to travel
2000 px into a clamp that ends short of it is not explained by "cannot re-aim": overshooting needs no aim. The
loader's own rule (`AutomatorLoader.coffee`, about 252): "a failure there is either a translation defect or a product
one, and gets looked at rather than listed".
**The fix.** (1) Find why the translated swipes stop short: the toolkit's finger translation of a wheel
(`_touchScrollBy` and its legs), or the product's drag-scroll after a re-wrap changed the range. Measure it in one
probe (the offset after each swipe leg, the range at each). (2) If it is the product, fix the product (class A). If
it is the translation, the verb that over-scrolls yields between swipes and stops when the pane reports its limit.
(3) Delete both declarations and their reasons; capture finger references.
**Ratchets.** None. **Proof.** Both tests green under a finger at dpr 1 and 2; the finger suite (`fg finger` in the
gauntlet); the probe's before/after numbers in the LEDGER.
**Predicted pixel set.** No mouse reference moves. New finger references for the two tests (13 shots × 2 densities by
the audit's count). If the fix changes the translation of EVERY finger wheel, every finger shot after a wheel may
move: measure, and if that set is not empty, each diff must be the clamp reached.
**Park when.** The cause is a product drag-scroll defect whose fix moves mouse references. **Audit.** runtime S2.

### U17 — A menu row is found, not fetched

**Stands today.** `src/macros/MacroToolkit.coffee`, `_menuRowScrolledIntoView` (line 1944): `viewport.setScrollY
viewport.getScrollY() + deltaY  if deltaY != 0` (and the X twin), returned as the last line of
`getTextMenuItemFromMenu` (1995), `rowOfMenuStandingFor` (2041) and `_promptButtonLabelled` (2076). A QUERY changes
the world with a programmatic setter and no input event. It came with the 44 px touch geometry (`5a45a135`,
2026-08-25), when menus first outgrew the 880 px test world. It has kept a test green for the wrong reason at least
once (memory `spreadsheet-ux-brainstorm.md`: "a toolkit verb that RESCUES a step can keep a test green for a reason
other than its claim").
**The fix.** MEASURE FIRST: a `--prelude` plant that makes `_menuRowScrolledIntoView` throw when either delta is
non-zero, over the suite on both pointers at dpr 1 (the failing set is the set that leans on the rescue; record it).
Then: the locators answer the row and touch nothing; a press aimed at a row the viewport clips is a fault that names
the row and how far out of view it is; a verb brings a row into view through the input queue (a wheel over the rows;
a finger run translates it), and each test of the measured set says so before its press.
**Ratchets.** None.
**Proof.** The plant's set equals the set of tests edited. A new value-only test: a row past the fold is not pressed
without the scroll verb (the fault fires), and is pressed with it.
**Predicted pixel set.** The shots of the measured set taken with such a menu open and scrolled (a wheel lands on its
own offsets). Each diff must be the menu's scroll offset.
**Park when.** The measured set exceeds 30 tests (the unit does not fit its box: park with the set, for the owner to
schedule), or a test of the set fails for a reason other than the missing scroll. **Audit.** runtime S1.

### U18 — A capture that does not verify is UNSTABLE

**Stands today.** `Fizzygum-tests/scripts/capture-macro-test-references.js` (about lines 232–290): `const MAX_RETRIES
= doClean ? 2 : 0`; a verify that does not re-match the reference just captured is cleaned, captured and verified
again, and a later pass ends "captured + verified", exit 0 ("previous capture unstable/incomplete — likely
pre-settle"). The same header says capture is byte-identical run to run and "a verify FAIL is a real disagreement
about the pixels". A reference that does not match the next run of its own test is a nondeterminism finding (the
lesson of 2026-10-31: "'NEEDS RECAPTURE' right after a capture is a finding", a real z-order bug at 1 in 25); the
retry keeps whichever rendering happens to verify.
**The fix.** A verify mismatch is its own outcome: UNSTABLE, non-zero exit, naming the shot and both hashes, retrying
nothing. A retry stays only for a run that measured nothing (the runner's exit 2, which the script already tells
apart). `recapture.js` (about line 250) takes the same split where it retries a capture. Docs: the script headers,
`scripts/README-swcanvas-tests.md`.
**Ratchets.** None. **Proof.** The script's self-test (or a new one, found by name) on canned runner transcripts: a
mismatch reads UNSTABLE and exits non-zero; a measured-nothing run is retried; a clean run is exit 0.
**Predicted pixel set.** EMPTY. It may surface tests that are unstable today, which is its purpose: each is FILED
with its two hashes (`DETERMINISM.md` has the playbook), never recaptured until stable.
**Left out (R7):** `lib/shards.js`'s retry and the gauntlet's serial retry. **Audit.** runtime S4.

### U19 — Close

1. File, in `docs/BACKLOG.md` under this plan's heading (one line each, at most 325 characters, each naming the audit
   section as its detail, which U19 copies into this plan's `## BACKLOG detail`): the three product forks on "a test
   is playing" (`ViewportWdgt` `glideSuppressed = aTestIsPlaying()`; `ActivePointerWdgt` `pressedMovesAreEventOnly`;
   the edge auto-scroll's `Date.now()` and its test's 20 s poll); `isFrame`, `isLayoutAdderOrDroplet` and the five
   layout-spec predicates; the gauntlet's serial retry and the runners' retry-on-any-failure
   (`lib/shards.js`, `recapture.js`); `_stopEditingNoSettle` inside a declaration window (`WorldWdgt.coffee` about
   1969); the 13 doubled waits; `ClippingWdgt._applyMoveBy` skipping `_assertBoundsWellFormed` (a hole in
   `NON_INTEGER_GEOMETRY`, medium); four soaked sends with no implementor (`radioButtonWasSwitched?`,
   `drawAdditionalPartsOnBaseShape?`, `processKeyUp?`, `dataflowApply?`); the dropped `disabledInkForMyParts` helper;
   the static audit's "unsure" list (`FooterBandLayout._arrange`, the toolbar tools' string-dispatched verb, the caret's
   delete chords, `NativeValueKinds.rebuildsItself`); anything a unit parked.
2. Close the BACKLOG item "No audit has looked for shapes chosen only to quiet a non-ratchet gate" (the three audits
   of 2026-11-21 are it): its line moves to this plan's ledger, its detail from
   `archive/backlog-open-items-detail.md` to this plan's `## BACKLOG ledger`.
3. `git mv` this plan to `docs/archive/`, stamp it COMPLETE with the heads, add its `archive/INDEX.md` line, retarget
   its BACKLOG heading. Copy the five audit reports into `docs/archive/gate-contortions-audit-2026-11-21/` so the
   evidence is in the repo (they are prose and tables; `check-doc-narration` does not read `archive/`).
4. Memory: `gate-contortions-audit-2026-11-21.md` and its `MEMORY.md` line, in place.
5. The final digest in the LEDGER.

## 5. Central risks

- **A fix shaped by a count, again.** The reflex this plan exists to end can run inside it. A research or
  implementation brief written for a unit never mentions a ceiling as a limit; the review of every unit asks "was any
  shape here chosen for a number?" as its first question.
- **"Pixel-neutral" is a hypothesis.** U5, U10, U11 and U13 predict inspector churn only. The suite decides.
- **Inspector churn repeats.** U5, U9, U10, U11 and U13 each move member lists; each is its own recapture under the
  pixel policy. That is expected cost, not a reason to batch unrelated units into one commit.
- **U18 can stall later captures.** It is last for that reason.
- **U14 touches a class-A gate's reach.** It never adds a marker by itself.
- **The talk.** The owner speaks on 2026-11-25 from this tree. The loop prompt states whether units may start; U15 to
  U17 move the most pixels and are last so they can be cut.

## 6. Verification protocol

- Inner loop: `/Users/davidedellacasa/code/Fizzygum-all/fg build` (every static gate), then
  `/Users/davidedellacasa/code/Fizzygum-all/fg presuite`. A unit that changes input or pixels also runs the finger
  suite at dpr 1 (`node scripts/run-all-headless.js --pointer=finger`, from `Fizzygum-tests/`, in the background).
- Commit point: `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet`, in the background with a log; never piped.
- Docs: `node /Users/davidedellacasa/code/Fizzygum-all/Fizzygum/buildSystem/check-doc-narration.js`.
- Self-tests alone: `node /Users/davidedellacasa/code/Fizzygum-all/Fizzygum/buildSystem/run-selftests.js`.
- A single test: `node scripts/run-macro-test-headless.js SystemTest_<name> [--dpr=2] [--pointer=finger]`; a
  follower: `node scripts/run-sequence-headless.js SystemTest_<new> SystemTest_macroAnalogClockInspectEdit`.
- A plant: `--prelude=/abs/plant.js` on any runner or rig; read the failure LINES, not the exit code.

## 7. Rejected alternatives (do not re-attempt)

- **Loosen or delete the ratchets.** They still flag real growth (three method ceilings fell and seven complexity
  records went in five days). The number is a signal; what changes is the answer to it.
- **Leave slack in each number** so a first member passes. A ratchet with slack stops reporting; the raise with its
  dated reason is the record the owner reads.
- **A `WorldSnapshotLoader` collaborator for U11**, to avoid raising `WorldWdgt`'s ceiling: it would exist to dodge
  the count; the phases read and write the world's own fields.
- **A new [A] marker decided inside U14.** A gate rule changes only by the owner.
- **Recapture-inspector for the churn.** Each unit recaptures its predicted set through `fg recapture --auto`.
- **The product forks on "a test is playing" in this loop.** Each is an event-time redesign with a recapture of every
  shot after a drag-scroll; the owner left them out (R7).
- **Batching every `Widget` member change into one commit** to pay the inspector churn once: it couples unrelated
  undos, and a count would again be choosing the shape of the work.

## 8. References

- The owner's rule and the first audit: `docs/archive/backlog-open-items-detail.md` (two headings, "A firing gate…"
  and "No audit has looked…"); memory `ratchets-must-not-dictate-design.md`.
- The audits of 2026-11-21: `Fizzygum-tests/.scratch/gate-contortions-audit/` (five files; `INDEX.md` first); memory
  `gate-contortions-audit-2026-11-21.md`.
- Policy and markers: `docs/architecture/lint-and-static-checks.md` §3b, §5; `docs/architecture/layering-naming-convention.md`;
  `docs/architecture/widget-authoring-guidelines.md` §14, §16.
- Determinism and the reference rules: `Fizzygum-tests/DETERMINISM.md`; `Fizzygum-tests/CLAUDE.md`.
- The loop: `Fizzygum-tests/.scratch/gate-contortions-loop/BRIEF.md` and `LEDGER.md`.

## Start prompt for a fresh session

See `Fizzygum-tests/.scratch/gate-contortions-loop/BRIEF.md`, "The loop prompt".

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

(empty until a unit closes an item)

## BACKLOG detail (open items, moved from docs/BACKLOG.md)

(empty until a unit files an item)
