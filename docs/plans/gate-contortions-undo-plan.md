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
| U1 | A firing ratchet says what its number holds back and when a raise is the answer | CLOSED 2026-11-22 (§U1) |
| U2 | Every other gate names its quiet fix as the wrong answer | CLOSED 2026-11-22 (§U2) |
| U3 | The words say what is true again | CLOSED 2026-11-22 (§U3) |
| U4 | Three spellings a gate's blind spot chose | CLOSED 2026-11-22 (§U4) |
| U5 | One answer on `Widget`, asked plainly | CLOSED 2026-11-22 (§U5) |
| U6 | Three checks get a witness of their own | CLOSED 2026-11-22 (§U6) |
| U7 | The world steps what is attached; a row with nothing to load says so | CLOSED 2026-11-22 (§U7) |
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
  and `RECORDED` gained a new entry on 2026-11-19 (`9c5d1076`; deleted the next day, `0cfa93dd`, when its core fell
  to 11) and a raise (`Serializer._buildObjectTable` 106 → 109), so the mechanism already takes a raise and a new
  record: the header and the `RECORDED` comment are false, not only forbidding. (Corrected at U1's research: also
  `census-widget-conformance.js`'s footer invites raising its class-A undeclared-field ZERO and its header calls both
  baselines floors; `check-stinks.js:316` prints for zero stinks too; `gates.js` and `lint-and-static-checks.md`'s §3
  row restate the old policy; `BASELINE_U_QUERY` measured 102 under its 103.)
- `buildSystem/check-call-separation.js:90`: `… mark the CALLER  # public-call-sanctioned: <why>); never raise the
  baseline to ship.`
- `buildSystem/check-stinks.js:316`: `Either fix the smell (preferred) or, if genuinely intentional, raise that
  stink's baseline … with a one-line reason.` It prints each stink's `why` (line 304).
- `check-plane-discipline.js` B states the legitimate raise outright; `census-widget-conformance.js` and
  `check-hand-lists.js` partly; `check-doc-narration.js` lets an instruction file's ceiling rise only for "a rule every
  reader must meet", not for a sentence that must grow to stay true.
- No gate prints its class, and none names its quiet fix as the wrong answer. The table of quiet fixes, gate by gate,
  is this plan's `## BACKLOG ledger` (moved there from `docs/archive/backlog-open-items-detail.md`), heading "A firing gate says how to go quiet, never when the quiet fix
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

