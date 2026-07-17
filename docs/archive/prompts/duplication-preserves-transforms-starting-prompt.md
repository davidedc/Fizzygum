# Starting prompt — execute the "duplication & save preserve transforms" plan

(Paste everything below into a fresh session started in `/Users/davidedellacasa/code/Fizzygum-all`.)

---

You are working in `/Users/davidedellacasa/code/Fizzygum-all` — an umbrella workspace (NOT a
git repo) holding three sibling git repos: `Fizzygum/` (CoffeeScript framework source — the
only place you edit behavior), `Fizzygum-tests/` (the macro SystemTest suite), and
`Fizzygum-builds/` (generated build output — never edit).

**Orient first, in this order (do not skip):**
1. Read `CLAUDE.md` (workspace root) — build/test commands, the `fg` wrapper, shell discipline.
2. Read `Fizzygum/CLAUDE.md` — framework architecture and conventions.
3. Read `Fizzygum/docs/archive/duplication-and-save-preserve-transforms-plan.md` — **this is the
   single authority for your task**; it is self-contained (root cause with file:line refs,
   fix sketch, test deliverables, gates). Follow it; where it defers a detail to "the
   implementing session", that's you.

**Your mission:** duplicating a rotated/scaled widget currently produces an UN-transformed
copy, and "save to file…" saves an un-transformed widget. The root cause is already
diagnosed (plan §1): the menu entry points operate on the content widget instead of the
enclosing transform-island figure. Implement the entry-point fix (plan §2, ~15 lines in
`Fizzygum/src/basic-widgets/Widget.coffee`), behaviourally confirm and fix the flagged
sibling "pick up"-menu defect (§2a), and author the macro SystemTests (§3) that fail
pre-fix and pass post-fix. Do NOT implement §2b (owner-gated Phase 2) and do NOT change
`fullCopy`/`deepCopy`/`Serializer` semantics.

**Order of work:**
1. Step-0 repro exactly as the plan prescribes (build with
   `/Users/davidedellacasa/code/Fizzygum-all/fg build`, reproduce in the browser or a quick
   headless probe) — confirm the bug before changing anything.
2. Implement plan §2 items 1–3; verify the §2a pick-up defect behaviourally, then fix it as
   sketched.
3. Author the tests (plan §3) with the `/author-macro-test` skill in `Fizzygum-tests`;
   prove each fails against pre-fix code via a WIP commit or worktree A/B (NEVER `git stash`
   in these repos). Capture references with `fg recapture <testName>`, then REBUILD before
   re-running any suite.
4. Gate: `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` while iterating; finish with
   `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet`. Launch these long runs with the
   Bash tool's `run_in_background: true` redirected to a log file and wait for the
   completion notification — never foreground-poll, never pipe the fg call through
   `tail`/`grep`. Expect ZERO recaptures of existing tests (plan §2 dormancy argument);
   investigate any unexpected diff before touching references.
5. STOP: present a summary of changes in BOTH repos plus proposed commit messages, and wait
   for explicit owner approval before any commit or push (standing owner rule).

**Hard rules (violations have burned hours before):** absolute paths everywhere (`git -C
<abs-path>`, invoke the wrapper as `/Users/davidedellacasa/code/Fizzygum-all/fg`, never
`./fg`); never hand-edit `Fizzygum-builds/`; edit `.coffee` files with the Edit tool only
(no perl/sed in-place — it de-indents CoffeeScript); a backtick anywhere in a macro test
file (even a comment) breaks the test-.js gate; ad-hoc Node probes go in
`Fizzygum-tests/.scratch/`, not the session scratchpad; `fg status` re-orients you in <1 s
after any compaction.
