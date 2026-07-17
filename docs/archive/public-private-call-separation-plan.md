> **ARCHIVED — COMPLETE (2026-07-17 restructure).** PUSHED 2026-07-12 — T0-T5 all executed; header banner stale (still reads NOT STARTED)
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Public/private call-separation — command/query discipline for self-calls (rules [S]/[T]/[U])

**STATUS: AUTHORED 2026-07-12 — NOT STARTED.** Census tool landed (`buildSystem/census-public-private-calls.js`);
no gate built, no source changed yet. Execution ledger in §10.

**What this is.** A self-contained plan (executable cold, zero prior context) for a campaign that (1) stops
private code from self-calling public *commands*, (2) stops settling methods from calling other settling
methods (double flush), and (3) privatizes the large population of public methods that are provably not
public API. It was sized by a real census (2026-07-12, tool now in-repo — §2) rather than by intuition;
every number below is measured, and the plan says which claims are VERIFIED vs PROVISIONAL.

**Origin.** Owner proposal (2026-07-12): "there should be a new hint rule that checks the methods where a
mix of public and private methods are used … we don't want public methods to be re-entrant, and we certainly
don't want private methods to use public methods … I'm sure many public methods should in fact be private."
The census confirmed the diagnosis but changed the cut: the literal "mixed use" rule is ~85% noise (§8-R1);
the enforceable rules are the three below.

---

## 0. Cold-start orientation (read this if you have zero context)

- **Fizzygum** is a CoffeeScript canvas GUI framework, ~510 one-class-per-file sources under `Fizzygum/src/`
  (filename == class name; no imports — every class is a global; `nil` means `undefined`). It lives in an
  umbrella workspace `Fizzygum-all/` beside `Fizzygum-tests/` (196 screenshot-diff macro SystemTests) and
  `Fizzygum-builds/` (generated output — never edit). Read the root and per-repo `CLAUDE.md` files first.
