# Starting prompt — drag-embed dwell-to-arm EXECUTION (Phases 1-6)

Paste the block below verbatim as the first message of the executing session.

---

You are executing a fully-specified UX arc in the Fizzygum workspace at
`/Users/davidedellacasa/code/Fizzygum-all/` (an umbrella folder, NOT a git repo, holding three sibling git
repos: `Fizzygum/` = source, `Fizzygum-tests/` = the 181-test byte-exact screenshot suite,
`Fizzygum-builds/` = generated output, never edited).

READ, IN THIS ORDER, BEFORE TOUCHING ANYTHING:
1. `Fizzygum-all/CLAUDE.md` (workspace + `./fg` command wrapper), `Fizzygum/CLAUDE.md` (architecture),
   `Fizzygum-tests/CLAUDE.md` + `Fizzygum-tests/DETERMINISM.md` (suite + determinism doctrine).
2. `Fizzygum/docs/specs/drag-embed-interaction-spec.md` — the DESIGN. Every decision in it is owner-approved
   and LOCKED; do not re-litigate. §6 contains a revision record (the dwell mechanic was already falsified
   once and reframed — its remaining falsification budget is 1).
3. `Fizzygum/docs/drag-embed-implementation-plan.md` — the EXECUTION PLAN. §0a is your BINDING working
   contract (commit/push policy, gates, recapture rules, stop conditions, hygiene). §1 is a fresh-verified
   anchor table. §2 records the completed spikes — read the findings box carefully, including the S3 scope
   note. §3 defines Phases 1-6. Appendix A holds a throwaway probe you may re-create for visual checks
   (never commit it).

THE TASK: execute Phases 1 through 6 of the plan, in order, one phase at a time.
- The spikes (Phase 0) are DONE — start at Phase 1 (ephemeral infrastructure).
- Before Phase 1: confirm the tree state (`git -C Fizzygum log --oneline -1` — the plan was verified on
  `b91cd9b5`; if the tree has moved, re-grep the §1 anchors you are about to touch rather than trusting line
  numbers), and confirm the suite is green (`./fg suite` after `./fg build`).
- Per phase: implement per the plan's touch-list, run the phase's gates (`./fg gauntlet` at minimum; the
  phase text says when serialization legs / `./fg homepage` are also required), append a dated LANDED-STATUS
  line with real numbers under the phase heading in the plan, then STOP and present to the owner: what
  landed, gate results, deviations, proposed commit message(s). Commit ONLY after explicit owner approval
  (git commit -F <file>; lockstep commits across the two repos when both change). NEVER push.
- The spec and plan docs are untracked; propose including them in the Phase 1 commit.
- New SystemTests are authored with the `/author-macro-test` skill in `Fizzygum-tests`.

HARD RULES (full set in plan §0a — these are the ones people break):
- Byte-exactness is the default bar: a phase that intends "no pixel change" must PROVE it with the gauntlet
  before any such claim is written anywhere.
- Never hand-edit `Fizzygum-builds/**`; never grep from the workspace root; route builds/tests through
  `./fg` from the umbrella root.
- Recaptures only via the full `./fg recapture <name>` flow; re-verify the webkit leg afterwards; benign
  inspector recaptures are pre-authorized — never contort code to avoid one.
- Determinism: input/layout/render decisions are pure functions of the event stream; timed VISUALS follow
  the stepping + `Automator.animationsPacingControl` pattern (see `src/apps/AnalogClockWdgt.coffee:99-108`).
  Any new `Date.now()` in decision logic is a defect.
- Two falsified fix-shapes on one problem → stop and reframe with the owner; do not try a third variant.
- State an ETA before long operations; post status every ~5 minutes.

Begin by reading the docs listed above, then confirm tree + suite state, then propose your Phase 1 execution
outline (files, edits, gates, expected pixel impact) in a few sentences before writing code.

---
