#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
buildProfile.py -- a build FLAVOUR as DATA: the one reader of buildSystem/profiles/*.json.

WHAT A PROFILE IS -- three facts, in buildSystem/profiles/<name>.json:

    parts    which slices of the system ship   (the partition: buildSystem/parts.json)
    form     how the classes reach the world   ("compile-at-boot" | "precompiled")
    entries  which entry pages ship            (ENTRY_PAGES below; each presets a backend)

EVERYTHING ELSE FOLLOWS. Every question the build used to answer with "is this the homepage?" is
DERIVED here from those three (arc 5 PR-D6: derive, never declare):

    the js/tests symlink + BUILDFLAG_LOAD_TESTS      <- does the `harness` part ship?
    the two tests-repo build gates                   <- same
    stripping the dead `if Automator?` branches       <- same, inverted: no Automator, no checks
    assembling the SWCanvas boot bundle               <- does any shipped entry render through SWCanvas?
    shipping the ~90 MB font-assets/                  <- same
    which non-source files land in the tree           <- the shipping parts' own `assets` / `vendor`
    which src/boot/ pieces join the boot bundle       <- the shipping parts' own `bootPrelude`
    running the pre-compile driver + minifying it     <- form == "precompiled"

So the schema has THREE keys, not the eight arc 5's plan first sketched: `sources`, `extras.tests`,
`extras.fontAssets` and `name` all turned out to be derivable or redundant, and a field that mirrors
a fact the build can compute is the very species this program exists to kill. (`sources: lazy|none`
arrives in arc 5 phase 2 WITH its consumer -- until then it would be a field nothing reads.)

WHY THIS EXISTS. Until arc 5, one flavour -- the homepage -- was spelled as a `--homepage` flag and
ten `if $homepage` branches in build_it_please.sh, plus an `inHomepage` boolean per part and a
per-flavour prune list of files to delete again at the end. "What does a production build contain?"
could only be answered by reading a 969-line shell script. Now it is three lines of JSON, and adding
a flavour is adding a file. See docs/plans/build-arc-5-packaging-profiles-plan.md.

USAGE
    build.py                imports this module and calls resolve(name)
    build_it_please.sh      eval's the shell assignments from:
    build_and_smoke.sh          python3 ./buildSystem/buildProfile.py --shell "$@"
                            (pass the build's WHOLE arg list -- this module owns `--profile` parsing,
                            so no caller has to re-implement it)

⚠ Every problem here is FATAL (message + exit 1), never a warning that a default papers over: a
profile that cannot be read, or names a part that no longer exists, would otherwise silently ship
the wrong artifact -- and a rename is exactly when that happens.
"""

from glob import glob
import codecs
import json
import os
import shlex
import sys

PROFILES_DIRECTORY = "buildSystem/profiles"
DEFAULT_PROFILE_NAME = "dev"

# THE PARTITION. buildSystem/parts.json names every part, the directories it owns, and its
# non-source belongings; read its header comment before changing anything here or in build.py.
PARTS_MANIFEST_FILE = "buildSystem/parts.json"

# THE ENTRY PAGES, as (filename, renders through SWCanvas?, loads every part at boot?).
#
# The rendering backend is a BUILD-TIME property of the page: each page presets the flag and loads
# the boot bundle carrying exactly the engine it can use, so no artifact ships an engine it will
# never call and there is no runtime switch to get wrong.
#   index.html                      native 2D + the SWCanvas 3D core (for SW3D)
#   worldWithSystemTestHarness.html full SWCanvas -- the deterministic test substrate
#   index-sw.html                   full SWCanvas, no test harness (interactive SW)
# The test harness is NOT switched on here: WorldWdgt/globalFunctions detect it from the page's
# NAME, so these three differ only in the substituted lines.
#
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
# Both are page PRESETS, chosen at build time, never runtime switches, and not test-only code
# living in the product.
#
# ⚠ This table lives HERE, not in build.py, because a profile's `entries` list is validated against
# it AND two derived facts read the SWCanvas column: the SW boot bundle and the font assets ship iff
# some shipped entry can actually use them. build.py imports it.
ENTRY_PAGES = [
    ("index.html", False, False),
    ("worldWithSystemTestHarness.html", True, True),
    ("index-sw.html", True, True),
]

FORMS = ("compile-at-boot", "precompiled")

# The part whose presence MAKES a build test-capable. Named once, here, because five derived facts
# key off it (see the module docstring) and "which part is the test machinery" is one fact.
HARNESS_PART = "harness"


def fail(message):
    """A profile problem is fatal. Printed to stderr so a `--shell` caller's command substitution
    captures no junk on stdout (an eval of a half-written assignment list is worse than no output)."""
    print("buildProfile: " + message, file=sys.stderr)
    exit(1)


def loadParts():
    """The partition, from buildSystem/parts.json. Read that file's header before changing this."""
    with codecs.open(PARTS_MANIFEST_FILE, "r", "utf-8") as f:
        return json.load(f)["parts"]


def partNames(parts):
    """Every declared part name ("//" keys are prose, not parts)."""
    return [name for name in parts.keys() if not name.startswith("//")]


def resolveSelection(spec, universe, what, profileName):
    """A `parts` / `entries` selection, in one of three spellings, resolved against what EXISTS.

        "all"                        everything -- the dev spelling; a new part/page joins with no edit
        {"allExcept": ["harness"]}   everything but these -- for a flavour defined by a subtraction
        ["core", "meta-tools"]       exactly these -- for a shipped artifact, whose contents should
                                     be visible in one place and should NOT grow when a part is added

    Naming something that does not exist is FATAL, and that is the point: rename a part or a page and
    every profile that still names the old one fails the build instead of quietly shipping less."""
    if spec == "all":
        return list(universe)

    if isinstance(spec, dict):
        unknownKeys = [key for key in spec.keys() if key != "allExcept"]
        if unknownKeys:
            fail("profile '%s': \"%s\" has unknown key(s) %s -- the only object form is "
                 "{\"allExcept\": [...]}" % (profileName, what, ", ".join(sorted(unknownKeys))))
        excluded = spec["allExcept"]
        if not isinstance(excluded, list):
            fail("profile '%s': \"%s\" allExcept must be a list" % (profileName, what))
        for name in excluded:
            if name not in universe:
                fail("profile '%s': \"%s\" allExcept names '%s', which the build does not declare "
                     "(known %s: %s)" % (profileName, what, name, what, ", ".join(universe)))
        return [name for name in universe if name not in excluded]

    if isinstance(spec, list):
        for name in spec:
            if name not in universe:
                fail("profile '%s': \"%s\" names '%s', which the build does not declare "
                     "(known %s: %s)" % (profileName, what, name, what, ", ".join(universe)))
        return [name for name in universe if name in spec]

    fail("profile '%s': \"%s\" must be \"all\", a list, or {\"allExcept\": [...]} -- got %r"
         % (profileName, what, spec))


class Profile:
    """A validated profile: the three declared facts, plus everything derived from them."""

    def __init__(self, name, parts, form, entries):
        self.name = name
        self.form = form
        # the resolved part NAMES this profile selects. Whether a part ALSO needs a build flag
        # (`requiresFlag`) is a separate question -- see partShips().
        self.selectedParts = parts
        # the resolved entry pages, as ENTRY_PAGES triples, in ENTRY_PAGES order
        self.entries = entries

    @property
    def shipsTests(self):
        """Is this a test-capable build? One question, one answer: does the test machinery ship."""
        return HARNESS_PART in self.selectedParts

    @property
    def shipsSWCanvasEntry(self):
        """Can anything in this artifact render through SWCanvas? The SW boot bundle and the ~90 MB
        of font assets exist only to serve such a page, so both follow from this."""
        return any(useSWCanvas for (_, useSWCanvas, _eager) in self.entries)

    @property
    def isPreCompiled(self):
        return self.form == "precompiled"

    def selectsPart(self, partName):
        return partName in self.selectedParts


def partShips(partName, part, profile, includeVideoPlayer):
    """Does this part ship in the build being made? THE part-inclusion rule, written once.

    Two independent conditions: the profile selects it, and any additional opt-in flag it declares
    is set. `requiresFlag` survives profiles for exactly one carrier -- the video player, whose
    `--includeVideoPlayer` is a per-invocation opt-in rather than a property of an artifact. (The
    other carrier, `requiresFlag: "tests"` on the harness part, is GONE: whether the test machinery
    ships is now the profile's own `parts` selection, so it is not asked twice.)"""
    if not profile.selectsPart(partName):
        return False
    if part.get("requiresFlag") == "videoPlayer" and not includeVideoPlayer:
        return False
    return True


def shippingParts(parts, profile, includeVideoPlayer):
    """(name, spec) for every part that ships, in parts.json order."""
    return [(name, parts[name]) for name in partNames(parts)
            if partShips(name, parts[name], profile, includeVideoPlayer)]


def bootPrelude(parts, profile, includeVideoPlayer):
    """The src/boot/ pieces that shipping parts contribute to the boot bundle.

    A part can own more than sources: `assets` are copied, `vendor` payloads assembled, and a
    `bootPrelude` piece is concatenated into the boot bundle. src/boot/numbertimes.coffee is the
    one carrier -- it extends Number for the fizzytiles LiveCodeLang preprocessor, and used to be
    appended under `if ! $homepage`, i.e. the shell knew a fact about a part."""
    pieces = []
    for (partName, part) in shippingParts(parts, profile, includeVideoPlayer):
        pieces.extend(part.get("bootPrelude", []))
    return pieces


def availableProfileNames():
    return sorted(os.path.basename(path)[:-len(".json")]
                  for path in glob(os.path.join(PROFILES_DIRECTORY, "*.json")))


def resolve(name):
    """Load and fully validate profiles/<name>.json. Any problem is fatal (see the module header)."""
    path = os.path.join(PROFILES_DIRECTORY, name + ".json")
    if not os.path.isfile(path):
        fail("no such profile '%s' (%s does not exist). Available: %s"
             % (name, path, ", ".join(availableProfileNames()) or "none"))
    try:
        with codecs.open(path, "r", "utf-8") as f:
            declared = json.load(f)
    except ValueError as error:
        fail("profile '%s' is not valid JSON (%s): %s" % (name, path, error))

    # An unknown key is a typo that would otherwise be silently ignored, and a silently-ignored
    # `"from": "precompiled"` ships a compile-at-boot tree while claiming otherwise.
    allowed = ("//", "parts", "form", "entries")
    unknownKeys = [key for key in declared.keys() if key not in allowed]
    if unknownKeys:
        fail("profile '%s' has unknown key(s): %s. A profile declares exactly %s (everything else "
             "about a build is DERIVED -- see buildProfile.py's header)."
             % (name, ", ".join(sorted(unknownKeys)), "/".join(allowed[1:])))
    for key in ("parts", "form", "entries"):
        if key not in declared:
            fail("profile '%s' is missing \"%s\"" % (name, key))

    form = declared["form"]
    if form not in FORMS:
        fail("profile '%s': form must be one of %s -- got %r" % (name, " / ".join(FORMS), form))

    parts = loadParts()
    selectedParts = resolveSelection(declared["parts"], partNames(parts), "parts", name)
    if "core" not in selectedParts:
        fail("profile '%s' does not ship the 'core' part -- core IS the product" % name)

    entryNames = [pageFileName for (pageFileName, _sw, _eager) in ENTRY_PAGES]
    selectedEntryNames = resolveSelection(declared["entries"], entryNames, "entries", name)
    if not selectedEntryNames:
        fail("profile '%s' ships no entry page -- there would be nothing to open" % name)
    entries = [entry for entry in ENTRY_PAGES if entry[0] in selectedEntryNames]

    # The pre-compile driver boots index.html?generatePreCompiled to harvest the image, so a
    # precompiled profile that does not ship index.html could not be built at all.
    if form == "precompiled" and "index.html" not in selectedEntryNames:
        fail("profile '%s': form \"precompiled\" needs index.html among its entries -- the "
             "pre-compile driver harvests the image by booting it" % name)

    return Profile(name, selectedParts, form, entries)


def profileNameFromArgv(argv):
    """`--profile <name>` out of a build's raw arg list; DEFAULT_PROFILE_NAME when absent.

    Owned here so that build_it_please.sh, build_and_smoke.sh and build.py cannot disagree about
    which profile is being built."""
    for index, argument in enumerate(argv):
        if argument == "--profile":
            if index + 1 >= len(argv):
                fail("--profile needs a name. Available: %s" % ", ".join(availableProfileNames()))
            return argv[index + 1]
        if argument.startswith("--profile="):
            return argument.split("=", 1)[1]
    return DEFAULT_PROFILE_NAME


def emitShellAssignments(argv):
    """The facts build_it_please.sh / build_and_smoke.sh need, as `eval`-able bash.

    Booleans are emitted as the literals true/false so the shell can keep its existing
    `if $SOMETHING ; then` idiom, and the prelude comes out as a bash ARRAY (quoted with shlex, so a
    path with a space cannot break the eval)."""
    profile = resolve(profileNameFromArgv(argv))
    parts = loadParts()
    includeVideoPlayer = "--includeVideoPlayer" in argv
    prelude = bootPrelude(parts, profile, includeVideoPlayer)

    print("PROFILE_NAME=%s" % shlex.quote(profile.name))
    print("PROFILE_FORM=%s" % shlex.quote(profile.form))
    print("PROFILE_SHIPS_TESTS=%s" % ("true" if profile.shipsTests else "false"))
    print("PROFILE_SHIPS_SWCANVAS_ENTRY=%s" % ("true" if profile.shipsSWCanvasEntry else "false"))
    print("PROFILE_BOOT_PRELUDE=(%s)" % " ".join(shlex.quote(piece) for piece in prelude))


if __name__ == "__main__":
    argv = sys.argv[1:]
    if "--shell" not in argv:
        fail("usage: buildProfile.py --shell [the build's whole arg list]")
    emitShellAssignments([argument for argument in argv if argument != "--shell"])
