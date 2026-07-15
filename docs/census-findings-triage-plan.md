# Hierarchy/property census findings — remaining triage

**STATUS: Phase 0 EXECUTED 2026-07-15 (tooling only, no `src` change). Phases 1–3 not started.**
Written to be executed **cold, by an LLM with zero prior context**: everything needed is embedded or
pointed at by absolute path.

> **Phase 0 outcome (2026-07-15).** The write-only DEMOTE bug is FIXED as **exclusion 4** in
> `buildSystem/census-property-placement.js`: a DEMOTE candidate must now have at least one
> **non-assignment** occurrence. **DEMOTE 36 → 20**, all 12 dangerous `SystemInfo` findings gone;
> PULL-UP unaffected and byte-identical; IDENTICAL unaffected (1). Verified by A/B of `--json` before
> and after: **0 findings added, 16 removed, every removal had exactly 1 use** — the candidate set was
> only re-partitioned, never gained or lost (36+49 = 20+3+62 = 85). The shared engine's `--self-test`
> passes and the `[S]/[U]` gate is unmoved (148/148). Two things were learned beyond the plan:
> - The test must be **"at least one non-assignment occurrence"**, NOT the `uses >= 2` this plan
>   proposed: `@x = 0` followed by `@x += 1` is two uses and still write-only in effect. The shipped
>   rule is the stricter one.
> - **The `.name` veto's withheld count fell 49 → 3.** It had been credited with withholding 49
>   findings when its true cost is 3 — the other 46 were write-only false positives it suppressed for
>   the wrong reason. The two exclusions now report separately so neither can hide behind the other.
>   Case law 6's example (`SliderButtonWdgt.offset`) survives as one of the real 3.
>
> **Phase 3 is now re-scoped — read its section before acting; its "~20 survivors" premise held, but
> the recapture arithmetic did not improve.**

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

### Baseline — CURRENT (2026-07-15, after Tranche A/B/C + Phase 0)

| Report | Count |
|---|---|
| IDENTICAL-TO-INHERITED | **1** (`BubblyAppearance.constructor` — Phase 1, owner-gated) |
| SHADOWS-MIXIN / JUST-SENDS-SUPER | 0 / 0 |
| PULL-UP | **10** (7 same-default; 9 of 10 `[inspector-visible]`) — Phase 2 |
| DEMOTE | **20** (**20 of 20 `[inspector-visible]`**, 9 classes; +3 withheld `.name`, +62 write-only) — Phase 3 |

*Superseded pre-Phase-0 baseline, for reading older notes: DEMOTE was **36** (23 `[inspector-visible]`;
+49 withheld). The 49 and the 36 are both tooling artefacts of the write-only bug — do not compare
them to the current row.*

### The cost model you are trading against

- **`[inspector-visible]` = the class is Widget-family.** The inspector renders live member lists, so
  adding/removing a **FIELD** there churns exactly the 15-screenshot `fg recapture-inspector` set
  (~20 min, background). It is a COST to budget, not a veto — and per owner policy a benign inspector
  recapture is fine: **just recapture; never contort the code to avoid one.**
- ⚠ **Methods are free; fields are not.** Verified empirically 2026-07-15: deleting 9 methods from
  Widget-family classes produced ZERO inspector churn (gauntlet 9/9). Do NOT budget a recapture for a
  method-only change. (The pre-run assumption was the opposite and was wrong.)

---

## Phase 0 — ✅ DONE 2026-07-15 — FIX the census first: the write-only DEMOTE bug

**Shipped as exclusion 4 in `buildSystem/census-property-placement.js`** (a DEMOTE candidate must have
at least one non-assignment occurrence), with the enumeration BLIND SPOT now documented in the census
header and the exclusion list renumbered 1–4 (the header had said "THE TWO SAFETY EXCLUSIONS" while
the code and case law already referred to an undocumented "exclusion 3"). **DEMOTE 36 → 20.** The
analysis below is retained as the durable rationale — it is case law 10 now.

**This was the highest-value item in the plan, and it was pure tooling (no `src`, no gauntlet).**

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

**Two distinct holes this exposed — both fixed:**

1. ✅ **Require a READ.** A genuine property→local needs a write AND a read. **Shipped as: at least one
   non-assignment occurrence** — deliberately NOT the `uses >= 2` first proposed here, because
   `@x = 0` followed by `@x += 1` is two uses and still write-only in effect. (Compound assignments do
   technically read, but a value only ever fed back into itself is not consumed by anything
   observable, so they count as writes — the conservative direction for an advisory census.)
   Measured: 16 of 36 had exactly 1 use ⇒ **DEMOTE 36 → 20**, all 12 SystemInfo findings gone.
2. ✅ **Whole-object ENUMERATION is a reach mechanism the census is blind to** — `JSON.stringify(obj)`,
   `DeepCopierMixin`'s `@[property]` walk, the serializer. The other exclusions only see `.name`
   member reads (3) and name-strings (1); enumeration names nothing. Now a KNOWN BLIND SPOT section in
   the census header, which states plainly that a **write-only field is presumed enumeration payload**.
   Not detected statically, by design — that way lies unsoundness; presume in the safe direction.
   *(Confirmed in the wild while verifying: `Class.coffee:379` does
   `for own fieldName, fieldValue of @staticPropertiesSources` — a real enumeration read of a field a
   name scanner sees only as write-only.)*

