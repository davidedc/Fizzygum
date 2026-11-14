#!/usr/bin/env node
'use strict';
// not-a-gate: the build step that assembles the tree; the gates are the checks it is followed by
//
// build.js -- performs only some of the steps of the build (build_it_please.sh does the rest):
//
// 1) For each class file (not all of the coffee files are class files), it
//    generates a special string that contains the coffeescript source of the
//    file itself.  This is so we can enable editing of the classes in
//    coffeescript within the running system, and do something like
//    generating the documentation on the fly.
//
// 2) Passes over the files that DON'T contain classes (it names each as it goes):
//    the boot files are compiled into the boot bundle by build_it_please.sh.
//
// 3) Generates the entry pages (see ENTRY_PAGES) from the single page source,
//    each one presetting its rendering backend and loading the matching boot
//    bundle.
//
// It is also the one LISTING of the partition the gates read, without building anything: `--list-shippable` (every
// .coffee file a part claims) and `--list-boot` (every src/boot file a part declares). A gate does not start this file
// to ask: it requires it and calls listShippable(args) / listBoot(args) (exported below; requiring this module runs
// nothing), which run the very command line -- the same argument parsing, the same refusals, a refusal THROWN with its
// exact text -- and return the lines that command line would print.
//
// Its command line is small and strict (THE ARGUMENTS below): anything it does not know is refused, exit 2, with a
// one-line usage. Every path, order and byte it reads or writes follows lib/profile.js's reading of the input (its
// header says how).

const path = require('path');

// THE FLAVOUR, as data. lib/profile.js reads buildSystem/profiles/<name>.json and derives from it
// everything this build used to decide by asking "is this the homepage?" -- read its header first.
// It also owns the two tables we share with build_it_please.sh: the partition (parts.json, via
// loadParts) and the entry pages, whose SWCanvas column the shell needs to know whether to assemble
// the SW boot bundle. One table, two readers.
const profileLib = require('./lib/profile');
const { loadParts, partNames, Refusal, inDirectory, readText, readBytes, writeFile, copyData, makeDirectory, isFile, isDirectory,
  filesIn, byCodePoint, finishCommandLine } = profileLib;

// GLOBALS
const INPUT_HTML_FILE = 'src/index.html';
const OUTPUT_HTML_DIRECTORY = '../Fizzygum-builds/latest';

// The single placeholder in src/index.html that lets ONE page source serve every
// entry page. It is replaced by the backend preset plus the matching boot-bundle
// tag — in that order, because globalFunctions.coffee reads
// window.FIZZYGUM_USE_SWCANVAS while the bundle executes.
const BOOT_SCRIPTS_PLACEHOLDER = '<!--FIZZYGUM_BOOT_SCRIPTS-->';

// (ENTRY_PAGES — the pages, their backend preset and their eagerness preset — comes from
// lib/profile.js above, which is where a profile's `entries` list is resolved against it.)

// IS THIS SOURCE A CLASS FILE? -- the one test, here because this is the module that wraps the class sources
// (check-coffee-syntax.js and lib/call-sites.js require it rather than keep a copy). A line opening `class <Name>`:
// at the start of the text or right after a `\n` (a `\r` or U+2028 starts no line here), the name a run of word
// characters -- letters and digits of any script, and `_`.
const IS_CLASS = /(?:^|(?<=\n))class +([\p{L}\p{N}_]+)/u;

