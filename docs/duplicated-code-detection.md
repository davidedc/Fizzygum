# Duplicated-code detection (`./find_duplicated_code.sh` + `./find_similar_code.sh`)

Two complementary scanners, run from the `Fizzygum/` repo root (or via absolute path — both cd themselves):

```sh
./find_duplicated_code.sh   # EXACT copy/paste clones (jscpd, token-based)   — .coffee line numbers
./find_similar_code.sh      # SIMILAR/structural clones (jsinspect, AST)     — compiled-JS line numbers
```

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
