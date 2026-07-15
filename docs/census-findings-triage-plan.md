# Hierarchy/property census findings — remaining triage

**STATUS: AUTHORED 2026-07-15 — not started.** Written to be executed **cold, by an LLM with zero
prior context**: everything needed is embedded or pointed at by absolute path.

**What this is.** The two advisory censuses added by the Pharo generic-rules carryover
(`docs/lint-generic-rules-carryover-plan.md`, EXECUTED 2026-07-15) still report findings. Tranches
A/B/C took every finding that was both provable and free (commits `83209869`, `3d038959` — 9 no-op
overrides + 1 field). **This plan owns what is left**, and every remaining item costs something: a
risk class, or an inspector recapture, or both. Nothing here is a sweep.

**Prior art you must read first** (do not re-derive it):
- `docs/done/duplication-triage-2026-07-15-hierarchy-round4.md` — the CLOSED round-4 record and its
  **9 pieces of case law**. Read this before touching any finding.
- `docs/lint-and-static-checks.md` §3b (severity policy) / §3c (the censuses, and why neither can
  ever be a gate).

---

## 0. Cold-start orientation (non-negotiable)

- Umbrella `/Users/davidedellacasa/code/Fizzygum-all/` is **NOT a git repo**; it holds sibling repos
  `Fizzygum/` (source — the only repo this plan commits to), `Fizzygum-tests/`, `Fizzygum-builds/`
  (generated; never edit; never grep from the root — `latest/` is ~1.3 GB).
- **Absolute paths everywhere**; the shell's cwd is unreliable across tool calls. Invoke the wrapper
  as `/Users/davidedellacasa/code/Fizzygum-all/fg <cmd>` (never `./fg`). `fg` is LOCAL tooling,
  committed to no repo.
- Long runs (`fg gauntlet` ~4.5 min, `fg presuite` ~3.5 min): launch ONCE with the Bash tool's
  `run_in_background: true`, redirect to a log, read `/tmp/fg-<cmd>.verdict`. **Never** foreground-poll
  with sleep loops (a guard hook blocks them). Never pipe an fg call whose exit code gates a decision.
- ⚠ **Do not edit source after launching a gauntlet** — its build happens at start, so later edits
  make the run test stale source (the build-freshness stamp will reject the runners). This bit once.
- **Never commit or push autonomously.** Present a summary + proposed message and WAIT. Backticks
  corrupt commit messages through the Bash tool — use `git commit -F <file>`.
- Re-orient any time: `/Users/davidedellacasa/code/Fizzygum-all/fg status`.

### Run the censuses (from `Fizzygum/`; ~0.5 s each, advisory, exit 0)

```sh
node ./buildSystem/census-hierarchy-duplication.js [--full] [--json out.json]
node ./buildSystem/census-property-placement.js    [--full] [--json out.json]
/Users/davidedellacasa/code/Fizzygum-all/fg critique     # both + every ratchet's "tighten me" note
```

### Baseline at plan-authoring time (2026-07-15, after Tranche A/B/C, at `3d038959`)

| Report | Count |
|---|---|
| IDENTICAL-TO-INHERITED | **1** |
| SHADOWS-MIXIN / JUST-SENDS-SUPER | 0 / 0 |
| PULL-UP | **10** (7 same-default; 9 of 10 `[inspector-visible]`) |
| DEMOTE | **36** (23 `[inspector-visible]`; +49 withheld by the `.name` veto) |

### The cost model you are trading against

- **`[inspector-visible]` = the class is Widget-family.** The inspector renders live member lists, so
  adding/removing a **FIELD** there churns exactly the 15-screenshot `fg recapture-inspector` set
  (~20 min, background). It is a COST to budget, not a veto — and per owner policy a benign inspector
  recapture is fine: **just recapture; never contort the code to avoid one.**
- ⚠ **Methods are free; fields are not.** Verified empirically 2026-07-15: deleting 9 methods from
  Widget-family classes produced ZERO inspector churn (gauntlet 9/9). Do NOT budget a recapture for a
  method-only change. (The pre-run assumption was the opposite and was wrong.)

---

## Phase 0 — FIX the census first: the write-only DEMOTE bug (do this before Phase 3)

**This is the highest-value item in the plan, and it is pure tooling (no `src`, no gauntlet).**

`census-property-placement.js`'s DEMOTE rule fires when every `@prop` use sits in ONE method and the
first use is an assignment. It does **not** require the property to be READ. So a **write-only**
field — assigned once, never read — is reported as "demote to a local", which is wrong twice over:
demoting a write-only field does not make it a local, it makes it **dead**; and a write-only field is
usually not dead at all, it is **enumeration payload** that no name scanner can see.

