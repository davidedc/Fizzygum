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
// It keeps the semantics of the Python it was ported from (buildSystem/build.py, deleted in cleanups U5): the
// arguments are parsed as Python's argparse parsed them (unique prefixes accepted, `--flag=value` and `--flag value`,
// a value starting with `-` read as missing, its usage block wrapped at the terminal width), and every value, path,
// order and byte follows lib/profile.js's reading of Python (its header says how).

const path = require('path');

// THE FLAVOUR, as data. lib/profile.js reads buildSystem/profiles/<name>.json and derives from it
// everything this build used to decide by asking "is this the homepage?" -- read its header first.
// It also owns the two tables we share with build_it_please.sh: the partition (parts.json, via
// loadParts) and the entry pages, whose SWCanvas column the shell needs to know whether to assemble
// the SW boot bundle. One table, two readers.
const profileLib = require('./lib/profile');
const { ENTRY_PAGES, loadParts, partShips, Refusal, inDirectory, py, readText, readBytes, writeText, writeAllSync, isfile, isdir,
  makedirs, copyfile, glob, pathJoin, pathBasename, pathDirname, toStdout, toStderr, finishCommandLine, encodable } = profileLib;
const fs = require('fs');

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
// THE ARGUMENTS -- Python's argparse, for this one parser
// ================================================================================================================
// THE FLAVOUR: --profile, a profile name, resolved by lib/profile.js against buildSystem/profiles/<name>.json.
// It replaced the --homepage and --notests flags (arc 5): a flavour is data, and adding one is
// adding a file rather than threading a boolean through two scripts. A stale `--homepage` on a
// command line now fails here, loudly, instead of silently building something else.
// --includeVideoPlayer ships the video-player part. --includeVideos and --keepPreviousPrivateVideos do nothing here
// (build_it_please.sh acts on them), but are accepted, or the forwarded arguments would be refused.
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
// is globbed under the --src= DIR instead, one under `../Fizzygum-tests` under the --tests-repo= DIR; every path is still
// printed as parts.json spells it (`src/...`, `../Fizzygum-tests/...`), so a gate maps it back onto the tree it was
// handed. An empty or missing value is refused.
const ACTIONS = [
  { strings: ['-h', '--help'], dest: 'help', flag: true, help: 'show this help message and exit' },
  { strings: ['--profile'], dest: 'profile', flag: false, metavar: 'PROFILE', initial: profileLib.DEFAULT_PROFILE_NAME },
  { strings: ['--includeVideoPlayer'], dest: 'includeVideoPlayer', flag: true },
  { strings: ['--includeVideos'], dest: 'includeVideos', flag: true },
  { strings: ['--keepPreviousPrivateVideos'], dest: 'keepPreviousPrivateVideos', flag: true },
  { strings: ['--noSyntaxCheck'], dest: 'noSyntaxCheck', flag: true },
  { strings: ['--list-shippable'], dest: 'listShippable', flag: true },
  { strings: ['--list-boot'], dest: 'listBoot', flag: true },
  { strings: ['--src'], dest: 'src', flag: false, metavar: 'SRC', initial: null },
  { strings: ['--tests-repo'], dest: 'testsRepo', flag: false, metavar: 'TESTSREPO', initial: null },
  { strings: ['--parts'], dest: 'parts', flag: false, metavar: 'PARTS', initial: null },
];
const OPTION_ACTIONS = new Map(ACTIONS.flatMap((action) => action.strings.map((s) => [s, action])));
// argparse names the program after the file it was started from
const PROG = path.basename(__filename);

// The help ends parsing with exit 0; anything else argparse refuses ends it with exit 2.
class HelpShown extends Error {}
const parserError = (message, columns) => new Refusal(usageText(columns).replace(/\n\n$/, '\n') + `${PROG}: error: ${message}`, 2);
const argumentError = (action, message, columns) => parserError(`argument ${action.strings.join('/')}: ${message}`, columns);

