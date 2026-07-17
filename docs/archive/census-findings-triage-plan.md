> **ARCHIVED — COMPLETE (2026-07-17 restructure).** CLOSED 2026-07-15; every phase done or closed with a recorded reason (Phase 0/1/3 done, Phase 2 zero-actionable).
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Hierarchy/property census findings — remaining triage

**STATUS 2026-07-15: Phase 0 ✅ DONE (tooling) · Phase 2 ⛔ CLOSED, zero actionable (all 10 falsified
or forbidden) · Phase 3 ✅ DONE (13 of 20 actioned) · Phase 1 remains owner-gated.**
**This plan is now essentially CLOSED** — what is left is one owner-gated 2-line constructor. Written
to be read **cold, by an LLM with zero prior context**: everything needed is embedded or pointed at by
absolute path.

> **The three headline results, if you read nothing else:**
> 1. **The censuses' two most-recommended items were both FALSE POSITIVES.** Phase 0's write-only bug
>    would have invalidated the entire reference set; Phase 2's "best batch" would have turned the
>    desktop icons near-white (case law 11). A census finding is a QUESTION, never an instruction.
> 2. **Phase 3 was free.** 13 field deletions, gauntlet 9/9, zero recaptures — the `[inspector-visible]`
>    cost tag over-warns badly (see the corrected cost model below).
> 3. **What is left is not a backlog.** Every un-actioned finding has a recorded, specific reason.

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
(`docs/archive/lint-generic-rules-carryover-plan.md`, EXECUTED 2026-07-15) still report findings. Tranches
A/B/C took every finding that was both provable and free (commits `83209869`, `3d038959` — 9 no-op
overrides + 1 field). **This plan owns what is left**, and every remaining item costs something: a
risk class, or an inspector recapture, or both. Nothing here is a sweep.

**Prior art you must read first** (do not re-derive it):
- `docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md` — the CLOSED round-4 record and its
  **9 pieces of case law**. Read this before touching any finding.
