# Reference filename grammar: retire `systemInfoHash`, name the Automator version instead

**✅ EXECUTED 2026-08-22 — CLOSED HISTORICAL RECORD.** Authored and executed the same day.
All phases landed; the living truth is now `CLAUDE.md` § "Test & reference-image layout".

> **As-built.** All 3,684 reference files carry `-automatorV0_2_0-`; zero legacy names remain.
> `refpaths.js` is the sole parser and the four bypassing regexes route through it; the runtime
> groups by the RECORD's Automator version, not the filename. `dataHash` never changed, and
> `check-refs:pixels` read 1,842 verified-consistent before, during and after — so no pixel moved.
> Landed as 11 commits in this repo (code → 8 reference batches → drop the legacy branch → docs)
> plus one docs commit in `Fizzygum`. Four gauntlets, 18/18 each.
>
> **Three things this plan got wrong, recorded so the next reader does not repeat them:**
> 1. **§4/§9's BACKLOG claim was false.** This item was *not* filed under "Pointer hit-test rework
>    2026-08-21 — residue"; `systemInfoHash` appeared nowhere in `docs/BACKLOG.md`. A ledger line for
>    the completed work was added instead of closing out a non-existent entry.
> 2. **§5 Phase 1's write-path proof (`fg recapture <test>`) is a no-op on a green test.** Capture
>    only writes images that did NOT match, so a recapture of a passing test writes nothing and no
>    name changes. The proof needs a CLEANING capture (`capture-macro-test-references.js`, which
>    cleans by default). This is also why the migration could not be done by recapturing.
> 3. **The rename orphans every `visualisation.html`** — 279 committed pages embed reference
>    filenames, and nothing in the plan regenerated them. The migration script therefore regenerates
>    each converted test's page at its write site, the way the capture path already does.
>
> §3's measurement reproduced exactly, and was strengthened from a 2-file sample to all 1,842
> records: 2 hash values, one distinct `systemInfo` blob each, differing in exactly `screenWidth` /
> `screenHeight` / `screenColorDepth`. Two risks the plan asserted but did not prove were measured
> and came back zero — collapsing the two groups creates no name collisions and no new AMBIGUOUS
> failures, because there is exactly one reference file per (directory, imageName, extension).

**MANDATE — eliminate the problem, do not make it easier to live with.** The goal is that a
reference filename stops encoding facts that cannot affect a reference's pixels, so the churn class
disappears permanently rather than being normalised once and left to recur. A one-off rename pass
that leaves the grammar unchanged is explicitly NOT the goal (see §8 Rejected alternatives).

---

## §0 Orientation

### What this repo is

`Fizzygum-tests` holds the SystemTest suite (309 tests) and the Automator harness source for the
Fizzygum GUI framework (sibling repo `Fizzygum/`). Each test drives the live world from a macro and
compares canvas screenshots against committed **reference images**. There are **1,842 reference
`.js` files and 1,842 matching `.png` files — 3,684 files**, and they are the most precious artifact
in the repo: the suite's entire verdict rests on them. Read `CLAUDE.md` (this repo) and
`../Fizzygum/CLAUDE.md` before touching anything.

Every reference is SWCanvas (the deterministic software backend). Matching is on a raw-pixel
SHA-256 (`dataHash`), which is what makes references survive lossless PNG recompression.

### The filename grammar today

```
<imageName>-systemInfoHash<sih>-dataHash<sha256>.<js|png>
```
e.g. `SystemTest_macroRoundedBoxCornerClickThrough_image_1-systemInfoHash-1747348995-dataHash65bd35….js`

`<sih>` is `HashCalculator.calculateHash(JSON.stringify(systemInfo))` — a 32-bit Java-style
`String.hashCode` over a JSON blob of ~21 environment fields
(`Automator-and-test-harness-src/SystemTestsReferenceImage.coffee`, the `@fileName = …` line —
grep `"-systemInfoHash"`, do not trust a line number).

