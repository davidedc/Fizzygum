# docs/explainers/ — visual walkthroughs for humans

Self-contained HTML pages (inline CSS/SVG, no external resources — they open over
`file://` like everything else here) that explain a subsystem or program visually,
for a reader with *some* Fizzygum context but no deep familiarity. Content is
ordered generic → specific; diagrams over prose where a diagram is clearer.

Explainers complement, never replace, the technical buckets: `architecture/` stays
the precise present-tense reference, `plans/` the executable detail. An explainer
that describes planned work states which plan owns each stage; when the plans land,
the explainer is updated to present tense or retired.

## Current sets

- **Build & packaging** (2026-07-28; describes the current state and the five-arc
  program owned by `plans/build-arc-1-test-serving-link-plan.md` through
  `plans/build-arc-5-packaging-profiles-plan.md` — filenames numbered by execution order;
  the explainer's "stages 1–4" are arcs 2–5, with arc 1 a small independent prelude):
  1. [`build-and-packaging-1-today.html`](build-and-packaging-1-today.html) — how the build, boot, backends, and the homepage flavour work today, and where it creaks.
  2. [`build-and-packaging-2-stages.html`](build-and-packaging-2-stages.html) — the four stages, what each retires, the completion doctrine.
  3. [`build-and-packaging-3-examples.html`](build-and-packaging-3-examples.html) — six everyday scenarios traced through the stages.
