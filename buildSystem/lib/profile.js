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
// rename is exactly when that happens. A refusal is THROWN (a `Refusal`, carrying its text and exit code),
// never a process exit: gates require this module in-process. Only a command line prints one -- the --shell
// one below, or build.js's -- after its own name, and sets the exit code.
//
// HOW THE INPUT IS READ. Each rule here either decides what the build WRITES, or refuses what it could not
// read faithfully:
//   - a path is relative to the WORKING DIRECTORY (Fizzygum/ when the build runs), never to this file. A
//     library caller that runs elsewhere names that directory: inDirectory(dir, fn) holds every relative path
//     of the synchronous call `fn` to it, the way a child process started with that cwd would be held;
//   - a text file is read as STRICT UTF-8: an invalid byte refuses, rather than reaching a source batch as a
//     replacement character, and a leading byte-order mark is KEPT, so a source carrying one is stored with
//     it (and a profile carrying one is not valid JSON);
//   - parts.json and a profile are checked for SHAPE as they are read (loadParts, resolve): every field the
//     build reads has one type -- a list of strings, a boolean, a pair -- and anything else refuses there,
//     naming the file, the part and the field, so no later step can misread it (a string walked as a list,
//     "false" read as true);
//   - a part, profile or entry-page NAME that reads as an array index ("0", "12") refuses: JavaScript orders
//     such an object key ahead of every other, whatever its place in the file, so a part so named would
//     silently move to the head of the boot prelude, the boot scripts and the listings (readsAsArrayIndex);
//   - a JSON string that is not well-formed Unicode (a lone surrogate, which only an escape can write)
//     refuses: no file could be written with it;
//   - what the build emits in sorted order is sorted by CODE POINT (byCodePoint): the source files -- and so
//     where each batch is cut -- and the parts manifest's parts and classes. A plain sort() compares UTF-16
//     units, which disagrees for a character beyond U+FFFF;
//   - a part directory's sources are its `*.coffee` entries, never a dot-file, and a directory that does not
//     exist holds none (filesIn).

const fs = require('fs');

// ================================================================================================================
// Reading and writing
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

// A REFUSAL: the build's own words about its input, and an exit code -- 1 for a bad profile or partition (build.js
// uses 2 for a misuse of its command line). The text carries no trailing newline and no program name: the command
// line that prints it puts its own name first.
class Refusal extends Error {
  constructor(text, exitCode = 1) {
    super(text);
    this.name = 'Refusal';
    this.exitCode = exitCode;
  }
}
function fail(message) {
  throw new Refusal(message);
}

// strict UTF-8, byte-order mark kept (see the header)
const STRICT_UTF8 = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });
function readBytes(p) {
  try {
    return fs.readFileSync(at(p));
  } catch (error) {
    return fail(`cannot read ${p}: ${error.message}`);
  }
}
function readText(p) {
  const bytes = readBytes(p);
  try {
    return STRICT_UTF8.decode(bytes);
  } catch {
    return fail(`${p} is not valid UTF-8`);
  }
}

// A JSON file: refused unless it parses, and unless every key and string in it is well-formed Unicode.
function readJson(p) {
  const text = readText(p);
  const wellFormed = (s) => {
    if (!s.isWellFormed()) fail(`${p} holds a string that is not well-formed Unicode (a lone surrogate): ${JSON.stringify(s)}`);
  };
  try {
    return JSON.parse(text, (key, value) => {
      wellFormed(key);
      if (typeof value === 'string') wellFormed(value);
      return value;
    });
  } catch (error) {
    if (error instanceof SyntaxError) fail(`${p} is not valid JSON: ${error.message}`);
    throw error;
  }
}

// Writes the text (as UTF-8) or the bytes, creating or truncating the file.
const writeFile = (p, data) => fs.writeFileSync(at(p), data);
// The DATA only, never the source's mode or extended attributes: the copy is a new file like every other the build writes.
const copyData = (source, destination) => writeFile(destination, readBytes(source));
const makeDirectory = (p) => fs.mkdirSync(at(p), { recursive: true });

