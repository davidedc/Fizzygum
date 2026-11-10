# Mixin teardown census — 2026-11-10

Phase 0 deliverable of `docs/plans/mixin-removal-plan.md` (its §7 Phase 8). Read at Fizzygum
`a59221da` / Fizzygum-tests `61adb7ce1`. **Made by reading only — nothing was built or run** — so a
"what happens" below is a reading of the code, not an observation. Line numbers are hints; the
identifier is authoritative. Nine of its claims were re-checked against the files afterwards and
all held: the uncounted self-test; the subjects of the lazy-part section, of the class-subjects
check and of the serialization donor checks; the smoke verdict's `augmentations > 0`; the
sanctioned entry in `check-stinks.js`; the header library's mixin branch; `build.py`'s silent glob;
and where `Class.coffee` names `Mixin`. §5 was counted separately, by grep.

The question: every build tool and test rig that references the mixin mechanism — what does each
one need when the mechanism goes, and can any of them go BLIND instead of failing?

The file set is the output of

```
cd Fizzygum
P='[Mm]ixin|augmentWith|augmentedWith|_class_injected_in|onceAddedClassProperties|addInstanceProperties'
grep -rlE "$P" buildSystem
grep -rlE "$P" ../Fizzygum-tests/scripts | grep -v '/.scratch/'
```

45 files under `buildSystem/`, 16 under the tests repo's `scripts/`.

## 1. Findings that change the plan

- **The pattern misses all-caps tokens.** `[Mm]ixin` does not match `MIXIN_…`, so
  `../Fizzygum-tests/scripts/graph-liveness-selftest-headless.js` (`MIXIN_CHAIN_TERMINATES`) is
  outside the set. Search case-insensitively.
- **The pattern also matches "mixing".** `buildSystem/check-plane-discipline-selftest.js` is in the
  set for that word alone.
- **Checks break in the phase that deletes their SUBJECT mixin, before the teardown:**

| Mixin deleted | What breaks | Why |
|---|---|---|
| `KeepsRatioWhenInVerticalStackMixin` | `parts-lazy-load-headless.js`, its `LAZY_CONSUMER_TAKES_MIXIN_EDITS` section | the section's subject is that mixin, through the lazy `plots` part |
| `ControllerMixin` | `serialization-roundtrip-headless.js`, `world.inspector.classSubjectsSurviveSnapshot` | its subject member is `openTargetSelector` |
| `BackBufferMixin` | `buildSystem/check-stinks.js`, a sanctioned entry; the capstone gate's diagnose text (comment only) | both name the mixin's file |
| `HighlightableMixin`, `ParentStainerMixin` | the serialization rig's donor checks and `sourceEdits.loadOverPageEditsIsTheFilesWorld`; the four SystemTests of §5 | their subject is one of the two |
| the last one, whichever it is | `smoke-boot-headless.js` | a verdict requires `augmentations > 0` |

- **One library can blind several gates at once** (`buildSystem/lib/coffee-method-header.js`, §4
  answer 1). Its mixin branch is what lets a gate see a member written deeper than two spaces
  inside an object literal. If a mixin's new home were such a literal, every gate using the library
  would stop seeing its members and report nothing. A member of a class body, at two spaces, is
  seen by the ordinary path.
- **`"src/mixins"` left in `buildSystem/parts.json` is silent:** `build.py` globs a missing
  directory to nothing, and no stale-directory check was found.

## 2. Counts

C = comments or message text only. D = code that parses or models the mixin DSL. R = a rule, token,
allowlist entry, expectation or plant keyed on a mixin name or on the mixin concept.

| | C | D | R | D+R | total |
|---|---|---|---|---|---|
| `buildSystem/` | 13 (one a pure false hit) | 20 | 6 | 6 | 45 |
| tests `scripts/` | 8 | 0 | 7 | 1 | 16 (+1 outside the set) |

## 3. Per file

### `buildSystem/`