The blob is `SystemTestsSystemInfo extends SystemInfo`. It serializes **21** fields (verified by
parsing a committed reference, not by reading the class): `AutomatorVersionMajor`,
`AutomatorVersionMinor`, `AutomatorVersionRelease`, `appCodeName`, `appName`, `appVersion`,
`backend`, `browser`, `browserVersion`, `cookieEnabled`, `cookies`, `mobile`, `os`, `osVersion`,
`platform`, `screenCeilPixelRatio`, `screenColorDepth`, `screenHeight`, `screenPixelRatio`,
`screenWidth`, `userAgent`.

⚠ `SystemInfo` also declares and assigns `systemLanguage`, but it is **structurally absent from the
hash**: `@systemLanguage = navigator.systemLanguage` is a legacy IE-only API that is `undefined` in
Chrome, and `JSON.stringify` omits `undefined`-valued keys. Do not reason about it as a live field.
(This is a second instance of the trap `SystemTestsSystemInfo`'s own header warns about — a value
that never reaches the JSON does not reach the hash.)

### ⭐ THE CRITICAL REFRAME

**The filename encodes the capture machine's DISPLAY, and the display provably cannot change a
reference's pixels.** On the harness page the world canvas is hard-sized:

```coffee
# Automator-and-test-harness-src/WorldTestSupport.coffee — grep `_sizeCanvasToTestScreenResolution`
@worldCanvas.width  = Math.round(960 * ceilPixelRatio)
@worldCanvas.height = Math.round(440 * ceilPixelRatio)
```

960×440 logical, times `ceilPixelRatio`. `window.screen` is never read. Every committed reference is
960×440 at dpr 1. So `screenWidth`/`screenHeight`/`screenColorDepth`/`screenPixelRatio` are pure
noise in the hash — and they are, empirically, the ONLY thing that has ever moved it.

**MEASURED 2026-08-22** (method in §3 — it is reproducible and decisive): the committed set carries
exactly **two** distinct `systemInfoHash` values, and diffing the full `systemInfo` blobs that the
reference `.js` files themselves embed shows **exactly three differing fields out of 21**:

| field | `-1747348995` (3,468 files) | `-1315295150` (216 files) |
|---|---|---|
| `screenWidth` | 1512 | 2560 |
| `screenHeight` | 982 | 1440 |
| `screenColorDepth` | 30 | 24 |

18 fields identical — `userAgent`, `browserVersion`, `os`, everything else. That is **the laptop
display vs an external monitor**, nothing more. Both groups sit under the same
`Chrome/148_0_0_0/SWCanvas/` directory, so the browser did not change between them.

Consequence: **the two values oscillate, they do not drift.** Whichever display is attached when a
recapture runs, that recapture flips the files it touches from one group to the other. It will never
converge. This is why a recapture diff contains renames of files whose pixels are byte-identical.

### Why the grammar is shaped this way

The comment at the `@fileName` assignment states the original intent: *"the same test/step might
have different images for different OSs/browsers, so they all must be different files."* In the
native-canvas era that was true — HTML5Canvas output genuinely forked per OS and browser, and a
hash over the whole environment was a cheap way to keep those variants from colliding in one
directory.

**That era is over.** Native/HTML5 references are retired — not one is left in the tree (see
`CLAUDE.md` § "The reference set (SWCanvas only)"). Every reference is SWCanvas, whose whole purpose
is identical output across OS, browser and engine; the cross-engine check is literally WebKit
reusing Chrome-captured references. The environment hash outlived the variation it was built to
disambiguate.

### What the hash is actually used for now

Exactly one thing: **grouping references that ought to agree on pixels**, so a stray/stale file is
detectable. Two sites:

- `Automator-and-test-harness-src/AutomatorPlayer.coffee` — grep `AMBIGUOUS REFERENCES`. Parses
  `-systemInfoHash-(\d+)-` out of the filename and fails when one group holds >1 distinct
  `dataHash`.
- `scripts/check-refs.js` — grep `DUPLICATE:`. Same rule, offline, over `(test,image,dpr,OS)`.