// Is there a file / a directory at p? Any failure to tell -- no such path, a file where a directory is on the way --
// is "no".
function statOf(p) {
  try { return fs.statSync(at(p)); } catch { return undefined; }
}
const isFile = (p) => statOf(p)?.isFile() === true;
const isDirectory = (p) => statOf(p)?.isDirectory() === true;

// The files of directory `dir` whose names end in `suffix`, never a dot-file, each named `<dir>/<name>`, in no
// particular order (every caller sorts). Trailing slashes are dropped from `dir` first, so `src/x/` names its files
// `src/x/<name>` as `src/x` does. A directory that does not exist, or is a file, holds none.
function filesIn(dir, suffix) {
  const directory = dir.replace(/(.)\/+$/, '$1');
  let names;
  try {
    names = fs.readdirSync(at(directory));
  } catch (error) {
    if (error.code === 'ENOENT' || error.code === 'ENOTDIR') return [];
    throw error;
  }
  const prefix = directory.endsWith('/') ? directory : directory + '/';
  return names.filter((name) => name.endsWith(suffix) && !name.startsWith('.')).map((name) => prefix + name);
}

// CODE POINT order, for Array#sort: UTF-8 bytes compare in code point order, where a plain sort() compares UTF-16
// units and so puts a character beyond U+FFFF before one in U+E000..U+FFFF.
const byCodePoint = (a, b) => Buffer.compare(Buffer.from(a), Buffer.from(b));

// A word the shell reads back as exactly `s`: as it is when it holds only characters no shell treats specially (the
// ASCII word characters and @%+=:,./-), `''` when empty, else single-quoted, each `'` in it written `'"'"'`. The
// --shell answers are eval'd, so this spelling is part of what they say.
const SHELL_UNSAFE = /[^\w@%+=:,./-]/;
const shellQuote = (s) => (!s ? "''" : !SHELL_UNSAFE.test(s) ? s : "'" + s.split("'").join("'\"'\"'") + "'");

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

// A NAME THAT READS AS AN ARRAY INDEX -- a canonical non-negative integer below 2^32 - 1, "0" or "12" but not "01" --
// is one JavaScript orders AHEAD of every other key of an object, in ascending numeric order, wherever it was written.
// Part names are object keys (parts.json's "parts"), so such a part would move to the head of every walk over the
// partition -- the boot prelude, the boot scripts, the listings -- with no word said. Refused for every name a build
// declares: a part, a profile, an entry page.
const readsAsArrayIndex = (name) => /^(?:0|[1-9][0-9]*)$/.test(name) && Number(name) <= 2 ** 32 - 2;
// `said` is what comes before the name: "buildSystem/parts.json declares a part named", "the profile is named", …
function refuseIndexLikeName(name, said) {
  if (readsAsArrayIndex(name)) {
    fail(`${said} '${name}', which reads as an array index -- JavaScript orders such an object key ahead of every other, `
      + 'whatever its place, so the build refuses it for any name it declares (a part so named would silently move to '
      + 'the head of the boot prelude, the boot scripts and the listings). Rename it.');
  }
}

const isPlainObject = (v) => typeof v === 'object' && v !== null && !Array.isArray(v);
const isString = (v) => typeof v === 'string';
const isStringList = (v) => Array.isArray(v) && v.every(isString);

// THE SHAPE OF A PART: each LIST field the build reads, as [field, what it must be, the test of one item]. `dirs` is
// required (see loadParts) and the rest optional; `eager`, the one field that is no list, is true or false; and
// "//"-prefixed keys are prose. parts.json's header says what each field means.
const PART_LIST_FIELDS = [
  ['dirs', 'a list of directory paths', isString],
  ['requires', 'a list of part names', isString],
  ['bootPrelude', 'a list of src/boot file paths', isString],
  ['bootScripts', 'a list of src/boot file paths', isString],
  ['assets', 'a list of [source file, destination directory] pairs', (pair) => isStringList(pair) && pair.length === 2],
  ['vendor', 'a list of {"out": <path>, "concat": [<paths>]} objects',
    (entry) => isPlainObject(entry) && isString(entry.out) && isStringList(entry.concat)],
];

