# Gate severity classification — which checks are laws, which are budgets

Read 2026-11-21 against Fizzygum `b6b2f60f` / Fizzygum-tests `e06b7c26a`. Sources: `buildSystem/gates.js` (the 30
build rows), each ratchet script's inline numbers, `Fizzygum-tests/scripts/lib/gate-tokens.js` (the runtime tokens),
the gauntlet's leg list, `docs/architecture/lint-and-static-checks.md` §3b and §5.

The existing policy (§3b) sorts a rule by how SOUND its signal is (sound negative ⇒ hard gate; count-shaped smell ⇒
ratchet; heuristic ⇒ advisory). This note sorts by what a FINDING MEANS, which is what decides how far a session may
bend to satisfy it.

## The three classes

| Class | A finding means | The only acceptable answers | Never |
|---|---|---|---|
| **A. Invariant** | the product is wrong: a crash, a wrong pixel, a broken settle, a leak, a nondeterminism | fix the cause; if the cause cannot be fixed in scope, STOP and report | a raise, a new exemption, a flag that suppresses the check, a recapture that banks the wrong picture |
| **B. Convention at zero** | a house rule was broken; the code may still run correctly | comply honestly, or use the gate's OWN reasoned sanction marker when the exception is real | bending the design to avoid writing the sanction; a sanction with a boilerplate reason |
| **C. Budget (a ratchet above zero)** | something grew; look at it | classify the new occurrence: fix it if it is the smell, otherwise raise the number in the same change with a dated reason | inlining, folding, odd homes, offsetting trades, wording by length — any shape chosen for the count |

A class-A gate is not immune to contortion: its quiet fix (an exemption entry, a suppression flag, a stub) hides a
bug, which is worse than a class-C contortion. "Dead serious" means "fix the cause", never "go quiet".

## Class A — invariants (a finding is a bug)

Build rows:
- `run-selftests.js` — a gate whose proof broke gives no verdict worth reading.
- `check-coffee-syntax.js`, `check-tests-syntax.js` — a parse error boots nothing / loads no test.
- `check-shippable-coverage.js` — a directory no part claims ships nothing (`X is not defined` at runtime).
- `check-unresolved-sends.js` — a call nobody implements is a TypeError on any path reaching it.
- `check-call-arguments.js` (HOLE / EXTRA_ARGUMENT / POSITIONAL_INTO_OPTIONS, exact zero).
- `check-menu-actions.js` rules 1–2 (a function literal or a string in the wrong slot throws when clicked).
- `check-part-edges.js` — an unguarded core→part reference throws in the artifact that lacks the part.
- `check-layering.js` [A] [B] [C] [E] [F] [G] [T] — the flow soundness of the settle engine (LAYOUT).
- `check-thin-wraps.js`, `check-constructors-build.js`, `check-relayout-bounds-first.js` — settle-tier shape; the
  last one is the dpr-2 one-cadence-lag flake class (LAYOUT).
- `check-invalidation-receivers.js` — self-invalidation (a missed repaint, PAINT).
- `check-relayout-repaints.js` (tombstone), `check-back-buffer-memos.js`, `check-page-loaded-elements.js` — paint and
  save/restore correctness.
- `check-raw-pointer-reads.js`, `check-plane-discipline.js` A and C — input in the wrong plane (silent until tilted or
  scrolled).
- `check-macro-source-discipline.js` — an eval in a macro repaints the whole world and masks missing damage.
- `check-refs.js` — a stray reference lets a wrong render pass.
- `aim-census.js --tables-only` — a stale table means the census checks less.
- stinks at 0 whose finding is a fault: `debugger-statement`, `nil-literal` (a ReferenceError).
- `census-widget-conformance.js` undeclared fields 0 / 0 (an undeclared field is invisible to copy, save, inspector).

Runtime tokens the headless runners fail on (all of `GATE_TOKENS`): `NON_INTEGER_GEOMETRY`, `NON_FINITE_GEOMETRY`,
`LAYOUT_ERROR`, `PAINT_ERROR`, `STEP_ERROR`, `INPUT_ERROR`, `RECALC_NONCONVERGENCE`, `DOWNWALK_UNREACHABLE_CHAINTOP`,
`STACK_DISTRIBUTION_INVARIANT`, `MIXED_DIVISION_AXES`, `BAR_PIECE_UNORDERED`, `POPUP_LARGER_THAN_WORLD`,
`DAMAGE_SUPPRESSION_UNBALANCED`, `CACHED_DERIVATION_DIVERGED`, `STORAGE_INVARIANT`, `WORLD_CONSTRUCTION_DRIFT`,
`WORLD_INVENTORY_*`, `TRANSIENT_FIELD_UNDECLARED`, `INVARIANT_VIOLATED`, `STALE_ALLOWLIST_ENTRY`, the source/boot
tokens (`SOURCE_COMPILE_FAILED`, `SOURCE_EVAL_FAILED`, `HELPER_VAR_NOT_STRIPPED`, `CONSTRUCTOR_NOT_NAMED`,
`APP_CATALOG_ENTRY_MISSING`), the SWCanvas tokens.