It is **NOT** used for selection. `AutomatorLoader.loadImagesOfTest` (grep `thisOSMarker`) picks
assets by **pixel ratio and OS** only; the browser directory segment and the filename hash play no
part. This is why WebKit finds Chrome-captured references.

---

## §1 The distilled argument

1. The hash exists to answer *"which references must agree on pixels?"*.
2. Its answer today is dominated by three display fields that provably cannot change a pixel
   (§0 reframe — canvas is a constant × `ceilPixelRatio`).
3. Everything in it that CAN legitimately change pixels — OS, backend, pixel ratio — is **already a
   directory axis** (`Mac-OS-X/10_15_7/Chrome/148_0_0_0/SWCanvas/ceilPixRatio_1/`).
4. So the hash's only *added* information over the directory is the **Automator version** — the one
   deliberate knob that says "the harness changed what it captures".
5. Therefore: drop the hash, name the Automator version in the filename, and group by
   (directory + Automator version). Same guard, no opaque 32-bit number, no environment churn.

**Why now:** the churn is currently paid on every recapture (measured 2026-08-21: of 48 replaced
PNGs in a 7-test recapture, **10 were pure renames with byte-identical pixels**). It also inflates
every reference diff a human or LLM has to review, which is exactly when mistakes get made.

**Why prior consideration stopped short:** `../Fizzygum/docs/archive/census-findings-triage-plan.md`
(grep `hashOfSystemInfo`) records a census that flagged the `SystemInfo.*` fields as write-only and
**declined to act**, on the grounds that *"Demoting those fields would change it and invalidate the
entire committed reference set."* That objection is correct and this plan does not dodge it — it
confronts it: the migration renames all 3,684 files, in staggered batches, with a completeness gate
(§5). Separately, `../Fizzygum/docs/archive/build-arc-1-test-serving-link-plan.md` §7 already
recorded the display-rename phenomenon ("a recapture done on the 'wrong' display renames every file
it touches… worth knowing before a mass recapture") — it named the mechanism but left it standing.

---

## §2 Fix shape

### 2a. New grammar

```
<imageName>-automatorV<M>_<m>_<r>-dataHash<sha256>.<js|png>
```
e.g. `SystemTest_macroRoundedBoxCornerClickThrough_image_1-automatorV0_2_0-dataHash65bd35….js`

Current Automator version is **0.2.0** (`SystemTestsSystemInfo.coffee` constructor).

### 2b. Grouping moves off the filename and onto the record

Each reference `.js` is one line of the form
`if (!AutomatorPlayer.loadedImages.hasOwnProperty('<imageName>')) { … } AutomatorPlayer.loadedImages.<imageName>.push(<record>);`
and the record's shape is **exactly this** (verified 2026-08-22 by parsing a committed reference —
mind the NESTING, it is easy to get wrong):

```
top level (6 keys):  fileName, hashOfData, hashOfSystemInfo, imageData, imageName, systemInfo
systemInfo (21):     AutomatorVersionMajor, AutomatorVersionMinor, AutomatorVersionRelease,
                     appCodeName, appName, appVersion, backend, browser, browserVersion,
                     cookieEnabled, cookies, mobile, os, osVersion, platform,
                     screenCeilPixelRatio, screenColorDepth, screenHeight, screenPixelRatio,
                     screenWidth, userAgent
```

⚠ `AutomatorVersionMajor/Minor/Release` are **inside `systemInfo`**, NOT at the top level — currently
`0 / 2 / 0`. `backend` ("SWCanvas") is in there too.

So `AutomatorPlayer`'s ambiguity check should group by
`record.systemInfo.AutomatorVersionMajor/Minor/Release` — strictly better than a filename regex,
because it stops the runtime depending on filename shape at all.

### 2c. `systemInfo` / `hashOfSystemInfo` in the record

**KEEP both in the record.** They are useful provenance ("what machine produced this?") and cost
nothing once they are out of the filename. Only their role as an identity axis goes away.
⚠ Do NOT delete `SystemInfo`'s fields — the census in §1 explains why they look write-only and
are not.