**Landed 2026-11-22.** One module, `buildSystem/lib/gate-advice.js`: `ROWS[<gate>][<rule id>]` holds each budget
rule's own advice (what its number holds back, or first the invariant's question; the legitimate raise; the wrong
answers) and `CLASSES.C` the text every budget shares (when a raise is right, the forbidden answers, how to raise).
`adviceLines(gate, ids)` prints one `[<gate>] ADVICE <ID> — …` header per fired rule, however many lines it fired on,
then the class text once, on lines of their own after the gate's report. The GATE chooses the ids, because the class
is sometimes a property of the moment: a stink is a budget only while its baseline is above zero, and
`check-hand-lists`' one `OVER_BASELINE` is a budget in the Fizzygum half and a convention in the tests half. The seven
gates print it (`check-complexity-ratchets` all three rules, `check-stinks` the six stinks above zero,
`check-call-separation` [U] query, `check-plane-discipline` B's rise, `check-hand-lists` the Fizzygum half,
`census-widget-conformance` the prologue copies, `check-doc-narration` the instruction-file ceiling); their footers and
headers state the policy (the complexity header and the `RECORDED` comment were false, not only forbidding: a record
had been raised and one added; the conformance footer invited raising the class-A undeclared-field zero and its header
called both baselines floors; the stinks footer invited raising a hard rule). `lib/prove-rules.js` holds each run,
the control included, to printing the advice of exactly the rules its `advised` names (`lib/planted-src.js` parses it),
so each self-test proves its budget rules advise and every other rule and the control do not; `prove-rules-selftest.js`
proves that check bites both ways, and `lib/gate-advice-selftest.js` proves the module (a row naming a rule its gate
no longer has fails). `lint-and-static-checks.md` §3b gained "What a finding MEANS" (the three classes, the raise
policy, the four budgets that ask an invariant's question first, the R1 sentence, the class of every gate, rule and
token); `Fizzygum/CLAUDE.md` gained the one rule. Ruled here: a stink that keeps a `sanctioned` list (`null-literal`,
`clock-read`, `instanceof-type-test`) names a site that is not the smell THERE, with its why, and its bare baseline
rises only for one more of the tolerated tail, so U13's rank-3 answer for an honest `instanceof` is a `sanctioned`
entry; classes the §0 table left unstated are in the §3b table (`check-relayout-repaints` and `aim-census
--tables-only` B; the runtime `STALE_ALLOWLIST_ENTRY` stays A with every token). Ratchets: `BASELINE_U_QUERY` 103 → 102
(a gain already landed, banked as the gate's own NOTE line asks); no raise — the CLAUDE.md rule fits under its ceiling
(35364 of 35421), so `check-doc-narration-baseline.json` is untouched.

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

**Landed 2026-11-22.** Every static gate whose finding has a tempting quiet fix, and six legs, print, when they fire, a
row of `buildSystem/lib/gate-advice.js` naming that fix as wrong, why, and the right answer; where its rule keeps a marker,
what the marker answers and what its reason names. `CLASSES.A` (fix the cause, or stop and report; never, for a real finding, a new exemption,
a suppression flag, a stub, a leaf guard, a recapture) and `CLASSES.B` (comply, or the gate's own marker with a reason
a reviewer can check) join U1's `CLASSES.C`. One row may serve several rules of its gate whose findings share an answer
(printed once, its header naming the rules that fired); an id may carry the case it fired in (`OVER_BASELINE.at-zero`
gives `check-hand-lists`' tests half its convention row with no rule change); a `*` row serves every id no named row
covers, so the suite runner's row for its gate tokens reads `lib/gate-tokens.js` rather than a second copy of the list.
32 static gates print rows (the 29 of `buildSystem/` and `check-macro-source-discipline`, `check-refs`, `aim-census`);
`check-layering`'s always-printed legend became the rows of the rules that fired; the zero stinks' rows replace
their HARD-rule line; `check-part-edges` names the await its scanner reads
(`world.parts.whenAllLoaded [...], ->`, the class bare under it) where it suggested `ensureLoaded(...).then`, which the
scanner does not read as a guard. Six legs print rows: `revisit-gate` (a NEW signature is fixed at its cause; a
baseline entry records an owner's decision about a design, never the answer to a finding — its header and
`layout.md` say so), `settle-gate`, `menu-click-sweep-headless` (THREW, PROMPT_OK_THREW, CONSOLE_ERROR,
SUBMENU_FLAG_MISMATCH), `pin-sweep-headless` (a pin with no setter or getter), `staleness-census` (a mover) and
`run-all-headless` (`SCREENSHOT_MISMATCH`: a recapture never banks a defect; `AMBIGUOUS_REFERENCES`,
`MACRO_INCOMPLETE`, `ASSERTION_FAILED`; the declarable catches; every other failing console line), after the RESULT block and in no line shape the block reserves. The four page findings carry
their row in their own message, on the first line the runners report, naming no other token:
`WORLD_CONSTRUCTION_DRIFT` (an exemption only for a value no render, layout or input reads), the `WORLD_INVENTORY_*`
hints (a page-lifetime entry only for a store page-lifetime by design), `AIM MISSED` and the `pointerKinds` throw.
Every touched proof lists `advised` per run; `scripts/lib/suite-gate-proof.js` plants the three page rows for REAL
(a field drifted onto `WorldWdgt.prototype` around one reset's construction audit; a class-level store grown across
one reset; a `verifyPressLanding` miss while a test plays; a test's metadata rewritten to `pointerKinds: ["mouse"]`
with no reason), each judged by its row's text; `lib/gate-advice-selftest.js` holds each stink's row class to its
baseline (class C exactly when it is above zero).
Corrected at research: of the three page messages the plan named, only `WORLD_CONSTRUCTION_DRIFT` is a tokened
`console.error` (`AIM MISSED` is an assertion line, the `pointerKinds` check a throw), and no proof ran any of the three real paths; the table's dead-methods,
identical-override and settle-gate rows were wrong about their gates (corrected rows in the module). Ruled here: an
inspector's own-member rows are no reader of ownership (`census-hierarchy-duplication`: a screenshot of them is
recaptured, never a reason to keep an identical override); the menu sweep's `KNOWN` header clause on "OPEN findings"
is corrected by U7, with the two entries it covers. Filed: `check-part-edges` does not read
`world.parts.ensureLoaded("p").then ->` as a guard (whether it should is a rule change for the owner); the dead-method
allowlist's "Kept as intentional API … currently unused" group gives reasons that name no reach; the other legs
(paint audit, tier-naming, capstone, storage, vmtruth, graph, parts, apps, serialization, boot smoke) print no advice
row. Ratchets: none.

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

**Landed 2026-11-22.** (1) `Fizzygum-tests/CLAUDE.md`'s macro-tests paragraph has its cut facts back, each true of
today's code: "there" (where the optional fields live), the three caught-error token names, the determinism clause
("SWCanvas + the event queue are deterministic and matching is on the raw-pixel `dataHash`, not on anything else in
the filename"), "a real disagreement about the pixels, not a staleness artifact", and "there is no backend axis: the
harness page IS the SWCanvas page" (+206 B, 66073 of 67015: no raise); and "Three more fields" counts them true,
"Four" (two declarations, two fields each). (2) The handle tests and the rounded-box test
name `catchesPointerAt` again, in words true of the code: `HandleWdgt` has no override, and `Widget.catchesPointerAt`
answers `HandleAppearance`'s shape, the whole box — so the wording before the census reword ("it declares
catchesPointerAt over its whole box") was false too and is not restored; the same strings' other stale facts (the
painted "striped triangle", drifted line numbers, `nonFloatDragging`'s receiver call, the handle count, a false
`topWdgtUnderPointer` gloss) are rewritten with them. Four sites in three tests; no gate reads test prose for member names. (3) `layering-naming-convention.md` §2.5
has THREE settle-thunk shapes: shape 2 is back to its definition, and shape 3, "a settle round a non-twin self core",
holds the pick-up's figure resolution and the settles of that shape (several verbs over one core, a menu verb's
narrow core, a deferred-settle entrypoint's settling branch, a sequence, one settled step of a longer method). (4) The
four `public-call-sanctioned` reasons about `createErrorConsole` say why it is public (macros and rigs build the
console with it; its body drives the public setters [A] keeps out of a `_` form); the copied `layout-apply-sanctioned`
reason on `ViewportWdgt._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle`, a method [F] does not judge, is gone.
Filed: about 21 settle thunks fit none of the three shapes; three more `layout-apply-sanctioned` markers sit in methods
[F] does not judge (a stale-marker rule for [F] is a rule change). Ratchets: none.

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

**Landed 2026-11-22.** (1) `check-unresolved-sends`' `BUILTINS` gains `startsWith`, `trimStart` and `getPrototypeOf`,
BARE: a name is keyed only where Fizzygum also defines it, and Fizzygum defines neither `is` nor `getPrototypeOf`
(`BUILTINS_KEYED_NOTHING_TO_UNMASK` refuses the keyed form). `Deserializer` writes `startsWith`, `Class` writes
`trimStart()`, and `Duplicator._copyBuffer` rebuilds a view by its PROTOTYPE's constructor, so a `constructor`
property written onto a view does not choose its copy's kind (on the old line a Float32Array carrying
`constructor = Uint8Array` copied as a Uint8Array of its first four bytes). `SerializationError`'s `-0` arm is deleted: a Map
stores a `-0` key as `0`, so the arm never ran, and no `Object.is` call is left to want a table entry. The
serialization rig's `duplicate.aViewWithItsOwnConstructorKeepsItsKind` (a typed array and a DataView, each carrying an
own `constructor`) holds it; the plant restoring `original.constructor` fails exactly that check. (2) The nine
`new (window["X"])` sites that sit under their `whenAllLoaded` name the class bare; `Widget.spawnInspector` and
`createConsole` build their widget INSIDE the callback (a closure built above the await reads as unguarded: the gate
reads one line at a time) — not `classNamed "X"`, which is for a name that arrives as data. `check-part-edges.js`'
rule 2 and blind-spot paragraph, `lib/part-edge-scan.js`, `PartsRegistry.launch`'s comment, `build-and-packaging.md`,
the boot explainer and `Fizzygum/CLAUDE.md` say the same; per the owner's ruling (the talk constrains nothing) the talk
plan's quoted door and its gate table follow the tree. A one-off probe on the dev `index.html` opened each of the ten
doors with its part lazy. (3) `ShortcutWdgt.isDesktopShortcut` and its false comment are gone; the rigs ask
`isShortcutTo`, the one any-shortcut line `referencedWidget`. Corrected at research: `Object.is` cannot be keyed; the
`-0` arm is dead code; eight rig lines, one serialization rig. Filed: `DemoMenus.createFridgeMagnets` builds through
`world.parts.launch("FridgeMagnetsWdgt")`, a known class by a string (moving it changes defer-vs-inline timing).
Ratchets: none.

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

