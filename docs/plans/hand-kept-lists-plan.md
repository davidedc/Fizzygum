# Hand-kept lists: derive them, or make them fail when they go stale

**STATUS (2026-11-05): §1 and Tier 2 (§4) LANDED — see the §4 ledger at the end; Tiers 1, 3, 4 OPEN.
Written to be executed COLD by an LLM or engineer with ZERO prior context.**

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

