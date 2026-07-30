# SourceVault — the ONE registry of every class/mixin source text the system knows, keyed by
# class name, each tagged with the PART it belongs to.
#
# WHY IT EXISTS. Fizzygum ships its ~500 classes as TEXT and compiles them in the browser (there
# is no module system; see the repo CLAUDE.md). Until arc 4 each source arrived as its own window
# global -- `window.Widget_coffeSource = "…"` -- and the only way to ask "what sources do we have?"
# was to scan `Object.keys(window)` for names ending in `_coffeSource`. That worked while the
# answer was always "all of them", but it cannot express the question a part system asks: *which*
# sources belong to *which* slice, so that a slice can be loaded on demand. A registry can. It
# also gives the escaping ONE choke point (below) instead of ~500 inline `.replace` chains, and it
# stops leaking ~500 names into the global namespace.
#
# WHY A PLAIN OBJECT AND NOT A CLASS. The `Class`/`Mixin` meta-system is itself compiled FROM
# sources held here (globalFunctions loads the Class and Mixin sources through this vault), so a
# SourceVault that were a Class-system class would be a chicken-and-egg. It is a boot-level plain
# object, compiled into the boot bundle, and it must come FIRST in that bundle: every generated
# `sources_batch_*.js` file is a sequence of `SourceVault.store(…)` calls.
#
# THE ESCAPING (moved in here from build.py's per-line emission). A JS string literal cannot
# contain a raw quote, backslash or newline, so buildSystem/build.py replaces those three
# characters with unused lookalike unicode ones on the way out, and `store` undoes it on the way
# in. The build ERRORS OUT if a source already contains one of the three replacements, so the
# round-trip is exact. Keep these three characters in sync with build.py's STRING_BLOCK.
#
# ⚠ Every enumeration here walks the Map directly. Do NOT convert it to a plain object and use
# `for … of`: Object-extensions.coffee puts `augmentWith`/`addInstanceProperties` on
# Object.prototype, so an un-`own`ed walk over any object in this system also yields those.
#
# THE API GROWS WITH ITS CONSUMERS, and only with them -- twice over, here. `namesForPart` and a
# `partOf` were both written in the phase that introduced this registry, had no callers, and were
# correctly REJECTED by the dead-method build gate. `namesForPart` is here now because PartsRegistry
# walks a part's sources to ingest them. `partOf` came back and went away AGAIN: PartsRegistry needs
# the class->part map BEFORE a lazy part loads, and the vault by definition cannot know about
# sources it has not been given yet -- so that map is build manifest data (window.FIZZYGUM_PARTS),
# and the entry's `part` tag is now just a label the vault carries for whoever inspects it. A
# `forgetPart` for a part hot-reload is absent for the same reason: nothing asks.
window.SourceVault =

  # name -> {text, part}
  _entries: new Map

  # Called once per class/mixin by the generated sources_batch_*.js files. `escapedText` is the
  # build's encoded form (see above); the decode happens here so the emitted call site is pure data.
  store: (name, escapedText, part) ->
    text = escapedText
      .replace(/＂/g, '"')
      .replace(/⧹/g, '\\')
      .replace(/⤶/g, '\n')
    @_entries.set name, {text: text, part: part}
    return

  # The source text for a class/mixin name, or nil if we hold no such source.
  get: (name) ->
    @_entries.get(name)?.text

  # Every name we hold, in insertion order (which is the build's emission order -- NOT a load
  # order; dependencies-finding derives that separately).
  names: ->
    Array.from @_entries.keys()

  # The names belonging to one part -- what loading a part walks (PartsRegistry).
  namesForPart: (part) ->
    found = []
    @_entries.forEach (entry, name) ->
      found.push name if entry.part == part
    found