**Landed 2026-11-22.** (1) `isVisuallyTransformed` is the one name: its private twin `_isInsideNonIdentityIsland`,
same body, made public "because macros cannot call `_` members" (false today: rule [D] has its oracle marker) and
asked only by the dock band, is deleted; the band asks the public question; the comments that leaned on the twin
(and its stale "handles refuse, float-drag escalates" policy) say what holds, and `transforms.md` §1 names the
predicate. (2) `Widget.boxPresentedToOverlays: -> @clippedThroughBounds()` is the base answer every widget gives; the
viewport keeping a margin overrides it; the hover wash, the drag outlines and the lock badge, the grip's outline and
the pinout label ask it plainly where they wrote `x.boxPresentedToOverlays?() ? x.clippedThroughBounds()`.
`widget-authoring-guidelines.md` §14 says what the soft probe had misread: a question every widget answers is a
`Widget` member a subclass overrides, not a capability probed with `?()`. Proof: a plant that logs from
`isVisuallyTransformed` fails the two value tests AND the three dock tests (the band asks it); deleting the base fails
all six overlay tests; insetting it by 3 px fails the five base-path tests and not the document's margin leg, which
the override answers; deleting the override fails that leg's three lines. Pixels: exactly the predicted set —
`SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2 and image_3, both densities, both pointers (8
references): its member list, inherited shown, rests one row-index off after the scroll to `alpha`, each changed shot
the list shifted 1 logical px, nothing else. Ratchets, each on its own merits: `Widget`'s method ceiling lowered 394 →
393 (the twin) and raised 393 → 394 (the base answer), both dated; `comment-narration` 80 → 79 (a reworded comment
stopped narrating).

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

**Landed 2026-11-22.** (1) The serialization rig's pane check names the pane's seven runtime fields as a literal —
`surface`, `depth`, `engine`, `imageData`, `meshCache`, `transforms`, `lclCodeCompiler` — and holds it both ways
against the pane (each named field declared and holding a stamped object, read by a plain `typeof`, never by
`rebuildsItself`; every declared transient holding one named), sanctioned `// hand-list-sanctioned:` naming the rig.
The rig's bite-proof gains a standing run that unstamps `meshCache` and expects `CHECK_MISMATCH`, so a list derived
again from the rule it judges goes red. Corrected at research: the literal never reached git (the derivation was the
check's first form), and the plan's plant (drop a transient) already failed the derived check; the discriminating
plants unstamp a field or add a stamped one, and each fails the literal. (2)
`SystemTest_macroThumbHighlightOnlyUnderAPointer` reads the PAINTED thumb: the bright fixture's colours, a probe of the
canvas at the thumb's centre after `waitForScreenshotReady`, compared with the pointer kind (a mouse rests where it let
go, a finger nowhere) — the over-list stays as its own claim against the same witness, and the sweep is the thumb the
pointer left, painted at rest. The plan's plant (`_showsHover` true) now fails under a mouse too; a no-op
`notePointerStateChanged` (lime left on the canvas, every predicate right) fails it under both pointers — the old test,
which read the predicates alone, passes it by construction. (3) `SystemTest_macroPointerCancelEndsNonFloatDrag` runs under a finger: its one mouse-shaped assertion
expects "atRest" there, image_1's claim is worded per pointer, the `pointerKinds` declaration and its reason are gone,
and its two shots have finger references at both densities; under a finger every other assertion passed first time.
Ratchets: none.

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

