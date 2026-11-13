'use strict';
// ---------------------------------------------------------------------------
// Cognitive Complexity for CoffeeScript
//
// A native implementation of SonarSource's Cognitive Complexity metric
// (G. Ann Campbell, 2017/2023 white paper, rule S3776) that walks the REAL
// CoffeeScript AST (`require('coffeescript').nodes(src)`) rather than measuring
// compiled-to-JS output. Working on the source AST is what lets us honour the
// spec's "ignore readable shorthand" rule for the constructs CoffeeScript adds:
// the existential operator `?`, soaks `a?.b`, and `?=`/`or=` compound assigns
// never increment — whereas they compile to `if`/`&&` guards that a JS analyser
// would (wrongly) charge for, and comprehensions expand to an IIFE+loop+guard.
//
// The three spec rules:
//   1. Ignore structures that shorthand many statements into one (methods,
//      null-coalescing).
//   2. +1 for each break in linear flow (if/loop/switch/catch/logical-seq/
//      recursion).
//   3. +1 extra per level of nesting a flow-break structure sits inside.
//
// Ternary vs. statement-if is decided exactly the way the CoffeeScript compiler
// decides `a?b:c` vs `if(){}else{}`: an `if/then/else` is a ternary (a single
// increment, no separate `else`) only when its value is consumed in expression
// position AND both branches are single expressions; a function-tail or
// standalone `if/else` is a statement (`if` +1, `else`/`else if` +1 each).
// ---------------------------------------------------------------------------

let CoffeeScript;
try {
  CoffeeScript = require("coffeescript");
} catch (e) {
  throw new Error(
    "coffeescript-cognitive-complexity: could not load its \"coffeescript\" dependency — run \"npm install\"."
  );
}

const DEFAULT_OPTIONS = {
  // How to treat CoffeeScript comprehensions (a `for` used as a value, e.g.
  // `evens = (x for x in xs when x % 2 is 0)`):
  //   'loop'      – spec-literal: a comprehension IS a loop → +1 (+nesting),
  //                 and its `when` guard is a nested conditional → +1 more.
  //                 Mirrors the control flow the compiler emits (IIFE+for+if).
  //   'shorthand' – treat like `.filter().map()`: the iteration itself is free
  //                 (0); only genuine control flow / logical sequences inside
  //                 the body or guard still count (one nesting level in).
  //   'off'       – comprehensions contribute nothing and add no nesting.
  // Statement-position `for`/`while` loops ALWAYS score as loops regardless.
  comprehensions: 'loop',

  // Complexity-neutral shim for CoffeeScript-1-style bare `super` (which forwards
  // the caller's arguments). Vanilla CoffeeScript 2 rejects it, so a source that
  // uses it — e.g. the Fizzygum framework — otherwise fails to parse. Rewriting a
  // stand-alone `super` to `super()` makes it parse and does not change the score
  // (both are a bare call). It is a no-op on code that has no bare `super`, so it
  // is safe to leave on. Set false for strict vanilla-CS2 parsing only.
  superShim: true,
};