// HOW A FLAVOUR EXCLUDES CODE: it drops whole PARTS, named in buildSystem/parts.json. There is no
// marker of any kind in a source file, and no regex here that reads one. Two mechanisms were retired
// to get here, both of which worked by cutting text the build could not see the meaning of:
//
//   1. per-REGION stripping (arc 3): a `# »>> this part is …` comment opened a span ending at the
//      next comment carrying `«`, and the span was cut out of the source TEXT. It had accreted for
//      eight+ years without an audit; the audit found it stripping PRODUCT code out of the homepage
//      -- core sizing and `_reLayout` machinery, class constants that silently became `nil`, public
//      API -- because nothing about a comment tells you whether what follows is dev scaffolding or
//      the layout engine. Its 63 sites were RE-HOMED: promoted where they were product, moved to
//      ../Fizzygum-tests/Automator-and-test-harness-src/ where they were test machinery, or
//      extracted into their own collaborator class (PinoutsOverlay, DemoMenus).
//   2. per-FILE markers (arc 4): `# this file is excluded from the fizzygum homepage
//      build` (43 files), `# this file is only needed for Macros` (2), and
//      `# this file is only needed for VideoPlayer` (0 -- a regex with no carriers at all, live in
//      the build for who knows how long). A file's fate was written invisibly in its first line, so
//      the shape of a production build could only be learned by opening 499 files. It is now a
//      property of a named slice, stated once, where the whole partition is visible at a glance.
//
// Both are gated at zero and cannot come back: buildSystem/check-region-markers.js and
// buildSystem/check-whole-file-markers.js. Deliberately there is NO replacement marker syntax --
// the lesson was that invisible, text-level exclusion is the wrong tool, not that its spelling was
// wrong. A call site copes with an absent part through an existence guard (`if DemoMenus?`,
// `world.pinouts?.…`), which buildSystem/check-part-edges.js requires.

// ================================================================================================================
// THE ARGUMENTS
// ================================================================================================================
// THE FLAVOUR: --profile, a profile name, resolved by lib/profile.js against buildSystem/profiles/<name>.json.
// It replaced the --homepage and --notests flags (arc 5): a flavour is data, and adding one is
// adding a file rather than threading a boolean through two scripts. A stale `--homepage` on a
// command line now fails here, loudly, instead of silently building something else.
// --noSyntaxCheck is consumed by build_it_please.sh, which forwards ALL of its args to
// us; we accept it here as a no-op so the forwarded flag is not refused.
// --list-shippable: print the source files that WOULD be shipped (one per line) and
// exit WITHOUT building anything. This is the single source of truth for the build-time
// syntax gate (buildSystem/check-coffee-syntax.js), so the gate's file set can never
// drift from what the build actually wraps-as-text and compiles in-browser.
// --list-boot: print the src/boot files the parts declare (their `bootPrelude` and `bootScripts`), one per line as
// `<file>\t<part>\t<prelude|script>`, flavour-independent, and exit, failing on a piece that is not under src/boot/,
// does not exist or is named twice, or a boot script that is no .coffee file. The one listing of the boot files
// (buildSystem/lib/boot-pieces.js): the coverage gate reads its files and holds boot's by-name fetches to its scripts,
// the syntax gate takes the helper globals from core's files, the part-edges gate each file's part, what-pins-core
// its roots.
// Not classes, so not in --list-shippable (the syntax and part-edges gates compile what that lists the class way):
// buildSystem/check-shippable-coverage.js reads both, so every src/boot file is held to a declaration too.
// --src=DIR / --tests-repo=DIR / --parts=FILE, with a listing only: list the partition of ANOTHER src tree or
// tests repo, or by another parts.json -- a static gate's bite-proof hands its gate a planted copy
// (buildSystem/lib/planted-src.js), and the gates that read this list must read the copy's. A part directory under `src`
// is listed under the --src= DIR instead, one under `../Fizzygum-tests` under the --tests-repo= DIR; every path is still
// printed as parts.json spells it (`src/...`, `../Fizzygum-tests/...`), so a gate maps it back onto the tree it was
// handed. An empty or missing value is refused.
// -h / --help prints the usage line and exits 0, building nothing.
//
// THE RULES: each option at most once -- a second `--profile` is refused rather than overriding the first, since
// lib/profile.js's --shell, which reads the same arg list for build_it_please.sh, takes the first; an option taking a
// value takes it as `--opt=value` or as the next argument, which may not start with `-`; a flag takes no value; an
// option is spelled whole. Anything else -- an unknown option, a positional argument -- is refused, exit 2, with the
// usage line.
const VALUE_OPTIONS = new Map([['--profile', 'profile'], ['--src', 'src'], ['--tests-repo', 'testsRepo'], ['--parts', 'parts']]);
const FLAG_OPTIONS = new Map([['--noSyntaxCheck', 'noSyntaxCheck'], ['--list-shippable', 'listShippable'], ['--list-boot', 'listBoot']]);
const USAGE = 'usage: build.js [--profile NAME] [--noSyntaxCheck] '
  + '[--list-shippable | --list-boot [--src DIR] [--tests-repo DIR] [--parts FILE]]';