**Landed 2026-11-22.** (1) The world steps a member only while it is on the world or held by the hand:
`WorldWdgt._stepsMember` (`TreeNode.isOrphan`, the one definition of attached, and not banned for a throw) is asked
by the step station and by the macro pump's two "still moving?" queries alike, so a knob put away mid-slide holds no
wait. Membership stays the widget's to manage (no second registry, no detach hook): a widget taken off its holder,
closed into the bin or not placed yet waits, and steps again once it is back. `BouncerWdgt.step`'s
`return unless @parent?` is gone. Corrected at research: "attached" is not `@parent?` (a widget in a closed window
has one) nor `root() is world` (a carried widget would freeze); the menu sweep's bite-proof planted a stepper that was
never attached, and each sweep root's restore destroys what it adds, so the plant now puts its stepper on the desktop
at the first world cycle after the walk. Ruled: a clock closed into the bin stops ticking and, reopened, shows its
closing time until its next due step (at most a second): the fix entails it, and a fresh face at once would need
per-member bookkeeping the plan does not name. Proof: `SystemTest_macroAWidgetOffTheWorldIsNotStepped` (values only,
both pointers) — taken off its holder by "Make pointer", closed into the bin, carried by the hand, never placed (a
bouncer and its copy), and a knob put away mid-slide — each leg failed by its own plant (the old membership, a
`@parent?` test, a `root() is world` test, queries that ask every member). Writing it showed that `close()` on the
bin's own window does nothing (the window would file itself into the bin inside it; the close button's path puts the
bin away): FILED. (2) "Deserialise from memory…" with nothing serialised says so (`world.inform`) and returns;
`lastSerializationString` is `undefined` until something is serialised (a `""` default made a `?` guard pass and the
parse throw). The menu sweep's two `KNOWN` entries for those throws are gone, and its header admits an entry only for
a row whose behaviour IS the throw. (3) A class-A finding on the way, fixed at its cause: the end-of-cycle capstone
probe of the new test found two careless pushes — `Widget.removeFromTree`, a public structural mutator, did not
self-settle, so the bin's close button (`BinWdgt.closeFromContainerFrame`) and "Make pointer" left the removal's
layout to the end of the cycle. It is the canonical wrap now, `removeFromTree: -> @_settleLayoutsAfter =>
@_removeFromTreeNoSettle()`; the probe reads clean. Pixels: the new `Widget` member moves
`SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2 and image_3 (its inherited member list rests 15 px
higher after the scroll to `alpha`), recaptured at both densities and pointers. Ratchets: `WorldWdgt`'s method
ceiling raised 129 → 130 (`_stepsMember`) and `Widget`'s 394 → 395 (`_removeFromTreeNoSettle`), each dated.

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

- The owner's rule and the first audit: this plan's `## BACKLOG ledger` ("A firing gate…", moved there from
  `docs/archive/backlog-open-items-detail.md`) and that archive file ("No audit has looked…"); memory `ratchets-must-not-dictate-design.md`.