// CS1-style bare `super` (forwards args) → `super()`, ONLY when `super` stands
// alone on a line (optionally before a comment). `super(...)`, `super arg`, and
// `super.x` are left untouched. Complexity-neutral (a call either way).
function applySuperShim(src) {
  return src.replace(/\bsuper\b(?=[ \t]*(?:#.*)?$)/gm, 'super()');
}

// --- tiny AST helpers -------------------------------------------------------

const typeOf = (n) => (n && n.constructor && n.constructor.name) || null;
const line1 = (n) =>
  (n && n.locationData && typeof n.locationData.first_line === 'number')
    ? n.locationData.first_line + 1
    : 0;

function eachChild(node, fn) {
  if (node && typeof node.eachChild === 'function') node.eachChild((c) => { fn(c); return true; });
}

// Name bound by an assignment target, for method/recursion attribution.
//  `name = ->`  → "name"   `foo: ->` → "foo"   `@method = ->` / `A.b = ->` → last
function assignTargetName(valueNode) {
  if (!valueNode) return null;
  const props = valueNode.properties;
  if (props && props.length) {
    const last = props[props.length - 1];
    if (last && last.name && last.name.value != null) return String(last.name.value);
    return null;
  }
  const base = valueNode.base || valueNode;
  const t = typeOf(base);
  if ((t === 'IdentifierLiteral' || t === 'PropertyName') && base.value != null) return String(base.value);
  return null;
}

// The name a Call invokes, for direct-recursion detection.
//  `fact(n)` → {name:"fact"}   `@method(x)` / `this.method(x)` → {name:"method"}
function calleeName(call) {
  const v = call && call.variable;
  if (!v) return null;
  const props = v.properties;
  if (props && props.length) {
    const last = props[props.length - 1];
    if (last && last.name && last.name.value != null) return { name: String(last.name.value) };
    return null;
  }
  const base = v.base || v;
  if (typeOf(base) === 'IdentifierLiteral' && base.value != null) return { name: String(base.value) };
  return null;
}

const isSingleIf = (block) =>
  block && Array.isArray(block.expressions) &&
  block.expressions.length === 1 && typeOf(block.expressions[0]) === 'If';

// A branch (Block) is "simple" if it holds exactly one expression — the
// condition under which the compiler will build a `?:` instead of an if-stmt.
const branchSimple = (block) =>
  !!(block && Array.isArray(block.expressions) && block.expressions.length === 1);

// Would this If compile to a ternary (given it is in value position)?
function simpleBranches(ifNode) {
  if (!branchSimple(ifNode.body)) return false;
  const eb = ifNode.elseBody;
  if (!eb) return true;
  if (!branchSimple(eb)) return false;
  const only = eb.expressions[0];
  if (typeOf(only) === 'If') return simpleBranches(only);   // chained ternary link
  return true;
}

// ---------------------------------------------------------------------------

class Analyzer {
  constructor(options) {
    this.opts = Object.assign({}, DEFAULT_OPTIONS, options || {});
    this.functions = [];                       // one record per top-level function/method
    this.fileLevel = { name: '<file top-level>', klass: null, line: 1, increments: [], recursion: false, names: [] };
    this.current = this.fileLevel;             // bucket receiving increments right now
    this.currentClass = null;                  // enclosing class name, for grouping
    this.currentFnNames = [];                  // names the enclosing method is known by (recursion)
    this.pendingName = null;                   // name to attach to the next Code we descend into
  }

  add(delta, ln, reason, nesting) {
    if (delta <= 0) return;
    this.current.increments.push({ delta, line: ln, reason, nesting });
  }

  // --- dispatch -------------------------------------------------------------
  visit(node, ctx) {
    if (!node || typeof node !== 'object') return;
    switch (typeOf(node)) {
      case 'Root':   return node.body ? this.visitBlock(node.body, stmtAt(ctx, ctx.nesting))
                                      : eachChild(node, (c) => this.visit(c, withStatement(ctx, true)));
      case 'Block':  return this.visitBlock(node, ctx);
      case 'If':     return this.visitIf(node, ctx);
      case 'While':  return this.visitWhile(node, ctx);
      case 'For':    return this.visitFor(node, ctx);
      case 'Switch': return this.visitSwitch(node, ctx);
      case 'Try':    return this.visitTry(node, ctx);
      case 'Code':   return this.visitCode(node, ctx);
      case 'Class':  return this.visitClass(node, ctx);
      case 'Assign': return this.visitAssign(node, ctx);
      case 'Op':
        if (node.operator === '&&' || node.operator === '||') { this.countLogical(node, null, ctx); return; }
        break; // other operators (?, arithmetic, comparison, !, ++): fall through
      case 'Call':
        if (this.currentFnNames.length) {
          const cn = calleeName(node);
          if (cn && this.currentFnNames.indexOf(cn.name) !== -1) this.current.recursion = true;
        }
        break; // then recurse generically into callee + args
    }
    // generic: descend; everything below a non-block node is expression position
    eachChild(node, (c) => this.visit(c, withStatement(ctx, false)));
  }

  // A block's value is used iff it was reached in expression position — then
  // (only) its final expression is in value position; the rest are statements.
  visitBlock(block, ctx) {
    const exprs = block && block.expressions;
    if (!Array.isArray(exprs)) return;
    const valueBlock = ctx.statement === false;
    exprs.forEach((e, i) => {
      const stmt = !(valueBlock && i === exprs.length - 1);
      this.visit(e, withStatement(ctx, stmt));
    });
  }

  // --- if / else if / else / ternary ---------------------------------------
  visitIf(node, ctx) {
    const n = ctx.nesting;
    const ternary = ctx.statement === false && simpleBranches(node);
    this.add(1 + n, line1(node), ternary ? 'ternary' : 'if', n);        // structural (+nesting)
    if (node.condition) this.visit(node.condition, exprAt(ctx, n));      // boolean seqs / nested flow
    if (node.body) this.visitBlock(node.body, ternary ? exprAt(ctx, n + 1) : stmtAt(ctx, n + 1));
    this.handleElse(node, ctx, ternary);
  }

  handleElse(ifNode, ctx, ternary) {
    const eb = ifNode.elseBody;
    if (!eb) return;
    const n = ctx.nesting;                 // the chain's base nesting
    if (!ternary) {
      if (ifNode.isChain && isSingleIf(eb)) {
        const inner = eb.expressions[0];
        this.add(1, line1(inner), 'else if', n);                         // hybrid (+1, no nesting)
        if (inner.condition) this.visit(inner.condition, exprAt(ctx, n));
        if (inner.body) this.visitBlock(inner.body, stmtAt(ctx, n + 1));
        this.handleElse(inner, ctx, false);                              // continue statement chain
      } else {
        this.add(1, line1(eb), 'else', n);                               // hybrid (+1, no nesting)
        this.visitBlock(eb, stmtAt(ctx, n + 1));                         // nested if here nests deeper
      }
    } else {
      if (isSingleIf(eb)) this.visitIf(eb.expressions[0], exprAt(ctx, n + 1)); // nested ternary, deeper
      else this.visitBlock(eb, exprAt(ctx, n + 1));                            // plain expression else
    }
  }

  // --- while / until / loop -------------------------------------------------
  visitWhile(node, ctx) {
    const n = ctx.nesting;
    this.add(1 + n, line1(node), 'while', n);
    if (node.condition) this.visit(node.condition, exprAt(ctx, n));
    if (node.guard) this.visit(node.guard, exprAt(ctx, n));
    if (node.body) this.visitBlock(node.body, stmtAt(ctx, n + 1));
  }

  // --- for loops and comprehensions ----------------------------------------
  visitFor(node, ctx) {
    const n = ctx.nesting;
    const isComprehension = ctx.statement === false;   // its resulting array is used
    const mode = this.opts.comprehensions;

    let loopInc, bodyN, guardStructural;
    if (!isComprehension || mode === 'loop') { loopInc = 1 + n; bodyN = n + 1; guardStructural = true; }
    else if (mode === 'shorthand')           { loopInc = 0;     bodyN = n + 1; guardStructural = false; }
    else /* 'off' */                          { loopInc = 0;     bodyN = n;     guardStructural = false; }

    if (loopInc > 0) this.add(loopInc, line1(node), isComprehension ? 'comprehension' : 'for', n);
    if (node.source) this.visit(node.source, exprAt(ctx, n));           // nested comprehension in iterable
    if (node.guard) {
      if (guardStructural) this.add(1 + bodyN, line1(node.guard), 'comprehension guard', bodyN);
      this.visit(node.guard, exprAt(ctx, bodyN));
    }
    if (node.body) this.visitBlock(node.body, isComprehension ? exprAt(ctx, bodyN) : stmtAt(ctx, bodyN));
  }

  // --- switch ---------------------------------------------------------------
  visitSwitch(node, ctx) {
    const n = ctx.nesting;
    this.add(1 + n, line1(node), 'switch', n);   // whole switch = ONE structural increment
    if (node.subject) this.visit(node.subject, exprAt(ctx, n));
    for (const c of (node.cases || [])) {
      // a SwitchWhen holds condition expr(s) + a body Block; walk each in role
      // without relying on exact field names.
      eachChild(c, (ch) => {
        if (typeOf(ch) === 'Block') this.visitBlock(ch, stmtAt(ctx, n + 1));
        else this.visit(ch, exprAt(ctx, n));     // `when a`, `when a, b`
      });
    }
    if (node.otherwise) this.visitBlock(node.otherwise, stmtAt(ctx, n + 1));
  }

  // --- try / catch / finally ------------------------------------------------
  visitTry(node, ctx) {
    const n = ctx.nesting;
    if (node.attempt) this.visitBlock(node.attempt, stmtAt(ctx, n));    // try adds no nesting
    if (node.catch) {
      this.add(1 + n, line1(node.catch), 'catch', n);
      if (node.catch.recovery) this.visitBlock(node.catch.recovery, stmtAt(ctx, n + 1));
    }
    if (node.ensure) this.visitBlock(node.ensure, stmtAt(ctx, n));      // finally: ignored
  }

  // --- functions ------------------------------------------------------------
  visitCode(node, ctx) {
    if (ctx.funcDepth === 0) {
      // A top-level function/method: no structural increment, opens its own
      // score with nesting reset to 0.
      const rec = {
        name: this.pendingName || '(anonymous)',
        klass: this.currentClass,
        line: line1(node),
        increments: [],
        recursion: false,
        names: this.pendingName ? [this.pendingName] : [],
      };
      this.functions.push(rec);
      const prevCur = this.current, prevNames = this.currentFnNames, prevPending = this.pendingName;
      this.current = rec;
      this.currentFnNames = rec.names;
      this.pendingName = null;
      if (node.body) this.visitBlock(node.body, { nesting: 0, funcDepth: 1, statement: true });
      if (rec.recursion) this.add(1, rec.line, 'recursion', 0);          // fundamental (+1)
      this.current = prevCur;
      this.currentFnNames = prevNames;
      this.pendingName = prevPending;
    } else {
      // A nested function/lambda: no structural increment, but it raises the
      // nesting level for any flow-break structures inside it.
      const prevPending = this.pendingName;
      this.pendingName = null;
      if (node.body) this.visitBlock(node.body, { nesting: ctx.nesting + 1, funcDepth: ctx.funcDepth + 1, statement: true });
      this.pendingName = prevPending;
    }
  }

  visitClass(node, ctx) {
    const prev = this.currentClass;
    this.currentClass = assignTargetName(node.variable) || '(anonymous class)';
    if (node.body) this.visitBlock(node.body, stmtAt(ctx, ctx.nesting));
    this.currentClass = prev;
  }

  visitAssign(node, ctx) {
    const prevPending = this.pendingName;
    this.pendingName = assignTargetName(node.variable);   // seen by a Code value below
    if (node.variable) this.visit(node.variable, exprAt(ctx, ctx.nesting));
    if (node.value) this.visit(node.value, exprAt(ctx, ctx.nesting));
    this.pendingName = prevPending;
  }

  // --- logical operator sequences ------------------------------------------
  // +1 for each maximal run of the same operator; a change of operator (or the
  // start of a new boolean expression) begins a new run.
  countLogical(node, parentOp, ctx) {
    if (typeOf(node) === 'Op' && (node.operator === '&&' || node.operator === '||')) {
      if (node.operator !== parentOp) {
        const orig = node.originalOperator || node.operator;
        this.add(1, line1(node), `logical sequence (${orig})`, ctx.nesting); // fundamental (+1)
      }
      this.countLogical(node.first, node.operator, ctx);
      if (node.second) this.countLogical(node.second, node.operator, ctx);
    } else {
      // not part of this run — resume normal traversal (finds nested flow and
      // fresh boolean sequences inside e.g. `!(a && b)` or a call argument).
      this.visit(node, withStatement(ctx, false));
    }
  }
}

// ctx helpers (ctx = { nesting, funcDepth, statement })
function withStatement(ctx, statement) { return { nesting: ctx.nesting, funcDepth: ctx.funcDepth, statement }; }
function stmtAt(ctx, nesting) { return { nesting, funcDepth: ctx.funcDepth, statement: true }; }
function exprAt(ctx, nesting) { return { nesting, funcDepth: ctx.funcDepth, statement: false }; }

// --- public API -------------------------------------------------------------

function summarize(rec) {
  const complexity = rec.increments.reduce((s, i) => s + i.delta, 0);
  return {
    name: rec.name,
    klass: rec.klass,
    line: rec.line,
    complexity,
    increments: rec.increments.slice().sort((a, b) => a.line - b.line),
  };
}

/**
 * Analyze CoffeeScript source. Returns:
 *   { file, functions:[{name,klass,line,complexity,increments}],
 *     fileTop:{complexity,increments}, total, classes:{name:complexity} }
 * On parse error: { file, error }.
 */
function analyzeSource(src, file, options) {
  const a = new Analyzer(options);
  let root;
  try {
    root = CoffeeScript.nodes(a.opts.superShim ? applySuperShim(src) : src);
  } catch (e) {
    return { file: file || '<source>', error: (e && e.message) || String(e) };
  }
  a.visit(root, { nesting: 0, funcDepth: 0, statement: true });

  const functions = a.functions.map(summarize);
  const fileTop = summarize(a.fileLevel);
  const total = functions.reduce((s, f) => s + f.complexity, 0) + fileTop.complexity;

  const classes = {};
  for (const f of functions) {
    const key = f.klass || '(no class)';
    classes[key] = (classes[key] || 0) + f.complexity;
  }
  return { file: file || '<source>', functions, fileTop, total, classes };
}

module.exports = { analyzeSource, Analyzer, DEFAULT_OPTIONS };
