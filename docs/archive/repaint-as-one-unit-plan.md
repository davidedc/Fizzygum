> **ARCHIVED — CLOSED (2026-08-11).** `Widget._repaintAsOneUnit` (cover + depth-restore in
> `finally`) replaces the paired damage-suppression verbs at all 26 sites; the boolean stack is a
> depth counter, and a live `DAMAGE_SUPPRESSION_UNBALANCED` tripwire watches the one remaining
> corruption path. Gates: presuite, gauntlet 14/14, `fg homepage`, four probes all pass; one
> benign reference churn, recaptured.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Repaint-as-one-unit: the suppression window becomes a self-balancing, self-covering block

**STATUS: CLOSED 2026-08-11 — EXECUTED IN FULL, same day as authored.** `Widget._repaintAsOneUnit` (cover + depth-restore in `finally`) replaces the paired verbs at all 26 sites (healing the three no-cover `_reLayout`s); the boolean stack is a depth counter; the dead assert is a LIVE self-healing `DAMAGE_SUPPRESSION_UNBALANCED` tripwire wired into the headless fail-gates (runner-fails plant-proven); INV-1 reduced to a tombstone; rig + smoke re-spelled. Gates: presuite, gauntlet 14/14 all-in-wave (338s), fg homepage, four probes ALL PASS. One reference churn, root-caused as the documented benign member-census class and recaptured COMPLETE (see §6.5 ledger). Case law: `archive/INDEX.md`; memory note `repaint-as-one-unit-arc`.

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Originally authored 2026-08-11, owner-approved design (same-day session, right after the `_fullChanged` trim arc closed); owner's brief: "we don't mind rework, recaptures — we want clean and effective code."

**Mandate:** eliminate the underlying problem, don't guard it. Today the damage-suppression window is assembled from paired imperative verbs plus caller discipline: the caller must remember to close the window (an exception mid-window leaks it and the world silently stops repainting), and must remember to issue the covering repaint (three sites don't, leaning on an undocumented invariant). Both failure modes must become UNREPRESENTABLE — one construct that balances and covers itself — with the one remaining corruption path (direct field tampering / future bugs) watched by a LIVE, correctly-spelled, fail-gated tripwire. No new discipline, no new gate obligations on call sites.

---

## §0 Orientation

Fizzygum (CoffeeScript GUI framework, one `<canvas>`, broken-rects incremental repaint — root `CLAUDE.md` + `Fizzygum/CLAUDE.md` for build/test; ⚡ prefer the `fg` wrapper, absolute paths, background long ops) invalidates via two PRIVATE verbs on `src/basic-widgets/Widget.coffee`: `_changed()` / `_fullChanged()`. Both consult a world-global suppression state so a bulk child-positioning pass can be coalesced into ONE owner repaint.

Immediately prior arc: **`docs/archive/fullchanged-trim-and-precision-plan.md`** (CLOSED + pushed 2026-08-11, Fizzygum `3b68e1b3`) — its P6 falsified a per-child collect-union variant (⭐⭐ the area-GO was an instrument artifact; case law in `archive/INDEX.md`) and deleted the hand's no-op suppress window. Its P6 ledger recorded two residuals hands-off; the owner then directed this arc to fix both cleanly. **This plan supersedes those two hands-off notes.** The two residuals:

1. **The flush-time stack assert is dead code** (`WorldWdgt._updateBroken`): `if @trackChanges.length != 1 and @trackChanges[0] != true` — a De Morgan slip. The stack bottom `[0]` is always `true`, so the conjunction is always false and the alert can NEVER fire, even on a genuinely leaked window (`[true, false]`). And a naive `or` fix would alert-spam the serialization rig's DELIBERATE unbalance scenario (§1.4).
2. **Three idiom sites omit the covering repaint** (`BinWdgt`, `ErrorsLogViewerWdgt`, `FridgeMagnetsWdgt` `_reLayout`s): safe only because their child layout is a pure function of the owner frame — an invariant nothing states or checks; one future non-frame layout input turns each into a staleness bug no gate catches directly.

**Critical reframe:** these are ONE defect, not two. The construct is assembled at every call site from `world.disableTrackChanges()` … `world.maybeEnableTrackChanges()` … `@_fullChanged()`; pairing and cover are caller obligations. Make the window a single Widget-side block that suppresses, restores in `finally`, and covers — then both obligations vanish, the world verbs and the boolean stack dissolve, and the assert becomes a real tripwire for the only corruption left.