- The audits of 2026-11-21: `Fizzygum-tests/.scratch/gate-contortions-audit/` (five files; `INDEX.md` first); memory
  `gate-contortions-audit-2026-11-21.md`.
- Policy and markers: `docs/architecture/lint-and-static-checks.md` §3b, §5; `docs/architecture/layering-naming-convention.md`;
  `docs/architecture/widget-authoring-guidelines.md` §14, §16.
- Determinism and the reference rules: `Fizzygum-tests/DETERMINISM.md`; `Fizzygum-tests/CLAUDE.md`.
- The loop: `Fizzygum-tests/.scratch/gate-contortions-loop/BRIEF.md` and `LEDGER.md`.

## Start prompt for a fresh session

See `Fizzygum-tests/.scratch/gate-contortions-loop/BRIEF.md`, "The loop prompt".

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] **A firing gate says how to go quiet, never when the quiet fix is wrong** — ratchets steered sessions to inline helpers, home code by a ceiling, make a CLAUDE.md line false; many gates have a cheap quiet fix that is a contortion; each should print why it exists and when a raise or sanction is right — medium. — CLOSED 2026-11-22 (gate-contortions loop, U1 + U2): every firing gate prints what its finding means from one module, `buildSystem/lib/gate-advice.js` — a budget when a raise is the answer, an invariant or a convention its quiet fixes as wrong and the right answer — and each bite-proof holds it to that advice (`lib/prove-rules.js` `advised`); the classes are `lint-and-static-checks.md` §3b.
- [x] U3: four facts cut from `Fizzygum-tests/CLAUDE.md` by byte count, three tests' prose that stopped naming `catchesPointerAt`, a layering-doc shape bent to hold one site, two stale sanction pointers — small. — CLOSED 2026-11-22 (gate-contortions loop, U3): the facts restored where true, the tests name `catchesPointerAt` in words true of the code, §2.5 has a third shape, the two pointers corrected.
- [x] U4: four platform calls respelled for unresolved-sends (one dropped a Duplicator hardening), eleven `new (window["X"])` sites, and `isDesktopShortcut`, alive only for two rigs — small. — CLOSED 2026-11-22 (gate-contortions loop, U4): the plain platform calls, the Duplicator hardening with a rig check, the classes named bare under their await, the predicate deleted.
- [x] U5: `isVisuallyTransformed` duplicates a private twin made so a macro could call it; `boxPresentedToOverlays` has its default written at four readers — small, inspector churn. — CLOSED 2026-11-22 (gate-contortions loop, U5): one public name; the base answer on `Widget`, a viewport overriding it.
- [x] U6: three checks take their expected value from the rule they judge, or dodge a finger failure: the serialization rig's pane list, the thumb-highlight test, the pointer-cancel test's mouse-only declaration — small. — CLOSED 2026-11-22 (gate-contortions loop, U6): the literal list both ways, the painted thumb against a pointer-kind witness, the cancel test under a finger.
- [x] U7: two dev-menu rows throw when clicked before anything is serialised, excused in the menu sweep's `KNOWN` table; the bouncer's `return unless @parent?` guards the stepping defect filed in this file — small. — CLOSED 2026-11-22 (gate-contortions loop, U7): the rows inform and return; the entries are gone.
- [x] The world steps every registered stepper, attached or not: a detached widget and a never-attached copy of a stepping widget keep stepping and stay in the set. Reached by the menu sweep (a detached bouncer threw). Medium-low. Detail: the plan's §U4e. — CLOSED 2026-11-22 (gate-contortions loop, U7): `WorldWdgt._stepsMember` — the world steps a member only while on the world or the hand; the bouncer's guard is gone.

