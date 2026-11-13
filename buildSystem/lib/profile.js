#!/usr/bin/env node
'use strict';
// not-a-gate: the build step that derives a profile's flavour; it refuses a malformed profile, judging no code
//
// profile.js -- a build FLAVOUR as DATA: the one reader of buildSystem/profiles/*.json.
//
// WHAT A PROFILE IS -- three facts, plus one that only a precompiled artifact has to answer, in
// buildSystem/profiles/<name>.json:
//
//     parts    which slices of the system ship   (the partition: buildSystem/parts.json)
//     form     how the classes reach the world   ("compile-at-boot" | "precompiled")
//     entries  which entry pages ship            (ENTRY_PAGES below; each presets a backend)
//     sources  WHEN the reflective layer loads   ("background" | "lazy" | "none") -- required iff
//              form is "precompiled", and forbidden otherwise, because a compile-at-boot build's
//              sources ARE its world. See SOURCES_POLICIES.
//
// EVERYTHING ELSE FOLLOWS. Every question the build used to answer with "is this the homepage?" is
// DERIVED here from those three (arc 5 PR-D6: derive, never declare):
//
//     the js/tests symlink + BUILDFLAG_LOAD_TESTS      <- does the `harness` part ship?
//     the two tests-repo build gates                   <- same
//     stripping the dead `if Automator?` branches       <- same, inverted: no Automator, no checks
//     assembling the SWCanvas boot bundle               <- does any shipped entry render through SWCanvas?
//     shipping the ~90 MB font-assets/                  <- same
//     which non-source files land in the tree           <- the shipping parts' own `assets` / `vendor`
//     which src/boot/ pieces join the boot bundle       <- the shipping parts' own `bootPrelude` (core's first)
//     which src/boot/ scripts are compiled for boot     <- the shipping parts' own `bootScripts`
//     running the pre-compile driver + minifying it     <- form == "precompiled"
//     whether js/coffeescript-sources/ exists at all    <- sources != "none"
//     when the reflective layer loads, if ever          <- sources (BUILDFLAG_SOURCES in the bundle)
//
// So the schema stayed SMALL, against the eight keys arc 5's plan first sketched: `extras.tests`,
// `extras.fontAssets` and `name` all turned out to be derivable or redundant, and a field that mirrors
// a fact the build can compute is the very species this program exists to kill. `sources` was held back
// from phase 0+1 for the same reason and arrived in phase 2 WITH its consumer -- which is also why it is
// required only where it expresses a real choice.
//
// WHY THIS EXISTS. Until arc 5, one flavour -- the homepage -- was spelled as a `--homepage` flag and
// ten `if $homepage` branches in build_it_please.sh, plus an `inHomepage` boolean per part and a
// per-flavour prune list of files to delete again at the end. "What does a production build contain?"
// could only be answered by reading a 969-line shell script. Now it is three lines of JSON, and adding
// a flavour is adding a file.
//
// CURRENT-STATE REFERENCE: docs/architecture/build-and-packaging.md (the partition, the profiles, and
// the full DERIVED table). The arc that produced this shape, with its measurements and its rulings, is
// docs/archive/build-arc-5-packaging-profiles-plan.md.
//
// USAGE
//     build.js                requires this module and calls resolve(name) (and bootFiles(parts) for --list-boot)
//     build_it_please.sh      eval's the shell assignments from:
//     build_and_smoke.sh          node ./buildSystem/lib/profile.js --shell "$@"
//     fg (presuite, gauntlet) (pass the build's WHOLE arg list -- this module owns `--profile` parsing,
//                             so no caller has to re-implement it)
//
// ⚠ Every problem here is FATAL, never a warning that a default papers over: a profile that cannot be
// read, or names a part that no longer exists, would otherwise silently ship the wrong artifact -- and a
// rename is exactly when that happens. A refusal is THROWN (a `Refusal`, carrying its exact text and exit
// code), never a process exit: gates require this module in-process. Only the --shell command line below
// prints a refusal and sets the exit code.
//
// THE SEMANTICS ARE THE PYTHON ONES THIS MODULE WAS PORTED FROM (buildSystem/buildProfile.py, deleted in
// cleanups U5), kept exactly, because the words of a refusal and the bytes of a build are what callers and
// fingerprints compare. So, deliberately:
//   - a path is relative to the WORKING DIRECTORY (Fizzygum/ when the build runs), never to this file. A
//     library caller that runs elsewhere names that directory: inDirectory(dir, fn) holds every relative path
//     of the synchronous call `fn` to it, the way a child process started with that cwd would be held;
//   - every text file is read as STRICT UTF-8 (an invalid byte refuses, never decodes to U+FFFD) and a
//     leading BOM is KEPT (so a profile carrying one is not valid JSON, as it never was);
//   - a JSON value reaches a message through `py.str` / `py.repr` (`'x'`, `None`, `True`, `1.0`, `['a']`,
//     `"it's"`), a JSON number keeps whether it was written as an integer, and every list is sorted by CODE
//     POINT (`py.sorted`), never by UTF-16 unit or locale;
//   - a value of the wrong JSON type fails where the Python failed: a STRING where a list belongs is walked
//     character by character (`py.iter`), an object as its keys, and anything else not iterable, not a
//     mapping or not a string CRASHES (`PyCrash`: a non-zero exit, never a refusal's words), as a Python
//     TypeError/AttributeError/KeyError did. `eager` is read by Python truthiness (`0`, `[]`, `""` are lazy;
//     `"false"` is eager);
//   - a glob is Python's (`glob` below): directory order as the filesystem returns it, a name starting with `.`
//     never matched by `*`, `os.path.join` never normalising `..`.

const fs = require('fs');

// ================================================================================================================
// Python's semantics, as the build's two modules need them
// ================================================================================================================

// THE WORKING DIRECTORY. undefined: the process's own (the command line). A library caller passes an absolute
// directory through inDirectory(); every fs call below goes through at(), and every PRINTED path stays as given.
let base;
function inDirectory(dir, fn) {
  const saved = base;
  base = dir;
  try { return fn(); } finally { base = saved; }
}
const at = (p) => ((base === undefined || p === '' || p.startsWith('/')) ? p : (base.endsWith('/') ? base + p : base + '/' + p));

// A REFUSAL: the build's own words, the stream they go to and the exit code -- what Python's print + exit(1),
// sys.exit(text), raise SystemExit(text) and argparse's error() did. `text` carries no trailing newline.
class Refusal extends Error {
  constructor(text, exitCode = 1, stream = 'stderr') {
    super(text);
    this.name = 'Refusal';
    this.exitCode = exitCode;
    this.stream = stream;
  }
}

// A CRASH: where the Python raised an exception it did not catch (a traceback, exit 1). Its text is the crash's
// own and was never the build's, so only its non-zero exit is kept.
class PyCrash extends Error {
  constructor(kind, text) { super(kind + ': ' + text); this.name = 'PyCrash'; }
}
const crash = (kind, text) => { throw new PyCrash(kind, text); };

