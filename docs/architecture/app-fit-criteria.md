# App fit criteria — the disqualifier is the ontology, not the domain

Standing criteria for judging whether a candidate widget or app belongs in Fizzygum.
They expand the citizenship acid test
([`widget-citizenship.md`](widget-citizenship.md): *"whether it could be assembled
manually using existing, simpler components"*) into facets that can be applied one at a
time — because candidates rarely pass or fail wholesale, and the productive design move
is usually **splitting an idea along a facet line** so the citizen-shaped part comes in
and the rest stays outside a boundary widget.

Two poles calibrate the scale:

- **A port of Doom** fails nearly every facet below: it arrives as a sealed rival world
  (its own 3D space, camera, engine) with no parts to reuse, nothing meaningful on pins,
  meaningless duplication, and a mountain of code below the inspectable floor.
- **A tenori-on-style button-grid synth sequencer** passes nearly every facet: it *is*
  layout (a grid of toggles), it wires (tempo/transpose/current-step pins, spreadsheet-
  drivable), editing it is the same activity as playing it, and it decomposes into parts
  (toggle-grid, step-clock, voice) that other apps want.

The pole comparison also fixes the headline rule: **the disqualifier is never the
domain, it's the ontology.** Fizzytiles is 3D and belongs — its engine is small,
deterministic, legible, and its authoring surface (the tiles) is pure Fizzygum
([`../archive/fizzytiles-sw3d-port-plan.md`](../archive/fizzytiles-sw3d-port-plan.md)).
Doom's problem is not the corridors; it is arriving as a rival universe with no
authoring gradient.

## A. Structural fit — where the idea's model lives

**1. Geometry alignment: aligned / neutral / rival.**
- *Aligned* — the idea's own structure IS rectangles-in-planes (a button grid, a kanban
  board, a calendar, a piano roll): the layout machinery works *for* it.
- *Neutral* — no spatial model of its own (a metronome, a unit converter): fine, it sits
  in a panel.
- *Rival* — it brings its own scene graph / camera / internal coordinate space (Doom, a
  3D modeler, a pannable slippy map). Not automatically fatal — Fizzytiles proves a
  rival space can live inside one widget — but everything inside the rival space is dead
  to direct manipulation, pins, and inspection unless explicitly re-exported.

**2. Model granularity — put widgets where manipulation pays.**
A model can be *widgets* (chess pieces: every piece grabbable, right-clickable,
wireable) or *data rendered by one widget* (a 200×200 cellular-automaton grid, which
must not be 40,000 widgets). Ask: **is the granularity at which the user wants to grab
things affordable as widgets?** A 16×16 toggle grid: yes. Hybrids are legitimate and
often best — cells as data, playhead/cursor as a real widget. An idea whose natural
manipulation grain is unaffordably fine (per-pixel, per-particle) should be re-cut so
manipulation happens on controllers rather than elements — FizzyPaint's shape: you
manipulate brushes and the canvas widget, not pixels.

**3. Decomposability with named beneficiaries.**
The acid test, sharpened: name three parts of the proposed app, and for each part name
a *second* app that wants it. Tenori-on → step-clock (also drives slideshows, animation,
automaton generations), toggle-grid (also a boolean-matrix and pixel-icon editor),
synth voice (also playable from a keyboard widget, a spreadsheet, a `MouseSensorWdgt`).
Doom → camera, BSP renderer, monster AI: zero second customers. No second customers ⇒
the proposal is a chiselled monolith, against composition-over-chiselling
([`design-principles.md`](design-principles.md)).

**4. Content/chrome tiering.**
The idea must be describable as a *naked capability* — a `Simple*Wdgt` holding data plus
a self-mutation API — with editing arriving from outside, per the frame model
([`regularity-principles.md`](regularity-principles.md)). Good sign: two *different*
editing chromes over the same Simple core are imaginable. Ideas that only exist as a
fused editor-plus-content blob (IDE-like tools, video editors) fight the tiering.

**5. The postcard test.**
Fizzygum's home territory is documents and dashboards: things get embedded at postcard
size inside a page, half-occluded, next to prose. Does the idea still make sense at
200×150 px inside a document, still running? A sequencer, a clock, a sparkline, a
dice-roller: yes. A DAW, a full-screen game: no — those are *destination* apps that
assume they own the screen. Slogan: **materials, not destinations.**

## B. Connectivity — the mashup dividend

