# Dispatch-slot protocol — give ButtonWdgt's four slots stable meanings, then honest names

**STATUS: EXECUTED IN FULL AND CLOSED 2026-08-18 (authored, censused, decided, executed and gated
the same day). Kept verbatim below as authored; the as-built record is §4's DECIDED block + §9.**

**Mandate:** eliminate the conditional slot semantics — not document them better, not rename around
them. The end state is a dispatch whose every slot has ONE meaning at every call site, and names
that say it. If Phase 0 proves that end state costs more than it buys, the honest close is a
RECORDED REFUSAL with the census attached, not a half-migration.

---

## §0 Orientation

Fizzygum: CoffeeScript GUI framework, one `<canvas>`, ~470 classes as `SourceVault` text compiled
in-browser; three sibling repos under `Fizzygum-all/`; all commands via
`/Users/davidedellacasa/code/Fizzygum-all/fg`. Every menu item and prompt button is a `ButtonWdgt`
(or subclass) that fires a stored `@action` (a STRING method name) at a stored `@target`.

**Why this plan exists:** the 2026-08-18 naming-gloss audit (BACKLOG § "Naming-gloss audit
2026-08-18") identified `dataSource`/`widgetEnv` as its top finding and then explicitly REFUSED to
rename them, because the slots have no stable meaning to name — the defect is protocol-level. Two
earlier arcs already paid for this: the menu-action-wiring arc found SIX live user-facing bugs all
reducible to "nothing at the call site says what the slots hold", and the menu-subject-routing arc
established the semantics are CONDITIONAL (below) and falsified two of its own residue filings by
inferring defects from the dispatch fact without reading consumers. Memory notes:
`menu-action-wiring-arc`, `menu-subject-routing-arc`, `naming-gloss-audit-arc`.

**The critical reframe, stated up front:** the question is not "what should the slots be called"
but "**what do the reachable verbs actually READ**". Nobody has ever measured that. Every past bug
AND both falsified filings came from reasoning about the dispatch side; the consumers are the
ground truth, and Phase 0 exists to enumerate them.

## §1 Exact current state (verified 2026-08-18 at Fizzygum `9ef5c116`; line numbers drift, grep the names)

**The dispatch** (`ButtonWdgt.coffee` — fields ~:15, ctor ~:62, trigger ~:122):

```coffee
dataSourceWidgetForTarget: undefined        # <- opts.dataSource
widgetEnv: undefined                        # <- opts.widgetEnv
...
@target[@action].call @target, @dataSourceWidgetForTarget, @widgetEnv, @argumentToAction1, @argumentToAction2
```

**The conditional fill** (`MenuRowsPanelWdgt.createMenuItem` ~:178, its own comment flags the
CROSSOVER):

```coffee
item = new MenuItemWdgt menuItemSpec,
  ...
  dataSource: @target            # panel WITH environment: slot 1 = the panel's target
  widgetEnv: @environment        #                          slot 2 = the environment
if !@environment?
  item.dataSourceWidgetForTarget = item      # panel WITHOUT: slot 1 = the ROW ITSELF
  item.widgetEnv = @target                   #                slot 2 = the panel's target
```

So slot 1 means "the subject" or "the triggering row" depending on panel configuration, and slot 2
means "the environment" or "the subject". **A verb reading its SUBJECT from slot 2 is right exactly
when the menu was built ABOUT that subject** (the subject-routing arc's law). A row wired to a
DIFFERENT receiver does not opt out — the receiver comes from the row, both leading arguments still
come from the panel.

**The second delivery family — wires/pins** (`DataflowEngine.coffee` ~:522):

```coffee
consumer[actionToCall]?.call consumer, value      # slot 1 = THE VALUE, slot 2 = undefined
```

Prompt-reached setters therefore carry the documented SHAPE `(valueOrWidget, widgetGivingValue)` —
slot 2 checked FIRST, falling through to slot 1 (three identical ⚠ SHAPE comments in
`SliderWdgt.coffee` ~:303/:330/:372; convention recorded in
`docs/archive/widget-practices-convergence-plan.md` §2.6). Prompts themselves are MenuRowsPanelWdgt
compositions (PromptWdgt extends PopUpWdgt), so their Ok buttons ride the SAME four-slot dispatch —
for a slider prompt, slot 1 = the widget being configured, slot 2 = the entry field.

**Site counts** (re-verify with fresh greps): `dataSource`-family ~21 src + ~9 tests sites,
`widgetEnv` ~19 src + ~9 tests; the runtime reach is **~519 distinct (receiver class, action)
pairs** (`fg menusweep`'s DISTINCT count — breadth, not a ratchet; "menus walked" 324 is the
stable reach number).

**The gates and their stated blind spots** (`docs/architecture/lint-and-static-checks.md`):
`buildSystem/check-menu-actions.js` (static, on the build) catches a function literal in the
action slot, a string where opts goes, and ratchets trailing padding — it CANNOT see a parameter
read as the wrong THING, nor a MISSING parameter. `fg menusweep`
(`Fizzygum-tests/scripts/menu-click-sweep-headless.js`, gauntlet wave-A leg) fires every reachable
action and catches throws — it CANNOT see a wrong-but-non-throwing subject. `fg pinsweep` is the
runtime pin-contract sweep. Both sweeps exist because of this exact bug family.

## §2 ⛔ Falsified ground — do NOT re-derive these (each cost real time)

- **`widgetOpeningThePopUp` is NOT a misnomer** (103 sites, 31 files, all correct). Its one
  consumer, `PopUpWdgt.getParentPopUp: -> @widgetOpeningThePopUp.firstParentThatIsAPopUp()`, needs
  exactly the OPENER (for a submenu, the MenuItemWdgt) — passing "the widget the menu is about"
  would break the pop-up parent chain. Recorded ⛔ in BACKLOG § "Menu-dispatch residue".
- **`menusHelper.testMenuForMacros?()` is not dead** — the method installs from the TESTS repo at
  boot; the `?` is the part-absence idiom.
- **The general law both taught:** the dispatch fact tells you what a slot HOLDS, never whether the
  receiving parameter is WRONG to want it. Read the consumer.
- **A rig that mutates the world manufactures its own bugs** — re-run any sweep finding in
  ISOLATION before believing it (the `make pointer` false positive).
- **P10(a) recorded refusal stands:** `ButtonWdgt.trigger` does NOT route through the dataflow
  drain.

## §3 Phase 0 — the reader census (the deciding measurement)

**Question:** for every reachable (receiver, action) pair, what do the verb's first two parameters
DECLARE and READ? Until this table exists, every design argument is the same speculation that
produced two falsified filings.

**Instrument** (probe in `Fizzygum-tests/.scratch/`, requiring `../scripts/lib/…`):
1. Dump the reachable pair list from the menusweep rig (it already enumerates; add a `--dump-pairs`
   or reuse its `--verbose` pair set). Include the prompt sweep surface if the rig walks prompts;
   if not, add the prompt Ok/slider/colour family by hand from `pinsweep`'s reach.
2. For each pair, resolve the method SOURCE via the reflective layer (`Class`/`Mixin` parse member
   sources; `buildSystem/lib/coffee-method-header.js` is the sanctioned header parser — ⚠ one
   header regex in SIX gates once missed 45 methods; use the shared lib, never a fresh regex) and
   extract: the declared parameter list; whether params 1/2 are referenced in the body; the
   parameter NAMES (they encode intent: `widgetGivingValue`, `widgetThisMenuIsAbout`, `ignored`).
3. Classify each pair: **(a)** takes nothing · **(b)** reads slot 1 — and as WHAT (row? subject?
   value?) · **(c)** reads slot 2 — as what · **(d)** declares-but-ignores (padding) ·
   **(e)** unresolvable statically (computed names, mixin members) — count these honestly, the
   census is only as good as its stated coverage.
4. Cross-tabulate against the TWO fill configurations (env-present / env-absent panels — the rig
   can report which panel kind each pair was reached through) and the wire family (slot 1 = value).

**Deliverable:** a table in `docs/measurements/dispatch-slot-census-<date>.md` + the go/no-go:
- If slot-2-as-subject readers and slot-2-as-environment readers are BOTH numerous → fixed
  meanings need per-verb migration; estimate from the counts.
- If one bucket dominates and the other is a handful → the minority migrates, the protocol
  stabilises cheaply.
- If bucket (a) dominates overall (most verbs take nothing) → the protocol matters for a small
  minority and option O4 (narrowing) may beat any grand unification.

## §4 Design options (decide AFTER Phase 0, with the census on the table)

- **O1 — fixed positional meanings:** every dispatch passes `(subject, context, arg1, arg2)` with
  one definition each; verbs wanting the ROW get it another way (it is reachable as the button
  itself — nothing stops a spec option carrying it). Cheapest if the census shows few
  row-readers.
- **O2 — one named bag:** `@target[@action].call @target, {subject, row, environment, value…}`.
  Clearest end state, biggest churn (every reachable verb's signature), and it must still serve
  the wire family's bare `(value)` delivery — likely as a separate, honest convention.
- **O3 — rename only** — ⛔ pre-falsified: instability cannot be named; this is the option the
  naming audit already refused.
- **O4 — narrow the sharing:** stop the prompt family and the menu family sharing one four-slot
  dispatch (different trigger paths for different button roles), so each path's slots CAN mean one
  thing without migrating the other's verbs. Attractive if the census splits cleanly along that
  line.

Whatever wins: the `MenuRowsPanelWdgt` crossover and the `if !@environment?` fork must DIE — they
are the conditionality. The names (`dataSource`/`widgetEnv` → whatever the stable meanings are)
land in the SAME arc, with the naming-audit discipline (both repos, docs, zero-leftover
absolute-path greps).

**DECIDED 2026-08-18 (owner-approved, census attached): O4 with the prompt family converging on
wire-style VALUE delivery.** Three honest sub-protocols:

- **Menu rows** — `ButtonWdgt.trigger` passes the button ITSELF as slot 1 (`@target[@action].call
  @target, @, @subjectOfAction, @actionArgument`): the stored self-pointer fill
  (`item.dataSourceWidgetForTarget = item`) is redundant state and dies; slot 2 is the panel's
  target under its honest name (the menu's subject); the census proves every reachable menu reader
  already treats the slots exactly this way, so ZERO menu verbs migrate.
- **Prompts** — the Ok row targets the PROMPT itself (`addMenuItem "Ok", @, "fireCallback"`);
  `PromptWdgt.fireCallback` extracts the value from its own editor (per-subclass `_promptValue`:
  entry field / picker) and calls `@target[@callback].call @target, value`. `panel.environment`
  dies at its three writers, so `environment` leaves `MenuWdgt`/`MenuRowsPanelWdgt` wholesale and
  the crossover collapses. Every prompt-reached setter then takes ONE honest value parameter —
  the ⚠ SHAPE convention (slider setters' three-leg interrogation included) dies with it. The
  census's finding-2 bug is the evidence for this direction: its author wrote the setter the way
  the protocol naturally reads, and value delivery makes that natural expectation the contract.
- **Wires** — unchanged `(value)`; the former SHAPE setters become exact convergence instead of a
  bridged mismatch.

`argumentToAction1/2` STAY (the census's "one reachable consumer" measured only the menusweep
roots): the P2c re-verification found two real two-payload consumers behind the choose-target
UI — `addPropertyToMixin (…, prop, mixinGlobalName)` and
`setTargetAndActionWithOnesPickedFromMenu (…, theTarget, setterName)` — both filling `arg1:` and
`arg2:`. Phase 3's checkable invariant: a prompt-reached setter with more than one parameter is a
gate failure.

## §5 Central risks

1. **This is the six-live-bugs neighbourhood.** Every change risks re-introducing exactly the bug
   class the two sweeps were built for. Protocol: `fg menusweep` + `fg pinsweep` after EVERY
   wiring change (seconds each), full gauntlet at commit points; any sweep finding re-run in
   isolation before belief.
2. **The gates cannot see wrong-but-non-throwing subjects.** A migration that silently retargets a
   verb passes everything except a human noticing. Mitigation: the census's per-verb table IS the
   checklist — tick each migrated verb against what it read before and after; A/B any verb whose
   bucket changes.
3. **A LEADING unread slot cannot be dropped** (dropping it slides the real parameter into slot 1
   and silently retargets) — name it `ignored`; that asymmetry is check-menu-actions rule 3.
4. **Scope creep into P10(b)/graph-edges:** indexing button `@target`s as graph edges is a
   DIFFERENT arc (`plans/graph-edges-and-lifecycle-plan.md` §4.2, owner-gated on G1). This plan
   changes what flows through a trigger, not how triggers are indexed.

## §6 Phases + gates

- **Phase 0** — the census (§3). No src changes beyond an optional `--dump-pairs` flag on the rig.
  Gate: none (read-only measurement) — but the deliverable doc must state coverage honestly,
  including bucket (e).
- **Phase 1** — owner decision on §4 with the census attached. STOP HERE and ask.
- **Phase 2** — execute the chosen option; kill the crossover + the conditional fill; rename the
  slots to their now-stable meanings (both repos + docs, naming-audit discipline). Gates:
  menusweep/pinsweep per change, `fg presuite` per batch, `fg gauntlet` + `fg homepage` at commit
  points. Expect inspector member-list churn if public Widget/ButtonWdgt members rename → named
  diffpage review before any recapture.
- **Phase 3** — teach the gates the new invariant (a fixed-meaning slot is CHECKABLE where a
  conditional one was not: check-menu-actions can then flag a verb whose declared param name
  contradicts its slot's fixed meaning). Close: BACKLOG, archive this plan + INDEX line, memory.

## §7 Verification protocol (commands, not vibes)

`fg menusweep` (~5s) · `fg pinsweep` (~4s) · `fg presuite` (~2min) · `fg gauntlet` (16 legs,
~5min) · `fg homepage` (production boot + snapshot round-trip). Long ops in background awaiting
the notification; a `PASS-serial-only` leg = read its `/tmp/fg-<leg>.parallel-fail.log` and NAME
the failure (boot-storm shapes: "world did not become ready", "CoffeeScript is not defined")
before accepting.

## §8 References

BACKLOG §§ "Naming-gloss audit 2026-08-18" (the refusal that spawned this) + "Menu-dispatch
residue" (the falsified filings, kept with refutations) ·
`docs/archive/menu-action-wiring-plan.md` + `docs/archive/menu-subject-routing-plan.md` (the two
prior arcs; §5 of the latter is the as-built dispatch record) ·
`docs/architecture/lint-and-static-checks.md` (gate blind spots) ·
`docs/archive/widget-practices-convergence-plan.md` §2.6 (the prompt-setter SHAPE) · memory notes
`menu-action-wiring-arc`, `menu-subject-routing-arc`, `naming-gloss-audit-arc`.

## §9 STATUS BOX

- Phase 0: **DONE 2026-08-18** — deliverable `docs/measurements/dispatch-slot-census-2026-08-18.md`
  (631 pairs → 208 methods, bucket (e) = 0). Headline: the two fill configurations partition
  EXACTLY by delivery family (menu rows 594/594 env-absent, prompt Oks 37/37 env-present, zero
  shared verbs, statically total — only the three prompt classes ever write `environment`), and
  83% of verbs declare no parameters; per-family slot meanings are ALREADY stable at every
  reachable reader. Verdict: GO — O4-shaped (make the family split explicit), near-zero verb
  migration. Two by-catch findings recorded in the deliverable: the header lib's
  space-before-colon blind spot (13 methods invisible to every gate), and a LIVE bug confirmed in
  isolation (`WidgetHolderWithCaptionWdgt.setColor` sets `icon.color` to the widget itself from
  the colour prompt).
- Phase 1: **DECIDED 2026-08-18** — O4 + value-delivery convergence; the full shape is recorded in
  §4's DECIDED block. By-catch fixes landed first (header-lib space-colon guard + 13
  normalizations + the holder setColor forward, all gate-verified) — Fizzygum `11c5a06c`.
- Phase 2: **EXECUTED 2026-08-18.** P2a (`1bca55d9`): prompts deliver the VALUE
  (`PromptWdgt.deliverValue` + per-subclass `_promptValue`; `panel.environment` dead at all three
  writers), all 33 giver-shaped setters + the `ignored`-named overrides collapsed to one value
  parameter, the ⚠ SHAPE convention deleted, `widget-authoring-guidelines.md` §11 rewritten.
  P2b (`a1ad3476` + tests `a040d6a81`): `trigger` passes ITSELF as slot 1 and the panel-filled
  `@subjectOfAction` as slot 2; the crossover, the `if !@environment?` fork and `environment` on
  `MenuWdgt`/`MenuRowsPanelWdgt` deleted; `_createMenuItem` `_`-tier; comment/doc sweep both
  repos. ZERO verb migrations (as the census predicted); the only recaptures were the two
  ClassInspector-on-ButtonWdgt tests' member lists (diffpage-reviewed, gated recapture COMPLETE).
  `argumentToAction1/2` kept — see §4's correction.
- Phase 3: **EXECUTED 2026-08-18** (tests `4a74ac5c2`): menusweep fails on a prompt callback
  declaring >1 parameter (PROMPT_CALLBACK_ARITY, read off the live composed method; proven on a
  planted violation, silent on a healthy one; the real sweep is green tree-wide).
- Close gates: build 0 violations ×4, menusweep/pinsweep green throughout, presuite green,
  **gauntlet 16/16 all in-wave (276s)**, **fg homepage BOOT OK** incl. the production snapshot
  round-trip over the reshaped classes. Census deliverable:
  `../measurements/dispatch-slot-census-2026-08-18.md`. By-catch live bug (holder setColor) fixed
  and isolation-verified.

## §10 Cold-start prompt (paste into a fresh session)

> Execute `Fizzygum/docs/plans/dispatch-slot-protocol-plan.md`, Phase 0 only, then STOP for the
> owner decision. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (expect both repos
> clean; if dirty, STOP and ask); read the plan fully — §2's falsified ground is load-bearing;
> re-grep every §1 name before trusting it. Working rules: never commit/push without explicit
> approval (present the message and wait); `git commit -F <file>`, never `-m`; `git -C
> <abs-repo>`; never `git stash`; absolute path for `fg`; long ops in background, WAIT for the
> notification; probes in `Fizzygum-tests/.scratch/` requiring `../scripts/lib/…`; macro sources
> are CoffeeScript in JS template literals (no backticks); comments state what IS.