// a value written `-` then digits (or `-.5`) is a value, not an option: Python's `\d` (any script's digits) and its
// `$`, which also matches before a final newline
const NEGATIVE_NUMBER = /^-\p{Nd}+\n?$|^-\p{Nd}*\.\p{Nd}+\n?$/u;
const codePoints = (s) => [...s];

// shutil.get_terminal_size().columns: COLUMNS when it is a positive integer, else the size of the terminal stdout is
// (when it is one), else 80. `int()` reads COLUMNS: surrounding whitespace, a sign, `_` between digits, any script's
// decimal digits.
const PY_SPACE = /[\t\n\v\f\r\x1c-\x1f \x85\xa0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]/u;
const DECIMAL = /\p{Nd}/u;
function pyIntOrZero(text) {
  if (text === undefined) return 0;
  const chars = codePoints(text);
  let a = 0, b = chars.length;
  while (a < b && PY_SPACE.test(chars[a])) a++;
  while (b > a && PY_SPACE.test(chars[b - 1])) b--;
  let sign = 1;
  if (a < b && (chars[a] === '+' || chars[a] === '-')) { sign = chars[a] === '-' ? -1 : 1; a++; }
  let digits = '';
  for (let i = a; i < b; i++) {
    const ch = chars[i];
    if (ch === '_' && i > a && i < b - 1 && DECIMAL.test(chars[i - 1]) && DECIMAL.test(chars[i + 1])) continue;
    if (!DECIMAL.test(ch)) return 0;
    // a decimal digit's value: its offset in its run of decimal digits (each script's are 0..9, contiguous, in order)
    let start = ch.codePointAt(0);
    while (DECIMAL.test(String.fromCodePoint(start - 1))) start--;
    digits += String((ch.codePointAt(0) - start) % 10);
  }
  return digits ? sign * Number(digits) : 0;
}
function terminalColumns(sink) {
  let columns = pyIntOrZero(process.env.COLUMNS);
  const lines = pyIntOrZero(process.env.LINES);
  if (columns <= 0 || lines <= 0) {
    const size = sink.terminalColumns || 80;
    if (columns <= 0) columns = size;
  }
  return columns;
}

// HelpFormatter (width = columns - 2): the usage block, wrapped as argparse wraps it
function usageText(columns) {
  const textWidth = columns - 2;
  const prefix = 'usage: ';
  const optParts = ACTIONS.map((action) => '[' + action.strings[0] + (action.flag ? '' : ' ' + action.metavar) + ']');
  const usage = PROG + ' ' + optParts.join(' ');
  if (prefix.length + usage.length <= textWidth) return prefix + usage + '\n\n';
  const getLines = (parts, indent, linePrefix) => {
    const lines = [];
    let line = [];
    let lineLen = linePrefix !== undefined ? linePrefix.length - 1 : indent.length - 1;
    for (const part of parts) {
      if (lineLen + 1 + part.length > textWidth && line.length) {
        lines.push(indent + line.join(' '));
        line = [];
        lineLen = indent.length - 1;
      }
      line.push(part);
      lineLen += part.length + 1;
    }
    if (line.length) lines.push(indent + line.join(' '));
    if (linePrefix !== undefined) lines[0] = lines[0].slice(indent.length);
    return lines;
  };
  let lines;
  if (prefix.length + PROG.length <= 0.75 * textWidth) {
    // a short prog: the options follow it, wrapped under it
    lines = getLines([PROG, ...optParts], ' '.repeat(prefix.length + PROG.length + 1), prefix);
  } else {
    // a long prog: on a line of its own, the options wrapped below
    const indent = ' '.repeat(prefix.length);
    lines = [PROG, ...getLines(optParts, indent)];
  }
  return prefix + lines.join('\n') + '\n\n';
}

