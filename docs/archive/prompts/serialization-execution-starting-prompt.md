# Starting prompt — RESUME the serialization/deserialization arc at Phase 5

Copy-paste everything below the line into a fresh Claude Code session opened at the
`Fizzygum-all` umbrella workspace. The session needs no other context.

---

Resume the Fizzygum serialization/deserialization arc. **Phases 0–4 are DONE, committed, and
pushed to `master` in both repos. Your job is Phase 5 (whole-world snapshot), then Phase 6
(source-edit capture) — the last two phases.**

## Read first, in this order (before touching anything)

1. `Fizzygum/docs/archive/serialization-deserialization-plan.md` — THE plan, fully self-contained. Read
   **§9 (LANDED-STATUS) first** — it records exactly what Phases 0–4 landed, the lessons, and the
   deferred items. Then §4.9 (whole-world snapshot design), §4.10 (source-edit capture), §5
   Phases 5–6 (touch-lists + exit gates), §2.6 (world state inventory), §6 (risks), §8 (owner
   decisions — do NOT re-open). It was verified against build `040330e6`; re-verify any file:line
   before editing.
2. `Fizzygum/docs/architecture/serialization-duplication-reference.md` — the ONE reference doc for the whole
   ser/deser/dup machinery (format §3, references §4, transients §5, handlers §6, the LIVE
   Serializer/Deserializer/file-I/O, and §11/§12 for the world-snapshot + source-edit designs).
   **Keep it current as you land Phase 5/6** (flip its [Ph 5]/[Ph 6] markers to [LIVE]).
3. `CLAUDE.md` (umbrella root), `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md` — repo layout,
   build/test workflow, conventions.
4. `Fizzygum-tests/DETERMINISM.md` — **REQUIRED before Phase 5.** The world snapshot restore runs
   through the world-reset + settle/layout machinery, which is the suite's historical
   nondeterminism minefield. Also skim the memory notes `settle-tier-teardown-flip` and
   `macro-test-relocation-gotchas`.

## What already exists (the ground you build on — all LIVE on `master`)

- **The engine** is in `Fizzygum/src/serialization/`: `Serializer` (`serializeWidget` /
  `buildEnvelope`), `Deserializer` (`deserialize`, 5 passes, `whenReady`), `WellKnownObjects`
  (lazy `keyFor`/`resolve`; `resolveApp` is a **stub** you finish in Phase 5), `SerializationError`,
  `FileSaving`, `FileLoading`. `Widget.serialize`/`deserialize`/`saveToFile` and the drop handler
  are wired. `build.py` already globs `src/serialization/` (it uses an EXPLICIT directory
  allowlist — any NEW `src/` subdir must be added there or it never builds).
- **The Phase-5 seams are already stubbed:** `Serializer.buildEnvelope` takes `opts.kind` and
  `opts.onExternalPointer: "throw"|"nullify"|"record"` (record emits `{"$ext": uniqueID}`);
  `Deserializer` already restores `iid` when `kind==="world"` and resolves `{"$ext"}` against the
  live world; `FileLoading.loadEnvelopeString`'s `kind:"world"` branch already calls
  `world.loadWorldSnapshot?` (currently informs "cannot load yet"). So Phase 5 is mostly:
  `WorldWdgt.serializeWorldSnapshot` / `loadWorldSnapshot`, the `world` envelope section (§4.9),
  completing the `WorldWdgt` transient seed (§4.3), finishing `resolveApp`, and the guided error
  on `world.serialize()`.
- **The gates** (keep them green): in-memory rig `cd Fizzygum-tests && npm run test:serialization`
  (native+SWCanvas, cross-session pixel parity — the serialization gate, driven by an
  EXPECTATIONS table you extend), file rig `npm run test:serialization:file` (byte-exact save +
  drop-restore over `file://`). Add a **world leg** to the round-trip rig for Phase 5 (default
  desktop + populated-world snapshot → fresh-page restore → pixel compare, per §5 Phase 5).

## Ground rules (non-negotiable)

- Edit ONLY `Fizzygum/src/**` and `Fizzygum-tests/**`. NEVER edit `Fizzygum-builds/**` (regenerated
  every build).
- Build/test through the `fg` wrapper at the umbrella root (path-correct from any cwd):
  `fg build` · `fg suite` (headless parallel suite, dpr 1, ~1 min) · `fg gauntlet`
  (build + dpr1 + dpr2 + webkit + apps, ~6–8 min) · `fg test <name>` · `fg recapture <name>` ·
  `fg homepage` (--homepage build + boot-smoke + restore). One-time setup if missing:
  `cd Fizzygum-tests && npm i`.
- Execute Phase 5 then Phase 6; a phase's exit gate (plan §5) must be green before the next.
  `fg gauntlet` green before declaring a phase done. Because serialization now ships in
  `--homepage`, run `fg homepage` when you touch product code.