**6. Pin surface, in both directions.**
Count what fraction of the interesting behaviour can be advertised as pins (the three
setter tables — `numericalSetters()` / `stringSetters()` / `colorSetters()` — plus
`@target`/`@action` driving, [`widget-citizenship.md`](widget-citizenship.md) point 4).
Then check *direction*: sinks (tempo, transpose, colour) let the world drive the app;
**sources** (current-step, computed value, detected event) let the app drive the world —
rarer and more valuable, because a source turns the app into an instrument for
everything else. A gauge is sink-only (fine); a metronome is source-only (great); a
sequencer is both (best).

**7. The spreadsheet two-way test.**
Could a spreadsheet drive it, and could it fill a spreadsheet? Since one dataflow
engine serves cells and patch wires
([`../specs/dataflow-engine-spec.md`](../specs/dataflow-engine-spec.md)), this asks
whether the app's state is a small set of scalar-ish values with clean semantics — and
it catches wire-vocabulary mismatch (facet 9) early.

**8. Progressive authoring depth.**
Programming available at every depth, required at none. Score the rungs the idea offers:
(1) direct use — click the cells; (2) direct-manipulation authoring — rearrange,
resize, recolour, duplicate; (3) wiring — pins and patch nodes; (4) formulas —
spreadsheet; (5) source — class inspector. The best citizens have **no gaps**, so a
user slides deeper one rung at a time. Doom offers rung 1 and rung 5 with a chasm
between.

**9. Wire vocabulary fit — payloads are cheap, edge semantics are the axis.**
The three payload types (number, string, colour) are *not* the expensive axis. What the
three share is one **edge semantic**: a wire carries a stateless *current value* —
latest-wins, coalescible, pulled at recompute time (notifications carry no values —
[`../specs/dataflow-engine-spec.md`](../specs/dataflow-engine-spec.md) §3). Adding a
fourth *payload* of that same semantic is cheap — one more setter table — and that
covers more than scalars: an **immutable buffer reference** (a wavetable, a sample, an
envelope) is a legitimate current value, since latest-wins is exactly what a buffer
*document* wants. Two conditions make a reference payload honest: replace-don't-mutate
(in-place mutation is invisible to the engine and pointer-equality would let the
equal-value cutoff suppress a real change — pair identity with a generation stamp, the
island-buffer-cache precedent), and a serialization answer for the blob (facet 10).

Traffic that **breaks the semantic** splits into two very different cases:

- **Discrete events** (a note-on): identity and *count* matter — two events must not
  coalesce into one. The engine already reserves this lane, in two halves: **`bang`**
  is a force-fire (stale-with-force — propagates despite the equal-value cutoff, spec
  §8) and **`firesPerEvent`** is the per-wire per-event delivery policy (spec §4) — a
  synchronous mini-pass inside the event, which is why there is no queue and no
  in-flight state to serialize (a cascade completes inside its own event). Status: the
  flag rides every edge record and has its menu toggle, but delivery currently POOLS —
  the mini-pass is deferred (spec §13, downstream-scoping fine print), so today N
  bangs in one cycle coalesce into one forced fire. An idea needing true per-event
  delivery is signing up to land that deferred lane — bounded engine work on an
  already-speced design, not a new type system. Structured events (pitch + velocity)
  are the cold-inlet idiom: store-without-firing **cold edges** (spec §8, unbuilt —
  §13 asks for their first real customer) set the fields, a hot bang fires.
- **Continuous signals on a deadline** (live audio quanta, ≈3 ms at 44.1 kHz): these
  break *rate*, and no wire semantics fix that — the world cycle is frame-paced and
  deliberately not hard-real-time. The sample pump lives below the floor (facet 13);
  the wires above carry buffer *values*, control scalars, and bangs. (Offline chunked
  pipelines with no deadline reduce to buffer-reference events — fine.)

One sanctioned out sidesteps even the event lane: **control-voltage flattening** —
encode events as scalar transitions (a gate pin going 0→1), the analog-synth trick;
keeps pooled semantics, accepts coalescing losses. An idea that stays scalar wires
natively today; one that needs per-event delivery inherits the deferred `firesPerEvent`
implementation as a prerequisite.

## C. Liveness, state, and the house physics

**10. The duplication test.**
Duplicate the running thing — is the live copy a *meaningful new object*? Two
sequencers that then diverge: meaningful (that is performance technique). Two copies of
mid-game Doom: nonsense. Duplication is a first-class power and the safety valve of
liveness ([`design-principles.md`](design-principles.md)); an idea that duplicates
meaninglessly is fighting it. Corollary: state must be plain serializable fields — no
instance-assigned closures, no opaque blobs
([`serialization-duplication-reference.md`](serialization-duplication-reference.md)).
Ask: **what does the saved document of this app look like, and is it small and
legible?** A sequencer document is a boolean grid plus a few numbers. A sampler's is
megabytes of PCM — that needs a transient/re-derive design before citizenship.