// A JSON NUMBER, as Python's json module gives it: an int when written without `.`/`e`/`E` (exact, any size), else
// a float. JSON.parse loses that distinction (1 and 1.0 are one number), and a message or the parts manifest prints
// the difference.
class PyNumber {
  constructor(source) {
    this.isInt = !/[.eE]/.test(source);
    this.value = this.isInt ? BigInt(source) : Number(source);
  }
}

const isDict = (v) => v !== null && typeof v === 'object' && !Array.isArray(v) && !(v instanceof PyNumber) && !(v instanceof Map);
const typeName = (v) => (v === null ? 'NoneType' : typeof v === 'boolean' ? 'bool' : typeof v === 'string' ? 'str'
  : Array.isArray(v) ? 'list' : v instanceof PyNumber ? (v.isInt ? 'int' : 'float') : 'dict');

// JSON text → value: objects keep their keys in insertion order -- but for a key that reads as an array index, which
// JavaScript orders FIRST where Python kept insertion order (no part, profile or entry key reads so today),
// numbers become PyNumber. Throws SyntaxError on text Python's json would refuse too (and on NaN/Infinity, which it
// accepted).
const parseJson = (text) => JSON.parse(text, (key, value, context) => (typeof value === 'number' ? new PyNumber(context.source) : value));

// strict UTF-8, BOM kept (codecs.open(path, "r", "utf-8"): binary underneath, so no newline translation either)
const STRICT_UTF8 = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });
const readBytes = (p) => fs.readFileSync(at(p));
const readText = (p) => STRICT_UTF8.decode(readBytes(p));
const isDecodeError = (e) => e instanceof TypeError && e.code === 'ERR_ENCODING_INVALID_ENCODED_DATA';

// a str that would not ENCODE as UTF-8 (a lone surrogate, from a JSON "\udXXX" escape) fails as Python's encoder did
const encodable = (text) => { if (!text.isWellFormed()) crash('UnicodeEncodeError', "'utf-8' codec can't encode a surrogate"); return text; };

// codecs.open(path, "w", "utf-8").write(text): created (or truncated) first, then the text encoded strictly
function writeText(p, text) {
  const fd = fs.openSync(at(p), 'w');
  try { encodable(text); writeAllSync(fd, Buffer.from(text, 'utf8')); } finally { fs.closeSync(fd); }
}
function writeAllSync(fd, buf) {
  for (let off = 0; off < buf.length;) off += fs.writeSync(fd, buf, off, buf.length - off);
}

const py = {
  truthy(v) {
    if (v === null || v === false) return false;
    if (v === true) return true;
    if (typeof v === 'string' || Array.isArray(v)) return v.length > 0;
    if (v instanceof PyNumber) return v.isInt ? v.value !== 0n : v.value !== 0;
    if (v instanceof Map) return v.size > 0;
    return Object.keys(v).length > 0;
  },
  // dict.keys(): the mapping's keys, in order; anything else has no .keys()
  keys(d) { if (!isDict(d)) crash('AttributeError', `'${typeName(d)}' object has no attribute 'keys'`); return Object.keys(d); },
  // dict.get(key, default): the DEFAULT only when the key is absent (a present null is None, not the default)
  get(d, key, dflt) { if (!isDict(d)) crash('AttributeError', `'${typeName(d)}' object has no attribute 'get'`); return Object.hasOwn(d, key) ? d[key] : dflt; },
  // value[key] with a string key: a mapping's entry, or KeyError; a list/str/number/None cannot be indexed so
  index(d, key) {
    if (!isDict(d)) crash('TypeError', `'${typeName(d)}' object is not subscriptable by '${key}'`);
    if (!Object.hasOwn(d, key)) crash('KeyError', `'${key}'`);
    return d[key];
  },
  // `for x in value`: a list's items, a str's characters (code points), a mapping's keys; nothing else iterates
  iter(v) {
    if (Array.isArray(v)) return v;
    if (typeof v === 'string') return [...v];
    if (isDict(v)) return Object.keys(v);
    return crash('TypeError', `'${typeName(v)}' object is not iterable`);
  },
  // `a, b = value`: exactly two items
  unpack2(v) {
    const items = py.iter(v);
    if (items.length !== 2) crash('ValueError', `expected 2 values to unpack, got ${items.length}`);
    return items;
  },
  // `x in aSet`: an unhashable x (a list, a mapping) raises; anything else is a plain membership test
  setHas(set, x) { if (Array.isArray(x) || isDict(x)) crash('TypeError', `unhashable type: '${typeName(x)}'`); return set.has(x); },
  mustStr(v, what) { if (typeof v !== 'string') crash('TypeError', `${what}: expected str, not ${typeName(v)}`); return v; },
  startswith(s, prefix) { if (typeof s !== 'string') crash('AttributeError', `'${typeName(s)}' object has no attribute 'startswith'`); return s.startsWith(prefix); },
  // str(v) / '%s' % v
  str(v) {
    if (typeof v === 'string') return v;
    return py.repr(v);
  },
  // repr(v) / '%r' % v
  repr(v) {
    if (typeof v === 'string') return reprStr(v);
    if (v === null) return 'None';
    if (v === true) return 'True';
    if (v === false) return 'False';
    if (v instanceof PyNumber) return v.isInt ? v.value.toString() : floatRepr(v.value);
    if (Array.isArray(v)) return '[' + v.map(py.repr).join(', ') + ']';
    if (v instanceof Map) return '{' + [...v].map(([k, x]) => py.repr(k) + ': ' + py.repr(x)).join(', ') + '}';
    return '{' + Object.keys(v).map((k) => reprStr(k) + ': ' + py.repr(v[k])).join(', ') + '}';
  },
  // json.dumps(v, sort_keys=True): separators ', ' and ': ', non-ASCII escaped \uXXXX (lowercase), keys sorted by code point
  dumps(v) {
    if (typeof v === 'string') return dumpsStr(v);
    if (v === null) return 'null';
    if (v === true) return 'true';
    if (v === false) return 'false';
    if (v instanceof PyNumber) {
      if (v.isInt) return v.value.toString();
      if (Number.isNaN(v.value)) return 'NaN';
      if (v.value === Infinity) return 'Infinity';
      if (v.value === -Infinity) return '-Infinity';
      return floatRepr(v.value);
    }
    if (Array.isArray(v)) return '[' + v.map(py.dumps).join(', ') + ']';
    const entries = v instanceof Map ? [...v] : Object.keys(v).map((k) => [k, v[k]]);
    return '{' + entries.sort((a, b) => cmpCodePoint(a[0], b[0])).map(([k, x]) => dumpsStr(k) + ': ' + py.dumps(x)).join(', ') + '}';
  },
  sorted: (strings) => [...strings].sort(cmpCodePoint),
};

