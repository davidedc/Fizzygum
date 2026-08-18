> **ARCHIVED — COMPLETE (owner-ratified P0 + executed 2026-08-06, same day as authoring).**
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# The island is a LENS — its content-stack preferences are its content's knob

**STATUS: RATIFIED + EXECUTED IN FULL 2026-08-06 (P0 owner-ratified on the pure-cleanliness
question; P1+P2 same day). See the execution ledger at the bottom: one in-flight discovery
(the materialize's empty-window seam → the pre-seed), suite 282 → 283, gauntlet green.**

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
Authored 2026-08-06; every fact below verified same day against Fizzygum `76130d2f` /
Fizzygum-tests `c8a2b8775` (the kept-spec knob-model arc's close; suite 282, gauntlet
14/14). ⚠ Line numbers drift — quoted method/class names are authoritative; re-grep first.

**MANDATE + RECOMMENDATION (owner-decided direction wanted at P0, then execute).** Decide —
and the Right-Thing recommendation is YES — that a sugar/transform ISLAND's content-stack
preferences ARE its content's knob: `TransformFrameWdgt` gains the two content-stack
initialiser overrides, each DELEGATING creation to `@contents`' own initialiser and SHARING
the resulting object. This is a small, uniform completion of the knob model, not a
compatibility patch — but it deliberately restores the pre-fold behavior in two corner
flows, so the owner should ratify the framing before code.

## §0 Orientation

**Fizzygum** — CoffeeScript canvas GUI framework; build + test via `fg` (`fg build` ·
`fg presuite` · `fg gauntlet`; long ops backgrounded with log + verdict). Read first:
`Fizzygum/CLAUDE.md`, `docs/architecture/layout.md` §4.2 (the spec family: TWO lifecycle
kinds — carrier-owned KNOB, e.g. the content-stack spec `Widget._contentStackSpec`, vs
per-attachment RECORD; container reads go SLOT-FIRST through `Widget.contentStackSpec()`),
`docs/architecture/transforms.md` (islands: `TransformFrameWdgt` wraps content;
`_materializeSugarIslandNoSettle` / `_dematerializeSugarIslandIfIdentityNoSettle` in
`Widget.coffee` — the ACTIVE spec rides the `layoutSpec:` add-arg; the knob stays on the
wrapped content since the kept-spec fold deleted the hand-carry).

**Why now.** The kept-spec fold (`docs/archive/kept-layout-spec-unification-plan.md`,
closed 2026-08-06) made the island keep NO content-stack knob of its own: when an island is
ADOPTED by a content stack or MOUNTED as window content while its slot does not already
carry a suitable spec, the base initialisers create FRESH base-default preferences on the
island. Pre-fold, the island hand-carry made it inherit the content's knob. Two corner
flows differ (both unpinned by any test, gauntlet-green):
1. Rotate a WINDOW's content: the island becomes `@contents` of the `FrameWdgt`; the mount
   guard (`FrameWdgt._addNoSettle` ~:601, `unless aWdgt._contentStackSpec?.isFrameContentSpec?()`)
   finds nil on the island → fresh `FrameContentLayoutSpec` with BASE sentinels — e.g. a
   rotated clock's window becomes freely height-stretchable while wrapped (the clock's own
   knob declares `canSetHeightFreely = false`); unwrap restores the content's knob fully.
2. Drop a desktop-rotated figure (island slot = stretch record) into a document: the stack
   adoption guard (`SimpleVerticalStackPanelWdgt._positionAndResizeChildren` ~:267,
   `unless widget.layoutSpec?.isStackElementActive?()` → `initialiseDefaultVerticalStackLayoutSpec()`)
   finds no capable knob on the island → fresh VSLS with derived defaults — the content's
   alignment/grow edits stay dormant on the content until it is unwrapped and re-adopted
   itself.

**CRITICAL REFRAME.** This is NOT "restore old behavior" — it is a modeling question the
fold surfaced: is the island a WIDGET with its own content-nature, or a LENS displaying its
content? The content-stack knob holds preferences about the DISPLAYED thing's nature
("empty vertical space around a clock is meaningless", "this paragraph centers"). The
island displays exactly that thing, rotated — it has no content-nature of its own. The
family's own E6 idiom (each class declares its defaults via initialiser overrides) is the
sanctioned home for the answer: the island's override declares "my preferences are my
content's knob".