// The arguments, or a refusal (exit 2). `help` set means: print USAGE, do nothing else.
function parseArgs(argv) {
  const misuse = (problem) => new Refusal(`${problem}\n${USAGE}`, 2);
  if (argv.includes('-h') || argv.includes('--help')) return { help: true };
  const args = { help: false, profile: profileLib.DEFAULT_PROFILE_NAME, noSyntaxCheck: false, listShippable: false, listBoot: false,
    src: undefined, testsRepo: undefined, parts: undefined };
  const given = new Set();
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    const equals = argument.startsWith('--') ? argument.indexOf('=') : -1;
    const option = equals < 0 ? argument : argument.slice(0, equals);
    if (!VALUE_OPTIONS.has(option) && !FLAG_OPTIONS.has(option)) throw misuse(`unknown argument '${argument}'`);
    if (given.has(option)) throw misuse(`${option} is given twice`);
    given.add(option);
    if (FLAG_OPTIONS.has(option)) {
      if (equals >= 0) throw misuse(`${option} takes no value`);
      args[FLAG_OPTIONS.get(option)] = true;
    } else if (equals >= 0) {
      args[VALUE_OPTIONS.get(option)] = argument.slice(equals + 1);
    } else {
      const value = argv[index + 1];
      if (value === undefined || value.startsWith('-')) throw misuse(`${option} needs a value`);
      args[VALUE_OPTIONS.get(option)] = value;
      index++;
    }
  }

  // which arguments go together
  if (args.listShippable && args.listBoot) throw misuse('--list-shippable and --list-boot are two listings: ask for one');
  if ((args.src !== undefined || args.testsRepo !== undefined || args.parts !== undefined) && !(args.listShippable || args.listBoot)) {
    throw misuse('--src, --tests-repo and --parts only qualify --list-shippable and --list-boot');
  }
  if (args.src !== undefined && !isDirectory(args.src)) throw misuse(`--src names no directory: '${args.src}'`);
  if (args.testsRepo !== undefined && !isDirectory(args.testsRepo)) throw misuse(`--tests-repo names no directory: '${args.testsRepo}'`);
  if (args.parts !== undefined && !isFile(args.parts)) throw misuse(`--parts names no file: '${args.parts}'`);
  return args;
}

// ================================================================================================================
// THE BUILD
// ================================================================================================================

// Writes one entry page from the single page source, substituting the backend
// preset + boot-bundle tag for BOOT_SCRIPTS_PLACEHOLDER. Everything else about
// the page (splash, canvas, onload -> boot()) is shared verbatim.
function generateEntryPage(srcHTMLFile, destHTMLFile, useSWCanvas, eagerAllParts) {
  const content = readText(srcHTMLFile);

  if (!content.includes(BOOT_SCRIPTS_PLACEHOLDER)) {
    throw new Refusal(
      srcHTMLFile + ' has no ' + BOOT_SCRIPTS_PLACEHOLDER
      + ' placeholder — an entry page without a backend preset would load one'
      + ' engine and drive the other.');
  }

  const bundleFileName = useSWCanvas ? 'fizzygum-boot-sw-min.js' : 'fizzygum-boot-native-min.js';
  const bootScripts =
    '<script type="text/javascript">window.FIZZYGUM_USE_SWCANVAS = '
    + (useSWCanvas ? 'true' : 'false')
    + '; window.FIZZYGUM_EAGER_ALL_PARTS = '
    + (eagerAllParts ? 'true' : 'false') + ';</script>\n'
    + '\t\t<script type="text/javascript" src="js/' + bundleFileName + '"></script>';

  writeFile(destHTMLFile, content.split(BOOT_SCRIPTS_PLACEHOLDER).join(bootScripts));
}

