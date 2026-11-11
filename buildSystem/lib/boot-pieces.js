'use strict';
// boot-pieces.js — the src/boot files, as the ONE listing gives them: build.py --list-boot, which reads them from
// parts.json (each part's `bootPrelude` and `bootScripts`) and refuses a malformed declaration. → [{ file, part, kind }],
// `file` spelled as parts.json spells it ("src/boot/…"), `kind` "prelude" (a piece of the boot bundle, in force before
// any class compiles) or "script" (compiled alone to js/src/<name>-min.js and fetched by name later). `buildArgs` are
// the caller's own listing rails (--src=, --parts=, --tests-repo=), so a bite-proof's planted tree is listed as it is.
// Throws when build.py refuses. Read by check-shippable-coverage (the files, and the scripts boot fetches by name),
// check-coffee-syntax (core's files: the helper globals, which a core boot script assigns), check-part-edges (each
// file's part) and what-pins-core (its roots: core's files and every shipped part's bundle pieces).
const { execFileSync } = require('child_process');
const path = require('path');

const REPO = path.resolve(__dirname, '..', '..');

function bootPieces(buildArgs = []) {
  const out = execFileSync('python3', ['-B', 'buildSystem/build.py', '--list-boot', ...buildArgs], { cwd: REPO, encoding: 'utf8' });
  return out.split('\n').filter(Boolean).map((line) => {
    const [file, part, kind] = line.split('\t');
    return { file, part, kind };
  });
}

// where a piece is on disk, in the tree `srcRoot` (the real src, or a planted copy)
const onDiskIn = (srcRoot, piece) => path.join(srcRoot, piece.file.slice('src/'.length));

module.exports = { bootPieces, onDiskIn };