## §1 Current state (verified 2026-08-06 at `76130d2f`)

- `TransformFrameWdgt` has `@contents` and NO `initialiseDefault*` overrides (grep: zero
  hits) — it inherits `Widget.initialiseDefaultFrameContentLayoutSpec` (~:336; creates a
  base FrameContentLayoutSpec, binds `.element = @`) and
  `initialiseDefaultVerticalStackLayoutSpec` (~:343; guarded `unless
  @_contentStackSpec?.isContentStackCapable?()`).
- The two adoption/mount seams read the widget-being-attached's KNOB FIELD (deliberately —
  W4 in the fold's census, mechanism-untouched): `FrameWdgt._addNoSettle` ~:601-612 and
  the stack adoption ~:267-273. Cross-widget object sharing is SAFE in both graph engines
  (identity-mapped; probe-proven in the fold's E1-M4,
  `Fizzygum-tests/.scratch/kept-spec-sharing-probe.js` — fullCopy and whole-world
  snapshot round-trip preserve shared substructure as one object).
- The capture re-binds `.element` at every (re)placement
  (`VerticalStackLayoutSpec.captureInitialPlacement: (@element, @stack) ->`), so one
  object serving content-then-island-then-content re-binds correctly per armed carrier.
- The lifecycle oracle: `SystemTest_macroContentStackKnobSurvivesDetachReadd` (the fold's
  P3 test) + the two `.scratch` probes (`kept-spec-coexistence-probe.js` C/D sections pin
  today's island carriage).

## §2 Why it is shaped this way

The fold's P1 deliberately scoped the initialisers as mechanism-untouched (the knob model's
correctness didn't depend on them), which left the island's defaults at the base. The
pre-fold inheritance was an ACCIDENT of the hand-carry's plumbing, never a modeled
decision — this plan models it.

## §3 The distilled argument

Under the knob model every class declares its own default preferences — and a transparent
wrapper's honest declaration is "my content's". Implementing it as initialiser-time
DELEGATION + OBJECT SHARING (not read-time delegation, which the family bans; not a value
copy, which diverges on edit) gives: the content's CLASS-specific override runs (a clock
content yields clock defaults), user edits made through the island hit the one object the
user thinks they are editing, and unwrap needs zero hand-off (the content's field held the
object all along). Cost: two small overrides. The alternative (status quo) costs nothing
but leaves the wrapped-state behavior contradicting the content's declared nature.

## §0.5 Cold-execution protocol

1. `fg status` — Fizzygum at/past `76130d2f`, tests at/past `c8a2b8775`, 282 tests, last
   gauntlet green; else STOP and re-orient.
2. Read this plan; layout.md §4.2; the fold's archived plan §4 E4/E5 + E1-M4; in src:
   `Widget` initialisers + materialize/dematerialize pair, `TransformFrameWdgt` (class
   head + `@contents` handling), `FrameWdgt._addNoSettle` ~:601-612, the stack adoption
   ~:267-273, `FrameContentLayoutSpec.captureInitialPlacement`.
3. P0 = present the §4 decision to the owner (one message: the lens framing vs status
   quo); on ratification execute P1 in one batch; gates per §6.
4. Never commit/push without the owner's word.

## §4 The decision + the fix shape (recommendation: EXECUTE)

D1. **The lens overrides, on `TransformFrameWdgt` (both flavors):**
    ```coffee
    initialiseDefaultFrameContentLayoutSpec: ->
      # a transform island is a LENS: its content-stack preferences ARE its content's
      # knob — creation delegates to the content's own class-specific initialiser and
      # the OBJECT is shared (identity-mapped by both graph engines; edits made through
      # the island hit the one knob the content resumes on unwrap). An authored EMPTY
      # island falls back to its own base defaults.
      return super() if !@contents?
      @contents.initialiseDefaultFrameContentLayoutSpec() unless @contents._contentStackSpec?.isFrameContentSpec?()
      @_contentStackSpec = @contents._contentStackSpec

    initialiseDefaultVerticalStackLayoutSpec: ->
      return super() if !@contents?
      @contents.initialiseDefaultVerticalStackLayoutSpec() unless @contents._contentStackSpec?.isContentStackCapable?()
      @_contentStackSpec = @contents._contentStackSpec
    ```
    (Spelling indicative — match the base guards exactly; the frame flavor must preserve
    the mount's role-flip/un-latch behavior, which operates on the returned object as for
    any veteran knob.) ⚠ VERIFY `@contents` is the right accessor on TransformFrameWdgt
    (vs a positional child) — grep its class body first.
