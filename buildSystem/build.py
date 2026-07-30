#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
This script performs only some of the steps of the build:

1) For each class file (not all of the coffee files are class files), it
   generates a special string that contains the coffeescript source of the
   file itself.  This is so we can enable editing of the classes in
   coffeescript within the running system, and do something like
   generating the documentation on the fly.

2) Combines the files that DON'T contain classes. The classes will be loaded
   dynamically by the environment, these other non-class files are loaded
   at start instead.

3) Generates the entry pages (see ENTRY_PAGES) from the single page source,
   each one presetting its rendering backend and loading the matching boot
   bundle.

"""

# standard library's imports
from datetime import datetime
from glob import glob
import codecs
import json
import re
import os
import ntpath

import argparse

# GLOBALS
FINAL_OUTPUT_FILE = '../Fizzygum-builds/latest/delete_me/fizzygum-boot.coffee'

# THE PARTITION. buildSystem/parts.json names every part and the directories it owns; read its
# header comment before changing anything here. It replaced a hand-maintained sequence of
# glob("src/<dir>/*.coffee") calls in this file (whose omissions shipped a directory as nothing)
# AND the three whole-file exclusion-marker regexes (which said, invisibly and one file at a time,
# what a part now says once).
PARTS_MANIFEST_FILE = "buildSystem/parts.json"


INPUT_HTML_FILE = "src/index.html"
OUTPUT_HTML_DIRECTORY = "../Fizzygum-builds/latest"

# The single placeholder in src/index.html that lets ONE page source serve every
# entry page. It is replaced by the backend preset plus the matching boot-bundle
# tag — in that order, because globalFunctions.coffee reads
# window.FIZZYGUM_USE_SWCANVAS while the bundle executes.
BOOT_SCRIPTS_PLACEHOLDER = "<!--FIZZYGUM_BOOT_SCRIPTS-->"

# The entry pages, as (filename, renders through SWCanvas?).
#
# The rendering backend is a BUILD-TIME property of the page: each page presets
# the flag and loads the bundle carrying exactly the engine it can use, so no
# artifact ships an engine it will never call and there is no runtime switch.
#   index.html                      native 2D + the SWCanvas 3D core (for SW3D)
#   worldWithSystemTestHarness.html full SWCanvas — the deterministic test substrate
#   index-sw.html                   full SWCanvas, no test harness (interactive SW)
# The test harness is NOT switched on here: WorldWdgt/globalFunctions detect it
# from the page's NAME, so these three differ only in the substituted lines.
# The third column is EAGER_ALL_PARTS: does this page load every part at boot, even the ones
# buildSystem/parts.json marks `"eager": false`?
#   index.html                      NO  -- the interactive product: a lazy part arrives on demand.
#   worldWithSystemTestHarness.html YES -- a part arriving MID-TEST would be frame-paced, hence
#                                   cycle-count-dependent, which is precisely the nondeterminism
#                                   class ../Fizzygum-tests/DETERMINISM.md exists about. The suite's
#                                   world must stay exactly what it was, so the harness takes
#                                   everything up front. The lazy path has its own test instead.
#   index-sw.html                   YES -- same world as the harness minus the harness, kept
#                                   comparable to it.
# This is a page PRESET, like the backend above: chosen at build time, never a runtime switch, and
# not test-only code living in the product.
ENTRY_PAGES = [
    ("index.html", False, False),
    ("worldWithSystemTestHarness.html", True, True),
    ("index-sw.html", True, True),
]

# RegEx Patterns
# We precompile them in order to improve performance and increase
# code readability
IS_CLASS = re.compile(r"^class +(\w+)", re.MULTILINE)
IS_MIXIN = re.compile(r"^(\w+Mixin)[ ]*=", re.MULTILINE)

# HOW A FLAVOUR EXCLUDES CODE: it drops whole PARTS, named in buildSystem/parts.json. There is no
# marker of any kind in a source file, and no regex here that reads one. Two mechanisms were retired
# to get here, both of which worked by cutting text the build could not see the meaning of:
#
#   1. per-REGION stripping (arc 3): a `# »>> this part is …` comment opened a span ending at the
#      next comment carrying `«`, and the span was cut out of the source TEXT. It had accreted for
#      eight+ years without an audit; the audit found it stripping PRODUCT code out of the homepage
#      -- core sizing and `_reLayout` machinery, class constants that silently became `nil`, public
#      API -- because nothing about a comment tells you whether what follows is dev scaffolding or
#      the layout engine. Its 63 sites were RE-HOMED: promoted where they were product, moved to
#      ../Fizzygum-tests/Automator-and-test-harness-src/ where they were test machinery, or
#      extracted into their own collaborator class (PinoutsOverlay, DemoMenus).
#   2. per-FILE markers (arc 4, this arc): `# this file is excluded from the fizzygum homepage
#      build` (43 files), `# this file is only needed for Macros` (2), and
#      `# this file is only needed for VideoPlayer` (0 -- a regex with no carriers at all, live in
#      the build for who knows how long). A file's fate was written invisibly in its first line, so
#      the shape of a production build could only be learned by opening 499 files. It is now a
#      property of a named slice, stated once, where the whole partition is visible at a glance.
#
# Both are gated at zero and cannot come back: buildSystem/check-region-markers.js and
# buildSystem/check-whole-file-markers.js. Deliberately there is NO replacement marker syntax --
# the lesson was that invisible, text-level exclusion is the wrong tool, not that its spelling was
# wrong. A call site copes with an absent part through an existence guard (`if DemoMenus?`,
# `world.pinouts?.…`), which buildSystem/check-part-edges.js requires.

# we just need to detect a switch
# see https://stackoverflow.com/a/8259080
parser = argparse.ArgumentParser()
parser.add_argument('--homepage', action='store_true')
parser.add_argument('--notests', action='store_true')
parser.add_argument('--includeVideoPlayer', action='store_true')
# doing nothing with these yet, but need to add them to the parser otherwise we get an error
parser.add_argument('--includeVideos', action='store_true')
parser.add_argument('--keepPreviousPrivateVideos', action='store_true')

# --noSyntaxCheck is consumed by build_it_please.sh, which forwards ALL of its args to
# us; we accept it here as a no-op so argparse doesn't error on the forwarded flag.
parser.add_argument('--noSyntaxCheck', action='store_true')
# --list-shippable: print the source files that WOULD be shipped (one per line) and
# exit WITHOUT building anything. This is the single source of truth for the build-time
# syntax gate (buildSystem/check-coffee-syntax.js), so the gate's file set can never
# drift from what the build actually wraps-as-text and compiles in-browser.
parser.add_argument('--list-shippable', action='store_true')

args = parser.parse_args()


# Writes one entry page from the single page source, substituting the backend
# preset + boot-bundle tag for BOOT_SCRIPTS_PLACEHOLDER. Everything else about
# the page (splash, canvas, onload -> boot()) is shared verbatim.
def generateEntryPage(srcHTMLFile, destHTMLFile, useSWCanvas, eagerAllParts):
    with codecs.open(srcHTMLFile, "r", "utf-8") as f:
        content = f.read()

    if BOOT_SCRIPTS_PLACEHOLDER not in content:
        raise SystemExit(
            "build.py: " + srcHTMLFile + " has no " + BOOT_SCRIPTS_PLACEHOLDER +
            " placeholder — an entry page without a backend preset would load one"
            " engine and drive the other.")

    bundleFileName = "fizzygum-boot-sw-min.js" if useSWCanvas else "fizzygum-boot-native-min.js"
    bootScripts = (
        '<script type="text/javascript">window.FIZZYGUM_USE_SWCANVAS = ' +
        ("true" if useSWCanvas else "false") +
        '; window.FIZZYGUM_EAGER_ALL_PARTS = ' +
        ("true" if eagerAllParts else "false") + ';</script>\n' +
        '\t\t<script type="text/javascript" src="js/' + bundleFileName + '"></script>')

    with codecs.open(destHTMLFile, "w", "utf-8") as f:
        f.write(content.replace(BOOT_SCRIPTS_PLACEHOLDER, bootScripts))


def loadParts():
    """The partition, from buildSystem/parts.json. Read that file's header before changing this."""
    with codecs.open(PARTS_MANIFEST_FILE, "r", "utf-8") as f:
        return json.load(f)["parts"]