// ... and the whole help (-h): the usage block, then every option, its help text wrapped at the help column
function helpText(columns) {
  const width = columns - 2;
  const maxHelpPosition = Math.min(24, Math.max(width - 20, 4));
  const invocation = (action) => (action.flag ? action.strings.join(', ') : action.strings.map((s) => s + ' ' + action.metavar).join(', '));
  const actionMaxLength = Math.max(...ACTIONS.map((action) => invocation(action).length + 2));
  const helpPosition = Math.min(actionMaxLength + 2, maxHelpPosition);
  const helpWidth = Math.max(width - helpPosition, 11);
  const actionWidth = helpPosition - 2 - 2;
  // textwrap.wrap on single-spaced words (the help's words are all shorter than the narrowest help width, 11)
  const wrap = (text, w) => {
    const lines = [];
    let line = '';
    for (const word of text.split(' ')) {
      if (line && line.length + 1 + word.length > w) { lines.push(line); line = word; } else line = line ? line + ' ' + word : word;
    }
    if (line) lines.push(line);
    return lines;
  };
  let items = '';
  for (const action of ACTIONS) {
    const header = invocation(action);
    if (!action.help) { items += '  ' + header + '\n'; continue; }
    let indentFirst;
    if (header.length <= actionWidth) { items += '  ' + header.padEnd(actionWidth) + '  '; indentFirst = 0; }
    else { items += '  ' + header + '\n'; indentFirst = helpPosition; }
    const helpLines = wrap(action.help, helpWidth);
    items += ' '.repeat(indentFirst) + helpLines[0] + '\n';
    for (const line of helpLines.slice(1)) items += ' '.repeat(helpPosition) + line + '\n';
  }
  const help = (usageText(columns) + '\noptions:\n' + items + '\n').replace(/\n\n\n+/g, '\n\n');
  return help.replace(/^\n+|\n+$/g, '') + '\n';
}