**11. Inspector legibility.**
Open the inspector on it mid-run: is the interesting state visible, named, small, and
*editable to good effect*? A physics toy (positions, velocities, spring constants) is
legible and rewarding to poke. A neural-net toy's weight matrix is inspectable in
principle, meaningless to read. Prefer state that is semantically dense per byte.

**12. Edit-while-running tolerance.**
The world never stops; the sweet spot is ideas where **editing is the same activity as
using** (toggling sequencer cells during playback, changing a formula in a live
spreadsheet). Ideas requiring a hard edit/run split (level editors,
compile-and-flash workflows) import the edit-compile-run cycle the environment exists
to abolish. Shallow modality is resolvable — the pencil/eye toggle is the precedent
([`../archive/pencil-eye-edit-mode-toggle-plan.md`](../archive/pencil-eye-edit-mode-toggle-plan.md)),
and it is deliberately a *paint/input* mode only. If an idea needs a different data
model when editing, it mismatches.

**13. Time model — step politely, quarantine the nondeterminism.**
Two sub-questions. (a) Can its process be a `step:` on the world's activity list, a
pure function of event time — so it survives duplication/serialization and stays
deterministic under the macro-test suite? (b) If it genuinely needs hard real-time
(audio sample clock) or the outside world (network feeds), can that be **cornered into
one boundary widget**? The audio shape: the widget world owns the *score* (grid, tempo,
waveform choice — deterministic, testable, serializable) and hands schedule-ahead
instructions across the native floor; sound is actuation, not state. Same shape for a
data feed: one source widget owns the nondeterminism, everything downstream is ordinary
dataflow. Seedable randomness passes cleanly: make the seed a pin, and whether copies
replay or diverge becomes an authorable choice. Nondeterminism that cannot be cornered
(multiplayer) fights the whole test regime.

**14. Feedback latency shape.**
Direct manipulation presumes immediate visible response: what does the user see 50 ms
after every gesture? Value that appears only after long computation (offline renders,
batch exports) is hostile — unless recast as *progressive* (a visibly sharpening
progressive-refinement renderer is charming and at home).

## D. Economy — the one-person system

**15. Simplicity budget — estimate the LOC before falling in love.**
The whole system stays understandable and modifiable by one person
([`design-principles.md`](design-principles.md)); every admission spends a share of
that budget, and an estimated line count is the cheapest honest proxy — make the
estimate part of evaluating the idea, not a discovery after landing it. In-repo
calibration anchors (source `.coffee` lines):

- **~50–150 — a trivial citizen**: `BouncerWdgt` (~50), `MouseSensorWdgt` (~50),
  `PenWdgt` (~150).
- **~300 — a typical self-contained widget**: `AnalogClockWdgt` (~290),
  `SliderWdgt` (~340).
- **~10 — an app that is honest composition**: `FizzyPaintApp` (~10 lines — a
  launcher wiring existing citizens). This is what "app" should usually price at.
- **~600–1800 — a subsystem serving many clients**: the dataflow engine (~600),
  patch programming (~800), the spreadsheet (~1800).
- **~1600–3200 — the outer edge, reserved**: `StringWdgt` (~1600 — text is the
  canonical irreducible), Fizzytiles (~3200, the largest single admission).

Two pricing rules follow. A candidate *app* should estimate like a widget or two plus
a launcher — if the estimate rivals the spreadsheet, the idea is claiming *subsystem*
status and must justify itself as infrastructure with many clients (facet 3's second
customers), not as one app. And LOC in reusable parts prices differently from LOC in a
monolith: five hundred lines as five reusable citizens is budget *invested*; five
hundred lines sealed inside one app is budget *consumed*.

