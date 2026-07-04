# Coalesced-nomenclature rename plan — self-contained, cold-executable

**Purpose:** free the word **"coalesced"** (and pin related contested vocabulary) before the
dataflow/calculation engine work begins, so the two adjacent per-cycle drains
(`recalculateLayouts`, upcoming `recalculateDataflow` — see
`docs/specs/dataflow-engine-spec.md`) never share ambiguous words. The vocabulary registry
that this plan enforces is `NOMENCLATURE.md` (repo root) — read it first; it is normative.

**This document assumes NO other context.** Everything needed to execute is in here plus the
two files named above. Numbers marked *(verified 2026-07-04)* are snapshot counts — always
re-derive them with the given grep commands before editing; the tree may have moved.

**Hard constraint: zero behavior change.** This is a rename of identifiers, comments and
living docs only. Fizzygum ships its ~470 `src/**/*.coffee` class sources **as text**
(compiled in the browser at boot), so renames are plain textual sweeps; comments compile
away and cannot affect pixels. Nothing in this plan touches serialized-document formats
(none of the renamed names appear in saved files).

---

## 0. Environment & baseline

Prerequisites (global, not npm-local): `coffee` (`npm i -g coffeescript`), `terser`
(`npm i -g terser`), `node`, `python3`.

Two environment tiers — determine which you're in with `ls ..`:

- **Full** (siblings `../Fizzygum-tests` and `../Fizzygum-builds` exist): verification is
  `./build_and_test.sh` (build + whole SystemTest suite headless, ~1 min on a many-core
  box; one-time `cd ../Fizzygum-tests && npm i`). Expect **zero pixel diffs**.
- **Repo-only** (no `../Fizzygum-tests`): verification is `./build_it_please.sh --notests`
  — it auto-creates `../Fizzygum-builds` (warning is fine) and still runs the three gates
  that matter here: the CoffeeScript **syntax gate**, the **layering gate**
  (`buildSystem/check-layering.js`) and the **dead-method gate**
  (`buildSystem/check-dead-methods.js`). Record in the commit message that the pixel suite
  was not run and must pass on the next full-environment run.

**Baseline first:** run the verification for your tier BEFORE any edit, to prove the tree
was green when you started. (Ignore the harmless `.gitattributes` warning git prints.)

## 1. Background: the three meanings of "coalesced"

*(verified 2026-07-04: 371 occurrences of `coalesc` across `src`, `buildSystem`, `docs`;
re-checked same day after the hover-resync and disable-editing-family merges — all growth
was in new `docs/*.md` plan records, which §4 excludes; every identifier count in §2a/§2b
was unchanged)*

1. **Layout deferred-settle tier** (the real rename target): five `_`-private geometry
   entrypoints that, instead of settling layouts themselves, *defer their settle to the ONE
   end-of-cycle flush* (`recalculateLayouts` in `WorldWdgt.doOneCycle`). Used by
   stream handlers (drag/resize/scroll). Guarded by `buildSystem/check-layering.js`
   **rule [O]** (a caller allowlist) and treated as auto-declared by the
   declaration-audit machinery.
2. **Menu takeover** (unrelated homonym): `takesOverAndCoalescesChildrensMenus` — a scroll
   panel presents its child's menu entries as its own. Semantically "merges".