Its detail, moved verbatim from `docs/archive/backlog-open-items-detail.md`:

### A firing gate says how to go quiet, never when the quiet fix is wrong

**The owner's rule (2026-11-16):** "if the right architectural shape needs a raise of the ratchet, go ahead. Don't
make the solution worse because of the ratchet." A ratchet still flags real growth, so a session first asks whether a
member is genuinely redundant or misplaced; it never trades clarity for the count. The same day the owner widened
this from ratchets to every gate whose cheapest fix is a contortion (the second half of this item, below).

**What is wrong.** Every ratchet gate (a recorded number that may fall and may not rise) tells a session how to get
back under its number, and none says when raising it is the right answer. Some forbid it outright:
- `buildSystem/check-complexity-ratchets.js`'s footer reads "A ratchet may fall and may not rise: split the function
  or the class rather than raising a number here". A NEW function above the complexity ceiling can never be
  recorded, even when it is born from a split that lowers a recorded parent.
- `check-call-separation.js` says "never raise the baseline to ship".

Others are partial: `check-stinks.js` and `census-widget-conformance.js` say "if genuinely intentional, raise … with
a one-line reason". `check-doc-narration.js` allows an instruction-file ceiling to rise only for a new rule, not for
a sentence that must grow to stay true. Only `check-plane-discipline.js` B states the legitimate case outright
("same-plane-by-construction ⇒ raise the baseline with a one-line reason"). Three practices add to the pressure:
- the loop briefs say "a unit never RAISES a recorded ratchet value (if it cannot land without, PARK)";
- every gain is banked at once (all four method ceilings sat exactly at their counts on 2026-11-16);
- subagents are barred from `buildSystem/`, so they cannot raise even when it is right.