Gauntlet legs: the three suites and `finger` (byte-exact screenshots), `fracplane`, paint audit, `capstone`,
`tiernaming`, `settle`, `revisits` (baseline EMPTY), `census` (arrange idempotence), `serialization`, `storage`,
`vmtruth`, `menusweep`, `pinsweep`, `parts`, `graph`, `apps`, `refs --pixels`, `selftests`; `fg fuzz`.

## Class B — conventions held at zero (a finding is a rule broken; the sanction marker is the honest exit)

- `check-call-separation.js` [S] settling 0 / effectful 0, [U] effectful 0 — exit: `# public-call-sanctioned:` (42 in
  src today), `public-api-allowlist.txt` (28).
- `check-layering.js` [D] (macro reaches a private) — exit: `# macro-private-call-sanctioned:`; [H] is a warning;
  [R] userland exemplars.
- `check-dead-methods.js` — exit: `dead-method-allowlist.txt` (10) with a reason.
- `census-hierarchy-duplication.js --gate` (identical override, 0) — exit: `# identical-override-sanctioned:` (0).
- `check-hand-lists.js` tests half (0) — exit: derive, or `# hand-list-sanctioned: <what fails>`.
- `check-menu-actions.js` rule 3 (padded slots, 0) — exit: name the slot `ignored` / `unused`.
- `check-stringified-scripts.js`, `check-region-markers.js`, `check-whole-file-markers.js`, `check-source-vault.js` —
  retired mechanisms held dead.
- `check-trailing-whitespace.js`, `check-scheduled-checks.js` — hygiene.
- stinks at 0 that are style or hygiene: `raw-chrome-color`, `comment-meta-edit`, `commented-out-debug`,
  `comment-past-receipt`.
- `check-doc-narration.js` narration (empty baseline; exit: `<!-- narration-ok: reason -->`), `BACKLOG_CLOSED_ITEM`.
- The macro discipline: `AIM MISSED` (a declared aim), `pointerKinds` (a test runs mouse AND finger unless its
  subject is a mouse mechanism).

Markers in src today: layout-apply 16, nosettle 11, early-return 11, double-settle 5, public-call 42, thin-wrap-exempt
10, cross-invalidation 13; relayout-bounds-first, raw-screen-pointer, escalated-pos, constructor-build,
stringified-script, identical-override, private-use: 0.

## Class C — budgets (ratchets above zero): a raise with a dated reason is a legitimate answer

| Ratchet | Today | What the number holds back | Classify a new occurrence as |
|---|---|---|---|
| `METHOD_CEILINGS` Widget / WorldWdgt / ActivePointerWdgt / FrameWdgt | 394 / 129 / 74 / 167 | a god class growing unwatched | a member that deserves its name and lives in its natural home ⇒ raise |
| cognitive complexity | ceiling 15; 94 recorded, 16…129 (median 23) | functions nobody can read | a split along a real seam, else raise or record |
| stink `instanceof-type-test` | 64 | type tests where a capability query belongs | an honest type test (a reflective walker) ⇒ raise |
| stink `comment-narration` | 80 | comments that tell history | a warning that must name what it bans ⇒ restate, or raise |
| stink `null-literal` | 6 | a second absence value | a foreign API that demands `null` ⇒ raise |
| `BASELINE_U_QUERY` | 103 | public queries nobody outside calls | deliberate inspector / scripting API ⇒ allowlist |
| `BASELINE_PROLOGUE_COPIES` | 8 | hand-copied `_reLayout` prologues | a deliberate exception ⇒ raise |
| `check-hand-lists` Fizzygum half | 4 | second sources of truth | sanction with a real guard |
| CLAUDE.md byte ceilings | 35421 / 67015 B | instruction files every session pays for | a true sentence that must grow ⇒ raise |
| `backlogItemChars` | 325 | the index turning into a plan | move detail to the plan (the gate's own right answer) |

Three class-C ratchets carry a class-A question inside them, so each new occurrence MUST be classified before any raise:
- stinks `clock-read` (5), `timer` (4), `math-random` (4): does it reach render, layout or input? Yes ⇒ a determinism
  bug, class A, whatever the count. No (a boot pump, a measurement) ⇒ raise with the reason.
- `check-plane-discipline.js` B (exactly 30): same plane by construction ⇒ raise; cross-plane ⇒ a bug, map it.

## What still pushes sessions toward contortions (read today, in the tree)

1. `check-complexity-ratchets.js:281` still ends every failure with "split the function or the class rather than
   raising a number here", directly under ceilings whose own comments record five owner-approved raises.
2. `check-call-separation.js:90` still says "never raise the baseline to ship".
3. `check-stinks.js:316` says "if genuinely intentional, raise … with a one-line reason" (partly right).
4. No gate prints its class, why its number exists, or which answers are wrong. BACKLOG item "A firing gate says how
   to go quiet, never when the quiet fix is wrong" (Gate audit 2026-11-16) is still open.
5. The latest loop brief (`scroll-indicators-loop/BRIEF.md` §66–69) allows "at most ONE dated ratchet raise per unit,
   by the smallest amount" and parks a unit that needs more. That is a cap, and a cap is itself a number a unit can
   contort around.