**16. What sinks below the native floor.**
No module system, no runtime npm; metacircularity reaches down to the canvas. Every
external library a candidate requires (codec, strong chess engine, PDF renderer, ML
runtime) is a permanently uninspectable blob below the floor. The SW3D vendoring sets
the bar: acceptable when the vendored thing is small, deterministic, and
comprehensible. Refined rule: **keep the semantics above the floor; push only actuation
below** (a synth's node graph mirrored as widgets above, samples below).

**17. Gesture grammar collision.**
The world has a house grammar: drag = move, drop = embed, right-click = menu,
dwell-to-arm for windows
([`../specs/drag-embed-interaction-spec.md`](../specs/drag-embed-interaction-spec.md)).
Does the idea's primary gesture collide (drag-to-paint, drag-to-aim-camera)?
Collisions are resolvable (the pencil/eye precedent; or claim only clicks, as buttons
do) but each resolution spends UX budget. An idea whose native gestures *coincide* with
the grammar — kanban (moving cards IS dragging widgets), chess (moving pieces IS
dragging widgets) — gets composition for free and feels at home immediately.

**18. The metacircularity dividend.**
The best citizens moonlight as tools for the environment itself: a waveform/envelope
editor is also a general curve editor (easing, pin-to-pin transfer functions); a
toggle-grid is also a pixel-icon editor; an oscilloscope that plots any numeric pin
over time is simultaneously a synth accessory and a debugging instrument for every
dataflow in the world. Ask: does this widget make Fizzygum better at being Fizzygum?

## The quick battery

Ten-second triage for any candidate:

1. Name three parts with second customers.
2. Postcard test — alive and sensible at 200×150 px inside a document?
3. Duplicate it — is the copy meaningful?
4. What is on its pins, in *and* out?
5. Can a spreadsheet drive it, and can it fill one?
6. What does its saved document look like?
7. Is editing it the same activity as using it?
8. What sinks below the floor?
9. Do its native gestures coincide with drag/drop/menu?
10. What is its second life as a tool?
11. Estimate the LOC — does it price like a widget or like a subsystem?

## Worked gradings

**Strong fits** (pass nearly all facets):

- **Oscilloscope / signal probe** — sink for any numeric pin, plots value over time;
  an instrument for the whole world (facet 18 at maximum); tiny; deterministic under
  event time.
- **Envelope/curve editor** — Simple core = point list + interpolation; second
  customers everywhere (synth, easing, transfer functions).
- **Logic-gate / circuit toy** — sibling of `src/patch-programming/`; wholly scalar
  wires; editing is using.
- **Kanban / card wall** — cards are widgets, columns are stacks
  (`SimpleVerticalStackPanelWdgt`); almost pure composition; gestures coincide
  perfectly.
- **Physics toy (masses/springs)** — `BouncerWdgt` is a seed; parameters as pins;
  editing mid-flight is the whole show; the Morphic-lineage classic.
- **Turtle/pen playground** — `PenWdgt` exists; EToys heritage; all five authoring
  rungs.
- **Seedable dice / random-source widget** — trivial, and it makes every other widget
  probabilistically drivable.
- **Timer/stopwatch/countdown family** — pure sources; postcard-perfect; unlimited
  second customers.
- **Tenori-on grid sequencer** — decomposes into three of the above (toggle-grid +
  step-clock + voice): the parts come first, the instrument is their showcase mashup.

**Instructive borderlines** (pass once split along a facet line):

- **Chess** — board and pieces are superb citizens (granularity, gestures, duplication
  all pass); the engine opponent is a below-floor blob. Split: the board is the
  citizen; an opponent is an optional "brain" widget wired by pins — possibly a
  deliberately weak, readable one.
- **Slippy map** — rival geometry inside, redeemed by exporting lat/long/zoom as pins
  so it joins the dataflow (`src/maps/` holds the flat-projection compromise).
- **Sampler / drum machine** — passes everything except the document question (binary
  audio buffers); needs a transient/re-derive serialization design first.
- **Generative-art canvas** — passes if the seed and all parameters are pins; fails if
  it is unseeded randomness all the way down.
- **Progressive ray-tracer postcard** — rival geometry, but tiny, deterministic,
  progressive, SW3D-adjacent; defensible the way Fizzytiles is.

**Mismatches** (fail three or more facets; no split rescues them):

- **Doom port** — rival ontology, zero decomposition, no pins worth having,
  meaningless duplication, modal, giant floor-sink.
- **Web-browser widget** — an entire rival universe below the floor.
- **Video editor** — batch time model, binary-blob documents, fused chrome,
  destination-shaped.
- **Multiplayer anything** — nondeterminism that cannot be cornered into one boundary
  widget.

## Where this binds

These criteria apply the standing principles to the *admission* question; the
principles themselves live in [`design-principles.md`](design-principles.md), the
per-widget obligations in [`widget-citizenship.md`](widget-citizenship.md), and the
content/chrome and naming law in
[`regularity-principles.md`](regularity-principles.md).