- Run straight through, verifying as you go; ONE review at the end. **NEVER commit or push
  autonomously** — at the arc end (or a stopping point) present a summary + proposed commit
  messages for BOTH repos and wait for explicit approval. Work lands on branch `serialization-arc`
  (already merged to `master` for 0–4); create/continue a branch, don't commit to `master`
  directly without the owner's OK.
- For any op over a few minutes, state an upfront ETA and post status every ~5 min.
- After each phase lands, update the plan's §9 LANDED-STATUS box AND the reference doc — docs are
  a required deliverable.
- Conventions: `nil` (never null/undefined); one class per file, filename = class name; reference
  classes with literal `new X`/`extends X`/`@augmentWith X` so the boot dependency scanner sees
  the edge; match surrounding comment density/idiom; reuse over duplication.
- New serialization product code carries NO homepage-strip markers (ships in production, §8.1).
  Keep any new menu items in the PRODUCT (`isIndexPage`) menu branch only if you want zero
  SystemTest menu-screenshot churn (the widget/world file menus already do this).
- Macro SystemTests are authored via the `/author-macro-test` skill — capture SWCanvas refs at
  dpr 1+2, verify per its full flow. LESSON from Phase 3/4: an **eval-driven** round-trip
  (`world.evaluateString` for build/serialise/restore) + `assertScreenshotsIdentical` is the
  robust macro idiom; the `world.inform` dialog is load-flaky (don't screenshot it in the suite);
  a macro that passes alone but fails under parallel `fg gauntlet` load is a real determinism bug
  (DETERMINISM.md), not a flake.

## Owner decisions (plan §8 — do NOT re-open)

1. Serialization ships in `--homepage`. 2. Old prototype format deleted, no back-compat. 3. Single
extension `*.fzw.json` for widgets AND worlds; route on the envelope `kind`, never the filename.
4. File I/O (Phase 4) before world snapshot (Phase 5) — already satisfied. 5. `kind:"widget"`
restores get fresh instanceNumericIDs; `kind:"world"` RESTORES `iid` + the per-class counters into
a zeroed ID space. 6. ALL ser/deser/dup docs live in ONE
`Fizzygum/docs/architecture/serialization-duplication-reference.md`; CLAUDE.md files LINK only, never carry the
content.

## Phase 5 shape (see plan §4.9 / §5 Phase 5 for the full touch-list)

`WorldWdgt.serializeWorldSnapshot()` — snapshot roots = world subtree + off-tree
`world.basementWdgt` subtree + each non-nil app-slot window (orphans included; the held-by-hand
transient is dropped — a snapshot restores a SETTLED world); cross-root pointers via `$r`,
stragglers via `onExternalPointer:"record"` + a resolution pass. A `world` envelope section
(outside the object table, greppable): `preferences`, `wallpaperPatternName`,
`desktopColor`/`alpha`, `isDevMode`, `infoDocFlags`, `untitledNamingCounters`,
`simpleEditorTemplates`, `appSlots`, `basement` ref, `idCounters`, `sourceEdits` (Phase 6).
`loadWorldSnapshot(envelopeString)` — confirm dialog (destructive + code-exec warning) → tear down
via the existing reset machinery (`fullDestroyChildren` / `_resetWorldNoSettle` zero the ID
counters) + empty basement + nil app slots → restore `idCounters` → deserialize with preserved
`iid` → re-link world sections + memberships + `whenReady` → settle (`_settleLayoutsAfter` batch) +
full repaint. `world.serialize()` becomes a guided error pointing at `serializeWorldSnapshot`.
Complete the `WorldWdgt` transient seed (§4.3 / §2.6a: the ~25 transient Sets/queues/caches/listener
fields, `DesktopAppearance.pattern` already declared). Finish `WellKnownObjects.resolveApp` (launch
the app singleton if absent, the `createOpener`/`launch` way). **Restore must attach through the
same public paths as duplication (world.add + settle batch) — never call layout cores directly**
(plan §6 risk 4).

## Phase 6 shape (see plan §4.10 / §5 Phase 6)

`src/serialization/SourceEditsRegistry.coffee` at `world.sourceEditsRegistry`
(`{scope,className,uniqueID?,propertyName,source,when}`), hooked at `Widget.injectProperty` and
`ClassInspectorWdgt.applyPropertyEdit`. The snapshot embeds it; restore replays CLASS-scope edits
BEFORE pass 1 (prototypes correct when shells are made), instance edits ride the normal `$src`
mechanism. Load confirms + warns about code execution (§4.12).

## If reality contradicts the plan

The plan is evidence-based but ~470 classes have a long tail. If an assumption is falsified, record
it (dated note in the affected plan section + §9), choose the smallest redesign consistent with §4,
and continue. Ask the owner only for genuine scope decisions — not for anything §8 settles. Loud,
path-carrying `SerializationError`s on unforeseen fields are the DESIGNED behaviour: fix each by
declaring a transient, registering a well-known, or adding a typed handler, and add the case to the
rig.