| File | Class | Identifiers (line hints) | Teardown | Risk |
|---|---|---|---|---|
| `build.py` | D | `IS_MIXIN` 64, 365, 384; `sourceName == "Mixin"` 412 | drop the regex and the `or is_mixin_file` arm; emit `Class-source.js` only | boot must stop fetching `Mixin-source.js` in the same commit |
| `buildProfile.py` | C | 113, 278 | reword | none |
| `census-call-arity.js` | C | 11 | reword | none |
| `census-hierarchy-duplication.js` | D+R | R: `SHADOWS-MIXIN` / `shadowsMixin`; D: `viaMixins` from `info.mixins` 173–175 | retire the category; drop `viaMixins` | advisory only; throws if the shared model drops `.mixins` first |
| `census-nosettle-naming.js` | D (thin) | `mixinHashIndent` 106–115 | drop the threaded state | none |
| `census-property-placement.js` | C | names `DeepCopierMixin`, which no longer exists | reword | none |
| `census-public-private-calls.js` | D | `classInfo.mixins`; the `@augmentWith` regex 194–195; `mixinHashIndent`; chain 224–235; import `MIXIN_METHOD_HEADER` | remove `mixins[]`, the regex, the mixin visit and the import | change together with its `.mixins` reader (`census-hierarchy-duplication.js`) |
| `census-widget-conformance-selftest.js` | R | plant `BiteProofDonorMixin` | delete the control case, or re-plant on a parent class | none |
| `census-widget-conformance.js` | D | own detector 63, 70–71; `declarationsOf` mixin branch; `mixinsOf`; mixin units 159–169 | delete the mixin map and branches | facet 1 is a build ratchet at zero: a field a mixin declares today must be declared in its consumer's `extends` chain, else a loud fail |
| `check-back-buffer-memos-selftest.js` | R | plant `BiteProofBuilderMixin`; expects `BUILDER_IN_MIXIN` | delete with the rule | rule and proof go together |
| `check-back-buffer-memos.js` | D+R | D: `mixins{}`, `augments`, the merge; R: `BUILDER_IN_MIXIN` 170 | delete the map, the merge and the rule | none of the eight mixins declares transients, saved content or a builder, so the merge adds nothing today |
| `check-call-arguments-selftest.js` | D | copies the real `meta/Mixin.coffee` 31 | drop it from the copy list | uncaught ENOENT once the file is deleted |
| `check-call-arguments.js` | C | 19 | reword | none |
| `check-coffee-syntax-selftest.js` | R | plants 35–36, 45–46; the `pass` regex needs `\d+ mixins` | delete the plants; update `pass` | in lockstep with the gate's summary line |
| `check-coffee-syntax.js` | D | `Mixin` 100, 107; `IS_MIXIN` 204, 224; `new Mixin` 228; `nMixin` | see §4 answer 2 | a non-class file is then counted "skipped", unchecked |
| `check-dead-methods.js` | D | own `mixinsOf`, own `chainOf`, `mixinHashIndent` | delete `mixinsOf` | none; its inventory is two-space headers |
| `check-hand-lists.js` | D | `mixinMemberIndent` 120, 415–419 | delete the mixin-key branch | fails loud |
| `check-layering.js` | D | `mixinHashIndent` at three sites; comments naming `ClippingAtRectangularBoundsMixin._applyMoveBy` and `ControllerMixin._fireConnection` | drop the threading; reword | `nearestDefinerKind` walks `extends` only: an ex-mixin method resolves to nothing today and to a kind afterwards, so its [G] findings may change (wider, not blinder) |
| `check-menu-actions.js` | C | comments; message "its mixin consumers" 337 | reword | RULE 1b stays sound (`receiversOf` covers subclasses) |
| `check-page-loaded-elements-selftest.js` | R | plant `BiteProofElementMixin`; expects `ELEMENT_FIELD_IN_MIXIN` | delete with the rule | rule and proof go together |
| `check-page-loaded-elements.js` | D+R | a near-copy of the back-buffer-memos shape; R: `ELEMENT_FIELD_IN_MIXIN` 166 | delete | no mixin defines the hooks or transients today |
| `check-part-edges-selftest.js` | D (inert) | fixture `mixins: []` | drop the field | none |
| `check-part-edges.js` | D | the `@augmentWith` arm of its `inherit` regex 352 | drop the arm; reword | none |
| `check-plane-discipline-selftest.js` | C (false hit) | "mixing" | nothing | none |
| `check-plane-discipline.js` | D | `mixinFile`, `augmentedBy`, `mixinOnAProvider` 237–241; OK-line text | delete the mixin units; trim the OK line | C1 for a mixin is "any consumer is a provider", for a class "it or an ancestor is": a handler in a base class whose provider is a SUBCLASS is not C1-checked. Moot today — the mixins' pointer handlers take no position |
| `check-raw-pointer-reads.js` | D (thin) | `mixinHashIndent` 99–103 | drop the threading | none |
| `check-relayout-bounds-first.js` | C | 67 | reword | none |
| `check-stinks.js` | D+R | R: sanctioned `{ file: 'mixins/BackBufferMixin.coffee', member: 'getPixelColor', count: 1 }` 155; D: `mixinMemberIndent` | re-point the entry; delete the indent branch | loud (`STALE_SANCTION`, and the moved hit counts against a zero baseline), when `BackBufferMixin` goes |
| `check-thin-wraps.js` | C | 47 | reword | none |
| `coffee-to-js-mirror.js` | C | 12 | reword | whether its `super` shim is still needed: not determined |
| `hypothetical-part.js` | D | `inherit` regex 80 | drop the arm | none |
| `lib/call-sites-selftest.js` | D+R | copies the real `Mixin.coffee` 25, 217; plants `BpMixin`, `BpMxMixin` | drop the copies, plants and assertions | ENOENT at deletion |
| `lib/call-sites.js` | D | `IS_MIXIN` 104, 326; `Mixin` 281; the tap 290–294, 376; mixin units; `mixinMember` | delete all | line 290 dereferences `Mixin` unconditionally. Ex-mixin members become class fragments, so coverage improves |
| `lib/coffee-method-header.js` | D | `MIXIN_METHOD_HEADER` 53; `MIXIN_CONTAINER` 118; `methodBoundary`'s mixin branch and second parameter; the span's `mixin` flag; `mixinMemberIndent` | delete; make `methodBoundary(raw)` take one argument | **the silent-blinding risk of §1** |
| `lib/meta-compiler-selftest.js` | D+R | loads `Mixin` 28; asserts the `_class_injected_in` rewrite | delete the case | fails at the loader change |
| `lib/meta-compiler.js` | D | 57–77 | see §4 answer 2 | — |
| `lib/method-references-selftest.js` | R | fixture chain with `SomeMixin` | rename the subject to a plain ancestor | none |
| `lib/method-references.js` | C | 14, 76 | reword | none |
| `lib/name-definitions.js` | C | 8 | reword | none |
| `lib/repaint-verbs.js` | D (thin) | `!s.mixin` 39 | drop | none; reads `Widget.coffee` only |
| `lib/settle-tiers.js` | D (thin) | `!s.mixin` 43 | drop | none; reads `Widget.coffee` only |
| `lib/settling-setters.js` | D (thin) | `!s.mixin` 70, 116 | drop; reword | line 116 widens: an ex-mixin member named like a derived setter becomes held. None has such a name today (checked by name) |
| `parts.json` | R (+C) | `"src/mixins"` in core's `dirs` 101; prose in several notes | remove the entry; reword | **silent if left** (§1) |
| `profiles/homepage.json` | C | 35 | reword | none |
| `profiles/lean.json` | C | 18 | reword | none |

