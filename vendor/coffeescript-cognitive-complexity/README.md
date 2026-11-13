# Vendored coffeescript-cognitive-complexity — the complexity ratchet's analyzer (build-time only)

`index.js` is **coffeescript-cognitive-complexity 1.0.0**'s `index.js` (the analyzer; its `cli.js` is not vendored),
copied verbatim from the npm package `coffeescript-cognitive-complexity@1.0.0`, the project owner's own package:

- source tarball: `https://registry.npmjs.org/coffeescript-cognitive-complexity/-/coffeescript-cognitive-complexity-1.0.0.tgz`
  (integrity `sha512-HjTxjmlsSBWR/V52TaGWe26zVqyyVJXu9sAxNnphf2pL0N1zvLRZwpqvi8ymCtykizAzxfBQZ517l8Ho07qKJA==`, as
  `package-lock.json` records it)
- sha256 of `index.js`: `89f9dc0d4a3855cb2bada32d9840d9048f3da4c9cd2ecfc383c0b943c6974479`
- license: MIT — `LICENSE`, copied from the same package.

It measures SonarSource's Cognitive Complexity (rule S3776) on the CoffeeScript AST. It walks that AST by node CLASS
NAME, so it needs a CoffeeScript whose node classes keep their names: the build's own minified compiler
(`vendor/coffeescript/`) does not, so `buildSystem/lib/cognitive-complexity.js` loads this file with its one
`require("coffeescript")` answered by the CoffeeScript the build already requires globally (`build_it_please.sh` runs
its `coffee` to compile the boot files) — and only at the version a caller's numbers were measured on (2.7.0 for the
ratchet gate), found behind a `coffee` on PATH or in Node's global prefix: a different version's AST may score
differently, so another is passed over, and with none found the gate reads INVALID.

**Do not hand-edit either file.** To move to another release, replace both from that release's tarball (check its
integrity against the registry's), update the facts above, and run every gate's self-test
(`node buildSystem/run-selftests.js`).

**Who reads it:** the build's Node tooling only — `buildSystem/check-complexity-ratchets.js`, through
`buildSystem/lib/cognitive-complexity.js`. `fg cc` (the human's report) runs the npm package's own CLI.
