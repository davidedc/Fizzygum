# Vendored acorn — a JavaScript parser for the build's static gates (build-time only)

`acorn.js` is **acorn 8.19.0**'s `dist/acorn.js` (its self-contained UMD build, no dependencies), copied verbatim
from the npm package `acorn@8.19.0`:

- source tarball: `https://registry.npmjs.org/acorn/-/acorn-8.19.0.tgz`
  (integrity `sha512-oJlA3XiRm7Cyk6qFD2Jn8ak9B7jSy0qy00ADO3+8dpT0LSjFihQYv4C02LFCSYJV3Q37xYwwRy5m+IpIiUzqWw==`, checked
  against the downloaded tarball)
- sha256 of `acorn.js`: `b95392d79457d0357555c5ed3e56302d074b92dff119bcf3b44179500b10e9df`
- license: MIT — `LICENSE`, copied from the same package.

Its readers parse with `ecmaVersion: 'latest'`: what Node runs, the build must read — a rig written with class
fields or a `#private` member would otherwise stop every gate that masks the tests repo's scripts.

**Do not hand-edit either file.** To move to another release, replace both from that release's tarball (check its
integrity against the registry's), update the facts above, and run every gate's self-test
(`node buildSystem/run-selftests.js`).

**Who reads it:** the build's Node tooling only — `buildSystem/lib/js-mask.js` (what in a JavaScript text is code,
string or comment, and where its template literals are) and `buildSystem/lib/call-sites.js` (every call site in the
tests repo's scripts, for `check-argument-holes.js`). Nothing in `src/` or the harness requires it and no part in
`buildSystem/parts.json` names it, so it never reaches a browser: code that RUNS in Fizzygum is hand-written and
minimal, while the build's tooling may use a pinned library where a real parser beats a hand-rolled one.

**Why vendored, not an npm dependency:** the build needs no `npm i` in `Fizzygum/` — every gate runs on Node
alone. `vendor/` is read only through explicit lists (`parts.json` vendor entries, the SWCanvas lines of
`build_it_please.sh`), so no gate walks this directory.
