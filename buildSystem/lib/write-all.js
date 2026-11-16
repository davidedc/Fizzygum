'use strict';
// write-all.js — a whole text to a descriptor, synchronously, so it lands in order with what the programs the writer
// launches write to the same descriptor. Kept apart from lib/gate-rules.js (which re-exports it) because that module
// loads acorn, and the build writes before it has checked that acorn is installed.
//
// The line must REACH its reader. fd 1 can be a non-blocking pipe still full of what a program just flushed (a big
// report — the census prints a thousand offender lines), and writeSync then throws EAGAIN: retried after a short nap,
// for up to two seconds, rather than lost — a lost RULES line reads as a gate that named no rule. A closed pipe (EPIPE)
// or anything else ends the attempt. (Fizzygum-tests/scripts/lib/audited-suite.js relays its embedded suite's output
// through it too.)
const fs = require('fs');

function writeAll(fd, s) {
  const buf = Buffer.from(s);
  const nap = new Int32Array(new SharedArrayBuffer(4));
  let off = 0, waited = 0;
  while (off < buf.length) {
    try { off += fs.writeSync(fd, buf, off); } catch (e) {
      if (e.code !== 'EAGAIN' || waited >= 2000) return;
      Atomics.wait(nap, 0, 0, 10);
      waited += 10;
    }
  }
}

module.exports = { writeAll };