const TESTS_REPO_PREFIX = '../Fizzygum-tests';

// Every .coffee file the partition claims, in ANY flavour, as [orderedFilenames, partOfFile].
//
// Flavour-INDEPENDENT on purpose. Two build gates read this set through --list-shippable:
// check-coffee-syntax.js (parse every shipped source) and check-shippable-coverage.js (every src/
// directory is claimed by some part). Both want "everything that can ship", not "what this
// particular flavour ships" -- a syntax error in a file only the dev build carries is still a
// syntax error, and coverage of the partition is not a property of one flavour. Use shippedFiles()
// for the flavour-applied set.
//
// The order is a plain codepoint sort of the full path, which is what the build has always emitted
// in (it re-sorted the whole accumulated list after every directory it added). The emission order
// decides where the source batches get cut, so preserving it exactly is what makes a build
// byte-comparable against its predecessor.
function partitionFiles(parts, srcRoot, testsRepoRoot) {
  const partOfFile = new Map();
  for (const partName of partNames(parts)) {
    for (const eachDir of parts[partName].dirs) {
      // another src tree (--src) or tests repo (--tests-repo): a dir under it is listed there, and named as
      // parts.json spells it, src/... or ../Fizzygum-tests/..., as always
      let spelled, root;
      for (const [prefix, given] of [['src', srcRoot], [TESTS_REPO_PREFIX, testsRepoRoot]]) {
        if (given !== undefined && (eachDir === prefix || eachDir.startsWith(prefix + '/'))) {
          spelled = prefix;
          root = given.replace(/\/+$/, '');
        }
      }
      const physical = root ? root + eachDir.slice(spelled.length) : eachDir;
      for (const found of filesIn(physical, '.coffee')) {
        const filename = root ? spelled + found.slice(root.length) : found;
        if (partOfFile.has(filename)) {
          throw new Refusal(`${filename} is claimed by two parts: ${partOfFile.get(filename)} and ${partName}. Every directory belongs to `
            + `exactly one part -- see ${profileLib.PARTS_MANIFEST_FILE}.`);
        }
        partOfFile.set(filename, partName);
      }
    }
  }
  return [[...partOfFile.keys()].sort(byCodePoint), partOfFile];
}

// A declared-but-missing file is a HARD failure, not a warning: a payload silently not written
// is the failure mode this whole mechanism replaced (the tree looks fine, and a page 404s for an
// <img> or an injected script at runtime).
function requirePartFile(partName, sourcePath, kind) {
  if (!isFile(sourcePath)) {
    throw new Refusal(`part '${partName}' declares ${kind} that does not exist: ${sourcePath} (buildSystem/parts.json)`);
  }
}

// Materialise the non-source files owned by every part that SHIPS in this flavour: plain assets
// (copied) and vendor payloads (assembled from their pieces).
//
// This is what makes "what a flavour ships" follow from which parts ship, instead of being a
// per-flavour prune list. A part that does not ship writes nothing. Whether a part ships is
// answered once, by lib/profile.js's Profile.selectsPart: build_it_please.sh asks the same question
// (through its --shell mode) to decide what else goes into the tree, and one question answered in
// two places is how a flavour ends up shipping half a part.
function copyPartAssets(parts, profile, sink) {
  let copiedAssets = 0;
  let builtPayloads = 0;
  for (const partName of partNames(parts)) {
    const part = parts[partName];
    if (!profile.selectsPart(partName)) continue;

    for (const [sourcePath, destinationDirectory] of part.assets ?? []) {
      requirePartFile(partName, sourcePath, 'an asset');
      const fullDestinationDirectory = path.join(OUTPUT_HTML_DIRECTORY, destinationDirectory);
      makeDirectory(fullDestinationDirectory);
      copyData(sourcePath, path.join(fullDestinationDirectory, path.basename(sourcePath)));
      copiedAssets += 1;
    }

    // Vendor payloads: concatenate the pieces, each followed by a newline-semicolon separator
    // that terminates the unit and defends against ASI between them (the same separator the
    // boot-bundle assembly uses).
    for (const { out, concat } of part.vendor ?? []) {
      const pieces = concat.map((piece) => {
        requirePartFile(partName, piece, 'a vendor payload piece');
        return readBytes(piece);
      });
      const outputPath = path.join(OUTPUT_HTML_DIRECTORY, out);
      makeDirectory(path.dirname(outputPath));
      writeFile(outputPath, Buffer.concat(pieces.flatMap((piece) => [piece, Buffer.from('\n;\n')])));
      builtPayloads += 1;
    }
  }

  sink.stdout(`copied ${copiedAssets} part asset(s), assembled ${builtPayloads} vendor payload(s)\n`);
}

