# `nil` global — retirement

**Status: DONE, 2026-08-13.** Landed in five commits across two repos:
`Fizzygum` a8a9c731 (step 1), eb063b3d (step 2), 92a010a4 (phase 3a), 6f19fb54 (phase 3c);
`Fizzygum-tests` 73bd57cbe, 56cde8fcd (recaptures), c943ee6f5 (phase 3b).
Present-tense residue: the `undefined`-is-the-one-absence-value convention and the
`nil-literal` / `null-literal` stinks, in `CLAUDE.md` and `architecture/lint-and-static-checks.md`.

## What `nil` was, and why it existed

`src/boot/globalFunctions.coffee` defined `nil = undefined`, and the codebase used `nil`
everywhere in place of `null`/`undefined` — about 2000 sites across both repos.

It was introduced by commit `3d43e902` (5 Dec 2017), *"using Coffeescript 2 for
fine-granularity compilation of classes. Needed to replace all `null`s with `nil`s (which
are really `undefined`s)"* — 116 files, +1039/−1018.

The cause is a genuine semantic change in the CoffeeScript 1 → 2 upgrade, which the
project needed so the meta-system could compile class fragments. CoffeeScript 1 desugared
default parameters to a `null`-loose check; CoffeeScript 2 emits native ES2015 defaults,
which fire on `undefined` only:

```
CoffeeScript 1.12.7              CoffeeScript 2.7.0
f = function(a) {                f = function(a = 42) {
  if (a == null) a = 42;           return a;
  return a;                      };
};

CS1: f(null)=42   f(undefined)=42
CS2: f(null)=null f(undefined)=42     <- the break
```

The codebase leaned on the idiom "pass `null` in a slot to mean *give me the default*", so
under CS2 every such call site silently passed a real `null` through. The fix was the
cheapest available: define `nil = undefined` and text-replace `null` → `nil`. Because `?`,
`?.` and `?=` are null-agnostic, nothing else could tell the difference, so a blind replace
was safe. (It was blind: it also rewrote e.g. `predicate.call null, element`, where the two
are identical anyway.)

## Why it was retired

The workaround stopped being load-bearing years ago — by 2026 only about a dozen call sites
in `src` still relied on absence-triggers-default. What remained was an **alias for a
language primitive**, which is a smell independent of churn:

1. **The ledger is upside down.** It cost a global, a boot-order dependency (it had to exist
   before any class source compiled), a lint rule, and a paragraph in two CLAUDE.mds. It
   bought six characters.
2. **A writable global pretending to be a constant.** The boot bundle is `coffee -b`
   compiled, so `nil = undefined` landed as a top-level `var nil` on `window` — anything
   could overwrite it, and a file that top-level-assigned `nil` would silently shadow it for
   that whole file. `undefined` compiles to `void 0`, which cannot be shadowed or reassigned.
3. **The name means the opposite thing to this codebase's likeliest reader.** Fizzygum
   descends from Morphic ← Smalltalk, where `nil` *is* the null object; likewise Ruby, ObjC,
   Lisp, Go. This was the one place it meant `undefined`.
4. **It had leaked into the reflective layer** — the decisive one. `ClassInspectorWdgt`
   emitted the literal token `"nil"` as *generated CoffeeScript source*
   (`applyMemberEdit prop, "nil"`), which the meta-system then compiled. A live-editing
   system that can only emit code requiring a global it also defines is a circular
   dependency with no upside.

## How it was done

Ordered so the semantics moved before the name, and so every step had a working gate.

- **Step 1 — remove the call sites that depend on "pass a hole, get the default."** Ten of
  twelve, by reordering optional parameters most-specified-first so a caller can stop passing
  arguments instead of filling slots (`measureText`, the
  `syntheticEventsMouseMove_InputEvents` family). ⭐ All 199 test call sites of the latter
  pass ≤3 arguments, so reordering params 4–6 was invisible to the suite.
- **Step 2 — delete 41 dead `= nil` default parameters.** `(a = nil) ->` compiles to
  `(a = void 0) ->`: a default that assigns `undefined` when the argument is already
  `undefined`.
- **Step 3 — the rename**, in three phases, keeping `nil = undefined` defined until the end:
  3a `src` (1510 sites), 3b harness + tests + rigs (469 sites), 3c delete the global and
  invert the lint.

## What was learned (the reusable parts)

- ⭐⭐ **A naive `\bnil\b` → `undefined` replace is NOT sufficient.** Four distinct classes
  escape it: `"nil"` **string literals** (one of which was emitted source and *had* to
  change); **prose broken by substitution** (`a undefined`, `undefined'd`); `nils` used as a
  **verb**; and **uppercase** `NIL`/`NILs`/`Nil-ing` emphasis, which a correctly
  case-sensitive sweep skips but which mean the same value.
- ⭐⭐ **Deleting a `= nil` default does NOT disarm the `@param` trap.** `constructor: (@x) ->`
  compiles to `this.x = x`, so constructing with no argument writes `undefined` over the
  prototype default just as `(@x = nil)` did. The hazard is the `@param`, not the default —
  a claim to the contrary was made in eb063b3d's commit message and is wrong.
- ⭐ **The source-DISPLAY surface is far narrower than the source-TEXT surface.** Rewriting
  ~1500 lines of class source moved exactly ONE test, because the inspector renders source
  only for the *member selected*, and across 294 tests few members are ever selected. Do not
  budget mass recapture for a source-wide edit on this reasoning alone.
- ⭐ **A recapture must be proven, not assumed.** Two tests moved during this arc; each cause
  was established before recapturing — one by bisect (revert the single suspect line, keep
  the other 40 changes, confirm the images pass again), one because the test's own assertion
  text named the string that changed. Recapturing on a hypothesis is how a real bug gets
  baked into a reference.
- ⭐ **The rename turns a disguised smell into a visible one.** `new SliderWdgt nil, nil, nil,
  nil, nil, true` reads as house idiom; the same call spelled with `undefined` reads as what
  it is. That is an argument for renaming BEFORE fixing the remaining positional-hole APIs,
  not after.

## Found on the way, still open

- **`SliderWdgt`** — 8 hole-passing construction sites in two groups wanting disjoint trailing
  parameters. No reordering helps; it wants `constructor: (opts = {})`.
- **The `add` family** — four overrides carry a parameter literally named `unused`, while
  `FrameWdgt.add` gives that same fifth positional slot the meaning `notContent`. One
  positional call therefore means different things per receiver. This is a latent bug
  independent of `nil` and deserves its own investigation, not a cleanup pass.

## Fixed on the way

A live bug, in one of the ten tolerated `null` literals: `DemoMenus` built
`new SimpleVerticalStackPanelWdgt null, null, null, false` against
`constructor: (extent, color, @padding = 5, @constrainContentWidth = true)`. `padding` has no
prototype default and `null` does not trigger an ES2015 default, so that demo ran with
`@padding = null` — coerced to 0 through the eight arithmetic sites reading it — instead of 5.
Precisely the breakage the `nil` convention existed to prevent, still alive nine years later.
`extent`/`color` are guarded with `?`, so only `padding` broke.