- **Build/test loop:** from the umbrella, `./fg build` · `./fg suite` · `./fg gauntlet` (or from `Fizzygum/`:
  `./build_it_please.sh`, `./build_and_test.sh`). The build runs a family of static gates
  (`buildSystem/check-*.js`) — the whole checking system is documented in **`docs/architecture/lint-and-static-checks.md`**
  (gate inventory, rules [A]–[R], markers, ratchet idioms, how to add a gate — this plan adds rules the way
  that doc's §8 prescribes).
- **The runtime invariant these rules protect** (depth: `docs/archive/layout-system-architecture-assessment.md`):
  ONE layout flush per outermost public mutation. A public mutator (e.g. `setExtent`, `add`, `close`)
  self-settles via `Widget._settleLayoutsAfter` (runs the non-settling core, then flushes
  `recalculateLayouts()` exactly once); internal/low-level code must use the non-settling `_<name>NoSettle`
  cores and `_`-tier primitives, and must never re-enter the public self-flushing layer (runtime throw backs
  this up; static rules [A]/[G] enforce the *direct* cases at build time).
- **Naming tiers** (authority: `docs/architecture/layering-naming-convention.md`): public `name` = user-meaningful API;
  `_name` = internal orchestrator; `__name` = leaf primitive (no orchestration, rule [I]); `*NoSettle` =
  non-settling core. `check-layering.js` classifies **by name** (`isLowLevel = /^raw[A-Z]/ || /^_/ ||
  /NoSettle$/`) — the convention and the lint are co-designed: *the name encodes the behaviour*.
- **Standing owner rules:** never commit/push autonomously — present a summary + message and wait; verify
  behaviour changes with the full headless suite; **benign inspector member-list recaptures are acceptable**
  (renaming a method of an inspected class changes the Object-Inspector member list drawn in some reference
  screenshots — just recapture, never contort code to avoid it); backtick/`$()` in `git commit -m` gets
  substituted by the Bash tool — use `git commit -F <file>`.

---

## 1. Problem statement and the design insight

The codebase is **83% public by name** (2,362 public vs 472 `_` + 13 `__` of 2,847 methods, 2026-07-12) —
far more surface than is real API. Consequences measured by the census:

1. **Private code calls public commands.** 84 sites where a `_`/`__`/`*NoSettle` method self-calls a public
   method that mutates state (82 EFFECTFUL) or transitively settles (2 SETTLING). The SETTLING pair is a
   demonstrated **one-hop blind spot in rule [G]**: `[G]` forbids low-level code from calling a *directly*
   settling wrapper (a method whose own body calls `_settleLayoutsAfter`), but a public method that settles
   only **transitively** (e.g. via `@add`) is invisible to it.
2. **The same one-hop blind spot defeats `check-constructors-build.js`**: `ColorPickerWdgt.constructor` calls
   public `@buildSubwidgets`, whose body does `@add` ×3 — the ctor gate scans only the constructor body.
3. **Double-flush shapes exist** but are rare and all currently conscious (9 sites — §App-C).
4. **245 public methods are referenced ONLY as `@`-self calls** — never `.member`-called, never named in a
   string (menu/connection dispatch is string-driven, so strings count), never referenced by the test harness
   or any macro test. They are provably not external API.

**The design insight (why the owner's literal rule was re-cut).** Of 622 private→public self-call sites,
**483 target pure queries** (`@width()`, `@bounds()`, `@isOrphan()`…) and **55 target `changed`/`fullChanged`**
(the *designed* react verbs — banned only in `__` leaves by rule [I]). Both are legitimate and ubiquitous.
So the rule must be **command/query-scoped**: what private code must not self-call is a public **command**
(mutating and/or settling), not "a public method". Queries stay free; react verbs stay blessed for `_` tier.

**Relationship to the existing rules** (all in `check-layering.js`, documented in
`docs/architecture/lint-and-static-checks.md` §4):

| Existing | Covers | This plan adds |
|---|---|---|
| [A] | low-level → the 5 geometry setters / 7 text setters / recalc (direct, hand-listed) | [S]: → *any* public command, incl. transitively-settling |
| [G] | low-level → *directly*-settling structural wrappers (discovered) + `@add` | [S]: the one-hop-transitive settlers [G] can't see |
| [C] | geometry setter → geometry setter | [T]: *any* directly-settling method → *any* settling public callee |
| [R] | MenusHelper reaching OTHER objects' `_` internals | complementary axis — [S]/[T]/[U] govern SELF-calls |
| dead-method gate | public method referenced NOWHERE | [U]: public method referenced only by ITSELF (`@`-self) |

---

## 2. The census tool (in-repo, the measurement authority)

**`buildSystem/census-public-private-calls.js`** — an ANALYSIS tool, not a gate (always exits 0; exit 2 on
operational error). Run from `Fizzygum/`:

```sh
node ./buildSystem/census-public-private-calls.js              # summary + truncated lists
node ./buildSystem/census-public-private-calls.js --full       # full site/name inventories
node ./buildSystem/census-public-private-calls.js --json o.json  # machine-readable dump
node ./buildSystem/census-public-private-calls.js --self-test  # call-extractor fixtures
```

It computes four censuses — **R1** (private→public self-calls, callee classified SETTLING / EFFECTFUL /
REACT-VERB / QUERY), **R2** (public→public settling self-calls, plus the NARROWED double-flush subset),
**R3** (the literal mixed-use rule — informational only), **R4** (privatization candidates, EFFECTFUL vs
QUERY split; needs the sibling `Fizzygum-tests` repo, self-skips without it). Methodology, definitions and
the documented blind spots (dynamic dispatch; `@foo?()` soak calls — 10 sites tree-wide; canvas `moveTo`
carve-out; cache/memo-write carve-out so memoizing getters stay queries) are in the file's header comment.

**Two rules for using it:**
- **Re-run it at the start of every tranche.** The tables in this plan are the 2026-07-12 snapshot, taken on
  a working tree that had unrelated uncommitted WIP — counts and `file:line` anchors WILL drift. Anchors in
  this plan are *symbol-first*: grep the symbol, treat quoted line numbers as hints.
- Its forward effect/settle closure runs over **`@`-self calls only**. This is deliberately NOT the rejected
  [G] transitive closure (`docs/architecture/lint-and-static-checks.md` §7: backward name-reachability through `.`-member
  calls and `new` hubs ballooned to ~500–710 false hits — DO NOT re-attempt *that*). The self-scoped forward
  closure converges cleanly: 2 SETTLING hits at baseline, not 500. This distinction is the reason the present
  campaign is tractable where the earlier prototype was not.

---

## 3. Findings snapshot (2026-07-12 — re-measure before acting)

Headline: 510 classes / 2,848 methods; R1 = 622 sites {QUERY 483, REACT-VERB 55, EFFECTFUL 82, SETTLING 2},
hard sites 84 across **46 classes** (464 classes already clean); R2 = 93 sites of which **9 narrowed**
(double-flush shape) — all currently conscious/documented; R3 = 216 mixed methods (78 with a command) —
rejected as a rule; R4 = 245 candidates (94 EFFECTFUL + 151 QUERY).

Individually notable (all VERIFIED by reading the source):

- **`Widget.markLayoutAsFixed`** (`src/basic-widgets/Widget.coffee`, one line: `@layoutIsValid = true`) — a
  layout-machinery primitive with a public name. 33 of the 82 EFFECTFUL sites are `_reLayout` overrides
  calling it; the only other use is the settle loop (`WorldWdgt.coffee`, grep `markLayoutAsFixed`). Rename
  to `_markLayoutAsFixed` erases 40% of the violation set in one move (T1).
- **`StretchableEditableWdgt.createNewStretchablePanel`** — public, body does `@add` (settling), called from
  `_buildAndConnectChildrenNoSettle` AND from the `_reactToChildPickedUp` callback. A comment in the file
  consciously defends the shape ("stays self-settling when called post-construction") — a KNOWN exception
  that today carries **no marker because no rule demands one**. Subclass overrides of the same protocol
  exist in `apps/DashboardsWdgt`, `apps/PatchProgrammingWdgt`, `apps/ReconfigurablePaintWdgt`,
  `apps/SimpleSlideWdgt` — any reshape must sweep the family (T2).
- **`ColorPickerWdgt.constructor` → `@buildSubwidgets` → `@add`×3 + `@_invalidateLayout`** — evades the
  constructor-build gate one hop out; should be folded into the canonical
  `_buildAndConnectChildrenNoSettle` pattern (T2).
- **`PromptWdgt._reLayoutSelf` → `@buildSubwidgets`** (same in `SaveShortcutPromptWdgt`) — a layout pass
  dispatching to a public, overridable *builder* hook. Both hooks are **empty** today (vestigial), so the
  hazard is dormant; delete the dead hooks and the calls (T2).
- **R2 narrowed (9 sites, §App-C)**: `ActivePointerWdgt.grab → @add` (the documented hand-rolled gesture
  settle), `WorldWdgt.doOneCycle` ×6 (the frame driver — already the [B] whitelist owner), and
  `Widget.newParentChoice{,WithHorizLayout} → @add` (comment documents the extra flush as deliberate and
  idempotent). Expectation: rule [T] lands green with ~3 markers and zero code movement.
- **Fix-shape fact:** **0 of the 39 distinct hard callees has an existing `_<name>NoSettle` twin** — so the
  dominant fix is *rename to `_` tier* (they were never really public), not wrapper/core splits. Splits are
  only for the handful of genuinely dual-use names (heavy `.member`/external refs — see the rubric §5).

---

## 4. The three rules

Letters continue `check-layering.js`'s [A]–[R]. Follow `docs/architecture/lint-and-static-checks.md` §8 ("How-to") for
wiring; every new rule/gate must be **self-tested** (plant a violation in a throwaway `src/__X.coffee`,
confirm loud failure, confirm the marker/allowlist exempts, delete the fixture).

### 4.1 Rule [T] — a directly-settling method must not call another settling public method (HARD)

- **Where:** inside `check-layering.js` (it already has every ingredient).
- **Subject:** any method whose own body matches `SETTLE_CALL` (`[@.]\s*_settleLayoutsAfter\b`), excluding
  `RECALC_WHITELIST` (the settle tiers / `doOneCycle`). This is exactly the population
  `discoverSettlingWrappers` already walks.
- **Forbidden in the subject's body:** an `@`/`.`-call to a public geometry setter (`PUB_CALL`), a text
  setter (`TEXT_SETTER_CALL`), a discovered settling wrapper (`wrapperCall`), or the unambiguous self-add
  (`SELF_ADD_CALL`) — i.e. a second flush for one logical mutation. (Branch-exclusive pairs — settle on one
  path, settling callee on another — are textually indistinguishable; accept a marker. The census bounds the
  subject population: 9 rows total, so marker noise is bounded and known.)
- **Marker:** `# double-settle-sanctioned: <why>` (per-method, reason mandatory — mirror
  `NOSETTLE_MARKER` mechanics). Expected initial markers (~3, VERIFY on a fresh census): `grab`
  (hand-rolled gesture settle — dispatcher owns sequential settles by design), `newParentChoice` +
  `newParentChoiceWithHorizLayout` (documented idempotent re-fit flush after `@add`).
- **Rationale it generalizes:** rule [C] (geometry-setter → geometry-setter) is the special case.
- **Ratchet type:** none — lands green with markers, HARD from day one.

### 4.2 Rule [S] — a private method must not self-call a public COMMAND (count-ratchet → HARD)

- **Where:** a NEW gate `buildSystem/check-call-separation.js`, because it needs the census engine (chain
  resolution + the forward @-self effect closure), which is heavier than the line-scanner idiom of
  `check-layering.js`. **T0 refactors the census** so the engine is importable
  (`module.exports = { runCensus }` + `if (require.main === module)` CLI guard) and the gate `require`s it —
  one engine, two entry points (census = report; gate = thresholds). Wire into `build_it_please.sh` with the
  standard block (§8 of the lint doc), behind `if ! $noSyntaxCheck`.
- **Subject:** every R1 site whose callee classifies SETTLING or EFFECTFUL (QUERY and REACT-VERB —
  `changed`/`fullChanged` — are expressly allowed; that is the command/query cut of §1).
- **Mechanism:** inline **count baseline** (the `check-stinks.js` idiom): FAIL when the hard-site count
  EXCEEDS the baseline; print a tighten-the-baseline reminder when below. Two counters, ratcheted
  separately: `SETTLING` (start = current count, drive to **0 within T2**, then it is a hard sub-rule) and
  `EFFECTFUL` (start ≈ 82, tranches drive it down; flip to 0/HARD at end of T3).
- **Marker:** `# public-call-sanctioned: <why>` — a marked site is excluded from the count (the census must
  learn the marker too, so tool and gate agree). Use sparingly: for genuinely dual-use callees the DEFAULT
  fix is rename or twin-split, not blessing (§5 rubric).
- **Soundness note for the gate's docs:** classification is per-(class,method), chain-resolved
  (own → mixins → `extends` ancestors), with a name-level fallback for unresolved callees; dynamic dispatch
  stays invisible (the runtime one-flush throw remains the backstop, as for [G]).

### 4.3 Rule [U] — a public method referenced only by `@`-self must be `_`-tier (count-ratchet + allowlist)

- **Where:** same new gate (`check-call-separation.js`), reusing the census R4 harvest. Requires the sibling
  `Fizzygum-tests` repo — SELF-SKIP (not fail) when absent, exactly like `check-dead-methods.js`.
- **Subject:** the R4 candidate set (self > 0, member == 0, other == 0 [bare-or-string], external == 0).
  A name in a string can be dispatch — it disqualifies; harness/macro refs disqualify. This construction has
  a pleasant property: **renaming a candidate cannot break any test except an inspector member-list
  screenshot** (benign recapture) — nothing external references it, by definition.
- **Mechanism:** count baseline (94 EFFECTFUL / 151 QUERY at snapshot), fails only on EXCEEDING (a NEW
  self-only public method), like the dead-method gate fails only on NEW dead.
- **Allowlist:** `buildSystem/public-api-allowlist.txt` (name + one-line reason) for methods that are
  **deliberate end-user API** despite zero code references — Fizzygum is a live-editable system; a method can
  exist for a user to call from the in-world Object Inspector / scripting. This is an OWNER-TRIAGE decision
  per name (§7-1), the same "intentional public API" concept `dead-method-allowlist.txt` already encodes.

---

## 5. Disposition rubric (how to fix each hard callee)

Decide per CALLEE (not per site), using the census shortlist's ref profile `refs[self/member/other/ext]`:

1. **`member == 0 && other == 0 && ext == 0`** (pure-internal) → **RENAME to `_<name>`** (or `__` if it is a
   true leaf per rule [I] — e.g. `markLayoutAsFixed` is a bare flag write). Sweep: def(s) + all `@`-self
   sites + any same-name subclass overrides (dynamic dispatch: the WHOLE override family must rename
   together) + `dead-method-allowlist.txt` if listed + doc mentions (grep the name across `docs/`).
2. **`ext > 0` or heavy `member`** (genuine dual-use API: macros/harness or many cross-object callers) →
   **KEEP public**; for the private call sites either (a) **twin-split**: create the `_<name>NoSettle`-style
   core (public wrapper must then satisfy `check-thin-wraps.js` — the canonical one-liner wrap), and re-point
   private callers at the core, or (b) **bless** the site with `# public-call-sanctioned: <why>` when the
   callee is a trivial settle-free property setter and a split adds nothing (e.g. `disableDrops`).
3. **`other > 0` only** (name appears in a string / bare identifier) → INVESTIGATE first: if the string is
   menu/connection dispatch, the name is de-facto public protocol → treat as dual-use (2). If the string is a
   comment-like artifact, treat as (1).
4. **Vestigial** (empty hooks, dead paths) → **DELETE** (PromptWdgt/SaveShortcutPromptWdgt `buildSubwidgets`).

**PROVISIONAL per-callee dispositions** (from the §App-B table; verify each at execution — read the method
before renaming): rename-tier-1 candidates: `markLayoutAsFixed`, `createAndAddEditButton`, `setToggleState`,
`createLinkIcon`, `createNewBehindTheScenesBuffer`, `createNewFrontFacingBuffer`, `paintImage`,
`setAppearanceAndColorOfTitleBackground`, `buildTitlebarBackground`, `initVirtualKeyboard`,
`synchroniseTextAndActualText`, `addChild` (TreeNode), `buildAndConnectObjOwnPropsButton`,
`updateHandlePosition`, `freeFromRatioConstraints`, `moveInFrontOfSiblings`, `resetSwitchButton`,
`rememberFractionalPositionInHoldingPanel`, `constrainToRatio`. Dual-use (split-or-bless): `show`,
`setColor`, `disableDrops`, `enableDrops`, `bringToForeground`, `removeShadow`, `mouseLeave` (event
protocol), `updatePopUpShadow`, `resetToDefaultContents`, `recommitAllCells`, `reflowText`,
`recordDrawnAreaForNextBrokenRects`. Owner-triage (ambiguous): `rememberFractionalSituationInHoldingPanel`
(48 member sites — rename is mechanical but wide), `clearSelection`, `setLayoutSpec`, `unlockFromPanels`,
`createLabel`, `hideUsedWidgets`/`showAllWidgets` (menu-string dispatched? check the `other` ref).

---

## 6. Execution tranches

Each tranche ends: `./fg build` green (all gates) + `./fg suite` green (196/196; benign inspector
member-list recaptures allowed and expected on renames of inspected classes — recapture via
`./fg recapture <test>`) → present commit summary to owner → owner approves → commit. Run `./fg gauntlet`
at T2 and T5 ends. NEVER push without explicit owner approval.

- **T0 — tooling (pure tooling, zero behaviour change).**
  1. Refactor `census-public-private-calls.js` into engine + CLI (§4.2); add marker awareness
     (`# public-call-sanctioned` subtracts a site; report marked counts separately).
  2. Add rule [T] to `check-layering.js`; place the ~3 markers; self-test (plant `src/__X.coffee` with a
     `_settleLayoutsAfter` + `@add` body → expect [T]; marker → pass; delete fixture).
  3. Build `check-call-separation.js` ([S] baselines SETTLING=2, EFFECTFUL=82 — or fresh census values;
     [U] baselines 94/151; `public-api-allowlist.txt` seeded empty); wire into `build_it_please.sh`;
     self-test both directions.
  4. Document: new rows in `docs/architecture/lint-and-static-checks.md` §3 gate table + §4 rules; note the census tool
     in its §3; add both to the §Appendix anchors. (A See-also pointer to this plan already exists.)
- **T1 — the `markLayoutAsFixed` rename.** `_markLayoutAsFixed`: def in `Widget.coffee` (+ any override —
  grep `markLayoutAsFixed:` across src), 33 `@`-self sites, the member call + comment in `WorldWdgt`'s
  settle loop (grep; it sits in the layout-convergence error path), any doc mentions. Tighten [S] EFFECTFUL
  baseline 82→~49. Suite: expect possible benign member-list recaptures only.
- **T2 — close the two demonstrated evasions + delete vestigial hooks.** (a) StretchableEditable family:
  make the panel (re)builder a non-settling core (`_createNewStretchablePanelNoSettle` using `@_addNoSettle`)
  across the base + 4 app overrides; re-point the two private callers; keep/restore public behaviour where a
  public entry is genuinely needed (verify: the callback path relies on the dispatcher's settle — rule [J]).
  (b) ColorPickerWdgt: fold `buildSubwidgets` into the canonical ctor pattern
  (`@_buildAndConnectChildren()` wrapper + `_buildAndConnectChildrenNoSettle` core with `@_addNoSettle`) —
  this also un-evades `check-constructors-build.js`. (c) Delete the empty `buildSubwidgets` hooks + their
  `_reLayoutSelf` call sites in `PromptWdgt`/`SaveShortcutPromptWdgt`. Tighten [S] SETTLING baseline → 0
  (**HARD from here**). NB (a)/(b) change construction order around settles — watch the suite closely; if a
  screenshot diff is NOT a benign member-list, STOP and re-read
  `docs/archive/all-constructors-settle-plan.md` before proceeding.
- **T3 — drain the remaining EFFECTFUL callees** per the §5 rubric (~36 callees, ~49 sites), in 3–5 commits
  grouped by family (WindowWdgt chrome; StretchableCanvas buffers; ratio-constraint family; text/caret;
  misc). Tighten the baseline after each group; at 0, flip [S] EFFECTFUL to HARD. Owner-triage names (§5)
  get decided here, not unilaterally.
- **T4 — owner triage pass over R4** (one sitting, list in §App-D/E): mark deliberate end-user API into
  `public-api-allowlist.txt` (with reasons); everything else is confirmed rename-fodder.
- **T5 — privatization drawdown.** Rename the confirmed EFFECTFUL candidates (94 minus allowlisted) in
  batches of ~10–15 (one commit each, suite per batch — remember: by construction these renames can only
  produce benign recaptures); tighten the [U] baseline per batch. QUERY candidates (151) are OPTIONAL /
  opportunistic — rename when already touching the file (`oval`→`_oval` etc.); no dedicated sweep unless the
  owner wants one.

**Rename mechanics (every rename, without exception):** grep the OLD name across `src/**/*.coffee`,
`docs/**`, `buildSystem/dead-method-allowlist.txt`, AND `../Fizzygum-tests/` (harness + `tests/**/*.js`) —
zero stragglers (macro `.js` references would break at the test-syntax gate or, worse, silently — rule [D]
forbids `_` calls in macros, so a macro-referenced name must NOT be renamed to `_`; that is exactly what the
R4 `external == 0` precondition guarantees). Then `./fg build` (the dead-method gate will also catch a
half-done rename) + `./fg suite`.

---

## 7. Gray areas — owner decision points (do NOT decide these unilaterally)

1. **Inspector-facing API.** A self-only public method may be deliberate surface for live in-world use.
   Only the owner can assert intent → T4 triage gates T5. Default when unsure: leave public, allowlist.
2. **Trivial property setters** (`disableDrops`/`enableDrops`, …): bless-in-place vs twin-split. Blessing
   keeps noise down; splitting is more uniform. Recommendation: bless (they are settle-free one-liners),
   revisit only if one ever gains a settle.
3. **`rememberFractionalSituationInHoldingPanel`** (+ sibling): 48 cross-object `.member` call sites —
   framework-internal but wide. Rename (mechanical, zero-behaviour) vs bless. Recommendation: rename.
4. **Event-protocol methods** (`mouseLeave` et al.): public by pointer-dispatch protocol; the single private
   self-call site is the anomaly — reshape the caller rather than the protocol.
5. **QUERY-tier renames (R4's 151)**: cosmetic; a dedicated sweep is churn vs consistency. Recommendation:
   opportunistic only.

---

## 8. Rejected alternatives (with the evidence — do not re-litigate without new facts)

- **R1-literal: "warn when a method mixes public+private self-calls"** (the original phrasing). Measured:
  216 methods, but the mixing is overwhelmingly with public QUERIES (483/622 private→public sites are
  queries; only 78/216 mixed methods involve any public command). The command/query cut ([S]) captures all
  the signal with none of that noise.
- **Blanket "public must not call public".** The dispatcher pattern — a public event entry delegating to one
  settling command per event (`processKeyDown`→`goLeft`, `closeButtonInBarPressed`→`close`) — is the
  DESIGNED shape (one settle per logical event; see the notification-grid convention §3). 84 of the 93 R2
  sites are this pattern. Only the narrowed double-flush shape ([T]) is enforceable.
- **Backward transitive closure for [G]** — previously prototyped and REJECTED
  (`docs/architecture/lint-and-static-checks.md` §7, ~500–710 false hits). Unchanged. The census's *forward, @-self-only*
  closure is a different, convergent computation (2 hits) — that distinction is load-bearing; preserve it in
  any gate work.
- **Making [S] a per-site marker rule from day one.** 84 unmarked sites on day one = 84 markers of pure
  ceremony. The stinks-style count ratchet reaches the same end state (0 + HARD) without the noise; markers
  exist only for the end-state residuals.

---

## 9. Risks

- **Screenshot recaptures.** Method renames on classes whose Object Inspector appears in reference
  screenshots change the drawn member list → benign recapture (standing owner policy: acceptable; verify the
  diff IS just the member list before recapturing). No other pixel effect is expected from pure renames.
- **Serialization / dependency discovery are rename-safe** (`docs/architecture/layering-naming-convention.md` §6: the
  dependency finder scans `extends`/`@augmentWith`/`new`, not method names; `DeepCopierMixin` copies data).
- **Override families.** Renaming a polymorphic name in the base but not a subclass override silently forks
  the protocol — the dead-method gate catches the orphaned override, but grep the whole family FIRST.
- **Concurrent arcs.** The tree carries in-flight work (affine §7.x etc.). Re-census before each tranche;
  coordinate if a touched file is hot.
- **T2 is the only tranche with real behaviour-adjacent risk** (construction/settle order around
  StretchableEditable + ColorPicker); it is deliberately small and heavily suite-checked.

---

## 10. Execution ledger (update as you go)

| Item | Status |
|---|---|
| Census tool `buildSystem/census-public-private-calls.js` | ✅ LANDED 2026-07-12 (uncommitted) |
| T0 gate work ([T] in check-layering; new check-call-separation; docs) | ✅ DONE 2026-07-12 — census refactored to engine+CLI (`runCensus` export, marker-aware); [T] in check-layering (3 sites found = the 3 predicted, all marked `# double-settle-sanctioned`); `check-call-separation.js` wired into build ([S] baselines 2/81, [U] 92/152 + empty `public-api-allowlist.txt`); both self-tested (plant→fail, marker/allowlist→pass, clean→green); lint doc updated (gate row, [T] rule row, 2 marker rows, census paragraph, appendix). Fresh-census note: baselines re-seeded from the 2026-07-12 post-ctor-arc tree (SETTLING 2 / EFFECTFUL 81 / U 92+152). |
| T1 `_markLayoutAsFixed` rename | ✅ DONE 2026-07-12 — 34 src refs (def + 30 sites + WorldWdgt settle-loop member call + comments) + `layout-system-architecture-assessment.md` sync; [S]-EFFECTFUL 81→51. Suite: only the predicted benign inspector member-list test red (recaptured at arc end). |
| T2 evasion closures + vestigial deletions; [S]-SETTLING → 0 HARD | ✅ DONE 2026-07-12 — (a) `_createNewStretchablePanelNoSettle` core (base `@_addNoSettle`; 3 byte-identical app overrides DELETED — SimpleSlide/PatchProgramming/Dashboards; ReconfigurablePaint's genuinely-different override converted); **`Widget.pickUp` now OWNS the callback settle** (`@_settleLayoutsAfter => oldParent?._reactToChildPickedUp?` — the `_reactToChildGrabbed` twin; without it the settle-neutral core would ride the end-of-cycle flush undeclared). (b) ColorPickerWdgt: found ALREADY converted upstream (menu/slider ctor-conversion arc, same day). (c) PromptWdgt + SaveShortcutPromptWdgt vestigial empty `buildSubwidgets` hooks + their `_reLayoutSelf: -> super()` shells DELETED. [S]-SETTLING 2→0 HARD. Suite 242/243 (same benign test only). |
| T3 EFFECTFUL drain; [S]-EFFECTFUL → 0 HARD | ✅ DONE 2026-07-12 — **27 renames to `_`-tier** (resetToDefaultContents, createAndAddEditButton, setAppearanceAndColorOfTitleBackground, buildTitlebarBackground, rememberFractional{Situation,Position,Extent}InHoldingPanel, moveInFrontOfSiblings, addChild, unlockFromPanels, setLayoutSpec, initVirtualKeyboard, recordDrawnAreaForNextBrokenRects, synchroniseTextAndActualText, createLabel ×3-defs, resetSwitchButton, setToggleState, updateHandlePosition, createLinkIcon, createNewBehindTheScenesBuffer, createNewFrontFacingBuffer, paintImage, buildAndConnectObjOwnPropsButton, constrainToRatio, freeFromRatioConstraints, updatePopUpShadow, recommitAllCells — all pre-screened: zero macro-code refs, zero dispatch strings) + **18 sites marked `# public-call-sanctioned`** on genuinely dual-use verbs (button-action strings hideUsedWidgets/showAllWidgets; event-protocol mouseLeave; macro-called reflowText/enableDrops/disableDrops/getContextForPainting; window-bar protocol showEdit/ViewModeInBar; heavy public show/setColor/bringToForeground/clearSelection/removeShadow) + census REACT_VERBS += `fullChangedIncludingShadowOwner` (the shadow-aware react verb). [S]-EFFECTFUL 51→**0 HARD**; side effect [U]-EFFECTFUL 91→76. |
| T4 owner R4 triage → `public-api-allowlist.txt` | ✅ DONE 2026-07-12 (interactive) — owner accepted all four recommendations: internals→RENAME; caret verbs SPLIT (internals rename, goHome/goEnd/deleteLeft/deleteRight/setSoftWrap allowlist); protocol hooks (recalculateOutput/reactToTargetConnection/paintFunction) ALLOWLIST; user-API set (setHeading/unTouch/setMouse+TouchInputMode/toggleVisibility/saveScript/setProgram) ALLOWLIST. |
| T5 verification postscript 2 — the SELF-INFLICTED detour (honest record) | ⚠ During the AddEdit crash diagnosis, a scratch instrumentation `perl -pi` insert (6-space pattern, no `^` anchor) silently DE-INDENTED two deeper-indented `@_softResetWorld()` calls in `WorldWdgt.coffee` out of their `catch` blocks — the world then soft-reset (hand.drop) on normal repaint-recovery paths → a 131/243 mass-red suite masquerading as nondeterminism, and several tainted diagnosis rounds (probes ran against the corrupted build). Found by mtime-scanning src against the last green build era + hunk-by-hunk diff; fixed by restoring the two indents. LESSONS: never unanchored-perl an indentation-significant file (use exact-string edits); after add AND remove of instrumentation, verify `git diff`; mass-red with "identical" src ⇒ distrust the BUILD first. The ORIGINAL AddEdit crash (pre-corruption) was real and owner-diagnosed — see the row below. AddEdit refs re-captured against the healthy build. |
| T5 verification postscript | ✅ `macroAddEditSaveRenameRemoveProperty` needed a tests-repo ROBUSTNESS fix (owner-diagnosed: member-list changes can crash this macro): `calculateVertBarMovement` is TOP-relative, so the test's retry-loop scroll depended on interaction history — the rename-shifted member count flipped attempt counts, broke its round-trip byte-identity assertion, and at worst clicked a scrolled-out row whose centre hit the hierarchy "Widget" box (opening a Class Inspector over everything → the `getTextMenuItemFromMenu undefined` crash). Fixed in the test's own subroutine: top-anchor before each drag + only click rows inside the list clip. Verified green ×2 dprs. ⚠ FOR FUTURE RENAME BATCHES: a red inspector-churn test can be a CRASH, not just member-list pixels — set-membership alone is not sufficient triage; the recapture flow's STUCK-STATE CANARY is the tell. |
| T5 privatization drawdown ([U] ratchet) | ✅ DONE 2026-07-12 — **53 renames** (incl. the setHiglightedColor→_setHighlightedColor typo fix and 2 execution-added: calculateHandsAngles, updateDimension) + **23 allowlist entries** (15 triage + 8 structural, below) + ~9 new `# public-call-sanctioned`/`# nosettle-sanctioned` markers on second-order sites. [U]-EFFECTFUL 76→**0 HARD**; [U]-QUERY 151→150. **Census harvest FIXED** (maskLine string-awareness): a `Macro.fromString` heredoc calling `@toolkitVerb` had classified as a SELF-call, letting 2 macro-surface verbs into the rename list (caught by rule [D] — un-renamed). **Execution finding — the [A]-collision rule (add to any future triage):** a public method whose body drives the public settling API on OTHER widgets (member-form `.setText`/`.setExtent`/`.add…`) CANNOT take the `_`-form — rule [A]/[G] then bans its own body and [A] has no marker; such names stay public via the allowlist: addText, updatePatternsMenuEntriesTicks, createErrorConsole, addDragAffordanceWidgets, bringTextAndCaretToState, createWidgetToBeHandled, + the process* dispatch family (processDoubleClick/processTripleClick — mis-bucketed as memory helpers, actually dispatcher surface). |

---

## Appendix A — R1 SETTLING sites (snapshot 2026-07-12; the [G] one-hop blind spot)

```
StretchableEditableWdgt._buildAndConnectChildrenNoSettle -> @createNewStretchablePanel   StretchableEditableWdgt.coffee:~202
StretchableEditableWdgt._reactToChildPickedUp            -> @createNewStretchablePanel   StretchableEditableWdgt.coffee:~209
```

## Appendix B — R1 hard-callee shortlist (39 callees, 84 sites; refs = self/member/other/external)

```
 33  markLayoutAsFixed                          Widget                       34/1/0/0
  3  resetToDefaultContents                     WindowWdgt                    3/0/0/4
  3  constrainToRatio                           StretchableEditable/3DPlot/KeepsRatioMixin  3/1/0/0
  3  freeFromRatioConstraints                   3DPlot/KeepsRatioMixin        3/0/0/0
  2  createNewStretchablePanel                  StretchableEditable + 4 app overrides       2/0/0/0
  2  createAndAddEditButton                     WindowWdgt                    2/0/0/0
  2  rememberFractionalSituationInHoldingPanel  Widget                        2/48/0/0
  2  disableDrops                               Widget                        7/29/0/16
  2  show                                       Widget                        4/14/13/119
  2  recommitAllCells                           SpreadsheetWdgt               2/0/0/1
  2  setToggleState                             ToggleButtonWdgt              2/0/0/0
  1  hideUsedWidgets / showAllWidgets           BasementWdgt                  1/0/1/0 each
  1  moveInFrontOfSiblings                      Widget                        1/1/0/0
  1  createLabel                                LabelButton/MenuItem/Menu     2/0/0/1
  1  mouseLeave                                 Handle/LabelButton/Droplet    1/1/1/6
  1  updatePopUpShadow                          PopUpWdgt                     2/0/0/4
  1  createLinkIcon                             SimpleLink/SimpleVideoLink    1/0/0/0
  1  createNewBehindTheScenesBuffer             StretchableCanvasWdgt         2/0/0/0
  1  createNewFrontFacingBuffer                 StretchableCanvasWdgt         3/0/0/0
  1  paintImage                                 StretchableCanvasWdgt         1/0/0/0
  1  resetSwitchButton                          SwitchButtonWdgt              1/1/0/0
  1  setAppearanceAndColorOfTitleBackground     WindowWdgt                    2/0/0/0
  1  buildTitlebarBackground                    WindowWdgt                    1/0/0/0
  1  recordDrawnAreaForNextBrokenRects          Widget                        3/0/0/2
  1  setColor                                   GlassBoxTop/HolderWithCaption/PanelWdgt     20/50/3/61
  1  initVirtualKeyboard                        WorldWdgt                     1/0/0/0
  1  enableDrops                                Widget                        2/1/0/7
  1  reflowText                                 StringWdgt/TextWdgt           7/0/0/6
  1  clearSelection                             StringWdgt                    5/5/0/0
  1  synchroniseTextAndActualText               StringWdgt                    2/0/0/0
  1  rememberFractionalPositionInHoldingPanel   Widget                        2/1/0/0
  1  bringToForeground                          Widget                        13/10/0/13
  1  addChild                                   TreeNode                      1/0/0/0
  1  unlockFromPanels                           Widget                        1/2/0/0
  1  setLayoutSpec                              Widget/InspectorWdgt          1/3/0/1
  1  removeShadow                               Widget                        2/1/0/1
  1  buildAndConnectObjOwnPropsButton           ClassInspector/Inspector      1/0/0/0
  1  updateHandlePosition                       SliderWdgt                    1/0/0/0
```
(Per-site listing: `node ./buildSystem/census-public-private-calls.js --full`, section "R1 EFFECTFUL sites".)

## Appendix C — R2 narrowed (9 sites; expected [T] baseline, all conscious)

```
ActivePointerWdgt.grab          -> @add                                     (hand-rolled gesture settle — documented)
WorldWdgt.doOneCycle            -> @showErrorsHappenedInRepaintingStepInPreviousCycle, @showLayoutErrorsFromPreviousCycle,
                                   @playQueuedEvents, @runChildrensStepFunction, @addPinoutingWidgets, @addDragAffordanceWidgets
                                   (the frame driver — RECALC_WHITELIST member, exempt as [T] subject)
Widget.newParentChoice          -> @add    (documented deliberate idempotent extra flush)
Widget.newParentChoiceWithHorizLayout -> @add   (ditto)
```

## Appendix D — R4 EFFECTFUL privatization candidates (94, snapshot; ✻ = also in App-B)

pushBrokenRect(7) · createRefreshOrGetBackBuffer(6) · softResetWorld(6) · addAndTrackHandle(5) ·
renderingHelper(4) · createErrorConsole(4) · paintNewFrame(4) · updateColor(4) · buildSubwidgets(3) ·
createWidgetToBeHandled(3) · createNewFrontFacingBuffer(3)✻ · fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow(3) ·
setHiglightedColor(3) · freeFromRatioConstraints(3)✻ · calculateNewPlotValues(3) · rememberClickGesture(3) ·
recalculateOutput(3) · forgetDoubleClickWdgts(2) · rememberDoubleClickWdgtsForAWhile(2) · forgetTripleClickWdgts(2) ·
unTouch(2) · setMouseInputMode(2) · setSoftWrap(2) · createNewBehindTheScenesBuffer(2)✻ · createNewStretchablePanel(2)✻ ·
setToggleState(2)✻ · updatePatternsMenuEntriesTicks(2) · setAppearanceAndColorOfTitleBackground(2)✻ ·
createAndAddEditButton(2)✻ · mergeBrokenRectsIfCloseOrPushBoth(2) · syncRenderCanvasToWorldCanvas(2) ·
queueErrorForLaterReporting(2) · hideOffendingWidget(2) · adjustAccordingToTargetText(2) · bringTextAndCaretToState(2) ·
deleteLeft(2) · paintImageOnBackBuffer(2) · synchroniseTextAndActualText(2)✻ · setFittingFontSize(2) ·
syntheticEventsConsecutiveLeftClicks_InputEvents(2) · rememberTripleClickWdgtsForAWhile · processDoubleClick ·
processTripleClick · addText · reactToTargetConnection · setHeading · markPopUpForClosure · setTouchInputMode ·
saveScript · createLinkIcon✻ · paintImage✻ · fullPaintIntoAreaOrBlitFromBackBufferJustShadow · buildTitlebarBackground✻ ·
makePrettier · fleshOutBroken · findOutAllOtherOffendingWidgetsAndPaintWholeScreen · resetDataStructuresForBrokenRects ·
addDragAffordanceWidgets · playQueuedEvents · showErrorsHappenedInRepaintingStepInPreviousCycle ·
showLayoutErrorsFromPreviousCycle · updateTimeReferences · runChildrensStepFunction · stepWidget ·
sizeCanvasToTestScreenResolution · initVirtualKeyboard✻ · initMouseEventListeners · initTouchEventListeners ·
initKeyboardEventListeners · initClipboardEventListeners · initOtherMiscEventListeners · addChild✻ · goHome · goEnd ·
ctrl · deleteRight · setNormalColor · updateHandlePosition✻ · setEndMark · disableSelecting · nextSteps ·
rememberFractionalExtentInHoldingPanel · toggleVisibility · removeOutgoingEdgesOf · ensureEngine · renderScene ·
commonPrimitiveDrawingLogic · setProgram · paintFunction · syntheticEventsMousePlace_InputEvents ·
bringListItemFromTopInspectorInView_InputEvents · clickOnListItemFromTopInspector_InputEvents ·
buildAndConnectObjOwnPropsButton✻ · parseVideosIndex

(NB `doOneCycle`-driven names — `playQueuedEvents`, `runChildrensStepFunction`, `stepWidget`, the `init*EventListeners`
family, broken-rect machinery — are WorldWdgt frame internals: prime rename material. The CaretWdgt keyboard verbs
(`goHome`/`goEnd`/`ctrl`/`deleteRight`/`deleteLeft`) are self-only TODAY but are conceptually the keyboard-command
protocol — triage with the owner before renaming. QUERY candidates (151) — regenerate with `--full`; headline:
`oval`(141) · `deduplicateSettersAndSortByMenuEntryString`(24) · `updateSelection`(18) · `doesTextFitInExtent`(14) ·
`buildCanvasFontProperty`(8) · `calculateTextWidth`(8) · `firstChildSuchThat`(7) · …)

## Appendix F — T4 TRIAGE WORKSHEET (post-T3 snapshot: 76 EFFECTFUL [U]-candidates) — ✅ TRIAGED + EXECUTED 2026-07-12

Owner accepted all recommendations (interactive triage); T5 executed them. DEVIATIONS found at execution
(the ledger row records them in full): 10 of the 61 planned renames REVERTED to public + allowlisted —
2 macro-heredoc-called toolkit verbs (rule [D]; census harvest since fixed), 6 whose bodies drive the
public settling API on other widgets (the [A]-collision rule — [A] has no marker), and the 2 process*
dispatchers (mis-bucketed). Historical worksheet below, kept as the triage record.

- **WorldWdgt frame/repaint/boot internals — recommend R (all):** pushBrokenRect(7) · softResetWorld(6) ·
  createErrorConsole(4) · mergeBrokenRectsIfCloseOrPushBoth(2) · syncRenderCanvasToWorldCanvas(2) ·
  queueErrorForLaterReporting(2) · hideOffendingWidget(2) · makePrettier · fleshOutBroken ·
  findOutAllOtherOffendingWidgetsAndPaintWholeScreen · resetDataStructuresForBrokenRects ·
  addDragAffordanceWidgets · playQueuedEvents · showErrorsHappenedInRepaintingStepInPreviousCycle ·
  showLayoutErrorsFromPreviousCycle · updateTimeReferences · runChildrensStepFunction · stepWidget ·
  sizeCanvasToTestScreenResolution · initMouse/Touch/Keyboard/Clipboard/OtherMiscEventListeners (×5).
- **ActivePointerWdgt click-recognition memory — recommend R:** forgetDoubleClickWdgts(2) ·
  forgetTripleClickWdgts(2) · rememberDoubleClickWdgtsForAWhile(2) · rememberTripleClickWdgtsForAWhile ·
  processDoubleClick · processTripleClick.
- **MacroToolkit L1/L2 helpers — recommend R:** rememberClickGesture(3) ·
  syntheticEventsConsecutiveLeftClicks_InputEvents(2) · syntheticEventsMousePlace_InputEvents ·
  bringListItemFromTopInspectorInView_InputEvents · clickOnListItemFromTopInspector_InputEvents.
- **Paint/buffer internals — recommend R:** createRefreshOrGetBackBuffer(6, 4 classes) · paintNewFrame(4, 2
  classes) · renderingHelper(4, many appearances) · commonPrimitiveDrawingLogic ·
  fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow(3) /
  fullPaintIntoAreaOrBlitFromBackBufferJustShadow (paint-pipeline pair) · paintImageOnBackBuffer(2) ·
  updateColor(4, HighlightableMixin) · setHiglightedColor(3) / setNormalColor (SliderButtonWdgt pair; note the
  typo — a rename could fix "Higlighted"→"Highlighted" in passing) · addAndTrackHandle(5, Widget).
- **CaretWdgt/StringWdgt editing verbs — OWNER CALL (conceptually the keyboard/selection command surface, but
  provably self-only today):** goHome · goEnd · ctrl · deleteLeft(2) · deleteRight · adjustAccordingToTargetText(2) ·
  bringTextAndCaretToState(2) · setEndMark · disableSelecting · setFittingFontSize(2) · setSoftWrap(2,
  SimplePlainTextWdgt) — recommend R for the internals (adjust*/bringTextAndCaretToState/setFittingFontSize),
  **A** for the user-verb-shaped ones (goHome/goEnd/deleteLeft/deleteRight/setSoftWrap) if you consider them
  inspector/scripting surface.
- **Protocol-shaped hooks — OWNER CALL:** recalculateOutput(3, patch nodes — the reactive recompute verb; [Q]
  allowlists it as a connector caller) · reactToTargetConnection(many classes — connection protocol) ·
  paintFunction(icon appearances — the polymorphic paint hook) — recommend **A** (protocol names, likely to gain
  dynamic callers) or defer.
- **User-facing-shaped API — recommend A:** setHeading (PenWdgt — turtle API) · unTouch(2, MouseSensorWdgt) ·
  setMouseInputMode(2)/setTouchInputMode (PreferencesAndSettings) · toggleVisibility (Widget) · saveScript
  (ScriptWdgt) · setProgram (LCLProgramRunner).
- **Misc internals — recommend R:** calculateNewPlotValues(3) · createWidgetToBeHandled(3, creator buttons) ·
  updatePatternsMenuEntriesTicks(2, Wallpaper) · addText (ErrorsLogViewerWdgt) · markPopUpForClosure (PopUpWdgt) ·
  ensureEngine / renderScene (FridgeMagnets3DCanvasWdgt) · parseVideosIndex (VideoPlayerWithRecommendationsWdgt) ·
  removeOutgoingEdgesOf (DataflowEngine) · nextSteps (Widget).

## See also

- `docs/architecture/lint-and-static-checks.md` — the gate system this plan extends (rules [A]–[R], markers, ratchets, how-to).
- `docs/architecture/layering-naming-convention.md` — the tier scheme (`_`/`__`/NoSettle) and why names are load-bearing.
- `docs/archive/layout-system-architecture-assessment.md` — the one-flush invariant (the *why* behind [S]/[T]).
- `docs/archive/all-constructors-settle-plan.md` — the ctor pattern T2(b) folds ColorPickerWdgt into.
- `docs/archive/lint-ratchet-static-checks-plan.md` — the rejected backward-transitive record (§8 boundary here).
