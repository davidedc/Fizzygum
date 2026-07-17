> **ARCHIVED — COMPLETE (2026-07-17 restructure).** LANDED + PUSHED 2026-07-08 (+ post-landing block-scoping fix); checklist checkboxes left stale.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Fizzytiles → SW3D port + live-tiles rendering — implementation plan

STATUS: PLANNED (validations done 2026-07-07; re-verified 2026-07-08, execution
starting). See §0.5 for the 2026-07-08 receipt re-verification + drift corrections.
Owner request (2026-07-07): (1) the SWCanvas-based software 3D engine ("SW3D",
demoed in the SWCanvas repo's `examples/3d-fox.html`) must be **committed and
vendored, i.e. ready for use in Fizzygum**, and Fizzytiles must **use it**
instead of WebGL/twgl; (2) the Fizzytiles 3D output pane must **actually run
the code produced by the tiles** instead of the current hard-coded demo
(rotating cube+sphere wireframes). The two workstreams are largely
independent; this plan does both.

This plan is self-contained: all receipts are embedded with `file:line` as of
2026-07-07. Verify a receipt before relying on it if the file has churned.

---

## §0 Repos, paths, baseline (2026-07-07)

| Repo | Path | Baseline |
|---|---|---|
| SWCanvas | `/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas` (⚠ path contains SPACES — always quote) | HEAD `f463993`; the ENTIRE 3D arc is **uncommitted** (see §2.2). Remote `origin` = `github.com/davidedc/swcanvas.js` |
| Fizzygum | `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum` | Uncommitted at plan time: the fridge-magnets desktop launcher (4 files: NEW `src/fizzytiles/FridgeMagnetsApp.coffee`, `src/icons/FridgeMagnetsIcon{Appearance,Wdgt}.coffee`, M `src/WorldWdgt.coffee`) awaiting owner-approved commit, PLUS 2 concurrent-session docs (`docs/plans/dataflow-engine-implementation-plan.md`, `docs/specs/dataflow-engine-spec.md`) — **never stage those 2; stage explicit paths, never `git add -A`** |
| Fizzygum-tests | `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests` | clean; suite = **190** tests |

Workflow conventions (owner standing prefs): commit-on-approval only (present
summary + message, wait); never push unless the step requires it AND the owner
approved; long ops get an upfront ETA + ~5-min status updates; verification
gates via the umbrella `fg` wrapper (`/Users/davidedellacasa/code/Fizzygum-all/fg`,
absolute path): `fg build` · `fg suite` · `fg gauntlet` · `fg homepage` ·
`fg test <name>`.

---

## §0.5 Receipt re-verification + drift corrections (2026-07-08)

Every load-bearing receipt below was re-read against the live tree on 2026-07-08.
**Verified correct as written**: the SW3D API surface (`makeEngine`/`makeMesh`/
`setCamera`/`drawMesh`/`packColor`, `examples/sw3d.js`), BOTH engine gaps
(D3a unscaled bounding radius `sw3d.js:202-207`, D3b negative-determinant winding
flip `sw3d.js:241`), the 9-element matrix being consumed **row-major, applied
`v'=M·v`** (`sw3d.js:185,217-219`); `Surface` is a **factory** (`SWCanvas.Core.Surface(w,h)`,
no `new`) with `stride = width*4` and both `.data`/`.data32` (`src/core/Surface.js:38,41,46`),
`DepthBuffer` is a **class** (`new SWCanvas.Core.DepthBuffer(w,h)`, `.clear()`);
`SWCanvas.Core` exports Surface/DepthBuffer/Texture3D/Triangle3DOps
(`build.sh:381-383,434-436`); all four LCLTransforms draft bugs (a–d, §2.1);
the exact **29** `@`-bound commands (`@allCommandsRegex = commandsExcludingScaleRotateMove
| qualifyingCommands | primitives`, `LCLCodePreprocessor.coffee:142-144`; expressions/
colors are NOT bound) — D7's real+stub list covers all 29; `CanvasWdgt` blit discipline
(`setTransform(1,0,0,1,0,0)` → physical draw → `useLogicalPixelsUntilRestore()`,
`CanvasWdgt.coffee:82-94`); and **no SystemTest drives fizzytiles** (the one `fridge`
grep hit is a *provenance comment* in `SystemTest_macroDesktopShortcutIcons` noting it
deliberately avoids `world.createDesktop`).

**Corrections applied to this plan (drift since 2026-07-07):**

1. **Suite is 194, not 190.** It grew (layout-regressions follow-up: paint-gate +
   icon guards + folder-open). Every "190" below now reads **194**; the new macro
   test(s) take it to **195/196**. Gates expect **194/0** on the unchanged suite.
2. **`alignmentOfWidgetIDsMechanism` was DELETED** post-plan (Fizzygum `0189d7d5`,
   tests `29b11ea34`). So D6's "guard idiom already used in
   `FridgeMagnetsWdgt.coffee:31-34`" and B2.3's "guards already exist (:31-34,
   :199-202)" are STALE — those guards no longer exist in the file. The LIVE
   event-time guard idiom is `if Automator? and Automator.state != Automator.IDLE`
   (e.g. `StringWdgt.coffee:331`, `BlinkerWdgt.coffee:21-23`, `Widget.coffee:461`).
   D6/B2.3 corrected inline to cite these.
3. **Build-script line numbers drifted ~+20.** The SWCanvas prepend block (now
   deterministic-trig FIRST, then `swcanvas.min.js`) is `build_it_please.sh:551-556`;
   `cat $SWCANVAS_VENDOR/swcanvas.min.js` is **:553** (plan said :533); the twgl copy
   `cp auxiliary\ files/twgl/twgl-full.js …` is **:577** (plan said :557). The
   vendor-freshness gate is `:141`; auto-vendor `:141-151`. A2/§2.3/B1 corrected.
4. **A1 SWCanvas commit — one more exclusion.** Besides `AGENTS.md`, also EXCLUDE
   `plans/clipping-optimization.md` (an unrelated runtime-perf-effort edit dated
   2026-07-07, references `Fizzygum/docs/plans/runtime-performance-optimization-plan.md`).
   The 3D-arc file set is otherwise exactly as §2.2 lists.
5. **Minor line drifts (non-blocking):** `WorldWdgt.timeOfEventBeingProcessed`
   declared `WorldWdgt.coffee:79`, set `:1374` (plan §2.4 said :80 / ~:1174);
   `@visualOutput = new FridgeMagnets3DCanvasWdgt` is `FridgeMagnetsWdgt.coffee:36`
   (plan said 40); twgl-full.js is **~360 KB** (369,141 B), not ~250 KB — so the
   homepage payload shrinks even more than D2 estimated.
6. **Fizzygum git state has more concurrent-session noise now** — untracked
   `docs/archive/accidental-complexity-reduction-plan.md`, `docs/plans/livecodelang-cleanup-and-extensions-plan.md`,
   `docs/profiling/`, `docs/done/`, and `D docs/archive/swcanvas-invisible-pixel-hash-nondeterminism-plan.md`,
   plus the still-`M` `docs/dataflow-engine-*`. The §0/§C rule stands, hardened:
   **stage explicit paths only; never `git add -A`.** The 4-file launcher (§0) is
   still uncommitted.
7. **Surface sizing (impl refinement, B1.2/D5):** size the SW3D `Surface`/`DepthBuffer`
   to the widget's `@backBuffer.width`/`@backBuffer.height` (already physical integers)
   rather than recomputing `extent.scaleBy(ceilPixelRatio)` — guarantees the
   `putImageData` 1:1 mapping and dodges any fractional-extent rounding skew.

---

## §1 The two workstreams

- **WS-A — Ship SW3D**: commit the 3D engine work in the SWCanvas repo, push
  (the pin-based vendoring 404s otherwise), extend Fizzygum's vendoring +
  boot bundle to deliver `SW3D` alongside `SWCanvas`, bump the pin.
- **WS-B — Make the tiles drive the render**: rewrite
  `FridgeMagnets3DCanvasWdgt` to (a) render via SW3D software rasterization
  (no WebGL, no twgl), and (b) actually EXECUTE the compiled tile program each
  frame with a real LCL command runtime (matrix stack + primitives).

WS-B's LCL-runtime half is conceptually independent of WS-A, but the target
renderer is SW3D, so execute A → B. Phases: A1 (SWCanvas commit+push),
A2 (vendor+bundle), B1 (widget rewrite), B2 (macro tests), C (docs closeout).

---

## §2 Verified facts (receipts)

### 2.1 Current Fizzytiles pipeline (all files in `Fizzygum/src/fizzytiles/`, all homepage-excluded)

- **Widget tree** (`FridgeMagnetsWdgt.coffee`): 4 panes — `@magnetsBox`
  (tiles bin, 4 `MagnetWdgt`s labeled `scale/rotate/box/move`), `@fridge`
  (`FridgeWdgt`, drop target), `@codeOutput` (`FizzytilesCodeWdgt`),
  `@visualOutput` = `new FridgeMagnets3DCanvasWdgt` (line 40; the 2D
  `FridgeMagnetsCanvasWdgt` alternative is commented out at line 39).
- **Tiles → code**: `FridgeWdgt.compileTiles` (`FridgeWdgt.coffee:174-178`)
  fires from `_reactToChildGrabbed`/`_reactToChildDropped` (:181-185) →
  `putIntoWords()` (spatial transliteration of magnet positions into
  indented code text, :136-172) → `sourceCodeHolder.showCompiledCode code`
  AND `fridgeMagnetsCanvas?.newGraphicsCode code`.
- **Manual code edits also recompile**: `FizzytilesCodeWdgt.setText`
  (`FizzytilesCodeWdgt.coffee:13-16`) calls
  `@fridgeMagnetsCanvas?.newGraphicsCode @text` unless `skipCompilation`.
- **Code → program**: `LCLCodeCompiler.compileCode`
  (`LCLCodeCompiler.coffee:28-80`): preprocess via
  `LCLCodePreprocessor.preprocessAndBindFunctionsToThis`
  (`LCLCodePreprocessor.coffee:1701-1712` — prefixes every known command
  with `@`), then `CoffeeScript.compile`, then `new Function(...)` →
  `output.program`. So the program is meant to run as `@graphicsCode()`
  **with `this` = the canvas widget, and every LCL command must exist as a
  method on that widget**.
- **Command surface** (`LCLCodePreprocessor.coffee:44-93`):
  qualifying commands `rotate, move, scale, fill, stroke, noFill, noStroke`;
  primitives `rect, line, box, ball, peg, run`; other commands
  `ballDetail, pushMatrix, popMatrix, resetMatrix, bpm, play, strokeSize,
  animationStyle, background, simpleGradient, colorMode, lights, noLights,
  ambientLight, pointLight, connect`. (Expressions like `wave/pulse/beat`
  are NOT `@`-bound.)
- **THE BUG (owner item 2)**: `FridgeMagnets3DCanvasWdgt.paintNewFrame`
  (`FridgeMagnets3DCanvasWdgt.coffee:429-518`) never calls `@graphicsCode`
  (the invocation exists only as comments :432-438). It renders a hard-coded
  twgl/WebGL wireframe demo (cube+sphere, `Date.now()/600` clock, solid
  green `rgb(0,255,0)` underlay :513-515) into a WebGL side-canvas and
  drawImages it onto the backbuffer. Its ONLY LCL method is a stub `box`
  (:521-531) that draws a 2D rect; `move/rotate/scale` don't exist on it →
  running tile code would throw even if it were invoked.
- **The 2D reference implementation**: `FridgeMagnetsCanvasWdgt.coffee`
  (dormant) DOES run the program per frame (`paintNewFrame` :50-59:
  `@clear()`, translate to center, `try @graphicsCode() catch → rollback to
  @oldGraphicsCode`) and implements `scale/rotate/move` (2D ctx transforms
  with LCL "appended function" block semantics: push=ctx.save, run appended
  fns, pop=ctx.restore, and the `!result?` → undo-push-and-leave dance) and
  `box` (2D rect stub). `pulse()` (:61-72) uses wall-clock `new Date`.
- **`newGraphicsCode`** (both canvas widgets, e.g. 3D :33-38): saves
  `@oldGraphicsCode = @graphicsCode`, compiles, and only replaces
  `@graphicsCode` if `compilation.program?`.
- **twgl delivery**: the 3D widget dynamically injects
  `<script src="js/libs/twgl-full.js">` at construction (:43-54); the file
  ships from `Fizzygum/auxiliary files/twgl/twgl-full.js` via
  `build_it_please.sh:557`. **Nothing else uses twgl** (only other mention:
  a comment in `LCLTransforms.coffee:14`). It ships even in `--homepage`
  builds (dead weight — fizzytiles is homepage-excluded).
- **`LCLTransforms.coffee` — dead draft, key reuse candidate**: zero
  references anywhere. Implements exactly the LCL matrix-stack runtime the
  3D widget needs: 4×4 `@worldMatrix` + `@matrixStack`,
  `pushMatrix/popMatrix/resetMatrix/discardPushedMatrix` (incl. the
  "functional-if scale 0" undo subtlety, :77-98), and `scale/rotate/move`
  with the appended-function block semantics (:223-347). **Known draft
  bugs** (verify + fix in B1): (a) `rotate`/`move` reference
  `@backBufferContext` and call `context.save()` (:290-292, :331-333) —
  copy-paste leftovers, the class has no canvas; (b) bare
  `discardPushedMatrix()` (no `@`) at :303 and :344 → runtime
  ReferenceError; (c) **mixed matrix conventions**: `makeRotationFromEuler`
  (:154-186) is three.js column-major layout, `multiplyMatrix` (:103-152)
  is twgl-style, but `makeTranslation` (:188-206) writes translation into
  `[3],[7],[11]` — the TRANSPOSE slot of the `[12],[13],[14]` convention
  `scaleMatrix` (:35-56) assumes. Unify on column-major/twgl (translation
  at `[12..14]`) and verify composition order with a probe (see §4 B1.6).
  (d) `pulse()` (:210-221) uses wall clock.
- **No SystemTest covers fizzytiles** (grep for `fridge|fizzytiles` over
  `Fizzygum-tests` excluding node_modules: zero hits). Blast radius of the
  rewrite on the existing 190 references: **zero** (also: the test-harness
  world never runs `createDesktop` — `src/boot/globalFunctions.coffee:427-428`
  gates it on `world.isIndexPage`).
- **Paint-read-only hazard**: both canvas widgets override
  `createRefreshOrGetBackBuffer` to call `@paintNewFrame()` (3D :24-27) —
  a mutation on the PAINT path. Unexercised by the suite today; the rewrite
  must not carry it over (render in `step`, paint only blits). `step`
  (:69-72) is fine: widgets register via `world.steppingWdgts.add @`
  (ctor :59) and `Widget` destroy cleans up (`src/basic-widgets/Widget.coffee:561`).
- **Base class**: `CanvasWdgt` (`src/basic-widgets/CanvasWdgt.coffee`)
  keeps a physical-pixel `@backBuffer` canvas; contexts are left in
  logical-pixel scaling (`useLogicalPixelsUntilRestore`); `clear(color)`
  resets transform and fills.

### 2.2 SWCanvas 3D state (repo `/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas`)

- **Uncommitted 3D arc** (git status 2026-07-07): NEW core
  `src/core/DepthBuffer.js` (105 L), `src/core/Texture3D.js` (239 L),
  `src/renderers/Triangle3DOps.js` (1065 L); NEW core tests
  `tests/core/401…410-*.js` (10 files) + perf case
  `tests/direct-rendering/perf-cases/triangle3d-perf.js`; NEW engine layer
  `examples/sw3d.js` (434 L, global `SW3D`) + examples
  `3d-fox{.html,-node.js,-scene.js}`, `3d-cubes{.html,-node.js,-scene.js,
  -html5-compose.html}`, `gryphon-models.js`; MODIFIED `build.sh` (cats the
  3 core files into dist and exports them on `SWCanvas.Core`, :85,:87,:194,
  :381-383,:434-436), `.eslintrc.js` (3 new globals), `README.md` /
  `tests/README.md` (test counts 46→62 core), `examples/README.md` (+47 L),
  and the `dist/*` build products. UNTRACKED-but-UNRELATED: `AGENTS.md`
  (a Codex-context mirror of CLAUDE.md) — **exclude from the 3D commit**.
- **Validation already done (2026-07-07, this plan's prep)**:
  `npm run build && npm test` → **all 218 tests pass**, including the ten
  3D core tests (`DepthBuffer creation…`, `Texture3D…`, `Triangle3DOps
  depth test / watertight / clip mask / textured / perspective bound /
  intensity / litVariant / mip chain` all ✓).
- **SW3D API** (`examples/sw3d.js`): `SW3D.makeEngine(SWCanvas, {width,
  height, focal?, znear?, light?, ambient?, diffuse?})` →
  `{setCamera(pos, rotOrYaw), drawMesh(target, depthBuffer, mesh, position,
  rotation3x3orEuler, clipBuffer?), packColor}`;
  `SW3D.makeMesh({positions, faces:[{v:[i,j,k(,l)], color:[r,g,b],
  texture?, uv?}]})` (computes bounding `radius`). Pipeline: model→camera,
  bounding-sphere reject, per-face backface cull + flat Lambert +
  Sutherland-Hodgman near clip + perspective → `Triangle3DOps.fillTriangleZ`
  / `fillTriangleTexturedPersp`. Conventions: right-handed, +y up, camera
  looks along +z; faces wound outward. `drawMesh` already accepts a
  9-element row-major matrix as `rotation` and applies it as a general
  linear map — but (gap 1) the bounding-sphere reject uses the UNSCALED
  `mesh.radius`, and (gap 2) a negative-determinant matrix (mirror scale,
  LCL allows `scale -1`) flips winding → faces get culled inside-out.
- **Simple usage reference**: `examples/3d-cubes-scene.js` (cube CORNERS/
  FACES tables :21-40, per-face loop, `packColor` little-endian ABGR :55-57,
  `surface.data32.fill(bgPacked)` + `depthBuffer.clear()` per frame
  :316-317). Browser present-path reference: `examples/3d-fox.html`
  (`SWCanvas.Core.Surface(w,h)` + `new SWCanvas.Core.DepthBuffer(w,h)` +
  `new ImageData(surface.data, w, h)` → `putImageData`; reduced-resolution
  upscale path via a hidden buffer canvas, :60-86).
- **Repo invariants** (`SWCanvas/CLAUDE.md`): `npm run build` REQUIRED
  before every test run; dual-API parity; visual tests use the standard
  Canvas API. Commands: `npm test`, `npm run build:prod` (build + minify —
  required before vendoring), `npm run lint`.

### 2.3 Delivery chain into Fizzygum

- **Vendoring** (`Fizzygum/scripts/vendor-swcanvas.sh`): copies ONLY
  `dist/swcanvas.js` + `dist/swcanvas.min.js` into `Fizzygum/vendor/swcanvas/`
  (gitignored) + writes `VERSION` sentinel. Two modes: from-pin (downloads
  `github.com/davidedc/swcanvas.js/archive/<SHA>.tar.gz` — **the SHA must be
  pushed or fetch 404s**; the script itself warns about dirty/unpushed
  checkouts) and `--source <path>` (copies a local checkout's `dist/`,
  rewrites `vendor/swcanvas.pin` to that checkout's HEAD SHA unless
  `--no-pin-update`). Current pin: `f4639937…` = SWCanvas HEAD **without**
  3D; current vendored bundle has 0 hits for `Triangle3DOps`.
- **Bundling** (`Fizzygum/build_it_please.sh`): auto-vendors if missing
  (:139-150); prepends `runtime-prelude/deterministic-trig.js` (fdlibm
  sin/cos/tan/atan2/asin/acos installed over `Math.*` — engine-independent
  trig, the cross-engine determinism fix) then `vendor/swcanvas/swcanvas.min.js`
  to `js/fizzygum-boot-min.js` (:520-537, with `\n;\n` ASI separators).
  **SWCanvas is ALWAYS bundled** (used only when `?sw=1`, but
  `window.SWCanvas` exists in every build) → SW3D can software-render inside
  a widget while the world paints on the native canvas, in ALL builds, and
  SW3D's `Math.sin/cos` are already deterministic cross-engine because the
  shim installs before anything runs.
- **Font assets etc. are irrelevant here** (SW3D needs no assets).

### 2.4 Determinism + gates context (for B1/B2)

- Contract (`Fizzygum-tests/DETERMINISM.md`): tested pixels must be a pure
  function of the **event stream** + final geometry — never wall-clock,
  frame/cycle counts, or intermediate layouts. Event-time precedent: the
  multi-click fix reads `WorldWdgt.timeOfEventBeingProcessed` (published at
  `WorldWdgt.coffee:80`, set ~`:1174`) instead of timers.
- Bare `box` (no args) is STATIC (defaults a=b=c=1 — 3D widget :542-546);
  only bare `move/rotate/scale` have time-varying defaults (via `pulse()`/
  `Date`) → a box-only scene is a fully deterministic screenshot; animated
  scenes are deterministic iff the widget clock is event-time under the
  Automator.
- Gates that must stay green: `fg gauntlet` (build + dpr1 + dpr2 + webkit +
  apps + tiernaming/settle/capstone), `fg homepage`, serialization rig,
  paint-read-only gate, build-time lints (thin-wraps, dead-methods, stinks,
  layering `check-layering.js`).
- Serialization: runtime state (surfaces, buffers, compiled programs) must
  be declared via the `@serializationTransients` protocol —
  `docs/architecture/serialization-duplication-reference.md` (per-class protocol §);
  rebuild lazily on first use after restore.
- ⚠ Macro-test gotcha (recurred): a backtick in an
  `automationCommands.js` macro COMMENT closes the template literal → the
  test-.js gate fails. No backticks in macro comments.

---

## §3 Decisions (D1–D10, with rationale)

- **D1 — SW3D ships from the SWCanvas repo as `examples/sw3d.js`, vendored
  as-is** (no promotion into `src/`, no separate dist artifact). Rationale:
  SWCanvas's own layering doc calls SW3D the "userland engine layer"; the
  Core primitives it rests on ARE tested (401–410); promoting it is churn
  the owner didn't ask for. The vendor script (from-pin mode already
  downloads the full repo tarball) and `--source` mode each gain one `cp` of
  `examples/sw3d.js` → `vendor/swcanvas/sw3d.js`. Revisit-later option:
  promote to `dist/sw3d(.min).js` if SW3D grows more consumers.
- **D2 — Bundle `sw3d.js` unminified into `js/fizzygum-boot-min.js`
  right after `swcanvas.min.js`** (same `\n;\n` separator discipline).
  ~15 KB unminified — negligible next to swcanvas.min.js; applies to ALL
  builds including `--homepage` (symmetric with SWCanvas-always-bundled;
  keeping the bundle assembly unconditional is simpler than a homepage
  branch). Note: this REMOVES twgl-full.js (~250 KB) from every build
  including homepage, so the net homepage payload SHRINKS.
- **D3 — Extend SW3D (in the SWCanvas repo, same commit arc) with the two
  gaps + mesh helpers**: (a) when `rotation` is a 9-matrix, scale the
  bounding-sphere reject radius by the matrix's max column norm
  (conservative, cheap); (b) if the matrix determinant is negative, swap
  two vertices per emitted face (restores outward winding under mirror
  scale); (c) add `SW3D.makeBoxMesh(size, color)` and
  `SW3D.makeSphereMesh(radius, bandsH, bandsV, color)` generators (the
  cube tables exist in `3d-cubes-scene.js`; lat/long sphere = quads +
  triangle caps) so Fizzygum stays thin. Keep `drawMesh`'s public signature
  unchanged.
- **D4 — Repair and WIRE `LCLTransforms` as the widget's matrix stack**
  (owner prefers reuse; it encodes non-obvious LCL semantics already).
  Fixes: remove the `@backBufferContext` leftovers, `@`-qualify
  `discardPushedMatrix`, unify matrix convention (column-major, translation
  in `[12..14]`, per §2.1), route `pulse()` through the widget clock (D6).
  The widget owns one instance: `@transforms = new LCLTransforms`.
- **D5 — `FridgeMagnets3DCanvasWdgt` becomes a pure SW3D client**:
  delete all twgl/WebGL/wireframe machinery (script injection, shaders,
  barycentric/coPlanar/unindex code, `initialiseWebGLStuff`, the gl fields);
  render each frame into an `SWCanvas.Core.Surface` + `DepthBuffer` sized to
  the pane's PHYSICAL extent (extent × `ceilPixelRatio`), run
  `@graphicsCode()` (try/catch rollback exactly like the 2D widget), blit
  via `putImageData` (transform-independent; set identity first, restore
  logical scaling after — `CanvasWdgt.clear` :82-94 shows the discipline).
  Fallback if dpr-2 perf disappoints: render at logical size and upscale via
  a scratch canvas (the 3d-fox.html reduced-resolution path).
- **D6 — Widget clock = event time under the Automator, wall clock live**:
  `@timeNowSeconds()` returns `WorldWdgt.timeOfEventBeingProcessed / 1000`
  when `Automator? and Automator.state != Automator.IDLE` (guard idiom
  already used in `FridgeMagnetsWdgt.coffee:31-34`), else `Date.now()/1000`.
  All time-dependent defaults (`pulse`, bare move/rotate/scale) read it →
  suite screenshots of ANIMATED scenes become deterministic (same event
  stream → same pose), live desktop keeps animating.
- **D7 — Command set v1** (methods on the widget; everything runs with
  `this` = widget): `box`, `ball` (SW3D meshes drawn with
  worldMatrix × local-scale(a,b,c), transform NOT persisted);
  `move/rotate/scale` (delegate to `@transforms`, preserving
  appended-function block semantics); `pushMatrix/popMatrix/resetMatrix`
  (delegate); `fill r,g,b` (sets current mesh color); `background r,g,b`
  (sets clear color); `run` (invoke function args — port of
  `LCLProgramRunner.run`, `LCLProgramRunner.coffee:52-62`); graceful no-op
  stubs for `stroke/noStroke/noFill/strokeSize/lights/noLights/
  ambientLight/pointLight/ballDetail/animationStyle/colorMode/
  simpleGradient/bpm/play/connect` (they must EXIST so `@`-bound calls
  don't throw; a one-line `noOpLCLCommand:` comment each). `line/rect/peg`:
  v1 no-ops too (document as deferred — no SW3D line/quad-strip primitive
  worth building now). Camera fixed: `setCamera([0,0,-5], 0)` (unit box at
  origin ≈ 22% of pane height with SW3D's default focal = height×1.1).
  Defaults: background light gray `[230,230,230]`, fill `[231,76,60]`
  (cubes-demo red) — both trivial owner-taste knobs.
- **D8 — Keep**: `FridgeMagnetsCanvasWdgt` (2D, dormant — out of scope),
  the `MenusHelper.createFridgeMagnets` menu path (`MenusHelper.coffee:19-21`,
  menu item :834), `LCLProgramRunner`/stability-rollback machinery
  (unused by the widgets; do NOT wire it in v1 — `newGraphicsCode`'s
  oldGraphicsCode rollback already covers the runtime-error case).
- **D9 — Commits**: SWCanvas = ONE commit for the whole 3D arc incl. dist
  (exclude `AGENTS.md`; note: `dist/swcanvas.build-info.js` stamps the
  PARENT commit SHA — existing repo convention, accept it), then PUSH
  (required for from-pin reproducibility; the owner's "make it so
  [committed and vendored]" authorizes it — still present before pushing,
  per standing preference). Fizzygum = two commits: (1) the already-pending
  fridge-magnets launcher (if not yet landed), (2) this arc (vendor script +
  build script + pin + fizzytiles rewrite + docs). Fizzygum-tests = one
  commit (new macro test(s), lockstep).
- **D10 — Paint-read-only**: rendering happens in `step` (mutation-legal);
  `paintNewFrame`-during-`createRefreshOrGetBackBuffer` is NOT carried
  over. On resize the pane may show the base-class background for ≤1 cycle
  until the next step re-renders — acceptable (and invisible at 60fps).

---

## §4 Phase plan

### Phase A1 — SWCanvas: finish, commit, push

1. **SW3D enhancements** (`examples/sw3d.js`, per D3):
   - In `drawMesh`, when `rotation.length === 9`: compute
     `radiusScale = max(‖col0‖, ‖col1‖, ‖col2‖)` of the matrix and use
     `mesh.radius * radiusScale` in both bounding-sphere tests (:202-207);
     compute `det(modelRot)`; if negative, emit each face with two vertex
     indices swapped (i1↔i2 and matching UVs) so outward winding survives
     mirror scale. Euler-array path (`length===3`) keeps the fast path
     unchanged (pure rotations: radiusScale=1, det>0).
   - Add `makeBoxMesh` / `makeSphereMesh` (D3c) to the exported `SW3D`
     object. Reuse the CORNERS/FACES tables from `3d-cubes-scene.js` for the
     box; lat/long sphere: `bandsH×bandsV` quads + two triangle-fan caps,
     outward winding (verify with the node harness below).
   - Optional-but-cheap witness: extend `3d-cubes-node.js` (node-runnable)
     or add a tiny `examples/3d-meshes-node.js` that draws a scaled box +
     sphere via the new helpers and asserts nonzero emitted triangles both
     with positive and negative scale (guards D3a/b regressions).
2. `cd` (quoted!) into the repo: `npm run lint` (eslint covers `src/` — the
   3 new core files), `npm run build:prod && npm test` → expect all green
   (218 at plan time; count may tick up if step 1 adds tests).
3. **Commit** (single, explicit paths: the 3 core src files, 10+1 test
   files, build.sh, .eslintrc.js, the 3 README/docs, all `examples/3d-*` +
   `sw3d.js` + `gryphon-models.js`, `tests/dist/core-functionality-tests.js`,
   `dist/*`). EXCLUDE `AGENTS.md`. Draft message:
   "feat: software 3D pipeline — DepthBuffer/Texture3D/Triangle3DOps core +
   SW3D userland engine + fox/cubes demos + tests 401-410". Use
   `git commit -F <file>` (backtick-in-`-m` corruption gotcha). Present to
   owner → on approval commit AND push `origin`.
4. Record the new SHA — Phase A2 pins it.

### Phase A2 — Fizzygum: vendor + bundle SW3D

1. `scripts/vendor-swcanvas.sh`: add `sw3d.js` to BOTH modes —
   `--source`: `cp "$SRC/examples/sw3d.js" "$STAGING/"` next to the dist
   copies (and extend the existence check + error message); from-pin:
   `cp "$EXTRACTED/examples/sw3d.js" "$STAGING/"`; final install:
   `cp "$STAGING/sw3d.js" "$DEST/"`. Keep VERSION-last discipline.
2. `build_it_please.sh`: after the `cat $SWCANVAS_VENDOR/swcanvas.min.js`
   line (:533) + its separator, append
   `cat $SWCANVAS_VENDOR/sw3d.js >> …tmp` + another `printf '\n;\n'`;
   extend the vendor-freshness check (:141) to also require
   `$SWCANVAS_VENDOR/sw3d.js` so stale vendor dirs re-fetch. Update the
   nearby comment block naming what the bundle contains.
3. Vendor from the local checkout (pin auto-bumps to the Phase-A1 SHA):
   `./scripts/vendor-swcanvas.sh --source "/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas"`
   (must be clean + pushed by then, or the script warns). Sanity: from-pin
   round-trip — `rm -rf vendor/swcanvas && ./scripts/vendor-swcanvas.sh` —
   must reproduce the same three files (proves the tarball path works).
4. Gate: `fg build` then a boot check that `window.SWCanvas.Core.Triangle3DOps`
   and `window.SW3D` exist in the built page (2-line puppeteer eval, or
   just `grep -c "Triangle3DOps\|SW3D" ../Fizzygum-builds/latest/js/fizzygum-boot-min.js`).
   `fg homepage` (bundle assembly is shared — prove homepage still boots).

### Phase B1 — Fizzygum: rewrite `FridgeMagnets3DCanvasWdgt` on SW3D + run the tiles' code

Touch list: `src/fizzytiles/FridgeMagnets3DCanvasWdgt.coffee` (rewrite,
~571→~250 L), `src/fizzytiles/LCLTransforms.coffee` (repairs, D4),
`build_it_please.sh` (remove twgl cp :557), delete
`auxiliary files/twgl/twgl-full.js`, `src/fizzytiles/LCLTransforms.coffee:14`
comment tweak if needed. Grep `twgl` repo-wide after — must be zero
functional hits.

1. **Fields**: `@transforms` (LCLTransforms), `@surface`, `@depth`,
   `@engine`, `@imageData`, `@boxMesh`, `@ballMesh`, `@currentFillRGB`,
   `@backgroundRGB`, `@lclCodeCompiler` (kept), `@graphicsCode`/
   `@oldGraphicsCode`/`newGraphicsCode` (kept as-is :29-38). Declare the
   SW3D runtime objects as serialization transients (§2.4) — follow the
   per-class protocol in `docs/architecture/serialization-duplication-reference.md`;
   lazy `@ensureEngine()` rebuilds them on first render after
   restore/duplication.
2. **`ensureEngine()`**: (re)build surface/depth/engine/imageData when
   absent or when `@extent().scaleBy(ceilPixelRatio)` ≠ surface size
   (replaces the old glBuffer-resize check :444). Meshes built once via
   `SW3D.makeBoxMesh(1, currentFill…)`-style helpers — note face color is
   per-mesh in SW3D, so either rebuild meshes on `fill` change or (better)
   pass color per draw: keep ONE white mesh and pre-multiply intensity…
   → simplest correct v1: cache one mesh per (primitive, fill-RGB) in a
   small map keyed by the rgb triple; `fill` just switches the key (tile
   scenes use a handful of colors at most).
3. **`step`** (unchanged registration): `@renderScene()` then `@changed()`.
   **`paintNewFrame` is deleted**; the `createRefreshOrGetBackBuffer`
   override is deleted (D10).
4. **`renderScene()`**: `return unless @graphicsCode? and @extent().gt …`;
   `@ensureEngine()`; fill surface with packed `@backgroundRGB` +
   `@depth.clear()`; `@transforms.resetMatrixStack()`; camera
   `@engine.setCamera [0,0,-5], 0`; `try @graphicsCode() catch →
   @graphicsCode = @oldGraphicsCode` (2D widget's exact rollback shape);
   blit: `@backBufferContext.setTransform 1,0,0,1,0,0` →
   `putImageData @imageData, 0, 0` → `useLogicalPixelsUntilRestore()`.
5. **Primitives**: `box`/`ball` keep the existing argument-normalization
   shape (:533-556 — a/b/c defaults + appended-function detection), then:
   compose `m = @transforms.worldMatrix × scaleMatrix(a,b,c)` (LOCAL, not
   persisted), extract SW3D inputs — column-major m → row-major linear
   `[m0,m4,m8, m1,m5,m9, m2,m6,m10]`, translation `[m12,m13,m14]` — and
   `@engine.drawMesh @surface, @depth, mesh, translation, linear9`;
   then `appendedFunction.apply @` if present.
6. **Transform commands** on the widget delegate to `@transforms` (which
   after D4 repairs is canvas-free). **Convention probe before trusting
   composition order**: run `move 2, 0, 0; rotate 0, 0.8, 0; box` vs
   `rotate 0, 0.8, 0; move 2, 0, 0; box` in the live pane — the first must
   orbit-translate THEN rotate locally (box away from center, rotated in
   place), the second must place the box at the rotated offset. If flipped,
   swap the `multiplyMatrix` argument order in LCLTransforms. (2
   falsified attempts → stop and re-derive on paper, owner rule.)
7. **Clock**: `timeNowSeconds()` per D6; `pulse` (move into the widget or
   keep on LCLTransforms reading a passed-in clock — pick ONE home, widget
   preferred since it owns Automator context) and the bare-arg defaults of
   move/rotate/scale read it.
8. **Stubs** per D7. `run` port per D7.
9. Gates: `fg build` (syntax gate) → `fg suite` (expect 190/0 — nothing
   references fizzytiles) → eyeball (recipe §5) → `fg gauntlet` +
   `fg homepage` before presenting.

### Phase B2 — Fizzygum-tests: macro coverage (suite 190 → 191 or 192)

Author via the `/author-macro-test` skill (tests repo; toolkit docs
`Fizzygum/src/macros/CLAUDE.md`, patterns `src/macros/MACRO-PATTERNS.md`).

1. **`macroFizzytilesBoxTileRendersStaticCube`** (the core witness): open
   the app (menu path or direct `world.openWindowWith (new
   FridgeMagnetsWdgt), (new Point 570,400), <fixed point>` in a macro
   command — mirror how other app macros open windows), drag the `box`
   magnet from the tiles bin onto the fridge pane, assert screenshot:
   code pane shows `box`, 3D pane shows the static lit cube (bare `box` is
   time-independent, §2.4 — deterministic at dpr1/dpr2/webkit by
   construction; SWCanvas rasterization is byte-exact and trig is
   fdlibm-shimmed).
2. **Optional second beat** (exercises D6): drag `rotate` to the left of
   `box` (code `rotate box`, animated) and screenshot — valid ONLY with the
   event-time clock; if it flakes at dpr2-fastest, drop the screenshot and
   keep a code-pane-only assertion (do not burn >2 attempts, owner rule).
3. Test-authoring gotchas: no backticks in macro comments (§2.4 ⚠);
   `alignmentOfWidgetIDsMechanism` guards already exist in
   `FridgeMagnetsWdgt` (:31-34, :199-202); a test failing with ZERO failed
   screenshots = uncaught error/shard stall (memory `macro-test-relocation-gotchas`).
4. Gates: `fg test <name>` while iterating → full `fg gauntlet` (dpr1 +
   dpr2 + webkit) + `fg apps` + `fg homepage`.

### Phase C — Docs closeout + landing

1. Fizzygum docs: breadcrumb in `Fizzygum/CLAUDE.md` (fizzytiles now
   SW3D-rendered, twgl removed, SWCanvas pin semantics unchanged); suite
   count bump in all three CLAUDE.md files (190 → new count); this plan
   file gets a §LANDED box (hashes, deviations, receipts).
2. Commits in order (each presented for approval first, explicit paths,
   `git commit -F`): SWCanvas (done in A1) → Fizzygum-tests → Fizzygum
   (vendor script, build script, pin, fizzytiles files, deleted twgl aux
   file, docs). ⚠ Re-check `git status` for concurrent-session files at
   execution time; at plan time the 2 dataflow docs must stay unstaged.
   The pending fridge-magnets-launcher commit (§0) lands FIRST if it
   hasn't already.

---

## §5 Verification gates + eyeball recipe

Per phase, in order: SWCanvas `npm run build:prod && npm test` (A1) ·
`fg build` + bundle grep (A2) · `fg suite` (B1) · `fg test <name>` → `fg
gauntlet` + `fg apps` + `fg homepage` (B2/C) · serialization rig if the
world-snapshot leg is touched by transients work (it shouldn't be — no test
serializes a fizzytiles window; run it anyway before the final present:
it's part of gauntlet-adjacent habit).

**Eyeball recipe** (headless, adapted from the launcher-work session; needs
`Fizzygum-tests/node_modules/puppeteer`): write to scratchpad e.g.
`fizzytiles-shot.js` —

```js
const puppeteer = require('/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/node_modules/puppeteer');
(async () => {
  const b = await puppeteer.launch({headless: 'new', args: ['--allow-file-access-from-files']});
  const p = await b.newPage(); await p.setViewport({width: 1280, height: 800});
  p.on('pageerror', e => console.log('PAGEERROR', e.message));
  await p.goto('file:///Users/davidedellacasa/code/Fizzygum-all/Fizzygum-builds/latest/index.html', {waitUntil: 'load'});
  for (let i = 0; i < 60; i++) {                       // world up? (plain evaluate; waitForFunction
    const n = await p.evaluate('window.world && world.children ? world.children.length : 0').catch(() => 0);
    if (n > 3) break; await new Promise(r => setTimeout(r, 1000));
  }
  await p.evaluate('menusHelper.createFridgeMagnets()');  // open the app directly
  await new Promise(r => setTimeout(r, 2000));
  // drag the box magnet onto the fridge: find coords in-page, then real mouse events
  const c = await p.evaluate(`(function(){
    var fm = null; world.children.forEach(function(w){ if (w.constructor.name==='WindowWdgt' && w.title && /Fizzytiles/.test(w.title.text||'')) fm = w; });
    var root = fm; var mag = null, fridge = null;
    root.forAllChildrenBottomToTop(function(ch){ if (ch.constructor.name==='MagnetWdgt' && ch.label && ch.label.text==='box') mag = ch; if (ch.constructor.name==='FridgeWdgt') fridge = ch; });
    return {mx: mag.center().x, my: mag.center().y, fx: fridge.center().x, fy: fridge.center().y};
  })()`);
  await p.mouse.move(c.mx, c.my); await p.mouse.down();
  await p.mouse.move(c.fx, c.fy, {steps: 20}); await p.mouse.up();
  await new Promise(r => setTimeout(r, 2000));
  await p.screenshot({path: '<scratchpad>/fizzytiles.png'}); await b.close();
})();
```

(NOTE: `waitForFunction` breaks against Fizzygum's prototype extensions —
poll with plain `evaluate`. Adjust the widget-finding walk to the real
APIs at execution time; treat the snippet as a template, not gospel.)
Read the PNG: expect the code pane to show `box` and the 3D pane to show a
lit static cube on the new background (NOT the green twgl demo). Then drag
`rotate` left of `box` similarly and re-shoot twice a second apart — the
cube pose should differ between shots (animation alive on wall clock).

---

## §6 Risks & gotchas

- **Pin/push ordering**: the pin must reference a PUSHED SWCanvas SHA or
  every fresh `fg build` on another machine 404s at auto-vendor (:141-150).
  Order is A1-push → A2-pin. If push approval stalls, A2 can proceed
  locally via `--source --no-pin-update` but MUST NOT commit the pin.
- **Matrix-convention bug class** (LCLTransforms §2.1d): symptoms are
  "translation ignored" or "rotation orbits instead of spins". Fix the
  convention FIRST (one probe, §4 B1.6), don't chase per-command.
- **dpr2 perf**: pane ≈ 190×370 logical → ~380×740 physical surface at
  dpr2; a few flat-shaded meshes is trivially cheap for Triangle3DOps (fox
  demo does orders of magnitude more), but the suite runs 5 shards in
  parallel — if the new test flakes on watchdog timeouts, drop to
  logical-resolution rendering (D5 fallback) before touching test flags.
- **Paint-read-only gate** (§2.4): render ONLY from `step`. If the gate
  still trips, the violation is real — do not exempt it.
- **`putImageData` needs `ImageData(surface.data, w, h)`** — `surface.data`
  is a `Uint8ClampedArray` view; re-create `@imageData` whenever the
  surface is rebuilt, never cache across resizes.
- **Serialization/duplication**: without transients, duplicating or
  world-snapshotting an open Fizzytiles window would try to serialize
  Float64Array scratch + Surface objects. Declare transients (B1.1) and
  smoke it manually: duplicate the window in-world; snapshot+reload via the
  file rig only if paranoid (no suite coverage exists → manual check).
- **Homepage build**: fizzytiles sources stay excluded (all carry the
  per-file marker; `FridgeMagnetsApp` createOpener call in
  `WorldWdgt.createDesktop` is section-excluded) — but `sw3d.js` now ships
  in the homepage bundle (D2, deliberate). `fg homepage` proves boot.
- **Preprocessor is UNTOUCHED** — do not edit `LCLCodePreprocessor` in this
  arc (its in-browser test harness instructions sit at its header :10-13 if
  ever needed).
- **Falsification budget** (owner rule): 2 failed fix-shapes on any single
  problem → stop, re-frame, write findings into this plan.

## §7 Non-goals / deferred

- `line/rect/peg` primitives, textures on LCL meshes (Texture3D is there
  when wanted), `stroke`-style wireframes (the twgl barycentric look),
  LCLProgramRunner stable-program machinery, doOnce ticks, sounds
  (`bpm/play`), 2D `FridgeMagnetsCanvasWdgt` (stays dormant), per-widget
  render-throttling when the scene is static.

## §8 Landing checklist

- [ ] A1: SW3D enhancements in; `npm run build:prod && npm test` green;
      single commit (no AGENTS.md) presented → approved → pushed; SHA noted.
- [ ] A2: vendor script + build script wired; `--source` vendored; pin
      bumped; from-pin round-trip reproduces; `fg build` + bundle grep +
      `fg homepage` green.
- [ ] B1: widget rewritten (twgl fully gone, grep-proven); LCLTransforms
      repaired + wired; `fg build` + `fg suite` 190/0; eyeball shows tiles
      driving the SW3D render (static + animated).
- [ ] B2: macro test(s) landed; `fg gauntlet` dpr1/dpr2/webkit + apps +
      homepage green at the NEW suite count.
- [ ] C: docs breadcrumbs + suite-count bumps + this plan's LANDED box;
      three repo commits presented → approved (SWCanvas already pushed;
      others NOT pushed unless asked).

---

## §9 AS-BUILT (execution 2026-07-08) — code done, commits pending approval

All CODE is written + verified; **nothing is committed or pushed** (owner
standing pref: present + wait). Per-phase evidence:

**A1 — SWCanvas SW3D enhancements (uncommitted in the SWCanvas repo).**
Edited `examples/sw3d.js` (D3a: bounding-sphere reject radius × max-column-norm
when `rotation.length===9`; D3b: reverse face winding when `det(modelRot)<0`,
keeping vertex 0 as the fan apex — `s1/s2` + `srcSlot`; D3c: `makeBoxMesh` /
`makeSphereMesh` exported on `SW3D`). New witness `examples/3d-meshes-node.js`
pins both gaps decisively (gap1: an off-axis unit box is rejected → 0 tris, the
same box ×3 survives → 4 tris; gap2: a red-front box stays red under an x-mirror
— without the fix the blue back face would show). `npm run lint` = the 34
PRE-EXISTING `src/text/*` errors only (lint is scoped to `src/`; `examples/` is
never linted; the `.eslintrc.js` change is purely 3 additive globals) — NONE in
my files; **not fixed (out of scope).** `npm run build:prod && npm test` = **218
passing.**

**A2 — vendor + bundle (uncommitted in Fizzygum).** `scripts/vendor-swcanvas.sh`
copies `examples/sw3d.js` → `vendor/swcanvas/sw3d.js` in both modes + extended
existence checks; `build_it_please.sh` bundles `sw3d.js` after `swcanvas.min.js`
(with the `\n;\n` separators) and the freshness gate (:141) now requires it.
Vendored via `--source --no-pin-update` (pin NOT bumped — the SWCanvas SHA is
unpushed; §6 fallback). `fg build` green; a headless boot probe confirms
`window.SW3D.makeEngine` + `SWCanvas.Core.{Triangle3DOps,DepthBuffer,Texture3D,
Surface}` exist and an end-to-end unit-box `drawMesh` emits 2 tris over
`file://`, no page errors. `fg homepage` boots green. (**Deferred to
post-push:** the from-pin round-trip — the pin still references the pre-3D SHA,
so a from-pin fetch would lack `sw3d.js`; run it after the SWCanvas commit+push
+ pin bump.)

**B1 — widget rewrite + LCLTransforms repair (uncommitted in Fizzygum).**
`FridgeMagnets3DCanvasWdgt` rewritten (571→~230 L) as a pure SW3D client (all
twgl/WebGL/wireframe + the `createRefreshOrGetBackBuffer` override + `paintNewFrame`
deleted; renders in `step`, blits by `putImageData`). All **29** `@`-bound LCL
commands present. `LCLTransforms` repaired — the plan's four bugs PLUS a **fifth,
unlisted latent bug**: `scaleMatrix` was a private `=` function but called as
`@scaleMatrix` (a runtime ReferenceError; the draft was never run) → made a
method. twgl removed (aux file + build cp; grep = only removal-describing
comments). `fg build` green (0 lint violations; dead-methods/stinks/thin-wraps
OK). Headless render checks: bare `box` → a lit red square (front face, head-on
camera per D7 — a red cube face, 0 twgl-green px); `rotate 0,0.7,0.4 box` → a 3D
cube (3 differently-lit faces); `move` → offset box; bare-`rotate` (pulse
default) renders without throwing; two renders at the same event-time are
**byte-identical** (deterministic). `fg suite` = **194/194, 0 failed** (twice —
before and after the transient fix). **New finding beyond the plan:** the file
`@serializationTransients` protocol governs the Serializer, but in-memory
duplication (`deepCopy`) drops a field only if its value carries a
`rebuildDerivedValue` method — so window duplication crashed until each runtime
object was stamped with a no-op `rebuildDerivedValue` (canvas-context idiom);
after the fix, duplicating an open pane rebuilds its runtime and re-renders (no
crash).

**B2 — macro test (uncommitted in Fizzygum-tests).**
`SystemTest_macroFizzytilesBoxTileRendersStaticCube` — opens the window at a
fixed point (not the nondeterministic `createFridgeMagnets` hand-position path),
`@dragWidgetTo_InputEvents fmm.box, fmm.fridge`, two screenshots (image_0 empty,
image_1 the cube). Preamble is the CURRENT 4-command one (ResetWorld +
AnimationsPacingControl + HidingOfWidgetsNumberIDInLabels +
HidingOfWidgetsContentExtractInLabels — the skill's listed
`TurnOnAlignmentOfMorphIDsMechanism` is STALE/deleted). References captured +
verified at **dpr 1 and dpr 2** (Chrome); visualisation page generated. Suite
**194 → 195.**

**Gauntlet / homepage: GREEN (2026-07-08).** `fg gauntlet` = build OK (0 lint
violations) · dpr1 **195/0** · dpr2 **195/0** · webkit **195/0** · apps PASS ·
paint PASS · tiernaming PASS (0 leaks/195) · settle PASS · capstone PASS. `fg
homepage` = BOOT OK (twgl-removed homepage boots clean; normal build restored).

**Commit plan (explicit paths; `git commit -F`; present each, wait):**
1. SWCanvas 3D arc — ONE commit, EXCLUDE `AGENTS.md` **and**
   `plans/clipping-optimization.md` (unrelated perf-effort edit) — then PUSH.
2. Fizzygum: pending 4-file launcher (if not landed) → this arc (vendor script +
   build script + pin bumped to the pushed SHA + fizzytiles rewrite + deleted
   twgl aux + docs). Never `git add -A`; the concurrent-session docs
   (`docs/dataflow-engine-*`, `docs/accidental-complexity-*`,
   `docs/livecodelang-*`, `docs/profiling/`, `docs/done/`) stay unstaged.
3. Fizzygum-tests: the new macro test (+ its captured refs + visualisation).

**LANDED + PUSHED 2026-07-08:** SWCanvas `f463993..f5f3f12`→main;
Fizzygum `e7510fa0..b8463ab7`→master (launcher `1284a6fc` + arc `b8463ab7`);
Fizzygum-tests `899a86775..24e46f242`→master. From-pin round-trip verified
against the pushed SHA.

---

## §10 POST-LANDING FIX — LCL block scoping (2026-07-08, owner-reported)

After the arc landed, the owner reported that `rotate box` ⏎ `box` rotated BOTH
boxes (should be one rotating, one still). Diagnosis (compiled-source dump): the
preprocessor is correct — `rotate box` compiles to `this.rotate(this.box)` (box
as rotate's scoped block) — the bug was in the RUNTIME. **Root cause:** the
primitives (`box`/`ball`, via `_drawMesh`) returned `undefined`, which
`LCLTransforms.{rotate,move,scale}` read as the LCL "fake function" signal (a
conditional that drew nothing) → `discardPushedMatrix` (KEEP the transform)
instead of `popMatrix` (restore it) → the transform leaked onto every following
shape. The ported `LCLTransforms` comment describes this distinction; the port
just never gave the primitives a truthy return.

**Fix (both in `FridgeMagnets3DCanvasWdgt.coffee`):** (1) `box`/`ball` (+ the
block-passing no-op commands + `run`) return truthy, so a qualifying command
`popMatrix`-restores its matrix and the transform scopes to its block; (2) the
same latent leak existed for **`fill`** (set the colour with no save/restore) —
`fill` now saves/sets/runs-block/restores when it has a block (a block-less
`fill` stays global), the colour analogue of push/pop. Verified structurally
(`worldMatrix` + `currentFillRGB` per box draw): rotate/move/scale/fill scope
inline, indented, and nested; block-less forms stay global.

**Regression test:** `SystemTest_macroFizzytilesBlockScoping` — sets
`fill 60,120,220 move 0.55,0,0 box` ⏎ `box` in the code pane; the SW3D pane must
show a blue box moved right (scoped) + a default-red box centred. Guards both
leaks in one static (deterministic) frame. Refs dpr1+dpr2. Suite **195 → 196.**

Gauntlet / homepage: GREEN (2026-07-08) — dpr1 **196/0** · dpr2 **196/0** ·
webkit **196/0** · apps/paint/tiernaming/settle/capstone PASS · `fg homepage`
BOOT OK.
