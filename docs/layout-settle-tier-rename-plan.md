# Plan — rename the layout-settle tier to private, layout-explicit names (and `Core` → `NoLayouting`)

**Status: PLAN ONLY. Written to be executed COLD by an LLM/engineer with zero prior context.** This is a **pure
rename** (no behaviour change, byte-identical render). **PREREQUISITE: do `private-noLayouting-core-callpaths-plan.md`
(Plan 1) FIRST** — it adds several `_xxxCore` methods and reroutes private chains; renaming before that would force
re-grepping a moving target. Read §0 → §2 before touching code.

---

## 0. Cold-start orientation

See `private-noLayouting-core-callpaths-plan.md` §0 for the full workspace/build/test orientation (umbrella with 3
sibling git repos, `fg build` / `fg suite` / `fg gauntlet` / `fg recapture`, one-class-per-file, `nil`==`undefined`,
no imports, ask-before-commit). The essentials: edit `Fizzygum/src/**/*.coffee`; `fg build` runs a CoffeeScript
syntax gate + the layering lint `buildSystem/check-layering.js`; `fg suite` is dpr1 165/165.

---

## 1. What is being renamed and why

There are three layout-engine methods on `Widget` (`src/basic-widgets/Widget.coffee`) plus a private-core naming
convention:

- **`mutateGeometryThenSettle(coreThunk)`** (~:780) — the **SINGLE-mutation** public self-settling tier: run the
  thunk, then `recalculateLayouts()` once. THROWS if reached mid-flush.
- **`settleLayoutsOnceAfter(thunk)`** (~:827) — the **BATCHED** version of the same idea: set
  `world._batchingLayoutSettling` so N nested mutations DEFER, then settle ONCE at the end. Does not throw.
- **`invalidateLayout(triggeringChild = nil)`** (~:3789) — the low-level "mark dirty + climb to parent" schedule
  primitive.
- **`_xxxCore`** — the private "do the work without settling" body that each public settling method delegates to
  (e.g. `_addCore`, `_destroyCore`, `_closeCore`, `_fullDestroyCore`, `_buildAndConnectChildrenCore`,
  `_recalculateLayoutsCore`, plus the ones Plan 1 adds).

**The owner's complaints (the rename goals):**
1. The naming does not reveal that **`settleLayoutsOnceAfter` is the BATCHED version of `mutateGeometryThenSettle`** —
   they read as unrelated. The new names must make the single↔batch relationship obvious (a shared stem + a `Batch`
   marker).
2. Neither name makes clear this is about **layouting** — both should contain **`SettleLayout`**.
3. These are **internal** mechanisms — they (and `invalidateLayout`) should be **private** (leading underscore). They
   are not meant to be called by feature code directly; the public API is the geometry setters (`add`, `setExtent`,
   `close`, `destroy`, …) that wrap them.
4. **`Core` really means "NoLayouting"** (the core does the work WITHOUT triggering layout). Rename the
   `_xxxCore` family to `_xxxNoLayouting` so the intent is explicit.

---

## 2. The rename scheme (recommended; the exact spelling is the owner's call)

| current | → new | rationale |
|---|---|---|
| `mutateGeometryThenSettle` | **`_settleLayoutAfter`** | private; "settle layout after [this one mutation]"; SINGLE variant = the bare stem |
| `settleLayoutsOnceAfter` | **`_settleLayoutAfterBatch`** | private; same stem + **`Batch`** = "…after [a batch of] mutations" → the relationship is now obvious |
| `invalidateLayout` | **`_invalidateLayout`** | private; already layout-explicit, just needs the underscore |
| `_xxxCore` (all) | **`_xxxNoLayouting`** | "Core" → the literal intent "does the work with NO layouting" |

So: `_addCore`→`_addNoLayouting`, `_destroyCore`→`_destroyNoLayouting`, `_closeCore`→`_closeNoLayouting`,
`_fullDestroyCore`→`_fullDestroyNoLayouting`, `_buildAndConnectChildrenCore`→`_buildAndConnectChildrenNoLayouting`,
`_recalculateLayoutsCore`→`_recalculateLayoutsNoLayouting` (+ every `_Core` Plan 1 added:
`_addInPseudoRandomPositionCore`, `_addLostWidgetCore` if created, etc.).

**Alternative spellings (if the owner prefers):** single/batch as `_settleLayoutAfterMutation` /
`_settleLayoutAfterMutationBatch` (more explicit, longer); or `_mutateThenSettleLayout` /
`_batchThenSettleLayout`. Pick ONE scheme and apply it uniformly. The two hard requirements (owner): both settle-tier
names contain **`SettleLayout`** and the batched one is visibly the batch of the single one.

---

## 3. Scope — exact call-site counts (so you know the blast radius)

Across `src/**/*.coffee` (definition lines excluded), as of the post-teardown-self-settle build:
- **`mutateGeometryThenSettle`** — **9 call sites** + 1 definition + ~5 comment mentions. Call sites (enclosing
  method): `destroy` (Widget.coffee:516), `setBounds` (:846), `fullMoveTo` (:1357), `setExtent` (:1576), `setWidth`
  (:1700), `setHeight` (:1736), `add` (:2400), `addRaw` (:2424), `setLabel` (LabelButtonWdgt.coffee:111). *(Plan 1
  may add a few more — re-grep.)*
- **`settleLayoutsOnceAfter`** — **5 call sites** + def + comments: `close` (Widget.coffee:480), `fullDestroy`
  (:588), `buildAndConnectChildren` (WindowWdgt.coffee:361), the two text-hug setters (TextWdgt.coffee:377,
  StringWdgt.coffee:1181).
