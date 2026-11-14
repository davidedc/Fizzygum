'use strict';
// gate-rules.js — every rule a gate can fail on is NAMED, and its bite-proof must see each one fire.
//
// A gate's bite-proof runs the real gate on a planted input (lib/planted-src.js, Fizzygum-tests/scripts/lib/
// gate-bite-proof.js). Proving "the gate failed" is not proving each RULE bites: a gate grows a rule, the old proof
// still passes, and the new rule is a hypothesis nobody has seen fail. So a gate names its rules here, and the proof
// helpers read the names back:
//
//   const rules = require('./lib/gate-rules').forGate(__filename);
//   violations.push(rules.fired('A_PUBLIC_SETTER', `[A] low-level ${m}() calls …`));   // returns the text unchanged
//   rules.declare(STINKS.map((s) => s.id));                                           // a table-driven gate
//
// WHICH RULES A GATE HAS is read, not listed: every string-literal first argument of a `.fired(` call in the gate's
// own CODE (comments and strings masked by lib/js-mask.js), plus whatever it `declare`s from a table it already keeps.
// A `.fired(` with a computed id must be declared, or the run stops (exit 2): the set the proof is held to is the set
// the gate can actually report.
//
// AN EXIT 1 MUST NAME ITS RULE. On the way out (an `exit` listener, so every path counts: `process.exit(1)`, an
// `exitCode`, an uncaught exception):
//   exit 1, a rule fired     prints `[<gate>] RULES fired: <ids> · of: <ids> · unplantable: <ids>` (the proof reads it)
//   exit 1, no rule fired    RULELESS_FAILURE, exit 2 — a failure no rule names is operational (a crash, a missing
//                            input), never a verdict, and a new failure branch cannot hide outside the registry
//   exit 0, a rule fired     RULE_FIRED_BUT_PASSED, exit 2 — a rule that does not fail the gate is not a rule
//   exit 2, a rule fired     the same RULES line, the exit kept: an INVALID run is no verdict, and a proof holds a
//                            planted INVALID to firing no rule (lib/prove-rules.js), so it must be able to see one
// A rule no plant can reach says why in the gate's header, one line each:
//   // bite-unplantable: <ID> — <reason>
// and the proof does not ask for it. A listed id the gate cannot fire is stale: BITE_UNPLANTABLE_STALE, exit 2, on
// every run (so a removed rule takes its excuse with it).
//
// A GATE'S REPORT REACHES ITS READER WHOLE. A gate run as a program writes its stdout and stderr SYNCHRONOUSLY: on
// macOS a write to a pipe is asynchronous in Node, so a gate that prints its findings and then calls process.exit
// LOSES whatever its reader had not taken yet — all of it, measured, when the reader is slow (a proof's spawn under a
// loaded pool) — while the RULES line, written synchronously at exit, survives: a rule fired with no violation line.
//
// Its proof: lib/gate-rules-selftest.js.

const fs = require('fs');
const path = require('path');
const { maskJs } = require('./js-mask');