- `docs/architecture/lint-and-static-checks.md` §3b (severity policy) / §3c (the censuses, and why neither can
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

### Baseline — CURRENT (2026-07-15, after Tranche A/B/C + Phases 0/2/3)

| Report | Count | Status |
|---|---|---|
| IDENTICAL-TO-INHERITED | **0** | ✅ Phase 1 DONE 2026-07-15 — `BubblyAppearance.constructor` deleted; the report is now driven to zero |
| SHADOWS-MIXIN / JUST-SENDS-SUPER | 0 / 0 | — |
| PULL-UP | **10** (7 same-default) | ⛔ Phase 2 CLOSED — **all 10 triaged, ZERO actionable.** The report stays at 10 forever unless the code changes; that is the correct answer, not a backlog. |
| DEMOTE | **4** (was 20) | ✅ Phase 3 done — 13 actioned; 3 more RESOLVED THEMSELVES when the listener bug was fixed (below); the 4 survivors each have a recorded reason |
| DEMOTE withheld | +3 `.name`, +62 write-only | Not backlogs (case law 6/7 and 10) |

*Superseded numbers, for reading older notes: DEMOTE was **36** (+49 withheld) before Phase 0 fixed the
write-only bug, then **20** (+3, +62) before Phase 3. The 36 and the 49 are tooling artefacts of that
bug — never compare them to the current row.*

### The cost model you are trading against — ⚠ CORRECTED 2026-07-15, it over-warns

- **`[inspector-visible]` asks only "is the class Widget-family?"** — a CRUDE over-approximation of
  the real predicate, which is *"do the tests inspect an instance of this class, or of something that
  inherits the member?"* Treat the tag as "check whether this class is ever a test's inspection
  TARGET", not as "budget a recapture".
- ⚠⚠ **MEASURED 2026-07-15: 13 FIELD deletions across 5 Widget-family classes, every one tagged
  `[inspector-visible]`, cost ZERO recaptures** (gauntlet 9/9, `Fizzygum-tests` dirty=0). The
  inspector renders its TARGET's member list; the 15 inspector tests inspect things like an analog
  clock, never an `InspectorWdgt` / `BasementWdgt` / `ScriptWdgt` / `ReconfigurablePaintWdgt` /
  `UpperRightTriangleIconicButtonWdgt`. Removing a field from a class nothing inspects is invisible.
  **This corrects an earlier entry in this very plan** which claimed "20 of 20 are inspector-visible ⇒
  no free subset remains". That was wrong: the subset was free.
- ⚠ **Methods are free too.** Verified 2026-07-15: deleting 9 methods from Widget-family classes
  produced ZERO inspector churn.
- **So what DOES cost a recapture?** Changing a member on a class the tests actually inspect — above
  all a COMMON BASE such as `Widget` itself, whose members appear in every inspected object's list
  (see `oo-smells-backlog`: "adding to a common base is inspector-safe only when the panel hides
  inherited members"). Per owner policy a benign recapture is fine when it does happen: **just
  recapture; never contort the code to avoid one.**

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

✅ Case law 10 added to `docs/archive/duplication-triage-2026-07-15-hierarchy-round4.md`; new baseline in
`docs/tooling/duplicated-code-detection.md`'s round-4 trend table; §3c of `docs/architecture/lint-and-static-checks.md`
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

## Phase 1 — `BubblyAppearance.constructor` — ✅ DONE 2026-07-15. **IDENTICAL-TO-INHERITED: 1 → 0.**

> **⚠ The risk assessment below was WRONG — recorded because being wrong here is the lesson.** Owner
> asked for the evidence; reading the meta-compiler dissolved every hazard this section lists:
> - **`meta/Class.coffee` has an explicit `else` branch for a class with NO constructor** (the
>   `hasOwnProperty('constructor')` test) that synthesises
>   `window.X.__super__.constructor.apply this, arguments` + `@registerThisInstance?()` + `return` —
>   exactly what the explicit ctor produces once `_addInstancesTracker` injects the same call.
>   **286 of 455 classes already rely on that path**, including 4 of the 8 Appearance-family classes
>   (`DragChargingRingAppearance extends Appearance` with no ctor is a working next-door precedent).
>   Far from exotic, it is the MAJORITY path.
> - **Arg forwarding is moot.** The synthesised ctor forwards `arguments` (all) where the explicit one
>   forwarded `widget` (one) — but `BoxyAppearance`'s own ctor truncates to one regardless, and both
>   call sites pass exactly one: `new BubblyAppearance @` (`SpeechBubbleWdgt:20`, `ToolTipWdgt:26`).
> - **`check-constructors-build.js` does not care** — it only enforces "a constructor must not build
>   its own children inline".
> - **The `WindowWdgt`/`FolderWindowWdgt` case law does not apply** — that trap was about REORDERING a
>   ctor's args breaking a subclass that called `super` positionally. `BubblyAppearance` **has no
>   subclasses**.
> - **`Object.create` (duplication/serialization) BYPASSES constructors entirely** — which *lowers* the
>   risk. This section had cited it as if it raised it.
>
> **Verified: gauntlet 9/9 PASS, zero screenshot diffs, zero recaptures.** The honest reason to have
> skipped it was only ever "it is two lines" — *not* "it is a dangerous risk class". ⚠ **Do not let a
> risk class be asserted from a distance: READ the mechanism before pricing the risk.** The original
> analysis is retained verbatim below as the record of that mistake.

### Original (WRONG) analysis — retained deliberately, see above

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

## Phase 2 — PULL-UP (10) — ⛔ CLOSED 2026-07-15: **ZERO actionable. All 10 falsified or forbidden.**

> **Do not re-open without new evidence.** Every finding was READ and triaged 2026-07-15; the two
> "strong" batches are FALSE POSITIVES with proven mechanisms (case law 11 and 12). The PULL-UP report
> is kept for future rounds, but its current 10 findings are all accounted for below. **Nothing here
> should be attempted.**
>
> | Finding | Verdict |
> |---|---|
> | 3 × `IconicDesktopSystemLinkWdgt` colours | ⛔ **FALSIFIED — case law 11.** All 3 subclasses `@augmentWith HighlightableMixin`, which injects its OWN `color_normal`/`color_hover` **onto the subclass prototype** (`addInstanceProperties` does `@::[key] = value`). `meta/Class.coffee:350-373` emits augmentWith BEFORE class-body fields, so the class-body colour EXISTS TO OVERRIDE THE MIXIN. Pull it up and the mixin's value shadows the parent: **icons render near-white instead of black, hover silver instead of grey.** Simulated and confirmed. |
> | 2 × `PatchNodeWdgt.setInputNIsConnected` | ⛔ **FALSIFIED — case law 12** (= case law 8's `fps` shape). Read only dynamically (`ControllerMixin:32-33`, `@target[@action + "IsConnected"]`), and the EXISTENCE of the flag declares the node's input surface. `PatchNodeWdgt:74-76` documents per-subclass input surfaces; Diffing declares `setInput1Hot` and deliberately not 3/4. 1+2 in all three is an INTERSECTION, not an abstraction. |
> | `videoPlayerCanvas` (`HhmmssLabelWdgt`) | ⛔ Skipped: `video-player` family has ZERO SystemTest coverage (unverifiable), and both subclasses auto-assign it via `constructor: (@videoPlayerCanvas) ->` — case law 4's shape. |
> | `tempPromptEntryField` (`MenuWdgt`) | ⛔ Rejected on design: both subclasses are PROMPTS, so the shared concept is "prompt", not "menu". Pulling a prompt-specific field onto the general menu class worsens cohesion. The honest refactor is an intermediate prompt base — a design change, not a census tidy. |
> | `seed`, `offset` | ⛔ Differing defaults (weak informational tier); `offset` is a name COLLISION — case law 9. |
> | `fps` (`DataflowSource`) | ⛔ Documented-deliberate — case law 8. **DO NOT "fix".** |
>
> **The durable lesson (now case law 11): before ANY pull-up, check every subclass for `@augmentWith`
> of a mixin supplying the same property.** The census structurally cannot: it inspects the PARENT's
> chain, while the mixin sits on the SUBCLASS and declares its properties inside a nested
> `addInstanceProperties` call that the class-body harvester never sees.

### Original analysis (retained — the candidate list and the cost model still describe the report)

A property declared in EVERY direct subclass of `P` but nowhere in `P` or above it. **9 of 10 are
`[inspector-visible]`, and PULL-UP moves FIELDS — so unlike the method work, these DO churn the
15-test inspector set.** Budget `fg recapture-inspector` (~20 min) per batch; batch them to pay once.

**The 5 candidates that LOOKED strong (same default in every subclass) — all now falsified above:**

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

## Phase 3 — DEMOTE — ✅ DONE 2026-07-15: **13 of 20 actioned. DEMOTE 20 → 7, then → 4.**

**Gauntlet 9/9 PASS (248 tests × dpr1/dpr2/webkit), ZERO screenshot diffs, ZERO recaptures,
`Fizzygum-tests` dirty=0.** It cost nothing — see the CORRECTED cost model above; the recapture this
plan budgeted never materialised, because the tests inspect none of the 5 classes touched.

**Actioned (13) — one shape: a ctor-built child parked in a field only the builder reads.** The real
owner already holds the reference, so the field was redundant state:

| Class | Fields | Why it was safe |
|---|---|---|
| `InspectorWdgt` | 8 (`show{Methods,Fields,Inherited,OwnPropsOnly}{On,Off}Button`) | Each `ToggleButtonWdgt` OWNS its two buttons (`SwitchButtonWdgt` keeps them in `@buttons`). Only the 4 TOGGLES remain fields — the honest ownership. |
| `BasementWdgt` | 2 (`hideUsedWdgts{On,Off}Button`) | Same toggle-owns-its-buttons shape. |
| `UpperRightTriangleIconicButtonWdgt` | 1 (`pencilIconWdgt`) | The widget TREE holds it (`_addNoSettle`). |
| `ReconfigurablePaintWdgt` | 1 (`mainCanvas`) | An ALIAS of `@stretchableWidgetContainer.contents`; `@overlayCanvas.underlyingCanvasWdgt` keeps the reference it needs. |
| `ScriptWdgt` | 1 (`saveTextWdgt`) | `@saveButton` keeps it as its face widget. |

**NOT actioned: 4 survivors, plus 3 that RESOLVED THEMSELVES. Do not re-triage without new evidence:**

- ✅ **`WorldWdgt` × 3** (`inputDOMElementForVirtualKeyboard*BrowserEventListener`) — **GONE from the
  report, and the most interesting result in this plan.** They were withheld under case law 13
  (members of the ~20-strong listener-field family whose whole purpose is `removeEventListeners` at
  `WorldWdgt.coffee:2100`, which removes each BY FIELD REFERENCE). Following that up found no leak —
  the hidden input only exists on a touch device with `useVirtualKeyboard` and an open caret, closing
  the caret already `removeChild`s and nils it, and it is never created in any environment tests run
  in — **but the audit it prompted found 7 listeners that `removeEventListeners` silently failed to
  detach (case law 15).** Fixing that added the missing removals, so each field is now used in TWO
  methods (`_initVirtualKeyboard` + `removeEventListeners`), the "every use in exactly ONE method" rule
  stops firing, and **DEMOTE 7 → 4 because the code became CORRECT, not because anything was
  suppressed.**
  ⚠⚠ **The durable lesson — a DEMOTE finding on a FAMILY member can mean THE FAMILY IS BROKEN, not
  that the member is redundant.** The census was right that something was anomalous here: a field
  claiming membership of a family that the family's own teardown never touched. The correct resolution
  was to make the family whole. **When case law 13 makes you withhold a finding, ask "why is this
  member the odd one out?" — the answer may be a bug.** This is the one case in the whole arc where a
  census finding led to a real defect being fixed.
- **`VideoPlayPauseToggle` × 2** (`playPausePlay/PauseButton`) — ⛔ worst combination: they live in a
  **`constructor`** (the Phase 1 risk class: meta-compiled, fragmented, `check-constructors-build`
  governs it, and the ctor passes them straight to `super`) AND the `video-player` family has **ZERO
  SystemTest coverage**, so the gauntlet could not verify the change.
- **`VideoPlayerWithRecommendationsWdgt.videosIndex` × 1** — ⛔ `video-player`: zero coverage,
  unverifiable. Mechanically trivial, but an unverifiable change for a 1-field payoff is a bad trade.
- **`SpreadsheetWdgt.backgroundColorGrid` × 1** — ⛔ **case law 13.** One of 8 sibling colour fields in
  a palette block whose comment explains why they are instance fields and not class statics
  ("class-level Color statics would run at class-definition time, before Color loads"). Demoting the
  one that happens to be read once leaves a lone local amid seven fields.

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
5. Re-run the census; log the count trend in `docs/tooling/duplicated-code-detection.md`'s round-4 table and
   append the outcome to the ledger `duplication-report/triage-report.md`.
6. ⚠ The ledger is **gitignored**. When an arc closes, snapshot it into `docs/done/` per that doc's
   lifecycle rule — and add your file **by path**, never `git add docs/done/` (it holds other arcs'
   untracked files).

## Outcome (this section replaces the original "suggested order" — the order is now history)

- **Phase 0** ✅ — removed 16 false positives, 12 of which would have invalidated the reference set.
- **Phase 2** ⛔ — **zero actionable; all 10 falsified or forbidden.** Its "best batch" would have
  turned the desktop icons near-white (case law 11). The report will keep printing 10; that is
  correct, not a debt.
- **Phase 3** ✅ — 13 of 20 actioned, DEMOTE 20 → 7 (then → 4 when the case-law-15 fix landed), gauntlet 9/9, **zero recaptures** (the budgeted
  cost never materialised — the tag over-warns).
- **Phase 1** ✅ — `BubblyAppearance.constructor` deleted. **IDENTICAL-TO-INHERITED 1 → 0**, so
  `census-hierarchy-duplication` now reports ZERO on all three of its reports. The "constructor risk
  class" that gated it for two rounds dissolved on reading the meta-compiler (case law 16).

**THIS PLAN IS CLOSED.** Every phase is done or closed with a recorded reason. The censuses are at
their correct floor: hierarchy-duplication at 0/0/0; PULL-UP at 10 with none actionable; DEMOTE at 4,
all reasoned. **A zero is not always reachable, and a non-zero is not always a debt.**

### An unplanned bug fix came out of this (case law 15)

Following case law 13's "that looks like a latent leak" hunch to the source found no leak — but did
find that **`WorldWdgt.removeEventListeners` silently failed to detach 7 of its 20 listeners**, because
they are added across three targets (`@worldCanvas` / `document.body` / `window`) and it removed all of
them from `canvas`; a wrong-target `removeEventListener` is a silent no-op. That method exists for
DETERMINISM (its only caller runs it at the start of every SystemTest), and one of the survivors pushes
a `ResizeInputEvent` into the input queue. No gate could ever have caught it. Fixed and audited
mechanically. **The transferable lesson: when a teardown pairs with a setup, verify the pairing
mechanically — silent-failure APIs give no signal when the pairing drifts.**

### If you are tempted to re-open the censuses, read this first

Across Phases 0/2/3 the two censuses produced **26 findings that were technically true and wrong to
act on** (16 write-only, 10 pull-up) against **13 that were worth taking**. Both of the items this
plan itself once called "the best remaining win" were false positives. The reason is structural and
will not improve: the censuses reason **per-property, textually**, and this codebase resolves
properties through **mixin injection onto subclass prototypes** (case law 11), **dynamic
`@[name + suffix]` access** (case law 12), **whole-object enumeration** (case law 10), and
**deliberate per-family conventions** (case law 8/13) — none of which a name scanner can see. That is
exactly why they are advisory and can never be gates (`docs/architecture/lint-and-static-checks.md` §3b/§3c).
**Treat every finding as a question to investigate, never an instruction to follow.**