D2. **Sharing, not copying:** the island's field and the content's field hold ONE object
    while the island exists. E1-M4 proves both engines round-trip this as shared; the
    fold's `kept-spec-sharing-probe.js` C/D sections become the standing oracle (extend
    with one check: island-mounted-in-window inherits `canSetHeightFreely`).
D3. **Behavior deltas (owner-visible, the point of the plan):** a rotated clock's window
    is height-locked again while wrapped; a rotated stack element adopted by a document
    applies the content's alignment/grow edits. Both restore the pre-fold semantics — as
    modeled behavior, not compat.
D4. **Rejected:** read-time delegation (family ban: synchronously-maintained fields);
    value-copying (edit divergence); status quo (leaves the lens lying about its
    content's nature — acceptable only if the owner prefers "island = plain widget",
    in which case CLOSE this plan as a decision record, delete nothing).

## §5 Phases

P0 — present §4 to the owner (this plan IS the design note); ratify or close-as-decided.
P1 — the two overrides + probe extension + a value-assert leg added to the fold's
     lifecycle test OR a small new macro (rotate a window's clock content → assert the
     window's height-freedom while wrapped → unwrap → assert restoration; capture dpr
     1+2, non-vacuous by plant + flipped assert).
P2 — docs (transforms.md island section + layout.md §4.2 one-line lens note), BACKLOG,
     archive + INDEX + memory, close.

## §6 Verification protocol

`fg presuite` per batch; `fg gauntlet` at close; BOTH serialization rigs + `fg homepage`
(the shared-object shape appears in snapshots whenever an island exists); the two
`.scratch` probes re-run; expected suite churn ZERO (no existing test pins the wrapped-
state defaults — verified at authoring).

## §8 References

`docs/archive/kept-layout-spec-unification-plan.md` (E4/E5/E1-M4 + §7 case law) ·
`docs/architecture/layout.md` §4.2 · `docs/architecture/transforms.md` · memory:
`kept-layout-spec-unification-arc`, `ask-before-commit-push`.

### Execution ledger (append per phase; empty at authoring)

**P0 RATIFIED 2026-08-06.** Presented after the corner-spec dissolution arc closed
(Fizzygum `41584e2f` / tests `5e04e2cca`); owner asked whether the LENS framing is the
Right Thing on pure cleanliness grounds regardless of compat, and ratified EXECUTE on the
answer: the overrides complete the island's existing "invisible plumbing" doctrine family
(isTransparentAt / escalate-only click / resolvesEditorSelectionToContent / derived claims)
rather than adding a mechanism; the restored pre-fold behaviors are consequences, not the
motivation. ⚠ Verified corrections to §4's sketch: the island has NO `@contents` field —
the content accessor is `TrackingTransformFrameWdgt._soleContent()` (to be HOISTED to base
`TransformFrameWdgt`), and the delegation must be robust to the content seam (one-content-
for-life made structural, not incidental).