## §1 Exact current state (line numbers drift — grep the quoted code fresh; verified 2026-08-11 at Fizzygum `3b68e1b3`)

### 1.1 The suppression state — an array that is really a counter
- Declaration (`src/WorldWdgt.coffee` ~:388, CLASS-level): `trackChanges: [true]`, under a Morphic-era comment ("we use the trackChanges array as a stack to…"). ⚠ Class-level: until the first teardown assigns an own prop, push/pop mutate the PROTOTYPE-held array (harmless — one world — but emblematic).
- The stack is touched in exactly SIX places (grep `trackChanges` in src): `disableTrackChanges: -> @trackChanges.push false` (~:1292) · `maybeEnableTrackChanges: -> @trackChanges.pop()` (~:1295) · the dead assert in `_updateBroken` (~:1379, quoted above, `alert` channel) · the teardown reset `@trackChanges = [true]` (~:2686, with the load-bearing comment "dying between disableTrackChanges and maybeEnableTrackChanges leaves it unbalanced… re-balancing it is the only thing that can put a loaded world back on its feet") · the two hot-path reads in `Widget._changed` (~:3200) / `Widget._fullChanged` (~:3236): `if world.trackChanges[world.trackChanges.length - 1]`.
- **Nothing ever pushes `true`.** The array is a depth counter wearing an array costume; the costume is what makes invalid states expressible.
- NOT serialized ("not serialized and not restored by the loader", per the teardown comment). ⚠ Verify the actual exclusion mechanism at execution (grep `trackChanges` in `src/serialization/` returns ZERO hits; the world is special-cased in `Serializer.coffee` ~:82-93 and is not walked as a generic record) — the replacement counter must inherit the same fate, proven by the rigs (§7).

### 1.2 The 26 idiom sites (post-hand-deletion; the hand's 27th was deleted in `3b68e1b3`)
Every site is a widget calling on itself; bucketed by shape:
- **22 exact-idiom** (disable → position children via `_apply*`/`_reLayout` tiers → enable → trailing `@_fullChanged()`): `ScriptWdgt`, `GlassBoxBottomWdgt` (⚠ in `_reLayoutSelf` — the ONLY body the INV-1 gate currently checks), `WidgetHolderWithCaptionWdgt`, `CodePromptWdgt`, `ColorPickerWdgt` (in `_reLayoutChildren`), `InspectorWdgt`, `ConsoleWdgt`, `StretchablePanelWdgt`, `SimpleLinkWdgt`, `StretchableCanvasWdgt`, `StretchableWidgetContainerWdgt`, `GenericShortcutIconWdgt`, `GenericObjectIconWdgt`, `FanoutWdgt`, `PatchNodeWdgt`, `ToolPanelWdgt`, `SpeechBubbleWdgt`, `VideoPlayerWdgt`, `VideoPlayerWithRecommendationsWdgt`, `VideoControlsPaneWdgt`, `PlotWithAxesWdgt`, `AxisWdgt` — all others in `_reLayout`.
- **3 no-trailing-call** (`_reLayout`): `BinWdgt`, `ErrorsLogViewerWdgt`, `FridgeMagnetsWdgt` — the owner's pre-window `@_applyGrantedBounds newBoundsForThisLayout` (tracking ON) covers the changed-bounds case; the unchanged-bounds case relies on the pure-function-of-frame invariant (§0 residual 2).
- **1 build-time** (`ListWdgt._buildAndConnectChildrenNoSettle`): wraps the `addMenuItem` build loop of a DETACHED rows-panel (attached only after, via `@contents._addNoSettle @listContents`, whose add-dispatcher invalidation covers the live-rebuild case). Discarded marks are for never-painted widgets — categorically safe, converted for uniformity.
- Several sites carry near-identical 8-line comment blocks ("here we are disabling all the broken rectangles. The reason is…") — copy-paste that collapses into the construct's one header comment.
- Real nesting exists: `InspectorWdgt`'s window contains `@list`'s `ListWdgt` build window. Today the inner trailing `@_fullChanged()` is silently swallowed by the outer window (suppressed at top-of-stack `false`) — the nested semantics the construct must preserve (§4.1).