// strings in CODE POINT order (Python's str ordering). UTF-16 unit order agrees except where a surrogate meets a unit
// above it (U+E000..U+FFFF), so at the first differing unit the surrogates are moved above that range.
function cmpCodePoint(a, b) {
  const n = Math.min(a.length, b.length);
  for (let i = 0; i < n; i++) {
    let x = a.charCodeAt(i), y = b.charCodeAt(i);
    if (x === y) continue;
    if (x >= 0xD800 && y >= 0xD800) {
      x = x >= 0xE000 ? x - 0x800 : x + 0x2000;
      y = y >= 0xE000 ? y - 0x800 : y + 0x2000;
    }
    return x - y;
  }
  return a.length - b.length;
}

// Python's str.isprintable(), negated, for a non-ASCII code point (categories C*, Z* other than the ASCII space)
const NOT_PRINTABLE = /[\p{Cc}\p{Cf}\p{Cs}\p{Co}\p{Cn}\p{Zl}\p{Zp}\p{Zs}]/u;
const hex = (n, width) => n.toString(16).padStart(width, '0');
function reprStr(s) {
  const quote = (s.includes("'") && !s.includes('"')) ? '"' : "'";
  let out = quote;
  for (const ch of s) {
    const c = ch.codePointAt(0);
    if (ch === quote || ch === '\\') out += '\\' + ch;
    else if (ch === '\t') out += '\\t';
    else if (ch === '\n') out += '\\n';
    else if (ch === '\r') out += '\\r';
    else if (c < 0x20 || c === 0x7F) out += '\\x' + hex(c, 2);
    else if (c < 0x7F) out += ch;
    else if (NOT_PRINTABLE.test(ch)) out += c <= 0xFF ? '\\x' + hex(c, 2) : c <= 0xFFFF ? '\\u' + hex(c, 4) : '\\U' + hex(c, 8);
    else out += ch;
  }
  return out + quote;
}

function dumpsStr(s) {
  let out = '"';
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c >= 0x20 && c <= 0x7E && c !== 0x22 && c !== 0x5C) { out += s[i]; continue; }
    switch (c) {
      case 0x5C: out += '\\\\'; break;
      case 0x22: out += '\\"'; break;
      case 0x08: out += '\\b'; break;
      case 0x0C: out += '\\f'; break;
      case 0x0A: out += '\\n'; break;
      case 0x0D: out += '\\r'; break;
      case 0x09: out += '\\t'; break;
      default: out += '\\u' + hex(c, 4);   // an astral code point is its surrogate pair, each escaped: as Python does
    }
  }
  return out + '"';
}

// repr(float): the shortest digits that round-trip, positional when the decimal exponent is in [-4, 16), else
// scientific with a two-digit-minimum exponent; always a '.0' when positional and integral
function floatRepr(x) {
  if (Number.isNaN(x)) return 'nan';
  if (x === Infinity) return 'inf';
  if (x === -Infinity) return '-inf';
  const sign = (x < 0 || Object.is(x, -0)) ? '-' : '';
  const [mant, exp] = Math.abs(x).toExponential().split('e');
  const digits = mant.replace('.', '');
  const decpt = Number(exp) + 1;
  if (decpt <= -4 || decpt > 16) {
    const e = decpt - 1;
    return sign + digits[0] + (digits.length > 1 ? '.' + digits.slice(1) : '') + 'e' + (e < 0 ? '-' : '+') + String(Math.abs(e)).padStart(2, '0');
  }
  if (decpt <= 0) return sign + '0.' + '0'.repeat(-decpt) + digits;
  if (decpt >= digits.length) return sign + digits + '0'.repeat(decpt - digits.length) + '.0';
  return sign + digits.slice(0, decpt) + '.' + digits.slice(decpt);
}

// shlex.quote
const SHELL_UNSAFE = /[^\w@%+=:,./-]/;
const shellQuote = (s) => (!s ? "''" : !SHELL_UNSAFE.test(s) ? s : "'" + s.split("'").join("'\"'\"'") + "'");

// ---- paths (posixpath: nothing normalised, `..` and `//` kept as written) ------------------------------------------
function pathJoin(a, ...rest) {
  let p = py.mustStr(a, 'join');
  for (const b of rest) {
    py.mustStr(b, 'join');
    if (b.startsWith('/')) p = b;
    else if (!p || p.endsWith('/')) p += b;
    else p += '/' + b;
  }
  return p;
}
function pathSplit(p) {
  const i = p.lastIndexOf('/') + 1;
  let head = p.slice(0, i);
  if (head && !/^\/+$/.test(head)) head = head.replace(/\/+$/, '');
  return [head, p.slice(i)];
}
const pathBasename = (p) => { py.mustStr(p, 'basename'); return p.slice(p.lastIndexOf('/') + 1); };
const pathDirname = (p) => pathSplit(py.mustStr(p, 'dirname'))[0];

// ---- the filesystem, as os.path asks it (a failure of any kind is "no") --------------------------------------------
const isOsError = (e) => e && typeof e.syscall === 'string';
function statOf(p, follow = true) {
  try { return follow ? fs.statSync(at(p), { bigint: true }) : fs.lstatSync(at(p), { bigint: true }); } catch { return undefined; }
}
// os.path.isfile also takes an int: a FILE DESCRIPTOR (a JSON integer in an asset or vendor path reaches it so)
function isfile(p) {
  if (typeof p === 'string') { const st = statOf(p); return !!st && st.isFile(); }
  if (typeof p === 'boolean' || (p instanceof PyNumber && p.isInt)) {
    const fd = typeof p === 'boolean' ? (p ? 1 : 0) : p.value;
    if (fd < 0n || fd < 0) return false;
    if (fd > 2147483647n || fd > 2147483647) crash('OverflowError', 'fd is greater than maximum');
    // Python's isfile(fd) answers True for an open regular file and the build then fails a step later; this port
    // fails here instead (a non-zero exit either way), not reproducing the file-descriptor path
    try { if (fs.fstatSync(Number(fd)).isFile()) crash('NotPorted', 'a JSON integer path names an open regular-file descriptor'); } catch (e) { if (e instanceof PyCrash) throw e; }
    return false;
  }
  return crash('TypeError', `stat: path should be string, bytes, os.PathLike or integer, not ${typeName(p)}`);
}
const isdir = (p) => { const st = statOf(p); return !!st && st.isDirectory(); };
const lexists = (p) => statOf(p, false) !== undefined;
const exists = (p) => statOf(p) !== undefined;

// os.makedirs(name, exist_ok=True)
function makedirs(name) {
  let [head, tail] = pathSplit(name);
  if (!tail) [head, tail] = pathSplit(head);
  if (head && tail && !exists(head)) {
    try { makedirs(head); } catch (e) { if (!(e && e.code === 'EEXIST')) throw e; }
    if (tail === '.') return;
  }
  try { fs.mkdirSync(at(name)); } catch (e) { if (!isdir(name)) throw e; }
}

