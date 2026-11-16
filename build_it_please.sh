#!/bin/bash
# THE BUILD: writes ../Fizzygum-builds/latest. This is its LAUNCHER; the build itself is buildSystem/run-build.js (its
# header says what it does, in order, and each step's comment why). A build flavour is a PROFILE, not a flag:
#   ./build_it_please.sh
#     the dev profile (the default): every part, compiled in the browser, all three entry pages
#   ./build_it_please.sh --profile homepage
#     the production artifact: pre-compiled, native-only, no test machinery
#   ./build_it_please.sh --profile dev-notests
#     the dev world with the test machinery left out
# (and --noSyntaxCheck, which skips every static gate). Exit 0 when the tree is built and stamped, else 1.

# SELF-LOCATE: always run from this script's own directory (Fizzygum/), regardless of the caller's cwd. The Bash cwd
# often resets to the umbrella Fizzygum-all/ between calls, and every path the build uses is relative to Fizzygum/ --
# without this, a bare `./build_it_please.sh` from the wrong dir is "no such file" and a `path/to/build_it_please.sh`
# would build against the wrong tree. Fail loudly if we cannot cd.
cd "$(dirname "$0")" || { echo "build_it_please.sh: FATAL — cannot cd to my own directory ($(dirname "$0"))" >&2; exit 1; }

# node runs the build: the one check that cannot be made by the program it would run
if ! command -v node &> /dev/null
then
    echo "Node.js could not be found; the build needs it (it records its inputs, and runs the syntax gate)."
    exit 1
fi

exec node buildSystem/run-build.js "$@"