### 1.3 The gates that touch this machinery
- **INV-1** `buildSystem/check-relayout-repaints.js` (row in `docs/architecture/lint-and-static-checks.md` ~:94): line-scans `_reLayoutSelf` bodies that call `disableTrackChanges`, requiring a covering `fullChanged` after the last enable; current live population = exactly ONE body (`GlassBoxBottomWdgt._reLayoutSelf`). After conversion its invariant is structural → reduce to a tombstone (§4.5).
- **Headless fail-gate tokens** (`NON_INTEGER_GEOMETRY` / `RESETWORLD_INCOMPLETE` / … matched on console output): carried by THREE scripts — `Fizzygum-tests/scripts/run-all-headless.js` (~:225 token list + classifier + summary), `run-macro-test-headless.js`, `smoke-boot-headless.js`. The new tripwire token wires into all three (§4.4).
- **`check-invalidation-receivers.js`**: the construct's internal `@_fullChanged()` is same-receiver — legal, no annotation needed.

### 1.4 The two tests-repo consumers of the verbs/stack
- `scripts/serialization-roundtrip-headless.js` ~:1304: `world.disableTrackChanges();` — DELIBERATE corruption, part of the teardown-hygiene ratchet scenario (`world.teardownHygiene.trackChangesRebalanced` key, ~:125): unbalance mid-life → settle cycles → snapshot save+load → assert the load healed the stack. ⚠ The world CYCLES between corruption and load — with a live flush guard, each of those flushes would fire the token. The scenario must be re-shaped (§4.6).
- `scripts/smoke-boot-headless.js` ~:199/:550: reads `world.trackChanges.length`, asserts `=== 1` after the production snapshot round-trip.
- The harness `.coffee` (Automator-and-test-harness-src) has ZERO references — verified by grep.

