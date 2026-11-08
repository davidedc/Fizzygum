'use strict';
// allowlist-file.js — the ONE reader of a gate's allowlist file (buildSystem/*-allowlist.txt): one entry per line,
// written `name  # reason`; a `#` begins a comment to the end of its line, so a comment-only or blank line holds no
// entry. (The format is the file's own, plain text — not CoffeeScript, whose reading is lib/coffee-mask.js's.)
//
// readAllowlist(file) -> Map(name -> its reason, '' when the line gives none), in file order; an empty Map when
// the file does not exist. Readers: check-dead-methods.js (dead-method-allowlist.txt), check-call-separation.js
// (public-api-allowlist.txt), check-unresolved-sends.js (unresolved-sends-allowlist.txt) and their self-tests.
// Cases: lib/allowlist-file-selftest.js.

const fs = require('fs');

function readAllowlist(file) {
  const entries = new Map();
  if (!fs.existsSync(file)) return entries;
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const hash = line.indexOf('#');
    const name = (hash < 0 ? line : line.slice(0, hash)).trim();
    if (name) entries.set(name, hash < 0 ? '' : line.slice(hash + 1).trim());
  }
  return entries;
}

module.exports = { readAllowlist };
