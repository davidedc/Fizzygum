# Hand-kept lists: derive them, or make them fail when they go stale

**STATUS (2026-11-06): CLOSED — §1 and all four tiers LANDED; see the §6, §5, §4 and §3 ledgers at the end. Open
residue lives in `docs/BACKLOG.md` under this plan. Written to be executed COLD by an LLM or engineer with ZERO prior
context.**

**Mandate.** Eliminate the class of defect, not its instances: a list that NAMES things declared
elsewhere (classes, fields, methods, tokens, parts) must either be DERIVED from where those things are
declared, or ASSERT its own completeness — fail when a name it holds no longer exists and when a name
it should hold is missing. "Silently checks less" is never an acceptable failure mode for a gate.

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework (`Fizzygum/src`, one class per file, every class a global,
built by `Fizzygum/build_it_please.sh`, wrapped as `fg` at `/Users/davidedellacasa/code/Fizzygum-all/fg`).
Its tests and test tooling live in the sibling repo `Fizzygum-tests` (`tests/` macro SystemTests,
`scripts/` Node rigs and gates, `Automator-and-test-harness-src/` the harness). The build runs ~30
static gates (`Fizzygum/buildSystem/check-*.js`, index: `Fizzygum/docs/architecture/lint-and-static-checks.md`);
`fg gauntlet` runs the suite three ways plus the runtime rigs (menusweep, pinsweep, serialization,
census, storage, vmtruth, …).

**Why this plan exists.** Party budget's closed window landed in the BIN while every other Examples
document was kept on the shelf. Each app that opens ONE window declared a world field name
(`slot: "sampleSheetWindow"`), and `Serializer.WORLD_APP_SLOTS` repeated five of the six names by hand
for every reader (the storage sort, the liveness roots, the snapshot, the teardown). The sixth was
never added, so that app was silently treated differently everywhere. The owner asked (a) for checks
so this kind of thing cannot happen, and (b) for an audit of similar lists.

