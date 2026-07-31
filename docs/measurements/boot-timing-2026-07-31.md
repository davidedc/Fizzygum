# Boot timing — where the time actually goes, per boot path

**Question it answers:** *would making more of the desktop's apps LAZY make Fizzygum boot faster?*
Asked 2026-07-31 while triaging a list of candidates (Draw, Docs Maker, Generic Panel, Super
toolbar, Patch programming, the Examples documents).

**Short answer: it depends entirely on WHICH page, and the two differ by 60×.** For the shipped
production artifact there is nothing left to win. For the `dev` `index.html` that a developer
actually opens all day there is — but a far bigger lever sits next to it (§"The other lever").

> ⚠ **A first version of this document concluded "no, boot speed is not a reason" full stop.** That
> was wrong, and the way it was wrong is worth keeping: it measured production (54 ms), declared the
> lever spent, and dismissed the 3.2 s compile-at-boot number as affecting only "a developer opening
> a dev index.html by hand" — which is the primary daily experience of the person who asked. Measure
> the artifact the QUESTIONER uses, not the one that is easiest to argue about.

**Method.** `Fizzygum-tests/.scratch/boot-timing-probe.js` (gitignored), headless Chrome over
`file://`, cache disabled, 5 runs per tree, medians reported. The marker is **time to world-ready**
(`world && worldRenderCanvas && worldCanvas && worldCanvasContext` — the same condition
`smoke-boot-headless.js` uses). ⚠ That marker is exact for this question on the compile-at-boot
path: `createWorldAndStartStepping()` runs at the END of the ingest chain, so a world existing means
every eager source has been fetched, compiled AND executed.

⚠ **These are CPU numbers, not network numbers** — `file://` on local disk. A real visitor still
downloads the image, which is where the byte savings from lazy parts genuinely land.

## The measurement

| | `dev` — compile-at-boot | `homepage` — precompiled, `sources: lazy` |
|---|---:|---:|
| **world ready** | **3219 ms** | **54 ms** |
| last `.js` source arrived at | 103 ms | image at 8 ms |
| ⇒ remaining = compile + execute | **3116 ms (97%)** | ~46 ms |
| sources in the vault at ready | 452 | 0 (nothing fetched) |
| `*Wdgt` globals defined | 227 | 210 |

Run-to-run spread was small on both (dev 3176–3237 ms; production 52–64 ms).

### How much can LAZINESS win on the dev page? — the floor, measured

Every non-core part flipped to `"eager": false` in `parts.json` (a timing-only change: no code moved,
no doors added — several icons simply do nothing on that build, which is fine for a measurement):

| dev `index.html` | sources compiled | world ready |
|---|---:|---:|
| as shipped | 452 | 3219 ms |
| **every non-core part lazy — the FLOOR** | 389 | **2680 ms** |

⇒ the entire current partition, made maximally lazy, is worth **539 ms (17%)** — a marginal
**~8.6 ms per source**. **Core alone is 389 sources and 2.68 s, and core cannot be lazy by
definition.** So the ceiling on this lever is set by how much can be moved OUT of core, and the
app-slice candidates under discussion (the GenericPanel/Document family + `samples`, ~13 sources)
are worth roughly **110 ms — 3%**.

### What the three extraction slices actually delivered (measured after each landed)

| after | sources in the vault at boot | dev `index.html` ready |
|---|---:|---:|
| the measurement above | 452 | 3219 ms |
| slice 1 — 25 icons re-homed | 452 | 3219 ms *(re-homing alone moves nothing)* |
| slice 2 — `demos` made lazy | 422 | 2931 ms |
| slice 3 — `authoring` extracted | **368** | **2711 ms** |

⚠ **`~8.6 ms per source` is an AVERAGE and over-predicts a slice of small classes.** Slice 3 took 54
sources out of the boot compile and the flat rate predicted −464 ms; the measured saving was
**−220 ms**, i.e. ~4.1 ms per source — **2× optimistic**. Compile cost tracks a source's SIZE, and
buttons and icon appearances are far below the tree's mean. Use the flat rate to rank candidates,
never to promise a number.

## The other lever: build the DEV tree pre-compiled (55×, and it keeps every class)