### 2d. Consolidate the parsers

`scripts/lib/refpaths.js` says of itself: *"ONE place that knows the filename grammar"*. **It is
not** — four sites bypass it (verify each with a fresh grep; line numbers drift):

| site | shape | action |
|---|---|---|
| `scripts/lib/refpaths.js` `parseRefName` | the canonical regex | update grammar; keep as the one parser |
| `scripts/torture-headless.js` | a byte-identical duplicate of that regex | **delete, require `refpaths`** |
| `scripts/make-before-after-comparison.js` | a looser third regex (`_image_(\d+)-systemInfoHash.*?-dataHash…`) | **delete, require `refpaths`** |
| `scripts/capture-macro-test-references.js` | `startsWith(n + '-systemInfoHash')` prefix test | **use `refpaths.parseRefName`** |
| `Automator-and-test-harness-src/AutomatorPlayer.coffee` | in-browser regex | replace with record-field grouping (§2b) — it cannot use a Node lib |

Doing this is a genuine improvement independent of the churn fix, and it is what makes the grammar
change a small edit instead of a scavenger hunt.

### 2e. Tolerate both grammars during the migration

The migration is staggered (§5), so for a while some tests are new-form and some are old-form.
`parseRefName` must accept **both** and report which. **Per-test atomicity is the invariant**: every
reference of a given test converts in the same batch, so no single test is ever mixed. That matters
because `check-refs.js`'s duplicate rule is per `(test,image,dpr,OS)` — a test holding one old-form
and one new-form reference for the SAME image would be two dataHashes in one group and would fail.

Phase 3 removes the old-form branch once nothing on disk uses it.

---

## §3 Reproducing the measurement (do this first — it is the plan's foundation)

Do not take §0's table on trust; it is cheap to re-derive and it is what justifies the whole change.

```bash
cd Fizzygum-tests
# how many distinct systemInfoHash values, and how many files each
git ls-tree -r HEAD --name-only tests/ | grep -oE 'systemInfoHash-?[0-9]+' | sort | uniq -c
```

Then diff the two environments straight out of the references (each `.js` embeds its full
`systemInfo`): pick one `.js` from each hash group, `git show` it, extract the `"systemInfo":{…}`
object, `json.loads` both and diff the keys. Expect exactly `screenWidth`, `screenHeight`,
`screenColorDepth` to differ.

⚠ **Do NOT measure the hash by launching a bare `puppeteer.launch()` probe.** A bare launch may pick
a different Chrome than the capture path uses (observed 2026-08-22: probe reported Chrome 127 while
the reference tree is `Chrome/148_0_0_0`), and `userAgent`/`appVersion`/`browserVersion` all feed the
hash — so such a probe reports a third value that means nothing. The reference `.js` files are the
authoritative record of both capture environments.

---

## §4 Central risks

1. **⛔⛔ THE REFERENCE SET IS THE CROWN JEWELS.** A botched migration silently destroys the only
   ground truth the suite has. Mitigations, all mandatory:
   - The **`dataHash` never changes** — it is a hash of the raw pixels, and this plan does not
     recapture anything. Pixels are preserved by construction; only names and one record field move.
   - `npm run check-refs:pixels` decodes **every** committed reference and re-hashes it against its
     stored `hashOfData`. Run it before starting, after every batch, and at the end. If pixels
     survive, nothing is lost.
   - Work **per test, atomically** (§2e).
   - Every batch is its own commit, so any breakage is bisectable and revertible.
2. **⚠ `git stash` IS BANNED IN BOTH REPOS** (see `CLAUDE.md`) — a `stash pop` once emptied the
   working tree AND the stash list. Use a WIP commit or `git worktree`.
3. **⚠⚠ `Fizzygum-builds/latest/js/tests` is a SYMLINK to `Fizzygum-tests/tests`.** `rm -rf <link>/`
   with a trailing slash deletes the REAL suite. Never aim a recursive delete at that path.
