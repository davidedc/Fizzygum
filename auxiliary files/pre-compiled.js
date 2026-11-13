// The "not pre-compiled" stub. Every build copies it to js/pre-compiled.js,
// and a compile-at-boot tree ships that copy as is: boot reads the flag below
// and compiles the classes from their source text. A profile whose form is
// "precompiled" replaces the copy with the real image, which
// Fizzygum-tests/scripts/generate-pre-compiled-headless.js harvests by booting
// the built page at
//     ?generatePreCompiled
// while the stub is still in place, and which the build then minifies
// (build_it_please.sh, "form: precompiled").

window.preCompiled = false;