// argparse's parse_args: the arguments, or a refusal (exit 2); -h writes the help and ends with exit 0
function parseArgs(argv, sink) {
  const columns = terminalColumns(sink);
  const ns = {};
  for (const action of ACTIONS) if (action.dest !== 'help') ns[action.dest] = action.flag ? false : action.initial;

  const getOptionTuples = (optionString) => {
    const result = [];
    if (optionString[0] === '-' && optionString[1] === '-') {
      const eq = optionString.indexOf('=');
      const optionPrefix = eq < 0 ? optionString : optionString.slice(0, eq);
      const explicitArg = eq < 0 ? undefined : optionString.slice(eq + 1);
      for (const [s, action] of OPTION_ACTIONS) if (s.startsWith(optionPrefix)) result.push([action, s, explicitArg]);
    } else {
      const chars = codePoints(optionString);
      const shortPrefix = chars.slice(0, 2).join(''), shortExplicitArg = chars.slice(2).join('');
      for (const [s, action] of OPTION_ACTIONS) {
        if (s === shortPrefix) result.push([action, s, shortExplicitArg]);
        else if (s.startsWith(optionString)) result.push([action, s, undefined]);
      }
    }
    return result;
  };
  // an argument that reads as an option: [action or null (an unknown one), the option string, its `=value` or undefined]
  const parseOptional = (arg) => {
    if (!arg || arg[0] !== '-') return undefined;
    if (OPTION_ACTIONS.has(arg)) return [OPTION_ACTIONS.get(arg), arg, undefined];
    if (arg.length === 1) return undefined;
    const eq = arg.indexOf('=');
    if (eq >= 0 && OPTION_ACTIONS.has(arg.slice(0, eq))) return [OPTION_ACTIONS.get(arg.slice(0, eq)), arg.slice(0, eq), arg.slice(eq + 1)];
    const tuples = getOptionTuples(arg);
    if (tuples.length > 1) throw parserError(`ambiguous option: ${arg} could match ${tuples.map((t) => t[1]).join(', ')}`, columns);
    if (tuples.length === 1) return tuples[0];
    if (NEGATIVE_NUMBER.test(arg)) return undefined;
    if (arg.includes(' ')) return undefined;
    return [null, arg, undefined];
  };

  // which arguments are options ('O') and which are values ('A'); everything after `--` is a value
  const optionAt = new Map();
  let pattern = '';
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--') { pattern += '-' + 'A'.repeat(argv.length - i - 1); break; }
    const tuple = parseOptional(argv[i]);
    if (tuple === undefined) pattern += 'A'; else { optionAt.set(i, tuple); pattern += 'O'; }
  }

  const takeAction = (action, args) => {
    if (action.dest === 'help') { sink.stdout(helpText(columns)); throw new HelpShown(); }
    ns[action.dest] = action.flag ? true : args[0];
  };
  const extras = [];
  // one option, and its value: an option taking a value takes exactly the next argument, and only if that is no option
  const consumeOptional = (startIndex) => {
    let [action, optionString, explicitArg] = optionAt.get(startIndex);
    const actionTuples = [];
    let stop;
    for (;;) {
      if (action === null) { extras.push(argv[startIndex]); return startIndex + 1; }
      if (explicitArg !== undefined) {
        const argCount = action.flag ? 0 : 1;
        if (argCount === 0 && optionString[1] !== '-' && explicitArg !== '') {
          // `-hx`: a single-dash flag followed by more single-letter flags
          actionTuples.push([action, []]);
          const chars = codePoints(explicitArg);
          const nextOption = optionString[0] + chars[0];
          if (!OPTION_ACTIONS.has(nextOption)) throw argumentError(action, `ignored explicit argument ${py.repr(explicitArg)}`, columns);
          action = OPTION_ACTIONS.get(nextOption);
          optionString = nextOption;
          explicitArg = chars.slice(1).join('') || undefined;
        } else if (argCount === 1) {
          stop = startIndex + 1;
          actionTuples.push([action, [explicitArg]]);
          break;
        } else throw argumentError(action, `ignored explicit argument ${py.repr(explicitArg)}`, columns);
      } else {
        const start = startIndex + 1;
        let argCount = 0;
        if (!action.flag) {
          if (pattern[start] !== 'A') throw argumentError(action, 'expected one argument', columns);
          argCount = 1;
        }
        stop = start + argCount;
        actionTuples.push([action, argv.slice(start, stop)]);
        break;
      }
    }
    for (const [action, args] of actionTuples) takeAction(action, args);
    return stop;
  };

  const optionIndices = [...optionAt.keys()];
  const maxOptionIndex = optionIndices.length ? Math.max(...optionIndices) : -1;
  let startIndex = 0;
  while (startIndex <= maxOptionIndex) {
    const nextOptionIndex = Math.min(...optionIndices.filter((index) => index >= startIndex));
    if (!optionAt.has(startIndex)) {
      extras.push(...argv.slice(startIndex, nextOptionIndex));
      startIndex = nextOptionIndex;
    }
    startIndex = consumeOptional(startIndex);
  }
  extras.push(...argv.slice(startIndex));
  if (extras.length) throw parserError(`unrecognized arguments: ${extras.join(' ')}`, columns);

  // this build's own rules about which arguments go together
  if (ns.listShippable && ns.listBoot) throw parserError('--list-shippable and --list-boot are two listings: ask for one', columns);
  if ((ns.src !== null || ns.testsRepo !== null || ns.parts !== null) && !(ns.listShippable || ns.listBoot)) {
    throw parserError('--src=, --tests-repo= and --parts= only qualify --list-shippable and --list-boot', columns);
  }
  if (ns.src !== null && (!ns.src || !isdir(ns.src))) throw parserError(`--src= names no directory: ${py.repr(ns.src)}`, columns);
  if (ns.testsRepo !== null && (!ns.testsRepo || !isdir(ns.testsRepo))) throw parserError(`--tests-repo= names no directory: ${py.repr(ns.testsRepo)}`, columns);
  if (ns.parts !== null && (!ns.parts || !isfile(ns.parts))) throw parserError(`--parts= names no file: ${py.repr(ns.parts)}`, columns);
  return ns;
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
      'build.js: ' + srcHTMLFile + ' has no ' + BOOT_SCRIPTS_PLACEHOLDER
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

  writeText(destHTMLFile, content.split(BOOT_SCRIPTS_PLACEHOLDER).join(bootScripts));
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
  for (const partName of py.keys(parts)) {
    if (partName.startsWith('//')) continue;
    for (const eachDir of py.iter(py.index(parts[partName], 'dirs'))) {
      // another src tree (--src) or tests repo (--tests-repo): a dir under it is globbed there, and named as
      // parts.json spells it, src/... or ../Fizzygum-tests/..., as always
      let spelled, root;
      for (const [prefix, given] of [['src', srcRoot], [TESTS_REPO_PREFIX, testsRepoRoot]]) {
        if (given !== null && (eachDir === prefix || py.startswith(eachDir, prefix + '/'))) {
          spelled = prefix;
          root = given.replace(/\/+$/, '');
        }
      }
      const physical = root ? root + eachDir.slice(spelled.length) : py.mustStr(eachDir, 'a part directory');
      for (const found of glob(physical + '/*.coffee')) {
        const filename = root ? spelled + codePoints(found).slice(codePoints(root).length).join('') : found;
        if (partOfFile.has(filename)) {
          throw new Refusal(`ERROR: ${filename} is claimed by two parts: ${partOfFile.get(filename)} and ${partName}. Every directory belongs to `
            + `exactly one part -- see ${profileLib.PARTS_MANIFEST_FILE}.`, 1, 'stdout');
        }
        partOfFile.set(filename, partName);
      }
    }
  }
  return [py.sorted(partOfFile.keys()), partOfFile];
}

