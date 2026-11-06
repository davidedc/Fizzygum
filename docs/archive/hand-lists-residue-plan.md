# Hand-kept-lists residue: four follow-ups, in the owner's order

**STATUS (2026-11-06): CLOSED — all four units + §1b done in one session, ARCHIVED. Closing gates: `fg gauntlet`
19/19 no retries (885 s), `fg homepage` OK, `npm run selftest` OK; one end-of-queue review (an independent read of
both diffs), whose findings are folded into §2 and §4 below. Residue: BACKLOG (the unresolved-sends DEF-side
catch-all mask). The queue as written follows the ledger.**

Ledger:
- §1 DONE — `HandleWdgt.attach` builds one menu per branch and pops it unconditionally (the family's shape);
  `SystemTest_macroHandleAttachShowsNoTargetsMessage` (assertion-only). ⚠ The off-canvas spot is past the world's
  bottom-right corner: `Widget._moveToNoSettle` floors a free widget's position at 0. ⭐ FINDING: the plant (the
  guard restored) first PASSED the test — `getMostRecentlyOpenedMenu` answers the pop-up most recently BUILT
  (`MenuWdgt`/`PromptWdgt` constructors file themselves in `world.freshlyCreatedPopUps`), so the test now also
  asserts the message is SHOWN; with that the plant fails it. Gates: build, presuite (369/369), selftest, follower on
  both pointers (0 `WORLD_INVENTORY_`).
- §1b DONE (owner ruling 2026-11-06: fold in) — the toolkit's menu assertions (`assertTopMenuItemCount`,
  `assertTopMenuItemStrings`) hold the menu to the new `popUpIsShown` (the product's own `isOrphan`), reporting "a menu
  built but not shown"; the new test reads its title behind `@popUpIsShown menu`. Proof: a plant making
  `Widget._attachToChosenParent` build-and-drop its message left `SystemTest_macroLonelySliderCantBeAttachedToAnything`
  GREEN before the change and fails it after; clean runs pass. Documented in MACRO-PATTERNS.md, `src/macros/CLAUDE.md`.
- §2 DONE — `scripts/lib/suite-summary.js` holds the RESULT block's format (`formatSuiteResult`, which
  `run-all-headless.js` now prints with) and its one reader (`readSuiteResult` + `measuredEverything`). FOUR readers
  moved onto it, not three: `torture-headless.js` had its own. ⭐ FINDING: `recapture.js` read a run with gate-token
  violations and no pixel failure as GREEN (the old `/\bfailed:\s*0\b/` fallback), and an incomplete-shard run
  likewise; it now gates those tests / calls the run INCONCLUSIVE. Proof: `lib/suite-summary-selftest.js` (34 checks,
  a real red run cut at every byte, the writer reproducing two real runner blocks byte for byte; 5 mutants each
  caught), the fuzz corpus now built with the real formatter, old-vs-new over 28 real suite logs (only the gate-only
  runs change), `derive-inspector-churn-set.js --check` live = MATCHES 15/369. End-of-queue review fixes: a FIFTH
  reader (`lib/audited-suite-with-infra-retry.sh`, sed) reads through the module's shell CLI now; a multi-line ERRORED
  status (a browser-launch error) split its row, so the writer keeps every row on one line (pinned in both
  selftests: fuzz `I1b` stays retryable); `measuredEverything` holds the shard totals to `tests:`; a gate token
  outside any test (`(boot/setup)`) makes recapture INCONCLUSIVE rather than single-verified.
- §3 DONE — the `fg recapture-inspector` case (local tooling, in NO repo) hands the churn set to the gated
  `recapture.js --dprs=1,2` once per pointer kind (mouse, then `--pointer=finger`); its per-test loop is gone, the
  stale-name refusal kept. Round trip under the churn plant (`AAAinspectorChurnPlant`, via `PRELUDE_JS` +
  `AUDIT_PRELUDE`): both kinds RECAPTURE COMPLETE (every suite gate green), 15 tests rewritten — 344 mouse + 344 finger
  reference paths — then restored (`git checkout` + `git clean` of exactly those 15 directories).