✅ Case law 10 added to `docs/done/duplication-triage-2026-07-15-hierarchy-round4.md`; new baseline in
`docs/duplicated-code-detection.md`'s round-4 trend table; §3c of `docs/lint-and-static-checks.md`
flipped from KNOWN BUG to FIXED.

**Verification (done):** `--json` A/B before vs after — 0 added, 16 removed, all with exactly 1 use;
85 candidates conserved (36+49 before = 20+3+62 after). Engine `--self-test` PASS; `check-call-separation`
unmoved at 148/148; hierarchy census unmoved at IDENTICAL 1; `fg critique` clean. No build or suite
needed — `buildSystem/*.js` is not compiled into the world.

**Spot-check of the 16 suppressed (all confirmed genuinely write-only, i.e. correctly suppressed):**
12 `SystemInfo.*` (enumeration payload — the reference-image identity); `Mixin.staticPropertiesSources`
(assigned `{}`, never read in `Mixin.coffee` — note `Class.coffee` enumerates its own copy);
`ListWdgt.active` (never read anywhere in src or harness); `RegexSubstitutionPatchNodeWdgt.input3`/
`input4` (the patch-node family exposes a uniform 4-input surface — `CalculatingPatchNodeWdgt` reads
all four at `:53`, the regex node consumes only two, so these are interface conformance, not dead).
⚠ None of these is a DEMOTE. Several may be genuinely vestigial state, but proving that needs exactly
the enumeration analysis the census cannot do — **the 62-strong write-only bucket is not a backlog.**

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

## Phase 3 — DEMOTE (**20** after Phase 0) — the weakest item in the plan; read this before starting

Phase 0 is done, so the report is now honest. **The economics got worse, not better, and that is the
key fact for whoever picks this up:**

- Pre-Phase-0, 23 of 36 were `[inspector-visible]`. **Post-Phase-0, 20 of 20 are** — every one of the
  13 non-Widget-family findings was a write-only false positive (`SystemInfo`, `Mixin`). So there is
  **no "free" subset left**: every remaining DEMOTE is a FIELD change on a Widget-family class, and
  fields churn the 15-test inspector set (methods do not — case law 2).
- The 20 span just **9 classes** and are dominated by ONE family: **a ctor-built child widget parked in
  a field that only the builder ever reads** — 10 in `_buildAndConnectChildrenNoSettle`, 3 in a
  `constructor`, 2 in `_buildAndConnectObjOwnPropsButton`. The widget TREE already holds the
  reference, so the field is redundant. `InspectorWdgt.show*On/OffButton` is the archetype (8 of the
  20 are `InspectorWdgt` itself).

**Recommendation: do not do this as its own arc.** The whole report is worth ONE `fg recapture-inspector`
(~20 min) plus a gauntlet, to delete 20 redundant fields across 9 classes — and the payoff is a
slightly narrower serialization surface, nothing behavioural. It is a reasonable *rider* on any arc
that is already recapturing the inspector for another reason, and a poor use of a recapture on its own.
If it is done, do it as ONE batch to pay the recapture once.

Spot-verified genuine (they have a real read): `VideoPlayPauseToggle.playPausePlayButton`/
`playPausePauseButton` (3 uses each, `@constructor`), `ReconfigurablePaintWdgt.mainCanvas`,
`ScriptWdgt.saveTextWdgt`, `UpperRightTriangleIconicButtonWdgt.pencilIconWdgt` (4 uses).

**Neither withheld bucket is a backlog:**
- **3 withheld by the `.name` veto** (case law 6/7). Do not "unlock" them by weakening the veto: it
  caught a false positive that hand-verification had already cleared (`InspectorWdgt.textWidget` —
  `MacroToolkit.coffee:879` reads it). Its cost is real, accepted, and now known to be **small**: e.g.
  `SliderButtonWdgt.offset` IS genuinely local to `@nonFloatDragging`, but the other `.offset` reads in
  src are `appliedShadow.offset` — a different object the scanner cannot distinguish.
- **62 withheld as write-only** (case law 10). Presumed enumeration payload. Separating the genuinely
  vestigial from the payload needs precisely the analysis a name scanner cannot do; a wrong guess here
  is how you invalidate the reference set.

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

~~**Phase 0 first**~~ — ✅ DONE 2026-07-15. It was the right call: it removed 16 false positives
including 12 that would have invalidated the reference set, and it made Phase 3 honest.

**The re-read that Phase 0 mandated has been done, and the answer is: Phase 3 is not worth its
recapture on its own** (20 findings, all inspector-visible, all redundant-ctor-child fields, zero
behavioural payoff — see its section). That is the legitimate "stop" outcome the plan anticipated, so
it is recorded rather than worked around.

**What is actually left, in order of value:**
1. **Phase 2's 3-colour batch** (`IconicDesktopSystemLinkWdgt.color_normal/_hover/_pressed`) — the best
   remaining *code* win: one parent, one recapture, verbatim-identical defaults.
2. **Phase 3** — only as a rider on an arc already recapturing the inspector. Never on its own.
3. **Phase 1** (`BubblyAppearance.constructor`) — owner-gated, 2 lines against a real risk class;
   probably never happens on its own.

⚠ Phases 2 and 3 both cost the SAME `fg recapture-inspector`. If both are ever wanted, do them as one
batch and pay it once.
