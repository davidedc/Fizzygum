# docs/explainers/ — visual walkthroughs for humans

Self-contained HTML pages (inline CSS/SVG, no external resources — they open over
`file://` like everything else here) that explain a subsystem visually, for a reader
with *some* Fizzygum context but no deep familiarity. Content is ordered generic →
specific; diagrams over prose where a diagram is clearer.

Explainers complement, never replace, the technical buckets: `architecture/` stays
the precise present-tense reference, `plans/` the executable detail. An explainer
that describes planned work states which plan owns each stage; when the plans land,
the explainer is updated to present tense or retired.

## Current explainers

The two are companions and deliberately split at one seam: **`build-and-packaging`
is how an artifact is ASSEMBLED, `boot-and-lazy-parts` is what happens when you
OPEN it.** Anything about `parts.json`, profiles or the build's derivations belongs
in the first; anything about the boot sequence, the reflective layer's arrival or
`world.parts` at runtime belongs in the second.

- [`boot-and-lazy-parts.html`](boot-and-lazy-parts.html) — how a Fizzygum page comes
  up and how code arrives afterwards: the entry page's two presets, the boot bundle's
  load-bearing order, the two boot paths (compile-at-boot vs pre-compiled image), the
  reflective layer and the meta-system split inside it, `PartsRegistry` loading a part
  on demand behind a running world, the six questions and the method that answers
  each, the five traps peculiar to lazy parts, and the Node rigs that cover what the
  SystemTest suite structurally cannot. Companion to
  `../architecture/build-and-packaging.md` §2 and §5 (authoritative).

- [`input-and-gestures.html`](input-and-gestures.html) — how input works: mouse and
  touch as one Pointer-Events pipeline (one event family, two construction
  boundaries, the event-time queue), the two TIERS of widget-facing verb (stroke
  FACTS vs certified GESTURES), the hand's per-stroke grammar (what a touch press
  means — the decision flow, the four finger gestures as timelines, the hold as the
  context gesture's second trigger, a scroll dispatches no click), typical
  interactions side by side, and how the test system covers both kinds (the
  dedicated touch witnesses, the finger-mode replay of the whole corpus, the two
  reference baselines one directory axis apart, and which gauntlet legs run what). Companion to
  `../architecture/input-and-gestures.md` (authoritative).

- [`build-and-packaging.html`](build-and-packaging.html) — how an artifact is
  assembled and selected: the partition (`parts.json`), the profiles, what a build
  derives rather than declares, the reflective layer and the `sources` axis, lazy
  parts (and the three traps peculiar to them), the gates, and the add-a-thing
  recipes. Companion to
  `../architecture/build-and-packaging.md` (authoritative). The program that
  produced this shape lives in `../archive/build-arc-1…5-*.md`; the earlier
  three-part explainer set that narrated the program as it was being planned was
  retired 2026-07-30 when the program closed (retrievable from git history).