// The partition, from buildSystem/parts.json (or another parts file: a bite-proof's planted one, through
// build.js --parts), its shape checked (PART_LIST_FIELDS) and its `requires` graph too. Read that file's header before
// changing this.
function loadParts(p = PARTS_MANIFEST_FILE) {
  const manifest = readJson(p);
  if (!isPlainObject(manifest) || !isPlainObject(manifest.parts)) fail(`${p} must be an object whose "parts" is an object, one key per part`);
  const parts = manifest.parts;
  for (const name of partNames(parts)) {
    refuseIndexLikeName(name, `${p} declares a part named`);
    const part = parts[name];
    const field = (key) => `${p}: part '${name}' "${key}"`;
    if (!isPlainObject(part)) fail(`${p}: part '${name}' must be an object -- got ${JSON.stringify(part)}`);
    if (!Object.hasOwn(part, 'dirs')) fail(`${field('dirs')} is missing -- every part names the directories it owns`);
    if (Object.hasOwn(part, 'eager') && typeof part.eager !== 'boolean') fail(`${field('eager')} must be true or false -- got ${JSON.stringify(part.eager)}`);
    for (const [key, shape, isWellShapedItem] of PART_LIST_FIELDS) {
      if (!Object.hasOwn(part, key)) continue;
      const value = part[key];
      if (!Array.isArray(value)) fail(`${field(key)} must be ${shape} -- got ${JSON.stringify(value)}`);
      const bad = value.findIndex((item) => !isWellShapedItem(item));
      if (bad >= 0) fail(`${field(key)} must be ${shape} -- its item ${bad} is ${JSON.stringify(value[bad])}`);
    }
  }
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
    for (const required of parts[name].requires ?? []) {
      if (!names.has(required)) {
        fail(`part '${name}' requires '${required}', which is not a part in ${PARTS_MANIFEST_FILE}`);
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
    for (const next of parts[node].requires ?? []) {
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
const partNames = (parts) => Object.keys(parts).filter((name) => !name.startsWith('//'));

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

  // every name a selection states: a string, not one that reads as an array index, and one the build declares
  const checkNamed = (names, how) => {
    for (const name of names) {
      if (typeof name !== 'string') fail(`profile '${profileName}': "${what}" ${how} ${JSON.stringify(name)}, which is not a name`);
      refuseIndexLikeName(name, `profile '${profileName}': "${what}" ${how}`);
      if (!universe.includes(name)) {
        fail(`profile '${profileName}': "${what}" ${how} '${name}', which the build does not declare `
          + `(known ${what}: ${universe.join(', ')})`);
      }
    }
  };

  if (isPlainObject(spec)) {
    const unknownKeys = Object.keys(spec).filter((key) => key !== 'allExcept');
    if (unknownKeys.length || !Object.hasOwn(spec, 'allExcept')) {
      fail(`profile '${profileName}': "${what}" ${unknownKeys.length ? `has unknown key(s) ${unknownKeys.sort().join(', ')}` : 'has no "allExcept"'} `
        + '-- the only object form is {"allExcept": [...]}');
    }
    const excluded = spec.allExcept;
    if (!Array.isArray(excluded)) fail(`profile '${profileName}': "${what}" allExcept must be a list`);
    checkNamed(excluded, 'allExcept names');
    return universe.filter((name) => !excluded.includes(name));
  }

  if (Array.isArray(spec)) {
    checkNamed(spec, 'names');
    return universe.filter((name) => spec.includes(name));
  }

  return fail(`profile '${profileName}': "${what}" must be "all", a list, or {"allExcept": [...]} -- got ${JSON.stringify(spec)}`);
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
    // the resolved part NAMES this profile selects: the parts that ship (selectsPart)
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

  // Does this part ship in the build being made? THE part-inclusion rule, written once: a part
  // ships exactly when the profile selects it. Nothing else is asked -- no build flag, no per-part
  // opt-in -- so build.js and build_it_please.sh (through --shell) cannot disagree about it.
  selectsPart(partName) { return this.selectedParts.includes(partName); }
}

// [name, spec] for every part that ships, in parts.json order.
const shippingParts = (parts, profile) =>
  partNames(parts).filter((name) => profile.selectsPart(name)).map((name) => [name, parts[name]]);

// The src/boot/ pieces that shipping parts contribute to the boot bundle, in order.
//
// A part can own more than sources: `assets` are copied, `vendor` payloads assembled, and its
// `bootPrelude` pieces are concatenated into the boot bundle -- core's own (boot itself: the
// SourceVault, globalFunctions, the built-in prototype extensions) first, whatever its place in
// parts.json, then every other shipping part's in partition order (e.g. fizzytiles'
// numbertimes.coffee, which extends Number for the LiveCodeLang preprocessor).
function bootPrelude(parts, profile) {
  const pieces = [];
  const shipping = shippingParts(parts, profile);
  for (const [, part] of [...shipping.filter(([name]) => name === CORE_PART), ...shipping.filter(([name]) => name !== CORE_PART)]) {
    pieces.push(...(part.bootPrelude ?? []));
  }
  return pieces;
}

// The src/boot/ files that shipping parts have compiled one by one to js/src/<name>-min.js, which
// boot fetches by name.
function bootScripts(parts, profile) {
  const scripts = [];
  for (const [, part] of shippingParts(parts, profile)) scripts.push(...(part.bootScripts ?? []));
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
      for (const piece of parts[name][key] ?? []) {
        if (!piece.startsWith(BOOT_DIRECTORY + '/') || piece.split('/').includes('..')) {
          fail(`part '${name}' ${key} names '${piece}', which is not under ${BOOT_DIRECTORY}/`);
        }
        const physical = srcRoot ? srcRoot.replace(/\/+$/, '') + piece.slice('src'.length) : piece;
        if (!isFile(physical)) fail(`part '${name}' ${key} names '${piece}', which does not exist`);
        if (declaredBy.has(piece)) {
          fail(`'${piece}' is declared twice in ${partsFile}: by part '${declaredBy.get(piece)}' and by part '${name}' (${key})`);
        }
        declaredBy.set(piece, name);
        if (key === 'bootScripts') {
          if (!piece.endsWith('.coffee')) {
            fail(`part '${name}' bootScripts names '${piece}', which is no .coffee file (each is compiled to js/src/<name>-min.js)`);
          }
          const scriptName = piece.slice(piece.lastIndexOf('/') + 1);
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
  filesIn(PROFILES_DIRECTORY, '.json').map((p) => p.slice(PROFILES_DIRECTORY.length + 1, -'.json'.length)).sort(byCodePoint);

// `requiredParts: [ … ]`, a class's own statement of the parts its `launch` awaits: the FIRST such line of a source.
const REQUIRED_PARTS_DECLARATION = /^\s*requiredParts\s*:\s*\[([^\]]*)\]/m;

// Load and fully validate profiles/<name>.json. Any problem is fatal (see the module header).
function resolve(name) {
  refuseIndexLikeName(name, 'the profile is named');
  const p = `${PROFILES_DIRECTORY}/${name}.json`;
  if (!isFile(p)) {
    fail(`no such profile '${name}' (${p} does not exist). Available: ${availableProfileNames().join(', ') || 'none'}`);
  }
  const declared = readJson(p);
  if (!isPlainObject(declared)) fail(`profile '${name}' must be a JSON object (${p}) -- got ${JSON.stringify(declared)}`);

  // An unknown key is a typo that would otherwise be silently ignored, and a silently-ignored
  // `"from": "precompiled"` ships a compile-at-boot tree while claiming otherwise.
  const allowed = ['//', 'parts', 'form', 'sources', 'entries'];
  const unknownKeys = Object.keys(declared).filter((key) => !allowed.includes(key));
  if (unknownKeys.length) {
    fail(`profile '${name}' has unknown key(s): ${unknownKeys.sort().join(', ')}. A profile declares exactly `
      + `${allowed.slice(1).join('/')} (everything else about a build is DERIVED -- see buildSystem/lib/profile.js's header).`);
  }
  // the keys every profile must state: the allowed ones bar the prose key and `sources` (whose rule is the form's)
  for (const key of allowed.filter((k) => k !== '//' && k !== 'sources')) {
    if (!Object.hasOwn(declared, key)) fail(`profile '${name}' is missing "${key}"`);
  }

  const form = declared.form;
  if (!FORMS.includes(form)) fail(`profile '${name}': form must be one of ${FORMS.join(' / ')} -- got ${JSON.stringify(form)}`);

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
      fail(`profile '${name}': sources must be one of ${SOURCES_POLICIES.join(' / ')} -- got ${JSON.stringify(sources)}`);
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
      if (parts[partName].eager === false) {
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
    for (const requiredPart of parts[partName].requires ?? []) {
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
    for (const sourceDir of parts[partName].dirs) {
      for (const sourcePath of filesIn(sourceDir, '.coffee').sort(byCodePoint)) {
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
  for (const entryName of entryNames) refuseIndexLikeName(entryName, 'ENTRY_PAGES declares an entry page named');
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
// `if $SOMETHING ; then` idiom, and the boot pieces and scripts come out as bash ARRAYS (each word
// quoted by shellQuote, so a path with a space cannot break the eval). The parts' boot declarations are
// checked first (bootFiles), so a bad one fails the build at its first step, naming itself.
function shellAssignments(argv) {
  const profile = resolve(profileNameFromArgv(argv));
  const parts = loadParts();
  bootFiles(parts);
  const prelude = bootPrelude(parts, profile);
  const scripts = bootScripts(parts, profile);
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

// A command line's end: a refusal's words on stderr after the program's name, and its exit code; anything else is a
// fault this module did not foresee, printed as Node prints it, exit 1. Never stdout: a --shell caller's command
// substitution must capture no junk there (an eval of a half-written assignment list is worse than no output). Never
// process.exit: the exit code is SET, and the output already written drains before the process ends.
function finishCommandLine(error, program) {
  if (error instanceof Refusal) {
    process.stderr.write(`${program}: ${error.message}\n`);
    process.exitCode = error.exitCode;
  } else {
    process.stderr.write(String((error && error.stack) || error) + '\n');
    process.exitCode = 1;
  }
}

module.exports = {
  // the profile
  PROFILES_DIRECTORY, DEFAULT_PROFILE_NAME, PARTS_MANIFEST_FILE, CORE_PART, ENTRY_PAGES, FORMS, SOURCES_POLICIES,
  HARNESS_PART, HARNESS_PAGE, META_TOOLS_PART, BOOT_DIRECTORY,
  loadParts, checkRequiresGraph, partNames, resolveSelection, Profile, shippingParts, bootPrelude, bootScripts,
  bootFiles, availableProfileNames, resolve, profileNameFromArgv, shellAssignments,
  // the reading and writing build.js shares
  Refusal, inDirectory, readText, readBytes, writeFile, copyData, makeDirectory, isFile, isDirectory, filesIn,
  byCodePoint, finishCommandLine,
};

// THE COMMAND LINE: `node ./buildSystem/lib/profile.js --shell [the build's whole arg list]` prints the shell
// assignments (shellAssignments) on stdout; a refusal goes to stderr with exit 1. Every other argument is left to
// profileNameFromArgv, which reads `--profile` and ignores the rest.
if (require.main === module) {
  try {
    const argv = process.argv.slice(2);
    if (!argv.includes('--shell')) fail("no --shell given -- usage: profile.js --shell [the build's whole arg list]");
    const lines = shellAssignments(argv.filter((argument) => argument !== '--shell'));
    process.stdout.write(lines.map((line) => line + '\n').join(''));
  } catch (error) {
    finishCommandLine(error, 'profile.js');
  }
}