// shutil.copyfile(src, dst): the DATA only (never the mode), dst created or truncated
function copyfile(src, dst) {
  const a = statOf(src), b = statOf(dst);
  if (a && b && a.dev === b.dev && a.ino === b.ino) crash('SameFileError', `${py.repr(src)} and ${py.repr(dst)} are the same file`);
  for (const [st, fn] of [[a, src], [b, dst]]) if (st && st.isFIFO()) crash('SpecialFileError', `\`${fn}\` is a named pipe`);
  const data = readBytes(src);
  const fd = fs.openSync(at(dst), 'w');
  try { writeAllSync(fd, data); } finally { fs.closeSync(fd); }
}

// ---- glob.glob(pathname): Python's, not a shell's -------------------------------------------------------------------
// Directory order is the filesystem's own (os.scandir; fs.opendirSync reads it the same way, where fs.readdirSync
// would sort); `*` and `?` never match a leading `.`; a directory part of the pattern may hold wildcards too.
const MAGIC = /[*?[]/;
const isHidden = (name) => name[0] === '.';
function listdir(dirname, dironly) {
  const names = [];
  let dir;
  try { dir = fs.opendirSync(at(dirname || '.')); } catch (e) { if (isOsError(e)) return names; throw e; }
  try {
    for (;;) {
      let entry;
      try { entry = dir.readSync(); } catch (e) { if (isOsError(e)) break; throw e; }
      if (entry === null) break;
      if (!dironly || entry.isDirectory() || (!entry.isFile() && isdir(pathJoin(dirname || '.', entry.name)))) names.push(entry.name);
    }
  } finally { try { dir.closeSync(); } catch { /* already closed */ } }
  return names;
}
function glob1(dirname, pattern, dironly) {
  let names = listdir(dirname, dironly);
  if (!isHidden(pattern)) names = names.filter((name) => !isHidden(name));
  const re = fnmatchRegExp(pattern);
  return names.filter((name) => re.test(name));
}
function glob0(dirname, basename) {
  if (basename) { if (lexists(dirname ? pathJoin(dirname, basename) : basename)) return [basename]; }
  else if (isdir(dirname)) return [basename];
  return [];
}
function* iglob(pathname, dironly) {
  const [dirname, basename] = pathSplit(pathname);
  if (!MAGIC.test(pathname)) {
    if (basename) { if (lexists(pathname)) yield pathname; }
    else if (isdir(dirname)) yield pathname;
    return;
  }
  if (!dirname) { yield* glob1('', basename, dironly); return; }
  const dirs = (dirname !== pathname && MAGIC.test(dirname)) ? [...iglob(dirname, true)] : [dirname];
  for (const d of dirs) {
    for (const name of (MAGIC.test(basename) ? glob1(d, basename, dironly) : glob0(d, basename))) yield pathJoin(d, name);
  }
}
const glob = (pathname) => [...iglob(py.mustStr(pathname, 'glob'), false)];

// fnmatch.translate(pat), as a RegExp: `*` any run, `?` one character, `[...]` a set (`[!...]` negated), ranges
// whose ends are reversed dropped, everything else literal. (Python adds atomic groups for speed; same matches.)
function fnmatchRegExp(pat) {
  const cps = [...pat];
  const n = cps.length;
  const lit = (ch) => '\\u{' + ch.codePointAt(0).toString(16) + '}';
  const out = [];
  let i = 0;
  while (i < n) {
    const c = cps[i++];
    if (c === '*') { if (out[out.length - 1] !== '.*') out.push('.*'); }
    else if (c === '?') out.push('.');
    else if (c === '[') {
      let j = i;
      if (j < n && cps[j] === '!') j++;
      if (j < n && cps[j] === ']') j++;
      while (j < n && cps[j] !== ']') j++;
      if (j >= n) { out.push(lit('[')); continue; }
      const text = (a, b) => cps.slice(a, b).join('');
      let chunks;
      if (!cps.slice(i, j).includes('-')) chunks = [text(i, j)];
      else {
        chunks = [];
        let start = i;
        let k = cps[i] === '!' ? i + 2 : i + 1;
        for (;;) {
          k = cps.indexOf('-', k);
          if (k < 0 || k >= j) break;
          chunks.push(text(start, k));
          start = k + 1;
          k += 3;
        }
        const last = text(start, j);
        if (last) chunks.push(last); else chunks[chunks.length - 1] += '-';
        for (let m = chunks.length - 1; m > 0; m--) {
          const left = [...chunks[m - 1]], right = [...chunks[m]];
          if (left[left.length - 1].codePointAt(0) > right[0].codePointAt(0)) {
            chunks[m - 1] = left.slice(0, -1).join('') + right.slice(1).join('');
            chunks.splice(m, 1);
          }
        }
      }
      i = j + 1;
      const joined = chunks.join('-');
      if (!joined) { out.push('(?!)'); continue; }
      if (joined === '!') { out.push('.'); continue; }
      const negate = joined[0] === '!';
      if (negate) chunks[0] = chunks[0].slice(1);
      // each chunk's characters are literals; between two chunks, a range from one's last to the next's first
      out.push('[' + (negate ? '^' : '') + chunks.map((chunk) => [...chunk].map(lit).join('')).join('-') + ']');
    } else out.push(lit(c));
  }
  return new RegExp('^(?:' + out.join('') + ')$', 'su');
}

// ================================================================================================================
// The profile
// ================================================================================================================

const PROFILES_DIRECTORY = 'buildSystem/profiles';
const DEFAULT_PROFILE_NAME = 'dev';

// THE PARTITION. buildSystem/parts.json names every part, the directories it owns, and its
// non-source belongings; read its header comment before changing anything here or in build.js.
const PARTS_MANIFEST_FILE = 'buildSystem/parts.json';
const CORE_PART = 'core';   // the product: every profile ships it, and its boot pieces are the boot itself

// THE ENTRY PAGES, as [filename, renders through SWCanvas?, loads every part at boot?].
//
// The rendering backend is a BUILD-TIME property of the page: each page presets the flag and loads
// the boot bundle carrying exactly the engine it can use, so no artifact ships an engine it will
// never call and there is no runtime switch to get wrong.
//   index.html                      native 2D + the SWCanvas 3D core (for SW3D)
//   worldWithSystemTestHarness.html full SWCanvas -- the deterministic test substrate
//   index-sw.html                   full SWCanvas, no test harness (interactive SW)
// The test harness is NOT switched on here: WorldWdgt/globalFunctions detect it from the page's
// NAME, so these three differ only in the substituted lines.
//
// The third column is EAGER_ALL_PARTS: does this page load every part at boot, even the ones
// buildSystem/parts.json marks `"eager": false`?
//   index.html                      NO  -- the interactive product: a lazy part arrives on demand.
//   worldWithSystemTestHarness.html YES -- a part arriving MID-TEST would be frame-paced, hence
//                                   cycle-count-dependent, which is precisely the nondeterminism
//                                   class ../Fizzygum-tests/DETERMINISM.md exists about. The suite's
//                                   world must stay exactly what it was, so the harness takes
//                                   everything up front. The lazy path has its own test instead.
//   index-sw.html                   YES -- same world as the harness minus the harness, kept
//                                   comparable to it.
// Both are page PRESETS, chosen at build time, never runtime switches, and not test-only code
// living in the product.
//
// ⚠ This table lives HERE, not in build.js, because a profile's `entries` list is validated against
// it AND two derived facts read the SWCanvas column: the SW boot bundle and the font assets ship iff
// some shipped entry can actually use them. build.js requires it.
const ENTRY_PAGES = [
  ['index.html', false, false],
  ['worldWithSystemTestHarness.html', true, true],
  ['index-sw.html', true, true],
];

const FORMS = ['compile-at-boot', 'precompiled'];

// WHEN THE REFLECTIVE LAYER LOADS -- for a PRECOMPILED artifact only (see resolve()).
//
// "The reflective layer" is the class SOURCE TEXT plus the meta-system that parses it: the
// individually-fetched Class source, then every source batch, then an ingest-only pass
// (`new Class src, false, false`) that registers each class's members and source against the class
// the pre-compiled image already defined. A precompiled world RUNS without it -- it is what lets the
// system inspect and rewrite itself, not what makes it go.
//
//   background  fetch it right after the world starts, off the critical path. Today's production.
//   lazy        fetch it on first demand (opening an inspector).
//   none        do not ship it at all: an appliance artifact that cannot reflect on itself. ~40% of
//               a production tree is that source text.
//
// There is deliberately no "eager": a COMPILE-AT-BOOT build's sources ARE its world, so it has no
// choice to state, and a field that can only hold one value is a mirror of `form`.
const SOURCES_POLICIES = ['background', 'lazy', 'none'];

// The part whose presence MAKES a build test-capable. Named once, here, because five derived facts
// key off it (see the module header) and "which part is the test machinery" is one fact.
const HARNESS_PART = 'harness';

// The entry page whose whole point is that part (resolve() refuses one without the other).
const HARNESS_PAGE = 'worldWithSystemTestHarness.html';

// The part that CANNOT ship without the reflective layer: the in-world inspectors read the member
// maps that only the ingest pass builds, so shipping them with sources: "none" is a broken window.
const META_TOOLS_PART = 'meta-tools';

// A profile problem is fatal: its words go to stderr, so a `--shell` caller's command substitution
// captures no junk on stdout (an eval of a half-written assignment list is worse than no output).
// (`buildProfile: ` is the prefix these refusals have always carried; the refusal corpus reads it, no caller does.)
function fail(message) {
  throw new Refusal('buildProfile: ' + message);
}

// The partition, from buildSystem/parts.json (or another parts file: a bite-proof's planted one, through
// build.js --parts). Read that file's header before changing this.
function loadParts(p = PARTS_MANIFEST_FILE) {
  const parts = py.index(parseJson(readText(p)), 'parts');
  checkRequiresGraph(parts);
  return parts;
}

// `requires` must name real parts and must not cycle -- neither was checked before.
//
// A cycle is not a style problem: PartsRegistry loads a part's requirements FULLY before ingesting
// the part itself, so A->B->A has no valid ingest order and would deadlock behind two promises
// that each wait for the other. check-part-edges.js's header used to claim the build caught this;
// it did not, and there was no `requires` field for it to catch anything in.
function checkRequiresGraph(parts) {
  const names = new Set(partNames(parts));
  for (const name of partNames(parts)) {
    for (const required of py.iter(py.get(parts[name], 'requires', []))) {
      if (!py.setHas(names, required)) {
        fail(`part '${name}' requires '${py.str(required)}', which is not a part in ${PARTS_MANIFEST_FILE}`);
      }
      if (required === name) fail(`part '${name}' requires itself`);
    }
  }

  // depth-first cycle detection, reporting the actual cycle rather than just its existence
  const VISITING = 1, DONE = 2;
  const state = new Map(), stack = [];
  const walk = (node) => {
    state.set(node, VISITING);
    stack.push(node);
    for (const next of py.iter(py.get(parts[node], 'requires', []))) {
      if (state.get(next) === VISITING) {
        const cycle = [...stack.slice(stack.indexOf(next)), next];
        fail(`parts.json has a \`requires\` CYCLE: ${cycle.join(' -> ')} -- a cycle has no valid ingest order, `
          + 'since each part\'s requirements must be fully loaded before it is.');
      }
      if (state.get(next) !== DONE) walk(next);
    }
    stack.pop();
    state.set(node, DONE);
  };
  for (const name of partNames(parts)) if (state.get(name) !== DONE) walk(name);
}

// Every declared part name ("//" keys are prose, not parts).
const partNames = (parts) => py.keys(parts).filter((name) => !name.startsWith('//'));

// A `parts` / `entries` selection, in one of three spellings, resolved against what EXISTS.
//
//     "all"                        everything -- the dev spelling; a new part/page joins with no edit
//     {"allExcept": ["harness"]}   everything but these -- for a flavour defined by a subtraction
//     ["core", "meta-tools"]       exactly these -- for a shipped artifact, whose contents should
//                                  be visible in one place and should NOT grow when a part is added
//
// Naming something that does not exist is FATAL, and that is the point: rename a part or a page and
// every profile that still names the old one fails the build instead of quietly shipping less.
function resolveSelection(spec, universe, what, profileName) {
  if (spec === 'all') return [...universe];

  if (isDict(spec)) {
    const unknownKeys = Object.keys(spec).filter((key) => key !== 'allExcept');
    if (unknownKeys.length) {
      fail(`profile '${profileName}': "${what}" has unknown key(s) ${py.sorted(unknownKeys).join(', ')} -- the only object form is `
        + '{"allExcept": [...]}');
    }
    const excluded = py.index(spec, 'allExcept');
    if (!Array.isArray(excluded)) fail(`profile '${profileName}': "${what}" allExcept must be a list`);
    for (const name of excluded) {
      if (!universe.includes(name)) {
        fail(`profile '${profileName}': "${what}" allExcept names '${py.str(name)}', which the build does not declare `
          + `(known ${what}: ${universe.join(', ')})`);
      }
    }
    return universe.filter((name) => !excluded.includes(name));
  }

  if (Array.isArray(spec)) {
    for (const name of spec) {
      if (!universe.includes(name)) {
        fail(`profile '${profileName}': "${what}" names '${py.str(name)}', which the build does not declare `
          + `(known ${what}: ${universe.join(', ')})`);
      }
    }
    return universe.filter((name) => spec.includes(name));
  }

  return fail(`profile '${profileName}': "${what}" must be "all", a list, or {"allExcept": [...]} -- got ${py.repr(spec)}`);
}

// A validated profile: the three declared facts, plus everything derived from them.
class Profile {
  constructor(name, parts, form, sources, entries) {
    this.name = name;
    this.form = form;
    // WHEN the reflective layer loads (SOURCES_POLICIES). Always "background" for a
    // compile-at-boot build: there, the sources ARE the world and are loaded to BE it, so the
    // question the field answers does not arise -- see resolve().
    this.sources = sources;
    // the resolved part NAMES this profile selects. Whether a part ALSO needs a build flag
    // (`requiresFlag`) is a separate question -- see partShips().
    this.selectedParts = parts;
    // the resolved entry pages, as ENTRY_PAGES rows, in ENTRY_PAGES order
    this.entries = entries;
  }

  // Is this a test-capable build? One question, one answer: does the test machinery ship.
  get shipsTests() { return this.selectedParts.includes(HARNESS_PART); }

  // Can anything in this artifact render through SWCanvas? The SW boot bundle and the ~90 MB
  // of font assets exist only to serve such a page, so both follow from this.
  get shipsSWCanvasEntry() { return this.entries.some(([, useSWCanvas]) => useSWCanvas); }

  // Does the test-harness entry page ship? Not the same fact as shipsTests: a profile may carry
  // the harness part without the page, never the page without the part (resolve() refuses it).
  get shipsHarnessEntry() { return this.entries.some(([entryName]) => entryName === HARNESS_PAGE); }

  get isPreCompiled() { return this.form === 'precompiled'; }

  // Does `js/coffeescript-sources/` exist in this tree at all? `none` is the one policy that
  // drops it -- batches AND the individually-fetched Class source, which is the only class of the boot a
  // pre-compiled image does NOT contain (measured) and which can do nothing with no batches to
  // ingest.
  get shipsSourceText() { return this.sources !== 'none'; }

  selectsPart(partName) { return this.selectedParts.includes(partName); }
}

// Does this part ship in the build being made? THE part-inclusion rule, written once.
//
// Two independent conditions: the profile selects it, and any additional opt-in flag it declares
// is set. `requiresFlag` survives profiles for exactly one carrier -- the video player, whose
// `--includeVideoPlayer` is a per-invocation opt-in rather than a property of an artifact. (The
// other carrier, `requiresFlag: "tests"` on the harness part, is GONE: whether the test machinery
// ships is now the profile's own `parts` selection, so it is not asked twice.)
function partShips(partName, part, profile, includeVideoPlayer) {
  if (!profile.selectsPart(partName)) return false;
  if (py.get(part, 'requiresFlag', null) === 'videoPlayer' && !includeVideoPlayer) return false;
  return true;
}

// [name, spec] for every part that ships, in parts.json order.
const shippingParts = (parts, profile, includeVideoPlayer) =>
  partNames(parts).filter((name) => partShips(name, parts[name], profile, includeVideoPlayer)).map((name) => [name, parts[name]]);

// The src/boot/ pieces that shipping parts contribute to the boot bundle, in order.
//
// A part can own more than sources: `assets` are copied, `vendor` payloads assembled, and its
// `bootPrelude` pieces are concatenated into the boot bundle -- core's own (boot itself: the
// SourceVault, globalFunctions, the built-in prototype extensions) first, whatever its place in
// parts.json, then every other shipping part's in partition order (e.g. fizzytiles'
// numbertimes.coffee, which extends Number for the LiveCodeLang preprocessor).
function bootPrelude(parts, profile, includeVideoPlayer) {
  const pieces = [];
  const shipping = shippingParts(parts, profile, includeVideoPlayer);
  for (const [, part] of [...shipping.filter(([name]) => name === CORE_PART), ...shipping.filter(([name]) => name !== CORE_PART)]) {
    pieces.push(...py.iter(py.get(part, 'bootPrelude', [])));
  }
  return pieces;
}

// The src/boot/ files that shipping parts have compiled one by one to js/src/<name>-min.js, which
// boot fetches by name.
function bootScripts(parts, profile, includeVideoPlayer) {
  const scripts = [];
  for (const [, part] of shippingParts(parts, profile, includeVideoPlayer)) scripts.push(...py.iter(py.get(part, 'bootScripts', [])));
  return scripts;
}

const BOOT_DIRECTORY = 'src/boot';

// Every src/boot file ANY part declares (`bootPrelude` and `bootScripts`), as parts.json spells it, each as
// [file, part, kind: "prelude" | "script"], in the parts' order -- flavour-independent, like the partition's own
// file list. Each must sit under src/boot/ (no `..`), exist
// (in `srcRoot` when given: another src tree, a bite-proof's planted copy) and be declared once, and no two
// boot scripts may share a name (each becomes js/src/<name>-min.js); anything else fails the build --
// which asks this at its first step (--shell) and through build.js --list-boot, the list
// check-shippable-coverage.js holds every src/boot file to.
function bootFiles(parts, srcRoot, partsFile = PARTS_MANIFEST_FILE) {
  const declaredBy = new Map();
  const scriptNames = new Map();
  const piecesInOrder = [];
  for (const name of partNames(parts)) {
    for (const key of ['bootPrelude', 'bootScripts']) {
      for (const piece of py.iter(py.get(parts[name], key, []))) {
        if (!py.startswith(piece, BOOT_DIRECTORY + '/') || piece.split('/').includes('..')) {
          fail(`part '${name}' ${key} names '${piece}', which is not under ${BOOT_DIRECTORY}/`);
        }
        const physical = srcRoot ? srcRoot.replace(/\/+$/, '') + piece.slice('src'.length) : piece;
        if (!isfile(physical)) fail(`part '${name}' ${key} names '${piece}', which does not exist`);
        if (declaredBy.has(piece)) {
          fail(`'${piece}' is declared twice in ${partsFile}: by part '${declaredBy.get(piece)}' and by part '${name}' (${key})`);
        }
        declaredBy.set(piece, name);
        if (key === 'bootScripts') {
          if (!piece.endsWith('.coffee')) {
            fail(`part '${name}' bootScripts names '${piece}', which is no .coffee file (each is compiled to js/src/<name>-min.js)`);
          }
          const scriptName = pathBasename(piece);
          if (scriptNames.has(scriptName)) {
            fail(`two bootScripts are both named '${scriptName}' (${scriptNames.get(scriptName)} and ${piece}): each is built as js/src/<name>-min.js`);
          }
          scriptNames.set(scriptName, piece);
          piecesInOrder.push([piece, name, 'script']);
        } else {
          piecesInOrder.push([piece, name, 'prelude']);
        }
      }
    }
  }
  return piecesInOrder;
}

const availableProfileNames = () =>
  py.sorted(glob(pathJoin(PROFILES_DIRECTORY, '*.json')).map((p) => pathBasename(p).slice(0, -'.json'.length)));

// `requiredParts: [ … ]`, a class's own statement of the parts its `launch` awaits: the FIRST such line of a
// source, at the start of a line (only `\n` starts one), with Python's whitespace (`\s`) around its punctuation
const PY_WHITESPACE = '[\\t\\n\\v\\f\\r\\x1c-\\x1f \\x85\\xa0\\u1680\\u2000-\\u200a\\u2028\\u2029\\u202f\\u205f\\u3000]';
const REQUIRED_PARTS_DECLARATION = new RegExp(`(?:^|(?<=\\n))${PY_WHITESPACE}*requiredParts${PY_WHITESPACE}*:${PY_WHITESPACE}*\\[([^\\]]*)\\]`);

// Load and fully validate profiles/<name>.json. Any problem is fatal (see the module header).
function resolve(name) {
  const p = pathJoin(PROFILES_DIRECTORY, name + '.json');
  if (!isfile(p)) {
    fail(`no such profile '${name}' (${p} does not exist). Available: ${availableProfileNames().join(', ') || 'none'}`);
  }
  let declared;
  try {
    declared = parseJson(readText(p));
  } catch (error) {
    // what Python's json raised as a ValueError -- a byte that is not UTF-8, text that is not JSON -- is the profile's
    // fault; the diagnostic after the colon is the parser's own
    if (isDecodeError(error) || error instanceof SyntaxError) fail(`profile '${name}' is not valid JSON (${p}): ${error.message}`);
    throw error;
  }

  // An unknown key is a typo that would otherwise be silently ignored, and a silently-ignored
  // `"from": "precompiled"` ships a compile-at-boot tree while claiming otherwise.
  const allowed = ['//', 'parts', 'form', 'sources', 'entries'];
  const unknownKeys = py.keys(declared).filter((key) => !allowed.includes(key));
  if (unknownKeys.length) {
    fail(`profile '${name}' has unknown key(s): ${py.sorted(unknownKeys).join(', ')}. A profile declares exactly `
      + `${allowed.slice(1).join('/')} (everything else about a build is DERIVED -- see buildSystem/lib/profile.js's header).`);
  }
  // the keys every profile must state: the allowed ones bar the prose key and `sources` (whose rule is the form's)
  for (const key of allowed.filter((k) => k !== '//' && k !== 'sources')) {
    if (!Object.hasOwn(declared, key)) fail(`profile '${name}' is missing "${key}"`);
  }

  const form = declared.form;
  if (!FORMS.includes(form)) fail(`profile '${name}': form must be one of ${FORMS.join(' / ')} -- got ${py.repr(form)}`);

  // `sources` is required for a precompiled artifact and FORBIDDEN otherwise -- both directions, so
  // neither a missing choice nor a stated non-choice can pass. A compile-at-boot build loads every
  // source in order to BE the world; there is no policy to pick, and declaring one would mirror
  // `form` and then rot when they disagreed.
  let sources;
  if (form === 'precompiled') {
    if (!Object.hasOwn(declared, 'sources')) {
      fail(`profile '${name}': form "precompiled" must also declare "sources" (${SOURCES_POLICIES.join(' / ')}) -- a `
        + 'precompiled world runs without the class source text, so when that text arrives '
        + 'is a real choice this profile has to make');
    }
    sources = declared.sources;
    if (!SOURCES_POLICIES.includes(sources)) {
      fail(`profile '${name}': sources must be one of ${SOURCES_POLICIES.join(' / ')} -- got ${py.repr(sources)}`);
    }
  } else {
    if (Object.hasOwn(declared, 'sources')) {
      fail(`profile '${name}': form "compile-at-boot" must NOT declare "sources" -- such a `
        + 'build compiles every source AT boot because they ARE its world, so the field could '
        + 'only ever restate `form`');
    }
    sources = 'background';
  }

  const parts = loadParts();
  const selectedParts = resolveSelection(declared.parts, partNames(parts), 'parts', name);
  if (!selectedParts.includes(CORE_PART)) fail(`profile '${name}' does not ship the 'core' part -- core IS the product`);

  // An incoherent pairing, in the same family as "precompiled needs index.html": the in-world
  // inspectors read the member maps that only the ingest pass builds, so with no source text they
  // would open onto nothing.
  if (sources === 'none' && selectedParts.includes(META_TOOLS_PART)) {
    fail(`profile '${name}' ships the '${META_TOOLS_PART}' part with sources "none" -- the inspectors read the `
      + 'member maps that only ingesting the source text builds, so they would open onto '
      + 'nothing. Drop the part, or pick sources "background"/"lazy".');
  }

  // A LAZY part arrives AS SOURCE -- PartsRegistry fetches its batches and compiles them at launch
  // -- so with no source text in the tree it could never load: its desktop icon would be a button
  // that 404s. (Nor is its code in the pre-compiled image: that is harvested by booting index.html,
  // where a lazy part is by definition not loaded.)
  if (sources === 'none') {
    for (const partName of selectedParts) {
      if (!py.truthy(py.get(parts[partName], 'eager', true))) {
        fail(`profile '${name}' ships the lazy part '${partName}' with sources "none" -- a lazy part is `
          + 'fetched as SOURCE when something launches it, and this artifact has no source '
          + 'text, so it could never load.');
      }
    }
  }

  // A part's `requires` names other parts whose classes its code names. Shipping one without them
  // is the both-or-neither rule that lived only in prose until now -- and prose is exactly what
  // failed: 'lean' once carried DashboardsApp and SimpleSlideApp icons whose click could only
  // reject, because nothing checked that the parts they need were there too.
  for (const partName of selectedParts) {
    for (const requiredPart of py.iter(py.get(parts[partName], 'requires', []))) {
      if (!selectedParts.includes(requiredPart)) {
        fail(`profile '${name}' ships the part '${partName}' but not '${requiredPart}', which parts.json says it `
          + `REQUIRES -- '${partName}' names classes from it, so those call sites would throw `
          + `'<TheClass> is not defined' the moment they ran. Add '${requiredPart}' to this profile's `
          + `parts, or drop '${partName}'.`);
      }
    }
  }

  // ...and the SAME both-or-neither rule for the parts a CLASS declares rather than a part.
  //
  // ⚠⚠ WHY THIS IS SEPARATE FROM `requires` ABOVE, AND MUST STAY SEPARATE. `requires` carries two
  // meanings at once: shipping (checked above) and, for a LAZY part, ORDERING -- PartsRegistry
  // loads the requirements FULLY FIRST. That second meaning makes it the wrong tool for a door.
  // Each `example-*` part is ONE launcher class, and the whole point is that its source arrives on
  // the click of its own icon: declaring `requires: ["maps","plots","authoring"]` on one would be
  // correct about shipping and disastrous about timing, dragging a document's whole apparatus in
  // behind the door rather than behind the click. So a door states its apps per-CLASS, in the
  // `requiredParts` its inherited `launch` awaits, and the shipping half is checked HERE instead.
  // Without this, having no `requires` would silently give back the dead-icon bug it was added for.
  for (const partName of selectedParts) {
    for (const sourceDir of py.iter(py.get(parts[partName], 'dirs', []))) {
      for (const sourcePath of py.sorted(glob(pathJoin(sourceDir, '*.coffee')))) {
        const found = REQUIRED_PARTS_DECLARATION.exec(readText(sourcePath));
        if (!found) continue;
        for (const [, declaredPart] of found[1].matchAll(/["']([^"']+)["']/g)) {
          if (!selectedParts.includes(declaredPart)) {
            fail(`profile '${name}' ships ${sourcePath}, which declares requiredParts "${declaredPart}" -- a part `
              + 'this profile does not ship. Its `launch` awaits that part, so the '
              + `icon would be present and its click could only reject. Add '${declaredPart}', or `
              + 'drop the part that carries this class.');
          }
        }
      }
    }
  }

  const entryNames = ENTRY_PAGES.map(([pageFileName]) => pageFileName);
  const selectedEntryNames = resolveSelection(declared.entries, entryNames, 'entries', name);
  if (!selectedEntryNames.length) fail(`profile '${name}' ships no entry page -- there would be nothing to open`);
  const entries = ENTRY_PAGES.filter(([pageFileName]) => selectedEntryNames.includes(pageFileName));

  // The pre-compile driver boots index.html?generatePreCompiled to harvest the image, so a
  // precompiled profile that does not ship index.html could not be built at all.
  if (form === 'precompiled' && !selectedEntryNames.includes('index.html')) {
    fail(`profile '${name}': form "precompiled" needs index.html among its entries -- the `
      + 'pre-compile driver harvests the image by booting it');
  }

  // The test-harness page exists to run the harness: it opens a bare world sized to the SystemTest
  // screen and waits for a test. Shipped without the part, it would boot a world with no harness to
  // run -- and that world's constructor sizes its canvas through a member only the part installs.
  if (selectedEntryNames.includes(HARNESS_PAGE) && !selectedParts.includes(HARNESS_PART)) {
    fail(`profile '${name}': entry ${HARNESS_PAGE} needs the '${HARNESS_PART}' part among its parts -- the page exists to run `
      + 'the test harness, and without the part it would boot a world with none');
  }

  return new Profile(name, selectedParts, form, sources, entries);
}

// `--profile <name>` out of a build's raw arg list; DEFAULT_PROFILE_NAME when absent.
//
// Owned here so that build_it_please.sh, build_and_smoke.sh and build.js cannot disagree about
// which profile is being built.
function profileNameFromArgv(argv) {
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    if (argument === '--profile') {
      if (index + 1 >= argv.length) fail(`--profile needs a name. Available: ${availableProfileNames().join(', ')}`);
      return argv[index + 1];
    }
    if (argument.startsWith('--profile=')) return argument.slice('--profile='.length);
  }
  return DEFAULT_PROFILE_NAME;
}