**P1 EXECUTED 2026-08-06.** `_soleContent()` hoisted to base `TransformFrameWdgt`; the two
LENS overrides added there (FCLS flavor mirrors the mount seam's guard — create fresh on the
CONTENT only when it has no frame-content-capable knob; VSLS flavor delegates
unconditionally, the content's own initialiser carries the keep-a-capable-knob guard; both
fall back to `super()` for an EMPTY island). ONE in-flight discovery, probe-first: the
sharing probe's new E1 check FAILED on the window flow — `_materializeSugarIslandNoSettle`
homes the island into the former parent BEFORE reparenting the content (the load-bearing
skin-derivation order), so a FrameWdgt former parent's mount guard ran the initialiser while
`_soleContent()` was still nil → base fallback → fresh spec. Fix: the materialize PRE-SEEDS
`island._contentStackSpec = @_contentStackSpec` before homing (the one seam that asks during
the empty window; the overrides cover every flow where the island holds its content).
Verification: BOTH kept-spec probes updated to the post-fold rename (`_stackElementSpec` →
`_contentStackSpec`, they predated P2's rename) and to the lens shape (island field now
SHARES the knob — C0/C1/D1/C2/D3), and the sharing probe gained the E section (window flow
E0-E2, stack flow + edit-through-island E3-E4): 16/16 + 11/11 green. New
`SystemTest_macroIslandLensWindowHeightLock` (suite 282 → 283, dpr 1+2): identity oracles
(`assertValuesEqual` + rule-[D] sanction comments) + the wrapped-resize height-lock pixels;
NON-VACUOUS by plant — disabling the pre-seed flips exactly the two sharing asserts + the
pixels (⚠ the clock's-own-knob VALUE assert stays true under the plant — the identity
asserts are the sharp oracle; catalogued in MACRO-PATTERNS.md). While wrapped the window BAR
reads "transform frame" (the bar labels the contents' colloquialName — pre-existing naming
behavior, surfaced to the owner as a possible future lens-family item, out of scope here).
`fg presuite` OK (dpr1 283 green + paint).

**P2 EXECUTED 2026-08-06.** Docs: transforms.md gains §5.4 (the LENS declarations),
layout.md §4.2's island-sharing paragraph updated (delegating initialisers + pre-seed,
slot/field sharing); BACKLOG line closed; archive + INDEX + memory per the close ritual.
Close gates: **fg gauntlet 14/14 GREEN (4m24s — dpr1/dpr2/webkit suites at 283, apps, parts,
paint, tiernaming, settle, capstone, refs, revisits, census, BOTH serialization rigs,
storage) + fg homepage OK** (production boot + snapshot round-trip).

**SAME-DAY FOLLOW-UP (owner-directed): the THIRD lens member — `colloquialName` read-through.**
The P1 observation (bar reads "transform frame" while wrapped) landed as
`TransformFrameWdgt.colloquialName -> @_soleContent()?.colloquialName() ? "transform frame"`,
plus the timing twin of the pre-seed: the FrameWdgt bar CAPTURES the name at mount — during
the materialize's empty window — so the island's `_reactToChildAdded` nudges the new
intent-named public note `FrameWdgt.noteContentsNameMayHaveChanged()` once the content
arrives (⚖ captured-during-the-empty-window is a seam CLASS). The lens test gained the name
oracle; its two wrapped shots recaptured COMPLETE at dpr 1+2 (the gate's full-suite runs
prove no other test sees the name change — consumer census: bar titles, inspector/console
titles, the naming service; hierarchy/menus are CLASS-named and never ask). Gauntlet 14/14
(5m44s) + homepage green again.

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

The closed items this plan owned, relocated VERBATIM from `docs/BACKLOG.md` on 2026-08-18 so
that file can go back to being an index of OPEN work only (`docs/README.md` filing rule 2: an
arc's items leave BACKLOG when it closes). Nothing above this line changed; any item of this
arc still OPEN stayed in `docs/BACKLOG.md`.

- [x] Island content-stack preferences — the LENS decision. **RATIFIED + EXECUTED 2026-08-06** (`archive/island-content-preferences-plan.md`): a `TransformFrameWdgt` island's content-stack preferences ARE its content's knob — the two initialiser overrides DELEGATE creation to `_soleContent()`'s own initialiser and SHARE the object, completing the island's "invisible plumbing" doctrine family (transforms.md §5.4); a rotated clock's window is height-locked again while wrapped, a rotated stack element applies the content's alignment/grow edits — modeled behavior, not compat. ⚠ ONE seam asks while the island is still EMPTY (the materialize homes the island into a FrameWdgt parent BEFORE reparenting the content — the load-bearing skin-derivation order — and the mount guard initialises right then): the materialize PRE-SEEDS the island's field with the content's knob. Suite 282 → 283 (`macroIslandLensWindowHeightLock` — identity oracles + wrapped-resize height-lock, non-vacuous by pre-seed plant: exactly the two sharing asserts + the pixels flip); both kept-spec probes extended (E sections) and green.