### `../Fizzygum-tests/scripts/`

| File | Class | Identifiers (line hints) | Teardown | Risk |
|---|---|---|---|---|
| `audit-preludes/revisit-trace-prelude.js` | C | 92–93 | reword; keep the function-only guard | none |
| `build-tree-fingerprint.js` | C | 173, 259 | reword | none |
| `end-of-cycle-audit/layout-audit-prelude.js` | C | 131–132 | reword; keep the guard | none |
| `end-of-cycle-audit/run-capstone-gate.sh` | C | 125 names `BackBufferMixin` | reword when that mixin goes | none |
| `generate-pre-compiled-headless.js` | C | 10 | reword | none |
| `graph-liveness-headless.js` | R | `MIXIN_CHAIN_TERMINATES` 70; its section 235–252 | rename the rule and its labels | in lockstep with its self-test, which is outside the set |
| `inspector-churn-set.json` | R | two entries, the `macroMixin*` tests | remove them when the tests retire | its own text says a missing directory makes `fg recapture-inspector` refuse |
| `lib/gate-bite-proof.js` | C | 133 | pick another example hook | none |
| `lib/gate-tokens.js` | R (+C) | `MIXIN_MEMBER_UNRECORDED` 44–45, 78 | delete the token with its emitter in `Mixin.coffee` | the file says its self-test holds the list both ways |
| `lib/serialization-expectations.js` | R | 76–79 | delete four names | a name no backend reports is a MISMATCH |
| `parts-lazy-load-headless.js` | R | `LAZY_CONSUMER_TAKES_MIXIN_EDITS` 50; its function 187–219 and report 332–340 | delete the section | its premise fails when `KeepsRatioWhenInVerticalStackMixin` goes |
| `parts-lazy-load-selftest-headless.js` | R | plant 26–28; the second run 37–46 | delete the plants, the second run and their expectations | a leftover plant gives `PLANT_NOT_APPLIED` (loud) |
| `pin-sweep-headless.js` | C | 114 | reword | none |
| `serialization-roundtrip-headless.js` | D+R | D: `findMixinsInTheClass`, `new Mixin`, `Mixin.allMixines` ~3681–3693; R: the donor checks ~450–515, ~3528–3642, and the entries of §4 answer 4 | see §4 answer 4 | breaks when `ControllerMixin`, then `HighlightableMixin`, go |
| `smoke-boot-headless.js` | R (+C) | `inPageParsedMixins` 453–496; three verdicts 838–858 | delete the function, its call and the verdicts | fails when the last augmentation goes |
| `tier-naming-audit/tier-naming-prelude.js` | C | 87, 171–172 | reword; keep the guard | none |