- **`invalidateLayout`** — **HIGH fan-out: ~42 files**, ~120 lines incl. the def + heavy intra-Widget use
  (Widget.coffee alone ~33 call/usage lines). This is the climb/dirty-mark primitive — the underscore rename touches
  the most files by far. A global, mechanical search-and-replace (word-boundary) is the only sane approach.
- **`_xxxCore`** — 6 existing defs (WindowWdgt.coffee:363, WorldWdgt.coffee:866, Widget.coffee:482/518/590/2437) +
  their call sites, + whatever Plan 1 added. `grep -rn '_[A-Za-z]*Core\b' src --include='*.coffee'`.

**⚠ The build lint `buildSystem/check-layering.js` hard-codes two of these names by string** and MUST be updated in
the same commit, or the build breaks:
- **`RECALC_WHITELIST = new Set(['doOneCycle', 'mutateGeometryThenSettle', 'settleLayoutsOnceAfter'])`** (~line 52) —
  **functional** (rule [B] reads it: "only these may call `recalculateLayouts`"). Update the two strings.
- Comments/messages that name the methods: the doc header (~lines 9-16), the `SANCTION_MARKER` area (~50-52), rule
  [B] text (~178), the failure-message footer (~255-256). Update all.
- If Plan 1 added a new lint rule keyed on `mutateGeometryThenSettle`/`settleLayoutsOnceAfter` regexes, update those
  regexes too.

---

## 4. Procedure (one symbol at a time, verify between)

Do them in this order (least → most fan-out), each as its own commit, `fg build` + `fg suite` after each:
1. **`_xxxCore` → `_xxxNoLayouting`** — per-symbol word-boundary replace (def + all calls). Start here: it's the
   `Core` family, self-contained, and Plan 1 just touched it so it's fresh.
2. **`mutateGeometryThenSettle` → `_settleLayoutAfter`** — 9 sites + def + comments. Update `check-layering.js`
   `RECALC_WHITELIST` string + comments in the SAME commit.
3. **`settleLayoutsOnceAfter` → `_settleLayoutAfterBatch`** — 5 sites + def + comments + the lint string.
4. **`invalidateLayout` → `_invalidateLayout`** — the big one (~42 files). Global word-boundary replace; then
   `grep -rn '\binvalidateLayout\b' src` must return ONLY the new name (zero stragglers). Watch for: the lint's
   `INVALIDATE_CALL` regex (`/[@.]\s*invalidateLayout\b/`, ~line 45) — update it to `_invalidateLayout`; the
   freefloating-skip param `triggeringChild?.isFreeFloating()` is unaffected (it's a different symbol).

Use a precise word-boundary match (`\binvalidateLayout\b`, not a bare substring) so you don't corrupt
`reLayoutAndRefreshContainerIfContainedText`, `_recalculateLayouts`, etc. CoffeeScript has no `import`s, so a symbol
is the same global everywhere — a uniform rename is safe, but VERIFY with a final `grep` that the OLD name is gone
from `src` entirely (except prose in `docs/`).

---

## 5. Verification (pure rename — must be byte-identical)

After each symbol:
1. `fg build` — the syntax gate + the layering lint (rule [B] reads `RECALC_WHITELIST`; if you forgot to update the
   string, [B] fails loudly here — that's the safety net).
2. `fg suite` (dpr1) — must stay **165/165**, pixels **byte-identical** (a rename cannot change render).
After all four symbols:
3. `fg gauntlet` (dpr1/dpr2/WebKit/apps) — confirm byte-identical across engines.
4. **No torture / no audit needed** — a pure rename changes neither settle timing nor the flush inventory. (Run them
   only if you are paranoid; they should be unchanged.)

**The ONE expected test change:** `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly`. The live
`InspectorWdgt` lists a widget's members alphabetically; renaming `invalidateLayout`→`_invalidateLayout` (underscore
sorts BEFORE letters) and `_xxxCore`→`_xxxNoLayouting` shifts the list, so this test's screenshots shift. This is a
**benign inspector recapture** (the owner does not care): `fg recapture macroDuplicatedInspectorDrivesCopiedTargetOnly`
(dpr1+dpr2). Its macro was hardened this session to centre `alpha` in the list pane (robust to member-list growth),
so the recapture should be clean. Do NOT contort the rename to keep the inspector byte-identical.

---

## 6. Risks & rollback

- **Lint string drift** (the #1 footgun): forgetting `RECALC_WHITELIST` breaks the build immediately — easy to catch
  and fix. Forgetting a comment mention is cosmetic.
- **Partial rename** (a straggler old-name call): the build's syntax gate won't catch a call to a now-nonexistent
  method until runtime, but the **boot-smoke** (`fg gauntlet` app-smoke) and the suite will. Always finish with the
  `grep` sweep proving the old name is gone from `src`.
- **`invalidateLayout`'s fan-out** is the only real labour; it's mechanical. Do it as one atomic global replace +
  one grep verification, not file-by-file (so you don't ship a half-renamed tree).
- **Rollback:** pure renames revert cleanly with `git checkout -- <files>`; each symbol is its own commit.

## 7. File:line map (lines drift — grep the name)
`src/basic-widgets/Widget.coffee`: `mutateGeometryThenSettle` ~:780 · `settleLayoutsOnceAfter` ~:827 ·
`invalidateLayout` ~:3789 · cores `_addCore` ~:2437, `_destroyCore` ~:518, `_closeCore` ~:482, `_fullDestroyCore`
~:590. `src/WindowWdgt.coffee`: `_buildAndConnectChildrenCore` ~:363. `src/WorldWdgt.coffee`:
`_recalculateLayoutsCore` ~:866 · `recalculateLayouts` ~:853. `buildSystem/check-layering.js`: `RECALC_WHITELIST`
~:52 · `INVALIDATE_CALL` ~:45 · failure footer ~:255.
