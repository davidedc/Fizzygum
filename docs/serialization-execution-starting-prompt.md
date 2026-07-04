# Starting prompt — execute the serialization/deserialization plan

Copy-paste everything below the line into a fresh Claude Code session opened at the
`Fizzygum-all` umbrella workspace. The session needs no other context.

---

Execute the approved serialization/deserialization plan for Fizzygum.

## Read first, in this order (before touching anything)

1. `Fizzygum/docs/serialization-deserialization-plan.md` — THE plan, fully self-contained:
   current-state survey with file:line refs (§2), spike-verified defect catalog (§3), design
   (§4), phased execution with touch-lists and exit gates (§5), risks (§6), owner-resolved
   decisions (§8), landed-status box (§9). It was verified against build `040330e6`
   (2026-07-03); re-verify any file:line that looks stale before editing.
2. `CLAUDE.md` (umbrella root), `Fizzygum/CLAUDE.md`, `Fizzygum-tests/CLAUDE.md` — repo layout,
   build/test workflow, conventions.
3. `Fizzygum-tests/DETERMINISM.md` — before writing anything that runs during render/layout/input.

## What you are building (one paragraph)

Fizzygum's duplication feature (`fullCopy` → `DeepCopierMixin.deepCopy(false,…)`) and a broken
dev-only prototype serializer (`deepCopy(true,…)` → `Widget.serialize`/`deserialize`) share one
engine. You will: leave duplication pixel-identical; replace the serialize mode with a proper
`Serializer`/`Deserializer` pair in a new `src/serialization/` family (versioned single-JSON
envelope, structured `{"$r"}/{"$wk"}/{"$src"}` reference tokens, per-class
`@serializationTransients`, well-known-object registry, rich path-carrying
`SerializationError` for any other external pointer, `whenReady` promise for async decode);
then file save/load over `file://` (Blob download + file-input/drag-drop FileReader — both
already spike-proven); then the whole-world snapshot (tree + off-tree basement + app slots +
preferences/wallpaper/ID counters, restored through the existing world-reset machinery); then a
source-edits registry so in-world code edits survive snapshots.

## Ground rules (non-negotiable)

- Edit ONLY `Fizzygum/src/**` and `Fizzygum-tests/**`. NEVER edit `Fizzygum-builds/**` — it is
  regenerated wholesale by every build.
- Build/test through the `fg` wrapper at the umbrella root (path-correct from any cwd):
  `fg build` · `fg suite` (headless parallel suite, dpr 1, ~1 min) · `fg gauntlet`
  (build + dpr1 + dpr2 + webkit + apps) · `fg test <name>` · `fg recapture <name>`.
  One-time setup if missing: `cd Fizzygum-tests && npm i` (Puppeteer).
- Execute phases STRICTLY in order 0 → 6; a phase's exit gate (defined per phase in plan §5)
  must be green before starting the next. `fg gauntlet` green before declaring any phase done.
- Run the whole arc straight through, verifying as you go; ONE review at the end of the arc.
  **NEVER commit or push.** When the arc (or a stopping point) is reached, present a summary +
  proposed commit messages for BOTH repos and wait for explicit approval.
- For any operation expected to take more than a few minutes of wall-clock, state an upfront ETA
  and post a status update roughly every 5 minutes.
- After each phase lands, update the plan's §9 LANDED-STATUS box (what landed, gate results,
  dated) and keep the new reference doc (below) current — docs are a required deliverable.
- Code conventions: `nil` (never null/undefined); one class per file, filename = class name;
  reference other classes with literal `new X` / `extends X` / `@augmentWith X` so the boot-time
  dependency scanner sees the edge; match surrounding comment density and idiom; prefer reusing
  existing mechanisms over duplicating them.
- New serialization product code carries NO homepage-strip markers (it ships in production —
  decision §8.1). The existing test-menu items keep theirs.
- Macro SystemTests are authored via the `/author-macro-test` skill (Fizzygum-tests repo) —
  capture SWCanvas references at dpr 1+2 and verify per that skill's full flow.

## Decisions already made by the owner (plan §8 — do NOT re-open)

1. Serialization ships in `--homepage` production builds.
2. The old prototype string format is deleted with NO back-compat loader.
3. Single file extension `*.fzw.json` for both widget and world files; the loader routes on the
   envelope's `kind` field, never the filename.
4. Phase order stands: file I/O (Phase 4) before world snapshot (Phase 5).
5. `kind:"widget"` restores assign fresh instanceNumericIDs (matches duplication); saved `#n`
   references not surviving is accepted.
6. Documentation: ALL ser/deser/duplication documentation lives in ONE dedicated reference doc,
   `Fizzygum/docs/serialization-duplication-reference.md` (created in Phase 1). CLAUDE.md files
   only LINK to it — one link line in `Fizzygum/CLAUDE.md`, a link-only
   `src/serialization/CLAUDE.md`. Never put the content itself in a CLAUDE.md.

## Working loop

For each phase N of plan §5: read the phase spec + the design sections it cites → implement per
its touch-list → run its exit gate (+ `fg suite` on every iteration, `fg gauntlet` at phase end)
→ update §9 and the reference doc → proceed to phase N+1. Phase 0's rig
(`Fizzygum-tests/scripts/serialization-roundtrip-headless.js`) must first REPRODUCE the §3
defect table on the unmodified build (expected-fail entries), then gets flipped green through
Phases 2-3; keep it green thereafter — it is the serialization gate.

## If reality contradicts the plan

The plan is evidence-based but ~470 classes have a long tail. If an assumption is falsified,
record it (dated note in the affected plan section + §9), choose the smallest redesign
consistent with §4's design decisions, and continue. Ask the owner only for genuine scope
decisions — not for anything §8 already settles. Loud, path-carrying `SerializationError`s on
unforeseen fields are the DESIGNED behaviour, not a plan failure: fix each by declaring a
transient, registering a well-known, or adding a typed handler, and add the case to the rig.