**⭐ Critical reframe.** The dangerous lists are mostly NOT in shipping code. Shipping `src` keeps
declarations (a class's own `@serializationTransients`, `requiredParts`, AppCatalog) — single sources.
The lists that rot are in the CHECKERS: build gates and test rigs that hand-list what the framework
declares, so when the framework grows, the checker silently checks less and stays green. Five such
holes are open today (§3). A gate whose coverage shrinks without failing is worse than no gate: it
certifies what it never looked at.

## §1 Landed with this plan (context only)

`world.appWindows` — a Map keyed by app class name — replaces `Serializer.WORLD_APP_SLOTS` and the six
named world fields; `WindowedApp.opensOneWindow: true` replaces `slot`; every reader walks the Map.
New test `SystemTest_macroOneWindowAppsKeepTheirWindowOnTheShelf`. The serialization rig lists
`appWindows` among the collections only the teardown empties. (Memory note: app-window-registry.)

## §2 How the audit was done (re-run it to refresh)

- Census script: `node /Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/hand-lists/scan-hand-lists.js [--kinds-only]`
  prints every array literal made only of string literals in `Fizzygum/src`, `Fizzygum/buildSystem`,
  the harness and `Fizzygum-tests/scripts` (229 on 2026-11-05: 7 lists of class names, 44 of member
  names). It misses object tables, regex alternations, switches and push sequences — the two read-only
  audit agents covered those by hand.
- Every candidate was classified DECLARATION (single source) · SANCTIONED (a decision list a gate keeps
  honest) · MIRROR-GUARDED (drift fails something) · MIRROR-UNGUARDED (drift silent) · DRIFTED, and
  each DRIFTED/UNGUARDED one was checked against a set DERIVED from its source of truth.
- ⚠ Line numbers below drift; the quoted names are authoritative — grep them fresh.

## §3 Tier 1 — gates and rigs that silently check less TODAY (DRIFTED)

Each entry: what drifted, the evidence, the fix shape. Every fix must ALSO make the list fail on its
own staleness from now on (derive it, or assert it), not just add the missing names.

1. **Serialization rig `COLLECTIONS`** (`Fizzygum-tests/scripts/serialization-roundtrip-headless.js`, ~2051).
   Mirrors what `WorldWdgt._teardownWorldStructureNoSettle` empties. Missing `pendingFractionalBookkeepingSeeds`
   and `pendingFractionalReRecords` (cleared since 2026-08-05): deleting either `.clear()` trips nothing.
   Fix: derive at runtime — every own world field that is a Set/Map/Array — minus a STATED exclusion
   table (destroy-unregisters: `steppingWdgts`, `keyboardEventsReceivers`,
   `wdgtsDetectingClickOutsideMeOrAnyOfMeChildren`, `widgetsReferencingOtherWidgets`; filtered:
   `widgetsWithMaybeChangedPaintBounds`, `widgetsWithMaybeChangedFullPaintBounds`; per-cycle/non-widget:
   `damageRects`, `errorsWhileRepainting`, `layoutErrorsToReport`, `widgetsThatMaybeChangedLayout`,
   `_widgetsFlaggedHasDirtyDescendant`, `users`), each with its reason; fail on any collection field in
   neither. Dirty the two pending sets in the fixture's no-settle window before the load.
2. **Serialization rig `DRAG_SLOTS`** (~2069). Six of the world's eight `dragEmbed*` slots
   (`WorldWdgt.coffee` ~300–307; teardown clears all eight). Missing `dragEmbedDockBandDeclared` /
   `dragEmbedDockBandWdgt`. Fix: `Object.keys(WorldWdgt.prototype).filter(k => /^dragEmbed\w*(Declared|Wdgt)$/.test(k))`
   (class-body fields are enumerable prototype fields, `src/meta/Class.coffee`); dirty the dock band in
   the fixture (`world.dragEmbedDockBandDeclared = {host, box: host.dockBandBoxAt 'left'}`); fix the
   "six" prose (~141, ~2066, ~2119).
3. **Menu sweep `REPRESENTATIVES`** (`scripts/menu-click-sweep-headless.js` ~590). 16 roots; 20 classes own
   `addWidgetSpecificMenuEntries`. No root reaches ColorPickerWdgt, FanoutPinWdgt, PatchNodeWdgt (+ its
   concrete subclasses), StretchableWidgetContainerWdgt, VerticalStackViewportWdgt, the two layout
   specs' menus (`divisionCellMenu`, `vertStackMenu`), ConsoleWdgt's "Run selection"/"Run all" — those
   rows are clicked by nothing. An unbuilt root is `[root SKIPPED]` and not counted as bad. Fix: derive
   contributors in the page (`SourceVault.names()` → own `addWidgetSpecificMenuEntries`), fail
   `MENU_CONTRIBUTOR_UNSWEPT` for one no dispatched receiver's chain includes, keep `REPRESENTATIVES`
   as construction recipes only, count unbuilt roots as bad. ⚠ Expect newly-swept rows to surface real
   defects; triage each (that is the point).
4. **Pin sweep: appearance wearers** (`scripts/pin-sweep-headless.js` ~124). Finds wearers by the regex
   `new <AppearanceName>`, but FrameWdgt builds `new look.bodyAppearance @` — log:
   "FrameBodyAppearance contributes [corner radius] to 0 wearer(s)". The window/menu/prompt
   `corner radius` pin is never checked. Fix: derive wearers from live instances
   (`w.appearance instanceof X`) and FAIL when an appearance that contributes pins has 0 wearers.
5. **Staleness census `APPS`** (`scripts/staleness-census.js` ~100, the gauntlet's `census` leg). 10 of
   AppCatalog's 15 apps; missing SampleSheetApp, DegreesConverterApp, SampleDashboardApp,
   HowToSaveMessageApp (FridgeMagnetsApp is covered by its EXTRAS). Fix: `Object.keys(AppCatalog.entries())`
   after the existing `ensureAllLoaded`, with a stated exclude map that fails on an unknown name. Also
   `/HandWdgt|ActivePointerWdgt/` (~166): `HandWdgt` is gone — compare `w isnt world.hand`.
6. **Gates matching the RETIRED public repaint verbs.** `check-layering.js` LEAF_FORBIDDEN (~223) and
   K_REACT_CALL (~239), `census-public-private-calls.js` REPAINT_CALL (~230) and REACT_VERBS (~234) match
   `changed`/`fullChanged`, renamed `_changed`/`_fullChanged` on 2026-07-22 (0 code lines left), so
   rule [I] cannot see repaints from `__` leaves and the census's "repaints" signal is dead. Fix: one
   shared repaint-verb list in `buildSystem/lib`, read from Widget's own `_changed:` / `_fullChanged:` /
   `_fullChangedIncludingShadowOwner:` definitions (the audit measured 0 new violations and 1 sanctioned
   site re-classed, `Widget._createReferenceNoSettle` → `bringToForeground`).
7. **`check-plane-discipline.js` POSITIONAL** (~63). Misses `bottomCenter`, `leftCenter`, `rightCenter`,
   `topCenter` (and probably `fullClippedBounds`, `clippedThroughBounds`); `origin`/`corner` are not
   Widget methods. With the four centres the rule-B count is 31 vs baseline 28 (new lines:
   `fizzytiles/FridgeWdgt.coffee` ~57/87/105, magnet-to-magnet). Fix: read the position-query names
   from Widget.coffee; classify the 3 lines; set the baseline honestly.
8. **Tier-naming prelude families** (`scripts/tier-naming-audit/tier-naming-prelude.js` ~36–40).
   `_commit(Extent|Bounds)AndNotify` matches nothing; `_commitBounds` and `_applyGrantedBounds` are
   claimed by no family. Fix: at install, emit `TIERNAMING-UNCLASSIFIED` for any own
   `/^_{1,2}(apply|commit)[A-Z]/` method no family claims (minus a stated non-geometry allowlist), and
   make `run-tier-naming-gate.sh` fail on it.
9. **CoffeeScript helper globals** (`src/boot/loading-and-compiling-coffeescript-sources.coffee` ~296,
   `src/meta/Class.coffee` ~129/174, `src/meta/Mixin.coffee` ~72/83): {hasProp, indexOf, slice} is
   called "CLOSED", but the bundled compiler also emits `splice`, `objectWithoutKeys`,
   `boundMethodCheck`, `modulo`; in a class member the helper declaration is cut, so those are runtime
   ReferenceErrors. 0 uses today (latent). Fix: `check-coffee-syntax.js` (which already compiles every
   fragment the browser way) fails any fragment whose `var` head declares a helper outside the three —
   the compiler is the source of truth; it subsumes the `%%` stink.
10. **Gate tokens** (`scripts/lib/gate-tokens.js`). 9 tokens; `console.error` in src emits 13 distinct
    ALL-CAPS tokens. Unlisted: `DATAFLOW_ERROR` (legitimately emitted by green spreadsheet tests — must
    stay off), `SOURCE_COMPILE_FAILED` (boot; the smoke catches it), and two candidate misses:
    `LAYOUT_ERROR` (`WorldWdgt.coffee` ~2104, "a real bug") and `RECALC_NONCONVERGENCE` (~1400, a
    never-fire assert). Fix: a selftest that scans src + harness for `console.error "<TOKEN>` and
    requires each to be in `GATE_TOKENS` or in a `NOT_GATED {token: reason}` table; gate the two
    candidates and run the suite to see whether anything already emits them.

## §4 Tier 2 — shipping mirrors (latent; owner decisions marked ⚑)

1. ⚑ **The templates window beside the registry.** `world.simpleEditorTemplates` is special-cased at the
   same 7 sites the app windows were (WorldWdgt ~463/3077/3373/3847, StorageSorter ~105, Serializer
   ~114/153). Registering it in the same registry (`TemplatesButtonWdgt` writes it) deletes 6 special
   cases — but the registry is named for APPS; either generalise it (a world-owned window registry
   keyed by owner name) or leave the templates window as the one documented exception.
2. ⚑ **InfoDocs repeats AppCatalog** (`src/authoring/InfoDocs.coffee`): titles and `_iconFor`. Two titles
   differ ("Dashboards Maker" vs the catalog's "Dashboards"; "Drawings Maker" vs "Draw") — deliberate or
   drift is the owner's call. Fix: key InfoDocs by app class name and read title and icon from
   AppCatalog.
3. **Stale `requires`** in `buildSystem/parts.json` `example-degrees-converter`: `examples-icons` is
   justified by a `buildIcon` that no longer exists. Drop it, and make `check-part-edges.js` fail on a
   `requires` entry the part never references.
4. **Snapshot memberships** (Serializer ~318, Deserializer ~121): both list the same 4 kinds; the decode
   `switch` drops an unknown marker silently. One shared table + an `else` that throws.
5. **WellKnownObjects** `keyFor` / `resolve` list the same 8 keys; 4 classes also declare `wellKnownKey`.
   One table; an unknown key throws.
6. **"Derived cache" rule** written three times (Duplicator ~186/194, WorldInventory ~53, Widget's field
   list ~36). One shared predicate.
7. **Pointer-handler names** in `check-raw-pointer-reads.js` (16) and `check-plane-discipline.js` (8):
   derive from what `ActivePointerWdgt` dispatches, or assert both against it.
8. Smaller, verified complete today, cheap to assert: `FormulaCompiler.timeBindingNames` vs its two
   resolvers; `cellRefScan` vs `SheetModel.cellAddressPattern`; `WorldInventory._gatedKey` (gates 8 of
   14 key prefixes, fails open — list the rest as report-only explicitly).

## §5 Tier 3 — diagnostic tools that report on a stale picture (not gates)

`scripts/aim-census.js` (VERBS missing `clickPromptButton_InputEvents`, `clickTopPromptButton_InputEvents`,
`clickAfterHoldingStill_InputEvents`; stale chrome/class lists — derive from MacroToolkit and the
`extends` graph); `scripts/end-of-cycle-audit/layout-audit-prelude.js` (hooks `playQueuedEvents`, now
`_playQueuedEvents` — every record reads `boot:true`; `setElasticity`/`setWidthOfElementWhenAdded`
renamed `setGrow`/`setDesiredWidth`; tag every own declarer via `allClassFunctions()`);
`scripts/audit-preludes/revisit-trace-prelude.js` (`_stackElementSpec` → `contentStackSpec()`);
`buildSystem/census-nosettle-naming.js` (dead names); `scripts/build-tree-fingerprint.js` (stamped files
by content); `scripts/heap-forensics.js` roots (use `world.graphLivenessRoots()` + bin + shelf);
`scripts/smoke-boot-headless.js` (`danglingErrorConsole` is vacuous — reuse the rig's derived scans;
forbidden-path lists need a positive control on a dev tree); `scripts/classify-diff.js` +
`fg` `INSPECTOR_CHURN_SET` (one shared JSON, re-derived by a plant).

## §6 Tier 4 — the standing guard (so the class cannot come back)

1. **Allowlist hygiene, everywhere.** Every allowlist or exemption list reports an entry that matched
   nothing (the `check-dead-methods.js` idiom): menu-sweep `CONDITIONAL_OPENERS`/`KNOWN`/
   `ELLIPSIS_EXCEPTIONS`, `WorldTestSupport._worldStateAuditExemptions`, `SWCanvasBrokenTests` (unknown
   test names), pin-sweep `FIXTURES` keys, `@staticMembersToInstall` (assert every own static listed).
2. **A hand-list gate** (promote the census script to `buildSystem/check-hand-lists.js`, run by the
   build over src + buildSystem + the tests repo's scripts/harness): a string-list literal naming ≥2
   classes or members FAILS unless it is a recognised declaration form (`@serializationTransients`,
   `requiredParts`, `optionalParts`, a gate's sanctioned table) or carries
   `# hand-list-sanctioned: <what fails if it goes stale>` on the line above. Ratcheted at the count
   left after Tiers 1–3; the sanction text must name a real guard, so writing one forces the question
   this plan answers.
3. **Doctrine**: one paragraph in `docs/architecture/lint-and-static-checks.md` (the rule in the
   Mandate, the two acceptable shapes DERIVED / ASSERTED, and the gate) and one line in
   `widget-authoring-guidelines.md` (a world-level registry the declaring code writes into, never a
   list of names kept elsewhere — `world.appWindows` is the worked example).

## §7 Cold-execution protocol

1. `fg status`; read this plan, then `docs/architecture/lint-and-static-checks.md` §1–2.
2. Re-run the census (§2) and re-verify each Tier-1 item against current code before touching it.
3. One tier at a time; within a tier, one item per commit-sized unit. For each: make the list derived
   or asserted, then PROVE the new check bites — plant the drift (rename a field, drop a name, add an
   unlisted collection) through `PRELUDE_JS` or a scratch copy and watch it fail; then watch it pass.
4. Gates per unit: `fg build` (static gates) or the rig itself; per tier: `fg gauntlet` + `fg homepage`.
   A newly-swept root/row that fails is a FINDING to triage, never a reason to narrow the check.
5. Never commit or push without the owner's approval (`git commit -F <file>`).

## §8 Verification protocol

`/Users/davidedellacasa/code/Fizzygum-all/fg build` · `fg presuite` (inner loop) · `fg gauntlet`
(19 legs, ~15 min, run in the background) · `fg homepage` · the individual rigs (`fg menusweep`,
`fg pinsweep`, `fg census`, the serialization leg) for their tier-1 items · `npm run selftest` in
`Fizzygum-tests` for any selftest added.

## §9 Rejected alternatives

- **Just add the missing names.** It fixes today's instance and leaves the list to rot again — the
  exact history of `WORLD_APP_SLOTS`, `COLLECTIONS` (created 2026-07-29, outgrown 2026-08-05) and
  `DRAG_SLOTS` (created 2026-08-21, outgrown 2026-08-24).
- **A per-line stink in `check-stinks.js`.** It scans one line at a time, and the lists that rot are
  multi-line (one name per line); it would see none of them.
- **Banning string lists outright.** Shipping src's lists are mostly declarations; a ban would be all
  noise and push authors to hide names in other shapes.

## §10 References

Memory notes: app-window-registry, document-icons-and-maker-documents. Related gate docs:
`docs/architecture/lint-and-static-checks.md`; the census engine pattern `buildSystem/check-dead-methods.js`
(the allowlist-reports-stale idiom). Raw audit reports: re-derivable by §2.

## §6 ledger — Tier 4 LANDED (2026-11-06)

Every check below was seen failing on a PLANT and passing without it (plants: `Fizzygum-tests/.scratch/hand-lists-t4/`;
gates via scratch copies, rigs via scratch copies or `PRELUDE_JS`). Doctrine: `docs/architecture/lint-and-static-checks.md`
§5 ("The rule holds for EVERY hand list…", "Every stated table fails on an entry that names nothing") and §3's
`hand-lists` row; `widget-authoring-guidelines.md` §4.3 (a fact the world reads about a class goes in a registry its
own code writes into; `world.appWindows`).

1. **Allowlist hygiene (§6.1), widened to every stated table** (a read-only inventory found 37; 23 had no stale
   handling). One word everywhere: `STALE_ALLOWLIST_ENTRY <table> <entry> — <why>` (a gate token in the page).
   - Build gates: the three central `.txt` allowlists (their stale NOTE is a FAIL now; the dead-method symmetry-redundant
     case too); `check-layering`'s `USERLAND_FILES` (a moved file made rule [R] check nothing), the [O]/[Q] caller
     allowlists (keyed by method name in ANY class), `WRAPPER_EXCLUDED`; the stinks `exclude` prefixes;
     `check-raw-pointer-reads`' extra handler names and skipped class; `check-shippable-coverage`'s and
     `check-source-vault`'s exemptions; `check-plane-discipline`'s `NON_WIDGET_ROOTS` (finding: ALL SIX entries were
     stale — none is ever a receiver; the table is empty and checked); `check-unresolved-sends`' `BUILTINS`, pruned from
     249 names to the 107 some call sends (residual: 29 sent names Fizzygum also defines, BACKLOG).
   - Harness: `WorldWdgt._worldStateAuditExemptions` (an exemption the sweep never meets, reported at the page's
     baseline call); `SWCanvasBrokenTests` (a name the manifest lacks; a density's list is found by its
     `testNamesDpi<N>` key, so a new density's list is used AND checked); `@staticMembersToInstall`, held to the support
     class's own class-side keys both ways by `buildSystem/lib/install-edges.js` (`STALE_ALLOWLIST_ENTRY` /
     `UNLISTED_STATIC`; its two gates exit 2 naming them).
   - Rigs: the menu sweep's six tables (a direction-keyed entry counts only when ITS direction matched; skipped,
     loudly, in a partial run); the pin sweep's `FIXTURES`; the lazy-icons `SAMPLE` (+ `ISOLATION_CHECK_VACUOUS`); the
     serialization rig's `DAMAGE_FIELDS` (asserted, not derived — it states which fields must never ride a file) and
     `SWCANVAS_ONLY_CHECKS` (held both ways on every full run).
   - ⭐ Findings: two `CONDITIONAL_OPENERS` entries read stale on the first run because the sweep had LOST REACH (the
     rows exist): a `HandleWdgt` root and an overflow-chevron remainder-menu root brought them back. With reach
     restored, `HandleWdgt.attach` was really stale (a handle on the canvas always has the world as a candidate) and
     `WorldWdgt.popUpDemoTestMenu` was excusing a mismatch its stated reason did not describe — a probe showed every
     non-opening dispatch had a DESTROYED subject (the row's target, the world, was alive), so the walk now judges a
     row's SUBJECT's liveness too (a dead subject is `stale`, like a dead target) and both entries were deleted.
     Product finding (owner's call, BACKLOG): `HandleWdgt.attach` builds a "no widgets to attach to" message it never
     shows.
2. **The hand-list gate (§6.2)** — `buildSystem/check-hand-lists.js`, on the build beside the dead-method gate: the
   census's multi-line tokenizer over src + buildSystem (+ the tests repo's scripts and harness when present; that half
   SKIPS without it); a NAME list = at least two items, and at least half, that are class or member names; each is a
   DECLARATION (`@serializationTransients`, `requiredParts`, `optionalParts`), SANCTIONED (`hand-list-sanctioned:` whose
   text resolves to an existing gate/rig file, `SystemTest_<name>` or emitted token — `SANCTION_NAMES_NO_GUARD`,
   `SANCTION_STALE`, `SANCTION_EMPTY` fail outright) or counted. `--census`, `--files`, `--self-test` (38 checks, proven
   by 11 deliberately broken copies of the gate). The census found 52 name lists; the sanction pass (each guard's
   claim checked, mostly by an in-memory plant) left **4 unsanctioned in Fizzygum — the LiveCodeLang vocabulary,
   whose fix is that plan's R1 — and 0 in the tests repo**: `BASELINE_FIZZYGUM = 4`, `BASELINE_TESTS = 0`. Writing the
   sanctions surfaced lists that went stale SILENTLY and were fixed instead of sanctioned: the boot's
   `["Class", "Mixin", "globalFunctions"]` (now one boot constant `META_SYSTEM_SOURCES`, read by
   `dependencies-finding` and the compile job; `globalFunctions` had no vault source and was a phantom job item);
   `check-page-loaded-elements`' hooks (a hook renamed at its WALKER's call site kept the gate green — now held to the
   walkers); `FrameBarWdgt.PIECE_DROP_ORDER` (a stale name was skipped by `indexOf >= 0`; no test narrows a strip until
   a piece drops — now `BAR_PIECE_UNORDERED`, a gate token); the inspector popout list (held to the inspector's "…"
   buttons, `POPOUT_BUTTON_UNSWEPT`); the serialization rig's shown-facts keys (derived from `shows()`) and remediation
   names (held to the live classes); `aim-census`'s widget-source exclusion (derived from the `extends` graph). Two
   diagnostics now fail on their own staleness: `aim-census.js` (exit 1 on a stale name, 2 on an empty derivation) and
   the layout survey's aggregator (exit 1 when the prelude reported a stale name).
3. **Shared name modules** (the same family was hand-spelled in two or three gates): `lib/settle-tiers.js` (Widget's
   `_settleLayoutsAfter…`, held to its body both ways; `_settleLayoutsAfterBatch` was dead in the census),
   `lib/settling-setters.js` (the public geometry/text setters that self-settle, DERIVED — the rule reproduces today's
   eleven names exactly), `lib/immediate-mutators.js` (the apply 2x2's named groups, asserted both ways; five dead names
   left `isImmediateMutator`, `_applyGrantedBounds` joined rule [E] at 0 new violations, rule [K]'s commit-corner arm
   now has its real subject `_commitBounds`). Readers: `check-layering`, `census-public-private-calls`,
   `census-nosettle-naming`.
4. **Doctrine (§6.3)** — the two paragraphs and the table row in `lint-and-static-checks.md`, the
   `widget-authoring-guidelines.md` §4.3 section, the gate count (31) in both CLAUDE.md files.

## §5 ledger — Tier 3 LANDED (2026-11-06)

Each tool reports on the real picture — its names DERIVED from the declarations, or its stated tables ASSERTED against
them — and says so loudly when a name goes stale (diagnostics, not gates: a finding line or a non-zero exit, never a
silently narrower picture). Each was run before and after, with every moved number explained.

1. **`aim-census.js`** — `VERBS`/`NON_AIM_VERBS` are decision tables held to every `…_InputEvents` key of MacroToolkit
   and every `…_InputEvents_Macro` its heredocs define (84 verbs): `AIM-CENSUS STALE NAME` / `UNCLASSIFIED VERB` /
   `CLASSIFIED TWICE` / `STALE ARGUMENT` / `UNKNOWN VERB`; the press/text/screenshot patterns come from one table; the
   geometry and locator names are read off the declaring classes; text, chrome and window classes from the `extends`
   graph; `AIM_CENSUS_SRC` points it at a scratch tree for plants (11, all biting). 1777 → 1797 sites (the prompt-button
   clicks the old table missed). Findings: `pressPointOf` credited as verb-verified; 20+ names that named nothing
   (`WindowWdgt`, `ScrollbarWdgt`, eight chrome members, …); every prompt, inspector and console button invisible as
   chrome.
2. **`layout-audit-prelude.js`** — hooks `_playQueuedEvents` (the stale `playQueuedEvents` hook left every record
   `boot:true`), the renamed setters; HOOKS/READS/TAGGED tables asserted at install (`LAYOUTAUDIT_STALE_NAME`,
   `LAYOUTAUDIT_UNHOOKED_OVERRIDE`, held to the first test start); a tagged method is wrapped on every own declarer
   under its scope through `allClassFunctions()` (16 overrides the class lists never tagged). Finding, fixed: records
   stored the layout SPEC object, circular for a stack element, so the first such record would throw inside the wrapped
   flush.
3. **`revisit-trace-prelude.js`** — `contentStackSpec()`; `_reLayout` wraps from `allClassFunctions()` (an
   `Object.keys(window)` walk missed classes shadowed by browser built-ins); the same assertion. ⭐ Plant lesson: a
   prelude plant must not call `classNamed` mid-boot — it reads `NativeValueKinds`, which compiles late, and the throw
   ended the plant's poll silently (a pageerror the LOG_FILE does not hold); plants now wait on the prelude's own gate
   and say `PLANT NOT APPLIED` loudly.
4. **`census-nosettle-naming.js`** — the three shared modules above; stale ⇒ exit 2.
5. **`build-tree-fingerprint.js`** — a stamped file is recognised by CONTENT (the `buildVersion` form), where a stamp
   belongs is read from each entry page's `<script src>`, and only the stamp's value is masked, so the rest of a boot
   bundle is compared byte for byte; `[FORMAT] 2` (an old-format compare is INVALID — ⚠ `fg fingerprint` writes its
   baseline with the COMMITTED copy, so it reads INVALID until this lands).
6. **`heap-forensics.js`** — lens 1's roots = `world.graphLivenessRoots()` + bin + shelf; `--selftest` OK.
7. **`smoke-boot-headless.js`** — the round-trip judges what the load leaves with the serialization rig's own scan (new
   shared `scripts/lib/world-holdings.js`) on a world dirtied first (an error console and a tooltip, through product
   API), failing VACUOUS unless the scan saw them; the forbidden-path lists get a positive control on a dev tree; a
   `PRELUDE_JS` rail.
8. **classify-diff + `fg recapture-inspector`** — one `scripts/inspector-churn-set.json` through
   `scripts/lib/inspector-churn-set.js`; classify-diff warns on a stale name, `fg` refuses; re-derived by
   `scripts/derive-inspector-churn-set.js` (the plant is an OWN field on every widget — the inspector hides inherited
   members); `--check` MATCHES today (15 of 368).

## §4 ledger — Tier 2 LANDED (2026-11-05)

Owner calls (AskUserQuestion, both the recommended option): ⚑1 = the templates window becomes a
one-window app; ⚑2 = InfoDocs reads its names from AppCatalog. Each item was proven by a plant that
fails it and a run that passes without it (plants under `Fizzygum-tests/.scratch/hand-lists-t2/`).

1. ⚑ **Templates window** → `TemplatesApp` (`src/authoring`, `opensOneWindow: true`, buildWindow =
   `TemplatesWindowWdgt.create()` + the old first-open placement, no AppCatalog entry — it has no
   launcher, and an entry would make the serialization rig report a missing one).
   `TemplatesButtonWdgt.activated` = `(new TemplatesApp).launch()`. `world.simpleEditorTemplates` and
   all 7 special cases DELETED (field, restore, teardown, liveness roots, storage sort, snapshot root
   + section). Behaviour now uniform with every app window: a re-open lands at hand+(100,-50), a
   window nested elsewhere is pulled back to the desktop. `SystemTest_macroOneWindowAppsKeepTheirWindowOnTheShelf`
   gained the templates button as its seventh door (no test clicked it before); plant
   `plant-unregistered-templates.js` fails exactly that leg; follower-proven on both pointers.
   Call-separation [U] baseline 104 → 101 (the button's two self-only helpers went; one older gain banked).
2. ⚑ **InfoDocs** keyed by app class name; an app entry states only its body, and its heading,
   "<name> info" window title and icon come from AppCatalog (`InfoDocs._identityOf`, which throws on
   an app entry stating a title/icon, a non-app entry stating none, or an unknown key — probe
   `probe-infodocs-identity.js`). Callers pass `@constructor.name`. Titles now: "Dashboards info",
   "Draw info", "Generic panel info" (were "Dashboards Maker info", "Drawings Maker info", "Generic
   panels info"); headings "Dashboards", "Draw". Predicted changed set EMPTY — no test opens those
   three info windows — and the suite confirmed it (zero recaptures). Every app-keyed doc is built by
   the `apps` gauntlet leg.
3. **parts.json**: `example-degrees-converter` requires `app-kit` only. `check-part-edges.js` now
   fails a `requires` entry the requiring part's code never names (comments/strings excluded); the
   real stale entry was the plant (1 of 21 → fixed, 0 of 20); `--self-test` covers the rule.
4. **Snapshot memberships**: ONE table `Serializer.WORLD_SET_MEMBERSHIPS` (marker → world Set field,
   with the per-marker verdicts), read by the writer and the decoder; an unknown marker is an
   envelope shape problem (`Deserializer._envelopeShapeProblem`), so a world load refuses it BEFORE
   its teardown and `deserialize` throws up front.
5. **WellKnownObjects**: ONE table `_liveSingletons` read by `keyFor` (identity) and `resolve` (lookup);
   an unknown non-app key THROWS in `resolve` and is refused up front by the shape check (via the
   shared walk `Serializer.wellKnownKeysIn`, which `classNamesIn` now uses too); a class marker
   (`wellKnownKey`) the table lacks is refused at save. App keys naming an absent class still
   resolve to undefined (unchanged, rig-gated). The four classes' string `wellKnownKey` markers
   (PreferencesAndSettings, Wallpaper, DataflowEngine, WidgetFactory), redundant with the identity
   match, were DELETED on the owner's call; the marker survives only as `WindowedApp`'s
   `"app:" + @constructor.name`.
6. **Derived state**: ONE predicate `Widget.isDerivedStateField` (cache pairs, `childrenBoundsUpdatedAt`,
   `_islandBufferSource*`), read by the Serializer, the Duplicator and WorldInventory; the 19 hand-listed
   cache names left `Widget.@serializationTransients`.
7. **Pointer handlers**: ONE table `buildSystem/lib/pointer-handlers.js` read by both body gates and
   held against `ActivePointerWdgt` both ways (a table name the dispatcher never names; a method
   handed a pointer position that the table lacks, minus stated `POSITION_QUERIES`). Three plants
   (renamed handler, new positional dispatch, renamed query) each caught. Stated blind spot: a new
   handler dispatched with no position.
8. **Small mirrors**: `FormulaCompiler.TIME_SOURCES` (binding → source thunk) replaces
   `timeBindingNames` + the two hand-spelled resolvers; `SheetModel.cellRefScan()` is DERIVED from
   `cellAddressPattern` (identical source, probed); `WorldInventory.KEY_FAMILIES` names all 14
   key families (8 gated, 6 report-only) and an undeclared family fails CLOSED (gated).

## §3 ledger — Tier 1 LANDED (2026-11-05)

Every item was proven by a PLANT that fails exactly the new check, with a detail naming the plant, and a
run that passes without it. Plants: `Fizzygum-tests/.scratch/hand-lists-t1/` (runtime rigs via the new
`PRELUDE_JS` rail, `Fizzygum-tests/scripts/lib/prelude-from-env.js`, now honoured by every rig touched here;
build gates via `--files` or a scratch tree). Doctrine: `docs/architecture/lint-and-static-checks.md` §5,
"The names a gate keys on are DERIVED, or ASSERTED".

1. **Serialization rig `COLLECTIONS`** → every own Set/Map/Array field of the world, read once the fixture has
   dirtied it, minus `NOT_EMPTIED_BY_THE_TEARDOWN` (13 entries, each with its verified reason; the plan's reasons
   were corrected for `widgetsReferencingOtherWidgets` — ShortcutWdgt unregisters it —, the layout work-list pair
   and `users`). New check `collectionsClassified` (stale exclusion, empty derivation). `fixtureDirtied` names what
   it did not dirty. The pending fractional sets are dirtied raw in the no-settle window, and
   `transientCollectionsCleared` also reads CORPSES in the load's own turn — the cycle drains both sets, so a
   post-settle read could never see them. Plants: unlisted collection, uncleared pending sets, stale exclusion.
2. **`DRAG_SLOTS`** → `WorldWdgt.prototype`'s `dragEmbed…(Declared|Wdgt)` keys (8); the dock band is dirtied on the
   converter's window; the count prose is gone. Plant: an unlisted slot.
3. **Menu sweep** → contributors DERIVED (every class owning `addWidgetSpecificMenuEntries`), each wrapped to tag
   the rows its call adds; REACHED = one of its rows was DISPATCHED (`MENU_CONTRIBUTOR_UNSWEPT` / `_CHECK_VACUOUS`);
   an unbuilt root is `ROOT_UNBUILT`, a failure. ⭐ "Its code ran" was measured insufficient: in dev mode the
   generic "Destroy" row precedes a widget's own rows, so on every bare representative the own rows arrived stale —
   68 never clicked. Every recipe now yields `<Class>` and `<Class>[own rows]`; recipes take an optional `fill`
   (a container's own rows need it to hold something); new nested roots: a fanout's pin, a division cell, a
   document paragraph, a console's text. 32 → 54 roots, 20/20 contributors reached. Finding: "Run contents" on
   prose throws (`KNOWN`, BACKLOG). Plants: a contributor no root reaches, an unbuildable root.
4. **Pin sweep** → wearers = the `new <Appearance>` text edge ∪ the LIVE edge (`Widget.instances`, exact
   appearance class) after a stated population (window, menu, prompt); `APPEARANCE_PIN_WITHOUT_WEARER` fails
   (also `PINS_THREW`, `POPULATION_SHAPE_THREW`). FrameBodyAppearance 0 → 19 wearers. Plants: the frame's
   `setCornerRadius` shadowed (21 violations; the old rig stayed green), a pin-contributing appearance nobody wears.
5. **Staleness census** → the app battery is every class extending `WindowedApp` (16 — the class graph, not
   AppCatalog: `TemplatesApp` has no launcher yet opens a window); `NOT_BATTERIED` (empty) fails stale; the hand
   regex became `w !== world.hand`. ⭐ Finding: `SimpleLinkWdgt`/`SimpleVideoLinkWdgt` sit at stale geometry in the
   "How to save?" and templates windows — a grandchild resize the down-walk never re-lays (root cause traced:
   `DocumentViewportWdgt._positionAndResizeChildren` → the stack's `_positionAndResizeChildren` → `_applyExtentBase`).
   Recorded in a new `KNOWN_MOVERS` table (stale entry fails); the engine fix is an owner call (BACKLOG).
   Plants: an app the battery never saw, a stale `KNOWN_MOVERS` entry.
6. **Repaint verbs** → ONE module `buildSystem/lib/repaint-verbs.js` (Widget's own `_changed` / `_fullChanged…`,
   throws if either base verb is missing), read by check-layering [I]/[K] (output byte-identical), the call census
   (`_createReferenceNoSettle → bringToForeground` re-classed, pre-sanctioned; the public-only `REACT_VERBS` branch,
   which could never fire, deleted) and — beyond the plan, same defect — `check-invalidation-receivers.js`, whose
   pattern still named `_updateBroken` (renamed `_repaintDamagedRects` 2026-08-18, header updated, regex not: the
   paint executor was checked by nothing) and could not match `_fullChangedIncludingShadowOwner`. The executor's
   name is now asserted against WorldWdgt. Finding: `Widget._addNoSettle`'s old-footprint mark was unmarked —
   sanctioned as the structural-move twin of the mark below it. Plants: a leaf repaint, a dropped sanction, the
   verb renamed (exit 2), a stray `world._repaintDamagedRects()`.
7. **Plane discipline B** → the position queries are read from Widget.coffee (no-parameter methods answering a
   one-line `@bounds` delegation, or named `…Bounds`) minus `NOT_POSITIONAL` (sizes, the screen query, a predicate;
   stale fails, empty exits 2): 26 names (the four centres, the `…Tight` edges, the clipped/merged/SLOW rectangles
   joined; `origin`/`corner`, never Widget methods, left). Baseline 28 → 31: three FridgeWdgt magnet-to-magnet
   lines, same plane by construction. Plants: a new cross-plane line, a stale exclusion, a vacuous derivation.
8. **Tier-naming families** → NAMED sets (leaf, arrange, notify — `_commitBounds` joins leaf and
   `_applyGrantedBounds` notify, per `layering-naming-convention.md` §2; the dead `_commit…AndNotify` arm left) plus
   a `NON_GEOMETRY` table, held to every class's own `_apply*`/`_commit*` METHODS both ways at install
   (`TIERNAMING-UNCLASSIFIED` / `-STALE`; `-CLASSIFIED` is the measurement proof, its absence INVALID); the lines are
   held and printed at the first test start, because the runner drops audit lines that precede one. The react verbs
   are read from Widget too. Plants: an unclassified `_apply*` corner, a stale family name.
9. **CoffeeScript helper globals** → `check-coffee-syntax.js` taps the real `Class._removeHelperFunctions` and fails a
   member whose stripped `var` head declares a name outside the PROVIDED set (read from
   `Class._memberNamesThatMustStayAnonymous`, held against boot's assignments); `--files` testing hook; the `%%`
   stink retired. ⭐ Finding, fixed: `CanvasWdgt.clear`'s default `(color = @color ? @_surfaceFill())` hoisted a `ref`
   temporary into the stripped head, so every call leaked a page-wide `window.ref`. Plants: `%%`, a range assignment,
   a hoisted temporary (fail); a control member (passes).
10. **Gate tokens** → `scripts/lib/gate-tokens-selftest.js` (in `npm run selftest`) holds `GATE_TOKENS` and a new
    `NOT_GATED {token: reason}` table to every `console.error "<TOKEN>` in src + harness, both ways, with a corpus.
    Gated now: `LAYOUT_ERROR`, `RECALC_NONCONVERGENCE`, and `SOURCE_COMPILE_FAILED` (its own comment promised every
    headless gate fails on it; the runners file a boot-time token under "(boot/setup)"). Ungated, with reasons:
    `DATAFLOW_ERROR` (green by design), `FIZZYGUM_USE_SWCANVAS` and `SHA256` (not distinctive — the runners match a
    token as a substring of every console line). The suite emits none of the new gates. Plant: an ungated token.

**Follow-ups (2026-11-06, owner-directed after the Tier 1 review).** Two of the findings above are fixed:
- **The grandchild resize** (item 5) is fixed in the settle engine. The B3 snapshot in
  `WorldWdgt.__reLayoutOneSettleNode` saw only the settled node's children, and an arrange reaches deeper (a viewport
  runs its stack's arrange; a stack sizes a nested window or stack through `_setWidthSizeHeightAccordingly`). Now
  `_applyExtentBase` notes a composite it sizes as a leaf (children, no `_reLayoutChildren`),
  `_markLayoutAsFixed` strikes the note, and after each settled node's `_reLayout` the engine re-lays whatever is
  still noted (`__reLayoutCompositesResizedSince`) — the B3 guarantee at any depth (`layout.md` §3). The census's
  `KNOWN_MOVERS` went stale exactly as designed and is empty. Plant: the note disabled → the census fails on
  `SimpleLinkWdgt` / `SimpleVideoLinkWdgt` movers.
- **"Run contents" on prose** (item 3): the finding's premise was half wrong — a real click DID show something: the
  throw reached the world's input-event catch, which soft-resets the world, pops the Error log with the compiler's
  message and a stack of the framework's own calls, and leaves the clicked menu open (the sweep calls the action
  directly, so it saw only the throw). Every RUN gesture over typed text (`TextWdgt`'s Run contents / Do all / Do,
  Show, Inspect selection; the console's two; the script's Try it) now goes through `Widget._reportingCompileErrors`:
  text that does not compile is reported at the hand ("Cannot run this as code (line L, column C): …", read from
  the compiler's own error, which `compileFGCode` now keeps as the thrown Error's `cause`); code that compiles and
  then throws still reaches the Error log, where its stack is the person's own. The sweep's `KNOWN` entry is gone.
  Plant: the helper rethrowing → the menu sweep fails `THREW:doContents`. The SAVE gestures stay open (BACKLOG).

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

Two items relocated VERBATIM from `docs/BACKLOG.md` on 2026-11-06 (`docs/README.md` filing rule 2); how each closed
is in the §3 ledger's follow-ups above. ⚠ The second item's "with nothing shown to the user" was wrong — see there.

- [x] **A grandchild resize escapes the down-walk** (census `KNOWN_MOVERS`): `DocumentViewportWdgt._positionAndResizeChildren`
      calls its stack's `_positionAndResizeChildren` directly, which widens the stack's children through
      `_applyExtentBase`; the walk re-lays only the children an ARRANGE resized, so those grandchildren keep the
      layout of a narrower frame — visible as a ~70 px gap beside the link button in the "How to save?" window
      (3 px in the templates window). Engine-level, and its fix recaptures every test showing those windows: owner's call.
- [x] **"Run contents" on prose throws** (menusweep `KNOWN` `THREW:doContents`): `TextWdgt.doContents` →
      `Widget.evaluateString` → `compileFGCode` rethrows the compile error out of the menu action, with nothing shown
      to the user (the Console's "Run all" shares the path). Report it instead of throwing?

Relocated VERBATIM from `docs/BACKLOG.md` on 2026-11-06 at the arc's close; each is closed by the §6 ledger (item 3)
or the §5/§6 ledgers as a whole.

  - [x] **check-layering's static apply-corner families are not held to the source**: `isImmediateMutator` /
        `APPLY_CORNER` keep the `_commit(Extent|Bounds)AndNotify` arm that matches nothing and omit
        `_commitBounds` / `_applyGrantedBounds` (the tier-naming prelude now classifies both, asserted both ways).
- [x] Tier 3 (§5): diagnostic tools reporting on a stale picture (aim-census, layout-audit and
      revisit-trace preludes, census-nosettle-naming — which also hand-lists the repaint verbs `lib/repaint-verbs.js`
      now owns —, heap-forensics roots, smoke-boot).
- [x] Tier 4 (§6): the standing guard — allowlists report unused entries; a hand-list gate; the doctrine.