// Is this part included in the flavour being built? This is what the whole-file exclusion
// markers used to answer, one file at a time and invisibly.
//
// The RULE itself lives in lib/profile.js partShips, because build_it_please.sh asks the same
// question (through its --shell mode) to decide what else goes into the tree -- and one
// question answered in two places is how a flavour ends up shipping half a part.
const partShipsInThisFlavour = (partName, part, profile, args) => partShips(partName, part, profile, args.includeVideoPlayer);

// A declared-but-missing file is a HARD failure, not a warning: a payload silently not written
// is the failure mode this whole mechanism replaced (the tree looks fine, and a page 404s for an
// <img> or an injected script at runtime).
function requirePartFile(partName, sourcePath, kind) {
  if (!isfile(sourcePath)) {
    throw new Refusal(`ERROR: part '${partName}' declares a ${kind} that does not exist: ${py.str(sourcePath)} (buildSystem/parts.json)`, 1, 'stdout');
  }
}

// Materialise the non-source files owned by every part that SHIPS in this flavour: plain assets
// (copied) and vendor payloads (assembled from their pieces).
//
// This is what makes "what a flavour ships" follow from which parts ship, instead of being a
// per-flavour prune list. A part that does not ship writes nothing.
function copyPartAssets(parts, profile, args, sink) {
  let copiedAssets = 0;
  let builtPayloads = 0;
  for (const partName of py.keys(parts)) {
    if (partName.startsWith('//')) continue;
    const part = parts[partName];
    if (!partShipsInThisFlavour(partName, part, profile, args)) continue;

    for (const entry of py.iter(py.get(part, 'assets', []))) {
      const [sourcePath, destinationDirectory] = py.unpack2(entry);
      requirePartFile(partName, sourcePath, 'asset');
      const fullDestinationDirectory = pathJoin('../Fizzygum-builds/latest', destinationDirectory);
      makedirs(fullDestinationDirectory);
      copyfile(sourcePath, pathJoin(fullDestinationDirectory, pathBasename(sourcePath)));
      copiedAssets += 1;
    }

    // Vendor payloads: concatenate the pieces, each followed by a newline-semicolon separator
    // that terminates the unit and defends against ASI between them (the same separator the
    // boot-bundle assembly uses).
    for (const entry of py.iter(py.get(part, 'vendor', []))) {
      const outputPath = pathJoin('../Fizzygum-builds/latest', py.index(entry, 'out'));
      makedirs(pathDirname(outputPath));
      const payload = fs.openSync(profileLib.at(outputPath), 'w');
      try {
        for (const piece of py.iter(py.index(entry, 'concat'))) {
          requirePartFile(partName, piece, 'vendor payload piece');
          writeAllSync(payload, readBytes(py.mustStr(piece, 'open')));
          writeAllSync(payload, Buffer.from('\n;\n'));
        }
      } finally { fs.closeSync(payload); }
      builtPayloads += 1;
    }
  }

  sink.stdout(`copied ${copiedAssets} part asset(s), assembled ${builtPayloads} vendor payload(s)\n`);
}