// The subset of the partition this flavour actually ships, in emission order.
function shippedFiles(parts, partOfFile, orderedFilenames, profile) {
  const excluded = new Set(partNames(parts).filter((name) => !profile.selectsPart(name)));
  return orderedFilenames.filter((f) => !excluded.has(partOfFile.get(f)));
}

// a string's length in CODE POINTS: a batch is cut once its text passes a length in code points, so this measure
// decides which source opens each batch file
function codePointLength(s) {
  let n = s.length;
  for (let i = 0; i < s.length - 1; i++) {
    const c = s.charCodeAt(i);
    if (c >= 0xD800 && c <= 0xDBFF) { const d = s.charCodeAt(i + 1); if (d >= 0xDC00 && d <= 0xDFFF) { n--; i++; } }
  }
  return n;
}

// THE PARTS MANIFEST'S SPELLING, fixed byte for byte (boot reads it as CoffeeScript, and a build is compared with its
// predecessor by its bytes): every object's keys in code point order, `, ` between items and `: ` after a key, and
// every character outside printable ASCII escaped -- as a backslash, `u` and four lowercase hex digits, one beyond
// U+FFFF as its two UTF-16 halves. It spells what the manifest holds: Maps, arrays, strings and booleans.
function manifestJson(value) {
  if (value instanceof Map) {
    return '{' + [...value.keys()].sort(byCodePoint).map((key) => asciiJsonString(key) + ': ' + manifestJson(value.get(key))).join(', ') + '}';
  }
  if (Array.isArray(value)) return '[' + value.map(manifestJson).join(', ') + ']';
  if (typeof value === 'string') return asciiJsonString(value);
  if (typeof value === 'boolean') return String(value);
  throw new Error(`build.js: the parts manifest holds a value it has no spelling for: ${typeof value}`);
}
// JSON.stringify already escapes every control character; what it leaves raw outside printable ASCII is DEL and
// everything above it, each UTF-16 unit of which is escaped here
const asciiJsonString = (s) => JSON.stringify(s).replace(/[^ -~]/g, (unit) => '\\u' + unit.charCodeAt(0).toString(16).padStart(4, '0'));