3. **Prose**: comments and docs describing meaning 1 ("the coalesced flush", "coalesced
   stream").

## 2. Authoritative rename tables

### 2a. Identifiers — layout family → `DeferredSettle`

Re-derive current sites with:
`for id in _moveToCoalesced _setExtentCoalesced _setWidthCoalesced _setHeightCoalesced _setMaxDimCoalesced _coalescedDeclare _coalescedDeclarationDepth coalescingEnabled; do echo "-- $id"; grep -rn "$id" src buildSystem; done`

| Old | New | Sites *(verified 2026-07-04)* |
|---|---|---|
| `_moveToCoalesced` | `_moveToDeferredSettle` | Widget.coffee ×3, HandleWdgt ×1, check-layering.js ×1 |
| `_setExtentCoalesced` | `_setExtentDeferredSettle` | Widget ×3, HandleWdgt ×1, check-layering.js ×1 |
| `_setWidthCoalesced` | `_setWidthDeferredSettle` | Widget ×3, HandleWdgt ×1, check-layering.js ×1 |
| `_setHeightCoalesced` | `_setHeightDeferredSettle` | Widget ×3, HandleWdgt ×1, check-layering.js ×1 |
| `_setMaxDimCoalesced` | `_setMaxDimDeferredSettle` | Widget ×5, WorldWdgt ×3, StackElementsSizeAdjustingWdgt ×2, CaretWdgt ×1, check-layering.js ×1 |
| `_coalescedDeclare` | `_deferredSettleDeclare` | Widget ×6, WorldWdgt ×1 |
| `_coalescedDeclarationDepth` | `_deferredSettleDeclarationDepth` | Widget ×5, WorldWdgt ×2, check-layering.js ×1 |
| `world.coalescingEnabled` → | `world.deferredSettlingEnabled` | Widget ×10, WorldWdgt ×2, StackElementsSizeAdjustingWdgt ×1 |

Naming rationale (recorded in `NOMENCLATURE.md`): aligns with the established
"deferred layout" vocabulary; the drain itself keeps its long-standing name
"the end-of-cycle flush". (`*EndOfCycle` suffix rejected — describes *when* not *what*;
`*Streamed` rejected — conflates caller nature with mechanism.)

### 2b. Identifier — menu homonym → `Merges` (cross-repo caveat!)

| Old | New | Sites *(verified 2026-07-04)* |
|---|---|---|
| `takesOverAndCoalescesChildrensMenus` | `takesOverAndMergesChildrensMenus` | Widget ×2 (definition), ScrollPanelWdgt ×1, SimplePlainTextPanelWdgt ×1, SimplePlainTextScrollPanelWdgt ×1, MACRO-PATTERNS.md ×2 (prose) |

**CAVEAT:** the sibling repo `Fizzygum-tests` hosts the Automator/SystemTest machinery, and
`src/macros/MACRO-PATTERNS.md` documents a macro verb `macroScrollPanelCoalescesChildMenu`
whose behavior is tied to this property. That verb is *defined in Fizzygum-tests, not here*.
Before renaming this property:
- **Full environment:** `grep -rn "takesOverAndCoalescesChildrensMenus" ../Fizzygum-tests`.
  If it appears there, either rename in lockstep (separate commit in that repo, landed
  together) or add a temporary alias in `Widget.coffee`
  (`takesOverAndCoalescesChildrensMenus: -> @takesOverAndMergesChildrensMenus` — check the
  property's shape first: if it is a boolean *field*, an alias getter won't work; in that
  case do the lockstep rename or defer 2b entirely to the cross-repo step §5).
- **Repo-only environment:** DEFER rename 2b to the cross-repo step §5 (do commits 1 and 3
  only, and note the deferral in the commit message). Renaming it blind risks silently
  breaking a SystemTest helper.

### 2c. Prose (comments in code + living docs)

After the identifier sweeps, rewrite remaining prose in `src/**` and `buildSystem/**`
(NOT `docs/` — see §4):

| Old phrase | New phrase |
|---|---|
| "coalesced flush", "coalesced end-of-cycle flush" | "the end-of-cycle flush" |
| "coalesced stream" / "coalesced input" | "deferred-settle stream(ed input)" |
| "coalescing" (the mechanism) | "deferred settling" |
| "coalesced" (adjective for the setters/tier) | "deferred-settle" |
| menu-sense "coalesces" (MACRO-PATTERNS.md §scroll-panel) | "merges" (note the *macro verb name* `macroScrollPanelCoalescesChildMenu` stays until §5 — do not edit the verb name inside macro examples, only surrounding prose) |

Enumerate leftovers with: `grep -rin "coalesc" src buildSystem`

## 3. Execution — three commits

**Commit 1 — layout identifier family + lint, atomic.**
Apply every rename in table 2a across `src/` and `buildSystem/check-layering.js` in ONE
commit — rule [O]'s allowlist patterns and rule text name these identifiers, so renaming
code and lint separately makes the build gate fail (that is the gate working as intended).
Mechanical global search-replace is safe: the names are unique strings, `_`-private, and
appear nowhere in serialized formats. Then run tier verification (§0). Also update rule [O]'s
prose in check-layering.js per table 2c while touching it.

**Commit 2 — menu homonym (2b), only if the caveat check passed.**
Rename + tier verification. In the full environment, additionally run the whole suite
(a SystemTest exercises the scroll-panel menu takeover via the macro verb).

**Commit 3 — prose sweep (2c).**
Comments in `src/**`, `buildSystem/**`, and `src/macros/MACRO-PATTERNS.md`. Tier
verification again (comments ship inside the source-text batches; the syntax gate will
catch a mangled comment that breaks a source string).

Use clear conventional commit messages (`refactor(layout): rename *Coalesced tier to
*DeferredSettle`, etc.), each stating the verification tier that was run.

## 4. What NOT to touch

- **Historical docs are records:** `docs/coalescing-measurement.md`, the
  `docs/end-of-cycle-*` and `docs/deferred-layout-*` families, and any other `docs/*.md`
  using old vocabulary stay byte-identical. `NOMENCLATURE.md` already notes that pre-rename
  docs use old vocabulary.
- **`docs/specs/dataflow-engine-spec.md` and `NOMENCLATURE.md`** already use the new
  vocabulary; no edits needed (sanity-check with `grep -in coalesc NOMENCLATURE.md docs/specs/dataflow-engine-spec.md` — hits there only *describe* the rename).
- **`../Fizzygum-builds/`** is generated output — never edit.
- The macro verb name `macroScrollPanelCoalescesChildMenu` (lives in Fizzygum-tests) — §5.

## 5. Cross-repo follow-up (separate session/PR in `Fizzygum-tests` — note only)

Not part of this repo's commits. When executing over there: grep for
`coalesc` — expected touchpoints: `DETERMINISM.md` (end-of-cycle-flush vocabulary),
that repo's `CLAUDE.md`, the Automator macro verb `macroScrollPanelCoalescesChildMenu`
(→ `macroScrollPanelMergesChildMenu`) and any macro scripts using it, plus any reference to
`takesOverAndCoalescesChildrensMenus` (must land in lockstep with commit 2 here, or after
it if an alias was used — then remove the alias). Update
`src/macros/MACRO-PATTERNS.md` here to the new verb name in the same change.

## 6. Definition of done

- [ ] Baseline verification ran green before edits.
- [ ] Commits 1–3 landed (2 possibly deferred per §2b caveat), each verified per tier.
- [ ] `grep -ri coalesc src buildSystem` returns nothing — or only the §2b property if its
      rename was deferred, and only `macroScrollPanelCoalescesChildMenu` in
      MACRO-PATTERNS.md if §5 hasn't run.
- [ ] Full-environment run: `./build_and_test.sh` all-green, zero screenshot recaptures.
- [ ] `NOMENCLATURE.md` needs no edits (it already records the target state); if any naming
      decision had to deviate during execution, update it in the same commit as the
      deviation.
- [ ] Cross-repo step §5 filed/queued for `Fizzygum-tests`.

## 7. Known gotchas

- The five deferred-settle entrypoints are `_`-private with a lint-enforced caller
  allowlist — atomicity of commit 1 is non-negotiable.
- `world.coalescingEnabled` is an A/B switch (both branches reach the same NoSettle core);
  no string references to it exist in `src` *(verified)*, but re-grep including quotes:
  `grep -rn "coalescingEnabled" src buildSystem --include=* | grep -v "\.coffee:"`.
- The dead-method gate (`check-dead-methods.js`) runs on every build: a half-applied rename
  (definition renamed, a caller missed) fails there or at the layering gate — trust the
  gates, don't `--noSyntaxCheck` around them.
- Comment edits are NOT pixel-safe *in principle* only for one reason: sources ship as
  text, so a comment edit that breaks CoffeeScript string escaping breaks boot. The syntax
  gate catches exactly this; never skip it.
