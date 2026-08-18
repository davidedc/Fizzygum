# Partition slices — what each extraction actually cost, and how badly it was estimated

**Question it answers:** *what is making a part LAZY worth, and can the answer be predicted before
building?* Recorded 2026-08 for the eight slices landed 2026-07-30 → 2026-08-02 (`eed2f2f2` …
`55e61596`), i.e. the whole of the core-app-slices / dynamic-parts partition work.

The durable rules these numbers produced are stated once, present-tense, in
`docs/architecture/build-and-packaging.md` §5. **This file is the receipts.** Read it when you want
to know how a rule was arrived at, or to calibrate a new slice against comparable ones — not as a
statement of what the tree looks like today.

**Method.** The image and boot-bundle deltas were read off a `--profile homepage` tree fingerprinted
before and after each slice — the §8 discipline the architecture doc prescribes
(`Fizzygum-tests/scripts/build-tree-fingerprint.js compare <a> <b>`, at the SAME commit and the same
cleanliness, since the boot bundles carry a build stamp that gains `" +local-changes"` on a dirty
tree). The "source text moved" column is the slice's own `.coffee` bytes.

⚠ Note first where the saving comes from: **not** from the source bytes — production is
`sources: "lazy"`, so nobody was downloading those anyway — but from the **IMAGE**, because a lazy
part's classes are absent from `js/pre-compiled.js`.

## The eight slices

| Slice | Classes | Source text moved behind an on-demand fetch | Off production's `pre-compiled.js` |
|---|---:|---|---|
| `maps` | 4 | 95.0 KB (97.5% code) | **−55.8 KB (−5.1%)** |
| `spreadsheet` | 12 | 119.4 KB (27.9% code) | **−33.7 KB (−3.4%)** |
| `authoring` | 54 | 94.3 KB (75.3% code) | **−91.9 KB (−9.8%)** |
| unpinning what only lazy parts named | 81 | 100.6 KB (71.8% code) | **−119.5 KB (−14.15%)** |
| the Examples folder's five doors | 5 | 19.7 KB (64% code) | **−11.7 KB (−1.62%)** |
| every remaining app icon + the folder's own art | 11 | 29.3 KB | **−14.0 KB (−1.97%)** |
| what no boot path reaches (`fg whatpins`) | 9 | 20.1 KB (12.2 KB code) | **−16.8 KB (−2.46%)** |
| the shared base layer → `app-kit` | 9 | 23.3 KB (9.8 KB code) | **−13.2 KB (−1.93%)** |

⭐ **Cumulatively, `js/pre-compiled.js` went 936,920 → 669,855 B — −28.5%** — and production's eager
image became exactly `core`, with nothing left in it that no boot path reaches except `CanvasWdgt`
and `PatchNodeWdgt` (blocked by rule, not by cost — build-and-packaging §5).

## Four misses, then a hit — why the estimator is not to be trusted

⚠⚠ **The third row broke the estimator a second time, in the OTHER direction — the image cost tracks
CLASS COUNT at least as much as code bytes.** `authoring` and `maps` move almost exactly the same
source (94.3 vs 95.0 KB), yet `authoring` takes 1.65× as much off the image. It has 54 classes to
maps' 4, and every class compiles to its own prototype scaffolding, which the source bytes do not
show. Estimating `authoring` from maps' KB-of-code ratio predicted −42 KB against an actual
−91.9 KB: **2.2× LOW**, having been 33% low for `maps` and 50% high for the spreadsheet. The fourth
row confirms the class-count reading a second time and missed the same way (predicted order −70 KB,
measured −119.5 KB): 81 mostly one-method icon classes, the smallest-per-class slice yet, took the
most off the image of any of them. Four slices, four misses, in both directions.

⚠⚠ **Source bytes do not predict image bytes, and the ratio between them varies by 2.5×.** `maps` is
vector-path artwork — 2.5% comment bytes, essentially all code. `src/spreadsheet` is 72.1% COMMENT
bytes, and comments never reach a compiled, minified image. So a per-KB-of-source estimate calibrated
on one slice was 33% LOW for `maps` and 50% HIGH for `spreadsheet`.

⚠ **The last row is the first prediction that landed** — stated in words before the build ("−12 to
−16 KB, on the class-count reading") against a measured −13.2 KB, and the boot bundle's +369 B against
a predicted +250–450 B. Five misses then a hit is not a calibrated estimator; it is one slice that
happened to resemble the row above it (9 classes both times). What actually paid was the other half of
the discipline — **treat any unpredicted FILE as a finding** — since the source-batch repacking that
turned up (one batch replaced, seven rewritten) is exactly the kind of churn a size-only check would
have read straight past.

## The pinned set is a fixpoint

The fourth row is not an app slice at all: it is the classes whose only namers were already-lazy
parts, which stayed in `core` only because moving them would have made an unordered cross-part edge —
the thing `requires` now orders. Because each mover takes its own references with it, the set has to
be re-derived after every round: **48 files qualified, moving them qualified 28 more, then 4, then
1.** (`buildSystem/pinned-by-lazy-parts.js`.)

The seventh and eighth rows are the same tool's list read twice, and the difference between them is
the lesson: `ToolbarWdgt`, `ToolbarCreatorButtonWdgt` and `IconicDesktopSystemWindowedApp` were left
behind on the seventh with a stated reason — moving them would oblige `plots requires ["authoring"]`
for 1.2 KB — and the eighth moved all nine of them by rejecting the assumed home rather than the move
(`app-kit`). The sixth row is `fg whatpins`' first harvest: `DegreesConverterIconAppearance`, 9.5 KB of
art nothing draws but one icon inside a folder, had stayed in the production image until it was
spotted BY EYE, because `pinned-by-lazy-parts.js` reads only ONE level over the partition as it stands.

## The toll on the boot bundle

The runtime parts manifest carries each part's `classes` name list, so a lazy part is not free on the
critical path:

| change | `js/fizzygum-boot-native-min.js` |
|---|---|
| extracting `authoring` | **+1,857 B** (17,158 → 19,015; the manifest is 3,554 B of it) |
| moving 81 more classes into EXISTING parts | **+1,935 B** (19,158 → 21,093) — no new part at all |
| the same change on `lean` (ships no lazy part, hence no such list) | **−3 B** |
| six MORE parts (five one-class doors plus `examples-icons`) | **+397 B** between them |

⇒ the toll is per CLASS NAME, not per part — which is what settles the "many tiny parts would
eventually spend more on the manifest than they save" worry at this scale.

## Boot speed: the payoff, and why the floor moved

The boot numbers themselves are `docs/measurements/boot-timing-2026-07-31.md` (production 54 ms of
which ~46 ms is the image parse+execute; the compile-at-boot `dev` `index.html` 3219 ms, 97% of it
compiling, ~8.6 ms per source). Two things about them are worth stating HERE, because they are about
the partition rather than about booting:

- The **2680 ms floor** quoted there was measured when core was **389 of the 452** sources the dev
  page compiled. The slices above are exactly what moves that ratio: core is now a far smaller share
  of the eager set, so the floor is lower and the quoted figure is a historical reading, not a
  standing one. Re-derive it rather than quoting it.
- On the production path there was nothing left to win even at the START of this work. A slice worth
  ~1.6% of the image buys about half a millisecond. ⇒ extract further parts for download size,
  partition uniformity, or dev-page boot — never for production startup.