**The evidence (verify it yourself, it is decisive):** 12 of the findings are `SystemInfo.*`
(`screenWidth`, `screenHeight`, `appCodeName`, `systemLanguage`, …). They are assigned in the
constructor and never read in src — because they are read by **`JSON.stringify`**:

- `Fizzygum-tests/Automator-and-test-harness-src/SystemTestsReferenceImage.coffee:31` —
  `@hashOfSystemInfo = HashCalculator.calculateHash(JSON.stringify(@systemInfo))`
- That hash IS the `systemInfoHash` in **every reference-image filename**. Demoting those fields
  would change it and invalidate the entire committed reference set.
- `SystemTestsSystemInfo.coffee` (which `extends SystemInfo`) says it outright: *"cannot just
  initialise the numbers here cause we are going to make a JSON out of this and these would not be
  picked up"* — i.e. class-body defaults are PROTOTYPE properties and are NOT serialized; the
  constructor's `@x = …` assignments are the OWN properties that are.

**Two distinct holes this exposes — fix both:**

1. **Require a READ.** A genuine property→local needs a write AND a read. Add `uses >= 2` (or
   explicitly: at least one non-assignment occurrence) to the DEMOTE condition. **Measured
   2026-07-15: 16 of the 36 findings have exactly 1 use** ⇒ expect DEMOTE 36 → ~20, and all 12
   SystemInfo findings to vanish. Re-measure; do not trust this number.
2. **Whole-object ENUMERATION is a reach mechanism the census is blind to** — `JSON.stringify(obj)`,
   `DeepCopierMixin`'s `@[property]` walk, the serializer. The existing exclusions only see
   `.name` member reads (exclusion 3) and name-strings (exclusion 1). Document this in the census
   header as a KNOWN BLIND SPOT alongside the others, and say plainly that a **write-only field is
   presumed enumeration payload**. (Fixing hole 1 covers the known cases; do not attempt to detect
   enumeration statically — that way lies unsoundness.)

Also update the case-law file (`docs/done/duplication-triage-2026-07-15-hierarchy-round4.md`) with
this as case law 10, and re-state the new DEMOTE baseline in
`docs/duplicated-code-detection.md`'s round-4 trend table.

**Verification:** `node ./buildSystem/census-property-placement.js` (counts move), re-run
`fg critique`. No build or suite needed — `buildSystem/*.js` is not compiled into the world.

---

## Phase 1 — `BubblyAppearance.constructor` (the last IDENTICAL-TO-INHERITED) — owner-gated

`src/BubblyAppearance.coffee:3` — `constructor: (widget) -> super widget`, byte-identical to
`src/basic-widgets/BoxyAppearance.coffee:9` (`BubblyAppearance extends BoxyAppearance`).

**Deliberately LEFT by the tranche work, and the reason still stands:** it is a CONSTRUCTOR, and
constructors here are not ordinary methods —
- `src/meta/Class.coffee` **fragments and rewrites** every class at boot, and rewrites every `super`
  form (`_equivalentforSuper`); a trailing space after a bare `super` once silently dropped forwarded
  args (the reason `check-trailing-whitespace.js` exists);
- `check-constructors-build.js` governs constructor bodies;
- duplication/serialization construct through `Object.create`, not the constructor;
- there is recorded case law of a subclass-super constructor trap (`WindowWdgt` / `FolderWindowWdgt`,
  memory `accidental-complexity-reduction-plan`).

**Two lines of win against that risk class is a bad trade on its own.** Do this ONLY as part of a
constructor-focused arc that is already paying the verification cost, or if the owner explicitly wants
the IDENTICAL report driven to 0. If attempted: delete the ctor, confirm CoffeeScript's implicit
constructor forwards correctly THROUGH the meta-compiler (do not assume — the meta-compiler is the
whole risk), then `fg gauntlet`. `BubblyAppearance` renders bubble/speech-balloon chrome, so a
regression is visible: check the tooltip/menu tests.

---

## Phase 2 — PULL-UP (10) — every one costs an inspector recapture

A property declared in EVERY direct subclass of `P` but nowhere in `P` or above it. **9 of 10 are
`[inspector-visible]`, and PULL-UP moves FIELDS — so unlike the method work, these DO churn the
15-test inspector set.** Budget `fg recapture-inspector` (~20 min) per batch; batch them to pay once.

**The 5 strong candidates (same default in every subclass):**

| Property | Parent | Subclasses | Default |
|---|---|---|---|
| `color_normal` | `IconicDesktopSystemLinkWdgt` | 3/3 (`BasementOpenerWdgt`, `IconicDesktopSystemShortcutWdgt`, `IconicDesktopSystemWindowedAppLauncherWdgt`) | `Color.BLACK` |
| `color_hover` | same | 3/3 | `Color.create 90, 90, 90` |
| `color_pressed` | same | 3/3 | `Color.GRAY` |
| `setInput1IsConnected` | `PatchNodeWdgt` | 3/3 (`Calculating`/`Diffing`/`RegexSubstitution`) | `false` |
| `setInput2IsConnected` | same | 3/3 | `false` |

