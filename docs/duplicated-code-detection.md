# Duplicated-code detection (`./find_duplicated_code.sh`)

One command, run from the `Fizzygum/` repo root (or via its absolute path — it cd's itself):

```sh
./find_duplicated_code.sh
```

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

## Feeding the results to an LLM

- `jscpd-report.ai.txt` — the cheap, token-efficient starting point (~1 line per clone pair
  + summary). Good for "cluster these, rank by refactoring value, propose extractions".
- `duplication-report/jscpd-report.json` — adds the actual duplicated code fragments and
  token counts per clone, for when the LLM should judge content without opening files.
- `duplication-report/html/index.html` — for humans.

Suggested prompt shape: paste `jscpd-report.ai.txt`, ask for (1) clustering into families
(many pairs share one underlying template, e.g. the `info-widgets/*InfoWdgt` 25–36 block),
(2) a ranked shortlist of extract-method/extract-base-class refactors with effort/risk,
(3) explicit "leave alone" calls for coincidental or ctor-boilerplate matches. Remind it of
repo rules: one class per file, `Mixin` system available, no imports (globals), and that
behaviour changes must pass `fg presuite` / the SystemTest suite.