Spiked 2026-07-31 as a scratch profile — same `parts: all`, same three entry pages, the only change
being `form: "precompiled"` (+ the `sources` policy that then becomes required):

| | build | boot |
|---|---:|---:|
| `dev` (compile-at-boot) | 12.2 s | 3219 ms |
| `dev-precompiled` spike | 17.5 s | **59 ms** |

**+5.3 s per build against −3.16 s per page load: break-even under two reloads per build**, and
nothing is given up — all 227 `*Wdgt` classes are present, every part ships. Arc 5 (PR-D5) declined
a pre-compiled `dev` on the ground that it "would add a headless boot-and-harvest to every ~18 s
build"; that cost is real and now measured at +5.3 s, against a saving that was never measured.

⚠ **SPIKE, NOT A RECOMMENDATION YET.** Two things are unverified: the SystemTest suite has never run
against a PRE-COMPILED `worldWithSystemTestHarness.html`, and the boot smoke on the spike reported
`loading "fizzytiles" pulled 8 EAGER batch(es)` — believed to be a false positive of the looped
lazy-part assertion on a `precompiled + sources: "background"` tree (the background layer load
fetches core's batches concurrently and the counter attributes them to the part load). Production is
`precompiled + lazy`, where nothing fetches in the background, so the gate is correct there. A real
`dev-precompiled` should use `sources: "lazy"`, or the gate must discount concurrent background
fetches. **Neither has been proven; do not adopt on the strength of this table alone.**

⚠⚠ **THE TWO LEVERS INTERACT, and the order matters.** A pre-compiled dev tree boots in 59 ms, which
REMOVES the dev-boot argument for aggressive laziness entirely — 17% of 3.2 s is worth chasing, 17%
of 59 ms is not. If `dev-precompiled` is adopted, laziness must then justify itself on its other two
grounds (production DOWNLOAD bytes, and partition UNIFORMITY), which are real but different
arguments. Decide the profile question first, or knowingly accept that it may retire the motivation
for the other.

## What it means

1. **On the compile-at-boot path, boot time is class count.** 97% of it is compiling; fetching all
   22 source files takes 103 ms of the 3.2 s. Marginal cost measured at **~8.6 ms per source**, so
   removing a class from the eager set removes roughly that much — but see the 389-source core floor
   above for the ceiling.
2. **On the production path there is nothing left to win.** The whole image parse+execute is ~46 ms.
   A candidate slice worth ~14 KB of code against a 956 KB image is ~1.6% of it — call it **half a
   millisecond**. Even the `spreadsheet` extraction, which took a measured 3.4% off the image, is
   worth ~1.5 ms here: below the run-to-run noise.
3. **The SUITE cannot benefit from laziness at all, by construction.**
   `worldWithSystemTestHarness.html` and `index-sw.html` preset `FIZZYGUM_EAGER_ALL_PARTS` on
   purpose (a part arriving mid-test would be frame-paced, hence cycle-count-dependent —
   `../../../Fizzygum-tests/DETERMINISM.md`), so they compile everything regardless. The dev
   beneficiary is `index.html`, where lazy parts genuinely are lazy (measured: 452 of 502 stored
   sources in the vault at world-ready — the ~50 absent ones are the five lazy parts).

⇒ **For production, the pre-compiled image already collected the boot-time win and collected
essentially all of it** (54 ms). ⇒ **For the dev `index.html`, laziness is worth up to 17% — but
building that tree pre-compiled is worth 55×.** Arguments for extracting further parts rest on
**download bytes** (real, though the large slices are banked — `architecture/build-and-packaging.md`
§5), on **partition uniformity** (a design argument), and — only while `dev` stays compile-at-boot —
on dev boot. ⛔ Do not re-argue any of it on boot speed without re-running the probe.

## The trap this measurement nearly fell into

`performance.getEntriesByType('resource')` returns **nothing over `file://`** in Chrome — Resource
Timing is not populated for that scheme. The first version of the probe therefore reported 0 files
and 0 bytes for every bucket while the page had demonstrably loaded 22 of them. The per-file
breakdown above is collected DRIVER-side (`page.on('response')`) instead. Any future in-page timing
work on this codebase hits the same wall.