// The facts build_it_please.sh / build_and_smoke.sh / fg need, as `eval`-able bash lines.
//
// Booleans are emitted as the literals true/false so the shell can keep its existing
// `if $SOMETHING ; then` idiom, and the boot pieces and scripts come out as bash ARRAYS (quoted as
// shlex.quote does, so a path with a space cannot break the eval). The parts' boot declarations are
// checked first (bootFiles), so a bad one fails the build at its first step, naming itself.
function shellAssignments(argv) {
  const profile = resolve(profileNameFromArgv(argv));
  const parts = loadParts();
  bootFiles(parts);
  const includeVideoPlayer = argv.includes('--includeVideoPlayer');
  const prelude = bootPrelude(parts, profile, includeVideoPlayer);
  const scripts = bootScripts(parts, profile, includeVideoPlayer);
  const flag = (b) => (b ? 'true' : 'false');
  return [
    `PROFILE_NAME=${shellQuote(profile.name)}`,
    `PROFILE_FORM=${shellQuote(profile.form)}`,
    `PROFILE_SOURCES=${shellQuote(profile.sources)}`,
    `PROFILE_SHIPS_SOURCE_TEXT=${flag(profile.shipsSourceText)}`,
    `PROFILE_SHIPS_TESTS=${flag(profile.shipsTests)}`,
    `PROFILE_SHIPS_SWCANVAS_ENTRY=${flag(profile.shipsSWCanvasEntry)}`,
    `PROFILE_SHIPS_HARNESS_ENTRY=${flag(profile.shipsHarnessEntry)}`,
    `PROFILE_BOOT_PRELUDE=(${prelude.map(shellQuote).join(' ')})`,
    `PROFILE_BOOT_SCRIPTS=(${scripts.map(shellQuote).join(' ')})`,
  ];
}