def partitionFiles(parts):
    """Every .coffee file the partition claims, in ANY flavour, as (orderedFilenames, partOfFile).

    Flavour-INDEPENDENT on purpose. Two build gates read this set through --list-shippable:
    check-coffee-syntax.js (parse every shipped source) and check-shippable-coverage.js (every src/
    directory is claimed by some part). Both want "everything that can ship", not "what this
    particular flavour ships" -- a syntax error in a file only the dev build carries is still a
    syntax error, and coverage of the partition is not a property of one flavour. Use shippedFiles()
    for the flavour-applied set.

    The order is a plain codepoint sort of the full path, which is what build.py has always emitted
    in (it re-sorted the whole accumulated list after every directory it added). The emission order
    decides where the source batches get cut, so preserving it exactly is what makes a build
    byte-comparable against its predecessor.
    """
    partOfFile = {}
    for partName, part in parts.items():
        if partName.startswith("//"):
            continue
        for eachDir in part["dirs"]:
            for filename in glob(eachDir + "/*.coffee"):
                if filename in partOfFile:
                    print("ERROR: %s is claimed by two parts: %s and %s. Every directory belongs to "
                          "exactly one part -- see %s." %
                          (filename, partOfFile[filename], partName, PARTS_MANIFEST_FILE))
                    exit(1)
                partOfFile[filename] = partName
    return (sorted(partOfFile.keys()), partOfFile)