function main(args, sink) {
  const profile = profileLib.resolve(args.profile);
  const parts = loadParts(args.parts);
  // --list-boot: the parts' declared src/boot files (lib/profile.js bootFiles checks each), then stop
  if (args.listBoot) {
    for (const [filename, part, kind] of profileLib.bootFiles(parts, args.src, args.parts ?? profileLib.PARTS_MANIFEST_FILE)) {
      sink.stdout(filename + '\t' + part + '\t' + kind + '\n');
    }
    return;
  }
  const [allFilenames, partOfFile] = partitionFiles(parts, args.src, args.testsRepo);

  // --list-shippable: emit the partition's file list and stop (see THE ARGUMENTS above).
  // One path per line, consumed by buildSystem/check-coffee-syntax.js and
  // buildSystem/check-shippable-coverage.js. Flavour-independent -- see partitionFiles().
  // We return BEFORE any output files are written, so nothing is built.
  if (args.listShippable) {
    for (const filename of allFilenames) sink.stdout(filename + '\n');
    return;
  }

  const filenames = shippedFiles(parts, partOfFile, allFilenames, profile);

  // Each class's .coffee text reaches the page as one line of a .js file -- a script, because a page
  // opened over file:// cannot fetch a .json file -- that hands the text to the SourceVault:
  // `SourceVault.store("<Name>", "<text>", "<part>");`. Every argument is written by JSON.stringify,
  // and a JSON string is a JavaScript string literal for any text (U+2028 and U+2029 included, since
  // ES2019), so the vault receives each source exactly as its file holds it, with nothing to decode.
  // The PART name is the third argument: it is what lets a slice of the system be
  // loaded on demand rather than all-at-boot (docs/archive/build-arc-4-dynamic-parts-plan.md).
  const STRING_BLOCK = (name, text, part) => 'SourceVault.store(' + JSON.stringify(name) + ', ' + JSON.stringify(text) + ', ' + JSON.stringify(part) + ');';

  // now iterate through the source files and create
  // 1) a few js files with A BATCH OF coffeescript sources
  //    (so we load ~15 source batches rather than ~500 sources)
  // 2) the count of the batches we ended up creating, so the boot code
  //    knows how many to load
  // We used to ALSO write one js file per class next to the batches, and load
  // none of them: ~500 files and ~3 MB of duplicate source per dev build that
  // only the --homepage flavour bothered to delete again. Arc 4 dropped them.
  // The one exception -- the Class source -- is still emitted as its own file
  // below, because it IS loaded individually and early (globalFunctions loads it
  // before any batch: the meta-system has to exist before a batch's contents can
  // be ingested).

  // Batches are cut PER PART, so a part's sources arrive as a unit that can be fetched on its
  // own. Core's batches keep the historical bare `sources_batch_<n>.js` name and every other
  // part's carry its name (`sources_batch_fizzytiles_0.js`): core is the default, and keeping its
  // filenames unchanged is what lets a build be compared byte-for-byte against its predecessor
  // (which is how the marker->parts migration was proven not to change what ships).
  const batchesOfPart = new Map();   // part -> [batch file basenames], in load order
  const classesOfPart = new Map();   // part -> [class names] (the manifest's class->part map)
  const accumulator = new Map();     // part -> { text, length }: the batch text being filled, its length in code points
  const minimumSourcesBatchSize = 150000;

  const batchBaseName = (partName, index) => (partName === 'core' ? 'sources_batch_' + index : 'sources_batch_' + partName + '_' + index);

  // Flush the part's accumulated text as its next batch file.
  const writeBatch = (partName) => {
    if (!batchesOfPart.has(partName)) batchesOfPart.set(partName, []);
    const basename = batchBaseName(partName, batchesOfPart.get(partName).length);
    writeFile('../Fizzygum-builds/latest/js/coffeescript-sources/' + basename + '.js', accumulator.get(partName).text);
    batchesOfPart.get(partName).push(basename);
    accumulator.set(partName, { text: '', length: 0 });
  };

  for (const filename of filenames) {
    sink.stdout('>>>> ' + filename + ' \n');
    // open file and read its contents
    const content = readText(filename);

    // if the file is a class, then we hand its source code to the SourceVault
    // (string block).
    // We check if the file is a class by searching its contents for a
    // class ... declaration.
    const isClassFile = IS_CLASS.test(content);

    // every class file's coffeescript source is emitted as text
    // inside a SourceVault.store call, batched into a handful of js files.
    // The boot code loads those batches and then ingests/compiles each source
    // in dependency order. This is what lets Fizzygum load its classes as
    // coffeescript source code -- and, per part, load them lazily.
    //
    // There is no flavour test here any more: `filenames` is already the set this
    // flavour ships (shippedFiles(), from the partition in buildSystem/parts.json).
    // It used to be `not args.homepage or not (three marker regexes match)` -- i.e.
    // every file carried, invisibly in its first line, the question of whether it
    // ships. See parts.json's header for why that moved out of the files.
    // ⚠ Emitted for EVERY profile, including sources: "none". The source text is what the
    // pre-compile driver compiles to harvest the image, so a "none" artifact needs it DURING its
    // own build and simply does not ship it -- build_it_please.sh drops the directory after the
    // driver has run, the same shape as the font-assets re-prune: derived from the policy, not a
    // list of files to delete.
    if (isClassFile) {
      // the vault is keyed by CLASS name, which is the file's basename
      // (one class per file, filename == class name -- see the repo CLAUDE.md)
      const sourceName = path.basename(filename).split('.coffee').join('');
      const storeLine = STRING_BLOCK(sourceName, content, partOfFile.get(filename));

      // Class is the one source loaded individually and EARLY, because the meta-system
      // has to exist before any batch's contents can be ingested (see globalFunctions'
      // boot sequence and its META_SYSTEM_SOURCES). Every other source travels in a batch only.
      if (sourceName === 'Class') {
        writeFile('../Fizzygum-builds/latest/js/coffeescript-sources/' + sourceName + '-source.js', storeLine);
      }

      // pile up the sources into this part's batch, and save the batch when it is big enough
      const eachPart = partOfFile.get(filename);
      if (!classesOfPart.has(eachPart)) classesOfPart.set(eachPart, []);
      classesOfPart.get(eachPart).push(sourceName);
      const pile = accumulator.get(eachPart) || { text: '', length: 0 };
      accumulator.set(eachPart, { text: pile.text + '\n\n' + storeLine,
        length: pile.length + 2 + codePointLength(storeLine) });
      if (accumulator.get(eachPart).length > minimumSourcesBatchSize) writeBatch(eachPart);
    }
  }

  // flush each part's remainder (parts are emitted in a stable order so the manifest is stable)
  for (const eachPart of [...accumulator.keys()].sort(byCodePoint)) {
    if (accumulator.get(eachPart).text !== '') writeBatch(eachPart);
  }

  // THE RUNTIME PARTS MANIFEST. Written as CoffeeScript and concatenated into the boot bundle by
  // build_it_please.sh, NOT fetched as its own file: the batch loader needs it immediately, and a
  // separate fetch would be one more thing that can arrive late. (It replaces the old
  // numberOfSourceBatches.coffee, which said only "there are N batches, they are called
  // sources_batch_0..N-1" -- true while every source was one undifferentiated stream.)
  //
  // `eager` is INCLUSION's twin, not its synonym: a part is IN this artifact because parts.json
  // said so for this flavour; it is loaded AT BOOT because eager is true. Arc 4 phase 1 ships
  // everything eager, so this is behaviourally identical to loading every batch in sequence.
  // ⚠ `classes` is NOT redundant with the SourceVault's per-source part tag, and this bit is
  // load-bearing: the vault only knows about sources that have ALREADY been stored, i.e. whose
  // batch has already loaded. For a LAZY part that is precisely the thing that has not happened
  // yet, so "which part owns FridgeMagnetsWdgt?" cannot be answered from the vault before the
  // load -- which is the one moment anything needs to ask (a snapshot naming a class from an
  // unloaded part). So the class->part map has to be BUILD data, here, present from boot.
  // Core's list is deliberately omitted: it is ~430 names nothing would read, and "no part owns
  // this name" already means "core, or not ours".
  // (Spelled by manifestJson, which puts every key in code point order whatever order it is set in here.)
  const manifest = new Map();
  for (const eachPart of [...batchesOfPart.keys()].sort(byCodePoint)) {
    const partSpec = parts[eachPart];
    const entry = new Map([
      ['batches', batchesOfPart.get(eachPart)],
      ['eager', partSpec.eager ?? true],
      // The parts this one's code names. PartsRegistry.ensureLoaded loads them FULLY FIRST,
      // which is the only thing that orders a cross-part `extends` -- a door naming several
      // parts goes through Promise.all and orders nothing. Emitted for every part, not just
      // lazy ones, because the manifest is also what a reader consults to understand the
      // shape; it costs a few bytes and an absent key would read as "none" rather than "n/a".
      ['requires', partSpec.requires ?? []],
      // Only the OUTPUT path reaches the runtime: PartsRegistry consumes each vendor entry as
      // a URL to inject (loadJSFilePromise), so how the payload was assembled from vendored
      // pieces is build-time detail that must not leak into the manifest.
      ['vendor', (partSpec.vendor ?? []).map((eachVendor) => eachVendor.out)],
    ]);
    if (eachPart !== 'core') entry.set('classes', [...(classesOfPart.get(eachPart) || [])].sort(byCodePoint));
    manifest.set(eachPart, entry);
  }
  writeFile('../Fizzygum-builds/latest/delete_me/partsManifest.coffee', 'window.FIZZYGUM_PARTS = ' + manifestJson(manifest) + '\n');

  // 4) each SHIPPING part's non-source assets. These used to be unconditional `cp`s in
  // build_it_please.sh followed by a per-flavour prune list in its --homepage block: the harness's
  // three pointer icons were copied into every tree and then deleted again from the production one.
  // Owning them here means what a flavour ships FOLLOWS from which parts ship
  // (arc 5 PR-D6: derive the tail, never declare it).
  copyPartAssets(parts, profile, sink);

  // 5) the entry pages this profile ships (its `entries`, resolved against ENTRY_PAGES). The
  // production profile ships index.html alone, which is what makes it native-only: no SWCanvas
  // boot bundle is assembled for it and no font assets travel with it — both of those follow, in
  // build_it_please.sh, from "does any shipped entry render through SWCanvas".
  for (const [pageFileName, useSWCanvas, eagerAllParts] of profile.entries) {
    generateEntryPage(INPUT_HTML_FILE, path.join(OUTPUT_HTML_DIRECTORY, pageFileName), useSWCanvas, eagerAllParts);
  }
}