The 3 `IconicDesktopSystemLinkWdgt` colours are the best batch: one parent, one recapture, verbatim
defaults. ⚠ Pulling a field UP makes it INHERITED — and an inherited member is **hidden from the
inspector's default own-props view** (see the note on `Widget._popUpTargetPropertyMenu`), so the
subclasses' member lists SHRINK. That is the churn; it is benign, recapture it.

**The other 5 — weak or forbidden:**
- `videoPlayerCanvas` (2/2 of `HhmmssLabelWdgt`, default `nil`) — `video-player` family has **ZERO
  SystemTest coverage**; hand-verify by booting, or skip.
- `tempPromptEntryField` (2/2 of `MenuWdgt`, `nil`) — plausible.
- `seed` (3/3 of `GraphsPlotsChartsWdgt`) and `offset` (2/2 of `CircleBoxWdgt`) — **differing
  defaults**, the weak informational tier.
- ⛔ **`fps` (2/2 of `DataflowSource`) — DO NOT "FIX".** Documented-deliberate: the parent's own header
  says "each subclass carries only its own cadence (`fps` / …)". It correctly lands in the weak tier.
  Recorded so future rounds stop re-triaging it.
- ⛔ **`offset` on `CircleBoxWdgt` is a name COLLISION, not a shared concept** — the DEMOTE report
  independently finds `SliderButtonWdgt.offset` is a one-method local. Two unrelated same-named things.

---

## Phase 3 — DEMOTE (36 today; ~20 after Phase 0) — do Phase 0 FIRST

**Do not start here.** Phase 0 removes ~16 write-only false positives including the dangerous
SystemInfo dozen. Acting on this report before that fix risks breaking the reference-image identity.

After Phase 0, the survivors are dominated by ONE family: **a ctor-built child widget parked in a
field that only the builder ever reads** (16 constructor-scoped + 10 in
`_buildAndConnectChildrenNoSettle`) — the widget TREE already holds the reference, so the field is
redundant. `InspectorWdgt.show*On/OffButton` is the archetype. **23 are `[inspector-visible]` ⇒ one
recapture per batch.** Low value each; only worth doing as one batched sweep, if at all.

Spot-verified genuine (survive Phase 0 — they have a real read):
`VideoPlayPauseToggle.playPausePlayButton`/`playPausePauseButton` (3 uses each, `@constructor`),
`ReconfigurablePaintWdgt.mainCanvas`, `ScriptWdgt.saveTextWdgt`,
`UpperRightTriangleIconicButtonWdgt.pencilIconWdgt` (4 uses).

**The 49 WITHHELD are not a backlog** — they are findings the census cannot prove, withheld by the
`.name` member-read veto (case law 6/7). Do not "unlock" them by weakening the veto: it caught a false
positive that hand-verification had already cleared (`InspectorWdgt.textWidget` — `MacroToolkit.coffee:879`
reads it). Its cost is real and accepted: e.g. `SliderButtonWdgt.offset` IS genuinely local to
`@nonFloatDragging`, but the other `.offset` reads in src are `appliedShadow.offset` — a different
object the scanner cannot distinguish.

---

## Verification loop (per item, not per phase)

1. **READ the site first.** Textual equivalence is a CANDIDATE, never a proof (`super` is
   meta-compiled). The removability test that made every Tranche-A deletion safe: *does the subclass
   already override the CORE (or the member the parent's body late-binds to)?* If yes, the parent's
   wrapper dispatches back in unchanged.
2. Run the gates: `node ./buildSystem/check-*.js` (10 of them; all must stay exit 0).
3. `fg presuite` per item (~3.5 min) — or go straight to `fg gauntlet` (~4.5 min) for anything
   touching dispatch, since it is barely slower and covers dpr2/webkit/apps/settle/tiernaming.
4. If the 15 inspector tests churn: that is the documented benign field-change cost →
   `fg recapture-inspector`, then re-run the gauntlet.
5. Re-run the census; log the count trend in `docs/duplicated-code-detection.md`'s round-4 table and
   append the outcome to the ledger `duplication-report/triage-report.md`.
6. ⚠ The ledger is **gitignored**. When an arc closes, snapshot it into `docs/done/` per that doc's
   lifecycle rule — and add your file **by path**, never `git add docs/done/` (it holds other arcs'
   untracked files).

## Suggested order

**Phase 0 first (tooling, free, and it makes Phase 3 honest).** Then stop and re-read the reports —
Phase 0 may well leave nothing in Phase 3 worth the recapture, which is a legitimate outcome. Phase 2's
3-colour batch is the best remaining *code* win. Phase 1 stays owner-gated and probably never happens
on its own.
