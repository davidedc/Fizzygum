# FileLoading — ingest a Fizzygum file (drag-dropped onto the desktop, or chosen through a
# file dialog) and route it by the envelope's `kind` field, NEVER by the filename. See
# docs/architecture/serialization-duplication-reference.md §10. A PRODUCT feature — ships in all builds.
#
# The single file extension is `*.fzw.json` (plain JSON inside); a `kind:"widget"` file
# restores a detached widget attached at the drop point, a `kind:"world"` file loads a whole
# world snapshot (§11). Non-Fizzygum files are rejected with a friendly inform.
#
# BOTH DOORS LOAD WHAT A FILE NEEDS FIRST, and both may therefore WAIT: a file can name classes a
# LAZY part provides, or (on a `sources: "lazy"` build) need the reflective layer, and either is
# fetched before anything is built (Deserializer.loadWhatItNeeds). A load that waits answers a
# promise, and a failure in its asynchronous half -- a part that did not load, a re-entered load that
# threw -- is reported exactly as a synchronous one is (_reportingSerializationErrors). On every
# build the suite runs, everything is resident, so both doors restore inline.
class FileLoading

  # A hidden <input type=file>, created on demand and clicked from an "Open from file…" menu
  # item (a user gesture, so it is allowed over file://).
  @openFromFileDialog: ->
    input = document.createElement "input"
    input.type = "file"
    input.accept = ".json,application/json"
    input.style.display = "none"
    input.onchange = =>
      @loadFile input.files[0] if input.files? and input.files.length > 0
      input.remove?()
    document.body.appendChild input
    input.click()
    return

  # Read a File object (from drag-drop or the dialog) as text, then route it.
  @loadFile: (file, dropPoint) ->
    return unless file?
    reader = new FileReader
    reader.onload = => @loadEnvelopeString reader.result, dropPoint
    reader.onerror = -> world.inform "Could not read that file."
    reader.readAsText file
    return

  # Sniff a string as a Fizzygum envelope and route by its `kind`. `dropPoint` (optional) is
  # where a restored widget should be placed. Answers the load's promise when the load waits for
  # what the file needs (the header), else undefined.
  @loadEnvelopeString: (string, dropPoint) ->
    envelope = undefined
    try
      envelope = JSON.parse string
    catch e
      envelope = undefined
    unless envelope? and envelope.format is Serializer.FORMAT
      world.inform "This is not a Fizzygum file\n(expected a *.fzw.json file)."
      return
    switch envelope.kind
      when "widget"
        @_reportingSerializationErrors => @_loadWidgetEnvelope envelope, dropPoint
      when "world"
        if world.loadWorldSnapshot?
          # A file this build can never restore is refused by the loader itself, desktop untouched,
          # so a SerializationError reported here is one that failed part-way through the restore,
          # or a part the file needs that did not load (the desktop untouched then too).
          @_reportingSerializationErrors -> world.loadWorldSnapshot envelope
        else
          world.inform "This build cannot load whole-world snapshots yet."
          undefined
      else
        world.inform "Unknown Fizzygum file kind: " + envelope.kind
        undefined

  # Restore a widget file and attach it at the drop point. A widget door has no teardown, so its
  # "before anything changes" is before the first shell is built, and it takes the world door's guards
  # there, from the same functions and in the same order (WorldWdgt.loadWorldSnapshot):
  #   1. a file this build can NEVER restore is refused, naming every class it lacks (a class a LAZY
  #      part provides is not a reason) or every app key naming a class that is not an app, and no part
  #      is fetched for it;
  #   2. what the file needs is loaded (Deserializer.loadWhatItNeeds), and this RE-ENTERS once it has
  #      arrived -- which also judges an app key naming a class that just arrived, and a {"$src"} on
  #      one, in deserialize's own pre-pass;
  #   3. then the restore.
  # Answers undefined when it restored inline, else the re-entered load's promise.
  @_loadWidgetEnvelope: (envelope, dropPoint) ->
    whyNot = Deserializer.whyItCanNeverBeRestored envelope, (className) -> world.parts.canEverProvideClass className
    throw new SerializationError whyNot, direction: "load" if whyNot?
    arriving = Deserializer.loadWhatItNeeds envelope
    if arriving?
      return arriving.then => @_loadWidgetEnvelope envelope, dropPoint
    result = Deserializer.deserialize envelope
    widget = result.widget
    world.add widget
    widget._applyMoveTo dropPoint if dropPoint?
    # RE-RECORD (the F6 family, auto-bookkeeping arc): the loaded widget carries the
    # fractional bookkeeping serialized in its previous life, which the fill-only seed
    # respects -- re-derive at the landing position explicitly.
    widget._rememberFractionalSituationInHoldingPanel?()
    result.whenReady?.then? ->
      # door-callback law (PartsRegistry's header): the decode is exactly when the freshly
      # landed widget can be closed and destroyed, and the tail must not invalidate a corpse
      return if widget.destroyed
      # cross-invalidation-sanctioned: load orchestration — a deferred repaint once async
      # image/canvas assets have decoded; the deserializer restores fields directly, so
      # there is no receiver-side method seam for this
      widget._fullChanged?()
    undefined

  # Run one restore and answer what it answers — or, when it fails with a SerializationError, show that
  # to the user as one message and answer undefined, so a bad file never surfaces as an uncaught
  # error in the file reader's callback. Any other error is a bug, and propagates. A restore that
  # WAITS answers a promise, and its rejection is reported the same way (a non-SerializationError one
  # stays a rejection: a bug). Both kinds of file come through here, so the two cannot report a
  # failed load differently, nor can a load's two halves.
  @_reportingSerializationErrors: (restore) ->
    try
      result = restore()
    catch error
      return @_informOfLoadError error
    return result unless typeof result?.then is "function"
    result.catch (error) => @_informOfLoadError error

  # A SerializationError is a file this build cannot load: one message, and the load answers
  # undefined. Anything else is a bug, and is thrown on.
  @_informOfLoadError: (error) ->
    throw error unless error instanceof SerializationError
    world.inform error.toString()
    undefined