**Evidence** (audit of 433 session transcripts, git history and memory, 2026-11-16):
1. The docked-and-floating-toolbars arc, P1 (R8, 2026-11-16): `WorldWdgt` was held at 126. The clean shape (a
   public door, a named climb, an intent-named notification) needed 129, and the orchestrator first bounced it toward
   a zero-net contortion. The owner stopped that: the shape was restored and the ceiling raised to 129 with its
   reason. Contortion, reverted.
2. Fizzygum `2868c732` (round-4 loop, U4): a `Fizzygum/CLAUDE.md` sentence was reworded to fit its byte ceiling and
   became false (the vendored CoffeeScript is not pinned). Review caught it, and the line is accurate today.
   Contortion.
3. Fizzygum `324f6d64` (round-2 loop, U6): a test-playing query meant as a `WorldWdgt` static became a boot function,
   `window.aTestIsPlaying`, because `WorldWdgt` was at its method ceiling. The commit gives only an after-the-fact
   reason. Leaning contortion: re-judge its home.
4. Fizzygum `9966b424` (round-1 loop, U10): `WorldWdgt.loadWorldSnapshot` (complexity 67, recorded) was left unsplit
   because a split adds methods to a class at its ceiling. One ratchet vetoed the refactor the other exists to
   drive. Re-judge.
5. Fizzygum `495e67ed` (2026-10-17): a redundant `instanceof` was removed to keep the type-test stink net-zero.
   Defensible, but the count drove it. Borderline.
6. Fizzygum `def42b0f` (round-3 loop, U3): an instruction-file sentence was chosen by measuring candidate lengths.
   It stayed accurate. Mild.

**To do.**
- One shared advice text (e.g. `buildSystem/lib/ratchet-advice.js`) that every ratchet rule prints beside its own
  `why`. It says:
  - (a) what drift the number holds back;
  - (b) the legitimate raises: the right shape needs it (a named helper, a public door, an intent-named
    notification, the natural home); a refactor a ratchet exists to drive crosses another one (a split adds
    methods); the gate's measurement widened; an instruction-file sentence must grow to stay true;
  - (c) the forbidden answers: inlining a helper that deserves a name, folding two concepts into one, an odd home,
    an offsetting trade made only for the count, a wording chosen by length, a true fact dropped;
  - (d) how to raise: in the same change, with a dated reason beside the number (the trailing-comment form the
    ceilings and baselines already use), naming the ratchet in the commit message and the report.