4. **The migration script rewrites `.js` CONTENT, not just names.** ⚠ **CONFIRMED**: the record
   carries a top-level `fileName` holding the FULL old-form name (e.g.
   `SystemTest_…_image_1-systemInfoHash-1747348995-dataHash65bd3568…`). It **must** be rewritten in
   step with the rename, or every record will disagree with the file it lives in. Rewrite by
   extracting the `.push(<record>)` argument, `JSON.parse` → mutate `fileName` → re-emit — **never**
   by regex over the base64 `imageData` payload. Leave `hashOfSystemInfo` and the whole `systemInfo`
   sub-object untouched (§2c: they stay as provenance).
5. **A stale `testsAssetsManifest.js` is impossible but a stale BUILD is not.** The manifests are
   regenerated at every runner's startup. `scripts/lib/tests-manifests.js` selects asset files by the
   presence of `-dataHash` in the name (grep the comment) — the new grammar keeps `-dataHash`, so the
   generator is unaffected. Confirm this rather than assume it.
6. **Do not bundle anything else into this arc.** It is a 3,684-file rename; any unrelated change
   hiding in those commits is unreviewable.

---

## §5 Execution — phases and the staggering

### Phase 0 — baseline (no code changes)
1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — both repos clean, build FRESH.
2. `npm run check-refs:pixels` — must pass over all 1,842 references. **Record the count.**
3. Reproduce §3's measurement.
4. `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` — green before you start. Do not begin
   from a red tree.

### Phase 1 — code: emit the new grammar, accept both (ONE commit)
- `SystemTestsReferenceImage.coffee`: build `fileName` with `-automatorV<M>_<m>_<r>-`.
- `AutomatorPlayer.coffee`: group the ambiguity check by the record's Automator version fields
  (§2b), not a filename regex.
- `scripts/lib/refpaths.js`: `parseRefName` accepts BOTH grammars, returns a discriminator
  (e.g. `{ grammar: 'automatorV' | 'systemInfoHash', … }`).
- The four bypassing parsers (§2d) route through `refpaths`.
- `scripts/check-refs.js`: group by whatever `parseRefName` reports.

**Gate:** `fg build` (runs `check-refs.js` structurally + the test-.js syntax gate), then
`fg gauntlet`. The whole reference set is still OLD-form at this point, so this phase proves the
tolerant path reads the existing tree correctly.
**Then prove the WRITE path:** `fg recapture <one small test>` — it must emit NEW-form filenames,
and the suite must go green with that one test new-form and 308 old-form. That is the mixed state
Phase 2 depends on, proven on one test before doing it 309 times.

### Phase 2 — migrate the references (STAGGERED, N commits)
A script (`scripts/migrate-ref-filenames.js`, new) that takes a list of test directories and, for
each reference: parses the name, rewrites the `.js` record, writes both files under the new name,
deletes the old pair. Idempotent; refuses to touch a test already fully new-form; refuses to leave a
test half-converted.

**Batch size: ~40 tests per commit ⇒ ~8 commits.** Rationale: a 3,684-file single commit is
unreviewable and awkward to push; ~470 files per commit is large but tractable, and each batch is
independently green and bisectable. Batch by alphabetical test-directory order for a reproducible,
resumable sequence.

**Per batch:** run the script → `npm run check-refs:pixels` → `npm test` (the dpr1 suite, ~1 min) →
commit. **Full `fg gauntlet` on the FIRST batch and the LAST batch**; the per-batch dpr1 suite plus
the pixel check is the right cost/benefit for the middle ones. (If any middle batch shows anything
unexpected, stop and gauntlet.)

### Phase 3 — drop the old grammar (ONE commit)
Once `git ls-tree -r HEAD --name-only tests/ | grep -c systemInfoHash` is **0**:
- remove the old-form branch from `refpaths.parseRefName` and anywhere else it leaked;
- `fg gauntlet`.