const ID = /^[A-Za-z0-9][\w.-]*$/;
const UNPLANTABLE_RE = /^[ \t]*(?:\/\/|#)[ \t]*bite-unplantable:[ \t]*([A-Za-z0-9][\w.-]*)[ \t]+—[ \t]+(\S.*)$/gm;
const RULES_LINE_RE = /^\[([\w.-]+)\] RULES fired: (.*?) · of: (.*?)(?: · unplantable: (.*))?$/m;

// The rule ids a gate's source can fire (literal first arguments of `.fired(` in its code) and the ids it declares
// unplantable, with their reasons.
function readRules(text) {
  const { mask } = maskJs(text);
  const literal = new Set();
  for (const m of text.matchAll(/\.fired\(\s*(['"])([^'"\n]+)\1/g)) {
    if (mask[m.index] !== 'code') continue;
    literal.add(m[2]);
  }
  const unplantable = new Map();
  for (const m of text.matchAll(UNPLANTABLE_RE)) unplantable.set(m[1], m[2].trim());
  return { literal, unplantable };
}

// The machine line a failing gate prints, read back: { gate, fired, of, unplantable } or undefined. Given `gate`, the
// line of THAT gate: a gate that runs another (an audit gate tees its embedded suite run) prints the inner one's line
// too, and the first line in the output is then not the gate's own.
function parseRulesLine(out, gate) {
  for (const m of String(out || '').matchAll(new RegExp(RULES_LINE_RE.source, 'gm'))) {
    if (gate !== undefined && m[1] !== gate) continue;
    const ids = (s) => new Set((s || '').split(' ').filter(Boolean));
    return { gate: m[1], fired: ids(m[2]), of: ids(m[3]), unplantable: ids(m[4]) };
  }
  return undefined;
}

// The exit line must REACH its reader. On the way out fd 1 can be a non-blocking pipe still full of the report the gate
// just flushed (a big one — the census prints a thousand offender lines), and writeSync then throws EAGAIN: retried
// after a short nap, for up to two seconds, rather than lost — a lost RULES line reads as a gate that named no rule.
// A closed pipe (EPIPE) or anything else ends the attempt. (Fizzygum-tests/scripts/lib/audited-suite.js relays its
// embedded suite's output through it too.)
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

function forGate(file, { name } = {}) {
  const gate = name || path.basename(file).replace(/\.(js|sh)$/, '');
  let text;
  try { text = fs.readFileSync(file, 'utf8'); } catch (e) {
    console.error(`[${gate}] gate-rules: cannot read the gate's own source ${file}: ${e.message}`);
    process.exit(2);
  }
  const { literal, unplantable } = readRules(text);
  const declared = new Set(literal);
  const fired = new Set();
  const stop = (msg) => { writeAll(2, `[${gate}] ${msg}\n`); process.exit(2); };

  const api = {
    gate,
    fired(id, text) {
      if (!ID.test(String(id))) stop(`gate-rules: a rule id must be a word (${JSON.stringify(id)})`);
      if (!declared.has(id)) stop(`gate-rules: rule '${id}' fired but is neither a literal .fired( id nor declared — declare the table it comes from`);
      fired.add(id);
      return text;
    },
    declare(ids) {
      for (const id of ids) {
        if (!ID.test(String(id))) stop(`gate-rules: a declared rule id must be a word (${JSON.stringify(id)})`);
        declared.add(id);
      }
      return api;
    },
    get firedIds() { return new Set(fired); },
    get ids() { return new Set(declared); },
  };

  // The verdict is the GATE's: a gate required as a library (a self-test exercising its exported engine) keeps the
  // registry but leaves its host's exit alone.
  const isMain = !!require.main && path.resolve(require.main.filename) === path.resolve(file);
  if (isMain) {
    for (const stream of [process.stdout, process.stderr]) {
      if (stream._handle && typeof stream._handle.setBlocking === 'function') stream._handle.setBlocking(true);
    }
  }
  if (isMain) process.on('exit', (code) => {
    const write = (fd, s) => writeAll(fd, s + '\n');
    const stale = [...unplantable.keys()].filter((id) => !declared.has(id));
    if (stale.length) {
      write(2, `[${gate}] BITE_UNPLANTABLE_STALE ${stale.join(' ')} — the header says no plant reaches it, but the gate cannot fire it: delete the line`);
      process.exitCode = 2;
      return;
    }
    if (code === 1 && !fired.size) {
      write(2, `[${gate}] RULELESS_FAILURE — it exited 1 without naming a rule (gate-rules): a failure no rule names is operational, so this run reads as exit 2`);
      process.exitCode = 2;
      return;
    }
    if (code === 0 && fired.size) {
      write(2, `[${gate}] RULE_FIRED_BUT_PASSED ${[...fired].join(' ')} — a rule fired and the gate exited 0: a rule that does not fail the gate is not a rule`);
      process.exitCode = 2;
      return;
    }
    if (code === 1 || (code === 2 && fired.size)) {
      const plantable = [...declared].filter((id) => !unplantable.has(id));
      write(1, `[${gate}] RULES fired: ${[...fired].join(' ')} · of: ${plantable.join(' ')}` +
               (unplantable.size ? ` · unplantable: ${[...unplantable.keys()].join(' ')}` : ''));
    }
  });
  return api;
}

module.exports = { forGate, readRules, parseRulesLine, RULES_LINE_RE, writeAll };