// The subset of the partition this flavour actually ships, in emission order.
function shippedFiles(parts, partOfFile, orderedFilenames, profile, args) {
  const excluded = new Set(py.keys(parts).filter((name) => !name.startsWith('//')
    && !partShipsInThisFlavour(name, parts[name], profile, args)));
  return orderedFilenames.filter((f) => !excluded.has(partOfFile.get(f)));
}

// a string's length in CODE POINTS (a batch is cut by the length Python measured)
function codePointLength(s) {
  let n = s.length;
  for (let i = 0; i < s.length - 1; i++) {
    const c = s.charCodeAt(i);
    if (c >= 0xD800 && c <= 0xDBFF) { const d = s.charCodeAt(i + 1); if (d >= 0xDC00 && d <= 0xDFFF) { n--; i++; } }
  }
  return n;
}

function main(args, sink) {
  const profile = profileLib.resolve(args.profile);
  const parts = args.parts ? loadParts(args.parts) : loadParts();
  // --list-boot: the parts' declared src/boot files (lib/profile.js bootFiles checks each), then stop
  if (args.listBoot) {
    for (const [filename, part, kind] of profileLib.bootFiles(parts, args.src, args.parts || profileLib.PARTS_MANIFEST_FILE)) {
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

  const filenames = shippedFiles(parts, partOfFile, allFilenames, profile, args);

  // so here we need to take a .coffee file and generate a js that
  // , when run, hands its contents as a string to the SourceVault.
  // There are three ways of doing this.
  // 1) generate a coffeescript that contains a multiline string
  //    with the file inside it, then do another pass to convert
  //    the .coffee into .js
  // 2) directly generate a .js file that uses JS multi-line strings
  // 3) directly generate a .js that contains a normal JS string
  //    (which requires us to turn the multi-line source into a normal
  //    js string)
  //
  // We used 1) before, however 3) is the easiest of the three.
  // You'd think that 2) is easiest but that still requires some escaping
  // of the source contents (multiline JS delimiters and in-string variables).
  // 3) Only requires us to escape the " and the \ and to turn the newlines
  // into something else. The easiest way is to replace " and \ with
  // similarly-looking unicode characters and \n with another dedicated
  // character (⤶).
  // The DECODE (the three matching "replace"s) lives in SourceVault.store --
  // src/boot/source-vault.coffee -- so it is written once instead of once per
  // emitted line. Keep the two in sync: the three characters below and the
  // three regexes there are one mechanism.
  //
  // Note that this mechanism fails if the "transformed to" characters
  // are already in the string, however we detect that and besides that's why
  // we picked some strange characters.
  //
  // Also note that we tried to use .json to store these strings rather
  // than using this js trick, however .json loading is not permitted from
  // filesystem, so we'd always need a server...
  //
  // The PART name is the third argument: it is what lets a slice of the system be
  // loaded on demand rather than all-at-boot (docs/archive/build-arc-4-dynamic-parts-plan.md).
  const STRING_BLOCK = (name, escaped, part) => 'SourceVault.store("' + name + '", "' + escaped + '", "' + part + '");';

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
    writeText('../Fizzygum-builds/latest/js/coffeescript-sources/' + basename + '.js', accumulator.get(partName).text);
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
      // backslashes and quotes and newlines all need
      // to be escaped. Quotes need to be escaped otherwise
      // they'll conflict with the starting and ending quote of
      // the complete string. Backslashes need to be escaped
      // otherwise that'll pair up with the next characters to
      // encode all kinds of escape sequences including backspace
      // and tabs and others (https://en.wikipedia.org/wiki/Escape_sequences_in_C)
      // finally, obviously newlines need to be turned into something else
      // since js (plain) strings can't span across multiple lines.

      if (content.includes('＂') || content.includes('⧹') || content.includes('⤶')) {
        // a refusal, never a stop: ending this script with status 0 half-way through
        // the batches would let the build stamp a tree with no parts manifest and no entry pages
        throw new Refusal("ERROR: I'm replacing a special character with a character that is already present in " + filename + '. Likely to be a problem.');
      }

      const escapedContent = content.split('"').join('＂').split('\\').join('⧹').split('\n').join('⤶');

      // the vault is keyed by CLASS name, which is the file's basename
      // (one class per file, filename == class name -- see the repo CLAUDE.md)
      const sourceName = windowsBasename(filename).split('.coffee').join('');
      const escapedContentWithDeclaration = STRING_BLOCK(sourceName, escapedContent, partOfFile.get(filename));

      // Class is the one source loaded individually and EARLY, because the meta-system
      // has to exist before any batch's contents can be ingested (see globalFunctions'
      // boot sequence and its META_SYSTEM_SOURCES). Every other source travels in a batch only.
      if (sourceName === 'Class') {
        writeText('../Fizzygum-builds/latest/js/coffeescript-sources/' + sourceName + '-source.js', escapedContentWithDeclaration);
      }

      // pile up the sources into this part's batch, and save the batch when it is big enough
      const eachPart = partOfFile.get(filename);
      if (!classesOfPart.has(eachPart)) classesOfPart.set(eachPart, []);
      classesOfPart.get(eachPart).push(sourceName);
      const pile = accumulator.get(eachPart) || { text: '', length: 0 };
      accumulator.set(eachPart, { text: pile.text + '\n\n' + escapedContentWithDeclaration,
        length: pile.length + 2 + codePointLength(escapedContentWithDeclaration) });
      if (accumulator.get(eachPart).length > minimumSourcesBatchSize) writeBatch(eachPart);
    }
  }

  // flush each part's remainder (parts are emitted in a stable order so the manifest is stable)
  for (const eachPart of py.sorted(accumulator.keys())) {
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
  // (Written as Python's json.dumps(manifest, sort_keys=True) wrote it: lib/profile.js py.dumps.)
  const manifest = new Map();
  for (const eachPart of py.sorted(batchesOfPart.keys())) {
    const partSpec = parts[eachPart];
    const entry = new Map([
      ['batches', batchesOfPart.get(eachPart)],
      ['eager', py.get(partSpec, 'eager', true)],
      // The parts this one's code names. PartsRegistry.ensureLoaded loads them FULLY FIRST,
      // which is the only thing that orders a cross-part `extends` -- a door naming several
      // parts goes through Promise.all and orders nothing. Emitted for every part, not just
      // lazy ones, because the manifest is also what a reader consults to understand the
      // shape; it costs a few bytes and an absent key would read as "none" rather than "n/a".
      ['requires', py.get(partSpec, 'requires', [])],
      // Only the OUTPUT path reaches the runtime: PartsRegistry consumes each vendor entry as
      // a URL to inject (loadJSFilePromise), so how the payload was assembled from vendored
      // pieces is build-time detail that must not leak into the manifest.
      ['vendor', py.iter(py.get(partSpec, 'vendor', [])).map((eachVendor) => py.index(eachVendor, 'out'))],
    ]);
    if (eachPart !== 'core') entry.set('classes', py.sorted(classesOfPart.get(eachPart) || []));
    manifest.set(eachPart, entry);
  }
  writeText('../Fizzygum-builds/latest/delete_me/partsManifest.coffee', 'window.FIZZYGUM_PARTS = ' + py.dumps(manifest) + '\n');

  // 4) each SHIPPING part's non-source assets. These used to be unconditional `cp`s in
  // build_it_please.sh followed by a per-flavour prune list in its --homepage block: the harness's
  // three pointer icons and FileSaver/JSZip were copied into every tree and then deleted again from
  // the production one. Owning them here means what a flavour ships FOLLOWS from which parts ship
  // (arc 5 PR-D6: derive the tail, never declare it).
  copyPartAssets(parts, profile, args, sink);

  // 5) the entry pages this profile ships (its `entries`, resolved against ENTRY_PAGES). The
  // production profile ships index.html alone, which is what makes it native-only: no SWCanvas
  // boot bundle is assembled for it and no font assets travel with it — both of those follow, in
  // build_it_please.sh, from "does any shipped entry render through SWCanvas".
  for (const [pageFileName, useSWCanvas, eagerAllParts] of profile.entries) {
    generateEntryPage(INPUT_HTML_FILE, pathJoin(OUTPUT_HTML_DIRECTORY, pageFileName), useSWCanvas, eagerAllParts);
  }
}

// ntpath.basename: the name after the last `/` or `\`, past a drive (`c:`) or a UNC share (`//host/share`) -- how the
// vault has always named a source from its path
function windowsBasename(p) {
  const norm = p.split('/').join('\\');
  let rest = p;
  if (codePoints(p).length >= 2) {
    if (norm.slice(0, 2) === '\\\\' && norm[2] !== '\\') {
      const index = norm.indexOf('\\', 2);
      if (index !== -1) {
        let index2 = norm.indexOf('\\', index + 1);
        if (index2 !== index + 1) {
          if (index2 === -1) index2 = p.length;
          rest = p.slice(index2);
        }
      }
    } else if (codePoints(norm)[1] === ':') rest = codePoints(p).slice(2).join('');
  }
  let i = rest.length;
  while (i && rest[i - 1] !== '/' && rest[i - 1] !== '\\') i--;
  return rest.slice(i);
}

// ================================================================================================================
// THE COMMAND LINE, and the listings a gate requires
// ================================================================================================================

// One run of the command line, writing through `sink` ({ stdout(text), stderr(text), terminalColumns }) → its exit
// code. A refusal is written to its stream; a crash (lib/profile.js PyCrash, or any other error) is thrown.
function run(argv, sink, listingOnly) {
  try {
    const args = parseArgs(argv, sink);
    if (listingOnly && !args.listShippable && !args.listBoot) throw new Error('build.js: a listing was asked for and none was parsed');
    main(args, sink);
    return 0;
  } catch (error) {
    if (error instanceof HelpShown) return 0;
    if (error instanceof Refusal) {
      sink[error.stream](error.message + '\n');
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
  const sink = { stdout: (text) => out.push(toStdout(text)), stderr: (text) => err.push(toStderr(text)), terminalColumns: undefined };
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
  const sink = {
    stdout: (text) => process.stdout.write(toStdout(text)),
    stderr: (text) => process.stderr.write(toStderr(text)),
    terminalColumns: process.stdout.isTTY ? process.stdout.columns : undefined,
  };
  try {
    process.exitCode = run(process.argv.slice(2), sink, false);
  } catch (error) {
    finishCommandLine(error);
  }
}