Outside both roots, comments only: `Fizzygum-all/fg` and `Fizzygum/build_it_please.sh`.

## 4. Four questions

**1. One library, or each tool's own parsing?**

- *Method grouping:* `buildSystem/lib/coffee-method-header.js` — `methodBoundary(raw,
  mixinHashIndent)`, `methodSpans(lines)` (each span carries a `mixin` flag),
  `mixinMemberIndent(lines)`. Threading the state: `census-nosettle-naming`,
  `census-public-private-calls`, `check-dead-methods`, `check-layering`, `check-plane-discipline`,
  `check-raw-pointer-reads`. Reading the flag: `check-back-buffer-memos`,
  `check-page-loaded-elements`, `check-plane-discipline`, `lib/repaint-verbs`, `lib/settle-tiers`,
  `lib/settling-setters`. Using `mixinMemberIndent`: `check-stinks`, `check-hand-lists`.
- *Class model:* `runCensus()` in `census-public-private-calls.js` returns `classInfo` (with
  `mixins[]`), `chainOf` and `resolve`; its users are `census-hierarchy-duplication`,
  `census-property-placement`, `check-menu-actions`, `check-part-edges` and
  `check-call-separation.js`.
- *Meta-compiler:* `loadMetaCompiler` in `lib/meta-compiler.js`; its users are
  `check-coffee-syntax`, `lib/call-sites` (and through it `check-call-arguments` and
  `census-call-arity`), `lib/meta-compiler-selftest` and `compile-fragment.js`.
- *Own "is this a mixin file" detectors:* `IS_MIXIN` in `build.py`, `check-coffee-syntax.js` and
  `lib/call-sites.js`; a `…Mixin\s*=` regex of its own in `census-widget-conformance.js`,
  `check-plane-discipline.js`, `check-back-buffer-memos.js` and `check-page-loaded-elements.js`.
- *Own `@augmentWith` readers:* `census-public-private-calls`, `check-dead-methods` (with its own
  `chainOf`), `census-widget-conformance`, `check-back-buffer-memos`, `check-page-loaded-elements`,
  `check-plane-discipline`, and the `inherit` regex in `check-part-edges` and `hypothetical-part`.

**2. What breaks if `src/meta/Mixin.coffee` is deleted and the loaders are not touched?**

- `lib/meta-compiler.js` reads the file inside its `try`, so every `loadMetaCompiler` call throws
  `META_COMPILER_UNAVAILABLE`; `check-coffee-syntax.js` then exits 2 and the build aborts.
