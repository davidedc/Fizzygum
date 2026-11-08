# Vendored CoffeeScript compiler

`fizzygum-coffeescript-min.js` is the CoffeeScript compiler Fizzygum loads in the browser at
boot to compile its class sources (`src/boot/globalFunctions.coffee` loads it; it ships as an asset of
the `core` part, `buildSystem/parts.json`, which `build.py` copies into `js/libs/`; the build tools that run
the meta-system — the syntax gate among them — `require()` it through `buildSystem/lib/meta-compiler.js`).

It is a **minimal, compile-only fork of CoffeeScript 2.0.3** that emits byte-for-byte identical
JavaScript to stock 2.0.3 for the subset Fizzygum uses, at ~19% smaller size (no Babel-ES5, no
CLI/browser/repl/sourcemap/JSX/import-export/literate machinery). Fizzygum's whole CoffeeScript
API surface at run time is two calls — `CoffeeScript.compile(source, {bare: true})`, and the lexer's
`CoffeeScript.tokens(source)`, which the meta-system's super rewrite reads (`Class.rewriteSuperCalls`
in `src/meta/Class.coffee`) — and the build tooling adds a third, the parser's `CoffeeScript.nodes(source)`
(`buildSystem/lib/call-sites.js`, the call-arguments gate's reader). None of the removed machinery is
reachable. A rebuild must keep all three exported (`tokens` and `nodes` cost nothing: compile runs the
same lexer and parser); `buildSystem/lib/meta-compiler-selftest.js` and `lib/call-sites-selftest.js` fail
the build without them.

**Source of truth / how to update it:** it is built by the standalone package
[`fizzygum-coffeescript-min`](https://github.com/davidedc/fizzygum-coffeescript-min) (its own
repo; also on npm). To change the compiler, edit/rebuild there (`npm run build && npm run verify`)
and copy its `dist/coffeescript.js` over this file. Do not hand-edit this file — it is generated
and minified.

**Regression gate:** any change here must keep the full `fg gauntlet` green — the pixel-exact
SystemTest references were captured with this compiler's output, so a codegen change would show
up as screenshot diffs.