- Rewrite the complexity footer, the call-separation line and the loop-brief rule to match: a brief says "STOP and
  report the right shape and the raise it needs", never "PARK".
- Let a split's child be recorded when the split lowers a recorded parent.
- State the policy in `docs/architecture/lint-and-static-checks.md`.
- Prove it the every-gate-bites way: each ratchet's self-test asserts the advice is printed with each rule it fires.
- Then re-judge cases 3 and 4 under the rule.

**The other gates (widened by the owner, 2026-11-16).** A gate whose cheapest way back to green is a rename, a move,
a deletion, an inlining or a stub invites the same contortion, number or not. Each one's failure line should name its
QUIET fix as the wrong answer and say what the right one is:

| Gate | The quiet fix (wrong when followed blindly) | The right answer |
|---|---|---|
| `check-part-edges` | an `if X?` guard | right for INCLUSION only; a LAZY part's door awaits `world.parts.ensureLoaded`, since a guard swallows the click |
| `check-unresolved-sends` | a stub method, at worst a `-> false` default on `Widget` | the missing dispatch is real (§14 forbids the default): implement it on the answering class or drop the call |
| `check-dead-methods` | delete it | a member reached by a string name (a menu action, a pin setter) is live: allowlist it with its reason |
| `check-layering` [D] | promote a private member to public product API so a macro can reach it | product API never exists for a test: an oracle line with `# macro-private-call-sanctioned: <reason>`, or a toolkit verb |
| `check-call-separation` [S]/[U] | rename a member's tier so the call goes quiet | a tier states a member's role: re-tier only when the role is wrong, else sanction the caller with its reason |
| `check-layering` [G] and the tier rules | fold a helper into its caller | keep a helper that deserves its name; sanction or re-tier it instead |
| `instanceof-type-test` stink | a type-named predicate (`isScrollPanel`), or a duck-typed type test in disguise | move the behaviour, or a query named for the CAPABILITY (§14); an honest type test is kept with its reason |
| `check-hand-lists` | replace a clear list by reflection, or reshape the literal so the detector misses it | derive the list when it can be, else assert it both ways and sanction it |
| `census-hierarchy-duplication --gate` | delete an identical override | it changes what `super` reaches and what a prototype owns (guidelines §16): sanction a deliberate one |
| `comment-narration`, `check-doc-narration` | delete a warning that names a retired shape | restate it as a present-tense constraint ("never X, because Y") |
| the two CLAUDE.md byte ceilings, the BACKLOG line length | shorten a true sentence until it is false | the ratchet half of this item: raise the ceiling for a sentence that must grow to stay true |
| `WORLD_CONSTRUCTION_DRIFT` | add the field to `_worldStateAuditExemptions` | find what the constructor or `finishWorldSetup` reads; only a field no render can reach is exempt |
| the revisits and settle gates | a flag that suppresses the re-visit | remove the cause (`docs/architecture/layout.md`) |
| macro `AIM MISSED` | `@pressMustLandOn` whatever the press hit, or aim at a raw point | aim by meaning; a declared aim names what the press must meet |
| `pointerKinds: ["mouse"]` | declare a test mouse-only to dodge a finger failure | only a test whose SUBJECT is a mouse mechanism; otherwise the finger failure is a finding |
| `check-plane-discipline`, `check-raw-pointer-reads` | map coordinates wholesale | map only what feeds an input event (a wholesale map broke a caret-slot test) |
| the cognitive-complexity ceiling (15) | split blindly, threading state through many-parameter helpers or across a `try/finally` | split along a real seam, or raise with a reason (the ratchet half) |

Most of these gates already have a sanction marker with a required reason (`lint-and-static-checks.md` §5 lists
them); what none of their messages says is WHEN a sanction or a design change is right, as opposed to the quiet fix.
The same shared advice text carries one row per gate. Its self-test asserts that each gate's failure line prints
that gate's row.

## BACKLOG detail (open items, moved from docs/BACKLOG.md)

(empty until a unit files an item)