- `lib/call-sites.js` throws; `compile-fragment.js` and `lib/meta-compiler-selftest.js` crash.
- Three self-tests read the file directly and die with ENOENT: `check-call-arguments-selftest.js`
  and `lib/call-sites-selftest.js` (twice).

The minimal change, in ONE commit with the deletion:
- `lib/meta-compiler.js`: drop the read, return `{ Class }`, make its messages Class-only.
- `lib/call-sites.js`: remove `Mixin` and the tap — its line 290 dereferences `Mixin`
  unconditionally.
- `check-coffee-syntax.js`: remove `Mixin`, `IS_MIXIN`, the `new Mixin` branch and the mixin count,
  and update its self-test's `pass` regex.
- The three self-tests: drop `'Mixin.coffee'` from their copy lists.

This is possible because the path the tools drive (`new Class(src, true, false)`) never reaches
`Mixin`: `Class.coffee` names it only in `removeMember` and `_takeMixinMembersFromTheStores`, the
second behind `if createClass`.

**3. Baselines that name a mixin or a mixin member.** `inspector-churn-set.json` (the two tests);
`parts.json` (`"src/mixins"`, configuration rather than a ratchet); the inline sanctioned entry in
`check-stinks.js`. `check-doc-narration-baseline.json` and the tests repo's `revisit-baseline.json`
are both empty, and the three `.txt` allowlists (dead methods, public API, unresolved sends) hold
no mixin name and none of today's mixin member names.

**4. Mechanism-only checks, and general checks that use a mixin as their subject.**

Mechanism-only — delete:
- `MIXIN_MEMBER_UNRECORDED`; `LAZY_CONSUMER_TAKES_MIXIN_EDITS` with both self-test plants and its
  second run; the three smoke-boot verdicts (mixins parsed, a run-time consumer takes the edit, a
  donated member returns to its donor).
- `sourceEdits.removedOverrideRestoresDonor`, `sourceEdits.donatedRenameRoutesToDonor`,
  `sourceEdits.removedOverrideRestoresTheWinningDonor`, and `sourceEdits.removalIsAllOrNothing`
  (the only compile step in `Class.removeMember` is the donor's member, so the refusal it checks
  cannot occur afterwards), with their rig code.
- The `Mixin._rewriteSuperCalls` case in `lib/meta-compiler-selftest.js`.
- `BUILDER_IN_MIXIN`, `ELEMENT_FIELD_IN_MIXIN`, `SHADOWS-MIXIN`.

General — keep, with a new subject:
- `MIXIN_CHAIN_TERMINATES`: what it checks is that `graphEdgesOut` terminates and that an
  inherited flow edge is enumerated. Rename it.
- `world.inspector.classSubjectsSurviveSnapshot`: drop its donor-attribution fact; point its row
  and rename facts at a member `SliderWdgt` owns or inherits.
- `sourceEdits.loadOverPageEditsIsTheFilesWorld` and its two siblings: drop the donor edit and the
  mixin entry ("exactly these four" becomes three), and the mixin boot comparison.
- `boot.classNamedIsTheOneDefinition`: drop `'Mixin'` and `'HighlightableMixin'` from its
  non-classes.
- The class-edit checks (replay, rename, removal, add): keep, minus their mixin steps.
- `HELPER_VAR_NOT_STRIPPED` and `SOURCE_EVAL_FAILED`: keep; `Class.coffee` still emits both.

## 5. The SystemTests

39 test directories name a `*Mixin`; by mixin: `ControllerMixin` 30, `ClippingAtRectangularBoundsMixin`
12, `HighlightableMixin` 9, `BackBufferMixin` 5, `KeepsRatioWhenInVerticalStackMixin` 2, the other
three none. Most name it in descriptor metadata or comments. Four depend on one in their run, and
all four use `HighlightableMixin`:

- `SystemTest_macroMixinEditDonorAndOverride`, `SystemTest_macroMixinFieldEditDonorAndOverride` —
  they exist to test the mechanism.
- `SystemTest_macroClassInspectorSaveRefusesCodeThatDoesNotCompile`,
  `SystemTest_macroInspectorOffersOnlyWhatItsSubjectOwns` — general, asserting on a member that
  mixin gives `ButtonWdgt`.