### 1.5 Doc/comment inventory naming the old machinery (all updated in §4.7)
`Widget.coffee` ~:511-520 (the Morphic-era "damage list housekeeping" block describing the boolean switch — replaced by the construct's story) · `Widget.coffee` `_changed` ~:3192-3199 comment ("tests should all pass even if you don't use the world.trackChanges flag…") · `WorldWdgt.coffee` ~:383-387 (stack declaration comment) + ~:2682-2685 (teardown comment) · `Fizzygum/CLAUDE.md` ~:58 ("the `trackChanges` stack" in the teardown bullet) · `Fizzygum-tests/DETERMINISM.md` ~:170 ("`trackChanges` stack (left unbalanced, later tests paint nothing)") · `docs/architecture/lint-and-static-checks.md` INV-1 row · `docs/specs/dataflow-engine-spec.md` ~:291 + `docs/plans/dataflow-engine-implementation-plan.md` ~:419 (passing mentions of the idiom spelling) · the sites' own copy-pasted comment blocks.

## §2 Why it is shaped this way

The boolean-stack switch is inherited Morphic design (the ~:511 comment block is near-verbatim Morphic.js): pre-`class` JavaScript, imperative pairing was the only spelling, and the "tremendous performance improvements" story predates the flesh-out lanes' dedup flags. The trailing-cover obligation was later ratified per-site (INV-1, born from the 2026-07 D2 edit-ghosts arc — five `_reLayoutSelf` bodies had dropped their cover) — i.e. the project already met this failure class once and answered with a GATE where a CONSTRUCT was available. The three no-trailing sites predate INV-1's arc and sit outside its deliberately-narrow `_reLayoutSelf` scope. The dead assert is simply a De Morgan slip that nothing ever exercised, because the teardown/load reset is the safety net that actually runs.

## §3 The distilled argument

- **Make invalid states unrepresentable, then guard the remainder.** A `try/finally` block cannot leak the depth; a cover in `finally` cannot be forgotten and survives exceptions (today an exception between enable and the trailing call loses BOTH). A depth counter cannot hold garbage the way an array can. What remains representable — direct field tampering, a future bug writing the counter — gets the live tripwire on the channel every always-on invariant already uses (`console.error` token + headless fail-gates), with self-healing so the world degrades loudly-but-visually-fine instead of silently going dark (the same stance as the paint-error machinery).
- **Invalidation privacy becomes structural.** The verbs move off the world (public, callable by anyone, promising a cover they don't enforce) onto Widget as a PRIVATE method that can only coalesce into `self` — the receiver rule `check-invalidation-receivers.js` exists to police, now enforced by the API's shape.
- **The three no-trailing sites are healed by conversion, at zero cost**: when owner bounds changed, the dedup flag makes the added cover free; when they didn't, the cover repaints a box that the census/revisits gates prove doesn't re-lay in steady state. The undocumented pure-function-of-frame invariant stops being load-bearing.
- **This is NOT the P6 collector** (falsified, `archive/fullchanged-trim-and-precision-plan.md` §5): that design tried to PRESERVE per-child marks for precision; this one keeps today's coalesce-to-owner semantics exactly, changing only who guarantees the invariants.

## §4 Fix shape

### 4.1 The construct (Widget-side, private) and the counter (world-side)

```coffee
# Widget.coffee — replaces the "damage list housekeeping" comment block ~:511
# Run fn (a bulk child-positioning pass) with per-widget damage recording
# suspended, then mark ME as the one damage unit covering everything fn did:
# my box bounds every child the pass placed, so ONE owner rect replaces N
# child rects. Suspension nests (an inner unit's cover is swallowed by the
# outer depth and the outer box covers it). The restore AND the cover sit in
# `finally`: neither an early return nor a throwing _reLayout can leak the
# depth or lose the covering repaint.
_repaintAsOneUnit: (fn) ->
  world._damageSuppressionDepth++
  try
    fn()
  finally
    world._damageSuppressionDepth--
    @_fullChanged()
```

```coffee
# WorldWdgt.coffee — replaces `trackChanges: [true]` (and its stack comment)
# damage-suppression nesting depth (Widget._repaintAsOneUnit): while > 0,
# _changed/_fullChanged marks are dropped — the unit's owner covers them at
# close. Transient (never serialized, like the trackChanges stack it replaced);
# teardown resets it, and _updateBroken self-heals + screams if it is ever
# nonzero at flush (DAMAGE_SUPPRESSION_UNBALANCED, a headless fail-gate token).
_damageSuppressionDepth: 0
```

- Cover AFTER decrement (else self-suppressed). Hot-path reads become `return if world._damageSuppressionDepth > 0` at the TOP of `_changed`/`_fullChanged` (replacing the `if world.trackChanges[…]` wrapper — rewrite the two methods' bodies as early-return, updating the `_changed` comment; the float-drag branch and dedup logic are unchanged beneath).
- `disableTrackChanges` / `maybeEnableTrackChanges` are **DELETED** (zero src callers after conversion; no-serialization-compat rule applies). Teardown line becomes `@_damageSuppressionDepth = 0` (comment updated: re-balancing → re-zeroing; still the thing that puts a loaded world back on its feet).
- Naming (owner-ratified in-session): construct `_repaintAsOneUnit`, field `_damageSuppressionDepth`. ⛔ Do not name it "coalesce\*" — that vocabulary belongs to the falsified P6 collector and to the deferred-settle family's history (`coalesced-nomenclature-rename`).

### 4.2 The live tripwire (in `_updateBroken`, where the dead assert sits)

```coffee
if @_damageSuppressionDepth isnt 0
  console.error "DAMAGE_SUPPRESSION_UNBALANCED depth=" + @_damageSuppressionDepth
  @_damageSuppressionDepth = 0   # heal: report loudly, never let the world go dark
```

`alert` dies. The token joins the fail-gate lists of the three scripts (§1.3), so a fire anywhere fails every suite/smoke run loudly.

### 4.3 Site conversion (26 sites, four shapes — use the Edit tool ONLY, never perl: `perl-inline-edits-deindent-coffee`)
- **Exact-idiom (22):** `world.disableTrackChanges()` → `@_repaintAsOneUnit =>`; indent the window body one level; delete `world.maybeEnableTrackChanges()` AND the trailing `@_fullChanged()`. Delete the site's copy of the "disabling all the broken rectangles" comment block (the construct's header now owns that story); keep any site-specific comment lines (e.g. InspectorWdgt's "every inspector subwidget stays within the parent's own bounds" sentence may stay, shortened, if it adds site-local information).
- **No-trailing (3: Bin/ErrorsLogViewer/FridgeMagnets):** same conversion — the construct ADDS their missing cover. State in the conversion commit message that this heals the latent class.
- **`_reLayoutSelf`/`_reLayoutChildren` (GlassBoxBottom, ColorPicker):** identical mechanics; note GlassBoxBottom empties INV-1's checked population.
- **Build-time (ListWdgt):** identical mechanics; the cover on a possibly-unattached list is a no-op (flesh-out skips orphans).
- ⚠ CoffeeScript hazards: bodies contain `for` loops and multi-line chains — after each batch of ~6-8 files run `fg build` (the fragmented-compile syntax gate is the authority; whole-file `coffee -c` false-fails). Watch that a converted body's final expression doesn't become an accidental return value consumers read (all 26 containing methods' returns are unconsumed — verified shapes: `_reLayout`/`_reLayoutSelf`/`_reLayoutChildren`/build cores — but keep the trailing `super`/`@_markLayoutAsFixed()` lines OUTSIDE the block exactly as they sit today).

### 4.4 Fail-gate wiring
Add `DAMAGE_SUPPRESSION_UNBALANCED` beside `RESETWORLD_INCOMPLETE` in: `run-all-headless.js` (~:225 include-list + token classifier + the per-shard/summary counting that lists offending tests), `run-macro-test-headless.js`, `smoke-boot-headless.js`. Follow each file's existing token plumbing exactly — grep `RESETWORLD_INCOMPLETE` in each and mirror it.

### 4.5 INV-1 reduced to a tombstone
`check-relayout-repaints.js`: the covering-repaint invariant is now enforced by construction. Rewrite the gate to the retired-mechanism pattern (cf. `check-region-markers.js` / `check-whole-file-markers.js`): FAIL the build if `disableTrackChanges` or `maybeEnableTrackChanges` appears anywhere in `src/` (or harness src), with a message pointing at `Widget._repaintAsOneUnit`. Keep the file name (the gate slot stays occupied); rewrite its header comment to tell the story (INV-1 → structural; the D2 ghosts arc as history). Update `build_it_please.sh` invocation only if its output text is echoed there (grep). Update the `lint-and-static-checks.md` row (§4.7).

### 4.6 The two tests-repo consumers
- **`serialization-roundtrip-headless.js`:** the corruption line becomes raw tampering in the SAME evaluate/JS turn as the snapshot save, so no flush runs between corruption and load and the tripwire correctly stays silent: replace `world.disableTrackChanges();` (currently sitting several settle-cycles before the save) with `world._damageSuppressionDepth = 1;` placed IMMEDIATELY before the `serializeWorldSnapshot` call inside the same `evaluate` block. The hygiene key keeps its meaning; rename key + comment (`trackChangesRebalanced` → `damageSuppressionRezeroed` or keep the key string if renaming ripples — decide at execution, the CHECK is `world._damageSuppressionDepth === 0` after load).
- **`smoke-boot-headless.js`:** `out.trackChanges = world.trackChanges.length` → `out.damageSuppressionDepth = world._damageSuppressionDepth`; the `!== 1` check becomes `!== 0`; update the two comment lines.

### 4.7 Docs-sync (same arc, never a slapped-on note)
Every §1.5 item: the Widget/WorldWdgt comment rewrites ride §4.1; `Fizzygum/CLAUDE.md` teardown bullet: "the `trackChanges` stack" → "the damage-suppression depth"; `DETERMINISM.md` ~:170 phrase update; `lint-and-static-checks.md` INV-1 row → tombstone description ("the paired suppression verbs are retired; suppression exists only as `Widget._repaintAsOneUnit`, whose `finally` makes the covering repaint structural; the runtime twin is unchanged"); `dataflow-engine-spec.md` ~:291 + `dataflow-engine-implementation-plan.md` ~:419 spelling updates. ⚠ `.scratch` audit preludes (`fullchanged-freq-prelude.js`) wrap the old verbs — out of product scope; add one header line noting they predate this arc if touched, else leave (gitignored instruments).

## §5 Tests

- **Permanent coverage** (what survives the arc): (a) the `DAMAGE_SUPPRESSION_UNBALANCED` token in all three fail-gates — any future leak fails EVERY test loudly, which is strictly stronger than any single regression test; (b) the serialization rig's corruption step (§4.6) — the load-heals-the-counter contract, exercised every gauntlet; (c) the smoke's production round-trip check (§4.6); (d) the INV-1 tombstone — the verbs cannot come back.
- **No new SystemTest, with reasoning stated:** the healed staleness class (a no-trailing site re-laying with unchanged owner bounds while a NON-frame input moved a child) cannot be exercised from a macro without first planting a non-frame layout input in src — a macro test would either test the plant or test nothing. The construct's cover makes the class unrepresentable; the suite's 290 tests exercise all 26 converted sites continuously and byte-identity is the behavioral proof.
- **In-arc probes** (`Fizzygum-tests/.scratch/probe-repaint-as-one-unit.js`, puppeteer, model on `.scratch/probe-p6-hand.js` — boot `worldWithSystemTestHarness.html?speed=fastest&intro=0&dpr=1`, poll for `world.automator`):
  1. **Construct semantics:** wrap `_fullChanged` counting; drive one `InspectorWdgt._reLayout` (nesting: inner ListWdgt unit) — assert depth returns to 0, exactly one live owner cover fires at outer close, inner covers suppressed.
  2. **Exception path:** monkey-wrap one converted site's fn to throw mid-body; assert depth back to 0 AND the owner cover still fired AND no `DAMAGE_SUPPRESSION_UNBALANCED` on the next flush.
  3. **Tripwire plant (non-vacuity, the planted-field law):** set `world._damageSuppressionDepth = 1` raw, run one cycle; assert the console shows the token and the depth healed to 0. Then run one full suite pass with a deliberately-planted permanent corruption in a scratch build IF cheap, else the probe's console assertion + a grep of the three scripts' wiring suffices — the plant must demonstrate the RUNNERS fail, not just that the error prints: run `node scripts/run-macro-test-headless.js SystemTest_<any>` against a temporarily-planted src (`_damageSuppressionDepth = 1` injected once at boot via evaluateOnNewDocument in the probe, or a one-line temporary src edit reverted immediately) and assert exit ≠ 0. NEVER commit the plant.
  4. **Healed-sites A/B:** before/after pixel capture of a Bin re-lay scene (incremental vs `world.resetImmutableBackBuffersCache()` ground truth) — exact-0 both sides; the healed cover changes no pixels (repaint idempotence).

## §6 Central risks

- **Indentation-shift conversions in CoffeeScript** — mitigated: Edit tool only, batch-of-6-8 + `fg build` cadence (§0.5), presuite after all.
- **Hot-path cost:** the two most-called invalidation verbs change their gate read. Counter compare (`> 0`) replaces double array index — neutral-or-faster; no measurement gate needed (P6's FCFLUSH instrument exists in `.scratch` if anyone doubts).
- **The RESETWORLD ratchet** (`_auditWorldResetCompletenessNoSettle`) fingerprints world mutable state per page: the counter is 0 at every teardown → stable fingerprint; `trackChanges` disappearing is invisible to it (per-session baseline). Check `WorldWdgt._worldStateAuditExemptions` doesn't name `trackChanges` (grep; remove the entry if present).
- **Serialization fate of the new field** (§1.1 caveat): verify the world's exclusion mechanism at execution; the proof is the serialization rig + `fg homepage`'s production snapshot round-trip, both in the gauntlet.
- **In-flight ordering:** convert sites FIRST (verbs still exist, INV-1 still passes — GlassBoxBottom's body stops matching its DISABLE regex, which is fine: "only bodies that CALL disableTrackChanges are checked"), THEN delete the verbs + tombstone the gate, THEN the rig/smoke edits (they reference the verbs — the rig would crash calling a deleted verb, so its edit lands in the same change as the deletion; tests are served by symlink, no rebuild needed for script edits).
- **Zero reference churn expected everywhere** — all changes are invalidation-timing on idempotent paint; the healed sites only ADD marks. ANY pixel shift = STOP and investigate, never recapture (the owner allowed recaptures; the design needs none — a shift means a bug).

## §0.5 Cold-execution protocol

1. Orient: `/Users/davidedellacasa/code/Fizzygum-all/fg status` (all three repos clean at/past Fizzygum `3b68e1b3`; if dirty, stop and ask). Read this plan FULLY. Re-verify §1 with fresh greps (the 6 stack touchpoints; the 26-site inventory and its four shapes; the INV-1 header; the three token-carrying scripts; the rig ~:1304 and smoke ~:199/:550 lines).
2. Land §4.1 + §4.2 (construct, counter, tripwire, hot-path reads, teardown line) — `fg build` green (syntax gate + INV-1 still passing: no site converted yet, the old verbs still exist and GlassBoxBottom still matches the old shape... ⚠ CHECK: with the construct landed but sites unconverted, both spellings coexist — fine; the tripwire fires only on depth≠0 which nothing can yet cause).
3. Convert the 26 sites in batches of 6-8, `fg build` between batches; after the last batch `fg presuite` (zero churn expected).
4. Delete the two verbs + the stack declaration; tombstone INV-1 (§4.5); update the rig + smoke (§4.6) in the same step; wire the token into the three runners (§4.4). `fg build && fg presuite`.
5. Run the §5 probes (all four); record results in this doc's ledger.
6. §4.7 docs-sync.
7. Close: full `fg gauntlet` (the serialization leg + `fg homepage`'s snapshot round-trip are the counter's serialization proof). Then the close-arc ritual: ledger appended here → this plan to `docs/archive/` + status stamp + `archive/INDEX.md` case law + `docs/BACKLOG.md` flip + memory note. Present per-repo commits via `git commit -F` (Fizzygum AND Fizzygum-tests both change this arc) and WAIT for owner OK; never push autonomously.

## §6.5 EXECUTION LEDGER (2026-08-11, same-day execution; gauntlet verdict appended at close)

- **Core + conversions landed as §4 specifies**, with two in-flight findings: (1) the plan's staging note "both spellings coexist" was realized as a MIGRATION BRIDGE (the verbs re-expressed on the counter) because the dead-methods build gate rejects an uncalled `_repaintAsOneUnit` — and then the same gate flagged the bridges themselves the moment the last site converted, forcing §0.5 step 4 immediately; the gates drove the sequencing exactly right. (2) The per-site whitespace-ignoring diff (`git diff -w`) verified all 26 conversions mechanically faithful — only the construct lines and the boilerplate-comment deletions differ.
- **ONE reference churn, root-caused before recapture (the plan's zero-churn expectation missed it):** `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` img2/img3 — NOT a paint defect: adding `_repaintAsOneUnit` to `Widget.prototype` adds one row to the inspected rectangle's inherited-members list, shifting `alpha`'s index, and the test's scrollbar-drag handle→content quantization lands the list at a different scroll offset (the test's own ⚠ comment documents this exact class, kept-spec arc precedent 2026-08-06; the diff bbox is confined to the list pane — the test's fading-rectangle subjects are byte-identical). Gated recapture: ✅ COMPLETE, suite green at both densities. Owner pre-authorized recaptures for this arc.
- **Probes (`.scratch/probe-repaint-as-one-unit.js`) ALL PASS:** (1a) nesting depths [1,2,1], final 0; inner cover + inner mark suppressed, exactly ONE live outer cover. (1b) product path (inspector resize +2px): 58 mark attempts suppressed into the one owner cover, 3 live (the pre-window `_applyBounds` / post-window `super` regions — the regions the old window also left live); at UNCHANGED bounds the body attempts ZERO marks (every `_apply*` an identity no-op) — the cover is the only attempt. (2) a throwing fn: depth restored AND cover fired by `finally`, no tripwire. (3) raw corruption + one flush: token fires exactly once, depth healed to 0. (4) healed-site scene (error console re-laid at unchanged bounds): incremental == ground-truth reset, byte-equal.
- **Runner-fails plant (`.scratch/damage-corruption-prelude.js` via the AUDIT_PRELUDE rail): PROVEN** — one-shot depth corruption per shard → 16 token lines, 8 geometry-violations, `failed: 0` screenshots (the tripwire HEALED each corruption before pixels suffered) and the run still EXITS 1 on the token — loud in gates, invisible on canvas, the designed degradation. Plant never committed.
- **Probe artifact case law:** the first 1b assertion ("zero descendant marks escaped") was wrong-strict — pending arrays can only receive depth-0 marks, and leftover paint-time text-cache marks (the P5 machinery) sit in the arrays between flush and read; the honest assertion is attempts-suppressed vs recorded-live, and a no-op re-lay has nothing to suppress.
- **Docs-sync done** (§4.7 full list; the root umbrella CLAUDE.md turned out to carry no mention). INV-1 row now describes the tombstone.

## §7 Verification protocol

| Step | Gate |
|---|---|
| after §4.1/4.2 land | `fg build` (syntax + all build gates) |
| per conversion batch | `fg build`; after last: `fg presuite` — zero churn |
| verb deletion + tombstone + rig/smoke | `fg build && fg presuite`; tombstone self-test: temporarily re-add one `disableTrackChanges` call → build FAILS → revert |
| probes | §5.1-5.4 all green; tripwire plant proves runner exit ≠ 0 |
| close | full `fg gauntlet` 14/14 (serialization leg + homepage snapshot round-trip = counter serialization proof); zero reference churn anywhere |

## §8 Rejected alternatives (do not re-attempt)

- **Fix the assert alone (`and`→`or`)** — REJECTED: leaves both caller obligations in place, and the live alert fires per-frame during the serialization rig's deliberate mid-life unbalance (which settles across cycles before its save); `alert` is also the wrong channel (blocks headless pages; the established channel is the console token + fail-gates).
- **Keep the stack, add the combinator** — REJECTED: the array's only honest content is its length; keeping it preserves representable-invalid states (arbitrary booleans) for zero benefit.
- **World-side combinator (`world.suppressDamageRecordingWhile owner, fn`)** — REJECTED: keeps cross-object invalidation public (anyone can pass any owner); the Widget-side private method makes receiver==self structural, which is the invalidation-privacy arc's whole point.
- **Per-child collect-union inside the window** — FALSIFIED 2026-08-11, do not revisit without new measurements: `archive/fullchanged-trim-and-precision-plan.md` P6 ledger + §5 (the r<25% population was 99.985% instrument artifact; true population 27 windows/run).
- **A macro SystemTest for the healed staleness class** — REJECTED with reasoning in §5 (untestable without planting src; the construct makes the class unrepresentable; the token is the standing tripwire).

## §9 References

- `docs/archive/fullchanged-trim-and-precision-plan.md` (predecessor arc; P6 ledger = the two residuals this plan eliminates) + its `archive/INDEX.md` entry.
- Memory notes: `fullchanged-trim-arc`, `cross-invalidation-audit-and-gate` (privacy + receiver gate), `resetworld-state-leak-between-tests` (planted-field law), `perl-inline-edits-deindent-coffee` (Edit tool only).
- `docs/architecture/lint-and-static-checks.md` (INV-1 row); `buildSystem/check-relayout-repaints.js` header (the D2 ghosts history); `docs/archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md` §2.
- Baseline commit: Fizzygum `3b68e1b3` / tests `d04985623` (suite 290, gauntlet 14/14).

---

### Ready-to-paste start prompt for a fresh session

> Run the repaint-as-one-unit plan: `Fizzygum/docs/plans/repaint-as-one-unit-plan.md` — read it fully and follow its §0.5 protocol. Cold start: `fg status` first (repos clean at/past Fizzygum `3b68e1b3`), re-verify §1 with fresh greps (the six `trackChanges` touchpoints, the 26 idiom sites and their four shapes, the INV-1 gate header, the three fail-gate scripts, the serialization-rig corruption line and the smoke's stack check). Then: land the construct + counter + tripwire; convert the 26 sites in batches with `fg build` between; delete the verbs, tombstone INV-1, edit the rig + smoke in the same step; run the four §5 probes (the tripwire plant must prove a RUNNER fails, and is never committed); docs-sync per §4.7; close with full `fg gauntlet`. Zero reference churn expected everywhere — any pixel shift is a bug, never a recapture. Commits via `git commit -F` per repo (both Fizzygum and Fizzygum-tests change), WAIT for owner OK, never push autonomously.

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

The closed items this plan owned, relocated VERBATIM from `docs/BACKLOG.md` on 2026-08-18 so
that file can go back to being an index of OPEN work only (`docs/README.md` filing rule 2: an
arc's items leave BACKLOG when it closes). Nothing above this line changed; any item of this
arc still OPEN stayed in `docs/BACKLOG.md`.

- [x] `archive/repaint-as-one-unit-plan.md`: the paired `disableTrackChanges`/`maybeEnableTrackChanges` suppression idiom dissolved into ONE self-covering private block `Widget._repaintAsOneUnit` (cover + depth-restore in `finally`) — **EXECUTED IN FULL + CLOSED 2026-08-11, same day as authored.** All 26 sites converted (healing the three no-cover `_reLayout`s); the boolean stack → `world._damageSuppressionDepth`; the De-Morgan-dead flush assert → a LIVE self-healing `DAMAGE_SUPPRESSION_UNBALANCED` token in both runners' fail-gates (plant-proven: 8 corrupted shards, screenshots all fine because the tripwire healed first, runner still exits 1); verbs DELETED; INV-1 → retired-verbs tombstone; rig corrupts the raw field in the same JS turn as the load; smoke checks the depth. Gauntlet 14/14 all-in-wave + fg homepage + four probes green. ONE reference churn, root-caused (prototype-method addition shifts the inspector member census → scrollbar-drag quantization; the test's own comment documents the class) and recaptured COMPLETE. Case law: `archive/INDEX.md`.