// ---- writing what a command line prints, as Python printed it ------------------------------------------------------
// stdout is strict UTF-8 (a lone surrogate fails, as Python's encoder did); stderr writes one as `\udXXX`
// (Python's stderr handler, backslashreplace).
const toStdout = (text) => encodable(text);
const toStderr = (text) => text.replace(/[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]/g, (s) => '\\u' + hex(s.charCodeAt(0), 4));

// A command line's end: the refusal's words on their stream and its exit code, or a crash's report and exit 1.
// Never process.exit: the exit code is SET, and the output already written drains before the process ends.
function finishCommandLine(error) {
  if (error instanceof Refusal) {
    (error.stream === 'stdout' ? process.stdout : process.stderr)
      .write(error.stream === 'stdout' ? toStdout(error.message + '\n') : toStderr(error.message + '\n'));
    process.exitCode = error.exitCode;
  } else {
    process.stderr.write(toStderr(String(error && error.stack || error) + '\n'));
    process.exitCode = 1;
  }
}

module.exports = {
  // the profile
  PROFILES_DIRECTORY, DEFAULT_PROFILE_NAME, PARTS_MANIFEST_FILE, CORE_PART, ENTRY_PAGES, FORMS, SOURCES_POLICIES,
  HARNESS_PART, HARNESS_PAGE, META_TOOLS_PART, BOOT_DIRECTORY,
  loadParts, checkRequiresGraph, partNames, resolveSelection, Profile, partShips, shippingParts, bootPrelude, bootScripts,
  bootFiles, availableProfileNames, resolve, profileNameFromArgv, shellAssignments,
  // the semantics build.js shares
  Refusal, PyCrash, inDirectory, py, readText, readBytes, writeText, writeAllSync, encodable, isfile, isdir, makedirs,
  copyfile, glob, pathJoin, pathBasename, pathDirname, at, toStdout, toStderr, finishCommandLine, cmpCodePoint,
};

// THE COMMAND LINE: `node ./buildSystem/lib/profile.js --shell [the build's whole arg list]` prints the shell
// assignments (shellAssignments) on stdout; a refusal goes to stderr with exit 1. Every other argument is left to
// profileNameFromArgv, which reads `--profile` and ignores the rest.
if (require.main === module) {
  try {
    const argv = process.argv.slice(2);
    if (!argv.includes('--shell')) fail("usage: profile.js --shell [the build's whole arg list]");
    const lines = shellAssignments(argv.filter((argument) => argument !== '--shell'));
    process.stdout.write(toStdout(lines.map((line) => line + '\n').join('')));
  } catch (error) {
    finishCommandLine(error);
  }
}
