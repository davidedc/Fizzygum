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

- [`build-and-packaging.html`](build-and-packaging.html) — how an artifact is
  assembled and selected: the partition (`parts.json`), the profiles, what a build
  derives rather than declares, the reflective layer and the `sources` axis, lazy
  parts (and the two traps peculiar to them), the gates, and the add-a-thing
  recipes. Companion to
  `../architecture/build-and-packaging.md` (authoritative). The program that
  produced this shape lives in `../archive/build-arc-1…5-*.md`; the earlier
  three-part explainer set that narrated the program as it was being planned was
  retired 2026-07-30 when the program closed (retrievable from git history).
