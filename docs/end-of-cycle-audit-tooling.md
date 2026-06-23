# End-of-cycle layout-flush audit tooling — how to use it

**The single source of truth for the audit harness.** Every end-of-cycle doc links here instead of repeating run
instructions. The tooling measures **what reaches the per-frame end-of-cycle layout flush** (the queue
`world.widgetsThatMaybeChangedLayout` drained once/frame at `WorldWdgt.doOneCycle → recalculateLayouts`), attributes
each origin to the action that caused it, and rolls it up by action — so you can see which deferred mutations
*should* self-settle. Background on the engine itself: `end-of-cycle-flush-inventory.md`.

## Where it lives (committed, reusable)

`Fizzygum-tests/scripts/end-of-cycle-audit/` (tracked):
- **`layout-audit-prelude.js`** — a behaviour-neutral runtime prelude injected via `run-macro-test-headless.js`'s
  `PRELUDE_JS` hook. It rAF-polls until `Widget`/`WorldWdgt`/`world` exist, then patches prototypes to log one
  `LAYOUTAUDIT <json>` line per **ORIGIN** survivor at the end-of-cycle flush. **Inspector-invisible** (audit state
  in a `WeakMap` off the widgets; a closure tag, not a window global) and **proven pixel-neutral** (the instrumented
  suite stays 165/165). Isolates the end-of-cycle flush via `!world._inLayoutMutation` at `recalculateLayouts` entry
  (the two self-settling callers set that flag first; `doOneCycle` doesn't). Distinguishes ORIGIN from climbed
  ancestor via an `invalidateLayout` re-entrancy depth counter.
- **`audit-one.sh`** — one test headless at dpr1 with the prelude + `LOG_FILE`; emits `PASS/FAIL inst=YES/NO recs=N`.
- **`run-audit-loop.sh`** — all 165 tests **SERIALLY** (`bash run-audit-loop.sh 1` — parallel cold Chrome launches
  overwhelm the box). ~25 min. Logs to the gitignored `scripts/.scratch/audit/`.
- **`aggregate-layout-audit.js`** — parses the logs → `_SUMMARY.{md,json}` (a **by-action** rollup + per-test +
  headline interaction-frame count). Pass the audit dir as arg 1.

## Run it (regenerate the inventory)

From `Fizzygum-tests/`:
```sh
/Users/davidedellacasa/code/Fizzygum-all/fg build                    # fresh build (runners refuse a stale one)
# (optional) snapshot the current inventory as the BEFORE baseline to diff against:
node scripts/end-of-cycle-audit/aggregate-layout-audit.js scripts/.scratch/audit/ 2>/dev/null \
  && cp scripts/.scratch/audit/_SUMMARY.json scripts/.scratch/audit/_SUMMARY_baseline.json
bash scripts/end-of-cycle-audit/run-audit-loop.sh 1                  # ~25 min, SERIAL
node scripts/end-of-cycle-audit/aggregate-layout-audit.js scripts/.scratch/audit/   # -> _SUMMARY.{md,json}
```

**Neutrality check (mandatory):** the loop's tally must be `165 PASS inst=YES`, `0 inst=NO`. Anything else means the
prelude perturbed something — fix before trusting the data.

**Before→after diff** (paste-ready):
```sh
node -e 'const b=require("./scripts/.scratch/audit/_SUMMARY_baseline.json"),a=require("./scripts/.scratch/audit/_SUMMARY.json");
const roll=s=>{const m={};for(const g of s.groups){const k=g.tag||(/playQueued|Set.forEach/.test(g.sig||"")?"(untagged)hover":/fullPaint/.test(g.sig||"")?"(untagged)paint":g.sig?"(untagged)other":"?");m[k]=(m[k]||0)+g.interaction;}return m;};
const mb=roll(b),ma=roll(a);console.log("records:",b.totalInteractionOrigins,"->",a.totalInteractionOrigins,"| frames:",b.interactionFrames,"->",a.interactionFrames);
[...new Set([...Object.keys(mb),...Object.keys(ma)])].sort((x,y)=>(mb[y]||0)-(mb[x]||0)).forEach(k=>{const x=mb[k]||0,y=ma[k]||0;if(x||y)console.log(String(x).padStart(4),"->",String(y).padStart(4)," ",k);});'
```

## Attributing a new contributor

The origin's `(ctor, spec)` names *which* widget reached end-of-cycle; the **tag** names the *action*. To attribute
a newly-suspected method, add it to the prelude's `tagClass(...)` block (section `(d)` of
`layout-audit-prelude.js`), rebuild, and re-run. Untagged origins fall back to `(ctor, sig)`.

## Reference numbers (the campaign so far)

- **Baseline survey: 1244 interaction records** across 69 origin groups, 735 non-empty frames.
- **After the `Widget.destroy` freefloating-skip + chrome-label self-settle: 564 records (−55%)** — `Widget.destroy`
  505 → 16. See `end-of-cycle-flush-inventory.md` §5b and `end-of-cycle-self-settle-conversion-plan.md`.

## Output / housekeeping

The audit OUTPUT (`*.log`, `_SUMMARY*`, `_progress.log`) goes to `Fizzygum-tests/scripts/.scratch/audit/`, which is
**gitignored** (throwaway). Only the four tool files under `scripts/end-of-cycle-audit/` are committed. To re-baseline,
re-run and `cp _SUMMARY.json _SUMMARY_baseline.json`.
