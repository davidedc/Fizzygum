# Duplicated-code detection (`./find_duplicated_code.sh` + `./find_similar_code.sh`)

Two complementary scanners over two surfaces, run from the `Fizzygum/` repo root (or via
absolute path — both cd themselves). A third, hierarchy-aware axis was added in 2026-07 — see
the box under the table:

```sh
./find_duplicated_code.sh           # EXACT copy/paste clones (jscpd, token-based) — .coffee lines
./find_similar_code.sh              # SIMILAR/structural clones (jsinspect, AST)   — compiled-JS lines
./find_duplicated_code.sh --tests   # same, over the sibling Fizzygum-tests repo (harness + scripts)
./find_similar_code.sh --tests      # same; node scripts are scanned DIRECTLY (real line numbers)
```

The full recurring workflow (scan → triage ledger → LLM session → land → rescan) is the
["re-audit / re-triage cycle" section](#the-recurring-re-audit--re-triage-cycle) below.

**A THIRD axis, added 2026-07-15 — hierarchy-aware duplication:**

```sh
node ./buildSystem/census-hierarchy-duplication.js   # overrides that add NOTHING (~0.4 s, advisory)
node ./buildSystem/census-property-placement.js      # fields at the wrong level/scope (~0.6 s, advisory)
```

Both scanners above are **blind to inheritance**: jscpd matches exact token runs and jsinspect matches
AST shapes, so neither can ever say *"this override is REMOVABLE"* — an override and the parent method
it duplicates are not textual twins sitting in one file. The censuses close exactly that gap
(`IDENTICAL-TO-INHERITED` / `SHADOWS-MIXIN` / `JUST-SENDS-SUPER`; `PULL-UP` / `DEMOTE`). They are
seconds-fast, so unlike jscpd/jsinspect they also run inside **`fg critique`**. They feed the SAME
ledger (`duplication-report/triage-report.md`, ROUND 4 / 4b) and follow the same cycle below.
⚠ Their findings are CANDIDATES, never proofs — `super` is meta-compiled and property access is partly
dynamic. Details + the soundness rules: `docs/lint-and-static-checks.md` §3c.

Run both: they see different things. The exact scan misses a clone the moment one identifier
is renamed — or when an interleaved comment breaks the token run, or when CoffeeScript's
terseness keeps a whole duplicated method under the token window. The structural scan
(section below) catches those; on 2026-07-14 it found 125 matches the exact scan was blind to
(verified example: `SimpleVerticalStackPanelWdgt`'s `add`/`_addNoSettle` ≈ `ToolPanelWdgt`'s).

Scans `src/**/*.coffee` for copy/paste duplication with [jscpd](https://github.com/kucherenko/jscpd)
(pinned devDependency — `npm install` once) and writes reports to `duplication-report/`
(gitignored). ~1.5 s per pass for the whole framework. The intended product is the
**LLM handoff file** `duplication-report/jscpd-report.ai.txt` — a compact
`fileA:x-y ~ fileB:x-y` clone-pair list to paste to an LLM for triage and actioning.

## History: why this exists, and what it replaces

An Oct-2019 experiment found duplicates with **jsinspect**, via a painful manual pipeline:
copy all `.coffee` files out of `src/` by hand (Total Commander), batch-compile with
`coffee -b -c`, *delete the mixins whose `super` broke bare compilation*, run
`jsinspect > jsinspect_results.txt`, then hand-strip the compiled-JS preambles from the
output. Findings pointed at throwaway generated JS, not at editable source.

That pipeline is obsolete on every axis:

- **jsinspect is abandoned** (last release 2017; chokes on modern JS, unmaintained AST parser).
- **jscpd tokenizes CoffeeScript natively** (`coffeescript` is one of its ~220 auto-detected
  formats), so there is **no compile step at all** — no file copying, no broken-mixin
  pruning, no preamble cleanup, and every finding is a real `src/**.coffee` line range.
- jscpd is the current de-facto standard (bundled in super-linter/Mega-Linter, ~1M weekly
  npm downloads, actively maintained).

Alternatives surveyed (2026-07) and why not: **PMD CPD** — Java dependency, no CoffeeScript;
**SonarQube** — needs a server; **jscpd v5** — a ground-up Rust rewrite (`cpd` binary,
drop-in CLI-compatible, 24-37× faster) — pointless here since v4 already does the full scan
in ~1.5 s, and v4 stays on the same Node toolchain as the rest of the repo (`coffeescript`,
`terser` devDeps). If the codebase ever grows 100×, switch the devDependency to `jscpd@5`.

## Configuration

Defaults live in [`.jscpd.json`](../.jscpd.json) (repo root); any CLI flag forwarded by the
script overrides them (e.g. `./find_duplicated_code.sh --min-tokens 35`).

| Key | Value | Why |
| --- | --- | --- |
| `path` / `format` | `src` / `coffeescript` | never point it at `Fizzygum-builds/` (1.3 GB) |
| `minTokens` | 50 | jscpd default; the reporting sweet spot, see curve below |
| `minLines` | 5 | jscpd default |
| `maxLines` / `maxSize` | 20000 / 2mb | **load-bearing — see gotcha #1** |
| `reporters` | console, json, markdown, html | plus a 2nd `ai`-reporter pass in the script |
| `output` | `duplication-report/` | gitignored |

### Threshold tuning (measured 2026-07-14, 484 files / ~55k lines)

| `--min-tokens` | exact clones | duplicated lines |
| --- | --- | --- |
| 35 | 231 | 5.8 % |
| 40 | 177 | 4.9 % |
| **50 (default)** | **104** | **3.4 %** |
| 70 | 56 | 2.1 % |
| 100 | 29 | 1.3 % |

## Gotchas

1. **jscpd SILENTLY skips files over `maxLines`/`maxSize`** (defaults: 1000 lines / 100 KB).
   With the defaults that excluded the seven biggest files — `Widget.coffee` (4922 lines!),
   `WorldWdgt.coffee`, `LCLCodePreprocessor.coffee`, `MacroToolkit.coffee`, `StringWdgt.coffee`,
   `ActivePointerWdgt.coffee`, `SimpleUSAMapIconAppearance.coffee` — i.e. exactly where
   duplication hides. `.jscpd.json` raises the caps to 20000 / 2mb; if a source file ever
   outgrows those, raise them again. **Coverage audit:** "Files analyzed" in
   `duplication-report/jscpd-report.md` should equal `find src -name '*.coffee' | wc -l`
   minus the handful of stub files shorter than `minLines` (2026-07: 478 analyzed = 484 − 6
   stubs of 1–3 lines, which cannot contain a 5-line clone anyway).
2. **A `regex` row appears in the summary table** next to `coffeescript`: the tokenizer
   attributes regex-literal tokens inside a few `.coffee` files to a nested `regex` format.
   Harmless; the files are still scanned as CoffeeScript.
3. **Exact-token clones only.** jscpd matches token sequences (whitespace/formatting
   insensitive), so a copy where identifiers were *renamed* will only match up to the first
   renamed token — unlike 2019-jsinspect's AST-structural matching. In practice the
   neighborhoods of exact hits are where the renamed variants live; tell the triaging LLM to
   read the whole containing methods, not just the reported ranges. (If real Type-2/3
   structural detection is ever wanted: `mizchi/similarity` is the modern AST-similarity
   tool, TS/JS only — it would need the compiled-JS route again.)
4. The `ai` reporter writes to **stdout only**, so the script runs a second, silent pass to
   capture it into `jscpd-report.ai.txt` (jscpd does not wipe the output dir between runs;
   ANSI codes and the trailing timing/sponsor banner are stripped).
5. **jsinspect's CLI hard-codes ignoring any path matching `node_modules|bower_components|
   test|spec`** — its `--ignore` only APPENDS patterns. "Fizzygum-tests", ".../tests/...",
   and even "Inspector" (In-**spec**-tor, lowercase substring match) all trip it: the two
   `meta/*Inspector*` files were silently missing from every directory-based structural scan
   until 2026-07-14. Explicit FILE arguments bypass the filter, so `find_similar_code.sh`
   always expands the file lists itself — **never call the jsinspect bin with a directory
   argument.**
6. **jscpd's `--ignore` globs cannot exclude dot-directories** (`**/.scratch/**` silently
   matches nothing; `--gitignore` doesn't catch it either from a sibling cwd). The `--tests`
   mode therefore greps `.scratch` pairs out of the ai handoff file; the json/console output
   still contains them.

## Structural similarity: `./find_similar_code.sh` (Type-2 / renamed clones)

jscpd cannot see "similar" code, only exact token runs. For structural matching the modern
tool would be `similarity-ts` (mizchi/similarity, Rust, APTED tree-edit distance) — but its
v0.5.0 prebuilt macOS binary is **broken** (finds nothing even on byte-identical functions;
sanity-tested 2026-07-14; re-check future releases). What *does* work — nicely — is
**jsinspect 0.12.7, the very tool of the 2019 experiment**, on a compiled-ES5 mirror:

1. `buildSystem/coffee-to-js-mirror.js` compiles all of `src/` with **CoffeeScript 1**
   (devDependency alias `coffeescript-v1`): CS 2.7 rejects ~106 files over bare-`super`
   idioms that the bundled in-browser compiler accepts; CS1 fails only the 6 `super`-bearing
   mixins, rescued by a textual `super`→`__SUPER__` shim (AST shape is all that matters
   here). 484/484 compile. It also strips the byte-identical compiler-preamble helpers —
   without that, the top "duplicate" is the preamble, ×394 (the 2019 note's manual-cleanup
   step, now automated).
   ⚠ Never invoke CS1 via `node_modules/.bin/coffee` or the alias package's `bin/coffee`:
   CS1's stock bin silently *prefers* a locally-installed `node_modules/coffeescript` (the
   2.7.0 devDep). The mirror script uses the compiler API to bypass it.
2. jsinspect matches AST **node types** (identifier-insensitive by default, threshold =
   `-t` nodes, default 30) over the mirror. Exit code 5 means "matches found" — its CI-gate
   convention, not an error.
3. `buildSystem/jsinspect-compact-report.js` condenses the JSON into
   `jsinspect-report.ai.txt`, mapping mirror names back to `src/**/*.coffee` and recovering
   `@method` names from `X.prototype.method` assignments.

**The one caveat: line numbers are compiled-JS mirror lines (`jsL…`), not `.coffee` lines.**
Locate findings by file (one class per file) + `@method` name. Baseline 2026-07-14 (post
opener-batch dedup): **133 structural matches** at `-t 30`, including families invisible to
jscpd — a 25× icon `paintFunction` wrapper, an 18× `stringSetters`/`numericalSetters`/
`colorSetters` boilerplate family, `Widget`-internal `setPadding*` quintuplets.

## The recurring re-audit / re-triage cycle

The scanners are step one of a repeatable campaign loop (first campaign: 2026-07, rounds 1–3,
EXACT clones 104 → 45, duplicated lines 3.4% → ~1.4%). The loop:

1. **Scan all four**: `./find_duplicated_code.sh`, `./find_similar_code.sh`, and both with
   `--tests`. Each writes a token-efficient `*.ai.txt` handoff list (src →
   `duplication-report/`, tests → `duplication-report/tests/`).
   **Plus the two hierarchy-aware censuses** (`census-hierarchy-duplication.js`,
   `census-property-placement.js` — seconds, `--json`), which cover the axis the two clone
   scanners are blind to. They are also in `fg critique`, so their counts surface without a
   scan round.
2. **Reconcile the ledger** — `duplication-report/triage-report.md`. This is the campaign's
   persistent memory: ranked refactor items with win/risk/effort, per-round ✅ PUSHED history
   with commit SHAs, the LEAVE-ALONE list *with reasons*, and hard-won case law (layering
   rules, inspector-churn handling, ctor-build rule, deliberate seams). New scan results get
   triaged INTO it; done/dropped items get marked; it is updated in place, append-friendly.
3. **Owner decides** anything the ledger flags as owner-call (deletions, non-pixel work,
   borderline families, new surfaces).
4. **Regenerate the starting prompt** — `duplication-report/llm-triage-prompt.md` — for a
   fresh LLM session with no context. It must be fully self-contained: the two-phase contract
   (Phase 1 = triage/plan then STOP; Phase 2 = implement one item at a time, only after
   approval), the owner decisions, the codebase hard rules and the pixel bar, the
   verification loop (`fg presuite` per item, `fg gauntlet` to close; background, never
   foreground-poll), pointers to the ledger, ALL fresh `*.ai.txt` lists embedded verbatim,
   the regeneration commands, and the current baselines so the session can log the trend.
   The current file is the template — reuse its structure.
5. **Run the session**; after each landed batch it rescans and logs the count trend.

**Artifact lifecycle — read this before `git clean`:** everything under `duplication-report/`
is gitignored. The scan reports are disposable (one command away). **`triage-report.md` and
`llm-triage-prompt.md` are NOT** — they are the campaign's accumulated judgment, and an
untracked file is one `git clean -fdx` from oblivion. Convention: when a campaign arc closes,
snapshot the ledger to `docs/done/duplication-triage-<date>.md` and commit it; the LEAVE-ALONE
list and case law are what future rounds must not re-litigate.

Baseline history (per-scan totals, for trend context):

| Date · commit | src exact | src structural | tests exact | tests structural |
| --- | --- | --- | --- | --- |
| 2026-07-14 · campaign start | 104 | 133 | — | — |
| 2026-07-14 · `62fa50f0` (round 1 landed) | 82 | 133 | — | — |
| 2026-07-14 · `0b51b0c8` (round 2 landed) | 49 | 118* | 29* | 28* |
| 2026-07-14 · `fc0aef7c` (round 3 items 1–2) | 45 | 113 | 24 | 24 |

Round 4 (2026-07-15) opened a THIRD axis rather than moving those columns — hierarchy-aware, so its
counts are additive, not comparable to the exact/structural ones:

| Date · commit | IDENTICAL-TO-INHERITED | SHADOWS-MIXIN | JUST-SENDS-SUPER | PULL-UP | DEMOTE |
| --- | --- | --- | --- | --- | --- |
| 2026-07-15 · `2dbf123d` (censuses born) | 10 | 0 | 0 | 10 (7 same-default) | 37 (+49 withheld) |
| 2026-07-15 · `83209869` (tranche A+B landed) | **4** | 0 | 0 | 10 (7 same-default) | 36 (+49 withheld) |
| 2026-07-15 · `3d038959` (tranche C landed) | **1** | 0 | 0 | 10 (7 same-default) | 36 (+49 withheld) |
| 2026-07-15 · Phase 0 (write-only DEMOTE bug FIXED) | 1 | 0 | 0 | 10 (7 same-default) | **20** (+3 withheld ·name, +62 write-only) |
| 2026-07-15 · Phase 3 (13 DEMOTEs actioned) | 1 | 0 | 0 | **10 — CLOSED, zero actionable** | **7** (+3, +62) |

⚠ The Phase 0 row is a **tooling** fix, not a code change: `census-property-placement.js`'s DEMOTE rule never required
the property to be READ, so 16 of the 36 were write-only false positives — 12 of them `SystemInfo` fields that ARE the
reference-image identity. See case law 10. It also re-attributed the withheld bucket: the `.name` veto's real cost is
**3**, not 49. Counts here are only comparable within a row's own tooling version.

⚠⚠ **PULL-UP is CLOSED at 10 and will stay there — all 10 were triaged 2026-07-15 and NONE is actionable** (case law
11/12; `docs/census-findings-triage-plan.md` Phase 2). It is not a debt, and re-triaging it is wasted work. Its own
strongest finding — 3 verbatim-identical colour defaults — would have turned the desktop icons near-white, because each
subclass `@augmentWith`es a mixin that injects the same properties onto the SUBCLASS prototype. **A non-zero census
count is not automatically a backlog.**

**Scoreboard for the hierarchy axis (2026-07-15, arc complete):** 23 findings actioned across all tranches
(9 no-op overrides + 1 field in A/B/C, 13 fields in Phase 3) against **26 triaged-and-correctly-rejected**
(16 write-only, 10 pull-up). The rejection rate is the point, not a failure: these censuses are heuristic by
construction and can never be gates (`docs/lint-and-static-checks.md` §3b).

Closed-arc snapshot with the full case law (the removability test, the inspector-churn finding, the
`super`-chaining trap, the four census exclusions, the write-only/enumeration rule):
[`docs/done/duplication-triage-2026-07-15-hierarchy-round4.md`](done/duplication-triage-2026-07-15-hierarchy-round4.md).

\* pre-fix numbers: structural scans before `fc0aef7c`-era tooling silently excluded the two
`Inspector*` files (gotcha 5 below), and the first tests scans were ad-hoc CLI runs.

## Feeding the results to an LLM

- `jscpd-report.ai.txt` — the cheap, token-efficient starting point (~1 line per clone pair
  + summary). Good for "cluster these, rank by refactoring value, propose extractions".
- `jsinspect-report.ai.txt` — same idea for the structural matches (remind the LLM that
  `jsL` ranges are compiled-JS lines; navigate by file + `@method`).
- `duplication-report/jscpd-report.json` — adds the actual duplicated code fragments and
  token counts per clone, for when the LLM should judge content without opening files.
- `duplication-report/html/index.html` — for humans.

Suggested prompt shape: paste `jscpd-report.ai.txt`, ask for (1) clustering into families
(many pairs share one underlying template, e.g. the `info-widgets/*InfoWdgt` 25–36 block),
(2) a ranked shortlist of extract-method/extract-base-class refactors with effort/risk,
(3) explicit "leave alone" calls for coincidental or ctor-boilerplate matches. Remind it of
repo rules: one class per file, `Mixin` system available, no imports (globals), and that
behaviour changes must pass `fg presuite` / the SystemTest suite.
