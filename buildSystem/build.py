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
import re
import os
import ntpath

import argparse

# GLOBALS
FINAL_OUTPUT_FILE = '../Fizzygum-builds/latest/delete_me/fizzygum-boot.coffee'


INPUT_HTML_FILE = "src/index.html"
OUTPUT_HTML_DIRECTORY = "../Fizzygum-builds/latest"
DIRECTORY_WITH_AUTOMATOR_AND_TEST_HARNESS_CODE = "../Fizzygum-tests/Automator-and-test-harness-src"

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
ENTRY_PAGES = [
    ("index.html", False),
    ("worldWithSystemTestHarness.html", True),
    ("index-sw.html", True),
]

# RegEx Patterns
# We precompile them in order to improve performance and increase
# code readability
IS_CLASS = re.compile(r"^class +(\w+)", re.MULTILINE)
IS_MIXIN = re.compile(r"^(\w+Mixin)[ ]*=", re.MULTILINE)

# regexps to exclude entire FILES from a build flavour.
#
# There used to be a second, per-REGION mechanism alongside these: a `# »>> this part is …`
# comment opened a span that ended at the next comment carrying `«`, and the whole span was
# cut out of the source TEXT by regex. Arc 3 retired it. It had accreted for eight+ years
# without an audit, and the audit found it stripping PRODUCT code out of the homepage —
# core sizing and `_reLayout` machinery, class constants that silently became `nil`, public
# API — because nothing about a comment tells you whether what follows is dev scaffolding
# or the layout engine. Its 63 sites were RE-HOMED instead: promoted where they were product,
# moved to ../Fizzygum-tests/Automator-and-test-harness-src/ where they were test machinery,
# or extracted into their own collaborator class (PinoutsOverlay, DemoMenus). ALL THREE region
# regexes are now DELETED: a flavour can only drop WHOLE FILES, and a call site copes with an
# absent file through an existence guard (`if DemoMenus?`, `world.pinouts?.…`).
# `buildSystem/check-region-markers.js` holds every kind at zero — a hard rule now, not a
# ratchet — so nothing can reintroduce the mechanism. Deliberately there is NO replacement
# marker syntax: the lesson was that invisible, text-level stripping is the wrong tool, not
# that its spelling was wrong.
FILE_NOT_IN_FIZZYGUM_HOMEPAGE = re.compile(r"# this file is excluded from the fizzygum homepage build")

FILE_ONLY_FOR_MACROS = re.compile(r"# this file is only needed for Macros")

FILE_ONLY_FOR_VIDEOPLAYER = re.compile(r"# this file is only needed for VideoPlayer")

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
def generateEntryPage(srcHTMLFile, destHTMLFile, useSWCanvas):
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
        ("true" if useSWCanvas else "false") + ';</script>\n' +
        '\t\t<script type="text/javascript" src="js/' + bundleFileName + '"></script>')

    with codecs.open(destHTMLFile, "w", "utf-8") as f:
        f.write(content.replace(BOOT_SCRIPTS_PLACEHOLDER, bootScripts))


