# Vendored CoffeeScript compiler

`fizzygum-coffeescript-min.js` is the CoffeeScript compiler Fizzygum loads in the browser at
boot to compile its ~470 class sources (`src/boot/globalFunctions.coffee` loads it; the build
copies it into `js/libs/` via `build_it_please.sh`; the syntax gate `require()`s it in
`buildSystem/check-coffee-syntax.js`).

It is a **minimal, compile-only fork of CoffeeScript 2.0.3** that emits byte-for-byte identical
JavaScript to stock 2.0.3 for the subset Fizzygum uses, at ~19% smaller size (no Babel-ES5, no
CLI/browser/repl/sourcemap/JSX/import-export/literate machinery). Fizzygum's whole CoffeeScript
API surface is one call — `CoffeeScript.compile(source, {bare: true})` — so none of the removed
machinery is reachable.

**Source of truth / how to update it:** it is built by the standalone package
[`fizzygum-coffeescript-min`](https://github.com/davidedc/fizzygum-coffeescript-min) (its own
repo; also on npm). To change the compiler, edit/rebuild there (`npm run build && npm run verify`)
and copy its `dist/coffeescript.js` over this file. Do not hand-edit this file — it is generated
and minified.

**Regression gate:** any change here must keep the full `fg gauntlet` green — the pixel-exact
SystemTest references were captured with this compiler's output, so a codegen change would show
up as screenshot diffs.