def partShipsInThisFlavour(partName, part, args):
    """Is this part included in the flavour being built? This is what the whole-file exclusion
    markers used to answer, one file at a time and invisibly."""
    if args.homepage and not part.get("inHomepage", True):
        return False
    flag = part.get("requiresFlag")
    if flag == "tests" and (args.homepage or args.notests):
        return False
    if flag == "videoPlayer" and not args.includeVideoPlayer:
        return False
    return True


def shippedFiles(parts, partOfFile, orderedFilenames, args):
    """The subset of the partition this flavour actually ships, in emission order."""
    excluded = set(name for name, part in parts.items()
                   if not name.startswith("//") and not partShipsInThisFlavour(name, part, args))
    return [f for f in orderedFilenames if partOfFile[f] not in excluded]


def main():

    parts = loadParts()
    allFilenames, partOfFile = partitionFiles(parts)

    # --list-shippable: emit the partition's file list and stop (see the argparse note above).
    # One path per line, consumed by buildSystem/check-coffee-syntax.js and
    # buildSystem/check-shippable-coverage.js. Flavour-independent -- see partitionFiles().
    # We return BEFORE any output files are written, so nothing is built.
    if args.list_shippable:
        for filename in allFilenames:
            print(filename)
        return

    filenames = shippedFiles(parts, partOfFile, allFilenames, args)

    # so here we need to take a .coffee file and generate a js that
    # , when run, hands its contents as a string to the SourceVault.
    # There are three ways of doing this.
    # 1) generate a coffeescript that contains a multiline string
    #    with the file inside it, then do another pass to convert
    #    the .coffee into .js
    # 2) directly generate a .js file that uses JS multi-line strings
    # 3) directly generate a .js that contains a normal JS string
    #    (which requires us to turn the multi-line source into a normal
    #    js string)
    #
    # We used 1) before, however 3) is the easiest of the three.
    # You'd think that 2) is easiest but that still requires some escaping
    # of the source contents (multiline JS delimiters and in-string variables).
    # 3) Only requires us to escape the " and the \ and to turn the newlines
    # into something else. The easiest way is to replace " and \ with
    # similarly-looking unicode characters and \n with another dedicated
    # character (⤶).
    # The DECODE (the three matching "replace"s) lives in SourceVault.store --
    # src/boot/source-vault.coffee -- so it is written once instead of once per
    # emitted line. Keep the two in sync: the three characters below and the
    # three regexes there are one mechanism.
    #
    # Note that this mechanism fails if the "transformed to" characters
    # are already in the string, however we detect that and besides that's why
    # we picked some strange characters.
    #
    # Also note that we tried to use .json to store these strings rather
    # than using this js trick, however .json loading is not permitted from
    # filesystem, so we'd always need a server...
    #
    # The PART name is the third argument: it is what lets a slice of the system be
    # loaded on demand rather than all-at-boot (docs/archive/build-arc-4-dynamic-parts-plan.md).
    STRING_BLOCK = 'SourceVault.store("%s", "%s", "%s");'

    # now iterate through the source files and create
    # 1) a few js files with A BATCH OF coffeescript sources
    #    (so we load ~15 source batches rather than ~500 sources)
    # 2) the count of the batches we ended up creating, so the boot code
    #    knows how many to load
    # We used to ALSO write one js file per class next to the batches, and load
    # none of them: ~500 files and ~3 MB of duplicate source per dev build that
    # only the --homepage flavour bothered to delete again. Arc 4 dropped them.
    # The two exceptions -- the Class and Mixin sources -- are still emitted as
    # their own files below, because those two ARE loaded individually and early
    # (globalFunctions loads them before any batch: the meta-system has to exist
    # before a batch's contents can be ingested).

    # Batches are cut PER PART, so a part's sources arrive as a unit that can be fetched on its
    # own. Core's batches keep the historical bare `sources_batch_<n>.js` name and every other
    # part's carry its name (`sources_batch_fizzytiles_0.js`): core is the default, and keeping its
    # filenames unchanged is what lets a build be compared byte-for-byte against its predecessor
    # (which is how the marker->parts migration was proven not to change what ships).
    batchesOfPart = {}          # part -> [batch file basenames], in load order
    classesOfPart = {}          # part -> [class/mixin names] (the manifest's class->part map)
    accumulator = {}            # part -> the batch text being filled
    minimumSourcesBatchSize = 150000

    def batchBaseName(partName, index):
        if partName == "core":
            return "sources_batch_" + str(index)
        return "sources_batch_" + partName + "_" + str(index)

    def writeBatch(partName):
        """Flush the part's accumulated text as its next batch file."""
        basename = batchBaseName(partName, len(batchesOfPart.setdefault(partName, [])))
        with codecs.open("../Fizzygum-builds/latest/js/coffeescript-sources/" + basename + ".js", "w", "utf-8") as f:
            f.write(str(accumulator[partName]))
        batchesOfPart[partName].append(basename)
        accumulator[partName] = ""

    for filename in filenames:
        print(">>>> %s " % (filename))
        # open file and read its contents
        with codecs.open(filename, "r", "utf-8") as f:
            content = f.read()

        # if the file is a class, then we hand its source code to the SourceVault
        # (string block).
        # We check if the file is a class by searching its contents for a
        # class ... declaration.
        is_class_file = IS_CLASS.search(content)
        is_mixin_file = IS_MIXIN.search(content)


        # all the class and mixins files' coffeescript source is emitted as text
        # inside a SourceVault.store call, batched into a handful of js files.
        # The boot code loads those batches and then ingests/compiles each source
        # in dependency order. This is what lets Fizzygum load its classes as
        # coffeescript source code -- and, per part, load them lazily.
        #
        # There is no flavour test here any more: `filenames` is already the set this
        # flavour ships (shippedFiles(), from the partition in buildSystem/parts.json).
        # It used to be `not args.homepage or not (three marker regexes match)` -- i.e.
        # every file carried, invisibly in its first line, the question of whether it
        # ships. See parts.json's header for why that moved out of the files.
        if is_class_file or is_mixin_file:

            # backslashes and quotes and newlines all need
            # to be escaped. Quotes need to be escaped otherwise
            # they'll conflict with the starting and ending quote of
            # the complete string. Backslashes need to be escaped
            # otherwise that'll pair up with the next characters to
            # encode all kinds of escape sequences including backspace
            # and tabs and others (https://en.wikipedia.org/wiki/Escape_sequences_in_C)
            # finally, obviously newlines need to be turned into something else
            # since js (plain) strings can't span across multiple lines.

            if ("＂" in content) or ("⧹" in content) or ("⤶" in content):
              print("ERROR: I'm replacing a special character with a character that is already present in " + filename + ". Likely to be a problem.")
              exit()

            escaped_content = content.replace('"',"＂")
            escaped_content = escaped_content.replace("\\","⧹")
            escaped_content = escaped_content.replace("\n","⤶")

            # the vault is keyed by CLASS name, which is the file's basename
            # (one class per file, filename == class name -- see the repo CLAUDE.md)
            sourceName = ntpath.basename(filename).replace(".coffee","")
            escaped_content_with_declaration = STRING_BLOCK % (str(sourceName), str(escaped_content), partOfFile[filename])

            # Class and Mixin are the two sources loaded individually and EARLY, because the
            # meta-system has to exist before any batch's contents can be ingested (see
            # globalFunctions' boot sequence). Every other source travels in a batch only.
            if sourceName == "Class" or sourceName == "Mixin":
                with codecs.open("../Fizzygum-builds/latest/js/coffeescript-sources/"+sourceName+"-source.js", "w", "utf-8") as f:
                    f.write(escaped_content_with_declaration)

            # pile up the sources into this part's batch, and save the batch when it is big enough
            eachPart = partOfFile[filename]
            classesOfPart.setdefault(eachPart, []).append(sourceName)
            accumulator[eachPart] = accumulator.get(eachPart, "") + "\n\n" + escaped_content_with_declaration
            if len(accumulator[eachPart]) > minimumSourcesBatchSize:
                writeBatch(eachPart)



    # flush each part's remainder (parts are emitted in a stable order so the manifest is stable)
    for eachPart in sorted(accumulator.keys()):
        if accumulator[eachPart] != "":
            writeBatch(eachPart)

    # THE RUNTIME PARTS MANIFEST. Written as CoffeeScript and concatenated into the boot bundle by
    # build_it_please.sh, NOT fetched as its own file: the batch loader needs it immediately, and a
    # separate fetch would be one more thing that can arrive late. (It replaces the old
    # numberOfSourceBatches.coffee, which said only "there are N batches, they are called
    # sources_batch_0..N-1" -- true while every source was one undifferentiated stream.)
    #
    # `eager` is INCLUSION's twin, not its synonym: a part is IN this artifact because parts.json
    # said so for this flavour; it is loaded AT BOOT because eager is true. Arc 4 phase 1 ships
    # everything eager, so this is behaviourally identical to loading every batch in sequence.
    # ⚠ `classes` is NOT redundant with the SourceVault's per-source part tag, and this bit is
    # load-bearing: the vault only knows about sources that have ALREADY been stored, i.e. whose
    # batch has already loaded. For a LAZY part that is precisely the thing that has not happened
    # yet, so "which part owns FridgeMagnetsWdgt?" cannot be answered from the vault before the
    # load -- which is the one moment anything needs to ask (a snapshot naming a class from an
    # unloaded part). So the class->part map has to be BUILD data, here, present from boot.
    # Core's list is deliberately omitted: it is ~430 names nothing would read, and "no part owns
    # this name" already means "core, or not ours".
    manifest = {}
    for eachPart in sorted(batchesOfPart.keys()):
        partSpec = parts[eachPart]
        manifest[eachPart] = {
            "batches": batchesOfPart[eachPart],
            "eager": partSpec.get("eager", True),
            "vendor": partSpec.get("vendor", []),
        }
        if eachPart != "core":
            manifest[eachPart]["classes"] = sorted(classesOfPart.get(eachPart, []))
    with codecs.open("../Fizzygum-builds/latest/delete_me/partsManifest.coffee", "w", "utf-8") as f:
        f.write("window.FIZZYGUM_PARTS = " + json.dumps(manifest, sort_keys=True) + "\n")


    # 4) the entry pages, one per backend flavour (see ENTRY_PAGES). A --homepage
    # build is native-only — no SWCanvas bundle is assembled for it and its font
    # assets are not shipped — so it gets index.html alone.
    for (pageFileName, useSWCanvas, eagerAllParts) in ENTRY_PAGES:
        if args.homepage and useSWCanvas:
            continue
        generateEntryPage(
                INPUT_HTML_FILE,
                os.path.join(OUTPUT_HTML_DIRECTORY, pageFileName),
                useSWCanvas,
                eagerAllParts)


if __name__ == "__main__":
    main()