def main():

    # create a list with the coffeescript files
    filenames = sorted(glob("src/*.coffee"))

    if not (args.homepage or args.notests):
        if os.path.exists("../Fizzygum-tests"):
            if os.path.exists(DIRECTORY_WITH_AUTOMATOR_AND_TEST_HARNESS_CODE):
                filenames = sorted(filenames + sorted(glob(DIRECTORY_WITH_AUTOMATOR_AND_TEST_HARNESS_CODE + "/*.coffee")))
                filenames = sorted(filenames + sorted(glob(DIRECTORY_WITH_AUTOMATOR_AND_TEST_HARNESS_CODE + "/AutomatorEventCommands/*.coffee")))

    # add the sources from the directories
    # the order here has no importance, just try to
    # give it some sense anyways, from most basic/necessary
    # to more elaborate/optional
    # note that the boot/ directory is not visited, those files are
    # concatenated by the shell script
    filenames = sorted(filenames + sorted(glob("src/mixins" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/basic-data-structures" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/basic-widgets" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/basic-widgets/menu-system" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/patch-programming" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/buttons" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/icons" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/info-widgets" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/meta" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/apps" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/toolbars" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/graphs-plots-charts" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/maps" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/fizzytiles" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/events-input" + "/*.coffee")))
    filenames = sorted(filenames + sorted(glob("src/macros" + "/*.coffee")))
    # dataflow / calculation engine (spec docs/specs/dataflow-engine-spec.md). A shipped product
    # feature, NOT homepage-excluded (like serialization below). The spreadsheet client's
    # src/spreadsheet glob is added in Phase 2.
    filenames = sorted(filenames + sorted(glob("src/dataflow" + "/*.coffee")))
    # spreadsheet app (the dataflow engine's first client). A shipped product feature, NOT
    # homepage-excluded (like serialization below).
    filenames = sorted(filenames + sorted(glob("src/spreadsheet" + "/*.coffee")))
    # serialization / deserialization / file-save-load family. NOT homepage-excluded:
    # serialization is a shipped product feature (only the dev "test menu" items are
    # stripped, via their own in-file markers). See serialization-deserialization-plan §8.1.
    filenames = sorted(filenames + sorted(glob("src/serialization" + "/*.coffee")))
    # duplication engine (the Duplicator), the live-cloning sibling of serialization.
    # NOT homepage-excluded: duplication is a shipped product feature.
    filenames = sorted(filenames + sorted(glob("src/duplication" + "/*.coffee")))
    if args.includeVideoPlayer:
        filenames = sorted(filenames + sorted(glob("src/video-player" + "/*.coffee")))

    # --list-shippable: emit the shipped-source file list and stop (see the argparse
    # note above). One path per line, consumed by buildSystem/check-coffee-syntax.js.
    # We return BEFORE any output files are written, so nothing is built.
    if args.list_shippable:
        for filename in filenames:
            print(filename)
        return

    # so here we need to take a .coffee file and generate a js that
    # , when run, puts its contents as string into a variable.
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
    # Of course we need to make sure that the obtained JS string is
    # transformed back to the original source, hence why we append the
    # three "replace"s to the string, so we undo the transformations
    # of above.
    #
    # Note that this mechanism fails if the "transformed to" characters
    # are already in the string, however we detect that and besides that's why
    # we picked some strange characters.
    #
    # Also note that we tried to use .json to store these strings rather
    # than using this js trick, however .json loading is not permitted from
    # filesystem, so we'd always need a server...
    STRING_BLOCK = 'window.%s = "%s".replace(/＂/g, "\\\"").replace(/⧹/g, "\\\\").replace(/⤶/g, "\\n");'

    # now iterate through the source files and create
    # 1) the js files with the coffeescript sources, one for each
    # 2) a few the js files with A BATCH OF coffeescript sources
    #    (so we load like 12 source batches rathern tna 400 sources)
    # 3) the manifest for the files above, so the system knows what to load
    #    and also we put in the manifest the number of batches that we
    #    ended up creating
    # In theory you don't need both emitting/loading mechanisms 1) and 2),
    # we just generate sources in both ways for completeness even if we end
    # up loading the batches only (i.e. 2).
    
    batchedSources = ""
    numberOfSourceBatches = 0
    minimumSourcesBatchSize = 150000

    for filename in filenames:
        print(">>>> %s " % (filename))
        # open file and read its contents
        with codecs.open(filename, "r", "utf-8") as f:
            content = f.read()

        # if the file is a class, then we add its source code in a
        # *.coffee file as a window.SOURCENAME_coffeSource variable
        # (string block).
        # We check if the file is a class by searching its contents for a
        # class ... declaration.
        is_class_file = IS_CLASS.search(content)
        is_mixin_file = IS_MIXIN.search(content)


        # all the class and mixins files' coffeescript source is put
        # in .coffee files containing such sources as text.
        # later on in the build process these .coffee "source containers"
        # are going to be translated to javascript (still containing coffeescript
        # sources as text).
        # Also keep track of all the sources in a manifest.
        # The manifest will be loaded at start, and then the sources will be
        # dynamically and asynchronously loaded following the manifest entries.
        # This is so Fizzygum can dynamically (and possibly lazily) load all
        # the morph's classes as coffeescript source code.

        # the meaning of the first bracket is: if --homepage parameter
        # is passed to this script, then
        # there must be no "FILE_NOT_IN_FIZZYGUM_HOMEPAGE" directive in the source,
        # nor "FILE_ONLY_FOR_MACROS" directive in the source,
        # (since p -> q is identical to not p or q, you have what's in the
        # bracket).
        if (not args.homepage or not (FILE_NOT_IN_FIZZYGUM_HOMEPAGE.search(content) or FILE_ONLY_FOR_MACROS.search(content) or FILE_ONLY_FOR_VIDEOPLAYER.search(content))) and (is_class_file or is_mixin_file):

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

            sourceFileName = ntpath.basename(filename).replace(".coffee","_coffeSource")
            escaped_content_with_declaration = STRING_BLOCK % (str(sourceFileName), str(escaped_content))

            with codecs.open("../Fizzygum-builds/latest/js/coffeescript-sources/"+sourceFileName+".js", "w", "utf-8") as f:
                f.write(escaped_content_with_declaration)

            # pile up the sources into a batch and save the batch
            # when is big enough
            batchedSources += "\n\n" + escaped_content_with_declaration
            if len(batchedSources) > minimumSourcesBatchSize:
                sourceFileName = ntpath.basename("sources_batch_"+str(numberOfSourceBatches))
                with codecs.open("../Fizzygum-builds/latest/js/coffeescript-sources/"+sourceFileName+".js", "w", "utf-8") as f:
                    f.write(str(batchedSources))
                numberOfSourceBatches = numberOfSourceBatches + 1
                batchedSources = ""



    # take care of saving the last batch with the remainder
    # of the sources
    sourceFileName = ntpath.basename("sources_batch_"+str(numberOfSourceBatches))
    with codecs.open("../Fizzygum-builds/latest/js/coffeescript-sources/"+sourceFileName+".js", "w", "utf-8") as f:
        f.write(str(batchedSources))
    numberOfSourceBatches += 1

    with codecs.open("../Fizzygum-builds/latest/delete_me/numberOfSourceBatches.coffee", "w", "utf-8") as f:
        f.write("numberOfSourceBatches = " + str(numberOfSourceBatches) + "\n")


    # 4) the entry pages, one per backend flavour (see ENTRY_PAGES). A --homepage
    # build is native-only — no SWCanvas bundle is assembled for it and its font
    # assets are not shipped — so it gets index.html alone.
    for (pageFileName, useSWCanvas) in ENTRY_PAGES:
        if args.homepage and useSWCanvas:
            continue
        generateEntryPage(
                INPUT_HTML_FILE,
                os.path.join(OUTPUT_HTML_DIRECTORY, pageFileName),
                useSWCanvas)


if __name__ == "__main__":
    main()