### Phase 4 — documentation
Update, in the same arc (the repo's standing rule — durable residue lands in the docs in-arc):
- `CLAUDE.md` (this repo) § "Test & reference-image layout" — the grammar block.
- `scripts/README-swcanvas-tests.md` (3 mentions).
- `../Fizzygum/src/macros/CLAUDE.md` and `../Fizzygum/src/macros/MACRO-PATTERNS.md` (3 mentions
  between them) — these say the `systemInfoHash` "is just metadata, NOT used for matching"; that
  sentence becomes wrong in its subject and needs rewording, not deleting.
- `../Fizzygum/buildSystem/census-property-placement.js` — its header comment cites the
  `systemInfoHash` as the reason the `SystemInfo` fields are not demotable. The *conclusion* still
  holds (they are enumeration payload for the record), but the *reason* changes. Fix the reason.
- Add a "BACKLOG ledger" line to `../Fizzygum/docs/BACKLOG.md` § "Pointer hit-test rework 2026-08-21
  — residue", where this item is currently filed, and close it out.

---

## §6 Verification protocol — EVERY FLOW THAT TOUCHES A REFERENCE FILENAME

⚠ The rename is the easy part. **This matrix is the actual work.** Each row is a distinct flow that
produces, parses or resolves a reference filename; a green gauntlet does NOT exercise most of them.
Run every row at the end of Phase 2, and the starred ones after Phase 1 as well.

| # | flow | command | what must be true |
|---|---|---|---|
| 1 ★ | suite load + match | `npm test` | 309/309; references resolve |
| 2 ★ | single test | `node scripts/run-macro-test-headless.js SystemTest_macroRoundedBoxCornerClickThrough` | PASS |
| 3 ★ | cross-engine | `npm run test:webkit` | green on the same references |
| 4 ★ | dpr 2 | `npm test -- --dpr=2` | green |
| 5 ★ | first-time capture | delete one test's refs, `node scripts/capture-macro-test-references.js <name> --dprs=1,2`, then verify | writes NEW-form names; verify green |
| 6 ★ | gated recapture | `fg recapture <name>` | `✅ RECAPTURE COMPLETE`; new-form names; writes its verdict file |
| 7 ★ | capture = REPLACE | `run-macro-test-headless.js --capture-ref` on a test with an existing ref | the stale sibling is deleted, not left beside the new one (`refpaths.siblingRefsToReplace`) |
| 8 ★ | check-refs structural | `fg build` | no DUPLICATE / orphan |
| 9 ★ | check-refs pixels | `npm run check-refs:pixels` | all 1,842 verified |
| 10 | manifest generation | any runner startup, or `npm run manifests` | asset manifest lists every reference |
| 11 | visualisation | `node scripts/make-visualisation.js SystemTest_<name>` | the `<img src>` paths resolve to files that exist |
| 12 | diff page | `fg diffpage <a failing test>` | pairs live renders against committed refs |
| 13 | before/after comparison | `node scripts/make-before-after-comparison.js …` | parses the new grammar |
| 14 | torture evidence re-catch | `node scripts/torture-headless.js --minutes=2` | its `parseRefName` path works |
| 15 | reset refs | `node scripts/reset-test-refs.js <name>` (on a scratch branch) | lists/removes correctly |
| 16 | recompress | `node scripts/recompress-swcanvas-references.js --check-only` | verifies; ⚠ it must still NOT rename (raw-pixel `dataHash` invariance is the point) |
| 17 | failure zip | force a failure, `world.automator.player.saveFailedScreenshots()` in the browser | names are new-form |
| 18 | selftests | `npm run selftest` | green (pins the PNG decoder + `rawPixelHash` layout) |
| 19 | full gate | `fg gauntlet` | 18/18 |

⚠ Rows 5, 6, 7 and 17 are the **write** paths — they are the ones a green suite cannot vouch for,
and the ones most likely to be missed.

---

## §7 Cold-execution protocol

1. Read §0 and §1 in full. If the §3 measurement no longer reproduces (e.g. a third
   `systemInfoHash` value has appeared, or the differing fields are not the three display ones),
   **STOP** and re-derive — the plan's justification is that measurement.
2. Run Phase 0. Do not proceed from a red tree.
3. Phase 1 in one commit, gated as written, including the write-path proof on one test.
4. Phase 2 batch by batch. **After each batch: pixel check + dpr1 suite + commit.** Never leave the
   tree half-migrated across a session boundary without committing the completed batches.
5. Phase 3, Phase 4.
6. Run the whole §6 matrix. Report which rows you actually ran — do not claim a row you skipped.
7. Ask before pushing (owner's standing preference: never commit or push autonomously; present the
   summary and the message and wait).

**Long-op discipline** (see `../Fizzygum/CLAUDE.md`): launch `fg gauntlet` / `fg suite` ONCE with
the Bash tool's `run_in_background: true`, redirect to a log, and wait for the task notification.
Do NOT hand-roll foreground `sleep`/`until` pollers — a PreToolUse hook blocks them. Peek at
`/tmp/fg-<cmd>.verdict` at a ~5-minute cadence at most.

---

## §8 Rejected alternatives (do-not-re-attempt)

- **(a) Leave it.** Livable, and it is what has happened so far. Rejected because the churn is paid
  on every recapture forever and it oscillates rather than converging — the two groups swap
  whenever the display changes.
- **(b) Normalise every filename to ONE of the two existing hashes.** Rejected: it is the same
  3,684-file migration cost as this plan and buys only temporary tidiness — the very next recapture
  on the other display starts the split again. It fixes the symptom and leaves the mechanism.
- **(c) Keep the hash but narrow it** (drop the three display fields, or all `screen*`). Genuinely
  better than (b), and a reasonable fallback if §2's grouping change proves harder than expected.
  Rejected as the primary because it has **identical migration cost** — narrowing changes the hash
  value for all 3,684 files anyway — while leaving an opaque 32-bit number in the filename that will
  silently absorb whatever `SystemInfo` gains next. Same price, strictly less benefit.
- **Demoting/deleting the `SystemInfo` fields themselves.** Already considered and correctly
  declined by the census (§1). They are `JSON.stringify` enumeration payload, not dead code. This
  plan keeps them in the record and only removes their role as a filename axis.

---

## §9 References

- `CLAUDE.md` (this repo) — reference-set layout, the SWCanvas-only rule, the manifest contract.
- `DETERMINISM.md` — why the suite is byte-exact; read before touching capture/compare paths.
- `../Fizzygum/docs/archive/build-arc-1-test-serving-link-plan.md` §7 — the display-rename
  phenomenon, recorded but left standing.
- `../Fizzygum/docs/archive/census-findings-triage-plan.md` — why the `SystemInfo` fields look
  write-only and must not be demoted.
- `../Fizzygum/docs/BACKLOG.md` § "Pointer hit-test rework 2026-08-21 — residue" — where this item
  is currently filed.
- `scripts/README-swcanvas-tests.md` — reference regeneration/maintenance procedure.

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] **Reference filenames no longer encode the capture machine's environment** — DONE. The
      `-systemInfoHash<h>-` token (a 32-bit hash of ~21 environment fields) is replaced by
      `-automatorV<M>_<m>_<r>-` across all 3,684 committed reference files. The hash's only movers were
      `screenWidth`/`screenHeight`/`screenColorDepth` — the capture machine's DISPLAY, which cannot
      change a reference's pixels (the harness canvas is a constant 960×440 × `ceilPixelRatio` and never
      reads `window.screen`), so it OSCILLATED between two values as recaptures ran on laptop vs external
      monitor and renamed byte-identical files forever. Grouping now reads the Automator version off the
      RECORD (`AutomatorPlayer`) rather than off the filename, and `scripts/lib/refpaths.js` is the sole
      parser — four bypassing regexes were routed through it. Doctrine: `Fizzygum-tests/CLAUDE.md`
      § "Test & reference-image layout".
      (Section "Pointer hit-test rework 2026-08-21 — residue", in Fizzygum's `docs/BACKLOG.md`.)
