# Starting prompt — execute FOLLOW-UP F1 of the "drop into rotated container: layout transparency" plan

(Paste everything below into a fresh session started in `/Users/davidedellacasa/code/Fizzygum-all`.)

---

You are working in `/Users/davidedellacasa/code/Fizzygum-all` — an umbrella workspace (NOT a
git repo) holding three sibling git repos: `Fizzygum/` (CoffeeScript framework source — the
only place you edit behavior), `Fizzygum-tests/` (the macro SystemTest suite), and
`Fizzygum-builds/` (generated build output — never edit).

**Orient first, in this order (do not skip):**
1. Read `CLAUDE.md` (workspace root) — build/test commands, the `fg` wrapper, shell discipline.
2. Read `Fizzygum/CLAUDE.md` — framework architecture and conventions.
3. Read `Fizzygum/docs/drop-into-rotated-container-layout-transparency-plan.md` IN FULL — **it
   is the single authority for your task**. Its §1–§8 describe an arc that is ALREADY
   IMPLEMENTED and sitting UNCOMMITTED in both repos' working trees (read the as-built status
   block at the top). **Your task is ONLY §9 — FOLLOW-UP F1.** Do not re-implement §5, do not
   revert anything, and do NOT commit: the top status block says the tree must not be
   committed until F1 lands.

**Current state you inherit (uncommitted, in the working trees):** `Fizzygum` —
`src/TrackingTransformFrameWdgt.coffee` (§5a layout-transparency forwarding),
`src/basic-widgets/Widget.coffee` (§5b bookkeeping transfer + §5c figure routing),
`src/StretchablePanelWdgt.coffee` (§5b nil-guard). `Fizzygum-tests` — two NEW tests
(`macroDropIntoRotatedStretchablePanelStretchesOnResize`,
`macroRotateChildInsideStretchablePanelThenResize`) + one benign recapture. HEADs are clean
(`01dbf101` / `5f5a34d43`); everything above is working-tree only.

**Your mission (plan §9):** the §5 fix makes wrapped children RESIZE correctly, but their
RENDER drifts off the slot box during container resizes (owner saw it in the slides maker:
post-tilt markers wander; near-edge ones get clipped out of sight). Root cause is CONFIRMED
numerically (§9.3): the Bug-D anchor-pinning in `TrackingTransformFrameWdgt._reLayoutChildren`
(the `else` extent-changed branch) fires on the §5a ARRANGE-driven forwarded re-fit; the
pinned anchor makes the island render offset by (I − sR)(A − c), which accumulates half of
every extent change. Implement §9.4 exactly: give `_reLayoutChildren` an `arrangeDriven =
false` ARGUMENT (no stateful flag); the TWO §5a forward sites (`_applyExtent` and
`_setWidthSizeHeightAccordingly` in `TrackingTransformFrameWdgt`) pass `true`; when
arrangeDriven, **nil the anchor** in the extent-changed branch instead of pinning (rationale
for nil-vs-normalize is in §9.4 — nil is the locked choice); every bare caller keeps the
Bug-D pin unchanged.

**Order of work:**
1. Step-0 repro: `/Users/davidedellacasa/code/Fizzygum-all/fg build`, then `cd
   Fizzygum-tests/.scratch && node repro-drop-into-rotated-container.js` — confirm legs A–D OK
   and leg E FAIL (`drift=14.7px pinnedAnchor=true`) before changing anything.
2. Implement §9.4 (a few lines in `src/TrackingTransformFrameWdgt.coffee`). Rebuild, re-run
   the probe: ALL legs OK, leg E drift ≤ 2px, verdict POST-FIX.
3. **Recapture the two new tests** — their references were captured WITH the drift baked in
   (§9.5): `fg recapture <testName>` for each, then REBUILD before re-running any suite.
   Verify `macroExplicitIslandFixedVsTrackingResize` passes UNCHANGED (it pins the
   content-driven direction you must not have touched). Investigate any OTHER reference diff
   before touching it.
4. Eyeball the real scenario once: open `Fizzygum-builds/latest/index.html`, slides maker →
   tilt the window → drop a few markers → resize by the handle — markers must stay glued to
   their fractional spots (the plan §9.1 screenshots scenario).
5. Gate: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` while iterating; finish with
   `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet`. Launch these long runs with the
   Bash tool's `run_in_background: true` redirected to a log file and wait for the completion
   notification — never foreground-poll, never pipe the fg call through `tail`/`grep`.
6. Update the plan's §9 status line (and the top status block) to reflect F1 landed; append
   any as-built deviations to §9.
7. STOP: present ONE combined summary of the WHOLE uncommitted arc (§5 + F1, both repos) plus
   proposed commit messages, and wait for explicit owner approval before any commit or push
   (standing owner rule).

**Hard rules (violations have burned hours before):** absolute paths everywhere (`git -C
<abs-path>`, invoke the wrapper as `/Users/davidedellacasa/code/Fizzygum-all/fg`, never
`./fg`); never hand-edit `Fizzygum-builds/`; edit `.coffee` files with the Edit tool only
(no perl/sed in-place — it de-indents CoffeeScript); a backtick anywhere in a macro test
file (even a comment) breaks the test-.js gate; ad-hoc Node probes go in
`Fizzygum-tests/.scratch/`, not the session scratchpad; `fg status` re-orients you in <1 s
after any compaction.