// ================================================================================================================
// THE COMMAND LINE, and the listings a gate requires
// ================================================================================================================

// One run of the command line, writing through `sink` ({ stdout(text), stderr(text) }) → its exit code. A refusal is
// written to stderr after the program's name; anything else (a fault build.js did not foresee) is thrown.
function run(argv, sink, listingOnly) {
  try {
    const args = parseArgs(argv);
    if (args.help) {
      sink.stdout(USAGE + '\n');
      return 0;
    }
    if (listingOnly && !args.listShippable && !args.listBoot) throw new Error('build.js: a listing was asked for and none was parsed');
    main(args, sink);
    return 0;
  } catch (error) {
    if (error instanceof Refusal) {
      sink.stderr(`build.js: ${error.message}\n`);
      return error.exitCode;
    }
    throw error;
  }
}

// A LISTING, in-process: the lines `node buildSystem/build.js <flag> <args…>` would print (each without its newline),
// run as if from the directory `cwd` (default: this process's own) -- every relative path, a rail's included, is
// relative to it, as a child process started there would read it. A refusal THROWS an Error whose message is the
// refusal's text (also `exitCode`, `stdout`, `stderr`); a crash throws as it is. The flag goes FIRST, so no argument
// after it can make this a build.
function listing(flag, args = [], { cwd } = {}) {
  const out = [], err = [];
  const sink = { stdout: (text) => out.push(text), stderr: (text) => err.push(text) };
  const code = inDirectory(cwd, () => run([flag, ...args], sink, true));
  const stdout = out.join(''), stderr = err.join('');
  if (code !== 0) {
    const error = new Error((stderr + stdout).replace(/\n$/, ''));
    Object.assign(error, { exitCode: code, stdout, stderr });
    throw error;
  }
  return stdout === '' ? [] : stdout.replace(/\n$/, '').split('\n');
}
const listShippable = (args, options) => listing('--list-shippable', args, options);
const listBoot = (args, options) => listing('--list-boot', args, options);

module.exports = { IS_CLASS, listShippable, listBoot };

if (require.main === module) {
  const sink = { stdout: (text) => process.stdout.write(text), stderr: (text) => process.stderr.write(text) };
  try {
    process.exitCode = run(process.argv.slice(2), sink, false);
  } catch (error) {
    finishCommandLine(error, 'build.js');
  }
}