- §4 DONE (owner ruling 2026-11-06: option (a)) — census (`Fizzygum-tests/.scratch/builtins-receiver-census.js` — local and
  gitignored; it reads the gate's own masker and harvest, 8017 calls): of 1431 paren-calls of the 29 shared names, 288 have a Fizzygum receiver; 156 are
  `toString` (cannot throw); BUILTINS masked 100 TypeError-capable sites (round 77, create 9, ceil 8, floor 4, abs 1,
  save 1), the DEF harvest's catch-all form the other 32 (close 15, add 10, get 3, clear 3, entries 1); no live bug.
  Landed: BUILTINS BARE by default, KEYED (`Math.round`) for a name Fizzygum ALSO defines that only a platform global
  sends — 8 entries (`Math.abs/floor/ceil/round/min/max`, `Array.isArray/from`); a keyed entry excuses only its literal
  receiver. (A first cut keyed all 34 global-only names; the end-of-queue review showed the 26 Fizzygum does not
  define unmask nothing and could false-fail on a receiver the gate cannot read, `window.JSON.parse(` — against the
  gate's zero-false-positive charter — so they are bare.) Form rules: `BUILTINS_NOT_KEYED`,
  `BUILTINS_KEYED_NOTHING_TO_UNMASK` (only once no call of the name is left unresolved, so deleting every Fizzygum
  `round` reports the 77 calls, never "make it bare"), `BUILTINS_KEYED_OFF_PLATFORM` against a stated, asserted
  `PLATFORM_GLOBALS`, stale; the receiver read allows no space before the dot (so an interpolation never reads as one);
  `create`/`add`/`close`/`entries` deleted (no platform paren-sender). Plants (scratch tree): every `round` implementor
  deleted → HEAD GREEN, new FAILS on the 77; every `create` implementor deleted → HEAD GREEN, new FAILS on 9; bare
  `min`, keyed `Math.trunc` / `Color.create` / `JSON.parse`, `PLATFORM_GLOBALS` + `Color` / `Reflect` each fail; bare
  `abs` stays green BY DESIGN (a non-global `@origin.abs(` sends it too: whether the platform has `abs` on an instance
  is the keyed entry's own claim). Blind spots stated in lint-and-static-checks.md.

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework (`Fizzygum/src`, one class per file, every class a global); its tests and test
tooling live in the sibling repo `Fizzygum-tests` (`tests/` macro SystemTests, `scripts/` Node rigs, the harness in
`Automator-and-test-harness-src/`). Everything is driven by the umbrella wrapper `/Users/davidedellacasa/code/Fizzygum-all/fg`
(local tooling, in no repo). These four items are the residue of the closed arc `docs/archive/hand-kept-lists-plan.md`
(its §6 ledger names each as a finding); the owner picked them and ordered them on 2026-11-06. ⚠ Line numbers drift;
grep the quoted names.

## §1 Unit 1 — `HandleWdgt.attach` shows its "no widgets to attach to" message

**The defect.** `src/HandleWdgt.coffee` `attach` (~:345) builds a "target" chooser of the widgets the handle could
stick to (`world.plausibleTargetAndDestinationWidgets @`); with none, its `else` branch builds a message menu
(`title: "no widgets to attach to", titleIsAMessage: true`, comment: "show a message instead of hiding the entry") —
and then the last line `menu.popUpAtHand() if choices.length` throws it away, so the click does nothing. Rarely
reachable: a candidate is any widget that is visible, not collapsed, not inside the handle, and overlapping it on
screen (`Widget._isSelfPlausibleAttachTargetFor`), so the WORLD qualifies for every handle on the canvas; only a handle
entirely off-canvas has none.

**Owner ruling (2026-11-06): show the message** (the recommendation — it keeps the case honest if the world ever stops
qualifying).

**Fix.** `menu.popUpAtHand()` unconditionally (and re-read the branch's comment so it is true). Pixel-neutral for the
suite (no test reaches the no-candidate case) — confirm with `fg presuite`.

**Prove it.** A new assertion-only macro test (see the `/author-macro-test` skill in `Fizzygum-tests/.claude/skills/`):
make a free handle (the demo menu's "Handle", `WidgetFactory.createNewHandle`), move it wholly off the canvas, open its
context menu, click "Attach", assert a pop-up whose title is "no widgets to attach to" opened; destroy everything it
built. Prove the test with a `PRELUDE_JS` plant that puts the bug back (re-guard the pop-up) — the test must fail;
then a FOLLOWER: `node scripts/run-sequence-headless.js SystemTest_<new> SystemTest_<any>` on both pointers, zero
`WORLD_INVENTORY_` lines. ⚠ The menu sweep (`fg menusweep`) proves every row's submenu flag: "Attach" is flagged
`opensSubmenu: true`, and a MESSAGE is not a menu there — the sweep's on-canvas handle root always has candidates, so
it never meets this case; if a future root does, that is a `CONDITIONAL_OPENERS` decision, not this unit's.

## §2 Unit 2 — ONE reader of the suite runner's summary line

**The duplication.** `scripts/run-all-headless.js` (~:572) prints the authoritative summary
`failed tests (N): [<JSON array>]`, and three tools parse it, each its own way:
- `scripts/recapture.js` (~:199) `out.match(/failed tests \(\d+\): (\[.*\])/)` — greedy, single line, count not checked;
- `scripts/run-atlas-fuzz.js` (~:98) `RE_FAILED_LIST = /^failed tests \(\d+\): (\[[\s\S]*?\])\s*$/m` — non-greedy, multi-line;
- `scripts/derive-inspector-churn-set.js` (~:156) `RE_FAILED_LIST = /^failed tests \((\d+)\): (\[.*\])\s*$/m` and
  holds the list's length to the count (~:197).
Three answers to one question, free to disagree (the truncated-pipe failure `scripts/lib/safe-exit.js` documents is
exactly where they would).

**Fix.** One module `scripts/lib/suite-summary.js` (read the runner's other summary lines too while there — the
per-shard summary and the `progress:` line — and include only what a caller needs): parse → `{ failed: [...],
declaredCount, … }`, and REFUSE (throw or an INVALID result each caller maps to its own exit 2) when the count and the
list disagree or the JSON does not parse — a truncated summary must never read as "fewer failures". All three callers
use it; their outputs unchanged on a green and a red run. A selftest `scripts/lib/suite-summary-selftest.js` in
`npm run selftest` over canned transcripts (a pass, a red run, a truncated line, a count mismatch, a CRLF/ANSI line if
any runner can produce one), whose ship gate is that no malformed summary parses as a clean result. Check
`scripts/lib/diffwork.js` and `run-atlas-fuzz-selftest.js` first — they already hold canned transcripts.

## §3 Unit 3 — `fg recapture-inspector` refreshes the finger references too

**The gap.** The inspector member-list CHURN SET (`Fizzygum-tests/scripts/inspector-churn-set.json`, read through
`scripts/lib/inspector-churn-set.js`; re-derived by `scripts/derive-inspector-churn-set.js`) is the tests whose
screenshots show a live member list, so a benign new widget member changes their pixels. `fg recapture-inspector`
(the `recapture-inspector)` case in `fg`) loops `capture-macro-test-references.js "$t" --dprs=1,2` per test: MOUSE
references only. The same tests carry FINGER references (`…/ceilPixRatio_<N>/finger/`), which the same change leaves
stale, so `fg finger` (a gauntlet leg) goes red; today the comment there says to run
`fg recapture --auto --pointer=finger` by hand.

**Fix (reuse the existing mechanism).** Have the case hand the churn set to the GATED recapture, once per pointer
kind: `node scripts/recapture.js --dprs=1,2 <names…>` then the same with `--pointer=finger` (`recapture.js` runs both
kinds, passes a mouse-only test over as TEST SKIPPED, re-runs the suite and prints COMPLETE/INCOMPLETE) — which also
deletes the case's hand-rolled per-test loop. Keep its refusal of a stale churn-set name. Verify on a real benign
change: plant one no-op OWN widget field the way `derive-inspector-churn-set.js` does, recapture, see both kinds
COMPLETE, then revert the plant and the references (`git -C Fizzygum-tests checkout -- tests/`) — or do it on a
throwaway branch. ⚠ `fg` is local tooling: its change is not committed anywhere; say so in the review.

## §4 Unit 4 — `BUILTINS` masks Fizzygum methods that share a platform name (DESIGN — measure, then owner call)

**The gap.** `Fizzygum/buildSystem/check-unresolved-sends.js` fails a call `[@.]name(` that nothing implements;
`BUILTINS` (107 names, each one some call sends; stale ⇒ fail) excuses platform API. The gate is RECEIVER-BLIND, so a
`BUILTINS` name excuses EVERY call of that name — and 29 of them are also Fizzygum methods: `push shift fill keys
entries match toString abs floor ceil round min max create isArray from measureText stroke clip save scale focus
resolve test add has get clear close`. Delete the Fizzygum `close` (say) while a `@frame.close()` caller survives,
and the gate stays green.

**Do first: measure.** For each of the 29, census the call sites by RECEIVER SHAPE (`@x.close(`, `Math.floor(`,
`ctx.save(`, `@children.push(`, `world.close(`, …): which are platform receivers (the global objects, a canvas
context, an Array/Set/Map/Promise), which are Fizzygum receivers, which are undecidable. Look at how
`check-layering.js` (`CANVAS_MOVETO`, a receiver carve-out for the canvas `moveTo`) and `census-call-arity.js` already
read receivers.

**Then propose to the owner** (a design fork — do not implement before the ruling): e.g. (a) key `BUILTINS` entries
by receiver pattern for the static-receiver families (`Math.*`, `Object.*`, `Array.isArray`, `JSON.*`, a canvas
context's `fill/stroke/clip/save/scale/measureText`) so a bare `@x.close(` is judged against Fizzygum's implementors;
(b) split each shared name into "platform when the receiver is X, Fizzygum otherwise"; (c) accept and state the blind
spot. Whatever lands must keep the stale-entry rule, and its blind spots go in
`docs/architecture/lint-and-static-checks.md`'s unresolved-sends row.

## §5 Protocol and gates

- `fg status` first; read this plan; for each unit read the files it names before touching them.
- Owner's standing rules: never commit or push without approval (`git commit -F <file>`, messages end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; ask about push separately); `fg` by absolute path; long ops
  in the background with an ETA; a running fg op owns src/ and tests/; `.coffee` edited with the Edit tool only;
  present-tense comments and docs; Node probes under `Fizzygum-tests/.scratch/`.
- Gates per unit: `fg build` + `npm run selftest` (Fizzygum-tests); Unit 1 also `fg presuite` and its follower proof;
  Unit 3 its real recapture round trip. At the close: `fg gauntlet` + `fg homepage`, then archive this plan
  (`git mv` to `docs/archive/`, stamp, INDEX line) and clear its BACKLOG section.
- Each check is believed only after a PLANT has been seen to fail it (the arc's standing rule).
